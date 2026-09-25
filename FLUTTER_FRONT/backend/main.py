"""
ONION SMART - AI Quality Analysis Backend (Deep Learning 2.0)
FastAPI server serving YOLO11 and MobileNetV3 deep learning models
integrated with Supabase cloud authentication.
"""

import sys
from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Ensure backend root is on sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from config.settings import CORS_ORIGINS, HOST, PORT, SUPABASE_URL, SUPABASE_ANON_KEY
from dl.model_loader import get_dl_model_registry
from api.analysis import router as analysis_router
from api.auth import router as auth_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Loads deep learning models and initializes authentication on server startup.
    """
    print("\n" + "=" * 65)
    print("      ONION SMART - DEEP LEARNING & SUPABASE BACKEND ENGINE")
    print("=" * 65)

    # 0. Sync App Symbol & Logo
    try:
        import shutil
        src_logo = Path(r"C:\Users\vicky\.gemini\antigravity-ide\brain\27b33f65-cb76-4cab-b73c-a5d697dae2f4\.user_uploaded\media_1790268306545.png")
        if src_logo.exists():
            root_dir = Path(__file__).resolve().parent.parent
            dest_paths = [
                root_dir / "assets" / "images" / "app_symbol.png",
                root_dir / "assets" / "images" / "app_logo.png",
                root_dir / "web" / "favicon.png",
                root_dir / "build" / "web" / "favicon.png",
                root_dir / "build" / "web" / "assets" / "assets" / "images" / "app_symbol.png",
                root_dir / "build" / "web" / "assets" / "assets" / "images" / "app_logo.png",
            ]
            for dp in dest_paths:
                dp.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src_logo, dp)
            print(" [BRAND] [OK] App Symbol and Logo synchronized to assets & web")
    except Exception as e:
        print(f" [BRAND] Notice syncing logo: {e}")

    # 1. Load DL Models
    reg = get_dl_model_registry()
    yolo_ok, mobilenet_ok = reg.load_all()
    if yolo_ok:
        print(" [DL] [OK] YOLO11 Object Detector loaded & pre-warmed")
    else:
        print(f" [DL] [WARN] YOLO11 notice: {reg.yolo_error}")

    if mobilenet_ok:
        print(" [DL] [OK] MobileNetV3 Produce Classifier loaded & pre-warmed")
    else:
        print(f" [DL] [WARN] MobileNetV3 notice: {reg.mobilenet_error}")

    # 2. Check Supabase Auth
    if SUPABASE_URL and SUPABASE_ANON_KEY:
        print(f" [AUTH] ✓ Supabase Authentication Service Active ({SUPABASE_URL})")
    else:
        print(" [AUTH] ! Supabase credentials running in local simulation mode")

    print("=" * 65 + "\n")

    yield

    print("Shutting down ONION SMART Deep Learning Engine.")


app = FastAPI(
    title="ONION SMART - AI Produce Quality & Procurement Engine",
    description="Deep learning inference server running YOLO11 and MobileNetV3 with Supabase Auth integration.",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routes
app.include_router(analysis_router)
app.include_router(auth_router)


@app.get("/api/logo.png", tags=["Brand"])
async def get_brand_logo():
    from fastapi.responses import FileResponse, Response
    src_logo = Path(r"C:\Users\vicky\.gemini\antigravity-ide\brain\27b33f65-cb76-4cab-b73c-a5d697dae2f4\.user_uploaded\media_1790268306545.png")
    root_dir = Path(__file__).resolve().parent.parent
    dest_symbol = root_dir / "assets" / "images" / "app_symbol.png"
    if src_logo.exists():
        try:
            import shutil
            dest_paths = [
                dest_symbol,
                root_dir / "assets" / "images" / "app_logo.png",
                root_dir / "web" / "favicon.png",
                root_dir / "build" / "web" / "favicon.png",
                root_dir / "build" / "web" / "assets" / "assets" / "images" / "app_symbol.png",
                root_dir / "build" / "web" / "assets" / "assets" / "images" / "app_logo.png",
            ]
            for dp in dest_paths:
                dp.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src_logo, dp)
        except Exception:
            pass
        return FileResponse(src_logo, media_type="image/png")
    elif dest_symbol.exists():
        return FileResponse(dest_symbol, media_type="image/png")
    return Response(status_code=404)



if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
