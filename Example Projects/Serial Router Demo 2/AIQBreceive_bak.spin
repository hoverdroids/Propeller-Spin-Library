{{
***************************************
* AIQBreceive.spin *
***************************************
* See end of file for terms of use. *
***************************************
This file is to be loaded onto the AIQB Propeller1 and tested with P2ABpassthrough
loaded onto the P2AB. This file disects the message type and message value and then displays the message
number and value on the two 8 segment displays. P2ABpassthrough provides serial pass through from PC to AIQB Prop1
while AIQBreceive

Messages:
cmmd000N where N is any number from 0 to 9
mssg000N where N is any number from 0 to 9

if the message type is cmmd, then the left 8 segment display will show a 1
if the message type is mssg, then the left 8 segment display will show a 2

regardless of the message type, the right 8 segment display will show the message value
so long as the message type is one of the two stated

Baud rate may differ between units though FullDuplexSerial can
buffer only 16 bytes.

Finally, if the user types a command and then deletes, the buffer will get the input and output incorrectly
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000
  
  ' Set pins and Baud rate for XBee comms
  XB_Rx = 26 ' XBee DOUT
  XB_Tx = 27 ' XBee DIN
  XB_Baud = 9600
  
  ' Set pins and baud rate for PC comms
  PC_Rx = 31
  PC_Tx = 30
  PC_Baud = 9600
  
Var
  long stack[50] ' stack space for second cog
  byte messageType[17]   'byte space for the message type
  byte messageValue[17]   'byte space for the message value
  byte messageNew[17]       'only 16 since FDSP can only cache 16 values, plus one extra for a zero terminator
  byte i, j, k, n, numCommas                    'an index value for loops
  word index          'this is used to pass the relay state to DIOB
  byte direction
  byte secondaryPower
  byte auxDCPower
  byte auxChargerPower
  byte values[50]     'for storing the values of the incoming message
  byte commas[50]     'notes the locations of commas in the message
  
  
OBJ
  PC : "FullDuplexSerialPlus"
  XB : "FullDuplexSerialPlus"
  DIOB: "Digital_IO_Board4"
  
Pub Start
  index:=%10000000
  DIOB.Main(index)
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  XB.rxFlush  'Empty buffer for new data

  {{Entry loop added 1/26/2013 to ensure proper startup; else the prop responds unpredicatably
  }}
  waitcnt(clkfreq*3+cnt)
  XB.str(string("Please hit a number key to start  ",13))
  repeat until n>0
    n:=XB.getdec
  XB.str(string("Main loop is being entered",13))  
  aiqbInit              'initialize the 7-seg pins to output
                             
  repeat
    clearOld
    XB.getstr(@messageNew)      'wait until a string with CR is sent; then, store it in messageNew with zero terminator
    disectMessage
    if strcomp(@messageType,string("state"))
      state
    boardResponse
    
    
   

Pri disectMessage

  i:=0  'null these just in case
  j:=0
  k:=1   'need to start noting value locations after the 0th element, since that is the first value
  repeat strsize(@messageNew) 'determine the message type, and only go for as long as was the received message
    if messageNew[i]==","
      XB.str(string("Message Type determined",13))
      i++
      Quit
    messageType[i]:=messageNew[i]
    i++

    'now that the first comma is reached, store the values, add zero terminator and note their locations
  repeat strsize(@messageNew)-i
    values[j++]:=messageNew[i++]   'the first element of values, is that after the first comma, not including the first comma
    if messageNew[i]==","
      commas[k]:=j+1  'when hitting a comma,replace with a 0 in values matrix, and note the next value start location
      values[j]:=0 'need to add a 0 string terminator where the comma was, but no need to add the comma
      k++
      j++
      i++

  numCommas:=k     'this notes how many zeros, i.e. number of values sent -1

  i:=0
  j:=0
  k:=1
  
Pri boardResponse
    i:=0
    j:=0
    k:=0
    XB.str(string("string size:"))
    XB.dec(strsize(@messageNew))
    XB.str(string(13))
    XB.str(string("----------"))
    XB.str(string(13))
    XB.str(string("messageNew: ")) 'after the message is stored, repeat it to the terminal
    XB.str(@messageNew)
    XB.str(string(13))
    XB.str(string("Type:"))
    XB.str(@messageType)
    XB.str(string(13))

    repeat numCommas 'strsize(@commas)
      waitcnt(clkfreq/10+cnt)          'the only reason this is here is due to printout on the terminal
      i:=commas[k++]
      XB.str(string("Message Value "))
      XB.dec(i)
      XB.str(string(" is: "))
      XB.str(@values[i])
      XB.str(string(13))
                       
    i:=0
    XB.str(string("----------"))
    XB.str(string(13))
    XB.str(string(13))
    repeat msgN
      if strcomp(@messageType,@msgType[i])
        outa[0..7]:=byte[@msgTypeDispNum][j]
        QUIT
      i:=i+strsize(@msgType[i])+1 'says to add the string size plus 1 to the current index; the plus 1 is due to the zero terminator after every string
      j++
      if j==msgN
        outa[0..7]:=%00010000

    i:=0
    j:=0
    repeat 10 'msgV
      if strcomp(@values,@msgValue[i])
        outa[16..23]:=byte[@msgValueDispNum][j]
        QUIT
      i:=i+strsize(@msgValue[i])+1
      j++
   
Pri clearOld
    i:=0                        'reset i for later index
    j:=0
    k:=1
    bytefill(@messageNew,0,17)  'clear the messageNew bytes to be null bytes
    bytefill(@messageType,0,17) 'clear the messageType bytes to be null bytes
    bytefill(@messageValue,0,17)
    bytefill(@commas,0,50)
    bytefill(@values,0,50)
    XB.rxFlush
    
Pri aiqbInit
  dira[0..7]:=%11111111        'set left 7-seg to output
  dira[16..23]:=%11111111         'set right 7-seg to output

  'initialize state variables
  secondaryPower:="0"     'all initial state vars are 0 since no power should be applied before logical analysis/user input
  auxDCPower:="0"
  auxChargerPower:="0"
  direction:="0"
Pri State|v1,v2,v3,v4
  'after state was called, save the temp values to the state variables
  direction:=values[6]            

  if direction=="1"               'only need to set the output state when direction is 1
    secondaryPower:=values[0]     'only write state values when direction was 1
    auxDCPower:=values[2]
    auxChargerPower:=values[4]

    if secondaryPower=="1"
      index:=%00000001
    else
      index:=%00000000

    if auxDCPower=="1"
      index:=index+%00000010   'this should be possible when combining binary

    if auxChargerPower=="1"
      index:=index+%00000100
    DIOB.Main(index)            'only change the DIOB settings if the direction was 1
    direction:="0"              'reset the direction to avoid accidentally writing to state variables

  'The following data will be sent to ASA whenever state is called, regardless of the direction
  'XB.str(string("data,variable,primaryPower,"))'this will show the start of this huge string
  'XB.str(@primaryPower)
  XB.str(string("secondaryPower:"))
  XB.tx(secondaryPower)'(@secondaryPower[0])
  XB.str(string(13))
  'waitcnt(clkfreq/2+cnt)
  XB.str(string("auxDCPower:"))
  XB.tx(auxDCPower)
  XB.str(string(13))
  'waitcnt(clkfreq/2+cnt)
  XB.str(string("auxChargerPower:"))
  XB.tx(auxChargerPower)
  XB.str(string(13))
  'waitcnt(clkfreq/2+cnt)

  'XB.str(string(",batteryLevel,"))
  'XB.str(@batteryLevel))
  'XB.str(string(",acPresence,"))
  'XB.str(@acPresence)
  'XB.str(string(",currentState,"))
  'XB.str(@currentState)
  'XB.str(string(",ballPresence,"))
  'XB.str(@ballPresence)
  'XB.str(string(",sliderReady,"))
  'XB.str(@sliderReady)
  XB.str(string(13))                         'this will show the end of this huge string
  
Dat
{The following numbers correspond to the green 7-segment display (left side)on the AIQB Propeller1.
The assigned values correspond to pin0 through 7, from left to right. Also, note that these are given
in tens of values rather than single digits; it's because this display is on the left in the tens location
when using both 7-segment displays
}
  'uncomment the following 2 lines and comment their "live copies" in order to revert to message names being numbers
  msgN byte 1 'make this ten when comparing to the msgType numbers below
  msgType byte "state",0          
  'msgType byte "hundred",0,"ten",0,"twenty",0,"thirty",0,"fourty",0,"fifty",0,"sixty",0,"seventy",0,"eighty", 0,"ninety",0
  'msgType byte "state"
  msgTypeDispNum byte %11101110, %00101000, %11001101, %01101101, %00101011, %01100111, %11100111, %00101100, %11101111, %00101111
  'state

  
{The following numbers correspond to the red 7-segment display (right side)on the AIQB Propeller1.
The assigned values correspond to pin16 through 23, from left to right;
NOTE:pin 20 is burned out at present so DO NOT TURN ON pin 20!
}
  msgV byte 10
  msgValue byte "0",0,"1",0,"2",0,"3",0,"4",0,"5",0,"6",0,"7",0,"8",0,"9",0
  msgValueDispNum byte %01110111, %00010100, %10110011, %10110110, %11010100, %11100110, %11100111, %00110100, %11110111, %11110100
    