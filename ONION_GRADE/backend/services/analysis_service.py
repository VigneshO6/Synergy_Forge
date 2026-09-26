"""
Combined Analysis Service
Integrates YOLO11 object detection with non-overlapping bounding boxes
and per-bulb 4-class classification: Good, Defective, Sprouted, URS (Undersized).
Powered by backend/dl/ deep learning engine.
Completely removes 'Medium'.
"""

from typing import Dict, Any, Union
from pathlib import Path
import numpy as np

from dl.deep_pipeline import deep_pipeline


def run_combined_analysis(
    image_input: Union[bytes, str, Path, np.ndarray],
    batch_id: str = "BTH-LIVE"
) -> Dict[str, Any]:
    """
    Orchestrates Deep Learning models on the provided image:
    1. YOLO11: Finds individual onions, enforces zero box overlap,
       calculates calibers, and categorizes bulbs into Good, Defective, Sprouted, or URS.
    2. MobileNetV3: Determines produce quality grade and confidence.
    Returns combined structured payload strictly with 4 classes (no Medium).
    """
    return deep_pipeline.analyze(image_input, batch_id=batch_id)
