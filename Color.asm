proc    Color.GetSmoothColor uses esi edi ebx,\
        c1, c2, c0

        mov     esi, [c1]
        mov     edi, [c2]
        mov     ebx, [c0]

        fld     [esi + Color.r]
        fadd    [edi + Color.r]
        fld1
        fld1
        faddp
        fdivp
        fstp    [ebx + Color.r]

        fld     [esi + Color.g]
        fadd    [edi + Color.g]
        fld1
        fld1
        faddp
        fdivp
        fstp    [ebx + Color.g]

        fld     [esi + Color.b]
        fadd    [edi + Color.b]
        fld1
        fld1
        faddp
        fdivp
        fstp    [ebx + Color.b]

        ret
endp