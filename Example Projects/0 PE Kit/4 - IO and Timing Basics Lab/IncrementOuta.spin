''This code example is from Propeller Education Kit Labs: Fundamentals, v1.1.
''A .pdf copy of the book is available from www.parallax.com, and also through
''the Propeller Tool software's Help menu (v1.2.6 or newer).
''
'' File: IncrementOuta.spin

PUB BlinkLeds

    dira[9..4]~~
    outa[9..4]~

    repeat
        
        waitcnt(clkfreq/2 + cnt)
        outa[9..4] := outa[9..4] + 1  