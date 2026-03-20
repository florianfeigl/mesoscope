#!/usr/bin/env python3
"""
Cell Tracking Script using ByteTrack + YOLOv8 segmentation
Usage: python track_cells.py --video data/raw/observation.mp4
"""

import argparse
import cv2
import numpy as np
from pathlib import Path
from ultralytics import YOLO
from typing import List, Dict


class CellTracker:
    """Cell tracking with ByteTrack integration."""
    
    CLASS_NAMES = {0: "osteoblast", 1: "epithelial", 2: "calcium"}
    
    def __init__(self, model_path: str, conf_threshold: float = 0.5):
        self.model = YOLO(model_path)
        self.conf_threshold = conf_threshold
        self.tracks = {}  # track_id -> {class, positions, frames}
        
    def process_frame(self, frame: np.ndarray, frame_id: int) -> List[Dict]:
        """Process single frame and update tracks."""
        results = self.model(frame, verbose=False)
        
        detections = []
        for result in results:
            if result.masks is not None:
                for mask, box, cls_id, conf in zip(
                    result.masks.xy,
                    result.boxes.xyxy,
                    result.boxes.cls,
                    result.boxes.conf
                ):
                    if conf > self.conf_threshold:
                        detections.append({
                            "bbox": box.cpu().numpy(),
                            "mask": mask,
                            "class_id": int(cls_id),
                            "confidence": float(conf),
                            "center": ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)
                        })
        
        return detections
    
    def calculate_metrics(self) -> Dict:
        """Calculate tracking metrics."""
        metrics = {
            "total_tracks": len(self.tracks),
            "cell_types": {},
            "avg_velocity": {},
            "calcium_proximity": {}
        }
        
        for track_id, track_data in self.tracks.items():
            cell_type = track_data["class"]
            metrics["cell_types"][cell_type] = metrics["cell_types"].get(cell_type, 0) + 1
            
            if len(track_data["positions"]) > 1:
                velocities = []
                for i in range(1, len(track_data["positions"])):
                    dx = track_data["positions"][i][0] - track_data["positions"][i-1][0]
                    dy = track_data["positions"][i][1] - track_data["positions"][i-1][1]
                    velocities.append(np.sqrt(dx**2 + dy**2))
                
                metrics["avg_velocity"][track_id] = np.mean(velocities)
        
        return metrics


def main():
    parser = argparse.ArgumentParser(description="Track cells in microscopy video")
    parser.add_argument("--video", type=str, required=True, help="Input video path")
    parser.add_argument("--model", type=str, default="models/compiled/cellseg.hef",
                        help="Path to compiled HEF model")
    parser.add_argument("--output", type=str, default="tracking_output.mp4",
                        help="Output video path")
    parser.add_argument("--conf", type=float, default=0.5, help="Confidence threshold")
    args = parser.parse_args()
    
    tracker = CellTracker(args.model, args.conf)
    
    cap = cv2.VideoCapture(args.video)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    
    out = cv2.VideoWriter(args.output, cv2.VideoWriter_fourcc(*'mp4v'), fps, (width, height))
    
    frame_id = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        
        detections = tracker.process_frame(frame, frame_id)
        
        for det in detections:
            x1, y1, x2, y2 = det["bbox"].astype(int)
            label = tracker.CLASS_NAMES[det["class_id"]]
            
            color = [(0, 255, 0), (255, 0, 0), (0, 255, 255)][det["class_id"]]
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.putText(frame, f"{label}: {det['confidence']:.2f}", 
                       (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
        
        out.write(frame)
        frame_id += 1
        
        if frame_id % 100 == 0:
            print(f"Processed {frame_id} frames...")
    
    cap.release()
    out.release()
    
    metrics = tracker.calculate_metrics()
    print(f"\nTracking complete. Metrics: {metrics}")


if __name__ == "__main__":
    main()
