# hd44780-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the HD44780 LCD

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at ~30kHz (P1: SPIN I2C), 100kHz (P1: PASM I2C, P2)
* Backlight control
* Set cursor visibility mode (block/underscore/blinking/no blinking)
* Set display visibility mode (independent of display RAM contents)
* Set cursor position (*see Limitations, below*)
* Enable/disable processing of control chars at runtime
* Support for alternate I2C addresses

## Requirements

P1/SPIN1:
* spin-standard-library
* For I2C-connected displays: 1 extra core/cog for the PASM PCF8574 driver (none if using the bytecode-based driver)

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.13-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.13-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.13-beta) | NuCode      | OK                    |
| P2        | SPIN2    | FlexSpin (5.9.13-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Cursor position currently hardcoded with 2x16 displays in mind
* No Newline() support

