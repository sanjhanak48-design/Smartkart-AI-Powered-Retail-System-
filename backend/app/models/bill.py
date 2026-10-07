from sqlalchemy import (
    Column,
    Numeric,
    String,
    TIMESTAMP,
    ForeignKey,
    func,
)

from sqlalchemy.dialects.mysql import BIGINT

from app.database.connection import Base


class Bill(Base):
    __tablename__ = "bills"

    id = Column(
        BIGINT(unsigned=True),
        primary_key=True,
        autoincrement=True
    )

    user_id = Column(
        BIGINT(unsigned=True),
        ForeignKey("users.id"),
        nullable=False
    )

    subtotal = Column(
        Numeric(10, 2),
        nullable=False
    )

    gst_percentage = Column(
        Numeric(5, 2),
        nullable=False,
        default=5.00
    )

    gst_amount = Column(
        Numeric(10, 2),
        nullable=False
    )

    total_amount = Column(
        Numeric(10, 2),
        nullable=False
    )

    payment_status = Column(
        String(30),
        nullable=False,
        default="PENDING"
    )

    created_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )