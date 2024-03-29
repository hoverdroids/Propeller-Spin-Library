{{
OBEX LISTING:

  http://obex.parallax.com/object/580

  The StringKeyMap is an associative array interface.
  The keys are null-terminated strings. The values may be arbitrary-length binary data,
  but pure-string methods are included for string/string maps.
}}

{{
 StringKeyMap 
 by Chris Cantrell
 Version 1.1 6/27/2011
 Copyright (c) 2011 Chris Cantrell
 See end of file for terms of use.
}}

{{

 StringKeyMap

 This is a simple implementation of an associative mapping data structure. The
 keys in the map are null-terminated strings. The values can be any size binary
 data, but the primary API is written with string/string maps in mind.

 The first argument to each function is a pointer to a map's data structure. The
 methods maintain the structure in memory as follows:

     MaxSize (2 bytes LSB first)
     CurSize (2 bytes LSB first)

       Key (bytes of key string null terminated)
       ValueSize (2 bytes LSB first)
       ValueBytes (bytes of value data)
    
       ,,, other key/values

 This implementation does NOT optimize for search speed. It is a simple implementation
 of the map API.
}}

PUB new(ptr,maxSize)
'
'' This function initializes a map data structure. The maxSize is
'' written to the first word of the structure. The value 4 (empty
'' size is 4 bytes) is written to the second word.
'' @param maxSize the total size of the buffer area

  writeWordToMemory(ptr,maxSize)
  writeWordToMemory(ptr+2,4) ' Four bytes

PUB clear(ptr)
'
'' This function empties all data in the structure by resetting
'' the current size to 4 (empty size is 4 bytes)
'' @ptr the pointer to the map data structure
 
  writeWordToMemory(ptr+2,4) ' Four bytes used (maxsize and cursize)

PUB put(ptr,keyPtr,valuePtr) | count
'
'' This function adds a string/string mapping to the data structure.
'' @ptr       pointer to the map data structure
'' @keyPtr    pointer to the null-terminated key string
'' @valuePtr  pointer to the null-terminated value string
'' @returns    true if added or false if not (no room)
 
 return putBinary(ptr,keyPtr,valuePtr,strsize(valuePtr)+1)

PUB putBinary(ptr,keyPtr,valuePtr,valueSize) | p2, cs, ms, ns
'
'' This function adds a string/binary mapping to the data structure.
'' The value may include zeros.
'' @ptr        pointer to the map data structure
'' @keyPtr     pointer to the null-terminated key string
'' @valuePtr   pointer to the binary value data
'' @valueSize  size of the binary value data
'' @returns    true if added or false if not (no room)

  ' If the key is already in the map then remove it
  ' (essentially replacing the value)
  if get(ptr,keyPtr)<>0
    remove(ptr,keyPtr)

  ms := readWordFromMemory(ptr)    ' Maximum size allowed
  cs := readWordFromMemory(ptr+2)  ' Current size

  ' Make sure there is room for: key_bytes + null + value_size + value
  ns := cs+strsize(keyPtr)+3+valueSize
  if ns > ms
    return false           
  
  p2 := ptr + cs  ' Point to end of current data

  ' Copy the key into the data
  repeat while(byte[keyPtr]<>0)
    byte[p2++] := byte[keyPtr++]

  ' Terminate the key string  
  byte[p2++]:=0

  ' Size of the value (value doesn't have to be a string)
  writeWordToMemory(p2,valueSize)
  ++p2
  ++p2

  ' Copy the data
  repeat while(valueSize>0)
    byte[p2++] := byte[valuePtr++]
    --valueSize

  ' Set the new size of the data structure  
  writeWordToMemory(ptr+2,ns)

  return true
   


PUB get(ptr,keyPtr) | p2
'
'' This function returns a pointer to the string value associated with
'' the given key or 0 if not found.
'' @ptr       pointer to the map data structure
'' @keyPtr    pointer to the null-terminated key string
'' @return    pointer to the value string or 0 if not found

  p2 := getBinary(ptr,keyPtr)
  if p2<>0
    p2:=p2+2
  return p2
  
PUB getBinary(ptr,keyPtr) | p2, pe
'
'' This function returns a pointer to the binary value associated with
'' the given key or 0 if not found.
'' @ptr       pointer to the map data structure
'' @keyPtr    pointer to the null-terminated key string   
'' @return    pointer to the binary value data (first word is the length of the data)

  pe := ptr + readWordFromMemory(ptr+2)
  p2 := ptr + 4

  repeat while p2<>pe
     ' If this is a match then return pointer to value
     if stringEquals(p2,keyPtr)
       p2:=p2+strsize(p2)+1
       return p2
    ' Not a match ... skip the key, null, value_size, and value    
     p2:=p2+strsize(p2)+1
     p2:=p2+readWordFromMemory(p2)+2
 
  return 0 ' Not found

  
PUB remove(ptr,keyPtr) | p2 , pe, ps, ds
'
'' This function removes the key/value association for the given key.
'' The data structure is closed up over the entry.
'' @ptr       pointer to the map data structure
'' @keyPtr    pointer to the null-terminated key string
'' @return    true if removed or false if not (not found)

  pe := ptr + readWordFromMemory(ptr+2)
  p2 := ptr + 4

  repeat while p2<>pe
     ' If this is a match then return pointer to value
     if stringEquals(p2,keyPtr)
       ps:= p2
       ps := ps+strsize(ps)+1
       ps := ps+readWordFromMemory(ps)+2
       ds := ps-p2 ' Number of bytes we are deleting
       repeat while(ps<pe)
         byte[p2++] := byte[ps++]
       writeWordToMemory(ptr+2,readWordFromMemory(ptr+2)-ds)       
       return true
     ' Not a match ... skip the key, null, value_size, and value    
     p2:=p2+strsize(p2)+1
     p2:=p2+readWordFromMemory(p2)+2
 
  return false   

PUB countEntries(ptr) | pe, p2, c
'
'' This function counts the key/value entries in the map.
'' @ptr       pointer to the map data structure
'' @return    number of entries in the map

  pe := ptr + readWordFromMemory(ptr+2)
  p2 := ptr + 4
  c:= 0
  
  repeat while p2<>pe
     ++c     
     ' Skip the key, null, value_size, and value    
     p2:=p2+strsize(p2)+1
     p2:=p2+readWordFromMemory(p2)+2

  return c

PUB getEntry(ptr,index) | pe, p2
'
'' This function returns the pointer to the requested key/value
'' entry. The indexed functions are useful for iteration through
'' the map. The return pointer points to:
'' KEY+NULL + SIZE + DATA
'' Where SIZE is the two byte length of the DATA bytes.
'' @ptr       pointer to the map data structure
'' @index     the iteration count (0 .. countEntries()-1)
'' @return    pointer to the entry or 0 if out of bounds

  pe := ptr + readWordFromMemory(ptr+2)
  p2 := ptr + 4
  
  repeat while p2<>pe
     if index==0
       return p2   
     ' Skip the key, null, value_size, and value    
     p2:=p2+strsize(p2)+1
     p2:=p2+readWordFromMemory(p2)+2
     --index

  return 0

PUB getKey(ptr,index)
'
'' This function returns the pointer to the reqeusted key.
'' @ptr       pointer to the map data structure
'' @index     the iteration count (0 .. countEntries()-1)
'' @return    pointer to the null-terminated key string
 
  return getEntry(ptr,index)

PUB getValue(ptr,index) | p
'
'' This function returns the pointer to the reqeusted value string.
'' @ptr       pointer to the map data structure
'' @index     the iteration count (0 .. countEntries()-1)
'' @return    pointer to the null-terminated value string
  p := getValueBinary(ptr,index)
  if p==0
    return p
  return p+2  

PUB getValueBinary(ptr,index) | p
'
'' This function returns the pointer to the reqeusted binary value.
'' @ptr       pointer to the map data structure
'' @index     the iteration count (0 .. countEntries()-1)
'' @return    pointer to the binary value (first word is the length)

  p := getEntry(ptr,index)
  if p==0
    return p
  p := p + strsize(p) + 1
  return p

PUB writeWordToMemory(ptr,value)
'
'' This utility function writes a word value to memory without
'' assuming a word alignment.
'' @ptr    pointer to memory
'' @value  two-byte value to write
  byte[ptr]   := (value)
  byte[ptr+1] := (value>>8)

PUB readWordFromMemory(ptr)
'
'' This utility function reads a word value from memory
'' without assuming a word alignment.
'' @ptr     pointer to memory
'' @return  the two-byte value

  return byte[ptr] | (byte[ptr+1]<<8)

PUB stringEquals(p1,p2)
'
'' This utility function compares two strings.
  repeat
    if byte[p1]<>byte[p2]
      return false      
    if (byte[p1]==0) and (byte[p2]==0)
      return true
    ++p1
    ++p2

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
