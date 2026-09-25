"""
Deep Learning Preprocessing & Data Augmentation Module
Provides high-performance image transformations, EXIF orientation correction,
adaptive gamma/illumination normalization, CLAHE enhancement, and tensor preparation
for YOLO11 and MobileNetV3.
"""

from typing import Union, Tuple, List
from pathlib import Path
import io
import cv2
import numpy as np
from PIL import Image, ImageOps

from dl.dl_config import YOLO_INPUT_SIZE, MOBILENET_INPUT_SIZE


def load_image_rgb(image_input: Union[bytes, str, Path, np.ndarray, Image.Image]) -> np.ndarray:
    """
    Standardizes any image input (camera bytes, file path, numpy, PIL) into a
    contiguous uint8 RGB numpy array (H, W, 3).
    Automatically fixes smartphone / webcam EXIF orientation rotations.
    """
    # 1. From file path
    if isinstance(image_input, (str, Path)):
        try:
            with Image.open(str(image_input)) as pil_img:
                transposed = ImageOps.exif_transpose(pil_img)
                return np.array(transposed.convert("RGB"))
        except Exception:
            img_bgr = cv2.imread(str(image_input))
            if img_bgr is None:
                raise ValueError(f"Could not load image file from {image_input}")
            return cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

    # 2. From raw camera bytes
    elif isinstance(image_input, bytes):
        try:
            with Image.open(io.BytesIO(image_input)) as pil_img:
                transposed = ImageOps.exif_transpose(pil_img)
                return np.array(transposed.convert("RGB"))
        except Exception:
            nparr = np.frombuffer(image_input, np.uint8)
            img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img_bgr is None:
                raise ValueError("Could not decode image from provided byte buffer.")
            return cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

    # 3. From PIL Image
    elif isinstance(image_input, Image.Image):
        transposed = ImageOps.exif_transpose(image_input)
        return np.array(transposed.convert("RGB"))

    # 4. From Numpy array
    elif isinstance(image_input, np.ndarray):
        if image_input.ndim == 2:
            return cv2.cvtColor(image_input, cv2.COLOR_GRAY2RGB)
        elif image_input.ndim == 3 and image_input.shape[2] == 4:
            return cv2.cvtColor(image_input, cv2.COLOR_RGBA2RGB)
        return image_input

    raise TypeError(f"Unsupported image input type: {type(image_input)}")


def normalize_camera_illumination(img_rgb: np.ndarray) -> np.ndarray:
    """
    Normalizes camera exposure and lighting variations:
    - If image is underexposed (< 75 mean luminance), boosts shadows with gamma=0.75
    - If image is overexposed (> 195 mean luminance), compresses highlights with gamma=1.25
    - Keeps well-balanced photos untouched
    """
    gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
    mean_lum = float(np.mean(gray))

    if mean_lum < 75.0:
        gamma = 0.75
    elif mean_lum > 195.0:
        gamma = 1.25
    else:
        return img_rgb

    inv_gamma = 1.0 / gamma
    table = np.array([((i / 255.0) ** inv_gamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
    return cv2.LUT(img_rgb, table)


def apply_clahe_enhancement(img_rgb: np.ndarray) -> np.ndarray:
    """
    Applies Contrast Limited Adaptive Histogram Equalization (CLAHE) on the L-channel
    in CIELAB color space to highlight subtle peel rot, neck mold, and surface decay.
    """
    lab = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    cl = clahe.apply(l)
    enhanced_lab = cv2.merge((cl, a, b))
    return cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2RGB)


def downscale_if_huge(img_rgb: np.ndarray, max_dim: int = 1920) -> np.ndarray:
    """
    Downscales ultra-high resolution camera images (e.g. 4000x3000)
    to a max dimension of 1920px while preserving aspect ratio.
    Dramatically accelerates YOLO11 and MobileNetV3 inference without losing detail.
    """
    h, w = img_rgb.shape[:2]
    if max(h, w) <= max_dim:
        return img_rgb

    scale = max_dim / float(max(h, w))
    new_w = int(w * scale)
    new_h = int(h * scale)
    return cv2.resize(img_rgb, (new_w, new_h), interpolation=cv2.INTER_AREA)


def preprocess_for_yolo(
    image_input: Union[bytes, str, Path, np.ndarray, Image.Image],
    target_size: Tuple[int, int] = YOLO_INPUT_SIZE
) -> Tuple[np.ndarray, int, int]:
    """
    Prepares camera RGB image for YOLO11 inference:
    1. EXIF orientation correction
    2. Adaptive lighting normalization
    3. High-res constraint
    Returns normalized RGB image and its dimensions.
    """
    rgb_img = load_image_rgb(image_input)
    rgb_img = downscale_if_huge(rgb_img)
    rgb_img = normalize_camera_illumination(rgb_img)
    h, w = rgb_img.shape[:2]
    return rgb_img, w, h


def preprocess_for_mobilenet(
    image_input: Union[bytes, str, Path, np.ndarray, Image.Image],
    target_size: Tuple[int, int] = MOBILENET_INPUT_SIZE,
    normalize: bool = True
) -> np.ndarray:
    """
    Resizes and standardizes image crop for MobileNetV3 inference.
    Outputs batch-ready float32 array of shape (1, 224, 224, 3) in [0.0, 1.0] range.
    """
    rgb_img = load_image_rgb(image_input) if not isinstance(image_input, np.ndarray) else image_input
    resized = cv2.resize(rgb_img, target_size, interpolation=cv2.INTER_AREA)
    img_array = resized.astype(np.float32)
    if normalize:
        img_array /= 255.0
    return np.expand_dims(img_array, axis=0)


def extract_bulb_crop(
    full_image_rgb: np.ndarray,
    bbox: dict,
    margin_ratio: float = 0.05
) -> np.ndarray:
    """
    Safely crops an individual onion bulb from full RGB image
    with a small contextual margin.
    """
    h_img, w_img = full_image_rgb.shape[:2]
    x1, y1 = bbox["x1"], bbox["y1"]
    x2, y2 = bbox["x2"], bbox["y2"]
    bw, bh = x2 - x1, y2 - y1

    pad_x = int(bw * margin_ratio)
    pad_y = int(bh * margin_ratio)

    safe_x1 = max(0, x1 - pad_x)
    safe_y1 = max(0, y1 - pad_y)
    safe_x2 = min(w_img, x2 + pad_x)
    safe_y2 = min(h_img, y2 + pad_y)

    crop = full_image_rgb[safe_y1:safe_y2, safe_x1:safe_x2]
    if crop.size == 0:
        return full_image_rgb[y1:y2, x1:x2]
    return crop
