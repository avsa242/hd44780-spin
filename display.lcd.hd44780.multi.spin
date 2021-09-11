{
    --------------------------------------------
    Filename: display.lcd.hd44780.multi.spin
    Author: Jesse Burt
    Description: Driver for HD44780 alphanumeric LCDs
    Copyright (c) 2021
    Started Sep 06, 2021
    Updated Sep 11, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    TABSTOPS    = 4

' I2C defaults
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000

' HD44780 control signals
    BL          = 1 << 3                        ' backlight
    E           = 1 << 2                        ' enable (clock)
    RW          = 1 << 1                        ' read/write
    RS          = 1                             ' reg. select (data/cmd)

' Character processing mode
    LITERAL     = 0                             ' print chars as-is
    TERM        = 1                             ' process control chars

VAR

    byte _disp_ctrl                             ' disp. control state
    byte _disponoff
    byte _charmode

OBJ

    ioexp:  "io.expander.pcf8574.i2c"           ' 8-bit I/O expander driver
    core:   "core.con.hd44780"                  ' hw-specific low-level const's
    time:   "time"                              ' basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< ioexp#I2C_MAX_FREQ                ' validate pins and bus freq
        if (status := ioexp.startx(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    ioexp.stop{}

PUB Defaults{}
' Set factory defaults

PUB Char(ch) | tmp
' Display single character
    _disp_ctrl |= RS                            ' RS high (data)
    if _charmode == LITERAL
        wr_nib(ch)                              ' MS nibble first
        wr_nib(ch << 4)                         ' LS nibble
    elseif _charmode == TERM
        case ch
            HM:                                 ' -Home:-
                wr_cmd(core#HOME)
                time.msleep(2)                  ' wait for display (1.52ms)
            BEL:                                ' -Bell (flash display):-
                tmp := enablebacklight(-2) ^ 1  ' get current backlight state,
                enablebacklight(tmp)            '   and set the inverse
                time.msleep(50)                 ' short delay for visible blink
                enablebacklight(tmp ^ 1)        ' revert to original state
                wr_cmd(core#CRSDISPSHFT & !core#CRSMOVE & !core#SHIFTL)
            BS, DEL:                            ' -Backspace/Delete:-
                wr_cmd(core#CRSDISPSHFT & !core#CRSMOVE & !core#SHIFTL)
                _disp_ctrl |= RS
                wr_nib(" ")                     ' MS nibble first
                wr_nib(" " << 4)                ' LS nibble
                wr_cmd(core#CRSDISPSHFT & !core#CRSMOVE & !core#SHIFTL)
            TB:                                 ' -Tab:-
                repeat TABSTOPS
                    wr_nib(" ")                 ' MS nibble first
                    wr_nib(" " << 4)            ' LS nibble
            other:                              ' -Printable character:-
                wr_nib(ch)                      ' MS nibble first
                wr_nib(ch << 4)                 ' LS nibble

PUB CharMode(mode): curr_mode
' Set character processing/display mode
'   Valid values:
'      *LITERAL (0):
'           printable characters are displayed
'           control characters are displayed
'       TERM (1):
'           printable characters are displayed
'           control characters are processed
'               (e.g., HM homes display, BS erases previous char, etc)
    case mode
        LITERAL, TERM:
            _charmode := mode
        other:
            return _charmode

PUB Clear{}
' Clear display contents, and set cursor position to 0, 0
    wr_cmd(core#CLEAR)
    time.msleep(5)

PUB CursorMode(mode): curr_mode
' Set cursor mode
'       0: No cursor
'       1: Block, blinking
'       2: Underscore, no blinking
'       3: Underscore, block blinking
'   Any other value returns the current setting
    case mode
        0:
            _disponoff := (_disponoff & core#CRSOFF & core#CRSNOBLINK)
        1:
            _disponoff &= core#CRSOFF
            _disponoff |= core#CRSBLINK
        2:
            _disponoff |= core#CRSON
            _disponoff &= core#CRSNOBLINK
        3:
            _disponoff |= core#CRSON | core#CRSBLINK
        other:
            return (_disponoff & %11)           ' ret both C and B bits

    wr_cmd(core#DISPONOFF | _disponoff)

PUB DisplayVisibility(mode): curr_mode
' Set display visibility
'   OFF (0): display off (display RAM contents unaffected)
'   ON (1): display on
    case mode
        0:
            _disponoff &= core#DISPOFF
        1:
            _disponoff |= core#DISPON
        other:
            return ((_disponoff >> core#DONOFF) & 1)

    wr_cmd(core#DISPONOFF | _disponoff)

PUB EnableBacklight(state)
' Enable backlight, if equipped
    case state
        0:
            _disp_ctrl &= !BL
        1:
            _disp_ctrl |= BL                    ' set backlight bit
        other:
            return ((_disp_ctrl >> 3) & 1)

    _disp_ctrl |= RW                            ' set LCD I/O direction to READ
    wr_nib(%0000)                               '   and send a dummy nibble,
                                                '   just for the backlight bit
    _disp_ctrl &= !RW                           ' set LCD back to WRITE

PUB Position(x, y)
' Set cursor position
    wr_cmd(core#DDRAM_ADDR | ((y * $40) + x))

PUB Reset{}
' Reset display
'   XXX ref. HD44780 datasheet p.45
    time.msleep(15)
    wr_nib(core#FUNCSET | core#IF_8BIT)
    time.msleep(5)
    wr_nib(core#FUNCSET | core#IF_8BIT)
    time.usleep(100)
    wr_nib(core#FUNCSET | core#IF_8BIT)

    wr_nib(core#FUNCSET | core#IF_4BIT)

    wr_cmd(core#FUNCSET | core#IF_4BIT | core#LINES2 | core#FNT8PX)
    wr_cmd(core#DISPONOFF | core#DISPON | core#CRSOFF | core#CRSNOBLINK)
    wr_cmd(core#CLEAR)
    wr_cmd(core#ENTRMD_SET | core#INCR)

PRI Wr_Cmd(cmdb)
' Write 8-bit command, 4 bits at a time
    _disp_ctrl &= !RS                           ' RS low (command)
    wr_nib(cmdb)                                ' MS nibble first
    wr_nib(cmdb << 4)                           ' LS nibble
    time.usleep(1000)

PRI Wr_Nib(nib)
' Write nibble to display and update display control bits
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl)    ' clock low
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl | E)' clock high
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl)    ' clock low

' Pull in standard terminal methods (Bin(), Dec(), Hex(), Str(), etc)
#include "lib.terminal.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
