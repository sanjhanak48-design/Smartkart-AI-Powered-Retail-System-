import sys
from pathlib import Path

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

# Allow Python to find the ai_ml folder
PROJECT_ROOT = Path(__file__).resolve().parents[3]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from app.database.connection import get_db
from ai_ml.recommendation.hybrid_recommender import get_hybrid_recommendations


router = APIRouter(
    prefix="/recommendations",
    tags=["Recommendations"]
)


@router.get("/{product_id}")
def recommendations(
    product_id: int,
    top_n: int = Query(default=5, ge=1, le=20),
    db: Session = Depends(get_db)
):
    recommendations = get_hybrid_recommendations(
        db=db,
        product_id=product_id,
        top_n=top_n
    )

    return {
        "product_id": product_id,
        "recommendations": recommendations
    }