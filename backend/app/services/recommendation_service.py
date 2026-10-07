from sqlalchemy.orm import Session
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from app.models.product import Product


def get_recommendations(
    db: Session,
    product_id: int,
    top_n: int = 5
):
    # 1. Get all active products
    products = (
        db.query(Product)
        .filter(Product.is_active == True)
        .all()
    )

    # 2. If there are no products, return an empty list
    if not products:
        return []

    # 3. Create text features for every product
    product_features = []

    for product in products:
        name = product.name or ""
        category = product.category or ""
        description = product.description or ""

        text = f"{name} {category} {description}"
        product_features.append(text)

    # 4. Convert product information into numbers
    vectorizer = TfidfVectorizer(stop_words="english")
    tfidf_matrix = vectorizer.fit_transform(product_features)

    # 5. Find the product requested by the customer
    target_index = None

    for index, product in enumerate(products):
        if product.id == product_id:
            target_index = index
            break

    # 6. Product doesn't exist
    if target_index is None:
        return []

    # 7. Calculate similarity between products
    similarity_scores = cosine_similarity(
        tfidf_matrix[target_index],
        tfidf_matrix
    ).flatten()

    # 8. Sort products from most similar to least similar
    similar_indices = similarity_scores.argsort()[::-1]

    recommendations = []

    # 9. Pick the best products
    for index in similar_indices:

        # Don't recommend the same product
        if index == target_index:
            continue

        product = products[index]

        recommendations.append({
            "id": product.id,
            "name": product.name,
            "category": product.category,
            "description": product.description,
            "price": float(product.price),
            "similarity_score": round(
                float(similarity_scores[index]), 4
            )
        })

        if len(recommendations) >= top_n:
            break

    return recommendations