"""
SmartKart - 16x2 LCD Display
Software simulation; no I2C hardware access.
"""


def show_message(line1="", line2=""):
    """Display two lines, each limited to 16 characters."""
    line1 = str(line1)[:16]
    line2 = str(line2)[:16]

    print("\n[LCD LINE 1] " + line1)
    print("[LCD LINE 2] " + line2)


def show_product(name, price):
    show_message(f"Product: {name}", f"Price: Rs.{price}")


def show_total(total):
    show_message("Total Amount:", f"Rs.{total:.2f}")


def test_display():
    print("SmartKart LCD Display Test")
    print("-" * 30)

    show_message("Welcome to", "SmartKart!")
    show_product("Milk", 60)
    show_total(315.00)

    print("-" * 30)
    print("LCD software test completed.")


if __name__ == "__main__":
    test_display()
