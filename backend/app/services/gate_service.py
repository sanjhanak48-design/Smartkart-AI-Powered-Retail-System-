from sqlalchemy.orm import Session

from app.models.bill import Bill


def check_gate_access(db: Session, bill_id: int):
    """
    Check whether the customer is allowed to exit.

    Gate opens only when payment status is PAID.
    """

    bill = (
        db.query(Bill)
        .filter(Bill.id == bill_id)
        .first()
    )

    if not bill:
        return None

    if bill.payment_status == "PAID":
        return {
            "allowed": True,
            "gate_status": "OPEN",
            "message": "Payment verified. Gate can be opened."
        }

    return {
        "allowed": False,
        "gate_status": "LOCKED",
        "message": f"Payment not completed. Current status: {bill.payment_status}"
    }