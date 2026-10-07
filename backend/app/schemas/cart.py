from pydantic import BaseModel


class CartCreate(BaseModel):
    user_id: int


class CartResponse(BaseModel):
    id: int
    user_id: int
    status: str
    subtotal: float
    tax_amount: float
    total_amount: float

    class Config:
        from_attributes = True