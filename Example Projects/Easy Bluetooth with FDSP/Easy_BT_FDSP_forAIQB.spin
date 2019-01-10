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

        HB_LEFT_PIN=24
        HB_RIGHT_PIN=25
        Dual=1
        Manual=0

VAR
  Byte myByte
  
  Long WHEEL_VELOCITY
  Long TREAD_VEL_L
  Long TREAD_VEL_R

OBJ
  BS2_Functions      : "BS2_Functions"
  Debug              : "FullDuplexSerialPlus"
  HB_25_LEFT:"HB25"
  HB_25_RIGHT:"HB25"
   
PUB Main
'-------[Initialization]------------
'the EBT module is waiting for a byte to establish a connection; press any ky
'in the top window pane of the debug to do this
dira[RX_PIN]:=0
dira[TX_PIN]:=1
Initialize_Bot_Motors

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
  repeat 2
    Debug.Str(string(13))
  Move_Bot
  
   
  
  
PUB Initialize_Bot_Motors

  WHEEL_VELOCITY:=0
  TREAD_VEL_L:=1500 '1000=reverse; 2000=forward
  TREAD_VEL_R:=1500 '2000=reverse; 1000=forward

  HB_25_LEFT.config(HB_LEFT_PIN, 1, 1)  'pin, 0-single 1-dual, 0-manual 1-auto refresh, returns ID of refresh cog
  HB_25_RIGHT.config(HB_RIGHT_PIN, 1, 1)

PUB Move_Bot|direction
If myByte==8   
     direction := 500
elseif myByte==2
     direction:=-500
else
     direction:=0
                      
HB_25_LEFT.set_motor1(1500)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
HB_25_LEFT.set_motor2(1500+direction)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms


HB_25_RIGHT.set_motor1(1500)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
HB_25_RIGHT.set_motor2(1500-direction)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms

HB_25_LEFT.pulse_motors    'send pulse(s) to HB-25(s)
HB_25_RIGHT.pulse_motors    'send pulse(s) to HB-25(s)
  
  
  



