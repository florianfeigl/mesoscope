#!/usr/bin/env python3
"""
Hailo-8 Inference Script for Cell Segmentation
Deploys compiled HEF model on Hailo-8 NPU
"""

import argparse
import time
import numpy as np
from pathlib import Path


def run_inference_onnx(model_path: str, image_path: str, device: str = "cpu"):
    """Run inference using ONNX Runtime (for testing)."""
    import onnxruntime as ort
    
    session = ort.InferenceSession(model_path, providers=[device])
    import cv2
    
    img = cv2.imread(image_path)
    img = cv2.resize(img, (640, 640))
    img = img.transpose(2, 0, 1).astype(np.float32) / 255.0
    img = np.expand_dims(img, axis=0)
    
    start = time.time()
    output = session.run(None, {"images": img})
    elapsed = time.time() - start
    
    return output, elapsed


def run_inference_hailo(model_path: str, image_path: str):
    """Run inference on Hailo-8 using HailoRT."""
    from hailo_platform import HEF, Device, ConfigureParams
    import numpy as np
    import cv2
    
    # Load HEF
    hef = HEF(model_path)
    
    # Connect to device
    devices = Device.get_available_devices()
    if not devices:
        raise RuntimeError("No Hailo device found")
    
    device = devices[0]
    
    # Configure device
    configure_params = ConfigureParams.create_from_hef(hef, default_stream_params=device.get_stream_params())
    device.configure(hef, configure_params)
    
    # Load and preprocess image
    img = cv2.imread(image_path)
    img = cv2.resize(img, (640, 640))
    img = img.transpose(2, 0, 1).astype(np.float32) / 255.0
    
    # Create input tensor
    import hailort
    vdevice = hailort.HailoRTClassifier(device)
    vdevice.set_input_data(np.ascontiguousarray(img))
    
    # Run inference
    start = time.time()
    output = vdevice.run()
    elapsed = time.time() - start
    
    device.release()
    
    return output, elapsed


def main():
    parser = argparse.ArgumentParser(description="Run cell segmentation inference")
    parser.add_argument("--model", type=str, required=True, help="Model path (.onnx or .hef)")
    parser.add_argument("--image", type=str, required=True, help="Input image path")
    parser.add_argument("--device", type=str, default="hailo", choices=["cpu", "cuda", "hailo"],
                        help="Inference device")
    args = parser.parse_args()
    
    print(f"Running inference on {args.device}")
    print(f"Model: {args.model}")
    print(f"Image: {args.image}")
    
    if args.model.endswith(".hef") or args.device == "hailo":
        output, elapsed = run_inference_hailo(args.model, args.image)
    else:
        output, elapsed = run_inference_onnx(args.model, args.image, args.device)
    
    print(f"\nInference time: {elapsed*1000:.2f} ms")
    print(f"FPS: {1/elapsed:.1f}")


if __name__ == "__main__":
    main()
