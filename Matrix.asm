proc Matrix.ProjectionOrtho uses edi,\
     x, y, width, height, zFar, zNear

        locals
                matrix          Matrix4x4
                deltaZ          dd              ?
        endl

        lea     edi, [matrix]
        mov     ecx, 4 * 4
        xor     eax, eax
        rep     stosd

        lea     edi, [matrix]

        fld1
        fld1
        faddp
        fld     [width]
        fdivp
        fstp    [edi + Matrix4x4.m11]

        fld1
        fld1
        faddp
        fld     [height]
        fdivp
        fstp    [edi + Matrix4x4.m22]

        fld     [zFar]
        fsub    [zNear]
        fstp    [deltaZ]

        fld1
        fld1
        faddp
        fchs
        fld     [deltaZ]
        fdivp
        fstp    [edi + Matrix4x4.m33]

        fld     [zNear]
        fadd    [zFar]
        fld     [deltaZ]
        fdivp
        fchs
        fstp    [edi + Matrix4x4.m43]

        fld1
        fstp    [edi + Matrix4x4.m44]

        fld     [x]
        fadd    [x]
        fadd    [width]
        fdiv    [width]
        fchs
        fstp    [edi + Matrix4x4.m41]

        fld     [y]
        fadd    [y]
        fadd    [height]
        fdiv    [height]
        fchs
        fstp    [edi + Matrix4x4.m42]

        invoke  glMultMatrixf, edi

        ret
endp

proc Matrix.ProjectionOrtho2d uses edi,\
     x0, x1, y0, y1

locals
        width dd ?
        height dd ?
endl
        fld     [x1]
        fsub    [x0]
        fstp    [width]

        fld     [y1]
        fsub    [y0]
        fstp    [height]

        stdcall Matrix.ProjectionOrtho, [x0], [y0], [width], [height], -1.0, 1.0

        ret
endp

proc Matrix.ProjectionPerspective\
     aspect, fov, zNear, zFar

        locals
                matrix          Matrix4x4
                sine            dd              ?
                cotangent       dd              ?
                deltaZ          dd              ?
                radians         dd              ?
        endl

        lea     edi, [matrix]
        mov     ecx, 4 * 4
        xor     eax, eax
        rep     stosd

        lea     edi, [matrix]

        fld     [fov]
        fld1
        fld1
        faddp
        fdivp
        fdiv    [radian]
        fstp    [radians]

        fld     [zFar]
        fsub    [zNear]
        fstp    [deltaZ]

        fld     [radians]
        fsin
        fstp    [sine]

        fld     [radians]
        fcos
        fdiv    [sine]
        fstp    [cotangent]

        fld     [cotangent]
        fdiv    [aspect]
        fstp    [edi + Matrix4x4.m11]

        fld     [cotangent]
        fstp    [edi + Matrix4x4.m22]

        fld     [zFar]
        fadd    [zNear]
        fdiv    [deltaZ]
        fchs
        fstp    [edi + Matrix4x4.m33]

        fld1
        fchs
        fstp    [edi + Matrix4x4.m34]

        fld1
        fld1
        faddp
        fchs
        fmul    [zNear]
        fmul    [zFar]
        fdiv    [deltaZ]
        fstp    [edi + Matrix4x4.m43]

        invoke  glMultMatrixf, edi

        ret
endp

proc Matrix.LookAt2D uses esi edi ebx,\
     camPos, camSize

        locals
                temp    dd      ?
        endl

        mov     esi, [camPos]
        mov     ebx, [camSize]

        fld     [ebx + Vector2.y]
        fld1
        fadd    st0, st0
        fdivp
        fst     [temp]
        push    [temp]
        fchs
        fstp    [temp]
        push    [temp]

        fld     [ebx + Vector2.x]
        fld1
        fld1
        faddp
        fdivp
        fst     [temp]
        push    [temp]
        fchs
        fstp    [temp]
        push    [temp]

        stdcall Matrix.ProjectionOrtho2d

        fldz
        fstp    [temp]
        push    [temp]

        fld     [esi + Transform2D.y]
        fchs
        fstp    [temp]
        push    [temp]

        fld     [esi + Transform2D.x]
        fchs
        fstp    [temp]
        push    [temp]

        invoke  glTranslatef

        ret
endp

proc Matrix.LookAt uses esi edi ebx,\
     camera, target, up

        locals
                temp    dd              ?
                matrix  Matrix4x4
                zAxis   Vector3
                xAxis   Vector3
                yAxis   Vector3
        endl

        lea     edi, [matrix]
        mov     ecx, 4 * 4
        xor     eax, eax
        rep     stosd

        mov     esi, [camera]
        mov     edi, [target]
        mov     ebx, [up]

        fld     [edi + Vector3.x]
        fsub    [esi + Vector3.x]
        fstp    [zAxis.x]

        fld     [edi + Vector3.y]
        fsub    [esi + Vector3.y]
        fstp    [zAxis.y]

        fld     [edi + Vector3.z]
        fsub    [esi + Vector3.z]
        fstp    [zAxis.z]

        lea     eax, [zAxis]
        stdcall Vector3.Normalize, eax

        lea     eax, [zAxis]
        lea     ecx, [xAxis]
        stdcall Vector3.Cross, eax, ebx, ecx

        lea     eax, [xAxis]
        stdcall Vector3.Normalize, eax

        lea     eax, [xAxis]
        lea     ecx, [zAxis]
        lea     ebx, [yAxis]
        stdcall Vector3.Cross, eax, ecx, ebx

        lea     esi, [xAxis]
        lea     edi, [matrix]
        fld     [esi + Vector3.x]
        fstp    [edi + Matrix4x4.m11]
        fld     [esi + Vector3.y]
        fstp    [edi + Matrix4x4.m21]
        fld     [esi + Vector3.z]
        fstp    [edi + Matrix4x4.m31]

        fld     [ebx + Vector3.x]
        fstp    [edi + Matrix4x4.m12]
        fld     [ebx + Vector3.y]
        fstp    [edi + Matrix4x4.m22]
        fld     [ebx + Vector3.z]
        fstp    [edi + Matrix4x4.m32]

        lea     esi, [zAxis]
        fld     [esi + Vector3.x]
        fchs
        fstp    [edi + Matrix4x4.m13]
        fld     [esi + Vector3.y]
        fchs
        fstp    [edi + Matrix4x4.m23]
        fld     [esi + Vector3.z]
        fchs
        fstp    [edi + Matrix4x4.m33]

        fld1
        fstp    [edi + Matrix4x4.m44]

        invoke  glMultMatrixf, edi

        mov     esi, [camera]
        fld     [esi + Vector3.z]
        fchs
        fstp    [temp]
        push    [temp]
        fld     [esi + Vector3.y]
        fchs
        fstp    [temp]
        push    [temp]
        fld     [esi + Vector3.x]
        fchs
        fstp    [temp]
        push    [temp]
        invoke  glTranslatef

        ret
endp