{{
OBEX LISTING:
  http://obex.parallax.com/object/419

  Full featured autopilot for boats, planes and rovers. Tested over 3 years. You can see the videos under Spiritplumber on youtube. This version does not contain the graphical console, but text i/o is possible and fairly easy to do.

  Other versions are maintained here http://robots-everywhere.com/portfolio/navcom_ai/ and may be downloaded there. If you intend to use this commercially, please see licensing information on that page.

  A note: It is possible to build functional drone bombers or similar with this. You the downloader are explicitly denied permission to do so. If you want to build autonomous weapons do your own homework, or better yet, go get your head examined.

  Videos of the drones in action!

  http://www.youtube.com/watch?v=5wJHj3hOcuI
  http://www.youtube.com/watch?v=diAZD68Y3Cw
  http://www.youtube.com/watch?v=AIbPvxf3hrk
  http://www.youtube.com/watch?v=en5TCSHZDyY
  http://www.youtube.com/watch?v=Dd1R-WeGWkU
  http://www.youtube.com/watch?v=9m6H5se6-nE
}}
CON
        ' NAVCOM AI prototype 2 pin assignment


        NoPinTX                 = -1
        NoPinRX                 = -1

        SDCard0                 = 00       
        SDCard1                 = 01       
        SDCard2                 = 02       
        SDCard3                 = 03       

        Servo1Out               = 07
        Servo2Out               = 06
        Servo3Out               = 05
        Servo4Out               = 04

        BattPinRX               = 08
        
        com0PinRx               = 09
        com0PinTx               = 10

        ADPinRx                 = 11  ' companion A/D
        Sensor1RX               = 12
        Sensor2RX               = 13
        Sensor3RX               = 14

        VectorHRX               = 15
        HeadingPinRx            = 15 ' for now: fix later

        SPI1                    = 16
        SPI2                    = 17

        Com1PinRX                  = 20
        Com1PinTX                  = 21
        Com2PinRX                  = 18
        Com2PinTX                  = 19
        Com3PinRX                  = 24
        Com3PinTX                  = 25
        Com4PinRX                  = 22
        Com4PinTX                  = 23

        GPS1PinTx               = 26
        GPS1PinRx               = 27

        i2iCLKPin               = 28
        i2cSDAPin               = 29

        ProgPinTx               = 30
        ProgPinRx               = 31

        MuxPinRx                = -1
        MuxPinAlert             = -1


CON
                                                                                                                              
        _clkmode                = xtal1 + pll16x
        _xinfreq                = 5_000_000
        _stack                  = 10 ' mah? set this to MainStack instead?                                                                                       

'        interprounds            = 10 ' How many interpolation rounds to have per second
        NaN             =       $7FFF_FFFF ' used to mean invalid value in floating point
        INVALIDANGLE    =       400.0 ' i.e. more than 360
        INVALIDCOORD    =       2147483647 ' invalid coordinate obviously (as in, more than 180degs)
                                 
obj

com0:"FullDuplexSerialExt"
com1:"FullDuplexSerialExt"
com2:"FullDuplexSerialExt"
com3:"FullDuplexSerialExt"
com4:"FullDuplexSerialExt"

pub start
com1.start(GPS1PinRX,GPS1PinTx,3,9600)
com0.start(com0PinRx,com0PinTx,0,38400)

repeat
   com0.tx(com1.rx)
