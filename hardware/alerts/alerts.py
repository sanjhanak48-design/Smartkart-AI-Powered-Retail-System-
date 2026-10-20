"""
SmartKart - LED and Buzzer Alert Module

GREEN LED: Product verified
RED LED + BUZZER: Weight mismatch
"""

import time


def product_verified():
    """Signal that a product has been verified."""
    print("[GREEN LED] Product verified successfully.")


def weight_mismatch():
    """Signal a weight mismatch or possible theft."""
    print("[RED LED] Weight mismatch detected!")
    print("[BUZZER] Alert activated!")


def test_alerts():
    """Software-only test; does not control physical GPIO pins."""
    print("\nSmartKart Alert Module Test")
    print("-" * 30)

    product_verified()
    time.sleep(1)

    weight_mismatch()

    print("-" * 30)
    print("Alert software test completed.")


if __name__ == "__main__":
    test_alerts()
