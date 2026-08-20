"""OpenFlexure Microscope IMX500 AI Camera Thing.

This module provides an OpenFlexure-compatible camera Thing for the
Raspberry Pi AI Camera (IMX500). The IMX500 sensor has an on-chip NPU
that runs inference in parallel with image capture.

The IMX500 requires firmware upload before the sensor can operate.
This is handled by the picamera2.devices.IMX500 class, which must be
instantiated before Picamera2.

See repository root for licensing information.
"""

from __future__ import annotations

import logging
import time
from contextlib import contextmanager
from threading import RLock
from types import TracebackType
from typing import Any, Iterator, Literal, Mapping, Optional, Self

import numpy as np
from picamera2 import Picamera2
from picamera2.devices import IMX500
from picamera2.encoders import MJPEGEncoder
from picamera2.outputs import Output
from PIL import Image

import labthings_fastapi as lt
from labthings_fastapi.types.numpy import NDArray

from openflexure_microscope_server.things.camera import BaseCamera, downsample
from openflexure_microscope_server.ui import PropertyControl, property_control_for

LOGGER = logging.getLogger(__name__)

DEFAULT_MODEL = "/usr/share/imx500-models/imx500_network_mobilenet_v2.rpk"


class IMX500StreamOutput(Output):
    """An Output class that sends MJPEG frames to an MJPEGStream."""

    def __init__(self, stream: lt.outputs.MJPEGStream) -> None:
        """Create an output that puts frames in an MJPEGStream."""
        Output.__init__(self)
        self.stream = stream

    def outputframe(
        self,
        frame: bytes,
        _keyframe: Optional[bool] = True,
        _timestamp: Optional[int] = None,
        _packet: Any = None,
        _audio: bool = False,
    ) -> None:
        """Add a frame to the stream's ringbuffer."""
        self.stream.add_frame(frame)


class IMX500Camera(BaseCamera):
    """A Thing providing an OpenFlexure camera interface for the IMX500 AI Camera.

    The IMX500 sensor includes an on-chip NPU that runs neural network
    inference in parallel with normal image capture. This class handles
    both standard imaging and optional inference output extraction.

    Args:
        thing_server_interface: The LabThings server interface.
        model_path: Path to the .rpk model file for the IMX500 NPU.
            A model must be provided for the sensor to operate, even
            if inference results are not used.
        camera_num: Camera index (usually 0 for single-camera setups).
    """

    stream_active: bool = lt.property(default=False, readonly=True)
    """Whether the MJPEG stream is active."""

    stream_resolution: tuple[int, int] = lt.property(default=(820, 616))
    """Resolution to use for the main MJPEG stream."""

    mjpeg_bitrate: Optional[int] = lt.property(default=100000000)
    """Bitrate for MJPEG stream."""

    calibration_crop_fraction: float = lt.property(default=1.0, ge=0.1, le=1.0)
    """Central fraction of the frame used by `capture_downsampled_array`.

    `camera_stage_mapping` (CSM) uses `capture_downsampled_array` for its
    autofocus-tracker cross-correlation (both the "fft" and "direct"
    algorithms). Our lens/illumination setup vignettes the corners of the
    full frame, which can starve the correlation of usable signal and make
    `calibrate_xy`/`calibrate_1d` fail with "MappingError: ... but saw no
    motion" even though the stage is actually moving (see
    docs/BIOREACTOR_POSITION.md). Setting this below 1.0 (e.g. 0.6) crops to
    the central region before downsampling, discarding the dark edges, while
    leaving `capture_array`/live preview/normal snapshots untouched.
    """

    def __init__(
        self,
        thing_server_interface: lt.ThingServerInterface,
        model_path: str = DEFAULT_MODEL,
        camera_num: Optional[int] = None,
    ) -> None:
        """Initialise the IMX500 camera."""
        super().__init__(thing_server_interface)
        self._model_path = model_path
        self._requested_camera_num = camera_num
        self._imx500: Optional[IMX500] = None
        self._picamera: Optional[Picamera2] = None
        self._picamera_lock = RLock()

    def __enter__(self) -> Self:
        """Initialise hardware and start streaming."""
        super().__enter__()
        self._initialise_imx500()
        self.start_streaming()
        return self

    def __exit__(
        self,
        exc_type: type[BaseException],
        exc_value: Optional[BaseException],
        traceback: Optional[TracebackType],
    ) -> None:
        """Close hardware connections."""
        self.stop_streaming()
        if self._picamera is not None:
            with self._picamera_lock:
                self._picamera.close()
                del self._picamera
                self._picamera = None
        super().__exit__(exc_type, exc_value, traceback)

    def _initialise_imx500(self) -> None:
        """Upload firmware to the IMX500 and create the Picamera2 instance."""
        LOGGER.info("Initialising IMX500 with model: %s", self._model_path)
        self._imx500 = IMX500(self._model_path)

        cam_num = (
            self._requested_camera_num
            if self._requested_camera_num is not None
            else self._imx500.camera_num
        )

        LOGGER.info("Creating Picamera2 instance for camera %d", cam_num)
        with self._picamera_lock:
            if self._picamera is not None:
                self._picamera.close()
                del self._picamera
            self._picamera = Picamera2(camera_num=cam_num)

    @property
    def streaming(self) -> bool:
        """True if the camera is currently streaming."""
        return self._picamera is not None and self._picamera.started

    @contextmanager
    def _streaming_picamera(self, pause_stream: bool = False) -> Iterator[Picamera2]:
        """Lock access to picamera and return the underlying Picamera2 instance."""
        already_streaming = self.stream_active
        with self._picamera_lock:
            if pause_stream and already_streaming:
                self.stop_streaming(stop_web_stream=False)
            try:
                yield self._picamera
            finally:
                if pause_stream and already_streaming:
                    self.start_streaming()

    # -- Streaming --

    @lt.action
    def start_streaming(
        self,
        main_resolution: tuple[int, int] = (820, 616),
        buffer_count: int = 6,
    ) -> None:
        """Start the MJPEG stream."""
        with self._streaming_picamera() as picam:
            try:
                if picam.started:
                    picam.stop()
                    picam.stop_encoder()

                stream_config = picam.create_video_configuration(
                    main={"size": main_resolution},
                    lores={"size": (320, 240), "format": "YUV420"},
                    controls={
                        "AeEnable": True,
                        "AwbEnable": True,
                    },
                    buffer_count=buffer_count,
                )
                picam.configure(stream_config)

                stream_name = "lores" if main_resolution[0] > 1280 else "main"
                picam.start_recording(
                    MJPEGEncoder(self.mjpeg_bitrate),
                    IMX500StreamOutput(self.mjpeg_stream),
                    name=stream_name,
                )
                picam.start_encoder(
                    MJPEGEncoder(100000000),
                    IMX500StreamOutput(self.lores_mjpeg_stream),
                    name="lores",
                )
            except Exception:
                LOGGER.exception("Error starting IMX500 stream")
            else:
                self.stream_active = True
                LOGGER.info("IMX500 MJPEG stream started at %s", main_resolution)

    @lt.action
    def stop_streaming(self, stop_web_stream: bool = True) -> None:
        """Stop the MJPEG stream."""
        with self._streaming_picamera() as picam:
            try:
                picam.stop_recording()
            except Exception:
                LOGGER.info("Stopping recording failed (may not have been started)")
            else:
                self.stream_active = False
                if stop_web_stream:
                    self.mjpeg_stream.stop()
                    self.lores_mjpeg_stream.stop()
                LOGGER.info("IMX500 MJPEG stream stopped.")

    # -- Capture --

    @lt.action
    def discard_frames(self) -> None:
        """Discard frames so that the next frame captured is fresh."""
        with self._streaming_picamera() as cam:
            cam.capture_metadata()

    def capture_image(
        self,
        stream_name: Literal["main", "lores", "full"] = "main",
        wait: Optional[float] = 0.9,
    ) -> Image.Image:
        """Acquire one image from the camera and return it as a PIL Image."""
        if wait is None:
            wait = 0.9
        if stream_name in ("main", "lores"):
            with self._streaming_picamera() as cam:
                return cam.capture_image(stream_name, wait=wait)
        elif stream_name == "full":
            with self._streaming_picamera(pause_stream=True) as cam:
                cam.configure(cam.create_still_configuration())
                cam.start()
                time.sleep(0.3)
                img = cam.capture_image(name="main", wait=wait)
                return img
        else:
            raise ValueError(f'Unknown stream name "{stream_name}"')

    @lt.action
    def capture_array(
        self,
        stream_name: Literal["main", "lores", "raw", "full"] = "main",
        wait: Optional[float] = 0.9,
    ) -> NDArray:
        """Acquire one image from the camera and return as a numpy array."""
        if stream_name == "raw":
            with self._streaming_picamera(pause_stream=True) as cam:
                cam.configure(cam.create_still_configuration())
                cam.start()
                time.sleep(0.3)
                return cam.capture_array(name="raw", wait=wait or 0.9)
        return np.array(self.capture_image(stream_name, wait))

    @lt.action
    def capture_downsampled_array(self) -> NDArray:
        """Acquire an image for `camera_stage_mapping` tracking/calibration.

        Crops to the central `calibration_crop_fraction` of the frame (if set
        below 1.0) before downsampling by `downsampled_array_factor`. This
        avoids vignetted/dark corners of the frame confusing the CSM
        tracker's cross-correlation. See `calibration_crop_fraction` for
        details.
        """
        img = self.capture_array()
        fraction = self.calibration_crop_fraction
        if fraction < 1.0:
            height, width = img.shape[:2]
            crop_h, crop_w = int(height * fraction), int(width * fraction)
            y0, x0 = (height - crop_h) // 2, (width - crop_w) // 2
            img = img[y0 : y0 + crop_h, x0 : x0 + crop_w, ...]
        return downsample(self.downsampled_array_factor, img)

    # -- IMX500 AI Inference --

    @lt.action
    def get_inference_outputs(self) -> Optional[list]:
        """Get the latest inference output tensors from the IMX500 NPU.

        Returns a list of numpy arrays (one per output tensor), or None
        if no inference result is available yet.
        """
        if self._imx500 is None:
            return None
        with self._streaming_picamera() as cam:
            metadata = cam.capture_metadata()
            return self._imx500.get_outputs(metadata, add_batch=True)

    @lt.property
    def inference_input_size(self) -> Optional[tuple[int, int]]:
        """The input size (width, height) expected by the loaded model."""
        if self._imx500 is None:
            return None
        return self._imx500.get_input_size()

    @lt.property
    def camera_configuration(self) -> Mapping:
        """The current picamera2 configuration dictionary."""
        with self._streaming_picamera() as cam:
            return cam.camera_configuration()

    @lt.property
    def capture_metadata(self) -> dict:
        """Return the metadata from the latest captured frame."""
        with self._streaming_picamera() as cam:
            return cam.capture_metadata()

    # -- Camera Controls --

    _analogue_gain: float = 1.0

    @lt.setting
    def analogue_gain(self) -> float:
        """The analogue gain applied by the camera sensor."""
        if self.streaming:
            with self._streaming_picamera() as cam:
                self._analogue_gain = cam.capture_metadata().get(
                    "AnalogueGain", self._analogue_gain
                )
        return self._analogue_gain

    @analogue_gain.setter
    def _set_analogue_gain(self, value: float) -> None:
        self._analogue_gain = value
        if self.streaming:
            with self._streaming_picamera() as cam:
                cam.set_controls({"AnalogueGain": value, "AeEnable": False})

    _exposure_time: int = 10000

    @lt.setting
    def exposure_time(self) -> int:
        """The camera exposure time in microseconds."""
        if self.streaming:
            with self._streaming_picamera() as cam:
                self._exposure_time = cam.capture_metadata().get(
                    "ExposureTime", self._exposure_time
                )
        return self._exposure_time

    @exposure_time.setter
    def _set_exposure_time(self, value: int) -> None:
        self._exposure_time = value
        if self.streaming:
            with self._streaming_picamera() as cam:
                cam.set_controls({"ExposureTime": value, "AeEnable": False})

    @lt.property
    def manual_camera_settings(self) -> list[PropertyControl]:
        """Camera settings exposed in the OpenFlexure settings panel."""
        return [
            property_control_for(
                self,
                "exposure_time",
                label="Exposure Time (us)",
                read_back=True,
                read_back_delay=1000,
            ),
            property_control_for(
                self,
                "analogue_gain",
                label="Analogue Gain",
                read_back=True,
                read_back_delay=1000,
            ),
        ]

    @property
    def thing_state(self) -> Mapping[str, Any]:
        """Return camera metadata for capture EXIF data."""
        state = dict(super().thing_state)
        state["camera_board"] = "imx500"
        state["model_path"] = self._model_path
        return state
