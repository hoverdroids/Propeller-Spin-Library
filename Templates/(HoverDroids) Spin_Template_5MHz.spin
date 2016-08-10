{
======================================================================
 
  Copyright (C) YYYY Your Company Name(TM)

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

   File......
   Purpose...
   Author.... 
   E-mail.... 
   Started... MM DD YYYY
   Updates... MM DD YYYY
   
======================================================================

----------------------------------------------------------------------
Derived from 
----------------------------------------------------------------------
  (REF1)  SpinObject1
  (REF2)  SpinObject2
  (REF3)  SpinObject3

  Different usage of references in code are list off the right side of the screen
  with the following format:

  [X]REF1 [ ]REF3               A version of the method is in found in
                                REF1 & REF3. The REF1 is used instead.
  [+]REF3                       REF3 has added this line vs other versions
  [-]REF1                       REF1 has removed this line vs other versions
  [M]REF1                       REF1 has modified this line vs other versions
----------------------------------------------------------------------
Program Description
----------------------------------------------------------------------

----------------------------------------------------------------------
Usage
----------------------------------------------------------------------
  To use this object in your code, declare it as shown below:

  OBJ
  objNickName:"Object Name"

  SomeMethod
  objNickName.objMethod(input1,...,inputN)

----------------------------------------------------------------------
Usage Notes
----------------------------------------------------------------------
  
}

CON
  _clkmode = xtal1 + pll16x     'Standard clock mode * crystal frequency = 96 MHz
  _xinfreq = 5_000_000          'Only use with a 5MHz crystal

VAR
  long  symbol
   
OBJ
  nickname      : "object_name"
  
PUB public_method_name
{
  Descr : ...

  Input : ...

  Return: ...
}

PRI private_method_name
{
  Descr : ...

  Input : ...

  Return: ...
}

DAT
name    byte  "string_data",0       '
        
