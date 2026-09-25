"""
Supabase Database Service for Backend
Handles direct PostgREST CRUD operations with Supabase PostgreSQL tables:
- profiles
- batches
- quality_reports
- analysis_records
"""

import logging
from typing import Dict, Any, Optional, List
import httpx

from config.settings import SUPABASE_URL, SUPABASE_ANON_KEY

logger = logging.getLogger("supabase_db")
logger.setLevel(logging.INFO)


class SupabaseDatabaseService:
    def __init__(self, url: str = SUPABASE_URL, anon_key: str = SUPABASE_ANON_KEY):
        self.base_url = url.rstrip("/")
        self.anon_key = anon_key

    def _headers(self, token: Optional[str] = None) -> Dict[str, str]:
        auth_bearer = f"Bearer {token}" if token else f"Bearer {self.anon_key}"
        return {
            "apikey": self.anon_key,
            "Authorization": auth_bearer,
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=representation",
        }

    async def save_analysis_record(self, record: Dict[str, Any], token: Optional[str] = None) -> bool:
        """Saves a Deep Learning analysis record into Supabase 'analysis_records' table."""
        if not self.base_url or not self.anon_key:
            return False

        url = f"{self.base_url}/rest/v1/analysis_records"
        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                res = await client.post(url, headers=self._headers(token), json=record)
                if res.status_code in (200, 201):
                    logger.info("Saved analysis record to Supabase database.")
                    return True
                else:
                    logger.warning(f"Supabase DB insert returned {res.status_code}: {res.text}")
                    return False
        except Exception as e:
            logger.error(f"Error saving to Supabase database: {e}")
            return False

    async def upsert_batch(self, batch_data: Dict[str, Any], token: Optional[str] = None) -> bool:
        """Upserts a consignment batch into Supabase 'batches' table."""
        if not self.base_url or not self.anon_key:
            return False

        url = f"{self.base_url}/rest/v1/batches"
        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                res = await client.post(url, headers=self._headers(token), json=batch_data)
                return res.status_code in (200, 201)
        except Exception as e:
            logger.error(f"Error upserting batch to Supabase: {e}")
            return False

    async def get_user_profile(self, user_id: str, token: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Retrieves profile information from Supabase 'profiles' table."""
        if not self.base_url or not self.anon_key:
            return None

        url = f"{self.base_url}/rest/v1/profiles?id=eq.{user_id}&select=*"
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.get(url, headers=self._headers(token))
                if res.status_code == 200:
                    data = res.json()
                    return data[0] if data else None
        except Exception as e:
            logger.error(f"Error fetching user profile from Supabase: {e}")
        return None


# Global instance
supabase_db = SupabaseDatabaseService()
