''Was config.spin in the HMC6343 I2C Driver zip from OBEX
''
'' Major functionality
''
'' 1. Application can pass into Init 2 configuration tables. The first table is 32 word entries. 1 per
'' pin, each entry contains a device type from the enum below. The 2nd table is N x 2 bytes to map device type
'' to I2C address
'' 2. Applications should call config.GetPin(DeviceType) to get the pin for the device. GetPin will return -1 if
'' the device is not supported in the pin table.
'' 2. Applications should call config.GetI2C(DeviceType) to get the I2C address for the device. GetI2C will return -1
'' if the device is not supported in the I2C table.
''
CON
'standard pin definitions
'enumeration of standard devices for pins
' Just add new devices to the end of the list
temp1,#0, NOT_USED
KEYBOARD1_DATA                                                                  'Primary keyboard
KEYBOARD1_CLK                                                                   'Primary keyboard
MOUSE1_DATA                                                                     'Primary mouse
MOUSE1_CLK                                                                      'Primary mouse
TV_DAC1                                                                         'Primary TV
VGA1                                                                            'Primary VGA
AUDIO1,AUDIO2                                                                   'Primary/Secondary Audio
FSRW1_DO,FSRW1_CLK,FSRW1_DI,FSRW1_CS                                            'Primary SD media connections
DS1302_INCLK,DS1302_INIO,DS1302_CS                                              'DS1302 clock
DEBUG_TX,DEBUG_RX                                                               'serial debug serial port
GPS_TX,GPS_RX                                                                   'serial gps serial port
CMUCAM_TX,CMUCAM_RX                                                             'cmucam serial port
XBEE_TX,XBEE_RX                                                                 'XBBE serial port
HYDRANET_TX,HYDRANET_RX                                                         'HYDRA Net
IRDETECT,IREMIT                                                                 'IR Emit/detect
PING_DATA                                                                       'Ping Sensor
JOY_CLK,JOY_SHLDN,JOY_DATAOUT0,JOY_DATAOUT1                                     'Nes controller configuration
PG_RXPIN,PG_TXPIN                                                               'PropGFX Lite configuration
DEBUG_LED1,DEBUG_LED2,DEBUG_LED3                                                'some leds for debugging
ENC1_SCK,ENC1_SI,ENC1_SO,ENC1_INT                                               'ENC28J60 Ethernet
HM55BEna,HM55BClk,HM55BDI,HM55BDO                                               'HM55B compass
I2C_SCL1, I2C_SDA1                                                              'primary I2C
I2C_SCL2, I2C_SDA2                                                              'secondary I2C
SERVO1, SERVO2, SERVO3,SERVO4                                                   'servos
SERVO5, SERVO6, SERVO7,SERVO8                                                   'servos
SERVO9, SERVO10, SERVO11,SERVO12                                                'servos
SERVO13, SERVO14, SERVO15,SERVO16                                               'servos
HB25_1,HB25_2,HB25_3,HB25_4                                                     'motor controllers
QE_1,QE_2,QE_3,QE_4                                                             'Quad encoder
QE_5,QE_6,QE_7,QE_8                                                             'Quad encoder
QE_9,QE_10,QE_11,QE_12                                                          'Quad encoder
QE_13,QE_14,QE_15,QE_16                                                         'Quad encoder
VEXDEMUX                                                                        'VEX RC receiver
HX512_C0,HX512_C1,HX512_CLK,HX512_RST,HX512_DATA                                'Hydra 512k expansion sram

PPDB_LED_SEGMENTA1, PPDB_LED_SEGMENTA2, PPDB_LED_SEGMENTB                       'PPDB LED segment displays
PPDB_LED_SEGMENTC, PPDB_LED_SEGMENTD1, PPDB_LED_SEGMENTD2
PPDB_LED_SEGMENTE, PPDB_LED_SEGMENTF, PPDB_LED_SEGMENTG1
PPDB_LED_SEGMENTG2, PPDB_LED_SEGMENTH, PPDB_LED_SEGMENTI
PPDB_LED_SEGMENTJ, PPDB_LED_SEGMENTK, PPDB_LED_SEGMENTL
PPDB_LED_SEGMENTM, PPDB_LED_SEGMENTDP
PPDB_LED_DIGIT_L1, PPDB_LED_DIGIT_R1, PPDB_LED_DIGIT_L2 
PPDB_LED_DIGIT_R2, PPDB_LED_DIGIT_L3, PPDB_LED_DIGIT_R3
'
' Used to define a list of non-standard devices. These are defined at $8000 or above
' so they do not conflict with standard devices
'
temp2,#$8000
SOUNDGIN_TX,SOUNDGIN_CTS, SOUNDGIN_RESET                                        'sound serial port

IPR_TX,IPR_RX                                                                   'Inter-Prop Ring

TFIFO_DATA,TOV6620_PWDN,TOV6620_RST,TFIFO_RST,TFIFO_SDAEN                       'Common camera 1/2 configuration
TFIFO_WRST1,TFIFO_RRST1,TFIFO_RCK1,TFIFO_OE1,TFIFO_WEE1,TFIFO_HREF1,TFIFO_VSYN1 'Camera 1 configuration - also uses I2C_SCL1/I2C_SDA1
TFIFO_WRST2,TFIFO_RRST2,TFIFO_RCK2,TFIFO_OE2,TFIFO_WEE2,TFIFO_HREF2,TFIFO_VSYN2 'Camera 2 configuration - also uses I2C_SCL/IC2_SDA

FPU_MCLR                                                                        'FPU reset

GPS_RX2,GPS_TX2                                                                 'secondary gps port

TLC5940_SCLK,TLC5940_SIN,TLC5940_XLAT,TLC5940_GSCLK,TLC5940_BLANK,TLC5940_VPRG  'TLC5940 LED painter
TLC5940_SOUT,TLC5940_DCPRG

THEREMIN_CLK,THEREMIN_D,THEREMIN_E1,THEREMIN_O1,THEREMIN_E2,THEREMIN_O2         'Theremin sensor
THEREMIN_E3,THEREMIN_O3,THEREMIN_E4,THEREMIN_O4

TIME_CLK

SPISRAM_CS,SPISRAM_SCK,SPISRAM_HOLD,SPISRAM_D0,SPISRAM_D1,SPISRAM_D2,SPISRAM_D3 'SPI SRAM x4
SPISRAM_D4,SPISRAM_D5,SPISRAM_D6,SPISRAM_D7                                     'SPI SRAM x8

SD13305_DATA,SD13305_A0,SD13305_WR,SD13305_RD,SD13305_CS,SD13305_RESET          'SED1330 LCD

TLV2543_CLK,TLV2543_DO,TLV2543_DI,TLV2543_EOC,TLV2543_CS                        'TLV2543 ADC

USBWIZ_DTRDY,USBWIZ_BUSY,USBWIZ_SCK,USBWIZ_MISO,USBWIZ_MOSI,USBWIZ_SSEL         'USBWiz OEM V2
USBWIZ_RESET

HC595_SCK, HC595_RCK, HC595_SER                                                 '74HC595

PIR_ALARM                                                                       'Sparkfun PIR motion sensor

HP03_MCLK, HP03_XCLR                                                            'HP03

SERLCD1                                                                         'Kronos SerLCD1

SHT_DATA                                                                        'SHT-11 data pin
SHT_CLOCK                                                                       'SHT-11 clock pin

'Device type num for I2C devices, skip 0 so can re-use NOT_USED from above
temp3,#1
DS3231                          'RTC
SRF08_0                         'Sonar
SRF02_0                         'Sonar
SRF02_1                         'Sonar
SRF02_2                         'Sonar
SRF02_3                         'Sonar
SRF02_4                         'Sonar
TPA81_0                         'Thermal
CMP03_0                         'Compass
I2CIT_0                         'IR
I2CIT_1                         'IR
LCD03_0                         'LCD03
FPU31_0                         'FPU 3.1
GPIO_0                          'GPIO
GPIO_1
LIS302DL_0                      'LIS302DL accelometer
LIS302DL_1                      'LIS302DL accelometer
LIS3LV02DQ_0                    'LIS3LV02DQ accelometer
BOOTEEPROM
OV6620_0                        'camera module
OV6620_1                        'camera module
FIFO_AL440B_0                   'FiFo for camera
FIFO_AL440B_1                   'FiFo for camera
TCN75_0                         'TCN75 Temp sensor
TCN75_1                         'TCN75 Temp sensor
HP03_AD                         'HP03 A2D
HP03_EEPROM                     'HP03 EEPROM
HMC6343                         '3 axis compass
MCP4725_0                       'DAC

DAT
  PINS  LONG  0                                         'DAT so available to all COGs
  I2C   LONG  0
  
PUB Init(pinaddr,i2caddr)                               'Save configuration table address
  PINS := pinaddr                                          
  I2C := i2caddr                                          
    
PUB GetPin(PinType)                                     'Find pin for this device type
  repeat result from 0 to 31
    if word[PINS][result] == PinType
      return
  return -1

PUB GetI2C(I2CType) | i                                 'Find I2C address for this device type
  result := -1
  if I2C <> 0
    repeat i from 0 to 128 step 2
      if byte[I2C][i] == NOT_USED
        quit
      if byte[I2C][i] == I2CType
        return byte[I2C][i+1]
     
'*************************************** 
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
