proc Transfrom2D.DistanceTo uses esi edi,\
     v1, v2

        locals
                temp    dd      ?
        endl

        mov     esi, [v1]
        mov     edi, [v2]

        fld     [esi + Transform2D.x]
        fsub    [edi + Transform2D.x]
        fmul    st0, st0

        fld     [esi + Transform2D.y]
        fsub    [edi + Transform2D.y]
        fmul    st0, st0

        faddp
        fsqrt
        fstp    [temp]
        mov     eax, [temp]

        ret
endp

proc Transform2D.SectionCrossing uses esi edi ebx,\
     v01, v02, v11, v12, resTrans

        locals
                vec1    Vector2
                vec2    Vector2
                z1      dd      ?
                z2      dd      ?
                flag    dd              ?
        endl

        mov     esi, [v01]
        mov     edi, [v02]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec1.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec1.y]

        mov     edi, [v11]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec2.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec2.y]

        lea     eax, [vec1]
        push    eax
        push    eax
        lea     eax, [vec2]
        push    eax
        stdcall Vector2.CrossProduct
        mov     [z1], eax

        mov     edi, [v12]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec2.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec2.y]

        lea     eax, [vec2]
        push    eax
        stdcall Vector2.CrossProduct
        mov     [z2], eax

        fld     [z1]
        fmul    [z2]
        fldz
        FCOMIP  st0, st1
        fstp    st0
        jb      .ReturnZero
        JE              .Return2
                mov     [flag], 1
        jmp             @F
.Return2:
        mov     [flag], 2
@@:

;-----------------
        mov     esi, [v11]
        mov     edi, [v12]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec1.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec1.y]

        mov     edi, [v01]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec2.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec2.y]

        lea     eax, [vec1]
        push    eax
        push    eax
        lea     eax, [vec2]
        push    eax
        stdcall Vector2.CrossProduct
        mov     [z1], eax

        mov     edi, [v02]

        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fstp    [vec2.x]

        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fstp    [vec2.y]

        lea     eax, [vec2]
        push    eax
        stdcall Vector2.CrossProduct
        mov     [z2], eax

        fld     [z1]
        fmul    [z2]
        FLDZ
        FCOMIP  st0, st1
        fstp    st0
        jb      .ReturnZero
;----------------
        mov     ebx, [resTrans]
        fld     [z1]
        fld     [z2]
        fsub    [z1]
        fdivp
        fabs
        fstp    [z1]

        ;<-mov     edi, [v02]
        mov     esi, [v01]

        fld     [esi + Transform2D.x]
        fld     [edi + Transform2D.x]
        fsub    [esi + Transform2D.x]
        fmul    [z1]
        fsubp
        fstp    [ebx + Transform2D.x]

        fld     [esi + Transform2D.y]
        fld     [edi + Transform2D.y]
        fsub    [esi + Transform2D.y]
        fmul    [z1]
        fsubp
        fstp    [ebx + Transform2D.y]

        jmp     .EndCross
.ReturnZero:
        mov             [flag], 0
.EndCross:
                mov             eax, [flag]
                
        ret
endp

proc    Vector2.ScalarProduct uses esi edi,\
        v1, v2

        locals
                temp    dd      ?
        endl

                mov             esi, [v1]
                mov             edi, [v2]

        fld     [esi + Vector2.x]
        fmul    [edi + Vector2.x]

        fld     [esi + Vector2.y]
        fmul    [edi + Vector2.y]

        faddp
        fstp    [temp]
        mov     eax, [temp]

        ret
endp

proc    Vector2.CrossProduct uses esi edi,\
        v1, v2

        locals
                temp    dd      ?
        endl

        mov     esi, [v1]
        mov     edi, [v2]

        fld     [esi + Vector2.x]
        fmul    [edi + Vector2.y]

        fld     [esi + Vector2.y]
        fmul    [edi + Vector2.x]

        fsubp
        fstp    [temp]
        mov     eax, [temp]

        ret
endp

proc    Vector2.Normilize uses esi,\
        v

        mov     esi, [v]

        mov     eax, [esi + Vector2.x]
        add     eax, [esi + Vector2.y]
        jnz     @F
        fldz
        fst     [esi + Vector2.x]
        fstp    [esi + Vector2.y]
        jmp     .End
@@:

        fld     [esi + Vector2.x]
        fmul    st0, st0

        fld     [esi + Vector2.y]
        fmul    st0, st0

        faddp
        fsqrt

        fld     [esi + Vector2.x]
        fdiv    st0, st1
        fstp    [esi + Vector2.x]

        fld     [esi + Vector2.y]
        fdivrp
        fstp    [esi + Vector2.y]

.End:

        ret
endp