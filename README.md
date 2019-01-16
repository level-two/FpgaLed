# FpgaLed

This project was created for fun for Spartan6. It displays Tux on led strip row-by-row and it can be visualized using shaked camera
Project contains several modules:
- WS2812 led driver
- Simple buffer manager (allocation and release)
- Spi slave
- Image receiver
- Wishbone interface for all submodules
- Wishbone NIC with round-robin arbiter
