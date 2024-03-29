{{
OBEX LISTING:
  http://obex.parallax.com/object/582

  Strings Library v2:Contains 17 string-affecting methods. Methods include Capitalize, CharPos, CharRPos, Concatenate, Pad, Parse, StrCount, StrPos, StrRepeat, StrReplace, StrRev, StrStr, StrToLower, StrToUpper, SubStr, Trim, and WordWrap. Some are similar in functionality to PHP's string functions by the same name.

  Version 2 and 1 are being kept separate because different precautions are needed for each. It is not to be used as a drop-in replacement. Be sure to read the documentation to understand the method differences.

  A list of methods that may return a string that is longer than the original passed string, thus requiring special setup: StrReplace, Concatenate, Pad, StrRepeat, and WordWrap.

  All methods in Version 2 are faster than version 1.X except StrPos which is the same, and StrRev which is 33% slower.
}}

{{
********************
* Strings v2.1
********************
* Created by Brandon Nimon
* Created 27/08/09 (August 27, 2009)
* Copyright (c) 2009 Parallax, Inc.
* See end of file for terms of use. 
********************
* String-affecting methods. Some are very similar in functionality to PHP's string functions by the same name.
*
* Notes: Version 2 functions may place strings into the original address which are longer than the original string. This can cause unexpected
*        results if original string are unprepared. Be sure to allow for expanding strings by reserving space for them (in the parent
*        object). View Strings_demo.spin for a few examples on how to prepare the strings. Here is a list of methods that may return a string
*        that is longer than the original passed string: StrReplace, Concatenate, Pad, StrRepeat, and WordWrap.
*
*
* v1.X  - 16/11/09 - Available here: obex.parallax.com/objects/502/ . Limits total string size to arbitrary limit, Reduces possible string
*                    overflow problems.
* v2.0  - 18/11/09 - Changed functions to alter passed strings instead of creating new ones. This greatly speeds up some functions and allows
*                    most of them to now be nested within other String Library calls. It also reduces variable space as well as overall
*                    program size. Input strings are no longer limited to STR_MAX_LENGTH, only "search" strings are limited to this size.
* v2.1  - 19/11/09 - Added StrCount, WordWrap, CharPos, and CharRPos.
********************          
}}

CON
  
  STR_MAX_LENGTH = 32                                   ' limit of string size of search strings 
  #0,PAD_RIGHT,PAD_LEFT 

OBJ

VAR

  BYTE ostr[STR_MAX_LENGTH]                             

PUB StrToLower (strAddr)
{{Sets all letters A..Z in string to lowercase a..z.
StrToLower("aBcDeFgH 12345")
Output: "abcdefgh 12345"
}}
  result := strAddr--  

  REPEAT strsize(result)
    CASE byte[++strAddr]
      "A".."Z": byte[strAddr] += 32                                             ' if byte is in the uppercase range, add 32 to byte

PUB StrToUpper (strAddr)
{{Sets all letters a..z in string to uppercase A..Z.
StrToUpper("aBcDeFgH 12345")
Output: "ABCDEFGH 12345"
}}
  result := strAddr--  

  REPEAT strsize(result)
    CASE byte[++strAddr]
      "a".."z": byte[strAddr] -= 32                                             ' if byte is in the lowercase range, subtract 32 to byte

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
    count := (size + count - start)

  byte[strAddr + start + count] := 0                                            ' terminate string
  RETURN strAddr + start  

PUB Parse (strAddr, start, count)
{{Previously: StrParse
Returns part of a string for count bytes starting from start byte.
This is a faster and simpler version of SubStr.
NOTE: forward counting starts at 0.
example: char-position 01234567890
string:                ABCDEFGHIJK
SubParse("ABCDEFGHIJK",4,1)
Output: "E"
}}
  strAddr += start
  byte[strAddr + count] := 0                                                    ' terminate string
  RETURN strAddr 

PUB StrStr (strAddr, searchAddr, offset) | size, searchsize
{{Finds first occurrence of search string and returns the remainder of str along with the search.
string: ABCDEFGHIJK
StrStr("ABCDEFGHIJK","GH",0)
Output: "GHIJK"
}}   
  size := strsize(strAddr) + 1
  searchsize := strsize(searchAddr)         

  REPEAT UNTIL (offset + searchsize > size)   
    IF (strcomp(StrParse(strAddr, offset++, searchsize), searchAddr))           ' if string search found
      RETURN Parse(strAddr, offset - 1, size - offset)                          ' return remainder of string
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

PUB StrReplace (strAddr, searchAddr, replaceAddr) | size, searchsize, repsize, pos, loc
{{Replace search strings with repalce within str.
StrReplace("this test is a test", "test", "mouse")
Output: "this mouse is a mouse"
input string (strAddr) needs to have additional space reserved if/when replace string is longer than search string.
}}
  size := strsize(strAddr) + 1              
  searchsize := strsize(searchAddr)
  repsize := strsize(replaceAddr)    
  
  pos := 0
  REPEAT WHILE ((loc := StrPos(strAddr, searchAddr, pos)) <> -1)                ' while a search string exists
    bytemove(strAddr + loc + repsize, strAddr + loc + searchsize, size - loc)   ' move remainder of string to make room for replacement string
    bytemove(strAddr + loc, replaceAddr, repsize)                               ' move replacement string into position
    pos := loc + repsize

  RETURN strAddr 

PUB Concatenate (str1Addr, str2Addr)
{{Previously: Combine
Appends str2 to the end of str1
Combine("12345", "6789")
Output: "123456789"
string 1 (str1Addr) needs to have additional space reserved enough for string 2 to be appended.
}}
  bytemove(str1Addr + strsize(str1Addr), str2Addr, strsize(str2Addr) + 1)       ' append           

  RETURN str1Addr    

PUB StrRev (strAddr) | i, size
{{Reverse the order of a string
StrRev("12345")
Output: "54321"
}}
  size := strsize(strAddr)  

  i := 0
  REPEAT size / 2
    byte[size] := byte[strAddr + i]
    byte[strAddr + i] := byte[strAddr + size - i - 1]                           ' grab bytes starting at the end
    byte[strAddr + size - i++ - 1] := byte[size]

  byte[size] := 0                                                               ' terminate string
  RETURN strAddr

PUB Trim (strAddr) | i, size 
{{Removes byte characters 9,10,11,13,32 from beginning and end of a string
Trim(" Test here ",13)
Output: "Test here"
}}
  size := strsize(strAddr)
  result := strAddr

  REPEAT size                                                                   ' look at beginning of string
    CASE byte[result]
      9..11,13,32: result++
      OTHER: QUIT

  i := strAddr + size
  REPEAT WHILE (i > result)                                                     ' look at end of string
    CASE byte[i--]
      9..11,13,32:
      OTHER: QUIT

  byte[i - 1] := 0           

PUB Pad (strAddr, length, padstrAddr, lr) | size1, size2, len
{{Previously: StrPad
Pad a string with another string to length.
lr is to pad the left or right. You can use STR#PAD_RIGHT or STR#PAD_LEFT. 
Truncates str to length if it is longer than length
StrPad("short", 10, "-_-", STR#PAD_RIGHT)
Output: "short-_--_"
input string (strAddr) needs to have additional space reserved for padding.
}}
  size1 := strsize(strAddr)               
  size2 := strsize(padstrAddr)
  len := length                  
                             
  IF (size1 < length)               
    CASE lr
      PAD_RIGHT:
        REPEAT WHILE (size1 + size2 < length)                                   ' repeat until output would overfill
          bytemove(strAddr + size1, padstrAddr, size2)                          ' put pad in output
          size1 += size2
        bytemove(strAddr + size1, padstrAddr, length - size1)                   ' fill output to length
      PAD_LEFT:
        bytemove(strAddr + length - size1, strAddr, size1)                      ' move str to end of output
        length -= size1~  
        REPEAT WHILE (size1 + size2 < length)                                   ' repeat until pad would encroach on str
          bytemove(strAddr + size1, padstrAddr, size2)                          ' put pad in output
          size1 += size2
        bytemove(strAddr + size1, padstrAddr, length - size1)                   ' fill output to beginning of str

  byte[strAddr + len] := 0                                                      ' terminate string
  RETURN strAddr                                                                

PUB StrRepeat (strAddr, count) | size
{{Returns a string with str repeated count times. Count must be a minimum of 1.
StrRepeat ("-=", 10)
Output: "-=-=-=-=-=-=-=-=-=-="
input string (strAddr) needs to have additional space reserved for repeating.
}}
  size := strsize(strAddr)
  result := strAddr  
          
  REPEAT count - 1 
    bytemove(strAddr += size, result, size)

  byte[strAddr + size] := 0                                                     ' terminate string

PUB Capitalize (strAddr) | size
{{Capitalize letters that follow white space (byte characters: 0-32)
Capitalize("test THIS string")
Output: "Test THIS String"
}}
  size := strsize(strAddr)
  result := strAddr  
          
  CASE byte[strAddr]                                                            ' check first character (no previous character which the below loop looks for)
    "a".."z": byte[strAddr] -= 32
  
  REPEAT size - 1                                                       
    IF (byte[strAddr++] =< 32)                                                  ' if previous byte is byte code 9,10,11,13, or 32 capitalize
      CASE byte[strAddr]  
        "a".."z": byte[strAddr] -= 32      

PUB StrCount (strAddr, searchAddr) : count | size, searchsize, pos, loc
{{Count the number of times a search string occurs in a string.
StrCount("test misconception testimonials", "test")
Output: 2
}}
  size := strsize(strAddr) + 1              
  searchsize := strsize(searchAddr)   

  count := pos := 0     
  REPEAT WHILE ((loc := StrPos(strAddr, searchAddr, pos)) <> -1)                ' while a search string exists
    count++
    pos := loc + searchsize  

PUB WordWrap (strAddr, CharWidth, LCD) | size, loc, lloc
{{Adds carriage return when a line reaches CharWidth.
If LCD is set true, carriage return is left out if line is already filled (Parallax-sold LCDs automatically move to next line).
NOTE: If a word is reached that is longer than CharWidth, it is displayed over multiple lines.
      It is assumed input string does not contain any characters less than ASCII 32. That includes line breaks. If it does, it
        will be considered just another character.
WordWrap("this is a test of superduperwrapping.", 10, 0)
Output: "this is a",13,"test of",13,"superduper",13,"wrapping." 
}}
  size := strsize(strAddr)
             
  loc := lloc := 0 
  REPEAT WHILE (size => loc + CharWidth)
    IF ((loc := CharRPos(strAddr, " ", loc, CharWidth + loc + 1)) <> -1)
      IF (LCD AND loc == lloc + CharWidth)
        bytemove(strAddr + loc, strAddr + loc + 1, size - loc)
        lloc := loc
      ELSE
        byte[strAddr + loc] := $D 
        lloc := ++loc
    ELSE                                                                        ' word is too long
      lloc += CharWidth
      IF (LCD)
        loc := lloc
      ELSE                                                             
        bytemove(strAddr + lloc + 1, strAddr + lloc, size - lloc)
        byte[strAddr + lloc] := $D
        loc := ++lloc                                                           ' move new location into loc
 
  RETURN strAddr  

PUB CharPos (strAddr, char, offset, omax)
{{Returns location of first occurrence of a character, searching from offset in str, returns -1 if search is not found.
NOTE: 0 can be returned if search is found at first character of str (thus -1 is considered false).
      Method counts toward omax of string from offset, so an offset equal to or less than omax will always return -1. 
CharPos("ABHCDEFGHIJK",H,0,11)
Output: 2
}}
  REPEAT WHILE (offset++ < omax)
    IF (byte[strAddr + offset] == char)
      RETURN offset
  RETURN -1

PUB CharRPos (strAddr, char, offset, omax)
{{Returns location of last occurrence of a character (before omax), searching from offset in str, returns -1 if search is not found.
NOTE: 0 can be returned if search is found at first character of str (thus -1 is considered false).
      Method counts toward offset of string from omax, so an omax equal to or less than offset will always return -1. 
CharRPos("ABHCDEFGHIJK",H,11,0)
Output: 8
}}
  REPEAT WHILE (omax-- > offset)
    IF (byte[strAddr + omax] == char)
      RETURN omax
  RETURN -1

    
PRI StrParse (strAddr, start, count)
{{Used for StrStr and StrPos (and thus StrReplace) for searches.
Returns part of a string for count bytes starting from start byte.
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
