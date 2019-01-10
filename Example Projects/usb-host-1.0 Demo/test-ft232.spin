{{
OBEX LISTING:
  http://obex.parallax.com/object/640

  This is a simple USB and Bluetooth protocol stack. It implements a full-speed (12 Mb/s) USB host by bit-banging, so it requires no external hardware to interface USB devices to a Propeller.

  Version 1.0 includes support for FTDI Serial, Mass Storage, and Bluetooth devices.

  The Bluetooth support lets you use a cheap USB Bluetooth adapter to add wireless communications to your Propeller. Supports the Serial Port Protocol.

  Advanced users can also write their own drivers for new USB or Bluetooth devices using lower-level APIs.

  Demo video: http://micah.navi.cx/2010/07/propeller-bluetooth-stack-demo/

  Forum thread: http://forums.parallax.com/forums/default.aspx?f=25&m=440787
}}
' Test communications with an FT232 UART device.

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000
  
OBJ
  uart : "usb-ft232"
  hc : "usb-fs-host"
  term : "Parallax Serial Terminal"

VAR
  byte  buf[1024]
  
PUB main
  term.Start(115200)

  repeat
    testUART
    waitcnt(cnt + clkfreq)

PRI testUART | count, i

  term.char(term#CS)

  if showError(\hc.Enumerate, string("Can't enumerate device"))
    return         

  if uart.Identify
    term.str(string("Identified as an FT232 device", term#NL))
  else
    term.str(string("Not a supported device!", term#NL))
    return

  if showError(\uart.Init, string("Error initializing device"))
    return

  term.str(string("Enter baud rate: "))
  uart.SetBaud(term.DecIn)
  
  term.str(string(term#NL, "Connected to UART. Forwarding characters to/from terminal.", term#NL))

  repeat while hc.GetPortConnection == hc#PORTC_FULL_SPEED

    count~
    repeat while term.RxCount
      buf[count++] := term.CharIn
    if count
      showError(\uart.Send(@buf, count), string("[TX Error]"))

    showError(count := \uart.Receive(@buf, 1024), string("[RX Error]"))
    if count > 0
      repeat i from 0 to count-1
        term.char(buf[i])
    
PRI showError(error, message) : bool
  if error < 0
    term.str(message)
    term.str(string(" (Error "))
    term.dec(error)
    term.str(string(")", term#NL))
    return 1
  return 0
