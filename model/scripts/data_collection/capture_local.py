#!/usr/bin/env python3
"""
Direct time-lapse capture using picamera2 (run locally on Pi).

Usage:
    python3 capture_local.py --output /path/to/data/raw --interval 60 --count 500
    python3 capture_local.py --output /path/to/data/raw --duration 24h
"""

import argparse
import logging
import time
from datetime import datetime, timedelta
from pathlib import Path

try:
    from picamera2 import Picamera2
except ImportError:
    print("picamera2 not available - run on Raspberry Pi")
    raise

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(
        description="Time-lapse capture using picamera2"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        required=True,
        help="Output directory for captured images"
    )
    parser.add_argument(
        "--interval", "-i",
        type=int,
        default=60,
        help="Capture interval in seconds (default: 60)"
    )
    parser.add_argument(
        "--duration", "-d",
        type=str,
        default=None,
        help="Total duration (e.g., '24h', '30m', '72h')"
    )
    parser.add_argument(
        "--count", "-n",
        type=int,
        default=None,
        help="Fixed number of images to capture (overrides duration)"
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default="cell",
        help="Filename prefix (default: cell)"
    )
    parser.add_argument(
        "--resolution",
        type=str,
        default="2028x1520",
        help="Capture resolution (default: 2028x1520)"
    )
    
    args = parser.parse_args()
    
    # Parse duration
    end_time = None
    if args.duration:
        duration_str = args.duration.lower()
        if duration_str.endswith("h"):
            duration = timedelta(hours=int(duration_str[:-1]))
        elif duration_str.endswith("m"):
            duration = timedelta(minutes=int(duration_str[:-1]))
        else:
            raise ValueError(f"Invalid duration format: {args.duration}")
        end_time = datetime.now() + duration
    
    # Parse resolution
    try:
        width, height = map(int, args.resolution.split("x"))
    except ValueError:
        raise ValueError(f"Invalid resolution: {args.resolution} (use 'WxH')")
    
    # Setup output directory
    args.output.mkdir(parents=True, exist_ok=True)
    logger.info(f"Output directory: {args.output.absolute()}")
    logger.info(f"Resolution: {width}x{height}")
    
    # Initialize camera
    logger.info("Initializing camera...")
    picam2 = Picamera2()
    
    config = picam2.create_still_configuration(
        main={"size": (width, height)}
    )
    picam2.configure(config)
    picam2.start()
    time.sleep(0.5)  # Sensor warmup
    
    logger.info("Camera ready")
    
    # Capture loop
    capture_count = 0
    start_time = datetime.now()
    
    logger.info(f"Starting time-lapse capture")
    logger.info(f"Interval: {args.interval}s | Prefix: {args.prefix}")
    if end_time:
        logger.info(f"Duration: {args.duration} (ends ~{end_time.strftime('%H:%M')})")
    if args.count:
        logger.info(f"Target: {args.count} images")
    
    try:
        while True:
            # Check termination conditions
            if args.count and capture_count >= args.count:
                logger.info(f"Reached target count: {capture_count} images")
                break
            
            if end_time and datetime.now() >= end_time:
                logger.info(f"Reached duration limit: {args.duration}")
                break
            
            # Capture
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = args.output / f"{args.prefix}_{timestamp}.jpg"
            
            picam2.capture_file(str(filename), quality=95)
            capture_count += 1
            logger.info(f"[{capture_count:04d}] Saved: {filename.name}")
            
            # Wait for next interval
            if not (args.count and capture_count >= args.count):
                time.sleep(args.interval)
    
    except KeyboardInterrupt:
        logger.info("\nCapture interrupted by user")
    
    finally:
        picam2.close()
        elapsed = datetime.now() - start_time
        logger.info(f"Session complete: {capture_count} images in {elapsed}")
        logger.info(f"Average interval: {elapsed.total_seconds() / max(capture_count, 1):.1f}s")


if __name__ == "__main__":
    main()
