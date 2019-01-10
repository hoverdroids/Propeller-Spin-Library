CON
    _XINFREQ = 5_000_000
    _CLKMODE = XTAL1 | PLL16X

    XGAP    = 6
    YGAP    = 6

    O_XVIS  = 0
    O_YVIS  = 1
    O_COLS  = 2
    O_ROWS  = 3
    O_COLORS = 4
    

PUB start(pParams) : x | bl
    lines_per_row := (long[pParams][O_YVIS] - long[pParams][O_ROWS] * YGAP) / long[pParams][O_ROWS]
    x := 480 - long[pParams][O_ROWS] * (lines_per_row + YGAP)
    vfp := 9 + x/2
    vbp := 28 + x - x/2
    total_lines := (lines_per_row + YGAP) * long[pParams][O_ROWS]
    
    '' pixels per col
    x := long[pParams][O_XVIS] / long[pParams][O_COLS]
    rect_pixels := -1
    repeat XGAP
        rect_pixels <<= 1
    vscl_rect := 1 << 12 + x

    bl := 640 - x  * long[pParams][O_COLS]
    hbp := 128 + bl/2
    hfp := 24 + bl - bl/2
    
    vscl_hbp := hbp + (1 << 12)
    vscl_hfp := hfp + (1 << 12)
    vscl_hblank := 640 - bl

    cCols := long[pParams][O_COLS]
    cRows := long[pParams][O_ROWS]
    cColsRows := cCols * cRows
    
    cognew(@display_entry, pParams)

DAT
                org     0
display_entry
                mov     DIRA, pins_mask
                movi    CTRA, ctra_value
                movi    FRQA, frqa_value
                mov     VCFG, vcfg_value
                mov     VSCL, vscl_value

                mov     color_ptr, PAR
                add     color_ptr, #16
                rdlong  colors, color_ptr
                add     color_ptr, #4
                rdlong  values, color_ptr

:loop           
                mov     color_ptr, colors
                mov     values_c_ptr, colors
                
                '' vsync
                mov     ahsync_colors, hvsync_colors
                mov     c1, #3
:vsync_loop     call    #blank_line
                djnz    c1, #:vsync_loop
                '' vbp
                mov     ahsync_colors, hsync_colors
                mov     c1, vbp
:vbp_loop       call    #blank_line
                djnz    c1, #:vbp_loop

                mov     ahsync_colors, hsync_colors
                mov     c2, cRows
:lines_loop     mov     c1, lines_per_row
:line_loop      call    #line
                sub     color_ptr, cColsRows
                djnz    c1, #:line_loop
                add     color_ptr, #1
                mov     c1, #YGAP
:gap_loop       call    #blank_line
                djnz    c1, #:gap_loop
                djnz    c2, #:lines_loop

                '' vfp
                mov     ahsync_colors, hsync_colors
                mov     c1, vfp
:vfp_loop       call    #blank_line
                djnz    c1, #:vfp_loop

                jmp     #:loop

blank_line      
                '' sync pulse
                mov     vscl, vscl_hsync
                waitvid ahsync_colors, all_ones
                '' blank - fporch + pixels + bporch
                mov     vscl, vscl_hbp
                waitvid ahsync_colors, #0
                mov     vscl, vscl_hblank
                waitvid ahsync_colors, #0
                'call    #render
                mov     vscl, vscl_hfp
                waitvid ahsync_colors, #0
blank_line_ret  ret

line      
                '' sync pulse
                mov     vscl, vscl_hsync
                waitvid ahsync_colors, all_ones

                mov     vscl, vscl_hbp
                waitvid ahsync_colors, #0
                mov     c3, cCols
                mov     vscl, vscl_rect
:rect_loop      rdbyte  rect_colors, color_ptr
                or      rect_colors, black
                shl     rect_colors, #8
                or      rect_colors, black
                waitvid rect_colors, rect_pixels
                add     color_ptr, cRows
                djnz    c3, #:rect_loop

                mov     vscl, vscl_hfp
                waitvid ahsync_colors, #0
line_ret        ret


ctra_value      long    %00001_110
frqa_value      long    (30 / 5) << 2
vcfg_value      long    1 << 29 | 0 << 28 | %010 << 9 | 255
vscl_value      long    1 << 12 + 24

all_ones        long    -1
pins_mask       long    255 << 16

vsync_colors    long    %%0002_0003
hsync_colors    long    %%0001_0003
hvsync_colors   long    %%0000_0002

vscl_hsync      long    40 << 12 + 40
vscl_hbp        long    0
vscl_hfp        long    0
vscl_hblank     long    0
vscl_rect       long    0

rect_colors     long    %%3303_0003
black           long    %%0003

total_lines     long    0

vbp             long    0
vfp             long    0
hbp             long    0
hfp             long    0
lines_per_row   long    0
rect_pixels     long    0

cCols           long    0
cRows           long    0
cColsRows       long    0

c1              res     1
c2              res     1
c3              res     1
ahsync_colors   res     1
color_ptr       res     1
colors          res     1
values          res     1
value           res     1
values_c_ptr    res     1
c4              res     1
c5              res     1
color           res     1
color_          res     1
