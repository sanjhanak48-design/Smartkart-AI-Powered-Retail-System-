"""
SmartKart - Raspberry Pi API Client
"""

import os
import requests

BASE_URL = os.getenv(
    "SMARTKART_API_URL",
    "http://127.0.0.1:8000"
)


def check_backend():
    """Check whether the SmartKart backend is reachable."""
    try:
        response = requests.get(
            f"{BASE_URL}/openapi.json",
            timeout=5
        )
        response.raise_for_status()
        print("[API] SmartKart backend is reachable.")
        return True

    except requests.RequestException as error:
        print(f"[API] Backend connection failed: {error}")
        return False


def get_product(product_id):
    """Fetch a product by its ID."""
    try:
        response = requests.get(
            f"{BASE_URL}/products/{product_id}",
            timeout=5
        )
        response.raise_for_status()
        return response.json()

    except requests.RequestException as error:
        print(f"[API] Could not fetch product: {error}")
        return None


if __name__ == "__main__":
    print("SmartKart API Client Test")
    print("Backend URL:", BASE_URL)
    check_backend()
