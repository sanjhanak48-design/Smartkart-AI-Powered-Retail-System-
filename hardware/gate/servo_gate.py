"""
SmartKart - Servo Exit Gate
Software-only simulation; no GPIO or servo movement.
"""

import time


def open_gate(payment_status):
    """Open the gate only when payment is confirmed."""
    if payment_status != "PAID":
        print("[GATE] Payment not confirmed. Gate remains CLOSED.")
        return False

    print("[GATE] Payment verified.")
    print("[SERVO] Gate OPEN (90 degrees).")
    time.sleep(2)
    print("[SERVO] Gate CLOSED (0 degrees).")
    return True


def test_gate():
    print("\nSmartKart Gate Module Test")
    print("-" * 30)

    open_gate("PENDING")
    print()
    open_gate("PAID")

    print("-" * 30)
    print("Gate software test completed.")


if __name__ == "__main__":
    test_gate()
