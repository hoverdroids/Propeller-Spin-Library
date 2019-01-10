'' =================================================================================================
''
''   File....... tCubed Firmware.spin
''   Purpose.... The main firmware for tCubed
''   Author..... Christopher Sprague
''               Copyright (c) 2016 tCubed
''               -- see below for terms of use
''   E-mail..... chris@playtCubed.com
''   Started.... 24 July 2016
''   Updated....
''   Version 0.1
''
'' =================================================================================================
CON
  _clkmode = xtal1 + pll16x                             'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000                                  'Using 5MHz crystal

OBJ
  debug  : "FullDuplexSerialPlus"                       'Connection to terminal; file must be in same folder as this one                         

VAR
  Byte str1[10]
      
PUB Main | str1, str2, str3
        'Start the debug terminal in a new cog
        debug.start(31,30,0,9600)  
        
        'Set the string to a new value using the String method
        str1:=String("1234567890") 'this won't work because String returns an address