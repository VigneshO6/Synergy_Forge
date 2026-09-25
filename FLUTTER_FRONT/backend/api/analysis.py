"""
Analysis API Router
Handles image uploads and triggers deep learning inference.
"""

import uuid
from pathlib import Path
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, status
from fastapi.responses import JSONResponse

from config.settings import UPLOAD_DIR
from services.analysis_service import run_combined_analysis

router = APIRouter(prefix="/api/analysis", tags=["Analysis"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

@router.post("/analyze")
async def analyze_onion_image(
    file: UploadFile = File(..., description="Uploaded onion inspection photograph"),
    batch_id: str = Form("BTH-LIVE", description="Optional batch identifier"),
):
    """
    Accepts an uploaded onion image, validates it, and runs YOLO11 + MobileNetV3.
    """
    # 1. Validate file extension
    filename = file.filename or "sample.jpg"
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image file format '{ext}'. Allowed formats: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    # 2. Read bytes
    try:
        content = await file.read()
        if len(content) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded file is empty."
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to read uploaded image: {str(e)}"
        )

    # 3. Store in uploads folder
    safe_batch_id = "".join([c if c.isalnum() or c in "-_" else "_" for c in batch_id])
    target_dir = UPLOAD_DIR / safe_batch_id
    target_dir.mkdir(parents=True, exist_ok=True)
    
    unique_name = f"{uuid.uuid4().hex[:8]}_{filename}"
    saved_path = target_dir / unique_name
    try:
        with open(saved_path, "wb") as f:
            f.write(content)
    except Exception as e:
        # Non-fatal if upload write fails; proceed with memory bytes
        pass

    # 4. Run Combined Inference
    try:
        result = run_combined_analysis(content, batch_id=batch_id)
        result["saved_image_name"] = unique_name
        return JSONResponse(content=result)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Model inference failed: {str(e)}"
        )
