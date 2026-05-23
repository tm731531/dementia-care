"""Shared helpers for companion_call → iDempiere REST.

Aligned with existing ocr_pipeline.py conventions:
- Uses PUT (not PATCH) for record updates
- Prepends new lines to Description (newest on top)
- Variable names match config.py: IDEMPIERE_USER, IDEMPIERE_PASS, etc.
"""
from __future__ import annotations

import logging
import os
from datetime import date

import requests

logger = logging.getLogger(__name__)

_token_cache: dict[str, str] = {}


def get_idempiere_token() -> str:
    """Login to iDempiere REST and cache token for the process lifetime.

    Returns: JWT token string

    Raises: RuntimeError if login fails
    """
    if "token" in _token_cache:
        return _token_cache["token"]

    url = f"{os.environ['IDEMPIERE_URL']}/auth/tokens"
    payload = {
        "userName": os.environ["IDEMPIERE_USER"],
        "password": os.environ["IDEMPIERE_PASS"],
        "parameters": {
            "clientId": int(os.environ["IDEMPIERE_CLIENT_ID"]),
            "roleId": int(os.environ["IDEMPIERE_ROLE_ID"]),
            "organizationId": int(os.environ["IDEMPIERE_ORG_ID"]),
            "warehouseId": int(os.environ["IDEMPIERE_WAREHOUSE_ID"]),
            "language": "zh_TW",
        },
    }
    r = requests.post(url, json=payload, timeout=10)
    if r.status_code != 200:
        raise RuntimeError(f"iDempiere login failed: {r.status_code} {r.text}")
    token = r.json()["token"]
    _token_cache["token"] = token
    logger.info("iDempiere token cached")
    return token


def _find_today_record(target_date: date, token: str) -> dict | None:
    """GET Z_momSystem record for given date + patient. Returns dict or None."""
    base = os.environ["IDEMPIERE_URL"]
    table = os.environ["TARGET_TABLE"]
    patient = os.environ["PATIENT_NAME"]
    url = f"{base}/models/{table}"
    params = {
        "$filter": f"DateDoc eq '{target_date.isoformat()}' and Name eq '{patient}'",
        "$top": 1,
    }
    r = requests.get(
        url, params=params,
        headers={"Authorization": f"Bearer {token}"},
        timeout=10,
    )
    if r.status_code >= 400:
        raise RuntimeError(f"GET {table} failed: {r.status_code} {r.text}")
    records = r.json().get("records", [])
    return records[0] if records else None


def _get_record_description(record_id: int, token: str) -> str:
    """Fetch a record's current Description (returns empty string if null)."""
    base = os.environ["IDEMPIERE_URL"]
    table = os.environ["TARGET_TABLE"]
    r = requests.get(
        f"{base}/models/{table}/{record_id}",
        headers={"Authorization": f"Bearer {token}"},
        params={"$select": "Description"},
        timeout=10,
    )
    if r.status_code >= 400:
        raise RuntimeError(f"GET desc {r.status_code}: {r.text}")
    return r.json().get("Description") or ""


def upsert_zmomsystem_description(target_date: date, line: str) -> None:
    """Append (prepend) a line to today's Z_momSystem.Description.

    If a record for target_date+patient exists, PUT updated Description (newest on top).
    Else POST a new record with full base fields (Name, DateDoc, C_BPartner_ID).

    Matches existing OCR pipeline convention: newest line at top.
    """
    token = get_idempiere_token()
    base = os.environ["IDEMPIERE_URL"]
    table = os.environ["TARGET_TABLE"]
    patient = os.environ["PATIENT_NAME"]
    bp_id = int(os.environ["REPORTER_BPARTNER_ID"])

    record = _find_today_record(target_date, token)

    if record is None:
        # Create new
        url = f"{base}/models/{table}"
        body = {
            "Name": patient,
            "DateDoc": target_date.isoformat(),
            "C_BPartner_ID": {"id": bp_id},
            "Description": line,
        }
        r = requests.post(
            url, json=body,
            headers={"Authorization": f"Bearer {token}"},
            timeout=15,
        )
        if r.status_code not in (200, 201):
            raise RuntimeError(f"POST {table} failed: {r.status_code} {r.text}")
        logger.info("Created %s record for %s", table, target_date)
        return

    # Existing record — fetch full Description (filter $select limits payload), prepend, PUT
    rid = record["id"]
    existing = _get_record_description(rid, token)
    new_desc = f"{line}\n{existing}" if existing else line

    url = f"{base}/models/{table}/{rid}"
    body = {"Description": new_desc}
    r = requests.put(
        url, json=body,
        headers={"Authorization": f"Bearer {token}"},
        timeout=15,
    )
    if r.status_code >= 400:
        raise RuntimeError(f"PUT {table}/{rid} failed: {r.status_code} {r.text}")
    logger.info("Prepended to %s record %s", table, rid)
