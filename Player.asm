proc    Player.GetWinner

        locals
                winner  dd      ?
        endl

        mov     [winner], -1

        mov     esi, [gteams.teams]
        mov     ecx, [gteams.tAmount]
        test    ecx, ecx
        jz      .NoTeams
.TeamsLoop:
        push    ecx

        mov     edi, [esi + Team.players]
        mov     ecx, [esi + Team.plAmount]
        test    ecx, ecx
        jz      .NoPlayers
        xor     eax, eax
.TeamLoop:

        test    [edi + Player.flags], 1
        jnz      .HavePlayers
@@:

        add     edi, sizeof.Player
        loop    .TeamLoop
        jmp     .NoPlayers
.HavePlayers:

        cmp     [winner], -1
        jne     .NoWinner
        mov     [winner], esi
.NoPlayers:
        pop     ecx
        add     esi, sizeof.Team
        dec     ecx
        jnz     .TeamsLoop

        jmp     .HaveWinner
.NoWinner:
        mov     [winner], 0
        pop     ecx
.NoTeams:

.HaveWinner:
        mov     eax, [winner]
        ret
endp

proc    Player.InitTeams uses ebx esi edi,\
        nTeam, nPl
                
                locals
                        temp    dd      ?
                        r       dd      ?
                        g       dd      ?
                        b       dd      ?
                        PiByThree    dd      ?
                endl

                fldpi
                fld1
                fadd    st0, st0
                fld1
                faddp
                fdivp
                fstp    [PiByThree]

                mov             eax, [nPl]
                test            eax, eax
                jz              .NoTeams
                
                mov             eax, [nTeam]
                test            eax, eax
                jz              .NoTeams
                mov             ebx, sizeof.Team
                mul             ebx
                invoke          HeapAlloc, [hHeap], 8, eax
                mov             [gteams.teams], eax
                mov             esi, eax
                
                mov             eax, [nPl]
                mov             ebx, sizeof.Player
                mul             ebx
                mov             ebx, eax
                
                mov             ecx, [nTeam]
                mov             [gteams.tAmount], ecx

.TeamsLoop:
                push    ecx
                
                invoke          HeapAlloc, [hHeap], 8, ebx
                mov             [esi + Team.players], eax
                mov             edi, eax
                
                mov             ecx, [nPl]
                mov             [esi + Team.plAmount], ecx

                mov             eax, [esp]
                mov             [temp], eax

                fild            [temp]
                fidiv           [nTeam]
                fldpi
                fld1
                fadd            st0, st0
                fdivp
                fmulp
                fld             [PiByThree]
                fadd            st0, st1
                fcos
                fabs
                fstp            [esi + Team.teamColorR]
                fld             [PiByThree]
                fadd            st0, st0
                fadd            st0, st1
                fcos
                fabs
                fstp            [esi + Team.teamColorG]
                fcos
                fabs
                fstp            [esi + Team.teamColorB]


                pop             ecx
                add             esi, sizeof.Team
                loop    .TeamsLoop
                
                jmp             .End
.NoTeams:
                mov             [gteams.tAmount], 0

.End:


        ret
endp

proc    Player.ChangeCurrPlayer uses ebx edi esi
                
                or              [controls], 0010'0000b
                and             [controls], 0111'1111b
                mov             [StepTime], STEP_TIME
                
                mov             ecx, [gteams.tAmount]
                push    ecx
                jmp             @F
.TeamsLoop:             
                pop             ecx
                dec             ecx
                js              .NoChange
                push    ecx     
@@:
                
                mov             eax, [gteams.currTeam]
                inc             eax
                mov             ebx, [gteams.tAmount]
                xor             edx, edx        
                div             ebx
                mov             [gteams.currTeam], edx
                mov             eax, edx
                mov             ebx, sizeof.Team
                mul             ebx
                mov             ebx, eax
                
                mov             edi, [gteams.teams]
                add             edi, ebx
                
                mov             ecx, [edi + Team.plAmount]
.TeamLoop:
                mov             eax, [edi + Team.currPl]
                inc             eax
                mov             ebx, [edi + Team.plAmount]      
                xor             edx, edx        
                div             ebx
                mov             [edi + Team.currPl], edx
                mov             eax, edx
                mov             ebx, sizeof.Player
                mul             ebx
                mov             ebx, eax
                
                mov             esi, [edi + Team.players]
                add             esi, ebx
                
                dec             ecx
                js              .TeamsLoop
                
                test    [esi + Player.flags], 1
                jz              .TeamLoop

                mov     al, [edi + Team.id]
                add     al, 30h
                mov     [turnTitleLen - 1], al
                fld     [edi + Team.teamColorR]
                fstp    [textColor.r]
                fld     [edi + Team.teamColorG]
                fstp    [textColor.g]
                fld     [edi + Team.teamColorB]
                fstp    [textColor.b]

                mov             edi, [currPlayer]
                fldz    
                fstp            [edi + Player.xSp]
                mov             [currPlayer], esi
                
                lea             edi, [esi + Player.x]
                mov             [camAim], edi

                pop             ecx
.NoChange:

                stdcall Player.GetWinner
                cmp     eax, -1
                je      @F
                cmp     eax, 0
                je      .End
                or      [controls], 0000'0001'0000'0000b
                mov     [endGameTitle], winnerTitle
                mov     edi, eax
                mov     al, [edi + Team.id]
                add     al, 30h
                mov     [winnerTitleLen - 1], al
                mov     al, [winnerTitleLen]
                mov     [endGameTitleLen], al
                jmp     .End
@@:
                or      [controls], 0000'0001'0000'0000b
                mov     [endGameTitle], drawTitle
                mov     al, [drawTitleLen]
                mov     [endGameTitleLen], al
.End:

                ret
        
endp

proc    Player.Die uses edi,\
                pl
        
                mov             edi, [pl]
                
                and             [edi + Player.flags], 1111'1110b
                cmp             edi, [currPlayer]
                jne             .End
                stdcall Player.ChangeCurrPlayer
        
.End:
        
                ret
endp

proc    Player.Hit uses esi edi ebx,\
                trans
                
                locals
                        temp    dd      ?
                        dir     Vector2
                endl
                
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

                
                mov             ebx, [trans]
                lea             eax, [edi + Player.x]
                stdcall Transfrom2D.DistanceTo, ebx, eax
                mov             [temp], eax
                fld             [temp]
                fld             [rocketRadius]
                fcomip  st0, st1
                fstp    st0
                jb              .Next
                
                fld1
                fld             [temp]
                fdiv    [rocketRadius]
                fsubp
                fild    [rocketDamage]
                fmul    st0, st1
                
                fisub   [edi + Player.hp]
                fchs
                fistp   [edi + Player.hp]

                fstp    [temp]
                fld     [edi + Player.x]
                fsub    [ebx + Transform2D.x]
                fstp    [dir.x]
                fld     [edi + Player.y]
                fsub    [ebx + Transform2D.y]
                fstp    [dir.y]
                lea     eax, [dir]
                stdcall Vector2.Normilize, eax

                fld     [dir.x]
                fmul    [temp]
                fmul    [rocketRepulsion]
                fadd    [edi + Player.xSp]
                fstp    [edi + Player.xSp]

                fld     [dir.y]
                fmul    [temp]
                fmul    [rocketRepulsion]
                fadd    [edi + Player.ySp]
                fstp    [edi + Player.ySp]
                
                cmp             [edi + Player.hp], 0
                jg              .Next
                and             [edi + Player.flags], 1111'1110b
.Die:

.Next:
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

proc    Shoot uses edi
        
                or              [controls], 1000'0000b
                and             [controls], 1101'1111b
        
                mov             edi, [currPlayer]
        
                test    [projectile.flags], 0000'0001b
                jnz             .End
                test    [edi + Player.flags], 0000'0001b
                jz              .End
        
                lea             eax, [projectile.x]
                mov             [camAim], eax
        
                or              [controls], 0010'0000b
                or              [projectile.flags], 0000'0001b
                mov             edi, [currPlayer]
                fld             [edi + Player.x]
                fstp    [projectile.x]
                fld             [edi + Player.y]
                fstp    [projectile.y]
                
                fld             [lookAngle]
                fsincos
                fmul    [rocketSpeed]
                fmul    [force]
                fstp    [projectile.ySp]
                fmul    [rocketSpeed]
                fmul    [force]
                test    [edi + Player.flags], 0000'0010b
                jnz             @F
                fchs
@@:
                fstp    [projectile.xSp]
                
                fldz
                fstp    [force]
                
.End:           
                ret
endp

proc    Projectile.Crash
        
                and             [projectile.flags], 1111'1110b
                mov             [StepTime], WAIT_TIME
                and             [controls], 1101'1111b
        
                ret
endp