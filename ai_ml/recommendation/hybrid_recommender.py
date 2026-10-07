from pathlib import Path
from functools import lru_cache

import pandas as pd
from sqlalchemy.orm import Session

from app.models import Product


# ============================================================
# SmartKart AI - Hybrid Recommendation Engine
# ============================================================
#
# Recommendation sources:
#
# 1. Content Similarity
# 2. Instacart Market Basket Association Rules
# 3. SmartKart <-> Instacart Product Mapping
#
# Final Score:
#
# Hybrid Score =
#     40% Content Similarity
#     +
#     60% Association Score
#
# ============================================================


# ------------------------------------------------------------
# Project paths
# ------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[2]

RULES_FILE = (
    PROJECT_ROOT
    / "datasets"
    / "processed"
    / "association_rules.csv"
)

MAPPING_FILE = (
    PROJECT_ROOT
    / "datasets"
    / "processed"
    / "product_mapping.csv"
)


# ------------------------------------------------------------
# Recommendation weights
# ------------------------------------------------------------

CONTENT_WEIGHT = 0.40
ASSOCIATION_WEIGHT = 0.60


# ============================================================
# LOAD ASSOCIATION RULES
# ============================================================

@lru_cache(maxsize=1)
def load_association_rules():
    """
    Load the pre-computed Instacart association rules.
    """

    if not RULES_FILE.exists():
        print(
            f"WARNING: Association rules file not found: "
            f"{RULES_FILE}"
        )
        return pd.DataFrame()

    rules = pd.read_csv(RULES_FILE)

    required_columns = {
        "antecedent_product_id",
        "consequent_product_id",
        "product_name",
        "recommended_product_name",
        "support",
        "confidence",
        "lift",
    }

    missing = required_columns - set(rules.columns)

    if missing:
        raise ValueError(
            "Missing columns in association_rules.csv: "
            f"{missing}"
        )

    return rules


# ============================================================
# LOAD PRODUCT MAPPING
# ============================================================

@lru_cache(maxsize=1)
def load_product_mapping():
    """
    Load SmartKart -> Instacart product mapping.
    """

    if not MAPPING_FILE.exists():
        print(
            f"WARNING: Product mapping file not found: "
            f"{MAPPING_FILE}"
        )
        return pd.DataFrame()

    mapping = pd.read_csv(MAPPING_FILE)

    required_columns = {
        "smartkart_product_id",
        "smartkart_product_name",
        "instacart_product_id",
        "instacart_product_name",
        "match_method",
        "match_confidence",
    }

    missing = required_columns - set(mapping.columns)

    if missing:
        raise ValueError(
            "Missing columns in product_mapping.csv: "
            f"{missing}"
        )

    return mapping


# ============================================================
# CONTENT SIMILARITY
# ============================================================

def calculate_content_score(source, candidate):
    """
    Calculate simple Jaccard-style text similarity.

    Uses:
        product name
        category
        description
    """

    source_text = " ".join(
        filter(
            None,
            [
                source.name,
                source.category,
                source.description,
            ],
        )
    ).lower()

    candidate_text = " ".join(
        filter(
            None,
            [
                candidate.name,
                candidate.category,
                candidate.description,
            ],
        )
    ).lower()

    source_words = set(source_text.split())
    candidate_words = set(candidate_text.split())

    if not source_words or not candidate_words:
        return 0.0

    intersection = source_words.intersection(
        candidate_words
    )

    union = source_words.union(
        candidate_words
    )

    if not union:
        return 0.0

    return len(intersection) / len(union)


# ============================================================
# ASSOCIATION SCORE
# ============================================================

def get_association_score(
    source_product_id,
    candidate_product_id,
    mapping,
    rules,
):
    """
    Find the market-basket association score between
    a SmartKart source product and SmartKart candidate product.

    Flow:

        SmartKart source ID
                ↓
        Instacart source ID
                ↓
        Association Rules
                ↓
        Instacart candidate ID
                ↓
        SmartKart candidate ID
    """

    if mapping.empty or rules.empty:
        return 0.0

    # --------------------------------------------------------
    # Find source SmartKart -> Instacart mapping
    # --------------------------------------------------------

    source_mapping = mapping[
        mapping["smartkart_product_id"]
        == source_product_id
    ]

    if source_mapping.empty:
        return 0.0

    source_instacart_id = int(
        source_mapping.iloc[0]["instacart_product_id"]
    )

    # --------------------------------------------------------
    # Find candidate SmartKart -> Instacart mapping
    # --------------------------------------------------------

    candidate_mapping = mapping[
        mapping["smartkart_product_id"]
        == candidate_product_id
    ]

    if candidate_mapping.empty:
        return 0.0

    candidate_instacart_id = int(
        candidate_mapping.iloc[0]["instacart_product_id"]
    )

    # --------------------------------------------------------
    # Find association rule
    #
    # antecedent = source Instacart product
    # consequent = candidate Instacart product
    # --------------------------------------------------------

    matching_rules = rules[
        (
            rules["antecedent_product_id"]
            == source_instacart_id
        )
        &
        (
            rules["consequent_product_id"]
            == candidate_instacart_id
        )
    ]

    if matching_rules.empty:
        return 0.0

    # --------------------------------------------------------
    # Select strongest rule
    # --------------------------------------------------------

    best_rule = matching_rules.sort_values(
        by=["lift", "confidence"],
        ascending=False,
    ).iloc[0]

    confidence = float(
        best_rule["confidence"]
    )

    lift = float(
        best_rule["lift"]
    )

    # --------------------------------------------------------
    # Normalize lift
    #
    # Cap lift at 5 so extremely large lift values
    # do not dominate the recommendation.
    # --------------------------------------------------------

    normalized_lift = min(
        max(lift, 0.0),
        5.0
    ) / 5.0

    # --------------------------------------------------------
    # Final association score
    # --------------------------------------------------------

    association_score = (
        confidence
        * normalized_lift
    )

    return min(
        max(association_score, 0.0),
        1.0
    )


# ============================================================
# HYBRID RECOMMENDATION
# ============================================================

def get_hybrid_recommendations(
    db: Session,
    product_id: int,
    top_n: int = 5,
):
    """
    Generate hybrid recommendations.

    Uses:

        40% Content Similarity
        60% Market Basket Association

    """

    # ========================================================
    # 1. Find source SmartKart product
    # ========================================================

    source_product = (
        db.query(Product)
        .filter(
            Product.id == product_id
        )
        .first()
    )

    if not source_product:
        return None

    # ========================================================
    # 2. Get all active candidate products
    # ========================================================

    all_products = (
        db.query(Product)
        .filter(
            Product.is_active == True,
            Product.id != product_id,
        )
        .all()
    )

    if not all_products:
        return []

    # ========================================================
    # 3. Load ML data
    # ========================================================

    rules = load_association_rules()
    mapping = load_product_mapping()

    # ========================================================
    # 4. Generate recommendations
    # ========================================================

    recommendations = []

    for candidate in all_products:

        # ----------------------------------------------------
        # Content score
        # ----------------------------------------------------

        content_score = calculate_content_score(
            source_product,
            candidate,
        )

        # ----------------------------------------------------
        # Association score
        # ----------------------------------------------------

        association_score = get_association_score(
            source_product_id=product_id,
            candidate_product_id=candidate.id,
            mapping=mapping,
            rules=rules,
        )

        # ----------------------------------------------------
        # Hybrid score
        # ----------------------------------------------------

        hybrid_score = (
            CONTENT_WEIGHT
            * content_score
            +
            ASSOCIATION_WEIGHT
            * association_score
        )

        # ----------------------------------------------------
        # Recommendation object
        # ----------------------------------------------------

        recommendations.append(
            {
                "id": candidate.id,

                "name": candidate.name,

                "category": candidate.category,

                "description": candidate.description,

                "price": float(
                    candidate.price
                ),

                "similarity_score": round(
                    content_score,
                    4,
                ),

                "association_score": round(
                    association_score,
                    4,
                ),

                "hybrid_score": round(
                    hybrid_score,
                    4,
                ),
            }
        )

    # ========================================================
    # 5. Sort by hybrid score
    # ========================================================

    recommendations.sort(
        key=lambda item: item["hybrid_score"],
        reverse=True,
    )

    # ========================================================
    # 6. Return Top N
    # ========================================================

    return recommendations[:top_n]