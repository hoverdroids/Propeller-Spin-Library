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
''   File....... jm_ws2812_ss.spin
''   Purpose.... Single-shot 800kHz driver for WS2812/WS2812B LEDs
''   Author..... Jon "JonnyMac" McPhalen
''               Copyright (c) 2013-16 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 
''   Updated.... 09 JAN 2016
''
'' =================================================================================================

{ -------------------------------------- }
{  NOTE: Requires system clock >= 80MHz  }
{        Use .execute() to update LEDs   }
{ -------------------------------------- }


con { standard io }

  RX1 = 31                                                      ' programming / terminal
  TX1 = 30
  
  SDA = 29                                                      ' eeprom / i2c
  SCL = 28

  
con { pixel limit }

  MAX_PIXELS = 256 


con { rgb colors }

  ' borrowed from Gavin Garner's TM1804 LED driver
  ' -- additional colors by Lachlan   
  ' -- some alterations by JM

  '             RR GG BB
  BLACK      = $00_00_00
  RED        = $FF_00_00
  GREEN      = $00_FF_00
  BLUE       = $00_00_FF
  WHITE      = $FF_FF_FF
  CYAN       = $00_FF_FF
  MAGENTA    = $FF_00_FF
  YELLOW     = $FF_FF_00
  CHARTREUSE = $7F_FF_00
  ORANGE     = $FF_60_00
  AQUAMARINE = $7F_FF_D4
  PINK       = $FF_5F_5F
  TURQUOISE  = $3F_E0_C0
  REALWHITE  = $C8_FF_FF
  INDIGO     = $3F_00_7F
  VIOLET     = $BF_7F_BF
  MAROON     = $32_00_10
  BROWN      = $0E_06_00
  CRIMSON    = $DC_28_3C
  PURPLE     = $8C_00_FF
  

var

  long  cog

  long  command                                                 ' command to cog
  long  striplen                                                ' pixels in strip(s)

  long  resetticks                                              ' ticks in reset period
  long  t0h                                                     ' bit0 high time (ticks)      
  long  t0l                                                     ' bit0 low time
  long  t1h                                                     ' bit1 high time
  long  t1l                                                     ' bit1 low time

  long  rgbbuf[MAX_PIXELS]                                      ' rgb buffer
  
    
pub start(pixels)

'' Start WS2812 single-shot LED driver
'' -- pixels is # of RGB LEDs in strip

  return startx(pixels, 350, 800, 700, 600)                     ' standard WS2812 timing
  

pub start_b(pixels)

'' Start WS2812 single-shot LED driver for WS2812B LEDs
'' -- pixels is # of RGB LEDs in strip
                                                                        
  return startx(pixels, 350, 900, 900, 350)                     ' WS2812B timing
  

pub startx(pixels, ns0h, ns0l, ns1h, ns1l) | ustix   

'' Start WS2812/WS2812B LED driver
'' -- pixels is # of RGB LEDs in strip 
'' -- ns0h is 0-bit high timing (ns)
'' -- ns0l is 0-bit low timing (ns)
'' -- ns1h is 1-bit high timing (ns)
'' -- ns1l is 1-bit low timing (ns)

  stop                                                          ' stop if running

  if (clkfreq < 80_000_000)                                     ' requires 80MHz clock
    return 0

  striplen := 1 #> pixels <# MAX_PIXELS                         ' limit led count
    
  ustix := clkfreq / 1_000_000                                  ' ticks in 1us

  ' set timing parameters

  resetticks := ustix * 50                                      ' 50.00us min reset timing
  t0h        := ustix * ns0h / 1000                             ' set pulse timing values
  t0l        := ustix * ns0l / 1000
  t1h        := ustix * ns1h / 1000
  t1l        := ustix * ns1l / 1000

  command := @resetticks                                        ' point to parameters
  
  cog := cognew(@ws2812ss, @command) + 1                        ' start the cog

  repeat while (busy)                                           ' let cog initialize

  return cog


pub stop

'' Stops WS2812 cog (if running)

  if (cog)
    cogstop(cog - 1)
    cog := 0

  off(@rgbbuf)                                                  ' clear internal buffer


pub execute(pin, count, p_buf) | cmd

'' Executes update of WS2812 string attached to pin
'' -- count is # LEDs to update (-1 for all, or 1 to 256)
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if ((pin < 0) or (pin > 27))                                  ' protect RX1, TX1, I2C pins
    return
  else
    cmd.byte[0] := pin

  if (count =< 0)
    cmd.byte[1] := striplen - 1                                 ' update entire strip 
  else
    cmd.byte[1] := (count <# striplen) - 1

  if (p_buf < 0)
    cmd.word[1] := @rgbbuf                                      ' use internal buffer
  else
    cmd.word[1] := p_buf                                        ' use external buffer

  repeat while (busy)                                           ' let previous command finish
  
  command := cmd                                                ' update strip

  return cmd
  

pub busy

'' Returns true if WS2812 cog is tx-ing rgb data

  return (command <> 0)
    

pub num_pixels

'' Returns number of RGB pixels in string(s)

  return striplen
  
  
pub color(r, g, b) : rgb

'' Packs r-g-b bytes into long
     
  rgb.byte[2] := r                                              ' r << 16
  rgb.byte[1] := g                                              ' g << 8
  rgb.byte[0] := b                                              ' b << 0


pub colorx(r, g, b, level)

'' Packs r-g-b bytes into long
'' -- level (0 to 255) used to adjust brightness (0 to 100%)

  if (level =< 0)
    return $00_00_00
    
  elseif (level => 255)
    return color(r, g, b)
    
  else
    r := r * level / 255                                        ' apply level to rgb   
    g := g * level / 255        
    b := b * level / 255        
    return color(r, g, b) 


pub wheel(pos)

'' Creates color from 0 to 255 position input
'' -- colors transition r->g->b back to r

  if (pos < 85)
    return color(255-pos*3, pos*3, 0)
  elseif (pos < 170)
    pos -= 85
    return color(0, 255-pos*3, pos*3)
  else
    pos -= 170
    return color(pos*3, 0, 255-pos*3)


pub wheelx(pos, level)

'' Creates color from 0 to 255 position input
'' -- colors transition r-g-b back to r
'' -- level is brightness, 0 to 255

  if (pos < 85)
    return colorx(255-pos*3, pos*3, 0, level)
  elseif (pos < 170)
    pos -= 85
    return colorx(0, 255-pos*3, pos*3, level)
  else
    pos -= 170
    return colorx(pos*3, 0, 255-pos*3, level)

 
pub set(ch, rgb, p_buf)

'' Writes rgb value to channel ch in buffer
'' -- rgb is packed long in form $RR_GG_BB
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if ((ch => 0) and (ch < striplen))
    if (p_buf < 0)
      rgbbuf[ch] := rgb
    else
      long[p_buf][ch] := rgb


pub setx(ch, rgb, level, p_buf)

'' Writes scaled rgb value to channel ch in buffer
'' -- rgb is packed long in form $RR_GG_BB
'' -- level is brightness, 0 to 255

  if ((ch => 0) and (ch < striplen))
    if (p_buf < 0)
      rgbbuf[ch] := scale_rgb(rgb, level)  
    else
      long[p_buf][ch] := scale_rgb(rgb, level)  


pub scale_rgb(rgb, level)

  if (level =< 0)
    return $00_00_00
    
  elseif (level < 255)
    rgb.byte[2] := rgb.byte[2] * level / 255
    rgb.byte[1] := rgb.byte[1] * level / 255 
    rgb.byte[0] := rgb.byte[0] * level / 255 
  
  return rgb  
    

pub set_rgb(ch, r, g, b, p_buf)

'' Writes rgb elements to channel ch in buffer
'' -- r, g, and b are byte values, 0 to 255
'' -- p_buf is address of rgb buffer (use -1 for internal)

  set(ch, color(r, g, b), p_buf)


pub set_red(ch, level, p_buf)

'' Sets red led level of selected channel
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if (p_buf < 0)                                                ' use internal? 
    p_buf := @rgbbuf

  if ((ch => 0) and (ch < MAX_PIXELS))
    byte[p_buf][(ch << 2) + 2] := 0 #> level <# 255
      

pub set_green(ch, level, p_buf)       

'' Sets green led level of selected channel
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if (p_buf < 0)     
    p_buf := @rgbbuf

  if ((ch => 0) and (ch < MAX_PIXELS))
    byte[p_buf][(ch << 2) + 1] := 0 #> level <# 255
 

pub set_blue(ch, level, p_buf)       

'' Sets blue led level of selected channel
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if (p_buf < 0)     
    p_buf := @rgbbuf

  if ((ch => 0) and (ch < MAX_PIXELS))    
    byte[p_buf][(ch << 2) + 0] := 0 #> level <# 255  

    
pub set_all(rgb, p_buf)

'' Sets all channels to rgb
'' -- rgb is packed long in form $RR_GG_BB
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if (p_buf < 0)     
    p_buf := @rgbbuf

  longfill(p_buf, rgb, striplen)
    
    
pub fill(first, last, rgb, p_buf) | swap

'' Fills first through last channels with rgb
'' -- rgb is packed long in form $RR_GG_BB
'' -- p_buf is address of rgb buffer (use -1 for internal)

  first := 0 #> first <# striplen-1
  last  := 0 #> last  <# striplen-1

  if (first > last)
    swap  := first
    first := last
    last  := swap

  if (p_buf < 0)     
    p_buf := @rgbbuf
    
  longfill(p_buf, rgb, last-first+1)
    

pub off(p_buf)

'' Turns off all LEDs
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if (p_buf < 0)     
    p_buf := @rgbbuf

  longfill(p_buf, $00_00_00, striplen)
    

pub read(ch, p_buf)

'' Returns color of channel
'' -- p_buf is address of rgb buffer (use -1 for internal)

  if ((ch => 0) and (ch < striplen))                          ' valid?
    if (p_buf < 0)
      return rgbbuf[ch]
    else
      return long[p_buf][ch]
  else
    return 0

  
pub address

'' Returns address of color array

  return @rgbbuf


pub transfer(p_src, n)

'' Transfter n longs from p_src to internal rgb buffer

  longmove(@rgbbuf, p_src, n)
  

pub running

'' Returns > 0 if running

  return cog
 

dat { single-shot ws2812 driver }

                        org     0

ws2812ss                rdlong  r1, par                         ' hub address of parameters -> r1
                        movd    :read, #resettix                ' location of cog parameters -> :read(dest)
                        mov     r2, #5                          ' get 5 parameters
:read                   rdlong  0-0, r1                         ' copy parameter from hub to cog
                        add     r1, #4                          ' next hub element
                        add     :read, INC_DEST                 ' next cog element                         
                        djnz    r2, #:read                      ' done?

reset_delay             mov     bittimer, resettix              ' set reset timing  
                        add     bittimer, cnt                   ' sync timer 
                        waitcnt bittimer, #0                    ' let timer expire                             

clear_cmd               mov     r1, #0                          ' clear last command
                        wrlong  r1, par

get_cmd                 rdlong  r1, par                 wz      ' look for packed command
        if_z            jmp     #get_cmd

                        mov     r2, r1                          ' get pin
                        and     r2, #$1F                        ' isolate
                        mov     txmask, #1                      ' create mask for tx
                        shl     txmask, r2
                        andn    outa, txmask                    ' set to output low
                        or      dira, txmask

                        mov     nleds, r1                       ' get count
                        shr     nleds, #8                       ' isolate
                        and     nleds, #$FF                        
                        add     nleds, #1                       ' update (1 to 256 leds)

                        mov     addr, r1                        ' get hub address
                        shr     addr, #16                       ' isolate


frame_loop              rdlong  colorbits, addr                 ' read a channel
                        add     addr, #4                        ' point to next
                        

' Correct placement of color bytes for WS2812
'   $RR_GG_BB --> $GG_RR_BB

fix_colors              mov     r1, colorbits                   ' copy for red
                        mov     r2, colorbits                   ' copy for green
                        and     colorbits, HX_0000FF            ' isolate blue
                        shr     r1, #8                          ' fix red pos (byte1)
                        and     r1, HX_00FF00                   ' isolate red
                        or      colorbits, r1                   ' add red back in
                        shl     r2, #8                          ' fix green pos (byte2)
                        and     r2, HX_FF0000                   ' isolate green
                        or      colorbits, r2                   ' add green back in

                        
' Shifts long in colorbits to WS2812 chain
'
'  WS2812 Timing 
'
'  0       0.35us / 0.80us
'  1      0.70us / 0.60us
'
'  WS2812B Timing
'
'  0       0.35us / 0.90us
'  1       0.90us / 0.35us
'
'  At least 50us (reset) between frames

shift_out               shl     colorbits, #8                   ' left-justify bits
                        mov     nbits, #24                      ' shift 24 bits (3 x 8) 

:loop                   rcl     colorbits, #1           wc      ' msb --> C
        if_c            mov     bittimer, bit1hi                ' set bit timing  
        if_nc           mov     bittimer, bit0hi                
                        or      outa, txmask                    ' tx line 1  
                        add     bittimer, cnt                   ' sync bit timer  
        if_c            waitcnt bittimer, bit1lo                
        if_nc           waitcnt bittimer, bit0lo 
                        andn    outa, txmask                    ' tx line 0             
                        waitcnt bittimer, #0                    ' hold while low
                        djnz    nbits, #:loop                   ' next bit

                        djnz    nleds, #frame_loop              ' done with all leds?

                        jmp     #reset_delay                    ' back to top  

' --------------------------------------------------------------------------------------------------

INC_DEST                long    1 << 9                          ' to increment D field 

HX_0000FF               long    $0000FF                         ' byte masks
HX_00FF00               long    $00FF00
HX_FF0000               long    $FF0000
                       
resettix                res     1                               ' frame reset timing
bit0hi                  res     1                               ' bit0 high timing
bit0lo                  res     1                               ' bit0 low timing
bit1hi                  res     1                               ' bit1 high timing    
bit1lo                  res     1                               ' bit1 low timing
                         
bittimer                res     1                               ' timer for reset/bit
                         
txmask                  res     1                               ' mask for tx output
nleds                   res     1                               ' # of channels to process
addr                    res     1                               ' address of current rgb bit
                         
colorbits               res     1                               ' rgb for current channel
nbits                   res     1                               ' # of bits to process
                         
r1                      res     1                               ' work vars
r2                      res     1
r3                      res     1
                         
                        fit     496                                    
                         
                        
dat { license }

{{

  Copyright (c) 2013-16 Jon McPhalen

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
