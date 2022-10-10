struct Teams
       tAmount  dd      ?
       teams    dd      ?
       currTeam dd      ?
ends

struct Team
       id       db      ?
       teamColorR        dd      ?
       teamColorG        dd      ?
       teamColorB        dd      ?
       plAmount dd      ?
       players  dd      ?
       currPl       dd      ?
ends

struct  Player
        x       dd      ?
        y       dd      ?
        xSp     dd      ?
        ySp     dd      ?
        r       dd      ?
        g       dd      ?
        b       dd      ?
        hp              dd              ?
        flags   db              ? ;0000'00|Direction|isLive|
ends

struct  Projectile
        flags   db      ?       ;0000'000|isActive|
        x       dd      ?
        y       dd      ?
        xSp     dd      ?
        ySp     dd      ?
ends