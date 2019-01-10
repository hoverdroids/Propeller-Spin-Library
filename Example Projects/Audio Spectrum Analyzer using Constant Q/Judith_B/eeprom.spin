CON

    SDA = 29
    SCL = 28

    
PUB writeBlock(pAddress, pBuffer, pCount)
        i2cStart
        i2cWriteByte($A0)
        i2cWriteByte(pAddress >> 8)
        i2cWriteByte(pAddress)
        repeat while pCount > 0
            i2cWriteByte(byte[pBuffer++])
            pAddress++
            pCount--
            ifnot pAddress & 63
                i2cStop
                waitcnt(CNT + CLKFREQ / 100)
                if pCount > 0
                    i2cStart
                    i2cWriteByte($A0)
                    i2cWriteByte(pAddress >> 8)
                    i2cWriteByte(pAddress)
        if pAddress & 63
            i2cStop
            waitcnt(CNT + CLKFREQ / 100)

    
PUB i2cStart
    OUTA[SDA] := 0
    OUTA[SCL] := 0
    DIRA[SDA]~~

PUB i2cStop
    DIRA[SCL]~~
    DIRA[SDA]~~
    DIRA[SCL]~
    DIRA[SDA]~

    

    
PUB i2cReadByte(ack)
    Result := 0
    repeat 8
        DIRA[SCL]~~
        DIRA[SDA]~
        DIRA[SCL]~
        Result <<= 1
        Result |= INA[SDA]
    DIRA[SCL]~~
    DIRA[SDA] := NOT ack
    DIRA[SCL]~

PUB i2cWriteByte(b)
    repeat 8
        DIRA[SCL]~~
        DIRA[SDA] := NOT (b & 128)
        DIRA[SCL]~
        b <<= 1
    DIRA[SCL]~~
    DIRA[SDA]~
    Result := NOT INA[SDA]
    DIRA[SDA]~~
    DIRA[SCL]~
