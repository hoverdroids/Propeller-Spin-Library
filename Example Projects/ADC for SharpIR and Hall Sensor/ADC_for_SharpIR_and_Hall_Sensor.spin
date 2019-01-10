{{---------------[title]---------------------
Read analog and convert to digital using ADC}}


CON
        _clkmode = xtal1 + pll16x                                               'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        CS_PIN=0
        CLK_PIN=1
        DataOutput_PIN=2

        MSBPOST=BS2_Functions#MSBPOST
        CLS=16 'This won't let me reference the constant in FDSP

VAR
  Byte adcBitsNew,adcBitsOld,v,r,v2,v3,value
  long stack[30]
OBJ
  BS2_Functions      : "BS2_Functions"
  Debug              : "FullDuplexSerial"
   
PUB Main
{{--[Initialization]--}}
dira[CS_PIN]:=1 '          'set to output
dira[CLK_PIN]:=1           'set to output
dira[DataOutput_PIN]:=0    'set to input

''send test messages and to parallax serial terminal
Debug.start(31,30,0,57600)
waitcnt(clkfreq*2+cnt)
Debug.tx(16)
dira[18]:=1

{{--[Main Routine]--}}
repeat
  ADC_Data
  
  coginit(6,Display(adcBitsNew),@stack[0])
  waitcnt(clkfreq+cnt)
  
PUB ADC_Data
  adcBitsOld:=adcBitsNew
  outa[CLK_PIN]:=0
  outa[CS_PIN]:=0 
  BS2_Functions.PULSOUT(CLK_PIN,210)
  adcBitsNew:=BS2_Functions.SHIFTIN(DataOutput_PIN,CLK_PIN,MSBPOST,8)
  outa[CS_PIN]:=1
  
PUB Display(value2)
'note:for IR sensor, values seem to range from 0 to 255
'for hall sensor, with 5vdc supply, value is 133 when no magnet present and 134 when a magnet present; this value
'depends on the supply voltage though, and hence the software needs to determine what the alternating values are at each startup
  Debug.tx(CLS)
  Debug.Str(String("The binary pot reads:  "))
  Debug.Dec(value2)
  Debug.Str(String(13))
  dira[18]:=1

  if value2==133
    repeat 2000
      !outa[18]
      waitcnt(clkfreq/2+cnt)
  else
      !outa[18]
      waitcnt(clkfreq+cnt)


