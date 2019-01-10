'' =================================================================================================
''
''   File....... (HoverDroids) IO Utils.spin
''   Purpose.... Functions for making IO operations a little easier to code
''   Author..... Chris Sprague
''               Copyright (C) 2016 - 2019 Chris Sprague, HoverDroids
''               -- see below for terms of use
''   E-mail..... chris@HoverDroids.com
''   Version History:
''   1.0        24 July 2016
''   1.1         8 Jan  2019
''
'' =================================================================================================
''derived from jm_io_basic.spin

con
  'Universal Propeller Pins

  'Load firmware from PC to RAM or ROM. Else, free. Typically used for PC serially comms
  PCRX = 31     'Receive serial data from PC
  PCTX = 30     'Send serial data to PC

  'I2C Bus. Loads firmware from EEPROM upon startup. It's OK to attach other I2C devices to this bus
  SDA = 29
  SCL = 28

pub null

  ' This is not a top-level object

pub start(pmask, dmask)

'' Setup pins using pins and directions masks
'' EX: pmask = %10000000001000000000100000000010
''     dmask = %11111111111111111111111111111111
''     The above would set all 32 pins to output and set pins 0,10,20,and 30 to high (3.3V)

  outa := pmask
  dira := dmask

pub high(pin)

'' Makes pin output and high

  outa[pin] := 1
  dira[pin] := 1

pub low(pin)

'' Makes pin output and low

  outa[pin] := 0
  dira[pin] := 1

pub toggle(pin)

'' Toggles pin state

  !outa[pin]
  dira[pin] := 1

pub input(pin)

'' Makes pin input and returns current state

  dira[pin] := 0

  return ina[pin]

pub output(pin)

'' Makes pin output and returns current state

  dira[pin] := 1

  return outa[pin]

dat { license }

{{

  Copyright (C) 2016 - 2019 Chris Sprague, HoverDroids

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}
