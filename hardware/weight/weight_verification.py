"""
SmartKart - HX711 Weight Verification
Software simulation; no GPIO hardware access.
"""

ALLOWED_DIFFERENCE_GRAMS = 5.0


def verify_weight(expected_grams, measured_grams):
    difference = abs(expected_grams - measured_grams)

    print(f"Expected weight: {expected_grams:.1f} g")
    print(f"Measured weight: {measured_grams:.1f} g")
    print(f"Difference:      {difference:.1f} g")

    if difference <= ALLOWED_DIFFERENCE_GRAMS:
        print("[GREEN] Weight verified.")
        return True

    print("[RED] Weight mismatch detected!")
    print("[BUZZER] Alert required.")
    return False


def test_weight_verification():
    print("\nSmartKart Weight Verification Test")
    print("-" * 35)

    print("\nTest 1: Normal weight")
    verify_weight(500.0, 497.0)

    print("\nTest 2: Weight mismatch")
    verify_weight(500.0, 450.0)

    print("-" * 35)
    print("Weight verification test completed.")


if __name__ == "__main__":
    test_weight_verification()
