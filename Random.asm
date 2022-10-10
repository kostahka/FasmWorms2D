proc    RandInit uses edi

        invoke GetTickCount
        mov    edi, 110101010100101010b
        mul    edi
        mov    [currentRand],  eax
        mov    [currRandXS], eax
        stdcall Rand
        mov    [predRandXS], eax

        ret
endp

proc    Rand uses edi

        mov     eax, [currentRand]
        mov     edi, [currentRand]
        mul     edi

        shl     edx, 16
        shr     eax, 16
        add     eax, edx

        mov     [currentRand], eax

        ret
endp

proc    Random.XorShift uses ebx

        mov     eax, [predRandXS]
        mov     ebx, [currRandXS]
        mov     [predRandXS], ebx
        mov     edx, eax
        shl     eax, 22
        xor     edx, eax
        mov     eax, edx
        shr     eax, 19
        xor     edx, eax
        mov     eax, ebx
        shr     eax, 5
        xor     eax, ebx
        xor     eax, edx
        mov     [currRandXS], eax

        add     eax, ebx

        ret
endp



proc    RandRangei uses edi,\
        x0, x1

        stdcall Rand
        mov     edi, [x1]
        sub     edi, [x0]
        inc     edi
        xor     edx, edx
        div     edi
        mov     eax, edx
        add     eax, [x0]

        ret
endp

proc    RandRangef\
        x0, x1

        locals
                result  dd      ?
        endl

        stdcall Random.XorShift


        mov     eax, [currRandXS]
        shr     eax, 1
        dec     eax
        mov     [result], eax
        fild    [result]
        mov     [result], 0111'1111'1111'1111'1111'1111'1111'1111b
        fild    [result]
        fdivp
        fld     [x1]
        fsub    [x0]
        fmulp
        fadd    [x0]
        fstp    [result]

        mov     eax, [result]

        ret
endp

currentRand     dd      ?
currRandXS      dd      ?
predRandXS      dd      ?