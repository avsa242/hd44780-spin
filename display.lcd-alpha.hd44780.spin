{
----------------------------------------------------------------------------------------------------
    Filename:       display.lcd.hd44780.spin
    Description:    Driver for HD44780 alphanumeric LCDs
    Author:         Jesse Burt
    Started:        Sep 6, 2021
    Updated:        Aug 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O settings; these can be overridden in the parent object }
    SCL         = 28
    SDA         = 29
    I2C_FREQ    = 100_000
    I2C_ADDR    = %000


    TABSTOPS    = 4

' I2C defaults
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    DEF_ADDR    = %000

' HD44780 control signals
    BL          = 1 << 3                        ' backlight
    E           = 1 << 2                        ' enable (clock)
    RW          = 1 << 1                        ' read/write
    RS          = 1                             ' reg. select (data/cmd)

' Character processing mode
    LITERAL     = 0                             ' print chars as-is
    TERM        = 1                             ' process control chars


VAR

    long _pos_x, _pos_y

    byte _disp_ctrl                             ' disp. control state
    byte _disponoff
    byte _charmode

    byte _disp_width, _disp_height
    byte _disp_xmax, _disp_ymax


OBJ

    ioexp:  "io.expander.pcf8574"               ' 8-bit I/O expander driver
    core:   "core.con.hd44780"                  ' hw-specific low-level const's
    time:   "time"                              ' basic timing functions


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom IO pins and I2C bus frequency
'   SCL_PIN: 0..31
'   SDA_PIN: 0..31
'   I2C_HZ: max official is 400_000 (unenforced, YMMV!)
'   ADDR_BITS: %000..%111
'   Returns:
'       cog ID + 1 of the I/O expander driver I2C cog
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := ioexp.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS) )
            time.usleep(core.T_POR)             ' wait for device startup
            pos_xy(0, 0)
            set_dims(2, 16)
            return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE


PUB stop()
' Stop the driver
    ioexp.stop()


PUB defaults()
' Set factory defaults


PUB backlight_ena(state)
' Enable backlight, if equipped
    if ( state )
        _disp_ctrl |= BL                    ' set backlight bit
    else
        _disp_ctrl &= !BL

    _disp_ctrl |= RW                            ' set LCD I/O direction to READ
    wr_nib(%0000)                               '   and send a dummy nibble,
                                                '   just for the backlight bit
    _disp_ctrl &= !RW                           ' set LCD back to WRITE


PUB charmode = char_mode
PUB char_mode(mode)
' Set character processing/display mode
'   Valid values:
'      *LITERAL (0):
'           printable characters are displayed
'           control characters are displayed
'       TERM (1):
'           printable characters are displayed
'           control characters are processed
'               (e.g., HM homes display, BS erases previous char, etc)
    _charmode := (LITERAL #> mode <# TERM)


PUB clear()
' Clear display contents, and set cursor position to 0, 0
    wr_cmd(core.CLEAR)
    time.msleep(5)


PUB cursor_mode(mode)
' Set cursor mode
'       0: No cursor
'       1: Block, blinking
'       2: Underscore, no blinking
'       3: Underscore, block blinking
'   Any other value returns the current setting
    case mode
        0:
            _disponoff := (_disponoff & core.CRSOFF & core.CRSNOBLINK)
        1:
            _disponoff &= core.CRSOFF
            _disponoff |= core.CRSBLINK
        2:
            _disponoff |= core.CRSON
            _disponoff &= core.CRSNOBLINK
        3:
            _disponoff |= core.CRSON | core.CRSBLINK
        other:
            return

    wr_cmd(core.DISPONOFF | _disponoff)


' tell the common terminal I/O routines not to define a generic newline(); we have our own:
#define _HAS_NEWLINE_

PUB newline()
' Move the cursor to the beginning of the next line
    _pos_x := 0
    _pos_y++
    if ( _pos_y > _disp_ymax )
        _pos_y := 0
    pos_xy(_pos_x, _pos_y)


PUB position = pos_xy
PUB pos_xy(x, y)
' Set cursor position
    case y
        0, 1:
            wr_cmd(core.DDRAM_ADDR | ((y * $40) + x))
        2, 3:
            wr_cmd(core.DDRAM_ADDR | (($14 + (y * $40)) + x))

    _pos_x := x
    _pos_y := y


PUB tx = putchar
PUB char = putchar
PUB putchar(ch) | tmp
' Display single character
    _disp_ctrl |= RS                            ' RS high (data)
    if ( _charmode == LITERAL )
        wr_nib(ch)                              ' MS nibble first
        wr_nib(ch << 4)                         ' LS nibble
    elseif ( _charmode == TERM )
        case ch
            CR:
                pos_xy(0, _pos_y)
                return
            LF:
                _pos_y++
                if ( _pos_y > _disp_ymax )
                    _pos_y := 0
                pos_xy(_pos_x, _pos_y)
                return
            HM:                                 ' -Home:-
                wr_cmd(core.HOME)
                time.msleep(2)                  ' wait for display (1.52ms)
                return
            BEL:                                ' -Bell (flash display):-
                tmp := backlight_ena(-2) ^ 1    ' get current backlight state,
                backlight_ena(tmp)              '   and set the inverse
                time.msleep(50)                 ' short delay for visible blink
                backlight_ena(tmp ^ 1)          ' revert to original state
                wr_cmd(core.CRSDISPSHFT & !core.CRSMOVE & !core.SHIFTL)
                return
            BS, DEL:                            ' -Backspace/Delete:-
                wr_cmd(core.CRSDISPSHFT & !core.CRSMOVE & !core.SHIFTL)
                _disp_ctrl |= RS
                wr_nib(" ")                     ' MS nibble first
                wr_nib(" " << 4)                ' LS nibble
                wr_cmd(core.CRSDISPSHFT & !core.CRSMOVE & !core.SHIFTL)
                return
            TB:                                 ' -Tab:-
                repeat TABSTOPS
                    wr_nib(" ")                 ' MS nibble first
                    wr_nib(" " << 4)            ' LS nibble
                return
            other:                              ' -Printable character:-
                wr_nib(ch)                      ' MS nibble first
                wr_nib(ch << 4)                 ' LS nibble

        _pos_x++
        if ( _pos_x > _disp_xmax )
            _pos_x := 0
            _pos_y++
            if ( _pos_y > _disp_ymax )          ' wrap around
                _pos_x := _pos_y := 0


PUB reset()
' Reset display
'   XXX ref. HD44780 datasheet p.45
    time.msleep(15)
    wr_nib(core.FUNCSET | core.IF_8BIT)
    time.msleep(5)
    wr_nib(core.FUNCSET | core.IF_8BIT)
    time.usleep(100)
    wr_nib(core.FUNCSET | core.IF_8BIT)

    wr_nib(core.FUNCSET | core.IF_4BIT)

    wr_cmd(core.FUNCSET | core.IF_4BIT | core.LINES2 | core.FNT8PX)
    wr_cmd(core.DISPONOFF | core.DISPON | core.CRSOFF | core.CRSNOBLINK)
    wr_cmd(core.CLEAR)
    wr_cmd(core.ENTRMD_SET | core.INCR)


PUB set_dims(width, height)
' Set display dimensions
    _disp_width := 16 #> width <# 20
    _disp_height := 2 #> height <# 4
    _disp_xmax := _disp_width-1
    _disp_ymax := _disp_height-1


PUB visibility(mode)
' Set display visibility
'   OFF (0): display off (display RAM contents unaffected)
'   ON (1): display on
    if ( mode )
        _disponoff |= core.DISPON
    else
        _disponoff &= core.DISPOFF

    wr_cmd(core.DISPONOFF | _disponoff)


PRI wr_cmd(cmdb)
' Write 8-bit command, 4 bits at a time
    _disp_ctrl &= !RS                           ' RS low (command)
    wr_nib(cmdb)                                ' MS nibble first
    wr_nib(cmdb << 4)                           ' LS nibble
    time.usleep(1000)                           ' inter-cmd delay


PRI wr_nib(nib)
' Write nibble to display and update display control bits
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl)    ' clock low
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl | E)' clock high
    ioexp.wr_byte( (nib & $f0) | _disp_ctrl)    ' clock low

' Pull in standard terminal methods (putbin(), putdec(), puthex(), puts(), etc)
#include "terminal.common.spinh"


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

