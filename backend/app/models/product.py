from sqlalchemy import Column, BigInteger, String, Text, Numeric, Integer, Boolean, TIMESTAMP
from sqlalchemy.sql import func

from app.database.connection import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
 
    rfid_tag = Column(String(100), unique=True, nullable=False)

    name = Column(String(150), nullable=False)

    category = Column(String(100), nullable=False)

    description = Column(Text, nullable=True)

    price = Column(Numeric(10, 2), nullable=False)

    weight_grams = Column(Numeric(10, 2), nullable=False)

    stock_quantity = Column(Integer, nullable=False, default=0)

    is_active = Column(Boolean, nullable=False, default=True)

    created_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )

    updated_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )
