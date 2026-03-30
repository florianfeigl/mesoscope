#!/usr/bin/env python3
"""
Automated time-lapse capture for cell analysis dataset.

Captures images from OpenFlexure server at regular intervals for training data.

Usage:
    python capture_timelapse.py --output data/raw --interval 60 --duration 72h
    python capture_timelapse.py --output data/raw --count 500  # Fixed number of images

Requirements:
    pip install requests pillow
"""

import argparse
import logging
import requests
import time
from datetime import datetime, timedelta
from pathlib import Path
from PIL import Image
from io import BytesIO

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def capture_from_openflexure(base_url: str = "http://mesoscope.local:5000", timeout: int = 30) -> Image.Image:
    """Capture a single image from OpenFlexure server."""
    endpoint = f"{base_url}/api/v1/camera/capture"
    
    try:
        response = requests.get(endpoint, timeout=timeout)
        response.raise_for_status()
        return Image.open(BytesIO(response.content))
    except requests.exceptions.ConnectionError:
        logger.error(f"Cannot connect to OpenFlexure at {base_url}")
        raise
    except requests.exceptions.Timeout:
        logger.error(f"Capture timeout after {timeout}s")
        raise
    except Exception as e:
        logger.error(f"Capture failed: {e}")
        raise


def capture_from_picamera2(output_dir: Path, prefix: str = "frame") -> str:
    """
    Alternative: Direct capture via picamera2 (run on Pi itself).
    
    This function generates a script snippet for direct capture
    when running locally on the Pi.
    """
    script = f'''
from picamera2 import Picamera2
import time
from pathlib import Path

output_dir = Path("{output_dir}")
output_dir.mkdir(parents=True, exist_ok=True)

picam2 = Picamera2()
picam2.start()
time.sleep(0.5)  # Warmup

for i in range(9999):
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    filename = output_dir / "{prefix}_{{timestamp}}.jpg"
    picam2.capture_file(str(filename))
    print(f"Captured: {{filename}}")
    time.sleep(60)  # Adjust interval as needed
'''
    return script


def main():
    parser = argparse.ArgumentParser(
        description="Time-lapse capture for cell analysis dataset"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        default=Path("data/raw"),
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
        "--base-url",
        type=str,
        default="http://mesoscope.local:5000",
        help="OpenFlexure server URL"
    )
    parser.add_argument(
        "--local",
        action="store_true",
        help="Run locally on Pi using picamera2 (generates script)"
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
            raise ValueError(f"Invalid duration format: {args.duration} (use '24h', '30m', etc.)")
        end_time = datetime.now() + duration
    
    # Setup output directory
    args.output.mkdir(parents=True, exist_ok=True)
    logger.info(f"Output directory: {args.output.absolute()}")
    
    if args.local:
        # Generate picamera2 script for local execution
        script = capture_from_picamera2(args.output, args.prefix)
        script_file = args.output / "capture_local.py"
        script_file.write_text(script)
        logger.info(f"Generated local capture script: {script_file}")
        logger.info("Run with: python3 {script_file}")
        return
    
    # Remote capture via OpenFlexure API
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
            
            try:
                image = capture_from_openflexure(args.base_url)
                image.save(filename, quality=95)
                capture_count += 1
                logger.info(f"[{capture_count:04d}] Saved: {filename.name}")
            except Exception as e:
                logger.error(f"Capture failed: {e}")
                # Continue anyway - don't abort entire session
            
            # Wait for next interval
            if not (args.count and capture_count >= args.count):
                logger.info(f"Waiting {args.interval}s...")
                time.sleep(args.interval)
    
    except KeyboardInterrupt:
        logger.info("\nCapture interrupted by user")
    
    finally:
        elapsed = datetime.now() - start_time
        logger.info(f"Session complete: {capture_count} images in {elapsed}")
        logger.info(f"Average interval: {elapsed.total_seconds() / max(capture_count, 1):.1f}s")


if __name__ == "__main__":
    main()
