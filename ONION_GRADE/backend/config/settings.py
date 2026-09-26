import os
from pathlib import Path
from typing import List

# Base backend directory
BASE_DIR = Path(__file__).resolve().parent.parent

# Configurable Model Directory (Default directly to OnionGrade_Models)
PRIMARY_MODEL_DIR = Path(r"C:\Users\vicky\Desktop\MODEL_ML\model\OnionGrade_Models")
FALLBACK_MODEL_DIR = Path(r"C:\Users\vicky\Desktop\MODEL_ML")
MODEL_DIR = Path(os.getenv("MODEL_DIR", str(PRIMARY_MODEL_DIR)))

def resolve_model_file(model_dir: Path, filename: str) -> Path:
    """Finds model file directly in model_dir or in recursive subdirectories, parent dirs, etc."""
    candidates = [
        model_dir / filename,
        BASE_DIR / filename,
        BASE_DIR.parent / filename,
        PRIMARY_MODEL_DIR / filename,
        FALLBACK_MODEL_DIR / filename,
    ]
    for c in candidates:
        if c.is_file():
            return c
    # Search recursively if nested
    for d in [model_dir, PRIMARY_MODEL_DIR, FALLBACK_MODEL_DIR, BASE_DIR]:
        if d.exists():
            matches = list(d.rglob(filename))
            if matches:
                return matches[0]
    return model_dir / filename

YOLO_MODEL_PATH = resolve_model_file(MODEL_DIR, "yolo11n_onion_best.pt")
MOBILENET_MODEL_PATH = resolve_model_file(MODEL_DIR, "oniongrade_mobilenetv3_new_best.keras")

# Upload Directory
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Accepted Quality Classes (Medium removed per requirements: Good, Defective, Sprouted, URS only)
ACCEPTED_CLASSES = ["Good", "Defective", "Sprouted", "URS (Undersized)"]

# MobileNetV3 Produce Quality Classes
env_classes = os.getenv("MOBILENET_CLASSES")
if env_classes:
    MOBILENET_CLASSES = [c.strip() for c in env_classes.split(",") if c.strip()]
else:
    MOBILENET_CLASSES = ["Good", "Defective", "Sprouted"]

# Server Configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))

# CORS Origins
CORS_ORIGINS = [
    "http://localhost",
    "http://localhost:8080",
    "http://localhost:8085",
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
    "http://127.0.0.1:8085",
    "*",
]

# Supabase Authentication Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://dwjvyiytbkmqjnvxplzo.supabase.co")
SUPABASE_ANON_KEY = os.getenv(
    "SUPABASE_ANON_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3anZ5aXl0YmttcWpudnhwbHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1NTg0MDAsImV4cCI6MjA0MzEzNDQwMH0.demo-placeholder-signature",
)
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")

