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
'' This object provides time delay and time synchronization functions.


CON

        _clkmode                = xtal1 + pll16x
        _xinfreq                = 5_000_000                                                                                       

CON
  
  _10us = 1_000_000 /        10                         ' Divisor for 10 us
  _1ms  = 1_000_000 /     1_000                         ' Divisor for 1 ms
  _1s   = 1_000_000 / 1_000_000                         ' Divisor for 1 s


VAR

  long delay10us
  long syncpoint10us

PUB markSIF(SIValue)
  delay10us := (clkfreq / _10us * SIvalue) #> 381                 ' Calculate 10 us time unit and saves it 
  syncpoint10us := cnt

PUB waitSIF(fudge)                                                 ' waits until we "hit" that. WARNING: this will lock up for a full clock cycle if missed!
   waitcnt(syncpoint10us += (delay10us + fudge))
