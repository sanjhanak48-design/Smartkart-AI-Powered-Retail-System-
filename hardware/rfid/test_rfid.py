import spidev
import time

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000
spi.mode = 0

def read_register(address):
    response = spi.xfer2([((address << 1) & 0x7E) | 0x80, 0x00])
    return response[1]

try:
    version = read_register(0x37)
    print(f"RC522 version register: 0x{version:02X}")

    if version in (0x82, 0x88, 0x91, 0x92):
        print("RC522 is responding over SPI.")
    else:
        print("Unexpected version. Check wiring and power.")

finally:
    spi.close()
