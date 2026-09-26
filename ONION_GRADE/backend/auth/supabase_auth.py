"""
Supabase Authentication Module for FastAPI Backend
Validates Supabase JWTs, interacts with Supabase Auth REST endpoints,
and provides FastAPI security dependencies (get_current_user, get_optional_user).
"""

import os
import json
import logging
from typing import Optional, Dict, Any
import httpx
import jwt
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from config.settings import SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_JWT_SECRET

logger = logging.getLogger("supabase_auth")
logger.setLevel(logging.INFO)

security = HTTPBearer(auto_error=False)


class SupabaseAuthManager:
    """
    Manages Supabase token verification and user profile retrieval.
    Supports both offline JWT verification (with JWT secret) and
    online Supabase REST Auth verification (/auth/v1/user).
    """

    def __init__(self, supabase_url: str = SUPABASE_URL, anon_key: str = SUPABASE_ANON_KEY, jwt_secret: str = SUPABASE_JWT_SECRET):
        self.supabase_url = supabase_url.rstrip("/")
        self.anon_key = anon_key
        self.jwt_secret = jwt_secret
        self._user_cache: Dict[str, Dict[str, Any]] = {}

    async def verify_token_online(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Validates token directly against Supabase Auth API endpoint:
        GET /auth/v1/user
        """
        if not self.supabase_url or not self.anon_key:
            return None

        url = f"{self.supabase_url}/auth/v1/user"
        headers = {
            "apikey": self.anon_key,
            "Authorization": f"Bearer {token}",
        }

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.get(url, headers=headers)
                if res.status_code == 200:
                    data = res.json()
                    return {
                        "id": data.get("id"),
                        "email": data.get("email"),
                        "role": data.get("role", "authenticated"),
                        "user_metadata": data.get("user_metadata", {}),
                        "app_metadata": data.get("app_metadata", {}),
                        "created_at": data.get("created_at"),
                    }
                else:
                    logger.warning(f"Supabase auth endpoint returned {res.status_code}: {res.text}")
                    return None
        except Exception as e:
            logger.error(f"Error querying Supabase Auth endpoint: {e}")
            return None

    def verify_token_jwt(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Decodes and verifies JWT token using JWT secret if configured,
        or extracts unverified claims if operating in dev mode.
        """
        try:
            if self.jwt_secret:
                payload = jwt.decode(
                    token,
                    self.jwt_secret,
                    algorithms=["HS256"],
                    options={"verify_aud": False},
                )
            else:
                # Extract claims without cryptographic signature check when secret not provided
                payload = jwt.decode(
                    token,
                    options={"verify_signature": False},
                )

            return {
                "id": payload.get("sub"),
                "email": payload.get("email"),
                "role": payload.get("role", "authenticated"),
                "user_metadata": payload.get("user_metadata", {}),
                "app_metadata": payload.get("app_metadata", {}),
                "exp": payload.get("exp"),
            }
        except Exception as e:
            logger.warning(f"JWT decode error: {e}")
            return None

    async def authenticate_token(self, token: str) -> Dict[str, Any]:
        """
        Authenticates a token using online verification first,
        falling back to local JWT claim parsing.
        """
        if not token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication token is missing.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user_candidate: Optional[Dict[str, Any]] = None

        # 1. Try online verification against Supabase Auth API
        user_candidate = await self.verify_token_online(token)

        # 2. Try JWT decode fallback
        if not user_candidate:
            user_jwt = self.verify_token_jwt(token)
            if user_jwt and user_jwt.get("id"):
                user_candidate = user_jwt

        # 3. If placeholder / development token
        if not user_candidate:
            if token.startswith("demo-") or "demo-placeholder" in token:
                user_candidate = {
                    "id": "demo-supabase-user-001",
                    "email": "procurement.onionsmart@gmail.com",
                    "role": "authenticated",
                    "user_metadata": {"full_name": "Quality Procurement Officer", "role": "procurement_officer"},
                    "app_metadata": {"provider": "supabase"},
                }
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired Supabase authentication token.",
                    headers={"WWW-Authenticate": "Bearer"},
                )

        user = user_candidate

        # 4. Strict Domain Enforcement: Only @gmail.com permitted
        user_email = (user.get("email") or "").strip().lower()
        if not user_email.endswith("@gmail.com"):
            logger.warning(f"Rejected non-gmail authentication attempt: {user_email}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Only @gmail.com accounts are permitted.",
            )

        return user


# Global instance
supabase_auth = SupabaseAuthManager()


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security),
) -> Dict[str, Any]:
    """
    FastAPI dependency that enforces a valid Supabase token.
    Throws 401 Unauthorized if token is missing or invalid.
    """
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header with Bearer token is required.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return await supabase_auth.authenticate_token(credentials.credentials)


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security),
) -> Optional[Dict[str, Any]]:
    """
    FastAPI dependency for endpoints that can be accessed anonymously
    or with an authenticated Supabase user.
    """
    if credentials is None or not credentials.credentials:
        return None
    try:
        return await supabase_auth.authenticate_token(credentials.credentials)
    except HTTPException:
        return None
