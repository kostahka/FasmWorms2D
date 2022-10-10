proc Interpolate\
     v1, v2, t

locals
        result  dd      ?
endl

        fld     [v2]
        fsub    [v1]
        fmul    [t]
        fadd    [v1]
        fstp    [result]
        mov     eax, [result]

        ret
endp