proc GenerateMap

        stdcall Marching.GenerateMap
        stdcall MakeTeams

        ret
endp

proc    MakeTeams       uses ebx edi esi
                
        locals
                temp    dd      ?
                AmPlaces        dd      ?
        endl

        stdcall CountPlacesForPlayers
        mov     [AmPlaces], eax

        mov     esi, [gteams.teams]
        mov     ecx, [gteams.tAmount]
        test    ecx, ecx
        jz              .NoTeams
.TeamsLoop:
        push    ecx

        mov     eax, [gteams.tAmount]
        sub     eax, ecx
        inc     eax
        mov     [esi + Team.id], al
        mov     edi, [esi + Team.players]
        mov     ecx, [esi + Team.plAmount]
        test    ecx, ecx
        jz              .NoPlayers
.TeamLoop:
        push    ecx

                mov             [edi + Player.flags], 1
                
                fldz
                fst             [edi + Player.xSp]
                fstp            [edi + Player.ySp]
                
                mov             eax, [maxHealth]
                mov             [edi + Player.hp], eax
                
                mov             eax, [esi + Team.teamColorR]
                mov             [edi + Player.r], eax
                mov             eax, [esi + Team.teamColorG]
                mov             [edi + Player.g], eax
                mov             eax, [esi + Team.teamColorB]
                mov             [edi + Player.b], eax
                
                stdcall PlacePlayer, edi, [AmPlaces]

        pop     ecx
        add     edi, sizeof.Player
        loop    .TeamLoop

.NoPlayers:
        pop     ecx
        add     esi, sizeof.Team
        dec     ecx
        jnz     .TeamsLoop

                mov             eax, [gteams.currTeam]
                mov             ebx, sizeof.Team
                mul             ebx
                add             eax, [gteams.teams]
                mov             ebx, eax
                mov             esi, ebx



                fld     [esi + Team.teamColorR]
                fstp    [textColor.r]
                fld     [esi + Team.teamColorG]
                fstp    [textColor.g]
                fld     [esi + Team.teamColorB]
                fstp    [textColor.b]
                mov             eax, [esi + Team.currPl]
                mov             ebx, sizeof.Player
                mul             ebx
                add             eax, [esi + Team.players]
                mov             ebx, eax
                mov             esi, ebx
                
                mov             [currPlayer], esi
                
                lea             edi, [esi + Player.x]
                mov             [camAim], edi
                
.NoTeams:

        ret
endp

proc    CountPlacesForPlayers uses edi esi

        locals
                AmPlaces        dd      ?
        endl

        mov     edi, [mGrid.variantMasks]
        mov     ecx, [SquaresAmount]
        mov     esi, [MapWidth]

        mov     [AmPlaces], 0

.CountLoop:
        mov             eax, [SquaresAmount]
        sub             eax, ecx
        xor             edx, edx
        div             esi
        inc             edx
        cmp             edx, 1
        je              .Next
        cmp             edx, [MapWidth]
        je              .Next
        inc             eax
        cmp             eax, 1
        je              .Next
        cmp             eax, [MapHeight]
        je              .Next

        cmp            [edi + VariantMask.variant], 0000'0011b
        jne            .Next
        cmp            [edi + UPPER_MASK + VariantMask.variant], 0
        jne            .Next
        inc            [AmPlaces]

.Next:
        add     edi, sizeof.VariantMask
        loop    .CountLoop

        mov     eax, [AmPlaces]

        ret
endp

proc    PlacePlayer uses ebx edi esi,\
        pl, AmPlaces

        locals
                temp    dd      ?
                place   dd      ?
        endl

        mov     edi, [mGrid.variantMasks]

        mov     ebx, [pl]
        mov     ecx, [SquaresAmount]
        mov     esi, [MapWidth]

        stdcall RandRangei, 1, [AmPlaces]
        mov     [place], eax

.PlLoop:
        mov             eax, ecx
        xor             edx, edx
        div             esi
        inc             edx
        cmp             edx, 1
        je              .Next
        cmp             edx, [MapWidth]
        je              .Next
        inc             eax
        cmp             eax, 1
        je              .Next
        cmp             eax, [MapHeight]
        je              .Next

        cmp            [edi + VariantMask.variant], 0000'0011b
        jne            .Next
        cmp            [edi + UPPER_MASK + VariantMask.variant], 0
        jne            .Next

        dec             [place]
        jnz             .Next

        mov             eax, [SquaresAmount]
        sub             eax, ecx
        xor             edx, edx
        div             esi
        inc             eax
        mov             [temp], eax
        fild            [temp]
        fmul            [SquareSize]
        fstp            [ebx + Player.y]

        mov             [temp], edx
        fild            [temp]
        fmul            [SquareSize]

        stdcall         RandRangef, 0, [SquareSize]
        mov             [temp], eax
        fadd            [temp]

        fstp            [ebx + Player.x]
        jmp             .EndLoop


.Next:
        add     edi, sizeof.VariantMask
        dec     ecx
        jnz     .PlLoop

.EndLoop:
        ret
endp