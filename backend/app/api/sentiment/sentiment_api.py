from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.sentiment_service import analyze_sentiment


# ============================================================
# SmartKart AI - Sentiment Analysis API
# ============================================================

router = APIRouter(
    prefix="/sentiment",
    tags=["Sentiment Analysis"]
)


# ============================================================
# Request Schema
# ============================================================

class SentimentRequest(BaseModel):
    text: str = Field(
        ...,
        min_length=1,
        description="Customer feedback text"
    )


# ============================================================
# Sentiment Analysis Endpoint
# ============================================================

@router.post("/analyze")
def analyze_customer_sentiment(
    request: SentimentRequest
):
    """
    Analyze customer feedback sentiment.
    """

    result = analyze_sentiment(request.text)

    return {
        "text": request.text,
        **result
    }