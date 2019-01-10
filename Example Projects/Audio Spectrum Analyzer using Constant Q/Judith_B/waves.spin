VAR
    long gCog
    long gCols
    long gRows
    long gScreen
    long stack[64]
    
    long gPhase
    long gFreq

PUB start(pScreen, pCols, pRows)
    stop
    gCols := pCols
    gRows := pRows
    gScreen := pScreen
    gCog := cognew(main, @stack) + 1


PUB stop
    if (gCog)
        cogStop(gCog~ - 1)

PUB running
    return gCog

PRI main 
    longfill(gScreen, 0, gRows)
    gFreq := 2
    repeat
        long[gScreen][0] := ?gPhase
        waitcnt(CNT + CLKFREQ)
                
        

PRI cos(angle)
    return sin(angle + $800)

PRI sin(angle) : tmp
'' Sine
    angle &= 8191
	tmp := angle
	if tmp & SIN_90
		angle := -angle
	angle |= SIN_TABLE
	angle <<= 1
	angle := word[angle]
	if tmp & SIN_180
		angle := -angle
	return angle

CON
	SIN_90		= $0800
	SIN_180		= $1000
	SIN_TABLE	= $E000 >> 1

