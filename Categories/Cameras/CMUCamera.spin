{{
SOURCE: http://obex.parallax.com/object/413

CMU Camera Object

by Joe Lucia
http://irobotcreate.googlepages.com
2joester@gmail.com

Uses 2 cogs, one for FullDuplexSerial, one to process the received data

Tim Moore May 2008
Modified to be able to use app cog for processing received data, rather than use a 2nd COG
Modified to use pcfullduplexserial4 which runs 4 serial ports in 1 COG
Modified for cmucam3 in cmucam2 emulation

Features:
  TrackWindow   - tracks mean color in the center of the camera view 
  TrackColor    - tracks a color 
}}

CON
  'CameraState values
  TEMP1,#0,STARTPACKET,WAITPACKET,WAITMMX,WAITMMY,WAITMX1,WAITMY1,WAITMX2,WAITMY2,WAITMPIXELS,WAITMCONF
  WAITT1,WAITT2,WAITXREPORT, WAITYREPORT
  ACK1,ACK2,ACK3,ACK4

OBJ
  'Init, AddPort and Start need to be called for this object from main COG
  ser   : "pcfullduplexserial4FC"

VAR
  long  stack[50]
  byte  cog
  long  port

  byte  _isTracking
  byte  Mmx, Mmy, Mx1, My1, Mx2, My2, Mpixels, Mconfidence
  byte  XReport, YReport

  byte  CameraState
  byte  SeenColon
  byte  Servomode
      
pub Start(portp)                                        '' Start the cogs
  Stop

  Init(portp)

  return (cog := cognew(ProcessCamera, @stack)+1)

pub Init(portp)  
''Init Camera serial without a COG to read from port
''If app calls this directly rather than Start then app needs to call GetCameraInput repeatly
  CameraState := STARTPACKET
  _isTracking := false
  port := portp

pub Stop                                                '' Stop the cogs
  if cog
    cogstop(cog~ - 1)

pub ProcessCamera                                       
  repeat
    GetCameraInput

'written as a FSM, so it can return immediately and come back when there is more to do
pub GetCameraInput | b                                  '' Main Camera Data Processing routine
  'debug camera state
  repeat while (b := ser.rxcheck(port)) <> -1
    'debug camera input
'   ser.str(0,string(" "))
'   ser.hex(0, b,2)
'    ser.tx(0,b) 
    if b == 255
      CameraState := WAITPACKET
      'ser.str(0,string(" Start Packet",13))
      next
    if b == ":"
      SeenColon := 1
    CASE CameraState    
      STARTPACKET   :
        if b == "A"
          CameraState := ACK1
      WAITPACKET   :
        if b=="C"                                         '' Color Tracking packet
          '(raw data: AA XX XX XX XX XX XX AA AA) C 45 72 65 106 18 51 (TC+LineMode Active)
          'C x1 y1 x2 y2 pixels confidence\r
          CameraState := STARTPACKET
          ser.str(0,string(" C packet",13))
        elseif b == "M"                                   ''Check for a middle mass packet
          '(raw data: FE XX XX XX XX XX XX FD) M 45 56 34 10 15 8 (GM+LineMode Active)
          ' M mx my x1 y1 x2 y2 pixels confidence\r 
          CameraState := WAITMMX
          ser.str(0,string(" M packet",13))
        elseif b=="N"                                     '' Servo-Position + Middle + Color tracking
          'N spos mx my x1 y1 x2 y2 pixels confidence\r 
          CameraState := STARTPACKET
          ser.str(0,string(" N packet",13))
        elseif b=="S"                                     '' Statistics
          'S Rmean Gmean Bmean Rdeviation Gdeviation Bdeviation\r
          CameraState := STARTPACKET
          ser.str(0,string(" S packet",13))
        elseif b == "T"
          ' Handle a T packet the same as a M packet
          ' T mx my x1 y1 x2 y2 pixels confidence\r 
          CameraState := WAITMMX
          'ser.str(0,string(" T packet"))
        else
          ser.str(0,string(" "))
          ser.hex(0,b,2)
          ser.str(0,string(" packet",13))
          CameraState := STARTPACKET
      WAITMMX       :
        Mmx := b
        CameraState := WAITMMY
      WAITMMY       :
        Mmy := b
        CameraState := WAITMX1
      WAITMX1       : 
        Mx1 := b
        CameraState := WAITMY1
      WAITMY1       :
        My1 := b
        CameraState := WAITMX2
      WAITMX2       :
        Mx2 := b
        CameraState := WAITMY2
      WAITMY2       :
        My2 := b
        CameraState := WAITMPIXELS
      WAITMPIXELS   :
        Mpixels := b
        CameraState := WAITMCONF
      WAITMCONF     :
        Mconfidence := b
        CameraState := WAITT1
        if Servomode & $04
          CameraState := WAITXREPORT
        else        
          CameraState := STARTPACKET
      WAITXREPORT:
        XReport := b
        if Servomode & $08
          CameraState := WAITYREPORT
        else        
          CameraState := STARTPACKET
      WAITYREPORT   :
        YReport := b
        CameraState := STARTPACKET
      ACK1          :
        if b == "C"
          CameraState := ACK2
        else
          CameraState := STARTPACKET
      ACK2          :
        if b == "K"
          CameraState := ACK3
        else
          CameraState := STARTPACKET
      ACK3          :
        if b == 13
          CameraState := ACK4
          'ser.str(0,string(">ACK",13))
        else
          CameraState := STARTPACKET
      ACK4          :
        if b == ":"
          CameraState := STARTPACKET
        else
          CameraState := STARTPACKET
     
pub SetRawMode(mode)                                    '' Set RawMode for received data
{
B0    Output to the camera is in raw bytes 
B1    “ACK\r” and “NCK\r” confirmations are suppressed  
B2    Input to the camera is in raw bytes
}
  ser.str(port,string("RM "))
  ser.dec(port,mode)
  ser.tx(port,13)
  _isTracking := false

pub SetServoMode(mode)
{ enable/disable servos }
  Servomode := mode
  ser.str(port,string("SM "))
  ser.dec(port,mode)
  ser.tx(port,13)
  
pub GetVersion
  ser.str(port,string("GV",13))
  
pub TrackWindow(mode) | time                              '' Track MiddleMass of camera views mean center color
'   ser.str(0,string("TrackWindow ",13))
'  ser.dec(0, _isTracking)
'  ser.newline(0) 
  if not _isTracking
    if mode & 1                 'enable servo tracking and reporting
      SeenColon := 0
      SetServoMode(15)
      repeat until SeenColon == 1
    SeenColon := 0
    SetRawMode(3)
    repeat until SeenColon == 1
    _isTracking:=true
  else  ' calling again stops tracking
    SetServoMode(0)
    repeat until SeenColon == 1
    _isTracking := false
  ser.str(port,string("TW",13))

pub TrackColor(mode, rmin, rmax, gmin, gmax, bmin, bmax) | time '' Track MiddleMass of specific color
  if not _isTracking
    if mode & 1
      SeenColon := 0
      SetServoMode(15)
      repeat until SeenColon == 1
    SeenColon := 0
    SetRawMode(3)
    repeat until SeenColon == 1
    _isTracking:=true
  else                                                  ' calling this procedure again stops the tracking
    SetServoMode(0)
    repeat until SeenColon == 1
    _isTracking := false

  ser.str(port,string("TC "))
  ser.dec(port,rmin)
  ser.tx(port," ")
  ser.dec(port,rmax)
  ser.tx(port," ")
  ser.dec(port,gmin)
  ser.tx(port," ")
  ser.dec(port,gmax)
  ser.tx(port," ")
  ser.dec(port,bmin)
  ser.tx(port," ")
  ser.dec(port,bmax)
  ser.tx(port," ")
  ser.newline(port) 

pub TmxValue                                            '' return X coordinate of Middle of tracked color
  return Mmx

pub TmyValue                                            '' return Y coordinate of Middle of tracked color
  return Mmy

pub TconfidenceValue                                    '' return Confidence of tracked color                                  
  return Mconfidence

pub ServoX                                              '' return X coordinate of servo
  return XReport

pub ServoY                                              '' return Y coordinate of servo
  return YReport

pub isTracking                                          '' indicates we are currently tracking a color
  return _isTracking

pub SetRegister(reg, val)                               '' Set a camera register value
{ Camera Registers:
Common Settings:  
 Register                                               Values     Effect 
  5   Contrast                                          0-255 
  6   Brightness                                        0-255  
  18 Color Mode           
                                                        36     YCrCb*  Auto White Balance On  
                                                        32     YCrCb* Auto White Balance Off  
                                                        44     RGB  Auto White Balance On                                      
                                                        40     RGB  Auto White Balance Off   (default)  
  17 Clock Speed                 
                                                        2         17 fps   (default) 
                                                        3         13 fps    
                                                        4         11 fps   
                                                        5         9  fps  
                                                        6         8  fps  
                                                        7         7  fps  
                                                        8         6  fps  
                                                        10        5  fps  
                                                        12        4  fps  
  19 Auto Exposure          
                                                        32       Auto Gain Off  
                                                        33       Auto Gain On  (default)
}
  ser.str(port,string("CR "))
  ser.dec(port,reg)
  ser.tx(port," ")
  ser.dec(port,val)
  ser.tx(port,13)

pub SetWindow(x1, y1, x2, y2)                           '' Set the window for dump or middle mass
  _isTracking := false

  ser.str(port,string("SW "))
  ser.dec(port,x1)
  ser.tx(port," ")
  ser.dec(port,y1)
  ser.tx(port," ")
  ser.dec(port,x2)
  ser.tx(port," ")
  ser.dec(port,y2)
  ser.tx(port,13)

pub GetMean                                             '' Gets the Mean Color for the selected window
  ser.str(port,string("GM",13))

pub SetHalfHorizontalResolution(active)                 '' Activates/Disables Half-Horizontal Res mode
  ser.str(port,string("HM "))
  if active
    ser.tx(port,"1")
  else
    ser.tx(port,"0")
  ser.tx(port,13)

pub SetFrameRate(val)                                   '' Set the sample Frame Rate
  '' Set Frame Rate
  SetRegister(17, val)

'pub DumpFrame                                      '' Initiate a Frame Dump
'  SetRawMode(3)
'  _isDumpingFrame:=true
'  ser.rxflush(port)
'  ser.str(port,string("DF"))

pub SetMiddleMassMode(mode)                              '' Set Middle Mass modes
{
Bits    
B0    Enable / Disable Middle Mass Mode 
B1    Enable / Disable the Servo Output 
B2    Change Servo Direction 
B3    Return N-type packet that includes the current servo position (see page 27.)
}
  ser.str(port,string("MM "))
  ser.dec(port,mode)
  ser.tx(port,13)

pub SetNoiseFilter(active)                              '' Activates/Disables Noise Filter
  ser.str(port,string("NF "))
  if active
    ser.tx(port,"1")
  else
    ser.tx(port,"0")
  ser.tx(port,13)

pub SetPollMode(active)                                 '' Activates/Disabled Poll Mode
  ser.str(port,string("PM "))
  if active
    ser.tx(port,"1")
  else
    ser.tx(port,"0")
  ser.tx(port,13)

pub ResetCamera                                         '' Reset Camera
  ser.str(port,string("RS",13))

pub SetLineMode(active)                                 '' Set Line Mode for Color and Mean Color tracking
  ser.str(port,string("LM "))
  if active
    ser.tx(port,"1")
  else
    ser.tx(port,"0")
  ser.tx(port,13)

pub SetSwitchingMode(active)                            '' Sets switching mode for Color Tracking
  ser.str(port,string("SM "))
  if active
    ser.tx(port,"1")
  else
    ser.tx(port,"0")
  ser.tx(port,13)
  
