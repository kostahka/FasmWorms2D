proc    CollWithGround uses edi esi,\
        trans, vel, dT

        locals
                resTrans        Transform2D
                delta           Vector2
                velocity                Vector2
        endl

                mov     edi, [trans]
                mov             esi, [vel]

                fld     [esi + Vector2.x]
                fadd    [esi + Vector2.y]
                fldz
                fcomip  st0, st1
                fstp    st0
                je              .NoTransf     

        fld    [dT]

        fld     [esi + Vector2.x]
        fst             [velocity.x]
        fmul    st0, st1
        fstp    [delta.x]
        fld     [esi + Vector2.y]
        fst             [velocity.y]
        fmul    st0, st1
        fstp    [delta.y]

        fstp    st0

        fld     [edi + Transform2D.x]
        fstp    [resTrans.x]
        fld     [edi + Transform2D.y]
        fstp    [resTrans.y]

                lea             eax, [velocity]
                push    eax
        lea     eax, [delta]
        push    eax
        lea     eax, [resTrans]
        push    eax
        stdcall Marching.GetResTransColl
                
        fld     [resTrans.x]
        fstp    [edi + Transform2D.x]
        fld     [resTrans.y]
        fstp    [edi + Transform2D.y]
        
                fld             [velocity.x]
                fstp    [esi + Vector2.x]
                fld             [velocity.y]
                fstp    [esi + Vector2.y]

.NoTransf:

        ret
endp

proc CalcSpTransPlayers uses esi edi,\
     dT

        or      [controls], 0000'0010'0000'0000b

        mov     esi, [gteams.teams]
        mov     ecx, [gteams.tAmount]
        test    ecx, ecx
        jz              .NoTeams
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
        fld     [edi + Player.xSp]
        fmul    [resistance]
                fmul    [dT]
        fchs
        fadd    [edi + Player.xSp]
        fstp    [edi + Player.xSp]

        fld     [edi + Player.ySp]
        fmul    [resistance]
                fadd    [gravityAcc]
                fmul    [dT]
        fchs
        fadd    [edi + Player.ySp]
        fstp    [edi + Player.ySp]
        
        push    [dT]
        lea             eax, [edi + Player.xSp]
        push    eax
        lea             eax, [edi + Player.x]
        push    eax

        stdcall CollWithGround

        cmp             edi, [currPlayer]
        jne             @F
        and     eax, 2
        stdcall ControlsToPlayer, edi, eax
@@:

        mov     eax, [edi + Player.xSp]
        test    eax, eax
        jz     .UnMovable
        mov     eax, [edi + Player.ySp]
        test    eax, eax
        jz     .UnMovable
        and     [controls], 1111'1101'1111'1111b

.UnMovable:

        fld             [edi + Player.y]
        fldz
        fcomip  st0, st1
        fstp    st0
        jb              @F
        xor             [edi + Player.flags], 1
        mov             [StepTime], WAIT_TIME
@@:
        
                ;jmp            @F
.Die:
                
;@@:

        pop     ecx
        add     edi, sizeof.Player
        dec     ecx
        jnz     .TeamLoop

.NoPlayers:
        pop     ecx
        add     esi, sizeof.Team
        dec     ecx
        jnz     .TeamsLoop
                
.NoTeams:
                ret

endp

proc    ControlsToPlayer uses edi,\
                player, OnGround
                
                        mov     edi, [player]
                        mov     eax, [OnGround]
                        test    eax, EAX
                        jz      .End
                        
                        
                        test    [controls], 0001'0000b
                        jz              @F
                        fld             [PlayerJumpSp]
                        fld1
                        fadd    st0, st0
                        fdivp
                        test    [edi + Player.flags], 0000'0010b
                        jnz             .Right
                        fchs
.Right:
                        fst             [edi + Player.xSp]
                        fld             [PlayerJumpSp]
                        fstp    [edi + Player.ySp]
                        jmp             .End
@@:
                        test    [controls], 0000'0100b
                        jz              @F
                        fld             [PlayerSpeed]
                        fchs
                        fstp    [edi + Player.xSp]
                        and             [edi + Player.flags], 1111'1101b
@@:
                        test    [controls], 0000'0001b
                        jz              @F
                        fld             [PlayerSpeed]
                        fstp    [edi + Player.xSp]
                        or              [edi + Player.flags], 0000'0010b
@@:
                        test    [controls], 0000'0101b
                        jnz             @F
                        fldz    
                        fstp    [edi + Player.xSp]
                                
@@:

        
                
.End:   
                
                        ret
endp

proc PhysicsToProjectile\
                dT
                
                test    [projectile.flags], 0000'0001b
                jz              .End
                
                fld     [projectile.xSp]
        fmul    [resistance]
                fmul    [dT]
        fchs
        fadd    [projectile.xSp]
        fstp    [projectile.xSp]

        fld     [projectile.ySp]
        fmul    [resistance]
                fadd    [gravityAcc]
                fmul    [dT]
        fchs
        fadd    [projectile.ySp]
        fstp    [projectile.ySp]

                push    [dT]
                lea             edi, [projectile.xSp]
                push    edi
                lea     edi, [projectile.x]
                push    edi
        stdcall CollWithGround
                test    eax, eax
                jz              @F
                stdcall Projectile.Crash
                lea             edi, [projectile.x]
                stdcall Player.Hit, edi
                stdcall Marching.ChangeValueInRadius, [projectile.x], [projectile.y], [rocketRadius], -1.0  
                jmp             .End
@@:             
                fld             [projectile.y]
        fldz
        fcomip  st0, st1
        fstp    st0
        jb              @F
                stdcall Projectile.Crash
@@:
.End:                   
                
                ret
endp

proc PhysicsProc\
        deltaTime

                locals
                        dT      dd      ?
                endl

                fild    [deltaTime]
                fmul    [timeK]
                fstp    [dT]    
        
        stdcall PhysicsToProjectile, [dT]
        
        stdcall CalcSpTransPlayers, [dT]
        
                test    [controls], 0000'0010b
                jz              @F
                fld             [lookAngle]
                fadd    [speedAngle]
                fldpi   
                fcomip  st0, st1
                ja              .LessPi
                fstp    st0
                fldpi
.LessPi:
                fstp    [lookAngle]
@@:
                test    [controls], 0000'1000b
                jz              @F
                fld             [lookAngle]
                fsub    [speedAngle]
                fldz    
                fcomip  st0, st1
                jb              .MoreZero
                fstp    st0
                fldz
.MoreZero:
                fstp    [lookAngle]

@@:
                test    [controls], 1000'0000b
                jnz             .End
                test    [controls], 0100'0000b
                jz              @F
                fld             [force]
                fadd    [deltaForce]
                fld             [maxForce]
                fcomip  st0, st1
                ja              .NotMaxForce
                fstp    st0
                fld             [maxForce]
                and             [controls], 1111'1111'1011'1111b
                jmp             @F
.NotMaxForce:
                fstp    [force]
                jmp     .End
@@:
                cmp             [force], 0
                je              .End
                stdcall Shoot
.End:

        ret
endp

timeK   dd      0.005
gravityAcc      dd     9.81
resistance              dd      0.01
CollDist        dd      0.01
AngleRes        dd      0.1