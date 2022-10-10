proc Marching.GenerateMap uses edi esi ebx

        locals
                x       dd      ?
                y       dd      ?
                temp    dd      ?
        endl

        mov     edi, [mGrid.colorPoints]
        mov     esi, [mGrid.massPoints]

        mov     ecx, [PointsAmount]
        mov     ebx, [PointsInWidth]

        invoke  GetTickCount
        stdcall ChangeNoiseSeed, eax
.InitLoop:
        push    ecx
        mov     eax, [PointsAmount]
        sub     eax, ecx
        xor     edx, edx
        div     ebx
        mov     [x], edx
        mov     [y], eax

        jmp     .ContinueLoop
.CheckLoop:
        pop     ecx
        loop    .InitLoop
        jmp     .EndLoop
.ContinueLoop:
        fild     [x]
        fstp     [x]
        fild     [y]
        fstp     [y]

        stdcall PerlinNoise, [x], 0.4, 0.3, 20.0, 3
        mov     [temp], eax
        fld     [temp]
        fimul   [PointsInHeight]
        fld     [y]
        fcomip  st0, st1
        fstp     st0
        ja      .HGrad
        fld1
        fstp    [temp]
                jmp             @F      
.HGrad:
                fild    [PointsInHeight]
                fsub    [y]
                fild    [PointsInHeight]
                fld             [temp]
                fimul   [PointsInHeight]
                fsubp
                FDIVP
                fstp    [temp]
@@:

        stdcall  PerlinNoise2D, [x], [y], 0.55, 0.45, 10.0, 3
        stdcall  Marching.GradientMap, [x], eax
        mov     [esi + MarchingPoint.mass], eax
        fld     [temp]
        fmul    [esi + MarchingPoint.mass]
        fst     [esi + MarchingPoint.mass]

        mov             [temp], 0.53
        fld             [temp]
        fcomip  st0, st1

        ja              .Green
        mov             [temp], 0.65
        fld             [temp]
        fcomip  st0, st1
        fstp    st0
        ja              .Red
        stdcall  PerlinNoise2D, [x], [y], 0.5, 0.2, 3.0, 6
        mov     [edi + Color.r], eax
        mov     [edi + Color.g], eax
        mov     [edi + Color.b], eax
        jmp             .EndColor
.Red:   
        stdcall  PerlinNoise2D, [x], [y], 0.5, 0.2, 3.0, 6
        mov     [edi + Color.r], eax
        stdcall  PerlinNoise2D, [x], [y], 0.2, 0.2, 3.0, 6
        mov     [edi + Color.g], eax
        mov     [edi + Color.b], 0
        jmp             .EndColor
.Green:
        fstp    st0
        stdcall  PerlinNoise2D, [x], [y], 0.5, 0.2, 3.0, 6
        mov     [edi + Color.g], eax
        mov     [edi + Color.r], 0
        mov     [edi + Color.b], 0
.EndColor:

        add     esi, sizeof.MarchingPoint
        add     edi, sizeof.Color
        jmp     .CheckLoop

.EndLoop:

        stdcall UpdateVariantMasks

        ret
endp

proc MarchingInit uses edi esi ebx,\
     marchGrid

        mov     ebx, [marchGrid]
        invoke  HeapAlloc, [hHeap], 8, sizeof.Color * POINTS_AMOUNT
        mov     [ebx + MarchingGrid.colorPoints], eax

        invoke  HeapAlloc, [hHeap], 8, sizeof.MarchingPoint * POINTS_AMOUNT
        mov     [ebx + MarchingGrid.massPoints], eax

        invoke  HeapAlloc, [hHeap], 8, sizeof.VariantMask * SQUARES_AMOUNT
        mov     [mGrid.variantMasks], eax

        ret
endp

proc    UpdateVariantMasks uses esi edi ebx

        locals
                variant db      ?
                temp    dd      ?
                xSq     dd      ?
                ySq     dd      ?
        endl

        mov     esi, [mGrid.variantMasks]

        mov     ecx, [SquaresAmount]

.InitLoop:

        mov     byte [variant], 0

        mov     eax, [SquaresAmount]
        sub     eax, ecx
        mov     edi, [MapWidth]
        xor     edx, edx
        div     edi
        mov     [xSq], edx
        mov     [ySq], eax

        mov     eax, [ySq]
        mov     edi, [PointsInWidth]
        mul     edi
        add     eax, [xSq]
        mov     edi, sizeof.MarchingPoint
        mul     edi
        add     eax, [mGrid + MarchingGrid.massPoints]


        mov     ebx, eax

        jmp     .ContinueLoop
.CheckLoop:
        loop    .InitLoop
        jmp     .EndLoop
.ContinueLoop:

;---------------------------------------------------------------------------------------|
;                               4   3-4   3        Numbers of vertices of square        |
;                                /--------\        1 - 0000'0001b                       |
;                                |        |        2 - 0000'0010b                       |
;                            4-1 |        | 2-3    3 - 0000'0100b                       |
;                                |        |        4 - 0000'1000b                       |
;                                \--------/                                             |
;                               1   1-2    2                                            |
;---------------------------------------------------------------------------------------|

        fld     [Ground]
        fld     [ebx + MarchingPoint.mass]
        fcomip  st0, st1
        fstp     st0
        jb      @F
        or      [variant], 0000'0001b
@@:
        fld     [Ground]
        fld     [ebx + sizeof.MarchingPoint + MarchingPoint.mass]
        fcomip  st0, st1
        fstp     st0
        jb      @F
        or      [variant], 0000'0010b
@@:
        fld     [Ground]
        fld     [ebx + UPPER_POINT + sizeof.MarchingPoint + MarchingPoint.mass]
        fcomip  st0, st1
        fstp    st0
        jb      @F
        or      [variant], 0000'0100b
@@:
        fld     [Ground]
        fld     [ebx + UPPER_POINT + MarchingPoint.mass]
        fcomip  st0, st1
        fstp     st0
        jb      @F
        or      [variant], 0000'1000b
@@:

        mov     al, [variant]
        mov     [esi + VariantMask.variant], al

        add     esi, sizeof.VariantMask
        jmp     .CheckLoop
.EndLoop:

        ret
endp

proc    Marching.GetSmoothPoint\
        v0, v1

        locals
                result  dd      ?
        endl

        fld     [v0]
        fsub    [Ground]
        fld     [v0]
        fsub    [v1]
        fdivp
        fmul    [SquareSize]
        fstp    [result]

        mov     eax, [result]

        ret
endp

proc    Marching.ChangeValueInRadius uses edi ebx esi,\
        x, y, r, delta

        locals
                PointsY dd      ?
                lX      dd      ?
                rX      dd      ?
                lY      dd      ?
                uY      dd      ?
                tempX   dd      ?
                tempY   dd      ?
                tempDelta       dd      ?
        endl

        fld     [r]
        fdiv    [SquareSize]
        fstp    [r]

        fld     [x]
        fdiv    [SquareSize]
        fstp    [x]

        fld     [y]
        fdiv    [SquareSize]
        fst     [y]
        fadd    [r]
        fistp   [uY]
        fld     [y]
        fsub    [r]
        fistp   [lY]

        mov     ecx, [uY]
        sub     ecx, [lY]
        inc     ecx
        cmp             ecx, 0
        jle     .EndChanging
        mov     edx, [lY]
        mov     [tempY], edx
        mov     esi, [mGrid.massPoints]
        mov     edi, sizeof.MarchingPoint
.YLoop:
        push    ecx

        mov     eax, [tempY]
        mov     ebx, [PointsInWidth]
        mul     ebx
        mov     [PointsY], eax

        fld     [r]
        fmul    st0, st0
        fild    [tempY]
        fsub    [y]
        fmul    st0, st0
        fsubp
        fabs
        fsqrt
        fld     [x]
        fsub    st0, st1
        fistp    [lX]
        fld     [x]
        faddp
        fistp    [rX]

        mov     ecx, [rX]
        sub     ecx, [lX]
        inc     ecx
        cmp             ecx, 0
        jle     .EndChangingX
        mov     edx, [lX]
        mov     [tempX], edx
.XLoop:
                cmp             [tempX], 0
                jl              .Skip
                cmp             [tempX], POINTS_IN_WIDTH
                jg              .Skip
                
                cmp             [tempY], 0
                jl              .Skip
                cmp             [tempY], POINTS_IN_HEIGHT
                jg              .Skip

        fld1
        fild    [tempY]
        fsub    [y]
        fmul    st0, st0
        fild    [tempX]
        fsub    [x]
        fmul    st0, st0
        faddp
        fsqrt
        fdiv    [r]
        fsubp
        fabs
        fmul    [delta]
        fstp    [tempDelta]

        mov     eax, [PointsY]
        add     eax, [tempX]
        mul     edi
        mov     ebx, eax
        fld     [esi + ebx + MarchingPoint.mass]
        fadd    [tempDelta]
        fldz
        fcomip  st0, st1
        fstp    st0
        ja      .LoadZero
        fld     [esi + ebx + MarchingPoint.mass]
        fadd    [tempDelta]
        fld1
        fcomip  st0, st1
        fstp    st0
        jb      .LoadOne
.LoadNumber:
        fld     [esi + ebx + MarchingPoint.mass]
        fadd    [tempDelta]
        fstp    [esi + ebx + MarchingPoint.mass]
        jmp     .Skip
.LoadOne:
        fld1
        fstp    [esi + ebx + MarchingPoint.mass]
        jmp     .Skip
.LoadZero:
        fldz
        fstp    [esi + ebx + MarchingPoint.mass]
.Skip:
        inc     [tempX]
        loop    .XLoop
.EndChangingX:
        pop     ecx
        inc     [tempY]
        dec     ecx
        cmp     ecx, 0
        jg    .YLoop
.EndChanging:
                stdcall UpdateVariantMasks
        
        ret
endp

proc Marching.GradientMap\
     x, val

        fld     [x]
        fild    [PointsInWidth]
        fdivp
        fld     [MapBorders]

        fcomip  st0, st1
        ja      .ExecGrad

        fld1
        fsubrp
        fld     [MapBorders]

        fcomip  st0, st1
        jb      .SkipGrad

.ExecGrad:
        fld     [MapBorders]
        fdivp
        fld     [val]
        fmulp

        fstp    [val]
        mov     eax, [val]
        jmp     .EndGrad
.SkipGrad:
        fstp    [val]
.EndGrad:

        ret
endp

proc    Marching.CollInSquare uses ebx esi edi,\
        trans, delta, velocity, xSq, ySq

        locals
                variant db      ?
                temp    dd      ?
                tempTrans    Transform2D
                tempVector   Transform2D
                v1      Transform2D
                v2      Transform2D
                v3      Transform2D
                v4      Transform2D
                x0              dd              ?
                y0              dd              ?
                normal  Vector2
                g1      dd      ?
                g2      dd      ?
                g3      dd      ?
                g4      dd      ?
                l1              dd              ?
                l2              dd              ?
        endl
        
        mov     esi, [trans]
        mov     edi, [delta]
                        
        mov     eax, [xSq]
        cmp     eax, [MapWidth]
        ja      .NoCorr
        cmp     eax, 0
        jb      .NoCorr

        mov     eax, [ySq]
        cmp     eax, [MapHeight]
        ja      .NoCorr
        cmp     eax, 0
        jb      .NoCorr

        mov     eax, [ySq]
        mov     ebx, [MapWidth]
        mul     ebx
        add     eax, [xSq]
        mov     ebx, sizeof.VariantMask
        mul     ebx
        add     eax, [mGrid.variantMasks]
        mov     ebx, eax
        mov     al, [ebx]
        mov     [variant], al

        mov     edi, [PointsInWidth]
        mov     esi, sizeof.MarchingPoint
        mov     eax, [ySq]
        mul     edi
        add     eax, [xSq]
        mul     esi
        add     eax, [mGrid.massPoints]
        
        fild    [xSq]
        fmul    [SquareSize]
        fstp    [x0]
        
        fild    [ySq]
        fmul    [SquareSize]
        fstp    [y0]

        mov     ebx, eax

        mov     eax, [ebx + MarchingPoint.mass]
        mov     [g1], eax
        mov     eax, [ebx + sizeof.MarchingPoint + MarchingPoint.mass]
        mov     [g2], eax
        mov     eax, [ebx + UPPER_POINT + sizeof.MarchingPoint + MarchingPoint.mass]
        mov     [g3], eax
        mov     eax, [ebx + UPPER_POINT + MarchingPoint.mass]
        mov     [g4], eax

;/////////////////////////1 - 2\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        stdcall Marching.GetSmoothPoint, [g1], [g2]
        mov     [v1.x], eax
        fld     [v1.x]
        fadd    [x0]
        fstp    [v1.x]
        fld     [y0]
        fstp    [v1.y]
;/////////////////////////2 - 3\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        stdcall Marching.GetSmoothPoint, [g2], [g3]
        mov     [v2.y], eax
        fld     [v2.y]
        fadd    [y0]
        fstp    [v2.y]
        fld     [x0]
        fadd    [SquareSize]
        fstp    [v2.x]
;/////////////////////////3 - 4\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        stdcall Marching.GetSmoothPoint, [g4], [g3]
        mov     [v3.x], eax
        fld     [v3.x]
        fadd    [x0]
        fstp    [v3.x]
        fld     [y0]
        fadd    [SquareSize]
        fstp    [v3.y]
;/////////////////////////1 - 4\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        stdcall Marching.GetSmoothPoint, [g1], [g4]
        mov     [v4.y], eax
        fld     [v4.y]
        fadd    [y0]
        fstp    [v4.y]
        fld     [x0]
        fstp    [v4.x]


                lea             ebx, [normal]
        
                cmp     [variant], 0000'0000b
        je      .NoCorr

        cmp    [variant], 0000'0001b
        je     .FirstLineCorr
        cmp    [variant], 0000'1110b
        jne    @F
.FirstLineCorr:
                lea             edi, [v1]
                fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fstp    [normal.y]
        jmp             .OneLineCorr
@@:
        cmp    [variant], 0000'0010b
        je      .SecondLineCorr
        cmp    [variant], 0000'1101b
        jne    @F
.SecondLineCorr:
                lea             edi, [v2]
        fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g2]
        fsub    [g3]
        fstp    [normal.y]
        jmp             .OneLineCorr
@@:
        cmp    [variant], 0000'0100b
        je      .ThirdLineCorr
        cmp    [variant], 0000'1011b
        jne    @F
.ThirdLineCorr:
                lea             edi, [v3]
        fld     [g4]
        fsub    [g3]
        fstp    [normal.x]
        fld     [g2]
        fsub    [g3]
        fstp    [normal.y]
        jmp             .OneLineCorr
@@:
        cmp    [variant], 0000'1000b
        je      .FourthLineCorr
        cmp    [variant], 0000'0111b
        jne    @F
.FourthLineCorr:
                lea             edi, [v4]
        fld     [g4]
        fsub    [g3]
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fstp    [normal.y]
                jmp             .OneLineCorr
@@:
        cmp    [variant], 0000'1100b
        je      .FifthLineCorr
        cmp    [variant], 0000'0011b
        jne    @F
.FifthLineCorr:
                lea             edi, [v2]
        fld     [g1]
        fadd    [g3]
        fsub    [g2]
        fsub    [g4]
        fmul    [Ground]
        fld     [g4]
        fmul    [g2]
        faddp
        fld     [g1]
        fmul    [g3]
        fsubp
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fld     [g2]
        fsub    [g3]
        fabs
        fmulp
        fstp    [normal.y]
        jmp             .OneLineCorr
@@:
        cmp    [variant], 0000'1001b
        je     .SixthLineCorr
        cmp    [variant], 0000'0110b
        jne    @F
.SixthLineCorr:
                lea             edi, [v1]
        fld     [g1]
        fadd    [g3]
        fsub    [g2]
        fsub    [g4]
        fmul    [Ground]
        fld     [g2]
        fmul    [g4]
        faddp
        fld     [g1]
        fmul    [g3]
        fsubp
        fld     [g1]
        fsub    [g2]
        fld     [g1]
        fsub    [g2]
        fabs
        fdivp
        fmulp
        fstp    [normal.y]
        fld     [g1]
        fsub    [g2]
        fld     [g4]
        fsub    [g3]
        fabs
        fmulp
        fstp    [normal.x]
        
.OneLineCorr:
                stdcall Vector2.Normilize, ebx
                
                mov             esi, [trans]
                fld             [esi + Transform2D.x]
                fsub    [edi + Transform2D.x]
                fstp    [tempVector.x]
                
                fld             [esi + Transform2D.y]
                fsub    [edi + Transform2D.y]
                fstp    [tempVector.y]
                
                lea             eax, [tempVector]
                
                stdcall Vector2.ScalarProduct, eax, ebx
                mov             [temp], eax
                fld             [temp]
                FLDZ
                fcomip  st0, st1
                fstp    st0
                jb              .NoCorr
                
                fld             [normal.y]
                fld             [AngleRes]
                fcomip  st0, st1
                fstp    st0
                jb              .YDelta
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.x]
                fadd    [esi + Transform2D.x]
                fstp    [esi + Transform2D.x]
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.y]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                
                fld             [normal.y]
                fld             [normal.x]
                fchs
                fstp    [normal.y]
                fstp    [normal.x]
                
                mov             esi, [velocity]
                
                stdcall Vector2.ScalarProduct, esi, ebx
                mov             [temp], eax
                fld             [temp]
                fmul    [normal.x]
                fstp    [esi + Vector2.x]
                
                fld             [temp]
                fmul    [normal.y]
                fstp    [esi + Vector2.y]
                
                jmp             .Corr
.YDelta:
                
                fld             [temp]
                FABS
                fdiv    [normal.y]
                fadd    [CollDist]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                mov             esi, [velocity]
                fldz    
                fst     [esi + Vector2.y]
                fstp    [esi + Vector2.x]
                jmp             .CorrGround
@@:
        cmp    [variant], 0000'0101b
        jne    @F
.SpecialLines1Corr:
                lea             edi, [v1]
                fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g2]
        fsub    [g3]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
                
                mov             esi, [trans]
                fld             [esi + Transform2D.x]
                fsub    [edi + Transform2D.x]
                fstp    [tempVector.x]
                
                fld             [esi + Transform2D.y]
                fsub    [edi + Transform2D.y]
                fstp    [tempVector.y]
                
                lea             eax, [tempVector]
                
                stdcall Vector2.ScalarProduct, eax, ebx
                mov             [temp], eax
                mov             [l1], eax
                fld             [temp]
                FLDZ
                fcomip  st0, st1
                fstp    st0
                jb              .NoCorr
                
                lea             edi, [v4]
                fld     [g4]
        fsub    [g3]
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
                
                mov             esi, [trans]
                fld             [esi + Transform2D.x]
                fsub    [edi + Transform2D.x]
                fstp    [tempVector.x]
                
                fld             [esi + Transform2D.y]
                fsub    [edi + Transform2D.y]
                fstp    [tempVector.y]
                
                lea             eax, [tempVector]
                
                stdcall Vector2.ScalarProduct, eax, ebx
                mov             [temp], eax
                mov             [l2], eax
                fld             [temp]
                FLDZ
                fcomip  st0, st1
                fstp    st0
                jb              .NoCorr
                
                fld             [l1]
                fld             [l2]
                fcomip  st0, st1
                fstp    st0
                ja              .Slm1
                fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g2]
        fsub    [g3]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
.Slm1:
                fld             [normal.y]
                fld             [AngleRes]
                fcomip  st0, st1
                fstp    st0
                jb              .YDelta1
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.x]
                fadd    [esi + Transform2D.x]
                fstp    [esi + Transform2D.x]
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.y]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                
                jmp             .Corr

.YDelta1:
                
                fld             [temp]
                FABS
                fdiv    [normal.y]
                fadd    [CollDist]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                jmp             .CorrGround

@@:
        cmp    [variant], 0000'1010b
        jne    @F
.SpecialLines2Corr:
        
                lea             edi, [v1]
                fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
                
                mov             esi, [trans]
                fld             [esi + Transform2D.x]
                fsub    [edi + Transform2D.x]
                fstp    [tempVector.x]
                
                fld             [esi + Transform2D.y]
                fsub    [edi + Transform2D.y]
                fstp    [tempVector.y]
                
                lea             eax, [tempVector]
                
                stdcall Vector2.ScalarProduct, eax, ebx
                mov             [temp], eax
                mov             [l1], eax
                fld             [temp]
                FLDZ
                fcomip  st0, st1
                fstp    st0
                jb              .NoCorr
                
                lea             edi, [v2]
                fld     [g4]
        fsub    [g3]
        fstp    [normal.x]
        fld     [g2]
        fsub    [g3]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
                
                mov             esi, [trans]
                fld             [esi + Transform2D.x]
                fsub    [edi + Transform2D.x]
                fstp    [tempVector.x]
                
                fld             [esi + Transform2D.y]
                fsub    [edi + Transform2D.y]
                fstp    [tempVector.y]
                
                lea             eax, [tempVector]
                
                stdcall Vector2.ScalarProduct, eax, ebx
                mov             [temp], eax
                mov             [l2], eax
                fld             [temp]
                FLDZ
                fcomip  st0, st1
                fstp    st0
                jb              .NoCorr
                
                fld             [l1]
                fld             [l2]
                fcomip  st0, st1
                fstp    st0
                ja              .Slm2
                fld     [g1]
        fsub    [g2]
        fstp    [normal.x]
        fld     [g1]
        fsub    [g4]
        fstp    [normal.y]
        
        stdcall Vector2.Normilize, ebx
.Slm2:
                
                fld             [normal.y]
                fld             [AngleRes]
                fcomip  st0, st1
                fstp    st0
                jb              .YDelta2
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.x]
                fadd    [esi + Transform2D.x]
                fstp    [esi + Transform2D.x]
                
                fld             [temp]
                fchs
                fadd    [CollDist]
                fmul    [normal.y]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                jmp             .Corr
                
.YDelta2:
                
                fld             [temp]
                FABS
                fdiv    [normal.y]
                fadd    [CollDist]
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                jmp             .CorrGround
@@:
                cmp    [variant], 0000'1111b
        jne    @F
                mov             esi, [trans]
                mov             edi, [delta]
                lea             ebx, [normal]
                
                fld             [edi + Vector2.x]
                fstp    [normal.x]
                fld             [edi + Vector2.y]
                fstp    [normal.y]
                
                stdcall Vector2.Normilize, ebx
                
                fld             [esi + Transform2D.x]
                fsub    [x0]
                fld             [SquareSize]
                fld1    
                fadd    st0, st0
                fdivp
                fcomip  st0, st1
                fstp    st0
                jb              .Right
.Left:
                fld             [esi + Transform2D.x]
                fsub    [x0]
                fstp    [temp]
                jmp             .UpDown
.Right: 
                fld             [esi + Transform2D.x]
                fsub    [SquareSize]
                fsub    [x0]
                fstp    [temp]
.UpDown:
        
                fld             [esi + Transform2D.y]
                fsub    [y0]
                fld             [SquareSize]
                fld1    
                fadd    st0, st0
                fdivp
                fcomip  st0, st1
                fstp    st0
                jb              .Up
.Down:
                fld             [esi + Transform2D.y]
                fsub    [y0]
                fld             [temp]
                fabs
                fcomip  st0, st1
                ja              .HorMore
                fstp    st0
                jmp             .HorRepl
.HorMore:
                fstp    [temp]
                jmp             .VertRepl
.Up:    
                fld             [esi + Transform2D.y]
                fsub    [SquareSize]
                fsub    [y0]
                fabs
                fld             [temp]
                fabs
                fcomip  st0, st1
                fchs
                ja              .HorMore
                fstp    st0
                jmp             .HorRepl
                
.VertRepl:
                fld             [temp]
                fabs
                fadd    [CollDist]
                
                fld             [normal.y]
                fld             [normal.y]
                fabs
                fdivp
                fmulp
                
                fchs
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                
                fld             [temp]
                fabs
                fadd    [CollDist]
                
                fdiv    [normal.y]
                fmul    [normal.x]
                
                fchs
                fadd    [esi + Transform2D.x]
                fstp    [esi + Transform2D.x]
                
                jmp             .Corr
.HorRepl:
                fld             [temp]
                fabs
                fadd    [CollDist]
                
                fld             [normal.x]
                fld             [normal.x]
                fabs
                fdivp
                fmulp
                
                fchs
                fadd    [esi + Transform2D.x]
                fstp    [esi + Transform2D.x]
                
                fld             [temp]
                fabs
                fadd    [CollDist]
                
                fdiv    [normal.x]
                fmul    [normal.y]
                
                fchs
                fadd    [esi + Transform2D.y]
                fstp    [esi + Transform2D.y]
                
                jmp             .Corr
@@:
.CorrGround:    
                mov     eax, 2
                jmp     .EndCorr
.Corr:
                mov     eax, 1
                jmp     .EndCorr
.NoCorr:
                mov     eax, 0
.EndCorr:
        ret
endp

proc    Marching.GetResTransColl uses esi edi ebx,\
        trans, delta, velocity

        locals
                xSq     dd      ?
                ySq     dd      ?
                flag    dd      ?
        endl

        mov     esi, [trans]
        mov     edi, [delta]
        
        fld     [esi + Transform2D.x]
        fadd    [edi + Vector2.x]
        fstp    [esi + Transform2D.x]
        
        fld     [esi + Transform2D.y]
        fadd    [edi + Vector2.y]
        fstp    [esi + Transform2D.y]
        
        xor             eax, eax
.CollLoop:
                mov             [flag], eax
                fld             [esi + Transform2D.x]
                fdiv    [SquareSize]
                fistp   [xSq]

                fld             [esi + Transform2D.y]
                fdiv    [SquareSize]
                fistp   [ySq]
        
        stdcall Marching.CollInSquare, [trans], [delta], [velocity], [xSq], [ySq]
                test    eax, eax
                jnz             .CollLoop
.EndColls:
                
                mov             eax, [flag]
        ret
endp