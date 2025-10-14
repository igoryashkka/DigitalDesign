//Bitmask definition
`ifndef __DRIVER__
`define __DRIVER__

`define _A 8'h77
`define _B 8'h7f
`define _C 8'h39
`define _D 8'h3f
`define _E 8'h79
`define _F 8'h71
`define _G 8'h3d
`define _H 8'h76
`define _J 8'h1e
`define _L 8'h38
`define _N 8'h37
`define _O 8'h3f
`define _P 8'h73
`define _S 8'h6d
`define _U 8'h3e
`define _Y 8'h6e

`define _0 8'h3f
`define _1 8'h06
`define _2 8'h5b
`define _3 8'h4f
`define _4 8'h66
`define _5 8'h6d
`define _6 8'h7d
`define _7 8'h07
`define _8 8'h7f
`define _9 8'h6f

`define _dash 8'h40

typedef enum logic [3:0] {
    _0,
    _1,
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,
    _A,
    _B,
    _C,
    _D,
    _E,
    _F
} TM1637_numbers_t;

`define ADRR_INCR_MODE 8'h40
`define ADRR_SNGL_MODE 8'h44
`define FIRST_TILE_ADDR 8'hc0
`define DISP_BRIGHTNESS 8'h2 // LED brightness - seven levels, will be embedded in display command 
`define CMD_DISPLAY (8'hf8|`DISP_BRIGHTNESS)

`endif // __DRIVER__
