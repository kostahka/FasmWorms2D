proc Noise uses esi ebx,\
     x

        locals
                temp    dd      ?
        endl

        mov      eax, [x]
        add      eax, [NoiseSeed]

        mov      edx, eax
        shl      eax, 13
        xor      eax, edx

        mov      ebx, eax
        mul      ebx
        mov      esi, 15731
        mul      esi
        add      eax, 789221
        mul      ebx
        add      eax, 1376312589
        and      eax, 7fffffffh

        fld1

        mov      [temp], eax
        fild     [temp]

        mov      [temp], 1073741824.0
        fdiv     [temp]

        fsubp

        fstp    [temp]
        mov     eax, [temp]

        ret
endp

proc Noise2D uses esi ebx,\
     x, y

        locals
                temp    dd      ?
        endl


        mov      eax, [y]
        mov      ebx, 57
        mul      ebx
        add      eax, [x]
        add      eax, [NoiseSeed]

        mov      edx, eax
        shl      eax, 13
        xor      eax, edx

        mov      ebx, eax
        mul      ebx
        mov      esi, 15731
        mul      esi
        add      eax, 789221
        mul      ebx
        add      eax, 1376312589
        and      eax, 7fffffffh

        fld1

        mov      [temp], eax
        fild     [temp]

        mov      [temp], 1073741824.0
        fdiv     [temp]

        fsubp

        fstp    [temp]
        mov     eax, [temp]

        ret
endp

proc InterpolatedNoise2D\
     x, y

locals
        intX    dd      ?
        intY    dd      ?
        v1      dd      ?
        v2      dd      ?
        v3      dd      ?
        v4      dd      ?
        t1      dd      ?
        t2      dd      ?
endl

        fld     [x]
        fist    [intX]
        fisub   [intX]
        fstp    [t1]

        fld     [y]
        fist    [intY]
        fisub   [intY]
        fstp    [t2]

        stdcall Smoothstep, [t1]
        mov     [t1], eax

        stdcall Smoothstep, [t2]
        mov     [t2], eax

        stdcall Noise2D, [intX], [intY]
        mov     [v1], eax

        fld     [v1]
        fldpi
        fmulp
        fsincos
        fld     [t1]
        fmulp
        fstp    [v1]
        fld     [t2]
        fmulp
        fadd    [v1]
        fstp    [v1]

        inc     [intX]

        stdcall Noise2D, [intX], [intY]
        mov     [v2], eax

        fld     [v2]
        fldpi
        fmulp
        fsincos
        fld1
        fld     [t1]
        fsubp
        fmulp
        fstp    [v2]
        fld     [t2]
        fmulp
        fadd    [v2]
        fstp    [v2]

        dec     [intX]
        inc     [intY]

        stdcall Noise2D, [intX], [intY]
        mov     [v3], eax

        fld     [v3]
        fldpi
        fmulp
        fsincos
        fld     [t1]
        fmulp
        fstp    [v3]
        fld1
        fld     [t2]
        fsubp
        fmulp
        fadd    [v3]
        fstp    [v3]

        inc     [intX]

        stdcall Noise2D, [intX], [intY]
        mov     [v4], eax

        fld     [v4]
        fldpi
        fmulp
        fsincos
        fld1
        fld     [t1]
        fsubp
        fmulp
        fstp    [v4]
        fld1
        fld     [t2]
        fsubp
        fmulp
        fadd    [v4]
        fstp    [v4]

        stdcall Interpolate, [v1], [v2], [t1]
        mov     [v1], eax
        stdcall Interpolate, [v3], [v4], [t1]
        mov     [v2], eax
        stdcall Interpolate, [v1], [v2], [t2]

        ret
endp

proc InterpolatedNoise\
     x

locals
        intX    dd      ?
        v1      dd      ?
        v2      dd      ?
        t1      dd      ?
endl

        fld     [x]
        fist    [intX]
        fisub   [intX]
        fstp    [t1]

        stdcall Smoothstep, [t1]
        mov     [t1], eax

        stdcall Noise, [intX]
        mov     [v1], eax

        inc     [intX]

        stdcall Noise, [intX]
        mov     [v2], eax

        stdcall Interpolate, [v1], [v2], [t1]

        ret
endp

proc Smoothstep\
     t

locals
        result  dd      ?
endl

        fld     [t]
        fmul    [t]
        fld1
        fld1
        fld1
        faddp
        faddp
        fmulp

        fld     [t]
        fmul    [t]
        fmul    [t]
        fld1
        fld1
        faddp
        fmulp

        fsubp

        fstp [result]
        mov  eax, [result]

        ret
endp

proc    PerlinNoise2D\
        x, y, mid, amplitude, freq, Oct

locals
        result  dd      ?
        temp    dd      ?
        persist dd      ?
endl

        fld     [amplitude]
        fild    [Oct]
        fild    [Oct]
        fld1
        faddp
        fmulp
        fld1
        fadd	st0, st0
        fdivp
        fdivp
        fstp    [persist]

        fldz
        mov ecx, [Oct]
.NoiseLoop:
        push    ecx

        fld     [freq]

        fld     [y]
        fdiv    st0, st1
        fstp    [temp]
        push    [temp]

        fld     [x]
        fdivrp
        fstp    [temp]
        push    [temp]

        stdcall InterpolatedNoise2D
        mov     [temp], eax
        fld     [temp]
        mov     [temp], ecx
        fild    [temp]
        fmul    [persist]
        fmulp
        faddp

        fld     [freq]
        fld1
        fld1
        faddp
        fdivp
        fstp    [freq]
        pop     ecx
        loop .NoiseLoop

        fadd    [mid]
        fstp    [result]
        mov     eax, [result]

        ret
endp

proc    PerlinNoise\
        x, mid, amplitude, freq, Oct

locals
        result  dd      ?
        temp    dd      ?
        persist dd      ?
endl

        fld     [amplitude]
        fild    [Oct]
        fild    [Oct]
        fld1
        faddp
        fmulp
        fld1
        fld1
        faddp
        fdivp
        fdivp
        fstp    [persist]

        fldz
        mov ecx, [Oct]
.NoiseLoop:
        push    ecx

        fld     [freq]
        fld     [x]
        fdivrp
        fstp    [temp]
        push    [temp]

        stdcall InterpolatedNoise
        mov     [temp], eax
        fld     [temp]
        mov     [temp], ecx
        fild    [temp]
        fmul    [persist]
        fmulp
        faddp

        fld     [freq]
        fld1
        fld1
        faddp
        fdivp
        fstp    [freq]
        pop     ecx
        loop .NoiseLoop

        fadd    [mid]
        fstp    [result]
        mov     eax, [result]
        ret
endp

proc ChangeNoiseSeed\
     seed

        mov     eax, [seed]
        mov     [NoiseSeed], eax

        ret
endp

NoiseSeed    dd      ?