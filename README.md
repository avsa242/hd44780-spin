# hd44780-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the HD44780 LCD

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to ~100kHz
* Backlight control

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM PCF8573 driver (for I2C-connected types)

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81), FlexSpin (tested with 6.0.0-beta)
* ~~P2/SPIN2: FlexSpin (tested with 6.0.0-beta)~~ _(not implemented yet)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* May require lower bus speed than specified maximum in order to operate reliably

## TODO

- [ ] add support for controlling blinking, cursor control, display visibility
- [ ] add support for custom characters
- [ ] add support for LCDs with other interface types (UART, SPI, Parallel)
