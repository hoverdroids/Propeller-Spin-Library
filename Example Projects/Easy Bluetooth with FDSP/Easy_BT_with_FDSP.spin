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
        _xinfreq = 5_000_000

        RX_PIN=14
        TX_PIN=15
        Baud=9600

        MSBPOST=BS2_Functions#MSBPOST
        CLS=16 'This won't let me reference the constant in FDSP

VAR
  Byte myByte

OBJ
  BS2_Functions      : "BS2_Functions"
  Debug              : "FullDuplexSerialPlus"
   
PUB Main
'-------[Initialization]------------
'the EBT module is waiting for a byte to establish a connection; press any ky
'in the top window pane of the debug to do this
dira[RX_PIN]:=0
dira[TX_PIN]:=1
dira[18]:=1

Debug.start(TX_PIN,RX_PIN,0,Baud)
waitcnt(clkfreq*2+cnt)
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
    Debug.Str(String(13,"And now me keep switching your lights!"))
   !outa[18]
   
  
  repeat 2
    Debug.Str(string(13))
  



