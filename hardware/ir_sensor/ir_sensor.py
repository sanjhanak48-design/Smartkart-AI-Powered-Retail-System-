"""
SmartKart - IR Obstacle Sensor
Software simulation; no GPIO hardware access.
"""


def process_sensor_reading(object_detected):
    if object_detected:
        print("[IR SENSOR] Object detected near the cart/gate.")
        return True

    print("[IR SENSOR] No object detected.")
    return False


def test_ir_sensor():
    print("\nSmartKart IR Sensor Test")
    print("-" * 30)

    process_sensor_reading(False)
    process_sensor_reading(True)

    print("-" * 30)
    print("IR sensor software test completed.")


if __name__ == "__main__":
    test_ir_sensor()
