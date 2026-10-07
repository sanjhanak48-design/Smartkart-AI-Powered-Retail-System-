from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer


# ============================================================
# SmartKart AI - Sentiment Analysis Service
# ============================================================

analyzer = SentimentIntensityAnalyzer()


def analyze_sentiment(text: str):
    """
    Analyze customer feedback using VADER sentiment analysis.

    Returns:
        sentiment: positive / negative / neutral
        score: compound sentiment score
        positive_score
        negative_score
        neutral_score
    """

    if not text or not text.strip():
        return {
            "sentiment": "neutral",
            "score": 0.0,
            "positive_score": 0.0,
            "negative_score": 0.0,
            "neutral_score": 1.0,
        }

    scores = analyzer.polarity_scores(text)

    compound = scores["compound"]

    if compound >= 0.05:
        sentiment = "positive"

    elif compound <= -0.05:
        sentiment = "negative"

    else:
        sentiment = "neutral"

    return {
        "sentiment": sentiment,
        "score": round(compound, 4),
        "positive_score": round(scores["pos"], 4),
        "negative_score": round(scores["neg"], 4),
        "neutral_score": round(scores["neu"], 4),
    }