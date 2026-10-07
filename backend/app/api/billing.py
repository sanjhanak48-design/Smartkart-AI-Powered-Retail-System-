from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.services.billing_service import generate_bill


# ============================================================
# SmartKart AI - Billing API
# ============================================================

router = APIRouter(
    prefix="/billing",
    tags=["Billing"]
)


@router.post("/generate/{user_id}")
def create_bill(
    user_id: int,
    db: Session = Depends(get_db),
):
    """
    Generate a bill from the customer's current cart.
    """

    bill = generate_bill(
        db=db,
        user_id=user_id,
    )

    if not bill:
        raise HTTPException(
            status_code=400,
            detail="Cart is empty or contains no valid products."
        )

    return {
        "message": "Bill generated successfully",
        "bill_id": bill.id,
        "user_id": bill.user_id,
        "subtotal": float(bill.subtotal),
        "gst_percentage": float(bill.gst_percentage),
        "gst_amount": float(bill.gst_amount),
        "total_amount": float(bill.total_amount),
        "payment_status": bill.payment_status,
        "created_at": bill.created_at,
    }