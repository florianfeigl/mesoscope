#!/usr/bin/env python3
"""
Cell Segmentation Model Training Script
Usage: python train.py --config configs/cellseg.yaml
"""

import argparse
import yaml
from pathlib import Path
from ultralytics import YOLO


def main():
    parser = argparse.ArgumentParser(description="Train YOLOv8 segmentation model")
    parser.add_argument("--config", type=str, required=True, help="Config YAML path")
    parser.add_argument("--resume", type=str, default=None, help="Resume from checkpoint")
    args = parser.parse_args()

    # Load config
    with open(args.config, "r") as f:
        config = yaml.safe_load(f)

    # Initialize model
    model = YOLO(config["model"])

    # Train
    results = model.train(
        data=config["data"]["path"],
        epochs=config["epochs"],
        patience=config["patience"],
        batch=config["batch"],
        imgsz=config["imgsz"],
        device=config["device"],
        optimizer=config["optimizer"],
        lr0=config["lr0"],
        lrf=config["lrf"],
        momentum=config["momentum"],
        weight_decay=config["weight_decay"],
        project=config["project"],
        name=config["name"],
        exist_ok=config["exist_ok"],
        save=config["save"],
        val=config["val"],
        plots=config["plots"],
        resume=args.resume,
    )

    # Export to ONNX
    if config.get("export", {}).get("enabled", True):
        best_model = Path(config["project"]) / config["name"] / "weights" / "best.pt"
        if best_model.exists():
            export_model = YOLO(str(best_model))
            export_model.export(
                format=config["export"]["format"],
                opset=config["export"]["opset"],
                simplify=config["export"]["simplify"],
            )
            print(f"Exported to ONNX: {best_model.parent.parent / 'best.onnx'}")


if __name__ == "__main__":
    main()
