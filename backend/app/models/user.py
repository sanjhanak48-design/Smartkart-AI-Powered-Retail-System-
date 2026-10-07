from sqlalchemy import Column, BigInteger, String, Enum, Boolean, TIMESTAMP
from sqlalchemy.sql import func

from app.database.connection import Base


class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, autoincrement=True)

    name = Column(String(100), nullable=False)

    email = Column(String(150), unique=True, nullable=False)

    password_hash = Column(String(255), nullable=False)

    role = Column(
        Enum("CUSTOMER", "MANAGER"),
        nullable=False,
        default="CUSTOMER"
    )

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