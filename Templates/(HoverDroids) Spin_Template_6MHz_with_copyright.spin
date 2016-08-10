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

   File......
   Purpose...
   Author.... Chris Sprague
   E-mail.... HoverDroids@gmail.com
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

CON
  _clkmode = xtal1 + pll16x     'Standard clock mode * crystal frequency = 96 MHz
  _xinfreq = 6_000_000          'Only use with a 6MHz crystal

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
        
