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
''   File....... jm_ws2812_demo.spin
''   Purpose.... WS2812/B demonstration program
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2014-2016 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 04 JAN 2016
''
'' =================================================================================================


con { timing }

  _clkmode = xtal1 + pll16x                                     
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = (_clkmode >> 6) * _xinfreq                         ' system freq as a constant
  MS_001   = CLK_FREQ / 1_000                                   ' ticks in 1ms
  US_001   = CLK_FREQ / 1_000_000                               ' ticks in 1us
  

con { io pins }

  RX1  = 31                                                     ' programming / terminal
  TX1  = 30
  
  SDA  = 29                                                     ' eeprom / i2c
  SCL  = 28

  LEDS = 1                                                     ' LED tx pin    ..started at 15


con

  STRIP_LEN = 384
            

obj

' main                                                          ' * master Spin cog
  time  : "jm_time"                                             '   timing and delays
  io    : "jm_io_basic"                                         '   essential io
  strip : "jm_ws2812"                                           ' * WS2812 LED driver
                                                                 
' * uses cog when loaded                                         
                                                                 

var


dat

  Chakras       long    strip#RED, strip#ORANGE, strip#YELLOW 
                long    strip#GREEN, strip#BLUE, strip#INDIGO


pub main | pos

  setup

  repeat 3
    color_wipe_side($20_00_00,10)                                 'Light each pixel from 1 to n with the given color
    color_wipe_side($00_00_20,10)
    color_wipe_side($00_20_00,10)
  '  color_wipe($20_00_00, 25)                                  'Red
  '  color_wipe($00_20_00, 25)                                  'Green
  '  color_wipe($00_00_20, 25)                                  'Blue
    
  'repeat
  '  repeat pos from 0 to 255                                   'Rainbow effects
  '    strip.set_all(strip.wheelx(pos, $1A))                     'brightness; 1/4 = 40; 1/10 = 1A; do pct*255 and convert to hex
  '    time.pause(20)
      

pub color_chase(p_colors, len, ms) | base, idx, ch

'' Performs color chase 

  repeat base from 0 to len-1                                   ' do all colors in table
    idx := base                                                 ' start at base
    repeat ch from 0 to strip.num_pixels-1                      ' loop through connected leds
      strip.set(ch, long[p_colors][idx])                        ' update channel color 
      if (++idx == len)                                         ' past end of list?
        idx := 0                                                ' yes, reset
   
    time.pause(ms)                                              ' set movement speed


pub setup                                                        
                                                                 
'' Setup IO and objects for application                          
                                                                 
  time.start                                                    ' setup timing & delays
                                                                 
  io.start(0, 0)                                                ' clear all pins (master cog)

  strip.start_b(LEDS, STRIP_LEN, 2_0, true)                     ' start led driver (2ms reset period)
  strip.off
                                                                 
   
con

  ' Routines ported from C code by Phil Burgess (www.paintyourdragon.com)


pub color_wipe(rgb, ms) | ch

'' Sequentially fills strip with color rgb
'' -- ms is delay between pixels, in milliseconds

  repeat ch from 0 to strip.num_pixels-1 
    strip.set(ch, rgb)
    time.pause(ms)

pub color_wipe_side(rgb, ms) | ch

'' Sequentially fills strip with color rgb
'' -- ms is delay between pixels, in milliseconds

  repeat ch from 0 to 63 
    strip.set(ch, rgb)
    strip.set(ch + 64, rgb)
    strip.set(ch + 128, rgb)
    strip.set(ch + 192, rgb)
    strip.set(ch + 256, rgb)
    strip.set(ch + 320, rgb)
    time.pause(ms)
    
pub rainbow(ms) | pos, ch

  repeat pos from 0 to 255
    repeat ch from 0 to strip.num_pixels-1
      strip.set(ch, strip.wheel((pos + ch) & $FF))
    time.pause(ms)
    

pub rainbow_cycle(ms) | pos, ch 

  repeat pos from 0 to (255 * 5)
    repeat ch from 0 to strip.num_pixels-1
      strip.set(ch, strip.wheel(((ch * 256 / strip.num_pixels) + pos) & $FF))
    time.pause(ms)
    

dat { license }

{{

  Copyright (c) 2014-2016 Jon McPhalen  

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
