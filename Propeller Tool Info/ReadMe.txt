Welcome to the Propeller Tool software for the Propeller microcontroller.

This file contains information about the Propeller Tool not found elsewhere.



WHERE TO FIND INFORMATION

Documentation on this product is contained in the Propeller Manual.

Please visit the Parallax web site periodically to find updated software and documentation.

  http://www.parallax.com/propeller



SYSTEM REQUIREMENTS

Windows 2000 or later
The recommended processor for the Operating System
The recommended RAM for the Operating System
40 MB Free Hard Drive Space
24-bit, or better, SVGA video card
1 Available USB port or COM port



INSTALLATION

The Propeller Tool is available as an install file downloadable from the Parallax web site.  Simply run the downloaded file and follow the prompts.  After
installation, run the Propeller.exe program to run the Propeller Tool software.



WHAT'S NEW
----------
Version 1.2.7

---General---

Enhanced to exclude PropScope from serial port searches by default.
Enhanced to protect against hard system errors (on removable media) when checking for the existence of a folder path.



--LIBRARY---

Updated Float32 to v1.5.
Updated Float32A to v1.5.
Updated Float32Full to v1.5.



---LIBRARY DEMOS---

Updated Propeller Floating Point.pdf. 





Version 1.2.6

---General---

Changed "Plain" element in Preferences' Syntax Elements list to "Regular."  This better describes the element.

Enhanced Preferences to display "Use Default" checkboxes as either "Use Regular" or "Use BLOCK" to indicate which setting will actually be used.  Updated
the hint descriptions for these as well.

Updated Help menu to include Enhanced Propeller Help and links to Propeller Datasheet v1.2, Propeller Education Kit Labs (pdf) v1.1, Object Exchange
website, and PE Kit Tools and Applications forum thread.

Included Parallax Serial Terminal with installer.



---Bug Fixes---

Fixed bug in Preferences causing the Background option to be available in non-Block elements.

Fixed bug causing Restore button to not update syntax highlighting when the scheme changed as a result of it.



--LIBRARY---

Added 4x4 Keypad Reader v1.0.
Updated FullDuplexSerial to v1.2.
Updated HM55B Compass Module Asm to v1.2.
Updated Memsic2125 to v1.1.
Updated Numbers to v1.1.
Added Parallax Serial Terminal v1.0.
Added PropellerRTC_Emulator v1.0.
Updated Servo32 to v1.5.
Updated Simple_Serial v1.3.
Added SPI_Asm.spin v1.2.
Added SPI_Spin.spin v1.0.



---LIBRARY DEMOS---

Added 4x4 keypad Reader Demo v1.0.
Added HM55B Compass Calibration v1.0.
Deleted HM55B Compass Module.
Added HM55B Compass Module_Serial Demo v1.1.
Added HM55B Compass Module_TVDemo v1.4.
Updated memsic_demo.spin to v1.1.
Added Parallax Serial Terminal Demo v1.0.
Added Parallax Serial Terminal QuickStart v1.0.
Added PropellerRTC_Emulator_Demo v1.0.
Updated Servo32 Demo to v1.5.
Added SPI Asm Demo v1.0.
Added SPI Spin Demo v1.0.



---Misc---

Updated FTDI VCP Driver (USB to Serial) to v2.04.16.
Updated Propeller Datasheet (pdf) to v1.2.
Updated Propeller Manual (pdf) to v1.1.
Updated Propeller Quick Reference (pdf) to v1.6.
Enhanced Propeller Help examples folder structure (formerly Manual examples).
Added PE Kit Labs examples.
  




Version 1.2.5

---General---

Modified the Block Group Indicators preference to be True by default.



---Bug Fixes---

Enhanced to prevent system-level dialog indicating "No Disk in Drive..." when a drive and/or path is scanned on a removable media drive that has no media in it.  This
would occur on some systems with media card readers either upon Propeller Tool startup, during the session, or both.






Version 1.2

---General---

Enhanced circular reference error message to diagram the relationship between objects to make it more clear where the problem is.

Enhanced serial routines to support FTDI VCP Driver v2.4.6 to avoid a possible "Write Error on COMx" message.

Enhanced to automatically check file associations during the first run.



---Bug Fixes---

Fixed bug causing confusing circular reference message when a child references a parent object with multiple instances.

Fixed bug that allowed for the possibility of an invalid circular reference error if two same-named objects existed in two different folders and both appeared along
a branch of the project hierarchy.

Fixed bug in serial routines that caused a "Propeller Not Found..." error message to be unclear when the Serial Search Method is set to a specific port.

Fixed bug in serial routines causing non-existent COM ports to be displayed in error message as COM65535.



--LIBRARY---

Updated H48C Tri-Axis Accelerometer.spin
Updated Servo32v3.spin



---LIBRARY DEMOS---

H48C Tri-Axis Accelerometer DEMO.spin



---Misc---

Updated FTDI VCP (Virtual Com Port) Driver to v2.4.6.





Version 1.1

---General---

Rewrote all serial routines and related items to increase reliability of Propeller chip identification and download process on machines who's CPU and/or other hardware
is heavily burdened.  This should significantly decrease the occurrence of "Propeller chip lost on COMx" error messages during download.

Enhanced to prevent software lock-up when accessing serial port hardware that is malfunctioning, misconfigured, or otherwise unusable by the Propeller Tool.



---Bug Fixes---

Fixed bug causing Progress Form to disappear behind the Info Form if focus changed to Info Form.

Fixed bug causing Progress Form to remain visible and "stuck" if communication completed while application is minimized.



---LIBRARY---

Updated AD8803.spin
Removed ADC.spin
Updated Clock.spin
Updated CoilRead.spin
Updated CTR.spin
Updated Debug_Lcd.spin
Removed DS1620.spin
Added   Float32.spin
Added   Float32A.spin
Added   Float32Full.spin
Updated FloatMath.spin
Updated FloatString.spin
Updated FullDuplexSerial.spin
Updated Graphics.spin
Updated H48C Tri-Axis Accelerometer.spin
Updated HM55B Compass Module Asm.spin
Updated Inductor.spin
Updated Keyboard.spin
Added   License.spin
Updated MCP3208.spin
Updated memsic2125.spin
Updated Monitor.spin
Updated Mouse.spin
Updated MXD2125 Simple.spin
Added   MXD2125.spin
Updated Numbers.spin
Updated Ping.spin
Updated PropellerLoader.spin
Updated Quadrature Encoder.spin
Added   RCTIME.spin
Updated RealRandom.spin
Updated Servo32v3.spin
Added   Serial_LCD.spin
Updated Simple_Numbers.spin
Updated Simple_Serial.spin
Updated Simple_Debug.spin
Updated Stack Length.spin
Updated StereoSpatializer.spin
Updated Synth.spin
Updated TSL230.spin
Updated TV.spin
Updated TV_Terminal.spin
Updated TV_Text.spin
Updated VGA.spin
Updated VGA_1280x1024_Tile_Driver_With_Cursor.spin
Updated VGA_1600x1200_Tile_Driver_With_Cursor.spin
Updated VGA_512x384_Bitmap.spin
Updated VGA_HiRes_Text.spin
Updated VGA_Text.spin
Updated VocalTract.spin



---LIBRARY DEMOS---

Updated AD8803_Demo.spin
Updated Coil_Demo.spin
Updated Debug_Lcd_Test.spin
Updated Dither.spin
Removed DS1620-Thermometer-v1.0.spin
Updated Float_Demo.spin
Updated FrequencySynth.spin
Updated Graphics_Demo.spin
Updated Graphics_Palette.spin
Updated H48C Tri-Axis Accelerometer Demo.spin
Updated HM55B Compass Module.spin
Updated Inductor Demo.spin
Updated Keyboard_Demo.spin
Updated Memsic_Demo.spin
Updated Microphone_to_Headphones.spin
Updated Microphone_to_VGA.spin
Updated Monitor_Demo.spin
Added   MXD2125 Demo.spin
Updated MXD2125 Simple Demo.spin
Updated Ping_Demo.spin
Added   Propeller Floating Point.pdf
Added   RCTIME_background_Demo.spin
Added   RCTIME_foreground_Demo.spin
Updated ReadRandom_Demo.spin
Updated Servo32v3_Demo.spin
Updated SingingDemo.spin
Updated SingingDemoSeven.spin
Updated SpatialSoundDemo.spin
Updated Stack Length Demo.spin
Updated TSL230 Demo.spin
Updated TSL230 Simple Demo.spin
Updated TV_Terminal_Demo.spin
Updated TV_Text_Demo.spin
Updated VGA_512x384_Bitmap_Demo.spin
Updated VGA_Demo.spin
Updated VGA_HiRes_Text_Demo.spin
Updated VGA_Text_Demo.spin
Updated VGA_Tile_Driver_Demo2.spin
Updated VGA_Tile_Driver_Demo3.spin
Updated VocalTractDemo_Mama.spin
Updated VocalTractDemo_Mixer.spin





Version 1.06

---General---

Enhanced serial port configuration options to allow user to include/exclude ports based on port ID or port description.  Also, user can specify the search order of ports.
See Edit -> Preferences -> Operation -> Edit Ports for options.

Added Serial Port Search field to Preferences' Operation tab that allows selection of: 1) AUTO (to scan all ports according to serial search preferences), or 2) a
specific port.

Enhanced to be aware of serial port add/remove events the moment they occur.

Enhanced all serial-related error messages to indicate port events and status.

Added support for Auto Recovery of fatal Serial Port Scanning failures.

Updated Object View and Info View to use enhanced hint window code.

Updated Propeller Quick Reference to v1.5.

Updated FTDI USB Virtual COM Port Drivers to v2.02.04.


---LIBRARY---

Added ADC.spin
Added CoilRead.spin
Updated FloatString.spin
Added Inductor.spin
Added MXD2125 Simple.spin
Added Servo32v3.spin
Added Synth.spin
Added TSL230.spin
Added VGA_1280x1024_Tile_Driver_With_Cursor.spin
Added VGA_1600x1200_Tile_Driver_With_Cursor.spin
Updated VGA_HiRes_Text.spin


---LIBRARY DEMOS---

Updated AD8803_Demo.spin
Added FrequencySynth.spin
Added Inductor Demo.spin
Added Memsic_Demo.spin
Added Microphone_to_Headphones.spin
Added Microphone_to-VGA.spin
Added MXD2135 Simple Demo.spin
Updated Ping_Demo.spin
Added Servo32v3_Demo.spin
Added TSL230 Demo.spin
Added TSL230 Simple Demo.spin
Added VGA_HiRes_Text_Demo.spin
Added VGA_Tile_Driver_Demo2.spin
Added VGA_Tile_Driver_Demo3.spin






Version 1.05.8

---Bug Fixes---

Updated compiler to fix bug causing local labels of exactly 16 characters to be processed incorrectly.  This was fixed in version 1.05.5 but was
mistakenly broken again in v1.05.6 and v1.05.7.




Version 1.05.7

---Bug Fixes---

Fixed scaling issues with Progress window, Object Info window, and Preferences window, that occur when system has a DPI setting other than 96 dpi.

Fixed to disallow filenames without the proper extension.  This is to support .spin, .eeprom, and .binary in one deterministic fashion.

Fixed bug preventing .binary or .eeprom files (listed on the command line) from opening upon initial startup.




Version 1.05.6

Updated compiler to support $ as a "here" operator.




Version 1.05.5

---General---

Added preference item to the Operations tab to control how the Propeller Reset Signal is output.  The signal can now appear on the: DTR pin (default), RTS
pin, or on both DTR and RTS pins.

Added "undo after save" preference item to the Files and Folders tab.


---Bug Fixes---

Updated compiler to fix bug causing local labels of exactly 16 characters to be processed incorrectly.

Updated serial communication routines to including scanning of COM ports that don't register normally with the system.  This issue was preventing some
manufacturer's COM port devices from being recognized by the Propeller Tool.




Version 1.05.2

---General---

Enhanced to allow stub-loader configurations of binary and eeprom files.  Adjusted Info View to display memory info and map in dark gray for everything
that could be code space (based on image size) and medium-gray for everything that is outside that region.

Adjusted look of block syntax preference items.

Removed *.binary and *.eeprom from normal Save As dialog.

Enhanced compiler to:
  1) Support a new directive, ORGX, to allow user to stop COG address incrementing for large-model assembly programs.
  2) Enhance arguments of ORG, RES, FIT, and ‘repeat’(in BYTE/WORD/LONG value[repeat]) so that they are allowed the same scope as instruction operands.
  3) Support RES as _RET destinations.
  4) Support TESTN instruction (which is an ANDN instruction, no result write... similar to how TEST is really an AND, no result write).

Updated syntax highlighting to include ORGX.

Updated syntax highlighting for TESTN.

Enhanced to refresh the file list if a Top Object File was SaveAs'd.

Added help menu items for the Propeller Quick Reference, Propeller Manual and Propeller Demo Board Schematic.



---Bug Fixes---

Fixed bad syntax highlighting when an equal immediately follows a comment in CON section ( '= ).

Fixed corrupt label on About window that caused immediate exceptions upon execution.

Fixed Progress display to show current compiled code rather than the last object name in the immediate chain.

Fixed bug causing multiple versions to mistake each other's auto-recover files as their own.

Fixed bug causing exceptions upon resizing edits.

Fixed bug causing tab to be activated without updating status bar after a tab was deleted.

Fixed Info Window to properly color code the Info Box and the Memory Map.

Fixed source location methods to prevent rare error when creating an Archive.





Version 1.0

---General---

Added Preferences feature (Edit -> Preferences).  Includes options for changing syntax highlighting, file association checks, launching into single
or multiple editors, showing/hiding bookmarks, line numbers, and block group indicators, auto-recover, saving and loading syntax schemes.

Updated color scheme.

Standardized sounds for all messages.

Enhanced forms to reposition themselves if they are more than 50% outside of visible space.

Optimized compilation process.

Enhanced Find/Replace to allow blank Replace fields (so user can replace text with nothing if desired).

Enhanced serial routines to prevent tool from hogging CPU cycles unnecessarily.

Added Auto-Recovery feature; if a system failure occurs, the next session recovers the last-used files up to the point they were last compiled and
relays options to user.

Eliminated limit of 32 objects per Propeller Application.

Modified to decrease startup time by retaining Show Recent Only button state between sessions (press Show Recent Only button to limit Integrated
Explorer's workload).

Enhanced Archive error message "Object View Empty..." to be more clear.



---Bug Fixes---

Eliminated memory leak in compilation process.

Fixed bug preventing undo/redo after saves.

Fixed issue causing the tool to process many key presses twice.

Fixed bug that allowed out-of-range font size values.

Fixed menus from responding during application initialization.

Fixed syntax highlighting of code and doc comments after a LONG declaration in DAT block.

Fixed syntax highlighting of WORD and LONG declarations in DAT block after line end.

Fixed syntax highlighting of assembly local labels after instruction.

Fixed syntax highlighting of = operator after 2 or more spaces in CON block.




VERSION 0.98

---General---
Updated/Added Objects in Library.

Updated compiler to support multi-pass CON/VAR/OBJ blocks to allow CON-defined constants
to be used throughout those blocks.

Updated syntax highlighting rules to support IFNOT and ELSEIFNOT reserved words.

Enhanced Info's OpenFile method to indicate that file may not be a Propeller Application
file, upon error. 

Added Close All Others option to both Edit shortcuts and Edit Tab shortcuts.

Updated compiler to support TRUNC, ROUND, and FLOAT as automatic CONSTANT directives in
addition to their normal tasks.

Adjusted parser rules to not use _, $, or % as delimiters so that labels with underscores,
or hex or binary numbers are selected properly with double-clicks.

Enhanced serial communication to prevent sticking on invalid ports and to user better feedback.

Modified/Updated Shortcut keys to following:
  Ctrl + Shift + B : Show/Hide Bookmarks
  Ctrl + Shift + N : Show/Hide Line Numbers
  Ctrl + B         : Toggle current line's bookmark on/off
  Ctrl + N         : New file
  Ctrl + W         : Close current file
  ALT  + T         : Set Current File as Top File.

Removed Minimize/Maximize buttons from Object Info window.

Removed "+ Run" from Load RAM and Load EEPROM menu options.  Removed Load EEPROM menu option.
Updated hints.  Made corresponding changes to Object Info window.  Removed F12 and Ctrl + F12
as a shortcut keys.

Enhanced to allow opening *.binary and *.eeprom files into Object Info window.

Updated compiler to error out when literals greater than 9 bits are used in the source field of
assembly instructions.

Enhanced Archive to enabled status all the time; it now prompts user if the Object View is empty.

Updated compile to fix STRING bug when in CASE-OTHER block.



---Bug Fixes---
Fixed bug in Archive feature that caused it to truncate binary files.

Fixed bug causing Edit Tab shortcuts Close and Close All to not necessarily match up with that of
Edit shortcuts.




VERSION 0.95.1

---General---
Added copyright notice to About window.

Updated/Added Objects in Library.



---Bug Fixes---
Updated compiler to fix REBOOT command.

Updated Parallax font to v0.70.




VERSION 0.95

Initial pre-release.