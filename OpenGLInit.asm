proc OpenGLInit

locals
        temp    dd      ?
endl

        invoke wglCreateContext, [hdc]
        invoke wglMakeCurrent, [hdc], eax

        invoke GetClientRect, [hMainWindow], clientRect

        invoke glViewport, ebx, ebx, [clientRect.right], [clientRect.bottom]

        invoke glMatrixMode, GL_PROJECTION
        invoke glLoadIdentity

        fild    [clientRect.bottom]
        fld1
        fadd    st0, st0
        fdivp
        fst     [temp]
        push    [temp]
        fchs
        fstp    [temp]
        push    [temp]
        ;push    ebx

        fild    [clientRect.right]

        fld1
        fadd    st0, st0
        fdivp
        fst    [temp]
        push   [temp]
        fchs
        fstp    [temp]
        push    [temp]
        ;push    ebx

        stdcall Matrix.ProjectionOrtho2d
        
        invoke glEnable, GL_DEPTH_TEST
        ;invoke glEnable, GL_ALPHA_TEST
        invoke glShadeModel, GL_FLAT

        invoke glLineWidth, 2.0
                
        stdcall Glext.LoadFunctions
        ;stdcall Glext.InitShaders

        stdcall CreateProgram

        invoke  glDeleteLists, ebx, NUM_OF_CHARACTERS
        invoke  CreateFont, [fontSize], ebx, ebx, ebx, 600, ebx, ebx, ebx, ebx, ebx, ebx, ebx, ebx, fontName
        invoke  SelectObject, [hdc], eax

        invoke  wglUseFontBitmapsA, [hdc], ebx, NUM_OF_CHARACTERS, ebx

        ret
endp