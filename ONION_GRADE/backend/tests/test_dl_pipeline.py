import os
import sys
import numpy as np

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from dl.deep_pipeline import deep_pipeline
from dl.preprocessing import load_image_rgb

def test_deep_learning_pipeline_execution():
    # Create synthetic test RGB image (e.g. simulating 4 separated onions)
    synthetic_image = np.ones((640, 640, 3), dtype=np.uint8) * 120
    
    # Process through pipeline
    result = deep_pipeline.analyze(synthetic_image)
    
    assert result["success"] is True
    assert "counts" in result
    assert "percentages" in result
    assert "calibers" in result
    assert "engine" in result
    assert "DeepLearning" in result["engine"]
    
    # Verify strict 4 classes in counts and percentages
    counts = result["counts"]
    assert "good" in counts
    assert "defective" in counts
    assert "sprouted" in counts
    assert "undersized" in counts
    assert "medium" not in counts  # Medium purged!

    print(f"Deep learning pipeline test passed! Engine: {result['engine']}")
    print(f"Counts: {counts}")
    print(f"Percentages: {result['percentages']}")

if __name__ == "__main__":
    test_deep_learning_pipeline_execution()
