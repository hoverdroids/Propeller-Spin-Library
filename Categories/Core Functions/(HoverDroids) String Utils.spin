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

   File...... (HoverDroids)String Utils.spin
   Purpose... An aggregate of string functions found throughout OBEX
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
   Started... 08 08 2016
   Updates... 08 08 2016

======================================================================

----------------------------------------------------------------------
Derived from
----------------------------------------------------------------------
  (REF1)  FullDuplexSerialPlus

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
}

PUB StrToDec(stringptr) : value | char, index, multiply                                                                           '[X]REF1
{
  Descr : Converts a zero terminated string representation of a decimal number to a value

  Input : stringptr:the address of the first byte of the string that will be converted to decimal

  Return: The corresponding value
}
  value := index := 0
  repeat until ((char := byte[stringptr][index++]) == 0)
    if char => "0" and char =< "9"
      value := value * 10 + (char - "0")
    if byte[stringptr] == "-"
      value := - value

PUB StrToBin(stringptr) : value | char, index                                                                                     '[X]REF1
{
  Descr : Converts a zero terminated string representaton of a binary number to a value

  Input : stringptr:the address of the first byte of the string that will be converted to binary

  Return: The corresponding value
}
  value := index := 0
  repeat until ((char := byte[stringptr][index++]) == 0)
     if char => "0" and char =< "1"
        value := value * 2 + (char - "0")
  if byte[stringptr] == "-"
     value := - value

PUB StrToHex(stringptr) : value | char, index
{
  Descr : Converts a zero terminated string representaton of a hexadecimal number to a value

  Input : stringptr:the address of the first byte of the string that will be converted to hex

  Return: The corresponding value
}
  value := index := 0
  repeat until ((char := byte[stringptr][index++]) == 0)
    if (char => "0" and char =< "9")
      value := value * 16 + (char - "0")
    elseif (char => "A" and char =< "F")
      value := value * 16 + (10 + char - "A")
    elseif(char => "a" and char =< "f")
      value := value * 16 + (10 + char - "a")
    if byte[stringptr] == "-"
      value := - value

