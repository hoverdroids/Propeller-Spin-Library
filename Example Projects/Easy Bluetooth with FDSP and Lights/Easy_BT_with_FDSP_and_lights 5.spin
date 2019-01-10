{{Easy_BT_with_FDSP provides a connection between a BT adapter on the PC and the EasyBT module on a propeller board, by using
the FullDuplexSerialPlus object.
Steps
1.Insert BT transceiver module in computer
2.Drivers should auto install
3.After drivers install, there should be a BT icon in the lower right hand of the screen; if not, go to show icons and make it show
4.Right click on the BT icon and select add a device
5.When EasyBT module shows up, select it and finish the setup
6.Install EasyBT module on prop
7.Open Parallax serial terminal on PC and set the Baud rate to 9600; set the BT to one of the comports the PC assigned the BT module
        note:my laptop set it to COM11,12,14,15 with COM13 being the usb/serial cable. I used COM14 and this worked.
8.Start the prop and download this code onto the Prop RAM (for testing)
9.Go to parallax serial screen and hit enable and then hit any key to initiate the link
10. The termina should show words to indicate all is well

}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 6_250_000

        RX_PIN=14
        TX_PIN=15
        Baud=9600

        MSBPOST=BS2_Functions#MSBPOST
        CLS=16 'This won't let me reference the constant in FDSP

VAR
  Byte myByte
  long  pin
  long one,two,three,four,five,six,seven,eight,nine,zero

OBJ
  BS2_Functions      : "BS2_Functions"
  Debug              : "FullDuplexSerialPlus"
   
PUB Main
'---LED initialization
one:=%00101000
two:=%11001101
three:=%01101101
four:=%00101011
five:=%01100111
six:=%11100111
seven:=%00101100
eight:=%11101111
nine:=%00101111
zero:=%11101110

dira[0..7]:=%11111111
dira[16..23]:=%11111111
dira[24..31]:=%00000000
'-------[Initialization]------------
'the EBT module is waiting for a byte to establish a connection; press any ky
'in the top window pane of the debug to do this
dira[RX_PIN]:=0
dira[TX_PIN]:=1
dira[18]:=1

Debug.start(TX_PIN,RX_PIN,0,Baud)
waitcnt(clkfreq*4+cnt)
Debug.Str(String(13, "this happens only on startup"))
waitcnt(clkfreq*4+cnt)
Debug.tx(16)

waitcnt(clkfreq*3+cnt)

repeat until myByte<>=0
  myByte:=Debug.getDec
Debug.Str(String(13,"You made it!"))
  
myByte:=0
waitcnt(clkfreq*2+cnt)

repeat
  'Debug.tx(CLS)
  Debug.Str(String(13,"You sent the following value:  "))
  myByte:=Debug.getDec
  Debug.Str(String(13, "Me Propeller...me send you:  ")) ', 13,"---------"))
  'Debug.Str(String(13, "Decimal:  "))
  Debug.Dec(myByte)
  'Debug.Str(String(13,"Hexadecimal:  "))
  'Debug.Hex(myByte,8)
  'Debug.Str(string(13, "Binary:  "))
  'Debug.Bin(myByte,32)
  if myByte==1
    outa[0..7]:=one
    outa[23..16]:=one
    'outa[24..31]:=%01111111   'note:having pins 30 and 31 on will create resetting issues
  elseif myByte==2
    outa[0..7]:=two
    outa[23..16]:=two
    'outa[24..31]:=%10111111
  elseif myByte==3
    outa[0..7]:=three
    outa[23..16]:=three
    'outa[24..31]:=%11011111
  elseif myByte==4 
    outa[0..7]:=four
    outa[23..16]:=four
    'outa[24..31]:=%11101111
  elseif myByte==5
    outa[0..7]:=five
    outa[23..16]:=five
    'outa[24..31]:=%11110111
  elseif myByte==6
    outa[0..7]:=six
    outa[23..16]:=six
    'outa[24..31]:=%11111011
  elseif myByte==7
    outa[0..7]:=seven
    outa[23..16]:=seven
    'outa[24..31]:=%11111101
  elseif myByte==8
    outa[0..7]:=eight
    outa[23..16]:=eight
    'outa[24..31]:=%11111110
  elseif myByte==9
    outa[0..7]:=nine
    outa[23..16]:=nine
    'outa[24..31]:=%11111100
  elseif myByte==10
    outa[0..7]:=zero
    outa[23..16]:=zero
    'outa[24..31]:=%111110-10
   
  repeat 2
    Debug.Str(string(13))
  

