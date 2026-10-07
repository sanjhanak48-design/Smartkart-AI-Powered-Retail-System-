from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models import User, Product
from app.models.bill import Bill


def get_dashboard_summary(db: Session):
    """
    Calculate the main SmartKart retail analytics.
    """

    # Total customers
    total_customers = (
        db.query(func.count(User.id))
        .filter(User.role == "CUSTOMER")
        .scalar()
        or 0
    )

    # Total active products
    total_products = (
        db.query(func.count(Product.id))
        .filter(Product.is_active == True)
        .scalar()
        or 0
    )

    # Total bills
    total_bills = (
        db.query(func.count(Bill.id))
        .scalar()
        or 0
    )

    # Number of paid bills
    paid_bills = (
        db.query(func.count(Bill.id))
        .filter(Bill.payment_status == "PAID")
        .scalar()
        or 0
    )

    # Total revenue from paid bills
    total_revenue = (
        db.query(func.sum(Bill.total_amount))
        .filter(Bill.payment_status == "PAID")
        .scalar()
        or 0
    )

    # Average paid bill value
    average_bill_value = (
        db.query(func.avg(Bill.total_amount))
        .filter(Bill.payment_status == "PAID")
        .scalar()
        or 0
    )

    # Number of low-stock products
    low_stock_products = (
        db.query(func.count(Product.id))
        .filter(
            Product.is_active == True,
            Product.stock_quantity <= 5
        )
        .scalar()
        or 0
    )

    return {
        "total_customers": int(total_customers),
        "total_products": int(total_products),
        "total_bills": int(total_bills),
        "paid_bills": int(paid_bills),
        "total_revenue": round(float(total_revenue), 2),
        "average_bill_value": round(float(average_bill_value), 2),
        "low_stock_products": int(low_stock_products),
    }