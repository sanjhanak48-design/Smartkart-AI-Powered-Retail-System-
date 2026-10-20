from mfrc522 import SimpleMFRC522
import time

reader = SimpleMFRC522()

print("SmartKart RFID UID test started.")
print("Place an RFID card on the RC522 reader.")
print("Press Ctrl+C to stop.")

try:
    while True:
        print("\nWaiting for card...")
        card_id = reader.read_id()
        print("RFID Card UID:", card_id)
        time.sleep(1)

except KeyboardInterrupt:
    print("\nRFID test stopped.")

finally:
    print("RFID test finished.")
