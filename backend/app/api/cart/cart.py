from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.models import CartItem, Product
from app.models.cart import CartItem
from app.models.product import Product

router = APIRouter(
    prefix="/cart",
    tags=["Cart"]
)


@router.put("/{user_id}/item/{product_id}")
def update_cart_item(
    user_id: int,
    product_id: int,
    quantity: int,
    db: Session = Depends(get_db)
):
    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.user_id == user_id,
            CartItem.product_id == product_id
        )
        .first()
    )

    if not cart_item:
        raise HTTPException(
            status_code=404,
            detail="Cart item not found"
        )

    if quantity <= 0:
        raise HTTPException(
            status_code=400,
            detail="Quantity must be greater than 0"
        )

    cart_item.quantity = quantity

    db.commit()
    db.refresh(cart_item)

    return {
        "message": "Cart quantity updated",
        "cart_item_id": cart_item.id,
        "user_id": user_id,
        "product_id": product_id,
        "quantity": cart_item.quantity
    }


@router.get("/{user_id}")
def get_cart(
    user_id: int,
    db: Session = Depends(get_db)
):
    cart_items = (
        db.query(CartItem, Product)
        .join(Product, CartItem.product_id == Product.id)
        .filter(CartItem.user_id == user_id)
        .all()
    )

    if not cart_items:
        return {
            "user_id": user_id,
            "items": [],
            "total": 0
        }

    items = []
    total = 0

    for cart_item, product in cart_items:

        subtotal = float(product.price) * cart_item.quantity
        total += subtotal

        items.append({
            "cart_item_id": cart_item.id,
            "product_id": product.id,
            "name": product.name,
            "price": float(product.price),
            "quantity": cart_item.quantity,
            "weight_grams": float(product.weight_grams),
            "subtotal": subtotal
        })

    return {
        "user_id": user_id,
        "items": items,
        "total": total
    }
@router.delete("/{user_id}/item/{product_id}")
def delete_cart_item(
    user_id: int,
    product_id: int,
    db: Session = Depends(get_db)
):
    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.user_id == user_id,
            CartItem.product_id == product_id
        )
        .first()
    )

    if not cart_item:
        raise HTTPException(
            status_code=404,
            detail="Cart item not found"
        )

    db.delete(cart_item)
    db.commit()

    return {
        "message": "Product removed from cart",
        "user_id": user_id,
        "product_id": product_id
    }
@router.delete("/{user_id}")
def clear_cart(
    user_id: int,
    db: Session = Depends(get_db)
):
    cart_items = (
        db.query(CartItem)
        .filter(CartItem.user_id == user_id)
        .all()
    )

    if not cart_items:
        return {
            "message": "Cart is already empty",
            "user_id": user_id
        }

    for item in cart_items:
        db.delete(item)

    db.commit()

    return {
        "message": "Cart cleared successfully",
        "user_id": user_id
    }
@router.post("/{user_id}/item/{product_id}")
def add_to_cart(
    user_id: int,
    product_id: int,
    quantity: int = 1,
    db: Session = Depends(get_db),
):
    """
    Add a product to the customer's cart.
    If the product already exists, increase its quantity.
    """

    if quantity < 1:
        raise HTTPException(
            status_code=400,
            detail="Quantity must be at least 1."
        )

    # Check product
    product = (
        db.query(Product)
        .filter(Product.id == product_id)
        .first()
    )

    if not product:
        raise HTTPException(
            status_code=404,
            detail="Product not found."
        )

    if not product.is_active:
        raise HTTPException(
            status_code=400,
            detail="Product is not active."
        )

    # Check existing cart item
    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.user_id == user_id,
            CartItem.product_id == product_id,
        )
        .first()
    )

    if cart_item:
        cart_item.quantity += quantity
    else:
        cart_item = CartItem(
            user_id=user_id,
            product_id=product_id,
            quantity=quantity,
        )

        db.add(cart_item)

    db.commit()
    db.refresh(cart_item)

    return {
        "message": "Product added to cart successfully",
        "cart_item_id": cart_item.id,
        "user_id": cart_item.user_id,
        "product_id": cart_item.product_id,
        "product_name": product.name,
        "quantity": cart_item.quantity,
        "unit_price": float(product.price),
    }