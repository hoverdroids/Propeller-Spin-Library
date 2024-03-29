{{
Source: http://www.rayslogic.com/propeller/Programming/AdafruitRGB/AdafruitRGB.htm
}}
'32x16 LED Matrix Graphics routines in Spin and Assembly
'Rev. 3.0   
'Note the small font is stored as 5x8 but drawn as 6x8 to give seperation between characters
'The regular Parallax Text functions:  hex, bin, dec, out, str should work as expected with the 5x8 font
'Some routines are now implemented in assembly for faster speed

'Note: The Assembly setpixel routine is a bit complex due to the way the display memory is organized

' Copyright (c) 2011 Rayslogic.com, LLC
' See end of file for terms of use.

VAR  'Configuration variables passed here from main routine
  long balance  'variable to scale input RGB values for color balance  
  long Intensity 'variable to reduce brightness by modulating the enable pin  (0..31)
  long BasePin[3]   'starting pin of three panels
  long EnablePin456  'reserved
  long pOutputArray  'pointer to precalculated array of outputs
  long Arrangement 'organization of panels
  'Extra variables for assembly driver
  long pGammaR 'address of red gamma table
  long pGammaG 'address of green gamma table
  long pGammaB 'address of blue gamma table
  long pFont5x8  'address of 5x8 font

VAR 'Variables for assembly drivers  
  long cog, command

VAR 'Balanced Gamma look up tables  
  byte GammaR[256]
  byte GammaG[256]
  byte GammaB[256]

VAR 'Variables to support the standard text output commands, bin, hex, dec, and out
  long row, col, rows, cols, flag, forecolor, backcolor
  long  colors[8 * 2] '8 possible sets of forecolor and backcolor
  long nPanels   


CON  'Some standard colors in regular 24-bit RGB format
  red=      255<<16 +  0<<8 +  0
  blue=       0<<16 +  0<<8 +255
  green=      0<<16 +255<<8 +  0
  black=      0<<16 +  0<<8 +  0
  white=    255<<16 +255<<8 +255
  dk_blue=    0<<16 +  0<<8 + 64        
  yellow=   255<<16 +255<<8 +  0

CON
  'Enumerate assembly driver commands
  #1, UpdateConfig, AsmSetPixel, DrawLimitedChar, AsmShowBitmap, AsmShowBitmap4bpp 
                
PUB Start(pSettings):okay|i      'Initialize graphics and start assembly cog
  'retrieve settings from caller
  longmove(@balance,pSettings,8)

  'initialize output
  InitializeOutputArray

  'Calculate Balanced Gamma look up tables
  UpdateGammas

  'Point assembly to font table
  pFont5x8:=@Font5x8
  
  'start graphics support cog2
  stop  'Stop any running cogs
  command:=UpdateConfig<<16+@balance  'copy settings when starting cog
  okay := cog := cognew(@init, @command) + 1

  'Position text cursor to upper left corner
  nPanels:=3  'you may want to change this to 2 or 1 if you have less panels
  colors[0]:=yellow
  colors[1]:=dk_blue
  forecolor:=colors[0]
  backcolor:=colors[1]
  row:=col:=0
  out(0) 'clear screen
  nPanels:=1 'calculate number of panels from assigned pin numbers (negative if not present)
  if BasePin[1]>0
     nPanels:=2
     if BasePin[2]>0
        nPanels:=3 
  case arrangement
    0:  'side-by-side landscape
        cols:=32*3/5'32*nPanels/5
        rows:=32/8'16/8
            
  return

PUB Stop   '' Stop assembly support driver - frees a cog
    if cog
       cogstop(cog~ - 1)

PRI UpdateGammas|i,r,g,b    'calculate the balanced gamma tables for each color
  pGammaR:=@GammaR
  pGammaG:=@GammaG
  pGammaB:=@GammaB
  r:=GetRValue(balance)
  b:=GetBValue(balance)
  g:=GetGValue(balance)
  repeat i from 0 to 255
    GammaR[i]:=Gamma[i]*r/255
    GammaG[i]:=Gamma[i]*g/255
    GammaB[i]:=Gamma[i]*b/255
    

PRI InitializeOutputArray|i, j, k, section, bit,bits, c0, Pin_A, Pin_EN
  'Fill in the address and enable bits into the precalculated output array
  
  Pin_A:=BasePin[0]+6
  Pin_EN:=BasePin[0]+11
  
  'precalculate initial outputs
  repeat section from 0 to 7
    repeat bits from 0 to 7 
      repeat bit from 0 to 63'31
        i:=section*64*8+bits*64+bit 'section*32*8+bits*32+bit
        long[pOutputArray][i]:=0  'init to zero (probably not required)
        if bits==0
          k:=section-1
        else
          k:=section
        if k<0
           k:=7
 
        long[pOutputArray][i]|=k<<Pin_A  'set the section bits

        if (bit>>1)=>Intensity  'disable display on last bit, before latch
           long[pOutputArray][i]|=1<<Pin_EN  
  
PUB ShowBitmap(x0,y0,pBmp)|p,x,y,w,h,s,c,i,j,d    'Show a bitmap

  'This needs to be sped up with assembly code!
  'Read bitmap header
   p:=ReadBitmapHeader(pBmp)
   x:=x0
   y:=y0
   w:=biWidth
   h:=biHeight
   s:=0 'number of bytes to skip on each line
   c:=@BmpPalette  'for indexed bmps

   case biBitCount
     24:
       
       p+=(biHeight*w*3)-1  'point to last byte in bitmap
       SetCommand(AsmShowBitmap,@p)
     8:
       p+=(biHeight*w)-1   
       repeat y from y0 to y0+biHeight-1
         repeat i from w-1 to 0
           SetPixel(x0+i,y,long[@BmpPalette][byte[p--]])
     4:
     { 
       repeat y from y0+biHeight-1 to y0
         repeat i from 0 to biWidth-1 step 2
           d:=byte[p++]           
           SetPixel(x0+i,y,long[@BmpPalette][(d>>4)&15])
           SetPixel(x0+i+1,y,long[@BmpPalette][d&15])
           }
           
         s:=4*((((biWidth+1)/2)+3)/4)-(biWidth)/2    'this is how many bytes to skip on each line
         SetCommand(AsmShowBitmap4bpp,@p)
         'p+=s  

       
  
PUB SetAllPixels(c)|x,y,z

  z:=nPanels*32-1
  case Arrangement
    0: 'Panels are side-by-side with total height=16
      repeat y from 0 to 31
        repeat x from 0 to z 
          SetPixel(x,y,c)

  


PUB RGB(r,g,b)|level  'create a long color from 3 color bytes
    'Blue byte first because that's how stored in bitmap...
    return ((r<<8+g)<<8)+b



PUB GetRValue(c)
  return (c>>16)&255

PUB GetGValue(c)
  return (c>>8)&255 

PUB GetBValue(c)
  return c&255 

PUB SetPixel(x,y,c) 'Set a pixel with assembly
  SetCommand(AsmSetPixel,@x)     


PUB DrawChar5x8(x,y,c,fore,back)|i,j,k  'Draw a 5x8 font character,c, with upper left corner givng by x and y
   'Will draw with specified foreground and background colors (unless set to -1)
   DrawLimitedC(x,y,c,fore,back,0,95)

   
PUB DrawText5x8(x,y,pString,fore,back)|i,j,k  'Draw a 5x7 string with upper left corner givng by x and y
  repeat i from 1 to StrSize(pString)
    DrawLimitedC(x+(i-1)*6,y,byte[pString+i-1],fore,back,0,95)

PUB ScrollText5x8(x,xmin,y,pString,fore,back,ms)|i,j,k,i2,j2,z,c  'Scroll text left from x back to xmin
  'Doing it the dumb way here and just drawing the whole string every time
  repeat k from 0 to StrSize(pString)*6
    'loop over each column in message 
    repeat i from 1 to StrSize(pString)
      c:=byte[pString+i-1]
      DrawLimitedC(x+(i-1)*6-k+1,y,c,fore,back,xmin,x)

    if ms<1  'need to wait at least 1 ms
      ms:=1
    waitcnt(cnt+ms*(clkfreq/1000)) 
    


PUB Dec(value) | i   '' Print a decimal number with 5x7 font using current row, col, forecolor and backcolor


  if value < 0
    -value
    out("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      out(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      out("0")
    i /= 10


PUB hex(value, digits) '' Print a hexadecimal number with 5x7 font using current row, col, forecolor and backcolor 

  value <<= (8 - digits) << 2
  repeat digits
    out(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


PUB bin(value, digits)'' Print a binary number  with 5x7 font using current row, col, forecolor and backcolor 

  value <<= 32 - digits
  repeat digits
    out((value <-= 1) & 1 + "0")

PUB out(c) | i, k '' Output a character or move cursor with 5x7 font using current row, col, forecolor and backcolor 
''
''     $00 = clear screen
''     $01 = home
''     $08 = backspace
''     $09 = tab (8 spaces per)
''     $0A = set X position (X follows)
''     $0B = set Y position (Y follows)
''     $0C = set color (color follows)
''     $0D = return
''  others = printable characters

  case flag
    $00: case c
           $00: SetAllPixels(backcolor)
                col := row := 0
           $01: col := row := 0
           $08: if col
                  col--
           $09: repeat
                  print(" ")
                while col & 7
           $0A..$0C: flag := c
                     return
           $0D: newline
           other: print(c)
    $0A: col := c // cols
    $0B: row := c // rows
    $0C: forecolor := 2<<(c & 7)
         backcolor := 2<<(c & 7)+1
  flag := 0

PRI Print(c)  'Output a character with 5x7 font using current row, col, forecolor and backcolor 

  DrawChar5x8(col*6,row*8,c,forecolor,backcolor)
  if ++col == cols
    newline

PRI newline | i  'this needs work...

  col := 0
  row:=rows-1
  return
  
  if ++row == rows
    row--
    ScrollScreen(0,8)
    repeat col from cols-1 to 0
       DrawChar5x8(col*6,row*8," ",forecolor,backcolor) 

PUB str(stringptr)

'' Print a zero-terminated string

  repeat strsize(stringptr)
    out(byte[stringptr++])

PUB ScrollScreen(x,y) 'Shift contents of screen by given x and y amounts
    'Not yet implemented

PUB DrawLimitedC(x,y,c,fore,back,xmin,xmax)|z,i,j
  SetCommand(DrawLimitedChar,@x)

PRI setcommand(cmd, argptr)

    command := cmd << 16 + argptr                       'write command and pointer
    repeat while command                                'wait for command to be cleared, signifying receipt
   

DAT 'Assembly graphics support
              org     0 
AsmEntry                'Start of driver
init
loop
              'Check for command
              rdlong  t1,par          wz                 
        if_z  jmp     #loop  'Wait for command



              mov     address,t1                        'preserve address location for passing
                                                        'variables back to Spin language.

              ror     t1,#16+2                          'lookup command address
              add     t1,#jumps
              movs    :table,t1
              rol     t1,#2
              shl     t1,#3
:table        mov     t2,0
              shr     t2,t1
              and     t2,#$FF
              jmp     t2                                'jump to command
jumps         byte    0                                 '0
              byte    UpdateConfig_                     '1
              byte    AsmSetPixel_                      '2
              byte    DrawLimitedChar_                  '3
              byte    AsmShowBitmap_                    '4
              byte    AsmShowBitmap4bpp_                '5            




LoopEnd       wrlong  zero,par                          'zero command to signify command complete              
NotUsed_      jmp     #loop

DAT UpdateConfig_ 'Update operating parameters
              mov       t3,#12
              movd      GetArg,#AsmBalance
              call      #GetSettingsSub
              jmp       #Loop

DAT GetArgumentsSub 'retrieves t3 number of arguments
              movd      GetArg,#arg0                        'get up to 7 arguments ; arg0 to arg6
GetSettingsSub 'enter here if you want to set destination to somewhere besides arg0              
              mov       t2,address                             '    │
              'mov     t3,#7                             '───┘ 
GetArg        rdlong    arg0,t2     'function is in the upper word of t1,t2, but this is ignored...
              add       GetArg,d0
              add       t2,#4
              djnz      t3,#GetArg

              'going to say we're done now, because we have the aruguments already
              wrlong  zero,par                          'zero command to signify command complete 
GetArgumentsSub_RET
GetSettingsSub_RET
              ret

DAT DrawLimitedChar_  'draw a character at given x and y but limit to xmin, xmax
              mov       t3,#7
              call      #GetArgumentsSub
   'arg0=x0
   'arg1=y0
   'arg2=char
   'arg3=fore color
   'arg4=back color
   'arg5=xmin
   'arg6=xmax
   
              mov       t9,#6
              mov       x1,arg0
              mov       t12,AsmPFont5x8
              add       t12,arg2
              rol       arg2,#2
              add       t12,arg2
DLC_xLoop              

              cmp       x1,arg5 wz,wc
        if_b  jmp       #DLC_xLoopEnd
              cmp       x1,arg6 wz,wc
        if_a  jmp       #DLC_xLoopEnd
              mov       t11,#8
              mov       y1,arg1

              rdbyte    t10,t12              
DLC_yLoop
              ror       t10,#1 wc  
              mov       pixelc,arg4
        if_c  mov       pixelc,arg3
              cmp       t9,#1  wz,wc  'last column?
        if_e  mov       pixelc,arg4  
              mov       pixelx,x1
              mov       pixely,y1
              call      #SetPixelSub

              add       y1,#1
              djnz      t11,#DLC_yLoop

        
              
DLC_xLoopEnd
              add       x1,#1
              add       t12,#1
              djnz      t9,#DLC_xLoop 
                            'all done
              jmp       #loop
     
DLC_LastLine              

          
DAT AsmShowBitmap_  'Display a 24bpp pixel at given x and y
              mov       t3,#5
              call      #GetArgumentsSub
 
   'arg0=address of bitmap bits
   'arg1=x0
   'arg2=y0
   'arg3=Width
   'arg4=Height
              mov       arg5,arg1    'using arg5 to mirror bitmap
              add       arg5,arg3
              sub       arg5,#1
   
              mov       y1,arg2
AsmBmpLoopY              
              mov       x1,arg1
              mov       t9,arg3
AsmBmpLoopX
              rdbyte    pixelc,arg0
              sub       arg0,#1
              rdbyte    t1,arg0
              sub       arg0,#1
              rdbyte    t2,arg0
              sub       arg0,#1
              rol       pixelc,#16
              
              rol       t1,#8
              add       pixelc,t1
              add       pixelc,t2
              mov       pixelx,arg5  'need to mirror bitmap
              sub       pixelx,x1
              mov       pixely,y1

              call      #SetPixelSub

              add       x1,#1
              djnz      t9,#AsmBmpLoopX
              
              add       y1,#1
              djnz      arg4,#AsmBmpLoopY
                            
               'all done
              jmp       #loop

          
DAT AsmShowBitmap4bpp_  'Display a 4bpp bitmap at given x and y
              mov       t3,#7
              call      #GetArgumentsSub
 
   'arg0=address of bitmap bits
   'arg1=x0
   'arg2=y0
   'arg3=Width
   'arg4=Height
   'arg5=bytes to skip on each row
   'arg6=address of palette
   
              mov       y1,arg2
              add       y1,arg4
              sub       y1,#1
:AsmBmpLoopY              
              mov       x1,arg1
              mov       t9,arg3
              shr       t9,#1  'two pixels per byte
:AsmBmpLoopX
              rdbyte    t10,arg0 'two pixels
              add       arg0,#1

              'first pixel
              mov       t1,t10
              shr       t1,#4
              shl       t1,#2 'long array
              add       t1,arg6
              rdlong    pixelc,t1
              mov       pixelx,x1
              mov       pixely,y1
              call      #SetPixelSub
              add       x1,#1

              'second pixel              
              mov       t1,t10
              and       t1,#15
              shl       t1,#2
              add       t1,arg6
              rdlong    pixelc,t1
              mov       pixelx,x1
              mov       pixely,y1
              call      #SetPixelSub
              add       x1,#1
              
              djnz      t9,#:AsmBmpLoopX
              add       arg0,arg5 'skip bytes 
              
              sub       y1,#1
              djnz      arg4,#:AsmBmpLoopY
                            
               'all done
              jmp       #loop
{
       repeat y from y0+biHeight-1 to y0
         repeat i from 0 to biWidth-1 step 2
           d:=byte[p++]           
           SetPixel(x0+i,y,long[@BmpPalette][(d>>4)&15])
           SetPixel(x0+i+1,y,long[@BmpPalette][d&15])
         s:=4*((((biWidth+1)/2)+3)/4)-(biWidth+1)/2    'this is how many bytes to skip on each line
         p+=s  
}              
DAT AsmSetPixel_  'Set Pixel
'Note:  Setting a pixel is a bit complex because pixel information is stored in the precalculated output array
'       We need to set 3 bits in each of 8 longs in this array
'       We also need to figure out which panel each pixel is in
'       We are also going to balance and gamma correct the color
              mov       t3,#3
              call      #GetArgumentsSub
              mov       pixelx,arg0 '  arg0:=x
              mov       pixely,arg1'  arg1:=y
              mov       pixelc,arg2'  arg2:=c

              call      #SetPixelSub
          'all done
              jmp       #loop             

DAT SetPixelSub 'subroutine to set pixel at pixelx, pixely with color pixelc
              
              rol       pixelc,#1 wc  'exit if color is negative
        if_c  jmp       #SetPixelSub_RET
              ror       pixelc,#1
          

              'calculate t2:=offset and check that x and y are in bounds
              movs      MovBasePin,#AsmBasePin1 'reset initial source
              'look at x
              cmp       pixelx,#0 wz,wc
        if_b  jmp       #SetPixelSub_RET  'x too small     
              cmp       pixelx,#32 wz,wc
        if_ae sub       pixelx,#32
        if_ae add       MovBasePin,#1
              cmp       pixelx,#32 wz,wc
        if_ae sub       pixelx,#32
        if_ae add       MovBasePin,#1               
              cmp       pixelx,#32 wz,wc 
        if_ae jmp       #SetPixelSub_RET       'x too big
MovBasePin    mov       t2,AsmBasePin1

              'make sure basepin is valid
              cmp       t2,#32 wz,wc
        if_ae jmp       #SetPixelSub_RET  'pixel is on a panel that is not present

              'now, look at y
              cmp       pixely,#0 wz,wc
        if_b  jmp       #SetPixelSub_RET  'y too small

              cmp       pixely,#16 wz,wc
        if_ae sub       pixely,#16
        if_ae add       pixelx,#32   'being in the second row is like being a pixelx>32
        
              cmp       pixely,#8 wz,wc
        if_ae sub       pixely,#8
        if_ae add       t2,#3
        
              cmp       pixely,#8 wz,wc 
        if_ae jmp       #SetPixelSub_RET       'y too big
    
              'Calculate gamma corrected rgb
              mov       t1,pixelc
              ror       t1,#16
              and       t1,#255
              add       t1,AsmPGammaR
              rdbyte    red_,t1
              mov       t1,pixelc 
              ror       t1,#8
              and       t1,#255
              add       t1,AsmPGammaG
              rdbyte    green_,t1              
              mov       t1,pixelc 
              and       t1,#255
              add       t1,AsmPGammaB
              rdbyte    blue_,t1
              'Shift colors all the way left so we can shift into carry later
              rol       red_,#24
              rol       blue_,#24
              rol       green_,#24
        

              'calculate base address of 8 longs (need to add in the i*32<<2 part with t4 later)
              mov       t5,pixely 't5=y
              shl       t5,#8+1    'RJA 6panel
              add       t5,pixelx 't5=(y*8)*32+x
              shl       t5,#2
              add       t5,AsmPOutputArray 't5=[pOutputArray][(y*8)*32+x]          

              't7 will be mask for 3 bits
              mov       t7,#%111
              shl       t7,t2 't7= %111<<offset 

              'Now, write three bits of RGB to 8 longs in output array
              'Starting with MSBit
              mov       t1,#8  't1=i+1    
ASP_loop
              'calculate address of long to alter, t4
              mov       t4,t1   'calculate offset for this bit, t4
              sub       t4,#1
              shl       t4,#(5+2+1)  'RJA: 6panel
              add       t4,t5              
              
              rdlong    t6,t4  't6=long[pOutputArray][(y*8+i)*32+x]
              andn      t6,t7

              'shift left-most color bits into carry and then shift carry to form BGR bits (blue first)
              rol       blue_,#1   wc
              rcl       t8,#1
              rol       green_,#1  wc
              rcl       t8,#1
              rol       red_,#1    wc
              rcl       t8,#1
              and       t8,#%111
   
              'save result
              shl       t8,t2
              or        t6,t8
              wrlong    t6,t4
              djnz      t1,#ASP_Loop   

SetPixelSub_RET
              RET
              
DAT {########################## Defined data ###########################}
 

zero                    long    0                       'constants
d0                      long    $200
pVariables              long    0

{
########################### Undefined data ###########################
}
address                 res     1
arg0                    res     1
arg1                    res     1
arg2                    res     1
arg3                    res     1
arg4                    res     1
arg5                    res     1
arg6                    res     1
arg7                    res     1
arg8                    res     1

x1                      res     1
y1                      res     1
x2                      res     1
y2                      res     1
c1                      res     1
c2                      res     1


                                                        'temp variables
t1                      res     1                       '     Used for DataPin mask     and     COG shutdown 
t2                      res     1                       '     Used for CLockPin mask    and     COG shutdown
t3                      res     1                       '     Used to hold DataValue SHIFTIN/SHIFTOUT
t4                      res     1                       '     Used to hold # of Bits
t5                      res     1
t6                      res     1
t7                      res     1
t8                      res     1
t9                      res     1
t10                     res     1
t11                     res     1
t12                     res     1
t13                     res     1

'12 parameters to be updated
AsmBalance              res     1
AsmIntensity            res     1
AsmBasePin1             res     1
AsmBasePin2             res     1
AsmBasePin3             res     1
AsmEnablePin456         res     1
AsmPOutputArray         res     1
AsmArrangement          res     1
AsmPGammaR              res     1
AsmPGammaG              res     1
AsmPGammaB              res     1
AsmPFont5x8             res     1

red_                    res     1
blue_                   res     1
green_                  res     1

pixelx                  res     1
pixely                  res     1
pixelc                  res     1

fit   

PUB ReadBitmapHeader(pB):bmpAddress|p,i
  'analyze bitmap image 
  p:=pB
  bytemove(@bfType,p,2) 'read bmp header
  p+=2
  bytemove(@bfSize,p,4) 'read bmp header
  p+=4
  bytemove(@bfReserved1,p,4) 'read bmp header
  p+=4
  bytemove(@bfOffBits,p,16) 'read bmp header
  p+=16
  bytemove(@biPlanes,p,4)
  p+=4
  bytemove(@biCompression,p,24)
  p+=24
  'calculate actual bytes in palette
  i:=bfOffBits-54
  'read in palette
  bytemove(@BmpPalette,p,i)
  p+=i
  return p 'return pointer to data

PUB GetBitmapWidth:w
  return biWidth


PUB GetBitmapHeight:w
  return biHeight

DAT     'Data space for reading bitmap files

BMPHeader  byte 'Mostly using info from here:  http://www.fortunecity.com/skyscraper/windows/364/bmpffrmt.html
bfType byte "B","M"  
bfSize long 0
bfReserved1 word 0
bfReserved2 word 0
bfOffBits long 54
biSize long 40
biWidth long 0
biHeight long 10
biPlanes word 1
biBitCount word 24
biCompression long 0
biSizeImage long 0
biXPelsPerMeter long 0
biYPelsPerMeter long 0
biClrUsed long 0
biClrImportant long 0


BmpPalette long
  long 0[256]      'container for bmp palette entries

DAT 'Gamma curve
gamma   byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        byte 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5
        byte 5, 6, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 13, 13, 14
        byte 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 21, 21, 22, 22, 23, 23, 24, 25
        byte 25, 26, 27, 27, 28, 29, 29, 30, 31, 31, 32, 33, 34, 34, 35, 36, 37, 37, 38, 39, 40
        byte 41, 42, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 52, 53, 54, 55, 56, 57, 59, 60
        byte 61, 62, 63, 64, 65, 66, 67, 68, 69, 71, 72, 73, 74, 75, 77, 78, 79, 80, 82, 83, 84
        byte 85, 87, 88, 89, 91, 92, 93, 95, 96, 98, 99, 100, 102, 103, 105, 106, 108, 109, 111
        byte 112, 114, 115, 117, 119, 120, 122, 123, 125, 127, 128, 130, 132, 133, 135, 137, 138
        byte 140, 142, 144, 145, 147, 149, 151, 153, 155, 156, 158, 160, 162, 164, 166, 168, 170
        byte 172, 174, 176, 178, 180, 182, 184, 186, 188, 190, 192, 194, 197, 199, 201, 203, 205
        byte 207, 210, 212, 214, 216, 219, 221, 223, 226, 228, 230, 233, 235, 237, 240, 242, 245
        byte 247, 250, 252, 255
 

DAT '// standard ascii 5x8 (really 6x8 because need a padding column) font from Adafruit example code

font5x8

byte   $00, $00, $00, $00, $00   
byte   $3E, $5B, $4F, $5B, $3E   
byte   $3E, $6B, $4F, $6B, $3E   
byte   $1C, $3E, $7C, $3E, $1C 
byte   $18, $3C, $7E, $3C, $18 
byte   $1C, $57, $7D, $57, $1C 
byte   $1C, $5E, $7F, $5E, $1C 
byte   $00, $18, $3C, $18, $00 
byte   $FF, $E7, $C3, $E7, $FF 
byte   $00, $18, $24, $18, $00 
byte   $FF, $E7, $DB, $E7, $FF 
byte   $30, $48, $3A, $06, $0E 
byte   $26, $29, $79, $29, $26 
byte   $40, $7F, $05, $05, $07 
byte   $40, $7F, $05, $25, $3F 
byte   $5A, $3C, $E7, $3C, $5A 
byte   $7F, $3E, $1C, $1C, $08 
byte   $08, $1C, $1C, $3E, $7F 
byte   $14, $22, $7F, $22, $14 
byte   $5F, $5F, $00, $5F, $5F 
byte   $06, $09, $7F, $01, $7F 
byte   $00, $66, $89, $95, $6A 
byte   $60, $60, $60, $60, $60 
byte   $94, $A2, $FF, $A2, $94 
byte   $08, $04, $7E, $04, $08 
byte   $10, $20, $7E, $20, $10 
byte   $08, $08, $2A, $1C, $08 
byte   $08, $1C, $2A, $08, $08 
byte   $1E, $10, $10, $10, $10 
byte   $0C, $1E, $0C, $1E, $0C 
byte   $30, $38, $3E, $38, $30 
byte   $06, $0E, $3E, $0E, $06 
byte   $00, $00, $00, $00, $00 
byte   $00, $00, $5F, $00, $00 
byte   $00, $07, $00, $07, $00 
byte   $14, $7F, $14, $7F, $14 
byte   $24, $2A, $7F, $2A, $12 
byte   $23, $13, $08, $64, $62 
byte   $36, $49, $56, $20, $50 
byte   $00, $08, $07, $03, $00 
byte   $00, $1C, $22, $41, $00 
byte   $00, $41, $22, $1C, $00 
byte   $2A, $1C, $7F, $1C, $2A 
byte   $08, $08, $3E, $08, $08 
byte   $00, $80, $70, $30, $00 
byte   $08, $08, $08, $08, $08 
byte   $00, $00, $60, $60, $00 
byte   $20, $10, $08, $04, $02 
byte   $3E, $51, $49, $45, $3E 
byte   $00, $42, $7F, $40, $00 
byte   $72, $49, $49, $49, $46 
byte   $21, $41, $49, $4D, $33 
byte   $18, $14, $12, $7F, $10 
byte   $27, $45, $45, $45, $39 
byte   $3C, $4A, $49, $49, $31 
byte   $41, $21, $11, $09, $07 
byte   $36, $49, $49, $49, $36 
byte   $46, $49, $49, $29, $1E 
byte   $00, $00, $14, $00, $00 
byte   $00, $40, $34, $00, $00 
byte   $00, $08, $14, $22, $41 
byte   $14, $14, $14, $14, $14 
byte   $00, $41, $22, $14, $08 
byte   $02, $01, $59, $09, $06 
byte   $3E, $41, $5D, $59, $4E 
byte   $7C, $12, $11, $12, $7C 
byte   $7F, $49, $49, $49, $36 
byte   $3E, $41, $41, $41, $22 
byte   $7F, $41, $41, $41, $3E 
byte   $7F, $49, $49, $49, $41 
byte   $7F, $09, $09, $09, $01 
byte   $3E, $41, $41, $51, $73 
byte   $7F, $08, $08, $08, $7F 
byte   $00, $41, $7F, $41, $00 
byte   $20, $40, $41, $3F, $01 
byte   $7F, $08, $14, $22, $41 
byte   $7F, $40, $40, $40, $40 
byte   $7F, $02, $1C, $02, $7F 
byte   $7F, $04, $08, $10, $7F 
byte   $3E, $41, $41, $41, $3E 
byte   $7F, $09, $09, $09, $06 
byte   $3E, $41, $51, $21, $5E 
byte   $7F, $09, $19, $29, $46 
byte   $26, $49, $49, $49, $32 
byte   $03, $01, $7F, $01, $03 
byte   $3F, $40, $40, $40, $3F 
byte   $1F, $20, $40, $20, $1F 
byte   $3F, $40, $38, $40, $3F 
byte   $63, $14, $08, $14, $63 
byte   $03, $04, $78, $04, $03 
byte   $61, $59, $49, $4D, $43 
byte   $00, $7F, $41, $41, $41 
byte   $02, $04, $08, $10, $20 
byte   $00, $41, $41, $41, $7F 
byte   $04, $02, $01, $02, $04 
byte   $40, $40, $40, $40, $40 
byte   $00, $03, $07, $08, $00 
byte   $20, $54, $54, $78, $40 
byte   $7F, $28, $44, $44, $38 
byte   $38, $44, $44, $44, $28 
byte   $38, $44, $44, $28, $7F 
byte   $38, $54, $54, $54, $18 
byte   $00, $08, $7E, $09, $02 
byte   $18, $A4, $A4, $9C, $78 
byte   $7F, $08, $04, $04, $78 
byte   $00, $44, $7D, $40, $00 
byte   $20, $40, $40, $3D, $00 
byte   $7F, $10, $28, $44, $00 
byte   $00, $41, $7F, $40, $00 
byte   $7C, $04, $78, $04, $78 
byte   $7C, $08, $04, $04, $78 
byte   $38, $44, $44, $44, $38 
byte   $FC, $18, $24, $24, $18 
byte   $18, $24, $24, $18, $FC 
byte   $7C, $08, $04, $04, $08 
byte   $48, $54, $54, $54, $24 
byte   $04, $04, $3F, $44, $24 
byte   $3C, $40, $40, $20, $7C 
byte   $1C, $20, $40, $20, $1C 
byte   $3C, $40, $30, $40, $3C 
byte   $44, $28, $10, $28, $44 
byte   $4C, $90, $90, $90, $7C 
byte   $44, $64, $54, $4C, $44 
byte   $00, $08, $36, $41, $00 
byte   $00, $00, $77, $00, $00 
byte   $00, $41, $36, $08, $00 
byte   $02, $01, $02, $04, $02 
byte   $3C, $26, $23, $26, $3C 
byte   $1E, $A1, $A1, $61, $12 
byte   $3A, $40, $40, $20, $7A 
byte   $38, $54, $54, $55, $59 
byte   $21, $55, $55, $79, $41 
byte   $21, $54, $54, $78, $41 
byte   $21, $55, $54, $78, $40 
byte   $20, $54, $55, $79, $40 
byte   $0C, $1E, $52, $72, $12 
byte   $39, $55, $55, $55, $59 
byte   $39, $54, $54, $54, $59 
byte   $39, $55, $54, $54, $58 
byte   $00, $00, $45, $7C, $41 
byte   $00, $02, $45, $7D, $42 
byte   $00, $01, $45, $7C, $40 
byte   $F0, $29, $24, $29, $F0 
byte   $F0, $28, $25, $28, $F0 
byte   $7C, $54, $55, $45, $00 
byte   $20, $54, $54, $7C, $54 
byte   $7C, $0A, $09, $7F, $49 
byte   $32, $49, $49, $49, $32 
byte   $32, $48, $48, $48, $32 
byte   $32, $4A, $48, $48, $30 
byte   $3A, $41, $41, $21, $7A 
byte   $3A, $42, $40, $20, $78 
byte   $00, $9D, $A0, $A0, $7D 
byte   $39, $44, $44, $44, $39 
byte   $3D, $40, $40, $40, $3D 
byte   $3C, $24, $FF, $24, $24 
byte   $48, $7E, $49, $43, $66 
byte   $2B, $2F, $FC, $2F, $2B 
byte   $FF, $09, $29, $F6, $20 
byte   $C0, $88, $7E, $09, $03 
byte   $20, $54, $54, $79, $41 
byte   $00, $00, $44, $7D, $41 
byte   $30, $48, $48, $4A, $32 
byte   $38, $40, $40, $22, $7A 
byte   $00, $7A, $0A, $0A, $72 
byte   $7D, $0D, $19, $31, $7D 
byte   $26, $29, $29, $2F, $28 
byte   $26, $29, $29, $29, $26 
byte   $30, $48, $4D, $40, $20 
byte   $38, $08, $08, $08, $08 
byte   $08, $08, $08, $08, $38 
byte   $2F, $10, $C8, $AC, $BA 
byte   $2F, $10, $28, $34, $FA 
byte   $00, $00, $7B, $00, $00 
byte   $08, $14, $2A, $14, $22 
byte   $22, $14, $2A, $14, $08 
byte   $AA, $00, $55, $00, $AA 
byte   $AA, $55, $AA, $55, $AA 
byte   $00, $00, $00, $FF, $00 
byte   $10, $10, $10, $FF, $00 
byte   $14, $14, $14, $FF, $00 
byte   $10, $10, $FF, $00, $FF 
byte   $10, $10, $F0, $10, $F0 
byte   $14, $14, $14, $FC, $00 
byte   $14, $14, $F7, $00, $FF 
byte   $00, $00, $FF, $00, $FF 
byte   $14, $14, $F4, $04, $FC 
byte   $14, $14, $17, $10, $1F 
byte   $10, $10, $1F, $10, $1F 
byte   $14, $14, $14, $1F, $00 
byte   $10, $10, $10, $F0, $00 
byte   $00, $00, $00, $1F, $10 
byte   $10, $10, $10, $1F, $10 
byte   $10, $10, $10, $F0, $10 
byte   $00, $00, $00, $FF, $10 
byte   $10, $10, $10, $10, $10 
byte   $10, $10, $10, $FF, $10 
byte   $00, $00, $00, $FF, $14 
byte   $00, $00, $FF, $00, $FF 
byte   $00, $00, $1F, $10, $17 
byte   $00, $00, $FC, $04, $F4 
byte   $14, $14, $17, $10, $17 
byte   $14, $14, $F4, $04, $F4 
byte   $00, $00, $FF, $00, $F7 
byte   $14, $14, $14, $14, $14 
byte   $14, $14, $F7, $00, $F7 
byte   $14, $14, $14, $17, $14 
byte   $10, $10, $1F, $10, $1F 
byte   $14, $14, $14, $F4, $14 
byte   $10, $10, $F0, $10, $F0 
byte   $00, $00, $1F, $10, $1F 
byte   $00, $00, $00, $1F, $14 
byte   $00, $00, $00, $FC, $14 
byte   $00, $00, $F0, $10, $F0 
byte   $10, $10, $FF, $10, $FF 
byte   $14, $14, $14, $FF, $14 
byte   $10, $10, $10, $1F, $00 
byte   $00, $00, $00, $F0, $10 
byte   $FF, $FF, $FF, $FF, $FF 
byte   $F0, $F0, $F0, $F0, $F0 
byte   $FF, $FF, $FF, $00, $00 
byte   $00, $00, $00, $FF, $FF 
byte   $0F, $0F, $0F, $0F, $0F 
byte   $38, $44, $44, $38, $44 
byte   $7C, $2A, $2A, $3E, $14 
byte   $7E, $02, $02, $06, $06 
byte   $02, $7E, $02, $7E, $02 
byte   $63, $55, $49, $41, $63 
byte   $38, $44, $44, $3C, $04 
byte   $40, $7E, $20, $1E, $20 
byte   $06, $02, $7E, $02, $02 
byte   $99, $A5, $E7, $A5, $99 
byte   $1C, $2A, $49, $2A, $1C 
byte   $4C, $72, $01, $72, $4C 
byte   $30, $4A, $4D, $4D, $30 
byte   $30, $48, $78, $48, $30 
byte   $BC, $62, $5A, $46, $3D 
byte   $3E, $49, $49, $49, $00 
byte   $7E, $01, $01, $01, $7E 
byte   $2A, $2A, $2A, $2A, $2A 
byte   $44, $44, $5F, $44, $44 
byte   $40, $51, $4A, $44, $40 
byte   $40, $44, $4A, $51, $40 
byte   $00, $00, $FF, $01, $03 
byte   $E0, $80, $FF, $00, $00 
byte   $08, $08, $6B, $6B, $08
byte   $36, $12, $36, $24, $36 
byte   $06, $0F, $09, $0F, $06 
byte   $00, $00, $18, $18, $00 
byte   $00, $00, $10, $10, $00 
byte   $30, $40, $FF, $01, $01 
byte   $00, $1F, $01, $01, $1E 
byte   $00, $19, $1D, $17, $12 
byte   $00, $3C, $3C, $3C, $3C 
byte   $00, $00, $00, $00, $00 





CON
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

  
