proc Draw uses edi

        locals
                MousePoint      POINT
                temp            dd      ?
        endl
 

                mov             edi, [camAim]
        fld     [edi + Transform2D.x]
        fstp    [camPos.x]

        fld     [edi + Transform2D.y]
        fstp    [camPos.y]

        invoke glClearColor, 0.1, 0.1, 0.1, 1.0
        invoke glClear, GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT

        invoke glMatrixMode, GL_MODELVIEW
        invoke glLoadIdentity

        invoke  glUseProgram, 0

        invoke  glColor3f, [textColor.r], [textColor.g], [textColor.b]
        test    [controls], 0000'0001'0000'0000b
        jnz     .WriteEndTitle

        invoke  glRasterPos2i, -200, 250
        movzx   eax, [turnTitleLen]
        invoke  glCallLists, eax, GL_UNSIGNED_BYTE, turnTitle

        jmp     @F
.WriteEndTitle:

        invoke  glRasterPos2i, -200, 200
        movzx   eax, [endGameTitleLen]
        invoke  glCallLists, eax, GL_UNSIGNED_BYTE, [endGameTitle]

@@:

        stdcall Draw.TimeBar, [StepTime]
        
        stdcall Matrix.LookAt2D, camPos, camSize

        stdcall Draw.Sea

        invoke  glUseProgram, 0

        stdcall Draw.Players
       
        stdcall Draw.Projectile

        invoke  glUseProgram, 0

        stdcall Draw.MarchingGrid

        stdcall Draw.BackGround

        invoke SwapBuffers, [hdc]

        ret
endp

proc    Draw.ScreenShader

                locals
                        temp    dd      ?
                        x       dd      ?
                        y       dd      ?
                        two     dd      ?
                endl
        
        
                fld1
                fadd    st0, st0
                fstp    [two]

                fild    [clientRect.right]
                fdiv    [two]
                fadd    [camPos.x]
                fstp    [x]

                fild    [clientRect.bottom]
                fdiv    [two]
                fadd    [camPos.y]
                fstp    [y]

                invoke  glBegin, GL_QUADS
                invoke  glVertex2f, [x], [y]

                push    [y]
                fld     [x]
                fchs
                fstp    [temp]
                push    [temp]
                invoke  glVertex2f
                
                fld     [y]
                fchs
                fstp    [temp]
                push    [temp]
                fld     [x]
                fchs
                fstp    [temp]
                push    [temp]
                invoke  glVertex2f
                
                fld     [y]
                fchs
                fstp    [temp]
                push    [temp]
                push    [x]
                invoke  glVertex2f
                invoke  glEnd
                
                ret
endp

proc    Draw.Sea

                invoke  glUseProgram, [programSea]
        
                invoke  glUniform2i, 0, [clientRect.right], [clientRect.bottom]
                invoke  glUniform1i, 1, [phTime]
                invoke  glUniform2f, 2, [camPos.x], [camPos.y]
                invoke  glUniform2f, 3, [camSize.x], [camSize.y]

                stdcall Draw.ScreenShader

                ret
endp

proc    Draw.BackGround
        
                invoke  glUseProgram, [programBG]
        
                invoke  glUniform2i, 0, [clientRect.right], [clientRect.bottom]
                invoke  glUniform1i, 1, [phTime]

                stdcall Draw.ScreenShader
                
                ret
endp

proc    Draw.Projectile
        
                test    [projectile.flags], 0000'0001b
                jz              .End

                invoke glUseProgram, [programRocket]

                invoke  glUniform2i, 0, [clientRect.right], [clientRect.bottom]
                invoke  glUniform1i, 1, [phTime]
                invoke  glUniform2f, 2, [camPos.x], [camPos.y]
                invoke  glUniform2f, 3, [camSize.x], [camSize.y]
                invoke  glUniform2f, 4, [projectile.xSp], [projectile.ySp]

                stdcall Draw.ScreenShader

                ;invoke glColor3f, 0.9, 0.5, 0.7
                ;invoke glPointSize, 7.0
                ;invoke glBegin, GL_POINTS
                ;invoke glVertex2f, [projectile.x], [projectile.y]
                ;invoke glEnd
        
.End:
        
                ret
endp

proc    Draw.ForceBar uses edi
                
                        locals
                                x1      dd      ?
                                y1      dd      ?
                                x2      dd      ?
                                y2      dd      ?
                        endl
                        
                        mov             edi, [currPlayer]
                        
                        
                        invoke glBegin, GL_TRIANGLES           
                        
                        fld             [lookAngle]
                        fadd    [forceBarAngle]
                        fsincos
                        fmul    [forceBarSize]
                        fmul    [force]
                        fadd    [edi + Player.y]
                        fstp    [y1]
                        fmul    [forceBarSize]
                        fmul    [force]
                        test    [edi + Player.flags], 0000'0010b
                        jnz             @F
                        fchs
@@:
                        fadd    [edi + Player.x]
                        fstp    [x1]
                        
                        fld             [lookAngle]
                        fsub    [forceBarAngle]
                        fsincos
                        fmul    [forceBarSize]
                        fmul    [force]
                        fadd    [edi + Player.y]
                        fstp    [y2]
                        fmul    [forceBarSize]
                        fmul    [force]
                        test    [edi + Player.flags], 0000'0010b
                        jnz             @F
                        fchs
@@:
                        fadd    [edi + Player.x]
                        fstp    [x2]
                        
                        invoke glColor3f, 0.9, 0.2, 0.2
                        invoke glVertex2f, [x1], [y1]
                        invoke glVertex2f, [x2], [y2]
                        ;invoke glColor3f, 0.2, 0.5, 0.2
                        invoke glVertex2f, [edi + Player.x], [edi + Player.y]           
                              
                        invoke glEnd
                        
                        ret
endp

proc    Draw.HealthBar uses esi,\
                trans, health

                locals
                        x0      dd      ?
                        x1      dd      ?
                        y1      dd      ?
                        y0      dd      ?
                endl

                mov             esi, [trans]
                fld             [esi + Transform2D.x] ;x'
                fsub    [healthBarWidth]        ; x' - w
                fst             [x0]                            ; x'-w
                fild    [health]                        ; h | x' - w
                fidiv   [maxHealth]                     ;h/mh | x' - w
                fld1                                            ; 1| h/mh | x' - w
                fadd    st0, st0                        ; 2| ...
                fmul    [healthBarWidth]        ;2w| h/mh | ...
                fmulp                                           ;2w*h/mh | x' - w
                faddp                                           ; x1
                fstp    [x1]
                
                fld             [esi + Transform2D.y]
                fadd    [healthBarDelta]
                fld             [healthBarHeight]
                fadd    st0, st1
                fstp    [y0]
                fsub    [healthBarHeight]
                fstp    [y1]

                invoke glColor3f, 0.9, 0.1, 0.1
        invoke glBegin, GL_QUADS           
        invoke glVertex2f, [x0], [y0]           
        invoke glVertex2f, [x1], [y0]           
        invoke glVertex2f, [x1], [y1]  
        invoke glVertex2f, [x0], [y1]      
        invoke glEnd

                ret
endp    

proc    Draw.Players uses edi esi
                
                locals
                        temp    dd      ?
                endl
                
                mov             edi, [currPlayer]
                
                stdcall Draw.ForceBar
                
                invoke glPointSize, 5.0
                
                invoke glColor3f, 0.9, 0.5, 0.5
                invoke glBegin, GL_POINTS
                fld             [lookAngle]
                fsincos
                fmul    [aimDistance]
                fadd    [edi + Player.y]
                fstp    [temp]
                push    [temp]
                fmul    [aimDistance]
                test    [edi + Player.flags], 0000'0010b
                jnz             @F
                fchs
@@:
                fadd    [edi + Player.x]
                fstp    [temp]
                push    [temp]  
                invoke glVertex2f
                invoke glEnd
                
                invoke glBegin, GL_LINE_STRIP
                
                invoke glColor3f, 0.3, 0.5, 0.5
                
                fld             [edi + Player.y]
                fadd    [arrowHeight]
                fadd    [arrowDelta]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fadd    [arrowWidth]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f
                
                fld             [edi + Player.y]
                fadd    [arrowDelta]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f
                
                fld             [edi + Player.y]
                fadd    [arrowHeight]
                fadd    [arrowDelta]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fsub    [arrowWidth]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f
                
                invoke glEnd
                
                invoke glPointSize, 10.0
                
                mov     esi, [gteams.teams]
        mov     ecx, [gteams.tAmount]
        test    ecx, ecx
        jz              .NoTeams
        push    ecx
                pop             ecx
.TeamsLoop:
        push    ecx

        mov     edi, [esi + Team.players]
        mov     ecx, [esi + Team.plAmount]
        test    ecx, ecx
                jz              .NoPlayers
.TeamLoop:
        push    ecx

                test    [edi + Player.flags], 1
                jz              .Die
                invoke glBegin, GL_POINTS
        invoke glColor3f, [edi + Player.r], [edi + Player.g], [edi + Player.b]
        invoke glVertex2f, [edi + Player.x], [edi + Player.y]
        invoke glEnd
        
        lea             eax, [edi + Player.x]
        stdcall Draw.HealthBar, eax, [edi + Player.hp]
        jmp             @F
.Die:
                invoke glBegin, GL_LINES
                invoke glColor3f, 0.8, 0.2, 0.2
                
                fld             [edi + Player.y]
                fadd    [crossSize]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fadd    [crossSize]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f 
                
                fld             [edi + Player.y]
                fsub    [crossSize]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fsub    [crossSize]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f 
                
                fld             [edi + Player.y]
                fsub    [crossSize]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fadd    [crossSize]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f 
                
                fld             [edi + Player.y]
                fadd    [crossSize]
                fstp    [temp]
                push    [temp]
                fld             [edi + Player.x]
                fsub    [crossSize]
                fstp    [temp]
                push    [temp]
                invoke glVertex2f 
                invoke glEnd
@@:

        pop     ecx
        add     edi, sizeof.Player
        dec             ecx
        jnz             .TeamLoop

.NoPlayers:
        pop     ecx
        add     esi, sizeof.Team
        dec             ecx
        jnz             .TeamsLoop
                
.NoTeams:
                ret
endp

proc    Draw.TimeBar\
                stTime
                
                        locals
                                x0      dd      ?
                                y0      dd      ?
                                x1      dd      ?
                                y1      dd      ?
                                x       dd      ?
                        endl
                
                        fild    [TimeBar.right]
                        fld1
                        fadd    st0, st0
                        fdivp
                        fchs
                        fstp    [x0]
                        
                        fild    [TimeBar.right] 
                        fld1
                        fadd    st0, st0
                        fdivp
                        fstp    [x1]
                        
                        fild    [TimeBar.top]
                        fstp    [y0]
                        
                        fild    [TimeBar.bottom]
                        fstp    [y1]
                        
                        fild    [stTime]
                        mov     [x], STEP_TIME
                        fidiv   [x]
                        fimul   [TimeBar.right]
                        fild    [TimeBar.right]
                        FLD1
                        fadd    st0, st0
                        fdivp
                        fsubp
                        fstp    [x]
                        
                        
                        invoke glBegin, GL_QUADS
                        ;invoke glColor3f, 0.8, 0.3, 0.3
                        invoke glColor3f, 0.7, 0.8, 0.5
                        invoke glVertex2f, [x0], [y0]
                        invoke glVertex2f, [x0], [y1]

                        invoke glVertex2f, [x], [y1]
                        invoke glVertex2f, [x], [y0]
                        invoke glEnd
                        
                        invoke glColor3f, 0.6, 0.6, 0.6
                        invoke glBegin, GL_LINE_LOOP
                        invoke glVertex2f, [x0], [y0]
                        invoke glVertex2f, [x0], [y1]
                        invoke glVertex2f, [x1], [y1]
                        invoke glVertex2f, [x1], [y0]
                        invoke glEnd
                        
                        ret
endp

proc    Draw.MarchingSquare uses esi edi ebx,\
        x, y, idPoint, idColor, idVariant

        locals
                variant db      ?
                tempX   dd      ?
                tempY   dd      ?
                c0      Color
                g1      dd      ?
                g2      dd      ?
                g3      dd      ?
                g4      dd      ?
        endl

        mov     ebx, [idVariant]
        mov     al, [ebx]
        mov     [variant], al

        fld     [x]
        fstp    [tempX]
        fld     [y]
        fstp    [tempY]

        mov     ebx, [idPoint]
        mov     eax, [ebx + MarchingPoint.mass]
        mov     [g1], eax
        mov     eax, [ebx + sizeof.MarchingPoint + MarchingPoint.mass]
        mov     [g2], eax
        mov     eax, [ebx + UPPER_POINT + sizeof.MarchingPoint + MarchingPoint.mass]
        mov     [g3], eax
        mov     eax, [ebx + UPPER_POINT + MarchingPoint.mass]
        mov     [g4], eax


        mov     esi, [idColor]

        cmp     [variant], 0
        je      .EndDrawing

        invoke glBegin, GL_TRIANGLE_FAN
        ;invoke glBegin, GL_LINE_LOOP

        test    [variant], 0000'0001b
        jz     @F

;////////////Vertix 1\\\\\\\\\\\\\\\\
 
        invoke glColor3f, [esi + Color.r],\
                          [esi + Color.g],\
                          [esi + Color.b]
        invoke glVertex2f, [tempX], [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        mov     al, [variant]
        and     al, 0000'0011b
        jz      @F
        xor     al, 0000'0011b
        jz      @F
;////////////Vertix 1-2\\\\\\\\\\\\\\

        lea         eax, [c0]
        push        eax
        push        esi
        lea         eax, [esi + sizeof.Color]
        push        eax
        stdcall Color.GetSmoothColor

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        stdcall Marching.GetSmoothPoint, [g1], [g2]

        fld     [tempX]
        mov     [tempX], eax
        fadd    [tempX]
        fstp    [tempX]

        invoke glVertex2f, [tempX], [tempY]
        fld    [x]
        fstp   [tempX]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        fld     [tempX]
        fadd    [SquareSize]
        fstp    [tempX]
        test   [variant], 0000'0010b
        jz     @F
;////////////Vertix 2\\\\\\\\\\\\\\\\
        
        invoke glColor3f, [esi + sizeof.Color + Color.r],\
                          [esi + sizeof.Color + Color.g],\
                          [esi + sizeof.Color + Color.b]
        invoke glVertex2f, [tempX], [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        mov     al, [variant]
        and     al, 0000'0110b
        jz      @F
        xor     al, 0000'0110b
        jz      @F
;////////////Vertix 2-3\\\\\\\\\\\\\\

        lea         eax, [c0]
        push        eax
        lea         eax, [esi + UPPER_COLOR + sizeof.Color]
        push        eax
        lea         eax, [esi + sizeof.Color]
        push        eax
        stdcall Color.GetSmoothColor

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        stdcall Marching.GetSmoothPoint, [g2], [g3]

        fld     [tempY]
        mov     [tempY], eax
        fadd    [tempY]
        fstp    [tempY]

        invoke glVertex2f, [tempX], [tempY]
        fld    [y]
        fstp   [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        fld     [tempY]
        fadd    [SquareSize]
        fstp    [tempY]
        test    [variant], 0000'0100b
        jz     @F
;////////////Vertix 3\\\\\\\\\\\\\\\\
        
        invoke glColor3f, [esi + UPPER_COLOR + sizeof.Color + Color.r],\
                          [esi + UPPER_COLOR + sizeof.Color + Color.g],\
                          [esi + UPPER_COLOR + sizeof.Color + Color.b]
        invoke glVertex2f, [tempX], [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        fld     [x]
        fstp    [tempX]
        mov     al, byte [variant]
        and     al, 0000'1100b
        jz      @F
        xor     al, 0000'1100b
        jz      @F
;////////////Vertix 3-4\\\\\\\\\\\\\\
        
        lea         eax, [c0]
        push        eax
        lea         eax, [esi + UPPER_COLOR + sizeof.Color]
        push        eax
        lea         eax, [esi + UPPER_COLOR]
        push        eax
        stdcall Color.GetSmoothColor

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        stdcall Marching.GetSmoothPoint, [g4], [g3]

        fld     [tempX]
        mov     [tempX], eax
        fadd    [tempX]
        fstp    [tempX]

        invoke glVertex2f, [tempX], [tempY]
        fld    [x]
        fstp   [tempX]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        test   [variant], 0000'1000b
        jz     @F
;////////////Vertix 4\\\\\\\\\\\\\\\\
        
        invoke glColor3f, [esi + UPPER_COLOR + Color.r],\
                          [esi + UPPER_COLOR + Color.g],\
                          [esi + UPPER_COLOR + Color.b]
        invoke glVertex2f, [tempX], [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        fld     [y]
        fstp    [tempY]
        mov     al, byte [variant]
        and     al, 0000'1001b
        jz      @F
        xor     al, 0000'1001b
        jz      @F
;////////////Vertix 4-1\\\\\\\\\\\\\\
        
        lea         eax, [c0]
        push        eax
        push        esi
        lea         eax, [esi + UPPER_COLOR]
        push        eax
        stdcall Color.GetSmoothColor

        invoke glColor3f, [c0.r], [c0.g], [c0.b]

        stdcall Marching.GetSmoothPoint, [g1], [g4]

        fld     [tempY]
        mov     [tempY], eax
        fadd    [tempY]
        fstp    [tempY]

        invoke glVertex2f, [tempX], [tempY]
;////////////////\\\\\\\\\\\\\\\\\\\\

@@:
        invoke glEnd

.EndDrawing:

        ret
endp

proc    Draw.MarchingGrid uses esi edi ebx

        locals
                x       dd      ?
                y       dd      ?
        endl

        mov     ecx, [SquaresAmount]
        mov     edi, [PointsInWidth]
        mov     esi, [MapWidth]

.GridLoop:
        push    ecx

        mov     eax, ecx
        dec     eax
        mov     ebx, sizeof.VariantMask
        mul     ebx
        add     eax, [mGrid + MarchingGrid.variantMasks]
        push    eax

        mov     eax, ecx
        dec     eax
        xor     edx, edx
        div     esi
        mov     [x], edx
        mov     [y], eax

        mul     edi
        add     eax, [x]
        mov     ecx, eax
        mov     ebx, sizeof.Color
        mul     ebx
        add     eax, [mGrid + MarchingGrid.colorPoints]
        push    eax

        mov     eax, ecx
        mov     ebx, sizeof.MarchingPoint
        mul     ebx
        add     eax, [mGrid + MarchingGrid.massPoints]
        push    eax

        fild    [x]
        fmul    [SquareSize]
        fstp    [x]
        fild    [y]
        fmul    [SquareSize]
        fstp    [y]

        stdcall Draw.MarchingSquare, [x], [y]

        pop     ecx
        loop    .GridLoop

.EndLoop:
        ret
endp