from sqlalchemy.orm import Session

from app.models.bill import Bill

# ============================================================
# SmartKart AI - Payment Service
# ============================================================


def initiate_payment(
    db: Session,
    bill_id: int
):
    """
    Start payment for a generated bill.

    Payment flow:
        PENDING -> INITIATED
    """

    bill = (
        db.query(Bill)
        .filter(Bill.id == bill_id)
        .first()
    )

    if not bill:
        return None

    # Payment can only be started for a pending bill
    if bill.payment_status != "PENDING":
        return {
            "success": False,
            "message": (
                f"Payment cannot be initiated. "
                f"Current status: {bill.payment_status}"
            ),
            "bill": bill,
        }

    bill.payment_status = "INITIATED"

    db.commit()
    db.refresh(bill)

    return {
        "success": True,
        "message": "Payment initiated successfully",
        "bill": bill,
    }


def verify_payment(
    db: Session,
    bill_id: int
):
    """
    Verify a payment.

    For the current development prototype:
        INITIATED -> PAID

    Later this function will be connected
    to Razorpay/UPI payment verification.
    """

    bill = (
        db.query(Bill)
        .filter(Bill.id == bill_id)
        .first()
    )

    if not bill:
        return None

    # Payment must be initiated first
    if bill.payment_status != "INITIATED":
        return {
            "success": False,
            "message": (
                f"Payment cannot be verified. "
                f"Current status: {bill.payment_status}"
            ),
            "bill": bill,
        }

    bill.payment_status = "PAID"

    db.commit()
    db.refresh(bill)

    return {
        "success": True,
        "message": "Payment verified successfully",
        "bill": bill,
    }