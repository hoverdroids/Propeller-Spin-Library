{{
***************************************
* AIQBProp2Main.spin *
***************************************
* See end of file for terms of use. *
***************************************
This file is to be loaded onto the AIQB Propeller2 and tested with P2ABpassthrough
loaded onto the P2AB and AIQBProp1Main loaded on to the AIQB Propeller1.
P2ABpassthrough wirelessly communicates user input from a PC terminal to Prop1.
AIQBProp1main will take the user commands and feed them to Prop2 if the command
is any other than for state changes.

Messages coded:
drive,A,t      will result in the command being passed to Prop2 for action

Baud rate may differ between units though FullDuplexSerial can
buffer only 16 bytes.

Finally, if the user types a command and then deletes, the buffer will get the input and output incorrectly
}}
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000
  
  ' Set pins and Baud rate for Prop to prop comms
  P2toP1_Tx = 9 ' Prop2 Tx to prop1 Rx
  P2toP1_Rx = 10 'Prop2 RX from prop1 TX
  P2toP1_baud= 115200

  'set HB-25 info for driving and throwing
  HB_LEFT_PIN=24
  HB_RIGHT_PIN=25

Var
  byte i,j,k
  byte messageNew[17]       'only 16 since FDSP can only cache 16 values, plus one extra for a zero terminator
  byte messageType[17]   'byte space for the message type
  'byte messageValue[17]   'byte space for the message value
  byte values[50]     'for storing the values of the incoming message
  byte commas[50]     'notes the locations of commas in the message
  byte numCommas
OBJ
  P2PComms : "FullDuplexSerialPlus"
  HB_25_LEFT:"HB25"
  HB_25_RIGHT:"HB25"
Pub Start
  aiqbP2Init

  repeat
    P2PComms.getstr(@messageNew)
    disectMessage
    if strcomp(@messageType,string("drive"))
      drive
    elseif strcomp(@messageType,string("whrot"))
      wheel_rotation
Pri aiqbP2Init
 P2PComms.start(P2toP1_RX,P2toP1_TX,0,115200)
Pri drive|left_speed,right_speed
  'cannot drive while throwing wheels are moving due to over current draw
  'there will be a manual update to stop the wheels from driving without a command
  repeat 3
    P2PComms.str(@messageNew)
    P2PComms.str(string(13))
  '1.search through the first value to determine what the tread velocities are
  '2.read the second value to determine how long to execute the drive command
  HB_25_LEFT.config(HB_LEFT_PIN, 1, 0)  'pin, 0-single 1-dual, 0-manual 1-auto refresh, returns ID of refresh cog
  HB_25_RIGHT.config(HB_RIGHT_PIN, 1, 0)  'manual for safety
  
  left_speed:=driveDirection[1]  'have a lookup table for the values based on the drive command
  right_speed:=driveDirection[2]  'same

  'repeat              'i don't think this is necessary since it's a manual update
    HB_25_LEFT.set_motor1(stopped)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_LEFT.set_motor2(left_drive_speed)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms

    HB_25_RIGHT.set_motor1(stopped)  '1000 is forward--Right wheel; greater than 1500set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms
    HB_25_RIGHT.set_motor2(right_drive_speed)  'set first HB-25; full reverse 1000ms,stop 1500ms,fullforward 2000ms

    HB_25_LEFT.pulse_motors    'pulse both sides at the same time; this may need a repeat loop
    HB_25_RIGHT.pulse_motors    '

    waitcnt(clkfreq*driveTime+cnt)   'only drive for the amount of time requested and then kill the method
  

  
 
Pri wheel_rotation
'cannot throw while driving due to over current draw
'thowing wheels are front Hb-25s and first in the daisy chain
'wheel velocity needs to be set by reading the value;wheel direction will always be the same for each wheel
'wheel speed will be set as a constant with autoupdate

'the requested velocity will need to be mapped to the table data which is measured-and is hopefully consistent
 
Pri disectMessage

  i:=0  'null these just in case
  j:=0
  k:=1   'need to start noting value locations after the 0th element, since that is the first value
  repeat strsize(@messageNew) 'determine the message type, and only go for as long as was the received message
    if messageNew[i]==","
      'XB.str(string("Message Type determined",13))
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
DAT
 str1 byte "testing",0
 driveDirN byte 13   'the number of drive commands possible
 'TREAD_VEL_R=2000 '2000=reverse; 1000=forward
 'TREAD_VEL_L=1000 '1000=reverse; 2000=forward
          '0    1    2    3    4
 ampR byte 2000 1850 1500 1150 1000 '-->fwd
 ampL byte 1000 1150 1500 1850 2000 '-->fwd
 driveDirection  byte "RH",0  ,"RMLT",0,"RHLT",0,"RMRT",0,"RHRT",0,"RM",0 ,"FH",0,"FMLT",0,"FHLT",0,"FMRT",0,"FHRT",0,"FM",0 ,"TH",0
 tread_vel_right byte  ampR[0],ampR[0] ,ampR[0] ,ampR[1] ,ampR[2] ,ampR[1],ampR[4],ampR[4],ampR[4] ,ampR[3] ,ampR[2] ,ampR[3],ampR[4]  
 tread_vel_left  byte  ampL[0],ampR[1] ,ampR[2] ,ampL[0] ,ampL[0] ,ampL[1],ampL[4],ampL[3],ampL[2] ,ampL[4] ,ampL[4] ,ampL[3],ampL[0]