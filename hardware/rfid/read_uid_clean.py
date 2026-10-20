from mfrc522 import SimpleMFRC522
import time

reader = SimpleMFRC522()

print("SmartKart RFID UID Test")
print("Hold one card near the reader.")
print("Press Ctrl+C to stop.")

last_uid = None

try:
    while True:
        uid, text = reader.read()
        if uid != last_uid:
            print(f"RFID UID: {uid}")
            last_uid = uid
        time.sleep(1)

except KeyboardInterrupt:
    print("\nTest stopped.")

finally:
    reader.READER.GPIO.cleanup()
