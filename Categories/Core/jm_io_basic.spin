{{
OBEX LISTING:
  http://obex.parallax.com/object/703

  By: Jon McPhalen, created: 2013-08-02 | updated: 2016-01-09
  Driver for controlling WS2812 LEDs and WS2811 driver chips. Set-and-forget with auto refreshing facilitate LED color animation projects.
  Updated 08-SEP-2013: Corrected constant value for WHITE in object.
  Updated 17-AUG-2013: Original post had type on object code.
  Updated 24-AUG-2014: Added new start methods which allow user to specify bit timing. Simplified PASM code for swapping R & G channels.
  Updates 09-JAN-2016: Added reset timing to start() methods to allow longer inactive time between string updates. This can be helpful for very long strings where constant updating may cause interference with odd color shifts.
  Archive includes standard and single-shot objects and demos.

}}
'' =================================================================================================
''
''   File....... jm_io_basic.spin
''   Purpose.... Basic IO control
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (C) 2014-2015 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 12 MAY 2015
''
'' =================================================================================================


con { fixed io pins }

  RX1 = 31                                                      ' serial / programming  
  TX1 = 30
  
  SDA = 29                                                      ' i2c / eeprom
  SCL = 28


pub null

  ' This is not a top-level object
  

pub start(pmask, dmask)

'' Setup pins using pins and directions masks

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


dat { license }

{{

  Copyright (C) 2014-2015 Jon McPhalen 

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
