{{
OBEX LISTING:
  http://obex.parallax.com/object/419

  Full featured autopilot for boats, planes and rovers. Tested over 3 years. You can see the videos under Spiritplumber on youtube. This version does not contain the graphical console, but text i/o is possible and fairly easy to do.

  Other versions are maintained here http://robots-everywhere.com/portfolio/navcom_ai/ and may be downloaded there. If you intend to use this commercially, please see licensing information on that page.

  A note: It is possible to build functional drone bombers or similar with this. You the downloader are explicitly denied permission to do so. If you want to build autonomous weapons do your own homework, or better yet, go get your head examined.

  Videos of the drones in action!

  http://www.youtube.com/watch?v=5wJHj3hOcuI
  http://www.youtube.com/watch?v=diAZD68Y3Cw
  http://www.youtube.com/watch?v=AIbPvxf3hrk
  http://www.youtube.com/watch?v=en5TCSHZDyY
  http://www.youtube.com/watch?v=Dd1R-WeGWkU
  http://www.youtube.com/watch?v=9m6H5se6-nE
}}
{{
'   fsrw.spin 1.5  7 April 2007   Radical Eye Software
'
'   This object provides FAT16 file read/write access on a block device.
'   Only one file open at a time.  Open modes are 'r' (read), 'a' (append),
'   'w' (write), and 'd' (delete).  Only the root directory is supported.
'   No long filenames are supported.  We also support traversing the
'   root directory.
'
'   In general, negative return values are errors; positive return
'   values are success.  Other than -1 on popen when the file does not
'   exist, all negative return values will be "aborted" rather than
'   returned.
'
'   Changes:
'       v1.1  28 December 2006  Fixed offset for ctime
'       v1.2  29 December 2006  Made default block driver be fast one
'       v1.3  6 January 2007    Added some docs, and a faster asm
'       v1.4  4 February 2007   Rearranged vars to save memory;
'                               eliminated need for adjacent pins;
'                               reduced idle current consumption; added
'                               sample code with abort code data
'       v1.5  7 April 2007      Fixed problem when directory is larger
'                               than a cluster.
}}
'
'   Constants describing FAT volumes.
'
con
   SECTORSIZE = 512
   SECTORSHIFT = 9
   DIRSIZE = 32
   DIRSHIFT = 5
'
'   The object that provides the block-level access.

var
'
'
'   Variables concerning the open file.
'
   long fclust ' the current cluster number
   long filesize  ' the total current size of the file
   long floc ' the seek position of the file
   long frem ' how many bytes remain in this cluster from this file
   long bufat ' where in the buffer our current character is
   long bufend ' the last valid character (read) or free position (write)
   long direntry ' the byte address of the directory entry (if open for write)
   long writelink ' the byte offset of the disk location to store a new cluster
   long fatptr ' the byte address of the most recently written fat entry
{
'
'   Variables used when mounting to describe the FAT layout of the card.
'
   long rootdir ' the byte address of the start of the root directory
   long rootdirend ' the byte immediately following the root directory.
   long dataregion ' the start of the data region, offset by two sectors
   long clustershift ' log base 2 of blocks per cluster
   long fat1 ' the block address of the fat1 space
   long totclusters ' how many clusters in the volume
   long sectorsperfat ' how many sectors per fat

}
'
'   Variables controlling the caching.
'
   long lastread ' the block address of the buf2 contents
   long dirty ' nonzero if buf2 is dirty


{
'
'  Buffering:  two sector buffers.  These two buffers must be longword
'  aligned!  To ensure this, make sure they are the first byte variables
'  defined in this object.
'
   byte buf[SECTORSIZE] ' main data buffer
   byte buf2[SECTORSIZE] ' main metadata buffer

   byte padname[11] ' filename buffer
}


dat
'
'  filename buffer
' 

fname
padname  byte "FILENAME"
padext   byte "EXT"
semabyte byte 255 ' also acts as end of file name string; if it's zero, we're working, otherwise return; also acts as padding, see above

'
'  Buffering:  two sector buffers.  These two buffers must be longword
'  aligned!  To ensure this, make sure they are the first byte variables
'  defined in this object. Alternatively, keeep the padname there.
'

buf
buf1_0   byte "B","U","F","1",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_63  byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_127 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_191 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_255 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_319 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_383 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf1_447 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

buf2
buf2_0   byte "B","U","F","2",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_63  byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_127 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_191 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_255 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_319 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_383 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
buf2_447 byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


{
'
'   Variables concerning the open file.
'
fclust        long 1.0 ' the current cluster number
filesize      long 1.0 ' the total current size of the file
floc          long 1.0 ' the seek position of the file
frem          long 1.0 ' how many bytes remain in this cluster from this file
bufat         long 1.0 ' where in the buffer our current character is 
bufend        long 1.0 ' the last valid character (read) or free position (write) 
direntry      long 1.0 ' the byte address of the directory entry (if open for write) 
writelink     long 1.0 ' the byte offset of the disk location to store a new cluster 
fatptr        long 1.0 ' the byte address of the most recently written fat entry
}

'
'   Variables used when mounting to describe the FAT layout of the card.
'
rootdir       long 1.0 ' the byte address of the start of the root directory  
rootdirend    long 1.0 ' the byte immediately following the root directory. 
dataregion    long 1.0 ' the start of the data region, offset by two sectors  
clustershift  long 1.0 ' log base 2 of blocks per cluster
fat1          long 1.0 ' the block address of the fat1 space
totclusters   long 1.0 ' how many clusters in the volume 
sectorsperfat long 1.0 ' how many sectors per fat  
{
'
'   Variables controlling the caching.
'
lastread      long 1.0 ' the block address of the buf2 contents
dirty         long 1.0 ' nonzero if buf2 is dirty 

}
pub log(ubuf) : t | r, count
{{
'   Write a string from the buffer ubuf.  Returns the number of bytes
'   successfully written, or a negative number if there is an error.
'   The buffer may be as large as you want.
}}
   t~
   count := strsize(ubuf)
   repeat while (count > 0)
      if (bufat => bufend)
         t := pflushbuf(bufat, 0)
      t := bufend - bufat
      if (t > count)
         t := count
      bytemove(@buf+bufat, ubuf, t)
      r += t
      bufat += t
      ubuf += t
      count -= t

pub open(filenameaddr) | r
   ' doesnt force closing, rather, it waits until whatever is using this is done.
   repeat until semabyte
   semabyte~
   r := \mount(0)
   if !r
     popen(filenameaddr)
   else
     corestop
     semabyte := 255
   
pub close
   if semabyte
      return ' already closed!
   pclose
   corestop
   semabyte := 255

{
pub logstring3(filenameaddr, prependstr, stringaddr, appendstr) : r ' returns all the bad things that may have happened
   repeat until semabyte
   semabyte~
   r := \mount(0)
   if !r
     popen(filenameaddr)
     if (prependstr)
         writestr(prependstr)
     writestr(stringaddr)
     if (appendstr)
         writestr(appendstr)
     pclose
   corestop
   semabyte := 255
}
pub buffaddr
    return @buf ' keeping in mind we got a HUGE buffer here

pri writeblock2(n, b)
'
'   On metadata writes, if we are updating the FAT region, also update
'   the second FAT region.
'
   writeblock(n, b)
   if (n => fat1 and n < fat1 + sectorsperfat)
      writeblock(n+sectorsperfat, b)
pri flushifdirty
'
'   If the metadata block is dirty, write it out.
'
   if (dirty)
      writeblock2(lastread, @buf2)
      dirty~
pri readblockc(n)
'
'   Read a block into the metadata buffer, if that block is not already
'   there.
'
   if (n <> lastread)
      flushifdirty
      readblock(n, @buf2)
      lastread := n

pri brword(b)
'
'   Read a byte-reversed word from a (possibly odd) address.
'
   return (byte[b]) + ((byte[b][1]) << 8)
pri brlong(b)
'
'   Read a byte-reversed long from a (possibly odd) address.
'
   return brword(b) + (brword(b+2) << 16)

pri brwword(w, v)
'
'   Write a byte-reversed word to a (possibly odd) address, and
'   mark the metadata buffer as dirty.
'
   byte[w++] := v
   byte[w] := v >> 8
   dirty := 1

pri brwlong(w, v)
'
'   Write a byte-reversed long to a (possibly odd) address, and
'   mark the metadata buffer as dirty.
'
   brwword(w, v)
   brwword(w+2, v >> 16)

pri mount(basepin) | start, sectorspercluster, reserved, rootentries, sectors
{{
'   Mount a volume.  The address passed in is passed along to the block
'   layer; see the currently used block layer for documentation.  If the
'   volume mounts, a 0 is returned, else abort is called.
}}
   corestart(basepin)
   lastread~~
   dirty~
   readblock(0, @buf)
   if (brlong(@buf+$36) == constant("F" + ("A" << 8) + ("T" << 16) + ("1" << 24)))
      start~
   else
      start := brlong(@buf+$1c6)
      readblock(start, @buf)
   if (brlong(@buf+$36) <> constant("F" + ("A" << 8) + ("T" << 16) + ("1" << 24)) or buf[$3a] <> "6")
      abort(-20) ' not a fat16 volume
   if (brword(@buf+$0b) <> SECTORSIZE)
      abort(-21) ' bad bytes per sector
   sectorspercluster := buf[$0d]
   if (sectorspercluster & (sectorspercluster - 1))
      abort(-22) ' bad sectors per cluster
   clustershift~
   repeat while (sectorspercluster > 1)
      clustershift++
      sectorspercluster >>= 1
   sectorspercluster := 1 << clustershift
   reserved := brword(@buf+$0e)
   if (buf[$10] <> 2)
      abort(-23) ' not two FATs
   rootentries := brword(@buf+$11)
   sectors := brword(@buf+$13)
   if (sectors == 0)
      sectors := brlong(@buf+$20)
   sectorsperfat := brword(@buf+$16)
   if (brword(@buf+$1fe) <> $aa55)
      abort(-24) ' bad FAT signature
   fat1 := start + reserved
   rootdir := (fat1 + 2 * sectorsperfat) << SECTORSHIFT
   rootdirend := rootdir + (rootentries << DIRSHIFT)
   dataregion := 1 + ((rootdirend - 1) >> SECTORSHIFT) - 2 * sectorspercluster
   totclusters := ((sectors - dataregion + start) >> clustershift)
   if (totclusters > $fff0)
      abort(-25) ' too many clusters
   return 0
pri readbytec(byteloc)
'
'   Read a byte address from the disk through the metadata buffer and
'   return a pointer to that location.
'
   readblockc(byteloc >> SECTORSHIFT)
   return @buf2 + (byteloc & constant(SECTORSIZE - 1))
pri readfat(clust)
'
'   Read a fat location and return a pointer to the location of that
'   entry.
'
   fatptr := (fat1 << SECTORSHIFT) + (clust << 1)
   return readbytec(fatptr)
pri followchain : clust
'
'   Follow the fat chain and update the writelink.
'
   clust := brword(readfat(fclust))
   writelink := fatptr
pri nextcluster : clust
'
'   Read the next cluster and return it.  Set up writelink to
'   point to the cluster we just read, for later updating.  If the
'   cluster number is bad, return a negative number.
'
   clust := followchain
   if (clust < 2 or clust => totclusters)
      abort(-9) ' bad cluster value
pri freeclusters(clust) | bp
'
'   Free an entire cluster chain.  Used by remove and by overwrite.
'   Assumes the pointer has already been cleared/set to $ffff.
'
   repeat while (clust < $fff0)
      if (clust < 2)
         abort(-26) ' bad cluster number")
      bp := readfat(clust)
      clust := brword(bp)
      brwword(bp, 0)
   flushifdirty
pri datablock
'
'   Calculate the block address of the current data location.
'
   return (fclust << clustershift) + dataregion + ((floc >> SECTORSHIFT) & ((1 << clustershift) - 1))
pri uc(c)
'
'   Compute the upper case version of a character.
'
   if ("a" =< c and c =< "z")
      return c - 32
   return c
pri pflushbuf(r, metadata) | cluststart, newcluster, count, i
'
'   Flush the current buffer, if we are open for write.  This may
'   allocate a new cluster if needed.  If metadata is true, the
'   metadata is written through to disk including any FAT cluster
'   allocations and also the file size in the directory entry.
'
   if (direntry == 0)
      abort(-27) ' not open for writing
   if (r > 0) ' must *not* allocate cluster if flushing an empty buffer
      if (frem < SECTORSIZE)
         ' find a new clustercould be anywhere!  If possible, stay on the
         ' same page used for the last cluster.
         newcluster~~
         cluststart := fclust & constant(!((SECTORSIZE >> 1) - 1))
         count := 2
         repeat
            readfat(cluststart)
            repeat i from 0 to constant(SECTORSIZE - 2) step 2
               if (buf2[i]==0 and buf2[i+1]==0)
                  quit
            if (i < SECTORSIZE)
               newcluster := cluststart + (i >> 1)
               if (newcluster => totclusters)
                  newcluster~~
            if (newcluster > 1)
               brwword(@buf2+i, -1)
               brwword(readbytec(writelink), newcluster)
               writelink := fatptr + i
               fclust := newcluster
               frem := SECTORSIZE << clustershift
               quit
            else
               cluststart += constant(SECTORSIZE >> 1)
               if (cluststart => totclusters)
                  cluststart~
                  count--
                  if (count < 0)
                     r := -5 ' No space left on device
                     quit
      if (frem => SECTORSIZE)
         writeblock(datablock, @buf)
         if (r == SECTORSIZE) ' full buffer, clear it
            floc += r
            frem -= r
            bufat~
            bufend := r
         else
            ' not a full blockleave pointers alone
   if (r < 0 or metadata) ' update metadata even if error
      readblockc(direntry >> SECTORSHIFT) ' flushes unwritten FAT too
      brwlong(@buf2+(direntry & constant(SECTORSIZE-1))+28, floc+bufat)
      flushifdirty
   if (r < 0)
      abort(r)
   return r
pri pflush
{{
'   Call flush with the current data buffer location, and the flush
'   metadata flag set.
}}
   return pflushbuf(bufat, 1)
pri pfillbuf | r
'
'   Get some data into an empty buffer.  If no more data is available,
'   return -1.  Otherwise return the number of bytes read into the
'   buffer.
'
   if (floc => filesize)
      return -1
   if (frem == 0)
      fclust := nextcluster
      frem := SECTORSIZE << clustershift
      if (frem + floc > filesize)
         frem := filesize - floc
   readblock(datablock, @buf)
   r := SECTORSIZE
   if (floc + r => filesize)
      r := filesize - floc
   floc += r
   frem -= r
   bufat~
   bufend := r
   return r
pri pclose : r
{{
'   Flush and close the currently open file if any.  Also reset the
'   pointers to valid values.  If there is no error, 0 will be returned.
}}
   r~
   if (direntry)
      r := pflush
   bufat~
   bufend~
   filesize~
   floc~
   frem~
   writelink~
   direntry~
   fclust~ 
pri pdate
{{
'   Get the current date and time, as a long, in the format required
'   by FAT16.  Right now it"s hardwired to return the date this
'   software was created on (April 7, 2007).  You can change this
'   to return a valid date/time if you have access to this data in
'   your setup.
}}
   return constant(((2007-1980) << 25) + (1 << 21) + (7 << 16) + (4 << 11))
pri popen(s) | i, sentinel, dirptr, freeentry
{{
'   Close any currently open file, and open a new one with the given
'   file name and mode.  Mode can be "r" "w" "a" or "d" (delete).
'   If the file is opened successfully, 0 will be returned.  If the
'   file did not exist, and the mode was not "w" or "a", -1 will be
'   returned.  Otherwise abort will be called with a negative error
'   code.
}}
   pclose
   i~
   repeat while (i<8 and byte[s] and byte[s] <> ".")
      padname[i++] := uc(byte[s++])
   repeat while (i<8)
      padname[i++] := " "
   repeat while (byte[s] and byte[s] <> ".")
      s++
   if (byte[s] == ".")
      s++
   repeat while (i<11 and byte[s])
      padname[i++] := uc(byte[s++])
   repeat while (i < 11)
      padname[i++] := " "
   sentinel~
   freeentry~
   repeat dirptr from rootdir to rootdirend - DIRSIZE step DIRSIZE
      s := readbytec(dirptr)
      if (freeentry == 0 and (byte[s] == 0 or byte[s] == $e5))
         freeentry := dirptr
      if (byte[s] == 0)
         sentinel := dirptr
         quit
      repeat i from 0 to 10
         if (padname[i] <> byte[s][i])
            quit
      if (i == 11 and 0 == (byte[s][$0b] & $18)) ' this always returns
         fclust := brword(s+$1a)
         filesize := brlong(s+$1c)
{
         if (mode == "r")
            frem := SECTORSIZE << clustershift
            if (frem > filesize)
               frem := filesize
            return 0
         if (byte[s][11] & $d9)
            abort(-6) ' no permission to write
         if (mode == "d")
            brwword(s, $e5)
            freeclusters(fclust)
            flushifdirty
            return 0

         if (mode == "w")
            brwword(s+26, -1)
            brwlong(s+28, 0)
            writelink := dirptr + 26
            direntry := dirptr
            freeclusters(fclust)
            bufend := SECTORSIZE
            fclust~
            filesize~
            frem~
            return 0
}            
'         if (mode == "a")

            frem := filesize
            freeentry := SECTORSIZE << clustershift
            if (fclust => $fff0)
               fclust~
            repeat while (frem > freeentry)
               if (fclust < 2)
                  abort(-7) ' eof repeat while following chain
               fclust := nextcluster
               frem -= freeentry
            floc := filesize & constant(!(SECTORSIZE - 1))
            bufend := SECTORSIZE
            bufat := frem & constant(SECTORSIZE - 1)
            writelink := dirptr + 26
            direntry := dirptr
            if (bufat)
               readblock(datablock, @buf)
               frem := freeentry - (floc & (freeentry - 1))
            else
               if (fclust < 2 or frem == freeentry)
                  frem~
               else
                  frem := freeentry - (floc & (freeentry - 1))
            if (fclust => 2)
               followchain
            return 0
{
         else
            abort(-3) ' bad argument
   if (mode <> "w" and mode <> "a")
      return -1 ' not found
}
   direntry := freeentry
   if (direntry == 0)
      abort(-2) ' no empty directory entry
   ' write (or new append): create valid directory entry
   s := readbytec(direntry)
   bytefill(s, 0, DIRSIZE)
   bytemove(s, @padname, 11)
   brwword(s+26, -1)
   i := pdate
   brwlong(s+$e, i) ' write create time and date
   brwlong(s+$16, i) ' write last modified date and time
   if (direntry == sentinel and direntry + DIRSIZE < rootdirend)
      brwword(readbytec(direntry+DIRSIZE), 0)
   flushifdirty
   writelink := direntry + 26
   fclust~
   bufend := SECTORSIZE
   return 0
{
pub pread(ubuf, count) | r, t
{{
'   Read count bytes into the buffer ubuf.  Returns the number of bytes
'   successfully read, or a negative number if there is an error.
'   The buffer may be as large as you want.
}}
   r~
   repeat while (count > 0)
      if (bufat => bufend)
         t := pfillbuf
         if (t =< 0)
            if (r > 0)
               return r
            return t
      t := bufend - bufat
      if (t > count)
         t := count
      bytemove(ubuf, @buf+bufat, t)
      bufat += t
      r += t
      ubuf += t
      count -= t
   return r
pub pgetc | t
{{
'   Read and return a single character.  If the end of file is
'   reached, -1 will be returned.  If an error occurs, a negative
'   number will be returned.
}}
   if (bufat => bufend)
      t := pfillbuf
      if (t =< 0)
         return -1
   return (buf[bufat++])
}
{
pri pwrite(ubuf, count) | r, t
{{
'   Write count bytes from the buffer ubuf.  Returns the number of bytes
'   successfully written, or a negative number if there is an error.
'   The buffer may be as large as you want.
}}
   t~
   repeat while (count > 0)
      if (bufat => bufend)
         t := pflushbuf(bufat, 0)
      t := bufend - bufat
      if (t > count)
         t := count
      bytemove(@buf+bufat, ubuf, t)
      r += t
      bufat += t
      ubuf += t
      count -= t
   return t
}
{
pub pputc(c)
{{
'   Write a single character into the file open for write.  Returns
'   0 if successful, or a negative number if some error occurred.
}}
   buf[bufat++] := c
   if (bufat == SECTORSIZE)
      return pflushbuf(SECTORSIZE, 0)
   return 0
}
{
pub opendir | off
{{
'   Close the currently open file, and set up the read buffer for
'   calls to nextfile.
}}
   pclose
   off := rootdir - (dataregion << SECTORSHIFT)
   fclust := off >> (clustershift + SECTORSHIFT)
   floc := off - (fclust << (clustershift + SECTORSHIFT))
   frem := rootdirend - rootdir
   filesize := floc + frem
   return 0
pub nextfile(fbuf) | i, t, at, lns
{{
'   Find the next file in the root directory and extract its
'   (8.3) name into fbuf.  Fbuf must be sized to hold at least
'   13 characters (8 + 1 + 3 + 1).  If there is no next file,
'   -1 will be returned.  If there is, 0 will be returned.
}}
   repeat
      if (bufat => bufend)
         t := pfillbuf
         if (t < 0)
            return t
         if (((floc >> SECTORSHIFT) & ((1 << clustershift) - 1)) == 0)
            fclust++
      at := @buf + bufat
      if (byte[at] == 0)
         return -1
      bufat += DIRSIZE
      if (byte[at] <> $e5 and (byte[at][$0b] & $18) == 0)
         lns := fbuf
         repeat i from 0 to 10
            byte[fbuf] := byte[at][i]
            fbuf++
            if (byte[at][i] <> " ")
               lns := fbuf
            if (i == 7 or i == 10)
               fbuf := lns
               if (i == 7)
                  byte[fbuf] := "."
                  fbuf++
         byte[fbuf]~
         return 0
}
















con
'   sdspi:  SPI interface to a Secure Digital card.
'
'   You probably never want to call this; you want to use fsrw
'   instead (which calls this); this is only the lowest layer.
'
'   Assumes SD card is interfaced using four consecutive Propeller
'   pins, as follows (assuming the base pin is pin 0):
'                3.3v
'                   
'                    20k
'   p0 ────────┻─┼─┼─┼─┼─┼────── do
'   p1 ──────────┻─┼─┼─┼─┼────── clk
'   p2 ────────────┻─┼─┼─┼────── di
'   p3 ──────────────┻─┼─┼────── cs (dat3)
'         150          └─┼────── irq (dat1)
'                        └────── p9 (dat2)
'
'   The 20k resistors
'   are pullups, and should be there on all six lines (even
'   the ones we don't drive).
'
'   This code is not general-purpose SPI code; it's very specific
'   to reading SD cards, although it can be used as an example.
'
'   The code does not use CRC at the moment (this is the default).
'   With some additional effort we can probe the card to see if it
'   supports CRC, and if so, turn it on.   
'
'   All operations are guarded by a watchdog timer, just in case
'   no card is plugged in or something else is wrong.  If an
'   operation does not complete in one second it is aborted.
'
{
dat
cog     long 0
command long 0
param   long 0
blockno long 0
}
var
long cog, command, param, blockno
pub corestop
   if cog
      cogstop(cog~ - 1)      
pub corestart(basepin)
'
'   Initialize the card!  Send a whole bunch of
'   clocks (in case the previous program crashed
'   in the middle of a read command or something),
'   then a reset command, and then wait until the
'   card goes idle.
'
   do := basepin++
   clk := basepin++ 
   di := basepin++
   cs := basepin
   corestop
   command := "I"
   cog := 1 + cognew(@entry, @command)
   repeat while command
   if param
      abort param
   return 0
pub readblock(n, b)
'
'   Read a single block.  The "n" passed in is the
'   block number (blocks are 512 bytes); the b passed
'   in is the address of 512 blocks to fill with the
'   data.
'                              \
   param := b
   blockno := n
   command := "R"
   repeat while command
   if param
      abort param
   return 0
pub writeblock(n, b)
'
'   Write a single block.  Mirrors the read above.
'
   param := b
   blockno := n
   command := "W"
   repeat while command
   if param
      abort param
   return 0
dat
        org
entry   mov comptr,par
        mov parptr,par
        add parptr,#4
        mov parptr2,parptr
        add parptr2,#4
' set up
        mov acca,#1
        shl acca,di
        or dira,acca
        mov acca,#1
        shl acca,clk
        or dira,acca
        mov acca,#1
        shl acca,do
        mov domask,acca
        mov acca,#1
        shl acca,cs
        or dira,acca
        mov csmask,acca
        neg phsb,#1
        mov frqb,#0
        mov acca,nco
        add acca,clk
        mov ctra,acca
        mov acca,nco
        add acca,di
        mov ctrb,acca
        mov ctr2,onek
oneloop
        call #sendiohi
        djnz ctr2,#oneloop
        mov starttime,cnt
        mov cmdo,#0
        mov cmdp,#0
        call #cmd
        or outa,csmask
        call #sendiohi
initloop
        mov cmdo,#55
        call #cmd
        mov cmdo,#41
        call #cmd
        or outa,csmask
        cmp accb,#1 wz
   if_z jmp #initloop
        wrlong accb,parptr           
' reset frqa and the clock
finished
        mov frqa,#0
        wrlong frqa,comptr
        or outa,csmask
        neg phsb,#1
        call #sendiohi
pause
        mov acca,#511
        add acca,cnt
        waitcnt acca,#0
waitloop
        mov starttime,cnt
        rdlong acca,comptr wz
   if_z jmp #pause
        cmp acca,#"B" wz
   if_z jmp #byteio
        mov ctr2,sector
        cmp acca,#"R" wz
   if_z jmp #rblock
wblock
        mov starttime,cnt
        mov cmdo,#24
        rdlong cmdp,parptr2
        call #cmd
        mov phsb,#$fe
        call #sendio
        rdlong accb,parptr
        neg frqa,#1
wbyte
        rdbyte phsb,accb
        shl phsb,#23
        add accb,#1
        mov ctr,#8
wbit    mov phsa,#8
        shl phsb,#1
        djnz ctr,#wbit
        djnz ctr2,#wbyte        
        neg phsb,#1
        call #sendiohi
        call #sendiohi
        call #readresp
        and accb,#$1f
        sub accb,#5
        wrlong accb,parptr
        call #busy
        jmp #finished
rblock
        mov starttime,cnt
        mov cmdo,#17
        rdlong cmdp,parptr2
        call #cmd
        call #readresp
        rdlong accb,parptr
        sub accb,#1
rbyte
        mov phsa,hifreq
        mov frqa,freq
        add accb,#1
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        mov frqa,#0
        test domask,ina wc
        addx acca,acca
        wrbyte acca,accb
        djnz ctr2,#rbyte        
        mov frqa,#0
        neg phsb,#1
        call #sendiohi
        call #sendiohi
        or outa,csmask
        wrlong ctr2,parptr
        jmp #finished
byteio     
        rdlong phsb,parptr
        call #sendio
        wrlong accb,parptr
        jmp #finished
sendio
        rol phsb,#24
sendiohi
        mov ctr,#8
        neg frqa,#1
        mov accb,#0
bit     mov phsa,#8
        test domask,ina wc
        addx accb,accb        
        rol phsb,#1
        djnz ctr,#bit
sendio_ret
sendiohi_ret
        ret
checktime
        mov duration,cnt
        sub duration,starttime
        cmp duration,clockfreq wc
checktime_ret
  if_c  ret
        neg duration,#13
        wrlong duration,parptr
        jmp #finished
cmd
        andn outa,csmask
        neg phsb,#1
        call #sendiohi
        mov phsb,cmdo
        add phsb,#$40
        call #sendio
        mov phsb,cmdp
        shl phsb,#9
        call #sendiohi
        call #sendiohi
        call #sendiohi
        call #sendiohi
        mov phsb,#$95
        call #sendio
readresp
        neg phsb,#1
        call #sendiohi
        call #checktime
        cmp accb,#$ff wz
   if_z jmp #readresp 
cmd_ret
readresp_ret
        ret
busy
        neg phsb,#1
        call #sendiohi
        call #checktime
        cmp accb,#$0 wz
   if_z jmp #busy
busy_ret
        ret

di      long 0
do      long 0
clk     long 0
cs      long 0
nco     long $1000_0000
hifreq  long $e0_00_00_00
freq    long $20_00_00_00
clockfreq long 80_000_000
onek    long 1000
sector  long 512
domask  res 1
csmask  res 1
acca    res 1
accb    res 1
cmdo    res 1
cmdp    res 1
comptr  res 1
parptr  res 1
parptr2 res 1
ctr     res 1
ctr2    res 1
starttime res 1
duration res 1
