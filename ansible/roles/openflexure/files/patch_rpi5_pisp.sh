#!/usr/bin/env bash
set -euo pipefail

SRC="src/openflexure_microscope_server/things/camera"
patched=0

# Patch 1: picamera_tuning_file_utils.py
# On Pi 5 (pisp ISP), the bundled vc4 tuning files are incompatible.
# Load system pisp tuning instead and mark it so _initialise_picamera
# skips passing it to Picamera2 (which would break the ISP pipeline).
# Picamera2 will use its built-in system default when no tuning kwarg is given.
TF="${SRC}/picamera_tuning_file_utils.py"
if grep -q '# Note the vc4 here' "$TF" 2>/dev/null; then
  python3 << 'PYEOF'
import os, json

path = "src/openflexure_microscope_server/things/camera/picamera_tuning_file_utils.py"
with open(path) as f:
    c = f.read()

c = c.replace(
    '    fname = f"{sensor_model}.json"\n'
    '    # Note the vc4 here. This locks us to Pi4. We will need to update this to support\n'
    '    # the Raspberry Pi 5.\n'
    '    tuning_path = os.path.join(THIS_DIR, "tuning_files", "vc4", fname)\n'
    '\n'
    '    try:\n'
    '        with open(tuning_path, "r", encoding="utf-8") as file_obj:\n'
    '            return json.load(file_obj)\n'
    '    except (json.decoder.JSONDecodeError, IOError) as e:\n'
    '        raise TuningFileError(f"Could not load tuning from {tuning_path}.") from e',

    '    fname = f"{sensor_model}.json"\n'
    '    vc4_path = os.path.join(THIS_DIR, "tuning_files", "vc4", fname)\n'
    '    if os.path.isfile(vc4_path):\n'
    '        with open(vc4_path, "r", encoding="utf-8") as file_obj:\n'
    '            tuning = json.load(file_obj)\n'
    '        if tuning.get("target") == "pisp":\n'
    '            return tuning\n'
    '    for sys_path in [\n'
    '        f"/usr/share/libcamera/ipa/rpi/pisp/{fname}",\n'
    '        f"/usr/share/libcamera/ipa/rpi/vc4/{fname}",\n'
    '    ]:\n'
    '        if os.path.isfile(sys_path):\n'
    '            with open(sys_path, "r", encoding="utf-8") as file_obj:\n'
    '                tuning = json.load(file_obj)\n'
    '            tuning["_ofm_pisp_system_tuning"] = True\n'
    '            return tuning\n'
    '    return {}'
)

with open(path, 'w') as f:
    f.write(c)
print('Patched tuning utils')
PYEOF
  patched=1
fi

# Patch 2: picamera.py
# - Remove readonly from tuning setting so it can be set during init
# - Handle ServerNotRunningError when setting tuning in __init__
# - Use default colour gains when tuning is empty/pisp-system
# - Skip passing tuning to Picamera2 on Pi 5 (pisp system tuning marked
#   with _ofm_pisp_system_tuning flag) so it uses its built-in default
# - Also clear LIBCAMERA_RPI_TUNING_FILE env var on Pi 5
PY="${SRC}/picamera.py"
if grep -q 'Tuning file could not be set' "$PY" 2>/dev/null; then
  python3 << 'PYEOF'
path = "src/openflexure_microscope_server/things/camera/picamera.py"
with open(path) as f:
    c = f.read()

# 2a: Remove readonly from tuning setting
c = c.replace(
    'tuning: dict = lt.setting(default_factory=dict, readonly=True)',
    'tuning: dict = lt.setting(default_factory=dict)'
)

# 2b: Replace __init__ tuning block
c = c.replace(
    '        # Set tuning to default tuning. This will be overwritten when the Thing is\n'
    '        # connected to the server if tuning is saved to disk.\n'
    '        try:\n'
    '            self.tuning = copy.deepcopy(self.default_tuning)\n'
    '        except ServerNotRunningError as e:\n'
    '            # This will throw an error after setting as we are not connected to\n'
    '            # a server. But we know this, so we ignore the error as long as the\n'
    '            # tuning data is set.\n'
    '            if "version" not in self.tuning:\n'
    '                raise RuntimeError("Tuning file could not be set.") from e\n'
    '\n'
    '        # Also set the colour gains based on the tuning. Set to _colour_gains to not\n'
    '        # trigger a ServerNotRunningError\n'
    '        self._colour_gains = tf_utils.get_colour_gains_from_lst(self.tuning)',

    '        # Set tuning to default tuning. On Pi 5 with pisp system tuning,\n'
    '        # the _ofm_pisp_system_tuning flag is set so _initialise_picamera\n'
    '        # skips passing it to Picamera2 (which would break the ISP pipeline).\n'
    '        try:\n'
    '            self.tuning = copy.deepcopy(self.default_tuning)\n'
    '        except ServerNotRunningError:\n'
    '            self.__dict__["tuning"] = copy.deepcopy(self.default_tuning)\n'
    '\n'
    '        if self.tuning and "version" in self.tuning and not self.tuning.get("_ofm_pisp_system_tuning"):\n'
    '            self._colour_gains = tf_utils.get_colour_gains_from_lst(self.tuning)\n'
    '        else:\n'
    '            self._colour_gains = (1.0, 1.0)'
)

# 2c: Replace _initialise_picamera tuning block
c = c.replace(
    '        with self._picamera_lock, tempfile.NamedTemporaryFile("w") as tuning_file:\n'
    '            json.dump(self.tuning, tuning_file)\n'
    '            tuning_file.flush()  # but leave it open as closing it will delete it\n'
    '            os.environ["LIBCAMERA_RPI_TUNING_FILE"] = tuning_file.name\n'
    '\n'
    '            if self._picamera is not None:',

    '        with self._picamera_lock:\n'
    '            if self.tuning and "version" in self.tuning and not self.tuning.get("_ofm_pisp_system_tuning"):\n'
    '                _tuning_file = tempfile.NamedTemporaryFile("w")\n'
    '                _tuning_file.__enter__()\n'
    '                json.dump(self.tuning, _tuning_file)\n'
    '                _tuning_file.flush()\n'
    '                os.environ["LIBCAMERA_RPI_TUNING_FILE"] = _tuning_file.name\n'
    '            else:\n'
    '                os.environ.pop("LIBCAMERA_RPI_TUNING_FILE", None)\n'
    '                _tuning_file = None\n'
    '\n'
    '            if self._picamera is not None:'
)

c = c.replace(
    '            # Specify tuning file otherwise it will be overwritten with None.\n'
    '            self._picamera = Picamera2(\n'
    '                camera_num=self._camera_num,\n'
    '                tuning=self.tuning,\n'
    '            )',

    '            if self.tuning and "version" in self.tuning and not self.tuning.get("_ofm_pisp_system_tuning"):\n'
    '                self._picamera = Picamera2(\n'
    '                    camera_num=self._camera_num,\n'
    '                    tuning=self.tuning,\n'
    '                )\n'
    '            else:\n'
    '                self._picamera = Picamera2(\n'
    '                    camera_num=self._camera_num,\n'
    '                )\n'
    '\n'
    '            if _tuning_file is not None:\n'
    '                _tuning_file.__exit__(None, None, None)'
)

with open(path, 'w') as f:
    f.write(c)
print('Patched picamera')
PYEOF
  patched=1
fi

# Patch 3: picamera.py image orientation
# The mesoscope's optical path delivers a vertically-inverted image
# (top/bottom flipped). OpenFlexure v3 exposes no orientation setting, so
# inject a picamera2 Transform(vflip=1) into both the streaming (video) and
# still-capture configurations. Applies at the ISP level, so preview and
# captures match.
PY="${SRC}/picamera.py"
if ! grep -q 'from libcamera import Transform' "$PY" 2>/dev/null; then
  python3 << 'PYEOF'
path = "src/openflexure_microscope_server/things/camera/picamera.py"
with open(path) as f:
    c = f.read()

# Import Transform from libcamera
c = c.replace(
    "from picamera2.outputs import Output\n",
    "from picamera2.outputs import Output\nfrom libcamera import Transform\n",
    1,
)

# Streaming (video) configuration
c = c.replace(
    '                stream_config = picam.create_video_configuration(\n'
    '                    main={"size": main_resolution},\n'
    '                    lores={"size": (320, 240), "format": "YUV420"},\n'
    '                    sensor=self._sensor_mode,\n'
    '                    controls=controls,\n'
    '                )',
    '                stream_config = picam.create_video_configuration(\n'
    '                    main={"size": main_resolution},\n'
    '                    lores={"size": (320, 240), "format": "YUV420"},\n'
    '                    sensor=self._sensor_mode,\n'
    '                    controls=controls,\n'
    '                    transform=Transform(vflip=1),\n'
    '                )'
)

# Still capture configuration
c = c.replace(
    'cam.configure(cam.create_still_configuration(sensor=self._sensor_mode))',
    'cam.configure(cam.create_still_configuration(sensor=self._sensor_mode, transform=Transform(vflip=1)))'
)

with open(path, 'w') as f:
    f.write(c)
print('Patched image orientation (vflip)')
PYEOF
  patched=1
fi

# Patch 4: Clean up persisted settings with empty tuning
SETTINGS="/var/openflexure/settings/camera/settings.json"
if [ -f "$SETTINGS" ]; then
  python3 -c "
import json
with open('$SETTINGS') as f:
    s = json.load(f)
if 'tuning' in s and not s['tuning']:
    del s['tuning']
    with open('$SETTINGS', 'w') as f:
        json.dump(s, f, indent=2)
    print('Removed empty tuning from persisted settings')
else:
    print('Persisted settings OK')
"
fi

if [ "$patched" -eq 1 ]; then
  find /opt/openflexure -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
  find /opt/openflexure -name '*.pyc' -delete 2>/dev/null || true
  echo "Patched"
else
  echo "Already patched (or upstream fixed)"
fi
