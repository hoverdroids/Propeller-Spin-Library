{{
OBEX LISTING:
  http://obex.parallax.com/object/581

  A faster version can be found here: http://obex.parallax.com/object/582/ some precautions must be taken to change from v1.X to 2.X.

  Strings Library:Contains 13 string-affecting methods. Methods include StrToLower, StrToUpper, SubStr, StrParse, StrStr, StrPos, StrReplace, Combine, StrRev, Trim, StrPad, Capitalize, and StrRepeat. Some are similar in functionality to PHP's string functions by the same name.

  Updated demo by: Stefan Ludwig

  NOTE: This file was provided in the Strings Library v2, not the Strings Library,because it has
        a few updates that are not included in the original Strings Library.
}}

{{
********************
* Strings v1.3
********************
* Created by Brandon Nimon
* Created 27/08/09 (August 27, 2009)
* Copyright (c) 2009 Parallax, Inc.
* See end of file for terms of use. 
********************
* Below is a list of string-affecting methods some are very similar in functionality to PHP's string functions by the same name.
*
* v1.0  - 27/08/09 - Initial release includes StrToLower, StrToUpper, SubStr, StrStr, and StrPos methods.
* v1.1  - 28/08/09 - StrToUpper/Lower have been sped up. Fixed SubStr's negative values.
* v1.2  - 02/09/09 - Added StrReplace, Combine, StrRev, Trim, StrPad, and Capitalize; removed STR_MAX_LENGTH limit from StrPos.
* v1.3  - 08/09/09 - Major speed updates from v1.2. Added StrRepeat and StrParse (simpler/faster version of SubStr).
* v1.31 - 16/11/09 - Fixed bug in StrPad when using PAD_LEFT. Fix for StrPos; last character was ingored.
********************          
}}

CON
  
  STR_MAX_LENGTH = 128                                  ' limit of affected/added bytes in strings (affects most methods)
  #0,PAD_RIGHT,PAD_LEFT 

OBJ

VAR

  BYTE ostr[STR_MAX_LENGTH]
  BYTE ostr2[STR_MAX_LENGTH]                            ' used for StrReplace only

PUB StrToLower (strAddr) | i, size
{{Sets all letters A..Z in string to lowercase a..z.
StrToLower("aBcDeFgH 12345")
Output: "abcdefgh 12345"
}}
  size := strsize(strAddr) <# constant(STR_MAX_LENGTH - 1) 

  i := 0                           
  REPEAT size
    CASE byte[strAddr]
      "A".."Z": ostr[i++] := byte[strAddr++] + 32                               ' if byte is in the uppercase range, add 32 to byte
      OTHER: ostr[i++] := byte[strAddr++]                        

  ostr[i] := 0                                                                  ' terminate string                    
  RETURN @ostr

PUB StrToUpper (strAddr) | i, size
{{Sets all letters a..z in string to uppercase A..Z.
StrToUpper("aBcDeFgH 12345")
Output: "ABCDEFGH 12345"
}}
  size := strsize(strAddr) <# constant(STR_MAX_LENGTH - 1)  

  i := 0                             
  REPEAT size
    CASE byte[strAddr]
      "a".."z": ostr[i++] := byte[strAddr++] - 32                               ' if byte is in the lowercase range, subtract 32 from byte
      OTHER: ostr[i++] := byte[strAddr++]

  ostr[i] := 0                                                                  ' terminate string                            
  RETURN @ostr

PUB SubStr (strAddr, start, count) | size
{{Returns part of a string for count bytes starting from start byte.
NOTE: forward counting starts at 0.
example: char-position 01234567890
string:                ABCDEFGHIJK
SubStr("ABCDEFGHIJK",-4,2)
Output: "HI"
}}
  size := strsize(strAddr)

  IF (start < 0)                                                                ' if value is negative, go to the end of the string
    start := size + start
  IF (count < 0)                                                                ' if value is negative, go to the end of the string
    count := (size + count - start) <# constant(STR_MAX_LENGTH - 1)
  ELSE
    count <#= constant(STR_MAX_LENGTH - 1)
  
  bytemove(@ostr, strAddr + start, count)                                       ' just move the selected section

  ostr[count] := 0                                                              ' terminate string
  RETURN @ostr  

PUB StrParse (strAddr, start, count)
{{Returns part of a string for count bytes starting from start byte.
This is a faster and simpler version of SubStr.
NOTE: forward counting starts at 0.
example: char-position 01234567890
string:                ABCDEFGHIJK
SubParse("ABCDEFGHIJK",4,1)
Output: "E"
}}
  count <#= constant(STR_MAX_LENGTH - 1)
  bytemove(@ostr, strAddr + start, count)                                       ' just move the selected section

  ostr[count] := 0                                                              ' terminate string
  RETURN @ostr  

PUB StrStr (strAddr, searchAddr, offset) | searchsize
{{Finds first occurrence of search string and returns the remainder of str along with the search.
string: ABCDEFGHIJK
StrStr("ABCDEFGHIJK","GH",0)
Output: "GHIJK"
}}   
  searchsize := strsize(searchAddr)

  REPEAT UNTIL (offset + searchsize > STR_MAX_LENGTH)
    IF (strcomp(StrParse(strAddr, offset++, searchsize), searchAddr))             ' if string search found
      RETURN StrParse(strAddr, offset - 1, STR_MAX_LENGTH - offset)               ' return remainder of string
  RETURN false

PUB StrPos (strAddr, searchAddr, offset) | size, searchsize
{{Returns location of first occurrence of search in str, returns -1 if search is not found.
NOTE: counting starts at 0. 0 can be returned if search is found at first character of str.
Faster than strstr if just searching for a string inside another str.
StrPos("ABCDEFGHIJK","GH",0)
Output: 6
}}
  size := strsize(strAddr) + 1
  searchsize := strsize(searchAddr)

  REPEAT UNTIL (offset + searchsize > size)
    IF (strcomp(StrParse(strAddr, offset++, searchsize), searchAddr))           ' if string search found
      RETURN offset - 1                                                         ' return byte location
  RETURN -1

PUB StrReplace (strAddr, searchAddr, replaceAddr) | searchsize, repsize, dpos, spos, loc
{{Replace search strings with repalce within str.
StrReplace("this test is a test", "test", "mouse")
Output: "this mouse is a mouse"
OMITTED because of use of second ostr. Uncomment this method and the ostr2 variable in VAR block to use this.
}}               
  searchsize := strsize(searchAddr)
  repsize := strsize(replaceAddr)
  bytefill(@ostr2, 0, STR_MAX_LENGTH)

  dpos := 0                                                                         ' destination position
  spos := 0                                                                         ' source position
  REPEAT WHILE (((loc := StrPos(strAddr, searchAddr, spos)) <> -1) AND dpos + loc - spos + repsize < STR_MAX_LENGTH) ' while a search string exists
    bytemove(@ostr2 + dpos, strAddr + spos, loc - spos)
    dpos += loc - spos
    spos := loc + searchsize
    bytemove(@ostr2 + dpos, replaceAddr, repsize)
    dpos += repsize
  
  bytemove(@ostr2 + dpos, strAddr +  spos, (strsize(strAddr) - spos) <# (constant(STR_MAX_LENGTH - 1) - dpos)) 
  RETURN @ostr2 

PUB Combine (str1Addr, str2Addr) | size1, size2, tmp
{{Appends str2 to the end of str1
Combine("12345", "6789")
Output: "123456789"
}}
  size1 := strsize(str1Addr)
  size2 := strsize(str2Addr)                                 

  bytemove(@ostr, str1Addr, size1 <# constant(STR_MAX_LENGTH - 1))              ' move string 1
  IF (size1 < STR_MAX_LENGTH)
    bytemove(@ostr + (size1 <# STR_MAX_LENGTH), str2Addr, (constant(STR_MAX_LENGTH - 1) - size1) <# size2) ' move string 2

  ostr[(size1 + size2) <# STR_MAX_LENGTH] := 0                                  ' terminate string
  RETURN @ostr                                                                                          

PUB StrRev (strAddr) | i, size
{{Reverse the order of a string
StrRev("12345")
Output: "54321"
}}
  size := strsize(strAddr) <# constant(STR_MAX_LENGTH - 1)  

  i := 0
  REPEAT size--
    ostr[i++] := byte[strAddr][size - i]                                        ' grab bytes starting at the end

  ostr[i] := 0                                                                  ' terminate string
  RETURN @ostr

PUB Trim (strAddr) | i, j, size 
{{Removes byte characters 9,10,11,13,32 from beginning and end of a string
Trim(" Test here ",13)
Output: "Test here"
}}
  size := strsize(strAddr)             

  i := 0
  REPEAT WHILE (i < size)                                                       ' look at beginning of string
    CASE byte[strAddr][i]
      9..11,13,32: i++
      OTHER: QUIT
  IF (i => size)
    RETURN @ostr

  j := size 
  REPEAT WHILE (j > i)                                                          ' look at end of string
    CASE byte[strAddr][--j]
      9..11,13,32: 
      OTHER: QUIT

  IF (++j == i)                                                                 ' if the end and beginning trim meet in the middle, fail
    RETURN @ostr

  bytemove(@ostr, strAddr + i, (j - i) <# constant(STR_MAX_LENGTH - 1))         ' move remaining string

  ostr[(j - i) <# STR_MAX_LENGTH] := 0                                          ' terminate string
  RETURN @ostr

PUB StrPad (strAddr, length, padstrAddr, lr) | size1, size2, len
{{Pad a string with another string to length.
lr is to pad the left or right. You can use STR#PAD_RIGHT or STR#PAD_LEFT. 
Truncates str to length if it is longer than length
StrPad("short", 10, "-_-", STR#PAD_RIGHT)
Output: "short-_--_"
}}
  size1 := strsize(strAddr) <# constant(STR_MAX_LENGTH - 1)

  len := length <#= constant(STR_MAX_LENGTH - 1)
  size2 := strsize(padstrAddr) <# (length - size1)             
                             
  IF (size1 < length)               
    CASE lr
      PAD_RIGHT:
        bytemove(@ostr, strAddr, size1)                                         ' move str to output
        REPEAT WHILE (size1 + size2 < length)                                   ' repeat until output would overfill
          bytemove(@ostr + size1, padstrAddr, size2)                            ' put pad in output
          size1 += size2
        bytemove(@ostr + size1, padstrAddr, length - size1)                     ' fill output to length
      PAD_LEFT:
        bytemove(@ostr + length - size1, strAddr, size1)                        ' move str to end of output
        length -= size1~  
        REPEAT WHILE (size1 + size2 < length)                                   ' repeat until pad would encroach on str
          bytemove(@ostr + size1, padstrAddr, size2)                            ' put pad in output
          size1 += size2
        bytemove(@ostr + size1, padstrAddr, length - size1)                     ' fill output to beginning of str
      OTHER:                            
        bytemove(@ostr, strAddr, length)                                        ' just place str in output
  ELSE                               
    bytemove(@ostr, strAddr, length)                                            ' just place str in output

  ostr[len] := 0                                                                ' terminate string
  RETURN @ostr    

PUB StrRepeat (strAddr, count) | size, i
{{Returns a string with str repeated count times.
StrRepeat ("-=", 10)
Output: "-=-=-=-=-=-=-=-=-=-="
}}
  size := strsize(strAddr)

  IF (size * count < constant(STR_MAX_LENGTH - 1))
    i := 0
    REPEAT count
      bytemove(@ostr + i, strAddr, size)
      i += size 
  ELSE
    i := 0
    REPEAT WHILE (i + size < constant(STR_MAX_LENGTH - 1))
      bytemove(@ostr + i, strAddr, size)
        i += size
    bytemove(@ostr + i, strAddr, size <# (constant(STR_MAX_LENGTH - 1) - i))
    i += size <# (constant(STR_MAX_LENGTH - 1) - i)

  ostr[i <# STR_MAX_LENGTH] := 0
  RETURN @ostr     

PUB Capitalize (strAddr) | i, size
{{Capitalize letters that follow white space (byte characters: 1-32)
Capitalize("test THIS string")
Output: "Test THIS String"
}}
  size := strsize(strAddr) <# constant(STR_MAX_LENGTH - 1)  

  i := 0
  CASE byte[strAddr]                                                            ' check first character (no previous character which the below loop looks for)
    97..122: ostr[i++] := byte[strAddr++] - 32
    OTHER: ostr[i++] := byte[strAddr++]
  
  REPEAT WHILE (i < size)                                                       
    CASE byte[strAddr - 1]                                                      ' if previous byte is byte code 9,10,11,13, or 32 capitalize
      1..32:      
        CASE byte[strAddr]  
          "a".."z": ostr[i++] := byte[strAddr++] - 32
          OTHER: ostr[i++] := byte[strAddr++]
      OTHER: ostr[i++] := byte[strAddr++]

  ostr[i] := 0                                                                  ' terminate string
  RETURN @ostr
    
  
DAT
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
