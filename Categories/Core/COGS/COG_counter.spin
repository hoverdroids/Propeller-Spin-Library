
PUB free_cogs : free | i, cog[8], jmp_0

  jmp_0 := %010111_0001_1111_000000000_000000000
  repeat while (cog[free] := cognew(@jmp_0, 0)) => 0 
    free++
  if free
    repeat i from 0 to free - 1
      cogstop(cog[i])
  return free