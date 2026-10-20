import time
import spidev

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000
spi.mode = 0

def read_reg(reg):
    return spi.xfer2([((reg << 1) & 0x7E) | 0x80, 0])[1]

print("RC522 SPI check")
print("Reader version:", hex(read_reg(0x37)))
print("This checks reader communication only.")
spi.close()
