from pydantic import BaseModel
from typing import Optional


class ProductCreate(BaseModel):
    rfid_tag: str
    name: str
    category: str
    description: Optional[str] = None
    price: float
    weight_grams: float
    stock_quantity: int = 0


class ProductResponse(BaseModel):
    id: int
    rfid_tag: str
    name: str
    category: str
    description: Optional[str]
    price: float
    weight_grams: float
    stock_quantity: int
    is_active: bool

    class Config:
        from_attributes = True