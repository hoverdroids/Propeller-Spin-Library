{{
======================================================================

   File...... (HoverDroids)String Utils.spin
   Purpose... An aggregate of string functions found throughout OBEX
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Version History:
   1.0          07 26 2016 - Copied from STRINGS2
   1.1          07 26 2016 - Added GetSubStr - This updates the target string instead of adding a zero into the initial string.
                             The benefit is that the initial string is preserved.
   2.0          01 08 2019

======================================================================

----------------------------------------------------------------------
Derived from
----------------------------------------------------------------------
  (REF1)  FullDuplexSerialPlus
  (REF2)  Paul_StandardLibrary
  (REF3)  ASCII0_STREngine_1
  (REF4)  FloatString
  (REF5)  STRINGS
  (REF6)  STRINGS2

----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------
  This object is an aggregate of string functions found in all different
  objects throughout OBEX and other spin objects. These are listed in the
  header of this file under "Derived From". This consolidation aims to
  standardize the use of string methods in Spin, provide a single and
  predictable location for string helper methods, and standardize spin code.
  Hopefully this will save developers time and make developing on the
  Propeller more efficient.

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  strings:"(HoverDroids) String Utils"

  SomeMethod
  strings.strMethodName(input1,...,inputN)

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

----------------------------------------------------------------------
Notes from REF1: FullDuplexSerialPlus
----------------------------------------------------------------------
  Only the string functions are copied

  This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
  A .pdf copy of the book is available from www.parallax.com, and also through
  the Propeller Tool software's Help menu (v1.2.6 or newer).


  Version: 1.1

  This is the FullDuplexSerial object v1.1 from the Propeller Tool's Library
  folder with modified documentation and methods for converting text strings
  into numeric values in several bases.

----------------------------------------------------------------------
Notes from REF2: Paul_StandardLibrary
----------------------------------------------------------------------
  Only the string functions are copied here

  OBEX LIBRARY:
        http://obex.parallax.com/object/449

        This is a library of standard functions that I find useful in the Spin programs that I write.
        Email me with suggestions for additions and improvements!

        Paul Deffenbaugh's Standard Function Library
        http://paul.bluearray.net

        Created January 31, 2008
        Edited March 8, 2008

        Typically included as:
            std           : "Paul_StandardLibrary"       ' Paul's Standard Library

----------------------------------------------------------------------
Notes from REF3: ASCII0_STREngine_1
----------------------------------------------------------------------
  OBEX LISTING:
        http://obex.parallax.com/object/579

        A string library. The code has been fully optimized with a super simple spin interface for maximum speed and is also fully commented.

        Provides full support for:

        Building strings from characters,
        Accesseing built strings from characters,
        Comparing strings case sensitively,
        Comparing strings case insensitively,
        Preforming string copying,
        Preforming string concatenation,
        Converting strings to uppercase,
        Converting strings to lowercase,
        Triming white space from strings,
        Tokenizing strings with white space,
        Finding characters in strings,
        Finding strings in strings,
        Replacing characters in strings,
        Replacing strings in strings,
        Converting a number to a decimal string,
        Converting a decimal string to a number,
        Converting a number to a hexadecimal string,
        Converting a hexidecimal string to a number,
        Converting a number to a binary string,
        Converting a binary string to a number,

  Update History:

  v1.0 - Original release - 4/10/2009.
  v1.1 - Made code faster - 8/18/2009.
  v1.2 - Updated library functions, fixed bugs, and made code more robust against whitespace and capitalization - 7/27/2010.

  For each included copy of this object only one spin interpreter should access it at a time.

----------------------------------------------------------------------
Notes from REF4: FloatString
----------------------------------------------------------------------
  OBEX LISTING:
        http://obex.parallax.com/object/236

        v1.2: Updates 1.1 with StringToFloat
        v1.1: This is an update to the FloatString object. It adds the FloatToFormat routine to return a string of up to 9 characters with the specified number of decimal points. (e.g FloatToFormat(pi,5,2) would return the string " 3.14").

  Floating-Point <-> Strings v 1.2
  Single-precision IEEE-754
  v1.0 - 01 May 2006 - original version
  v1.1 - 12 Jul 2006 - added FloatToFormat routine
  v1.2 - 06 Mar 2009 - added StringToFloat [mpark]

----------------------------------------------------------------------
Notes from REF5: STRINGS
----------------------------------------------------------------------
  OBEX LISTING:
        http://obex.parallax.com/object/581

        A faster version can be found here: http://obex.parallax.com/object/582/ some precautions must be taken to change from v1.X to 2.X.

        Strings Library:Contains 13 string-affecting methods. Methods include StrToLower, StrToUpper, SubStr, StrParse, StrStr, StrPos, StrReplace, Combine, StrRev, Trim, StrPad, Capitalize, and StrRepeat. Some are similar in functionality to PHP's string functions by the same name.

        Updated demo by: Stefan Ludwig

  Below is a list of string-affecting methods some are very similar in functionality to PHP's string functions by the same name.

  v1.0  - 27/08/09 - Initial release includes StrToLower, StrToUpper, SubStr, StrStr, and StrPos methods.
  v1.1  - 28/08/09 - StrToUpper/Lower have been sped up. Fixed SubStr's negative values.
  v1.2  - 02/09/09 - Added StrReplace, Combine, StrRev, Trim, StrPad, and Capitalize; removed STR_MAX_LENGTH limit from StrPos.
  v1.3  - 08/09/09 - Major speed updates from v1.2. Added StrRepeat and StrParse (simpler/faster version of SubStr).
  v1.31 - 16/11/09 - Fixed bug in StrPad when using PAD_LEFT. Fix for StrPos; last character was ingored.

  *STRINGS2 improves STRINGS, which means the functions will have the same name. In that case, we will assume that the STRINGS2 version
   updated the STRINGS version and we will note the reference to STRINGS without listing the outdated function

----------------------------------------------------------------------
Notes from REF6: STRINGS2
----------------------------------------------------------------------
  OBEX LISTING:

        http://obex.parallax.com/object/582

        Strings Library v2:Contains 17 string-affecting methods. Methods include Capitalize, CharPos, CharRPos, Concatenate, Pad, Parse, StrCount, StrPos, StrRepeat, StrReplace, StrRev, StrStr, StrToLower, StrToUpper, SubStr, Trim, and WordWrap. Some are similar in functionality to PHP's string functions by the same name.

        Version 2 and 1 are being kept separate because different precautions are needed for each. It is not to be used as a drop-in replacement. Be sure to read the documentation to understand the method differences.

        A list of methods that may return a string that is longer than the original passed string, thus requiring special setup: StrReplace, Concatenate, Pad, StrRepeat, and WordWrap.

        All methods in Version 2 are faster than version 1.X except StrPos which is the same, and StrRev which is 33% slower.

        String-affecting methods. Some are very similar in functionality to PHP's string functions by the same name.

  Version 2 functions may place strings into the original address which are longer than the original string. This can cause unexpected
  results if original string are unprepared. Be sure to allow for expanding strings by reserving space for them (in the parent
  object). View Strings_demo.spin for a few examples on how to prepare the strings. Here is a list of methods that may return a string
  that is longer than the original passed string: StrReplace, Concatenate, Pad, StrRepeat, and WordWrap.

  v1.X  - 16/11/09 - Available here: obex.parallax.com/objects/502/ . Limits total string size to arbitrary limit, Reduces possible string
                     overflow problems.
  v2.0  - 18/11/09 - Changed functions to alter passed strings instead of creating new ones. This greatly speeds up some functions and allows
                     most of them to now be nested within other String Library calls. It also reduces variable space as well as overall
                     program size. Input strings are no longer limited to STR_MAX_LENGTH, only "search" strings are limited to this size.
  v2.1  - 19/11/09 - Added StrCount, WordWrap, CharPos, and CharRPos.

}}

CON
  STR_MAX_LENGTH = 32        'REF6 REF5 limit of string size of search strings
  #0,PAD_RIGHT,PAD_LEFT      'REF6 REF5 Set padding modes via enumerations (ie PR = 0, PL = 1, ...)

VAR
  'TODO:See comment below
  'NOTE: BST will remove unused methods but not vars; consequently, these will all take up space unless we
  'call an init method that is based on the functions used - ie don't reserve space unless init is called

  byte tempstr[16]  'REF2

  word tokenStringPointer    'REF3
  byte decimalString[12], hexadecimalString[9], binaryString[33], characterToStringPointer, characterToString[255] 'REF3

  long  p, digits, exponent, integer, tens, zeros,  precision  'REF4
  long  positive_chr, decimal_chr, thousands_chr, thousandths_chr  'REF4
  byte  float_string[20]  'REF4

  BYTE ostr[STR_MAX_LENGTH]  'REF6 REF5 Used when searching strings

OBJ
  ' The F object can be FloatMath, Float32 or Float32Full depending on the application
  ' TODO figure out how to resolve the objects issue - is there any way to pass object references
  '      so that this file can be Generalized?
  F : "FloatMath"

PUB InitStringSearch()
{
  Descr :

  Input :

  Return:
}

PUB InitFloatString()
{
  Descr :

  Input :

  Return:
}

PUB ToDec(strAddr) : value | char, index, multiply 'REF1                                                                           '[X]REF1
{
  Descr : Was StrToDec in REF1
          Converts a zero terminated string representation of a decimal number to a value

  Input : strAddr:the address of the first byte of the string that will be converted to decimal

  Return: N/A ... Modifies memory directly
}
  value := index := 0
  repeat until ((char := byte[strAddr][index++]) == 0)
    if char => "0" and char =< "9"
      value := value * 10 + (char - "0")
    if byte[strAddr] == "-"
      value := - value

PUB ToBin(strAddr) : value | char, index 'REF1                                                                                     '[X]REF1
{
  Descr : Was StrToBin in REF1.
          Converts a zero terminated string representaton of a binary number to a value

  Input : strAddr:the address of the first byte of the string that will be converted to binary

  Return: N/A ... Modifies memory directly
}
  value := index := 0
  repeat until ((char := byte[strAddr][index++]) == 0)
     if char => "0" and char =< "1"
        value := value * 2 + (char - "0")
  if byte[strAddr] == "-"
     value := - value

PUB ToHex(strAddr) : value | char, index 'REF1
{
  Descr : Was StrToHex in REF1.
          Converts a zero terminated string representaton of a hexadecimal number to a value

  Input : strAddr:the address of the first byte of the string that will be converted to hex

  Return: N/A ... Modifies memory directly
}
  value := index := 0
  repeat until ((char := byte[strAddr][index++]) == 0)
    if (char => "0" and char =< "9")
      value := value * 16 + (char - "0")
    elseif (char => "A" and char =< "F")
      value := value * 16 + (10 + char - "A")
    elseif(char => "a" and char =< "f")
      value := value * 16 + (10 + char - "a")
    if byte[strAddr] == "-"
      value := - value

PUB ToLower (strAddr)  'REF6 REF5
{
  Descr : Sets all letters A..Z in string to lowercase a..z

  Input : strAddr:the address of the first byte of the string that will be converted to hex

  Return: N/A ... Modifies memory directly

  EX:     strUtils.ToLower("aBcDeFgH 12345") => "abcdefgh 12345"
}
  result := strAddr--

  REPEAT strsize(result)
    CASE byte[++strAddr]
      "A".."Z": byte[strAddr] += 32                                             ' if byte is in the uppercase range, add 32 to byte

PUB ToUpper (strAddr)  'REF6 REF5
{
  Descr : Sets all letters A..Z in string to UPPERCASE A..Z

  Input : strAddr:the address of the first byte of the string that will be converted to hex

  Return: N/A ... Modifies memory directly

  EX:     strUtils.ToUpper("aBcDeFgH 12345") => "ABCEDFGH 12345"
}
  result := strAddr--

  REPEAT strsize(result)
    CASE byte[++strAddr]
      "a".."z": byte[strAddr] -= 32 ' if byte is in the lowercase range, subtract 32 to byte

PUB GetSubStr (strAddr, start, count, targetStrAddr, targetSize)|i,addr
{
  Descr : Copies part of the string at strAddr to the string at targetStrAddr.
          Both strAddr and targetStrAddr need to be the address of strings, ie byte arrays, and the
          target byte array must be long enough to hold the desired sub string or else it will get
          cutoff

  Input : strAddr:the address of the first byte of the string that will be converted to hex
          start:  byte to start searching
          count:  number of bytes to obtain from start
          targetStrAddr:destination address to store the substring
          targetSize:

  Return: N/A ... Modifies memory directly
}
  'First reset the target string
  bytefill(targetStrAddr,0,targetSize)

  i:=0
  addr:=strAddr + start
  repeat strsize(strAddr)
    if i++ > targetSize-2
      'avoid writing in adjacent variable space

      'But first terminate the string with a zero or else life goes to hell :(
      byte[targetStrAddr]:=0
      quit
    byte[targetStrAddr++]:=byte[addr++]

PUB SubStr (strAddr, start, count) | size  'REF6 REF5

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

PUB Parse (strAddr, start, count)  'REF6 REF5
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

PUB StrStr (strAddr, searchAddr, offset) | size, searchsize  'REF6 REF5
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

PUB StrPos (strAddr, searchAddr, offset) | size, searchsize  'REF6 REF5
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

PUB StrReplace (strAddr, searchAddr, replaceAddr) | size, searchsize, repsize, pos, loc  'REF6 REF5
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

PUB Concatenate (str1Addr, str2Addr)  'REF6 REF5
{{Previously: Combine
Appends str2 to the end of str1
Combine("12345", "6789")
Output: "123456789"
string 1 (str1Addr) needs to have additional space reserved enough for string 2 to be appended.
}}
  bytemove(str1Addr + strsize(str1Addr), str2Addr, strsize(str2Addr) + 1)       ' append

  RETURN str1Addr

PUB StrRev (strAddr) | i, size  'REF6 REF5
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

PUB Trim (strAddr) | i, size  'REF6 REF5
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

PUB Pad (strAddr, length, padstrAddr, lr) | size1, size2, len  'REF6 REF5
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

PUB StrRepeat (strAddr, count) | size  'REF6 REF5
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

PUB Capitalize (strAddr) | size  'REF6 REF5
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

PUB StrCount (strAddr, searchAddr) : count | size, searchsize, pos, loc  'REF6
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

PUB WordWrap (strAddr, CharWidth, LCD) | size, loc, lloc  'REF6
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

PUB CharPos (strAddr, char, offset, omax)  'REF6
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

PUB CharRPos (strAddr, char, offset, omax)  'REF6
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


PRI StrParse (strAddr, start, count)  'REF6
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

PUB buildString(character)'REF3 '' 4 Stack longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Builds a string from individual characters. Use "builtString" to get the address of the string.
'' //
'' // If the backspace character is put into the string it is automatically evaluated by removing the previous character.
'' //
'' // If 254 characters are put into the string all characters excluding backspace that are put into the string are ignored.
'' //
'' // Character - The next character to include in the string. Null will be ignored.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  ifnot(characterToStringPointer)
    bytefill(@characterToString, 0, 255)

  if(characterToStringPointer and (character == 8))
    characterToString[--characterToStringPointer] := 0

  elseif(character and (characterToStringPointer <> 254))
    characterToString[characterToStringPointer++] := character

PUB builtString(resetString) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns the pointer to the string built from individual characters.
'' //
'' // Reset - If true the next call to "buildString" will begin building a new string and the old string will be destroyed.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  characterToStringPointer &= not(resetString)
  return @characterToString

PUB builderNumber '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns the number of characters in the string builder buffer.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return characterToStringPointer

PUB builderFull '' 3 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Returns true if the string builder buffer is full and false if not.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  return (characterToStringPointer == 254)

PUB stringCompareCS(characters, otherCharacters) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Compares two strings case sensitively.
'' //
'' // Returns zero if the two strings are equal.
'' // Returns a positive value if "characters" comes lexicographically after "otherCharacters".
'' // Returns a negative value if "characters" comes lexicographically before "otherCharacters".
'' //
'' // Characters - A pointer to a string of characters.
'' // OtherCharacters - A pointer to another string of characters.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat
    result := (byte[characters] - byte[otherCharacters++])
  while(byte[characters++] and (not(result)))

PUB stringCompareCI(characters, otherCharacters) '' 9 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Compares two strings case insensitively.
'' //
'' // Returns zero if the two strings are equal.
'' // Returns a positive value if "characters" comes lexicographically after "otherCharacters".
'' // Returns a negative value if "characters" comes lexicographically before "otherCharacters".
'' //
'' // Characters - A pointer to a string of characters.
'' // OtherCharacters - A pointer to another string of characters.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat
    result := (ignoreCase(byte[characters]) - ignoreCase(byte[otherCharacters++]))
  while(byte[characters++] and (not(result)))

PUB stringCopy(whereToPut, whereToGet) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Copies a string from one location to another. This method can corrupt memory.
'' //
'' // Returns a pointer to the new string.
'' //
'' // WhereToPut - Address of where to put the copied string.
'' // WhereToGet - Address of where to get the string to copy.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  bytemove(whereToPut, whereToGet, (strsize(whereToGet) + 1))
  return whereToPut

PUB stringConcatenate(whereToPut, whereToGet) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Concatenates a string onto the end of another. This method can corrupt memory.
'' //
'' // Returns a pointer to the new string.
'' //
'' // WhereToPut - Address of the string to concatenate a string to.
'' // WhereToGet - Address of where to get the string to concatenate.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  bytemove((whereToPut + strsize(whereToPut)), whereToGet, (strsize(whereToGet) + 1))
  return whereToPut

PUB stringToLowerCase(characters) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Demotes all upper case characters in the set of ("A","Z") to their lower case equivalents.
'' //
'' // Characters - A pointer to a string of characters to convert to lowercase.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat strsize(characters--)
    result := byte[++characters]
    if((result => "A") and (result =< "Z"))
      byte[characters] := (result + 32)

PUB stringToUpperCase(characters) '' 4 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Promotes all lower case characters in the set of ("a","z") to their upper case equivalents.
'' //
'' // Characters - A pointer to a string of characters to convert to uppercase.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat strsize(characters--)
    result := byte[++characters]
    if((result => "a") and (result =< "z"))
      byte[characters] := (result - 32)

PUB trimString(characters) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Removes white space and new lines arround the outside of string of characters.
'' //
'' // Returns a pointer to the trimmed string of characters.
'' //
'' // Characters - A pointer to a string of characters to be trimmed.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := ignoreSpace(characters)
  characters := (result + ((strsize(result) - 1) #> 0))

  repeat
    case byte[characters]
      8 .. 13, 32, 127: byte[characters--] := 0
      other: quit

PUB tokenizeString(characters) '' 8 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Removes white space and new lines arround the inside of a string of characters.
'' //
'' // Returns a pointer to the tokenized string of characters, or an empty string when out of tokenized strings of characters.
'' //
'' // Characters - A pointer to a string of characters to be tokenized, or null to continue tokenizing a string of characters.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  if(characters)
    tokenStringPointer := characters

  result := tokenStringPointer := ignoreSpace(tokenStringPointer)

  repeat while(byte[tokenStringPointer])
    case byte[tokenStringPointer++]
      8 .. 13, 32, 127:
        byte[tokenStringPointer - 1] := 0
        quit

PUB findCharacter(stringToSearch, characterToFind) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Searches a string of characters for the first occurence of the specified character.
'' //
'' // Returns the address of that character if found and zero if not found.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // CharacterToFind - The character to find in the string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat strsize(stringToSearch--)
    if(byte[++stringToSearch] == characterToFind)
      return stringToSearch

PUB replaceCharacter(stringToSearch, characterToReplace, characterToReplaceWith) '' 11 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Replaces the first occurence of the specified character in a string of characters with another character.
'' //
'' // Returns the address of the next character after the character replaced on success and zero on failure.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // CharacterToReplace - The character to find in the string of characters to search.
'' // CharacterToReplaceWith - The character to replace the character found in the string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := findCharacter(stringToSearch, characterToReplace)
  if(result)
    byte[result++] := characterToReplaceWith

PUB replaceAllCharacters(stringToSearch, characterToReplace, characterToReplaceWith) '' 17 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Replaces all occurences of the specified character in a string of characters with another character.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // CharacterToReplace - The character to find in the string of characters to search.
'' // CharacterToReplaceWith - The character to replace the character found in the string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat while(stringToSearch)
    stringToSearch := replaceCharacter(stringToSearch, characterToReplace, characterToReplaceWith)

PUB findString(stringToSearch, stringToFind) | index, size '' 7 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Searches a string of characters for the first occurence of the specified string of characters.
'' //
'' // Returns the address of that string of characters if found and zero if not found.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // StringToFind - A pointer to the string of characters to find in the string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  size := strsize(stringToFind)
  if(size--)

    repeat strsize(stringToSearch--)
      if(byte[++stringToSearch] == byte[stringToFind])

        repeat index from 0 to size
          if(byte[stringToSearch][index] <> byte[stringToFind][index])
            result := true
            quit

        ifnot(result~)
          return stringToSearch

PUB replaceString(stringToSearch, stringToReplace, stringToReplaceWith) '' 13 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Replaces the first occurence of the specified string of characters in a string of characters with another string of
'' // characters. Will not enlarge or shrink a string of characters.
'' //
'' // Returns the address of the next character after the string of characters replaced on success and zero on failure.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // StringToReplace - A pointer to the string of characters to find in the string of characters to search.
'' // StringToReplaceWith - A pointer to the string of characters that will replace the string of characters found in the
'' //                       string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  result := findString(stringToSearch, stringToReplace)
  if(result)

    repeat (strsize(stringToReplaceWith) <# strsize(stringToReplace))
      byte[result++] := byte[stringToReplaceWith++]

PUB replaceAllStrings(stringToSearch, stringToReplace, stringToReplaceWith) '' 19 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Replaces all occurences of the specified string of characters in a string of characters with another string of
'' // characters. Will not enlarge or shrink a string of characters.
'' //
'' // StringToSearch - A pointer to the string of characters to search.
'' // StringToReplace - A pointer to the string of characters to find in the string of characters to search.
'' // StringToReplaceWith - A pointer to the string of characters that will replace the string of characters found in the
'' //                       string of characters to search.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat while(stringToSearch)
    stringToSearch := replaceString(stringToSearch, stringToReplace, stringToReplaceWith)

PUB integerToDecimal(number, length) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts an integer number to the decimal string of that number padded with zeros.
'' //
'' // Returns a pointer to the converted string.
'' //
'' // Number - A 32 bit signed integer number to be converted to a string.
'' // Length - The length of the converted string, "+" or "-" will be concatenated onto the head of converted string.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  length := (10 - ((length <# 10) #> 0))

  decimalString := "+"
  if(number < 0)
    decimalString := "-"

  if(number == negx)
    bytemove(@decimalString, string("-2147483648KA"), 11)

  else
    repeat result from 10 to 1
      decimalString[result] := ((||(number // 10)) + "0")
      number /= 10

  decimalString[length] := decimalString
  return @decimalString[length]

PUB integerToHexadecimal(number, length) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts an integer number to the hexadecimal string of that number padded with zeros.
'' //
'' // Returns a pointer to the converted string.
'' //
'' // Number - A 32 bit signed integer number to be converted to a string.
'' // Length - The length of the converted string, negative numbers need a length of 8 for sign extension.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat result from 7 to 0
    hexadecimalString[result] := lookupz((number & $F): "0".."9", "A".."F")
    number >>= 4

  return @hexadecimalString[8 - ((length <# 8) #> 0)]

PUB integerToBinary(number, length) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts an integer number to the binary string of that number padded with zeros.
'' //
'' // Returns a pointer to the converted string.
'' //
'' // Number - A 32 bit signed integer number to be converted to a string.
'' // Length - The length of the converted string, negative numbers need a length of 32 for sign extension.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  repeat result from 31 to 0
    binaryString[result] := ((number & 1) + "0")
    number >>= 1

  return @binaryString[32 - ((length <# 32) #> 0)]

PUB decimalToInteger(characters) | sign '' 10 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts a decimal string into an integer number. Expects a string with only "+-0123456789" characters.
'' //
'' // If the string has a "-" sign as its leading character the converted integer returned will be negated.
'' //
'' // If the string has a "+" sign as its leading character the converted integer returned will not be negated.
'' //
'' // Returns the converted integer. By default the number returned is positive and the "+" sign is unnecessary.
'' //
'' // Characters - A pointer to the decimal string to convert. The number returned will be 2's complement compatible.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  characters := checkSign(ignoreSpace(characters), @sign)

  repeat (strsize(characters) <# 10)
    ifnot(checkDigit(characters, "0", "9"))
      quit

    result := ((result * 10) + (byte[characters++] & $F))
  result *= sign

PUB hexadecimalToInteger(characters) | sign '' 10 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts a hexadecimal string into an integer number. Expects a string with only "+-0123456789ABCDEFabdcef" characters.
'' //
'' // If the string has a "-" sign as its leading character the converted integer returned will be negated.
'' //
'' // If the string has a "+" sign as its leading character the converted integer returned will not be negated.
'' //
'' // Returns the converted integer. By default the number returned is positive and the "+" sign is unnecessary.
'' //
'' // Characters - A pointer to the hexadecimal string to convert. The number returned will be 2's complement compatible.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  characters := checkSign(ignoreSpace(characters), @sign)

  repeat (strsize(characters) <# 8)
    ifnot(checkDigit(characters, "0", "9"))
      ifnot(checkDigit(characters, "A", "F") or checkDigit(characters, "a", "f"))
        quit

      result += $90_00_00_00
    result := ((result <- 4) + (byte[characters++] & $F))
  result *= sign

PUB binaryToInteger(characters) | sign '' 10 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Converts a binary string into an integer number. Expects a string with only "+-01" characters.
'' //
'' // If the string has a "-" sign as its leading character the converted integer returned will be negated.
'' //
'' // If the string has a "+" sign as its leading character the converted integer returned will not be negated.
'' //
'' // Returns the converted integer. By default the number returned is positive and the "+" sign is unnecessary.
'' //
'' // Characters - A pointer to the binary string to convert. The number returned will be 2's complement compatible.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  characters := checkSign(ignoreSpace(characters), @sign)

  repeat (strsize(characters) <# 32)
    ifnot(checkDigit(characters, "0", "1"))
      quit

    result := ((result << 1) + (byte[characters++] & 1))
  result *= sign

PRI ignoreCase(character) ' 4 Stack Longs

  result := character
  if((character => "a") and (character =< "z"))
    result -= 32

PRI ignoreSpace(characters) ' 4 Stack Longs

  result := characters
  repeat strsize(characters--)
    case byte[++characters]
      8 .. 13, 32, 127:
      other: return characters

PRI checkSign(characters, signAddress) ' 5 Stack Longs

  if(byte[characters] == "-")
    result := -1

  if(byte[characters] == "+")
    result := 1

  long[signAddress] := (result + ((not(result)) & 1))
  return (characters + (||result))

PRI checkDigit(characters, low, high) ' 5 Stack Longs

  result := byte[characters]
  return ((low =< result) and (result =< high))

PUB FloatToString(Single) : StringPtr  'REF4

''Convert floating-point number to string
''
''  entry:
''      Single = floating-point number
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  Magnitudes below 1e+12 and within 1e-12 will be expressed directly;
''  otherwise, scientific notation will be used.
''
''  examples                 results
''  -----------------------------------------
''  FloatToString(0.0)       "0"
''  FloatToString(1.0)       "1"
''  FloatToString(-1.0)      "-1"
''  FloatToString(^^2.0)     "1.414214"
''  FloatToString(2.34e-3)   "0.00234"
''  FloatToString(-1.5e-5)   "-0.000015"
''  FloatToString(2.7e+6)    "2700000"
''  FloatToString(1e11)      "100000000000"
''  FloatToString(1e12)      "1.000000e+12"
''  FloatToString(1e-12)     "0.000000000001"
''  FloatToString(1e-13)     "1.000000e-13"

  'perform initial setup
  StringPtr := Setup(Single)

  'eliminate trailing zeros
  if integer
    repeat until integer // 10
      integer /= 10
      tens /= 10
      digits--
  else
    digits~

  'express number according to exponent
  case exponent
    'in range left of decimal
    11..0:
      AddDigits(exponent + 1)
    'in range right of decimal
    -1..digits - 13:
      zeros := -exponent
      AddDigits(1)
    'out of range, do scientific notation
    other:
      DoScientific

  'terminate z-string
  byte[p]~


PUB FloatToScientific(Single) : StringPtr

''Convert floating-point number to scientific-notation string
''
''  entry:
''      Single = floating-point number
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  examples                           results
''  -------------------------------------------------
''  FloatToScientific(1e-9)            "1.000000e-9"
''  FloatToScientific(^^2.0)           "1.414214e+0"
''  FloatToScientific(0.00251)         "2.510000e-3"
''  FloatToScientific(-0.0000150043)   "-1.500430e-5"

  'perform initial setup
  StringPtr := Setup(Single)

  'do scientific notation
  DoScientific

  'terminate z-string
  byte[p]~


PUB FloatToMetric(Single, SuffixChr) : StringPtr | x, y

''Convert floating-point number to metric string
''
''  entry:
''      Single = floating-point number
''      SuffixChr = optional ending character (0=none)
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  Magnitudes within the metric ranges will be expressed in metric
''  terms; otherwise, scientific notation will be used.
''
''  range   name     symbol
''  -----------------------
''  1e24    yotta    Y
''  1e21    zetta    Z
''  1e18    exa      E
''  1e15    peta     P
''  1e12    tera     T
''  1e9     giga     G
''  1e6     mega     M
''  1e3     kilo     k
''  1e0     -        -
''  1e-3    milli    m
''  1e-6    micro    u
''  1e-9    nano     n
''  1e-12   pico     p
''  1e-15   femto    f
''  1e-18   atto     a
''  1e-21   zepto    z
''  1e-24   yocto    y
''
''  examples               results
''  ------------------------------------
''  metric(2000.0, "m")    "2.000000km"
''  metric(-4.5e-5, "A")   "-45.00000uA"
''  metric(2.7e6, 0)       "2.700000M"
''  metric(39e31, "W")     "3.9000e+32W"

  'perform initial setup
  StringPtr := Setup(Single)

  'determine thousands exponent and relative tens exponent
  x := (exponent + 45) / 3 - 15
  y := (exponent + 45) // 3

  'if in metric range, do metric
  if ||x =< 8
    'add digits with possible decimal
    AddDigits(y + 1)
    'if thousands exponent not 0, add metric indicator
    if x
      byte[p++] := " "
      byte[p++] := metric[x]
  'if out of metric range, do scientific notation
  else
    DoScientific

  'if SuffixChr not 0, add SuffixChr
  if SuffixChr
    byte[p++] := SuffixChr

  'terminate z-string
  byte[p]~


PUB FloatToFormat(single, width, dp) : stringptr | n, w2

''Convert floating-point number to formatted string
''
''  entry:
''      Single = floating-point number
''      width = width of field
''      dp = number of decimal points
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  asterisks are displayed for format errors
''  leading blank fill is used

  ' get string pointer
  stringptr := p := @float_string

  ' width must be 1 to 9, dp must be 0 to width-1
  w2 := width  :=  width #> 1 <# 9
  dp := dp #> 0 <# (width - 2)
  if dp > 0
    w2--
  if single & $8000_0000 or positive_chr
    w2--

  ' get positive scaled integer value
  n := F.FRound(F.FMul(single & $7FFF_FFFF , F.FFloat(teni[dp])))

  if n => teni[w2]
    ' if format error, display asterisks
    repeat while width
      if --width == dp
        if decimal_chr
          byte[p++] := decimal_chr
        else
          byte[p++] := "."
      else
        byte[p++] := "*"
    byte[p]~

  else
    ' store formatted number
    p += width
    byte[p]~

    repeat width
      byte[--p] := n // 10 + "0"
      n /= 10
      if --dp == 0
        if decimal_chr
          byte[--p] := decimal_chr
        else
          byte[--p] := "."
      if n == 0 and dp < 0
        quit

    ' store sign
    if single & $80000000
      byte[--p] := "-"
    elseif positive_chr
      byte[--p] := positive_chr
    ' leading blank fill
    repeat while p <> stringptr
      byte[--p] := " "

PUB SetPrecision(NumberOfDigits)

''Set precision to express floating-point numbers in
''
''  NumberOfDigits = Number of digits to round to, limited to 1..7 (7=default)
''
''  examples          results
''  -------------------------------
''  SetPrecision(1)   "1e+0"
''  SetPrecision(4)   "1.000e+0"
''  SetPrecision(7)   "1.000000e+0"

  precision := NumberOfDigits


PUB SetPositiveChr(PositiveChr)

''Set lead character for positive numbers
''
''  PositiveChr = 0: no character will lead positive numbers (default)
''            non-0: PositiveChr will lead positive numbers (ie " " or "+")
''
''  examples              results
''  ----------------------------------------
''  SetPositiveChr(0)     "20.07"   "-20.07"
''  SetPositiveChr(" ")   " 20.07"  "-20.07"
''  SetPositiveChr("+")   "+20.07"  "-20.07"

  positive_chr := PositiveChr


PUB SetDecimalChr(DecimalChr)

''Set decimal point character
''
''  DecimalChr = 0: "." will be used (default)
''           non-0: DecimalChr will be used (ie "," for Europe)
''
''  examples             results
''  ----------------------------
''  SetDecimalChr(0)     "20.49"
''  SetDecimalChr(",")   "20,49"

  decimal_chr := DecimalChr


PUB SetSeparatorChrs(ThousandsChr, ThousandthsChr)

''Set thousands and thousandths separator characters
''
''  ThousandsChr =
''        0: no character will separate thousands (default)
''    non-0: ThousandsChr will separate thousands
''
''  ThousandthsChr =
''        0: no character will separate thousandths (default)
''    non-0: ThousandthsChr will separate thousandths
''
''  examples                     results
''  -----------------------------------------------------------
''  SetSeparatorChrs(0, 0)       "200000000"    "0.000729345"
''  SetSeparatorChrs(0, "_")     "200000000"    "0.000_729_345"
''  SetSeparatorChrs(",", 0)     "200,000,000"  "0.000729345"
''  SetSeparatorChrs(",", "_")   "200,000,000"  "0.000_729_345"

  thousands_chr := ThousandsChr
  thousandths_chr := ThousandthsChr


PUB StringToFloat(strptr) : flt | significand, ssign, places, exp, esign
{{
  Converts string to floating-point number
  entry:
      strptr = pointer to z-string

  exit:
      flt = floating-point number


  Assumes the following floating-point syntax: [-] [0-9]* [ . [0-9]* ] [ e|E [-|+] [0-9]* ]
                                               ┌── ┌───── ┌─────────── ┌───────────────────
                                               │   │      │            │     ┌──── ┌─────
    Optional negative sign ────────────────────┘   │      │            │     │     │
    Digits ────────────────────────────────────────┘      │            │     │     │
    Optional decimal point followed by digits ────────────┘            │     │     │
    Optional exponent ─────────────────────────────────────────────────┘     │     │
      optional exponent sign ────────────────────────────────────────────────┘     │
      exponent digits ─────────────────────────────────────────────────────────────┘

  Examples of recognized floating-point numbers:
  "123", "-123", "123.456", "123.456e+09"
  Conversion stops as soon as an invalid character is encountered. No error-checking.

  Based on Ariba's StrToFloat in http://forums.parallax.com/forums/default.aspx?f=25&m=280607
  Expanded by Michael Park
}}
  significand~
  ssign~
  exp~
  esign~
  places~
  repeat
    case byte[strptr]
      "-":
        ssign~~
      ".":
        places := 1
      "0".."9":
        significand := significand * 10 + byte[strptr] - "0"
        if places
          ++places                    'count decimal places
      "e", "E":
        ++strptr ' skip over the e or E
        repeat
          case byte[strptr]
            "+":
              ' ignore
            "-":
              esign~~
            "0".."9":
              exp := exp * 10 + byte[strptr] - "0"
            other:
              quit
          ++strptr
        quit
      other:
        quit
    ++strptr

  if ssign
    -significand
  flt := f.FFloat(significand)

  ifnot esign  ' tenf table is in decreasing order, so the sign of exp is reversed
    -exp

  if places
    exp += places - 1

  flt := f.FMul(flt, tenf[exp])              'adjust flt's decimal point


PRI Setup(single) : stringptr

 'limit digits to 1..7
  if precision
    digits := precision #> 1 <# 7
  else
    digits := 7

  'initialize string pointer
  p := @float_string

  'add "-" if negative
  if single & $80000000
    byte[p++] := "-"
  'otherwise, add any positive lead character
  elseif positive_chr
    byte[p++] := positive_chr

  'clear sign and check for 0
  if single &= $7FFFFFFF

    'not 0, estimate exponent
    exponent := ((single << 1 >> 24 - 127) * 77) ~> 8

    'if very small, bias up
    if exponent < -32
      single := F.FMul(single, 1e13)
      exponent += result := 13

    'determine exact exponent and integer
    repeat
      integer := F.FRound(F.FMul(single, tenf[exponent - digits + 1]))
      if integer < teni[digits - 1]
        exponent--
      elseif integer => teni[digits]
        exponent++
      else
        exponent -= result
        quit

  'if 0, reset exponent and integer
  else
    exponent~
    integer~

  'set initial tens and clear zeros
  tens := teni[digits - 1]
  zeros~

  'return pointer to string
  stringptr := @float_string


PRI DoScientific

  'add digits with possible decimal
  AddDigits(1)
  'add exponent indicator
  byte[p++] := "e"
  'add exponent sign
  if exponent => 0
    byte[p++] := "+"
  else
    byte[p++] := "-"
    ||exponent
  'add exponent digits
  if exponent => 10
    byte[p++] := exponent / 10 + "0"
    exponent //= 10
  byte[p++] := exponent + "0"


PRI AddDigits(leading) | i

  'add leading digits
  repeat i := leading
    AddDigit
    'add any thousands separator between thousands
    if thousands_chr
      i--
      if i and not i // 3
        byte[p++] := thousands_chr
  'if trailing digits, add decimal character
  if digits
    AddDecimal
    'then add trailing digits
    repeat while digits
      'add any thousandths separator between thousandths
      if thousandths_chr
        if i and not i // 3
          byte[p++] := thousandths_chr
      i++
      AddDigit


PRI AddDigit

  'if leading zeros, add "0"
  if zeros
    byte[p++] := "0"
    zeros--
  'if more digits, add current digit and prepare next
  elseif digits
    byte[p++] := integer / tens + "0"
    integer //= tens
    tens /= 10
    digits--
  'if no more digits, add "0"
  else
    byte[p++] := "0"


PRI AddDecimal

  if decimal_chr
    byte[p++] := decimal_chr
  else
    byte[p++] := "."


DAT
        long                1e+38, 1e+37, 1e+36, 1e+35, 1e+34, 1e+33, 1e+32, 1e+31
        long  1e+30, 1e+29, 1e+28, 1e+27, 1e+26, 1e+25, 1e+24, 1e+23, 1e+22, 1e+21
        long  1e+20, 1e+19, 1e+18, 1e+17, 1e+16, 1e+15, 1e+14, 1e+13, 1e+12, 1e+11
        long  1e+10, 1e+09, 1e+08, 1e+07, 1e+06, 1e+05, 1e+04, 1e+03, 1e+02, 1e+01
tenf    long  1e+00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07, 1e-08, 1e-09
        long  1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19
        long  1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25, 1e-26, 1e-27, 1e-28, 1e-29
        long  1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38

teni    long  1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000

        byte "yzafpnum"
metric  byte 0
        byte "kMGTPEZY"
'--------------------------------------------------------
'-------------------String Manipulators------------------
'--------------------------------------------------------
PUB findInString(address,char,number) 'REF2

  repeat
    if byte[address] == char
      if number == 0
        return address+1
      else
        number--
    elseif byte[address] == 0
      return address
    address++

PUB strcat(baseStr,appendStr)   '' FuncSize: 3 longs
'' concatinates appendStr onto the end of baseStr
  bytemove(baseStr + strsize(baseStr),appendStr,strsize(appendStr))
  baseStr[strsize(baseStr)] := 0 ' null-terminate
  return baseStr

PUB strcopy(destStr,sourceStr)
'' copies sourceStr into destStr
  bytemove(destStr,sourceStr,strsize(sourceStr))
  destStr[strSize(sourceStr)] := 0 ' null-terminate
  return destStr

PUB strclr(input,n)
  bytefill(input,0,n)
  return input
'PUB strclr(input)
'  byte[input] := 0
'  return input
'
'PUB strclrn(input,n) | i
'  repeat i from 0 to n
'    byte[input + i] := 0
'  return input

PUB chartostr(input)
  tempstr[0] := input
  tempstr[1] := 0 ' null-terminate
  return @tempstr

dat
{{
  Copyright (C) 2016 - 2019 HoverDroids(TM)

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
}}
