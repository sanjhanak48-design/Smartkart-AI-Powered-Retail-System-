from decimal import Decimal

from sqlalchemy.orm import Session

from app.models import Product, CartItem, Bill


# ============================================================
# SmartKart AI - Billing Service
# ============================================================

GST_PERCENTAGE = Decimal("5.00")


def generate_bill(
    db: Session,
    user_id: int,
):
    """
    Generate a bill from the customer's current cart.

    Calculation:

        Product Price × Quantity
                    ↓
                Subtotal
                    ↓
                 GST 5%
                    ↓
              Grand Total
    """

    # --------------------------------------------------------
    # Get customer's cart items
    # --------------------------------------------------------

    cart_items = (
        db.query(CartItem)
        .filter(CartItem.user_id == user_id)
        .all()
    )

    if not cart_items:
        return None

    # --------------------------------------------------------
    # Calculate subtotal
    # --------------------------------------------------------

    subtotal = Decimal("0.00")

    for item in cart_items:

        product = (
            db.query(Product)
            .filter(Product.id == item.product_id)
            .first()
        )

        if not product:
            continue

        item_total = (
            Decimal(str(product.price))
            * Decimal(str(item.quantity))
        )

        subtotal += item_total

    # --------------------------------------------------------
    # Calculate GST
    # --------------------------------------------------------

    gst_amount = (
        subtotal * GST_PERCENTAGE / Decimal("100")
    )

    # --------------------------------------------------------
    # Calculate final amount
    # --------------------------------------------------------

    total_amount = subtotal + gst_amount

    # --------------------------------------------------------
    # Create bill
    # --------------------------------------------------------

    bill = Bill(
        user_id=user_id,
        subtotal=subtotal,
        gst_percentage=GST_PERCENTAGE,
        gst_amount=gst_amount,
        total_amount=total_amount,
        payment_status="PENDING",
    )

    db.add(bill)
    db.commit()
    db.refresh(bill)

    return bill