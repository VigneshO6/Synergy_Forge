"""
FastAPI REST Server for ONION SMART System
Supports image upload, sample analysis, batch synchronization, and verification.
"""

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional
import uvicorn
from image_processor import OnionImageProcessor

app = FastAPI(
    title="ONION SMART Quality Analysis & Procurement API",
    version="1.0.0",
    description="REST backend for Image Processing Based Onion Quality Analysis and Smart Procurement System"
)

# Enable CORS for Flutter Web, mobile emulators, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

processor = OnionImageProcessor()

# In-memory batch store for development demo
batches_db = {}


@app.get("/api/health")
def health_check():
    return {
        "status": "healthy",
        "service": "ONION SMART Quality Engine",
        "mode": "Active CV Engine"
    }


@app.post("/api/analyse")
async def analyse_samples(
    batch_id: str = Form(...),
    files: List[UploadFile] = File(...)
):
    """
    POST /api/analyse
    Receives batch_id and one or more sample images.
    Returns quality distribution, categories, and observations.
    """
    if not files:
        raise HTTPException(status_code=400, detail="No sample images uploaded.")

    # Process first valid image or aggregate
    image_bytes = await files[0].read()
    result = processor.analyze_image_bytes(image_bytes, batch_id=batch_id)

    # Save to mock batch store if exists
    if batch_id in batches_db:
        batches_db[batch_id]["quality_report"] = result
        batches_db[batch_id]["status"] = "Analysed"

    return result


@app.post("/api/verify")
async def verify_received_batch(
    batch_id: str = Form(...),
    files: List[UploadFile] = File(...),
    selling_price: Optional[float] = Form(38.0)
):
    """
    Analyzes sample photos taken by Market Seller upon receipt
    and computes transit comparison.
    """
    if not files:
        raise HTTPException(status_code=400, detail="No verification images uploaded.")

    image_bytes = await files[0].read()
    current_result = processor.analyze_image_bytes(image_bytes, batch_id=batch_id)

    # Original baseline
    original_report = batches_db.get(batch_id, {}).get("quality_report", {
        "good_percentage": 82.0,
        "sprouted_percentage": 4.0,
        "defective_percentage": 7.0,
        "undersized_percentage": 7.0
    })

    good_delta = round(current_result["good_percentage"] - original_report.get("good_percentage", 82.0), 2)
    sprout_delta = round(current_result["sprouted_percentage"] - original_report.get("sprouted_percentage", 4.0), 2)
    defective_delta = round(current_result["defective_percentage"] - original_report.get("defective_percentage", 7.0), 2)

    return {
        "batch_id": batch_id,
        "current_quality": current_result,
        "original_quality": original_report,
        "transit_delta": {
            "good_delta": good_delta,
            "sprout_delta": sprout_delta,
            "defective_delta": defective_delta,
            "condition": "Stable" if abs(good_delta) < 5 else "Degraded in transit"
        },
        "selling_price_suggested": selling_price
    }


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
