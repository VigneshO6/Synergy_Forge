"""
Model Inspection Diagnostic Utility
Checks model files, input shapes, outputs, classes, and preprocessing settings.
"""

import sys
import os
import json
import zipfile
from pathlib import Path

# Ensure backend root is on sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config.settings import MODEL_DIR, YOLO_MODEL_PATH, MOBILENET_MODEL_PATH, MOBILENET_CLASSES

def inspect_yolo():
    print("\n" + "=" * 60)
    print("INSPECTING YOLO MODEL")
    print("=" * 60)
    print(f"Path: {YOLO_MODEL_PATH}")
    if not YOLO_MODEL_PATH.is_file():
        print(f"[ERROR] YOLO model not found at {YOLO_MODEL_PATH}")
        return

    print(f"File size: {YOLO_MODEL_PATH.stat().st_size / (1024*1024):.2f} MB")
    try:
        from ultralytics import YOLO
        model = YOLO(str(YOLO_MODEL_PATH))
        print(f"Task: {model.task}")
        print(f"Classes (model.names): {model.names}")
        print(f"Number of classes: {len(model.names)}")
        print(f"Overrides / Training Config: {model.overrides}")
        print("[SUCCESS] YOLO model verified.")
    except Exception as e:
        print(f"[ERROR] Failed to load YOLO model: {e}")

def inspect_mobilenet():
    print("\n" + "=" * 60)
    print("INSPECTING MOBILENETV3 MODEL")
    print("=" * 60)
    print(f"Path: {MOBILENET_MODEL_PATH}")
    if not MOBILENET_MODEL_PATH.is_file():
        print(f"[ERROR] MobileNetV3 model not found at {MOBILENET_MODEL_PATH}")
        return

    print(f"File size: {MOBILENET_MODEL_PATH.stat().st_size / (1024*1024):.2f} MB")
    
    # 1. Inspect internal zip config
    try:
        with zipfile.ZipFile(str(MOBILENET_MODEL_PATH)) as z:
            print(f"Archive contents: {z.namelist()}")
            if 'metadata.json' in z.namelist():
                print(f"Metadata: {z.read('metadata.json').decode('utf-8')}")
            if 'config.json' in z.namelist():
                cfg = json.loads(z.read('config.json'))
                print(f"Model Class: {cfg.get('class_name')}")
                layers = cfg.get('config', {}).get('layers', [])
                print(f"Top-level Layers ({len(layers)}): {[(l.get('name'), l.get('class_name')) for l in layers]}")
                
                # Check for built-in rescaling
                for layer in layers:
                    if layer.get('class_name') == 'Functional':
                        sublayers = layer.get('config', {}).get('layers', [])
                        rescaling = [sl for sl in sublayers if 'rescaling' in sl.get('name', '').lower()]
                        if rescaling:
                            print(f"Built-in Rescaling config found: {rescaling[0].get('config')}")
    except Exception as e:
        print(f"[WARNING] Could not read zip metadata: {e}")

    # 2. Load model using Keras
    try:
        os.environ['KERAS_BACKEND'] = 'torch'
        import keras
        model = keras.models.load_model(str(MOBILENET_MODEL_PATH))
        print(f"Input Shape: {model.input_shape}")
        print(f"Output Shape: {model.output_shape}")
        print(f"Configured Quality Classes ({len(MOBILENET_CLASSES)}): {MOBILENET_CLASSES}")
        print("[SUCCESS] MobileNetV3 model loaded and verified.")
    except Exception as e:
        print(f"[ERROR] Failed to load MobileNetV3 model with Keras: {e}")

if __name__ == "__main__":
    print(f"Configured Model Directory: {MODEL_DIR}")
    inspect_yolo()
    inspect_mobilenet()
    print("\n" + "=" * 60)
    print("INSPECTION COMPLETE")
    print("=" * 60)
