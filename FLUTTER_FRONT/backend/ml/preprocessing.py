"""
Image Preprocessing for YOLO11 and MobileNetV3
"""

import io
from typing import Union, Tuple
from pathlib import Path
import numpy as np
from PIL import Image
import cv2

def load_image_rgb(image_input: Union[bytes, str, Path, np.ndarray, Image.Image]) -> np.ndarray:
    """
    Loads any image input (raw bytes, file path, PIL Image, numpy array)
    and returns a clean uint8 RGB numpy array (H, W, 3).
    """
    if isinstance(image_input, bytes):
        pil_img = Image.open(io.BytesIO(image_input)).convert("RGB")
        return np.array(pil_img, dtype=np.uint8)
    elif isinstance(image_input, (str, Path)):
        pil_img = Image.open(str(image_input)).convert("RGB")
        return np.array(pil_img, dtype=np.uint8)
    elif isinstance(image_input, Image.Image):
        return np.array(image_input.convert("RGB"), dtype=np.uint8)
    elif isinstance(image_input, np.ndarray):
        if len(image_input.shape) == 2:
            return cv2.cvtColor(image_input, cv2.COLOR_GRAY2RGB)
        elif image_input.shape[2] == 4:
            return cv2.cvtColor(image_input, cv2.COLOR_RGBA2RGB)
        elif image_input.shape[2] == 3:
            return image_input
        return image_input
    else:
        raise ValueError(f"Unsupported image input type: {type(image_input)}")

def preprocess_for_yolo(image_input: Union[bytes, str, Path, np.ndarray, Image.Image]) -> np.ndarray:
    """
    YOLO11 accepts RGB/BGR numpy arrays or file paths.
    Returns RGB numpy array suitable for Ultralytics inference.
    """
    return load_image_rgb(image_input)

def preprocess_for_mobilenet(
    image_input: Union[bytes, str, Path, np.ndarray, Image.Image],
    target_size: Tuple[int, int] = (224, 224)
) -> np.ndarray:
    """
    Prepares image for MobileNetV3.
    Input image is resized to target_size (224, 224).
    The loaded MobileNetV3Large model contains a built-in Rescaling layer
    (scale=1/127.5, offset=-1.0), so pixel values MUST be in [0, 255] float32.
    Returns array of shape (1, 224, 224, 3).
    """
    rgb = load_image_rgb(image_input)
    resized = cv2.resize(rgb, target_size, interpolation=cv2.INTER_AREA)
    float_img = resized.astype(np.float32)
    batch = np.expand_dims(float_img, axis=0)
    return batch
