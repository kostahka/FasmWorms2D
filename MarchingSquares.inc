SQUARE_SIZE     equ       10.0
MAP_BORDERS     equ       0.1

MAP_HEIGHT      =       50
MAP_WIDTH       =       50

SQUARES_AMOUNT  =       MAP_HEIGHT * MAP_WIDTH

POINTS_IN_WIDTH =       MAP_WIDTH + 1
POINTS_IN_HEIGHT =      MAP_HEIGHT + 1
POINTS_AMOUNT   =       POINTS_IN_WIDTH * POINTS_IN_HEIGHT

UPPER_POINT     =       POINTS_IN_WIDTH * sizeof.MarchingPoint
UPPER_COLOR     =       POINTS_IN_WIDTH * sizeof.Color

UPPER_MASK      =       MAP_WIDTH * sizeof.VariantMask

GROUND          equ       0.5

struct MarchingPoint
        mass    dd      ?
ends

struct VariantMask
       variant  db      ?
ends

struct  MarchingGrid
        massPoints  dd      ?
        colorPoints dd      ?
        variantMasks dd      ?
ends