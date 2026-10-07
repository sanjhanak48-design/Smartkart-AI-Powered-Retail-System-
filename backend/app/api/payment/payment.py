from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.services.payment_service import (
    initiate_payment,
    verify_payment
)

# ============================================================
# SmartKart AI - Payment API
# ============================================================

router = APIRouter(
    prefix="/payment",
    tags=["Payment"]
)


# ============================================================
# Initiate Payment
# ============================================================

@router.post("/initiate/{bill_id}")
def initiate_bill_payment(
    bill_id: int,
    db: Session = Depends(get_db)
):
    """
    Initiate payment for a bill.

    Payment flow:
        PENDING -> INITIATED
    """

    result = initiate_payment(
        db=db,
        bill_id=bill_id
    )

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Bill not found"
        )

    if not result["success"]:
        raise HTTPException(
            status_code=400,
            detail=result["message"]
        )

    bill = result["bill"]

    return {
        "message": result["message"],
        "bill_id": bill.id,
        "user_id": bill.user_id,
        "amount": float(bill.total_amount),
        "payment_status": bill.payment_status
    }
# ============================================================
# Verify Payment
# ============================================================

@router.post("/verify/{bill_id}")
def verify_bill_payment(
    bill_id: int,
    db: Session = Depends(get_db)
):
    """
    Verify payment for a bill.

    Payment flow:
        INITIATED -> PAID

    Development prototype:
    This simulates successful payment verification.
    Later it will be connected to Razorpay/UPI.
    """

    result = verify_payment(
        db=db,
        bill_id=bill_id
    )

    if result is None:
        raise HTTPException(
            status_code=404,
            detail="Bill not found"
        )

    if not result["success"]:
        raise HTTPException(
            status_code=400,
            detail=result["message"]
        )

    bill = result["bill"]

    return {
        "message": result["message"],
        "bill_id": bill.id,
        "user_id": bill.user_id,
        "amount": float(bill.total_amount),
        "payment_status": bill.payment_status
    }