"""
Legacy ML Model Manager wrapper
Redirects to the new Deep Learning (DL) engine in backend/dl/model_loader.py
"""

from typing import Optional, Tuple, Any
from dl.model_loader import get_dl_model_registry, DeepLearningModelRegistry


class ModelManager:
    """
    Backwards compatibility wrapper pointing to DeepLearningModelRegistry.
    """
    @classmethod
    def get_instance(cls):
        return get_dl_model_registry()

    @property
    def yolo_model(self):
        return get_dl_model_registry().yolo_model

    @property
    def mobilenet_model(self):
        return get_dl_model_registry().mobilenet_model

    @property
    def yolo_loaded(self):
        return get_dl_model_registry().yolo_loaded

    @property
    def mobilenet_loaded(self):
        return get_dl_model_registry().mobilenet_loaded

    @property
    def yolo_error(self):
        return get_dl_model_registry().yolo_error

    @property
    def mobilenet_error(self):
        return get_dl_model_registry().mobilenet_error

    def load_all_models(self) -> Tuple[bool, bool]:
        return get_dl_model_registry().load_all()

    def load_yolo(self) -> bool:
        return get_dl_model_registry().load_yolo()

    def load_mobilenet(self) -> bool:
        return get_dl_model_registry().load_mobilenet()


def get_model_manager() -> DeepLearningModelRegistry:
    return get_dl_model_registry()


def get_yolo_model() -> Optional[Any]:
    reg = get_dl_model_registry()
    if not reg.yolo_loaded:
        reg.load_yolo()
    return reg.yolo_model


def get_mobilenet_model() -> Optional[Any]:
    reg = get_dl_model_registry()
    if not reg.mobilenet_loaded:
        reg.load_mobilenet()
    return reg.mobilenet_model
