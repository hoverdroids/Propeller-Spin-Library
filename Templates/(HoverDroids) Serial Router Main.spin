{

======================================================================
 
  Copyright (C) 2016 HoverDroids(TM)

  Licensed under the Creative Commons Attribution-ShareAlike
  International License, Version 4.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://creativecommons.org/licenses/by-sa/4.0/legalcode

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

======================================================================

   File...... (HoverDroids) Serial Router Main
   Purpose... The top-level object for projects using the HoverDroids
              Serial Router
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Started... 08 11 2016
   Updates... 08 11 2016
   
======================================================================

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------
  This is the top level object for this projects using the HoverDroids
  Serial Router.

  While you may add code in the Main method below, it is not advised.
  Instead, add your code to the init, Main, and ReactToPacket methods
  in the (HoverDroids) Serial Router Virtual Microcontroller object
  by following the instruction on the following page:

  http:\\HoverDroids.github.io\Serial Router Demo

----------------------------------------------------------------------
Usage Notes
----------------------------------------------------------------------
  It is highly recommend that Brad's Spin Tool (BST) is used as the IDE
  when using the HoverDroids library objects. This is because it provides
  an option for removing unused methods at compile time in order to reduce
  the size of the binary file. This can be done by:

  Tools->Compiler Preferences->Eliminate Unused Spin Methods

  When using this object, BST, and eliminating unused spin methods, ensure
  that your code calls at least one method in this object or else errors
  will be thrown at compile time.

  The Propeller Tool is not recommended when using the HoverDroids library
  objects because it doesn't provide the optimization mentioned above.
  Hence, this aggregation of code will certainly increase the size of your
  binary to an unnecessary degree.
}

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
'Info
'This object is the main object. It allows a debug port on pins 30/31 and connects to a Bluetooth
'module on 14 and 15. The Debug monitor can show data between serial ports, nothing, or data and
'packets. To set which function is used, set the bigbrother constant in DAT to 0,1, or 2
'To add/remove serial ports, modify devices in the DAT section.

'TODO talk about the effect of the stealthmask

OBJ
  router: "(HoverDroids) Serial Router with 128Byte Buffers"

CON
  _clkmode = xtal1 + pll16x                             'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000                                  'Using 5MHz crystal

PUB Main
  router.start
