import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_auth_status():
    response = client.get("/api/auth/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["provider"] == "supabase"

def test_verify_valid_gmail_demo_token():
    response = client.post("/api/auth/verify", json={"token": "demo-token-123"})
    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is True
    assert data["user"]["email"].endswith("@gmail.com")

def test_verify_empty_or_invalid_token():
    response = client.post("/api/auth/verify", json={"token": "invalid_token_xyz"})
    assert response.status_code == 401
    data = response.json()
    assert data["valid"] is False

def test_verify_non_gmail_rejected():
    from unittest.mock import patch
    # Mocking online user with non-gmail domain
    with patch("auth.supabase_auth.supabase_auth.verify_token_online", return_value={"id": "u-123", "email": "user@yahoo.com"}):
        response = client.post("/api/auth/verify", json={"token": "valid_yahoo_token"})
        assert response.status_code == 403
        data = response.json()
        assert data["valid"] is False
        assert "Only @gmail.com accounts are permitted" in data["error"]

if __name__ == "__main__":
    test_auth_status()
    test_verify_valid_gmail_demo_token()
    test_verify_empty_or_invalid_token()
    test_verify_non_gmail_rejected()
    print("All backend Supabase Auth tests passed successfully (including Gmail-only rejection)!")
