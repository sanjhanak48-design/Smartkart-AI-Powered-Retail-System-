from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.services.gate_service import check_gate_access


# ============================================================
# SmartKart AI - Exit Gate API
# ============================================================

router = APIRouter(
    prefix="/gate",
    tags=["Exit Gate"]
)


# ============================================================
# Check Gate Access
# ============================================================

@router.get("/check/{bill_id}")
def check_gate(
    bill_id: int,
    db: Session = Depends(get_db)
):
    """
    Check whether the customer is allowed to exit.

    Gate opens only when payment status is PAID.
    """

    result = check_gate_access(
        db,
        bill_id
    )

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Bill not found"
        )

    return {
        "bill_id": bill_id,
        **result
    }