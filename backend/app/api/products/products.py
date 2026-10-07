from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductResponse


router = APIRouter(
    prefix="/products",
    tags=["Products"]
)


@router.post("/", response_model=ProductResponse)
def create_product(
    product: ProductCreate,
    db: Session = Depends(get_db)
):
    # Check if RFID tag already exists
    existing_product = (
        db.query(Product)
        .filter(Product.rfid_tag == product.rfid_tag)
        .first()
    )

    if existing_product:
        raise HTTPException(
            status_code=400,
            detail="RFID tag already exists"
        )

    # Create product
    new_product = Product(
        rfid_tag=product.rfid_tag,
        name=product.name,
        category=product.category,
        description=product.description,
        price=product.price,
        weight_grams=product.weight_grams,
        stock_quantity=product.stock_quantity
    )

    db.add(new_product)
    db.commit()
    db.refresh(new_product)

    return new_product


@router.get("/", response_model=list[ProductResponse])
def get_products(
    db: Session = Depends(get_db)
):
    products = db.query(Product).all()
    return products


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int,
    db: Session = Depends(get_db)
):
    product = (
        db.query(Product)
        .filter(Product.id == product_id)
        .first()
    )

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )

    return product