from fastapi import FastAPI
from sqlalchemy import text

from app.database.connection import Base, engine
from app.api.users import router as users_router
from app.api.products.products import router as products_router
from app.api.cart.cart import router as cart_router
from app.api.auth.auth import router as auth_router
from app.api.recommendations import router as recommendations_router
from app.api.sentiment.sentiment_api import router as sentiment_router
from app.api.billing import router as billing_router
from app.api.payment.payment import router as payment_router
from app.api.gate.gate import router as gate_router
from app.api.analytics import router as analytics_router

from app.models import User, Product

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SmartKart AI",
    description="AI Powered Retail Billing with RFID & Intelligent Recommendations",
    version="1.0.0"
)

app.include_router(users_router)
app.include_router(products_router)
app.include_router(cart_router)
app.include_router(auth_router)
app.include_router(recommendations_router)
app.include_router(sentiment_router)
app.include_router(billing_router)
app.include_router(payment_router)
app.include_router(gate_router)
app.include_router(analytics_router)

@app.get("/")
def root():
    return {
        "message": "SmartKart AI Backend is running!"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }


@app.get("/health/database")
def database_health():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        return {
            "database": "connected",
            "status": "healthy"
        }

    except Exception as e:
        return {
            "database": "connection_failed",
            "error": str(e)
        }