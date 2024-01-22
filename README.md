# hd44780-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the HD44780 LCD

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* I2C connection at ~30kHz (P1: SPIN I2C), 100kHz (P1: PASM I2C, P2)
* Backlight control
* Set cursor visibility mode (block/underscore/blinking/no blinking)
* Set display visibility mode (independent of display RAM contents)
* Set cursor position
* Enable/disable processing of control chars at runtime
* Support for alternate I2C addresses


## Requirements

P1/SPIN1:
* spin-standard-library
* PCF8574 driver (provided by the spin-standard-library)
* For I2C-connected displays: 1 extra core/cog for the PASM PCF8574 driver (none if using the bytecode-based driver)
* terminal.common.spinh (provided by the spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* PCF8574 driver (provided by the p2-spin-standard-library)
* terminal.common.spin2h (provided by the p2-spin-standard-library)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.8.0)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.8.0)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.8.0)       | NuCode       | OK                    |
| P2        | SPIN2    | FlexSpin (6.8.0)       | Native/PASM2 | OK                    |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* Very early in development - may malfunction, or outright fail to build

