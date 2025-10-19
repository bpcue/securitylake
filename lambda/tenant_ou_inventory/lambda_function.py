import json
import os
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")
orgs = boto3.client("organizations")

INVENTORY_BUCKET = os.environ["INVENTORY_BUCKET"]
INVENTORY_PREFIX = os.environ.get("INVENTORY_PREFIX", "ous")
TARGET_OUS = [ou.strip() for ou in os.environ.get("TARGET_OUS", "").split(",") if ou.strip()]


def _object_key(ou_id: str) -> str:
    prefix = INVENTORY_PREFIX.strip("/")
    return f"{prefix}/{ou_id}.json" if prefix else f"{ou_id}.json"


def _list_accounts_for_parent(parent_id: str) -> list[str]:
    accounts: list[str] = []
    paginator = orgs.get_paginator("list_accounts_for_parent")
    for page in paginator.paginate(ParentId=parent_id):
        for account in page.get("Accounts", []):
            if account.get("Status") == "ACTIVE":
                accounts.append(account["Id"])
    return sorted(set(accounts))


def sync_ou(ou_id: str) -> dict:
    accounts = _list_accounts_for_parent(ou_id)
    payload = {
        "ou_id": ou_id,
        "accounts": accounts,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    body = json.dumps(payload, separators=(",", ":"))
    s3.put_object(
        Bucket=INVENTORY_BUCKET,
        Key=_object_key(ou_id),
        Body=body,
        ContentType="application/json",
    )
    return payload


def lambda_handler(event, context):
    if not TARGET_OUS:
        raise ValueError("Environment variable TARGET_OUS must contain at least one OU id")

    results = [sync_ou(ou_id) for ou_id in TARGET_OUS]
    return {
        "status": "ok",
        "updated": len(results),
        "details": results,
    }
