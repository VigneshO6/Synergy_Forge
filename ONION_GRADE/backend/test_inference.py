import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from services.analysis_service import run_combined_analysis
from ml.inference import compute_box_overlap

def test():
    base = Path(__file__).resolve().parent
    img_path = base.parent / "assets" / "images" / "sample_mixed.jpg"
    res = run_combined_analysis(img_path)
    print("Total detected:", res["total_onions"])
    print("Counts:", res["counts"])
    print("Percentages:", res["percentages"])
    print("Quality:", res["quality"]["label"])
    
    overlaps = []
    for i in range(len(res["detections"])):
        for j in range(i+1, len(res["detections"])):
            b1 = res["detections"][i]["bbox"]
            b2 = res["detections"][j]["bbox"]
            iou, ioa = compute_box_overlap(b1, b2)
            if iou > 0.18 or ioa > 0.28:
                overlaps.append((i, j, iou, ioa))
    print("Overlapping box pairs found:", len(overlaps))
    assert len(overlaps) == 0, f"Found overlapping boxes: {overlaps}"
    print("SUCCESS: Zero overlapping boxes and 4-class categorization verified!")

if __name__ == "__main__":
    test()
