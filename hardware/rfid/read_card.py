import time
import spidev

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000
spi.mode = 0

def read_reg(reg):
    result = spi.xfer2([((reg << 1) & 0x7E) | 0x80, 0])
    return result[1]

def write_reg(reg, value):
    spi.xfer2([(reg << 1) & 0x7E, value])

def antenna_on():
    if not read_reg(0x14) & 0x03:
        write_reg(0x14, read_reg(0x14) | 0x03)

try:
    write_reg(0x01, 0x0F)
    time.sleep(0.05)
    write_reg(0x2A, 0x8D)
    write_reg(0x2B, 0x3E)
    write_reg(0x2D, 30)
    write_reg(0x2C, 0)
    write_reg(0x15, 0x40)
    antenna_on()

    print("RC522 ready. Place an RFID card near the reader.")
    print("Press Ctrl+C to stop.")

    while True:
        write_reg(0x0D, 0x07)
        write_reg(0x0A, 0x80)
        write_reg(0x04, 0x00)
        write_reg(0x01, 0x0C)
        write_reg(0x09, 0x26)

        for _ in range(50):
            irq = read_reg(0x04)
            if irq & 0x30:
                break
            if irq & 0x01:
                break
            time.sleep(0.002)

        if read_reg(0x04) & 0x30:
            length = read_reg(0x0A) & 0x07
            if length:
                uid = [read_reg(0x09) for _ in range(length)]
                print("Card data:", " ".join(f"{b:02X}" for b in uid))
                time.sleep(1)

        time.sleep(0.1)

except KeyboardInterrupt:
    print("\nStopped.")

finally:
    spi.close()
