format PE GUI 4.0
entry Start

include 'win32ax.inc'
include 'api/gdi32.inc'
include 'api/opengl.inc'

include 'glext.inc'
include 'Consts.inc'
include 'Matrix.inc'
include 'MarchingSquares.inc'
include 'Color.inc'
include 'Player.inc'
include 'Transform2D.inc'

section '.text' code readable writeable executable

include 'Player.asm'
include 'MarchingSquares.asm'


include 'File.asm'
include 'Glext.asm'
include 'Draw.asm'
include 'Matrix.asm'
include 'WindowInit.asm'
include 'OpenGLInit.asm'
include 'Random.asm'

include 'Color.asm'
include 'Noise.asm'
include 'Interpolation.asm'
include 'MapGenerator.asm'
include 'Transform2D.asm'

include 'Physics.asm'


proc Start

        locals
                cwf     dw      ?
                tcw     dw      ?
        endl

        fnstcw  [cwf]
        fnstcw  [tcw]
        or      [tcw], 0000'0100'0000'0000b
        and     [tcw], 1111'0111'1111'1111b
        fldcw   [tcw]

        xor ebx, ebx

        stdcall WinInit

        stdcall RandInit

        stdcall Player.InitTeams, 2, 2

        stdcall MarchingInit, mGrid
        stdcall GenerateMap

        stdcall OpenGLInit

        invoke  GetTickCount
        mov     [phTime], eax
msg_loop:


        invoke  GetTickCount
        sub     eax, [phTime]
        add     [phTime], eax

        cmp     eax, [phFPS]
        jb      .SkipPhysics
        
        push    eax

        test    [controls], 0000'0001'0000'0000b
        jnz     .SkipPhysics

        test    [controls], 0010'0000b
        jnz             @F
        sub             [StepTime], eax
        jns             @F
        mov             [StepTime], 0
        test            [controls], 0000'0010'0000'0000b
        jz              @F
        stdcall Player.ChangeCurrPlayer
@@:     
        pop             eax
.phLoop:
        push    eax
        stdcall PhysicsProc, [phFPS]
        pop             eax
        sub             eax, [phFPS]
        jns             .phLoop         
.SkipPhysics:
        
        invoke GetMessage, msg, NULL, 0, 0
        cmp eax, 1
        jb end_loop
        jne msg_loop
        invoke TranslateMessage, msg
        invoke DispatchMessage, msg

        jmp msg_loop

error:
        invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

end_loop:
        fldcw   [cwf]
        invoke ExitProcess, [msg.wParam]

endp

proc RestartGame

        stdcall   GenerateMap
        mov       [controls], 0010'0000b
        mov       [projectile.flags], 0
        mov       [StepTime], STEP_TIME

        ret
endp

proc WindowProc uses ebx,\
      hWnd, uMsg, wParam, lParam

      xor ebx, ebx
      
      mov eax, [uMsg]
      JumpIf WM_KEYUP,  .KeyUp
      JumpIf WM_PAINT,    .Paint
      JumpIf WM_KEYDOWN,  .KeyDown
      JumpIf WM_DESTROY,  .Destroy
      
      invoke DefWindowProc, [hWnd], [uMsg], [wParam], [lParam]
      jmp .Return
      
.Paint:
      stdcall Draw
      jmp .ReturnZero


.KeyUp:
      cmp       [wParam], VK_RETURN
      jne       @F
      and               [controls], 1111'1111'1011'1111b
@@:     
      cmp       [wParam], VK_LEFT
      jne       @F
      and           [controls], 1111'1111'1111'1011b

@@:
      cmp       [wParam], VK_RIGHT
      jne       @F
      and           [controls], 1111'1111'1111'1110b
@@:     
          cmp       [wParam], VK_UP
      jne       @F
      and           [controls], 1111'1111'1111'0111b
@@:     
          cmp       [wParam], VK_DOWN
      jne       @F
      and           [controls], 1111'1111'1111'1101b
@@:     
.SpaceUp:
        cmp       [wParam], VK_SPACE
        jne       @F
        and               [controls], 1111'1111'1110'1111b
@@:     
      jmp       .ReturnZero

.KeyDown:
        test    [projectile.flags], 0000'0001b
        jnz             @F
    and     [controls], 1111'1111'1101'1111b
@@:
      cmp       [wParam], 52h
      jne       @F
      stdcall   RestartGame
@@:
      cmp       [wParam], VK_RETURN
      jne       @F
      mov       ebx, [currPlayer]
      test      [ebx + Player.flags], 1
      jz        @F
      or        [controls], 0100'0000b
      ;stdcall  Shoot
@@:
      cmp       [wParam], VK_LEFT
      jne       @F
      or                [controls], 0000'0100b
@@:
      cmp       [wParam], VK_RIGHT
      jne       @F
      or                [controls], 0000'0001b
@@:
          cmp       [wParam], VK_UP
      jne       @F
      or                [controls], 0000'1000b
@@:
          cmp       [wParam], VK_DOWN
      jne       @F
      or                [controls], 0000'0010b
@@:
      
.SpaceDown:
                cmp             [wParam], VK_SPACE
                jne             @F
                or              [controls], 0001'0000b
@@:

      cmp [wParam], VK_ESCAPE
      jne .ReturnZero
      
.Destroy:
      invoke ExitProcess, ebx
      
.ReturnZero:        
      xor eax, eax
      
.Return:
      ret
endp

section '.data' data readable writeable
        _class TCHAR 'DEMO_OPENGL_2D', 0
        _title TCHAR 'OpenGL_2D', 0
        _error TCHAR 'Startup failed.', 0

        Size dd 30.0

                StepTime                dd              STEP_TIME

                controls                dw              0000'0000'0010'0000b      ;----'--|CanChPl|EndGame|'|NoCharge|ChargeShoot|Wait|Space|'|Arrow_Up|Arrow_left|Arrow_down|Arrow_right|
                

        camPos          Transform2D 0, 0
        camSize         Vector2 1.0, 1.0
        camAim                  dd              ?

        Ground          dd      GROUND
        MapBorders      dd      MAP_BORDERS
        MapWidth        dd      MAP_WIDTH
        MapHeight       dd      MAP_HEIGHT
        SquareSize      dd      SQUARE_SIZE
        SquaresAmount   dd      SQUARES_AMOUNT
        PointsAmount    dd      POINTS_AMOUNT
        PointsInWidth   dd      POINTS_IN_WIDTH
        PointsInHeight  dd      POINTS_IN_HEIGHT

        wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _class
        hMainWindow dd ?
        clientRect RECT

        TimeBar RECT 0, 300, 500, 350

        mGrid   MarchingGrid

        hHeap         dd  ?

        time          dd  ?
        phTime        dd  ?
                phFPS             dd    8

        msg MSG
  
        pfd         PIXELFORMATDESCRIPTOR sizeof.PIXELFORMATDESCRIPTOR, 1, PFD_FLAGS,\
                                            PFD_TYPE_RGBA, COLOR_DEPTH,\
                                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,\
                                            COLOR_DEPTH, 0, 0, PFD_MAIN_PLANE, 0,\
                                            PFD_MAIN_PLANE 
                                            
        hdc dd ?
        
        fontSize        dd              50
        fontName        db              "Lucida Sans TypeWriter"

        drawTitle    db          "Nobody wins XD"
        drawTitleLen db          $ - drawTitle

        winnerTitle     db       "The winner player x"
        winnerTitleLen  db       $ - winnerTitle

        endGameTitle     dd      winnerTitle
        endGameTitleLen  db      19

        turnTitle       db       "The turn of player 1"
        turnTitleLen    db       $ - turnTitle

        textColor       Color



        programBG         GLint           0
        programSea        GLint           0
        programRocket     GLint           0


vertexShaderText:
                                file            "./shaders/vertex.glsl"
                                db              0
vertexShader    dd              vertexShaderText

fragmentShaderText:
                                file            "./shaders/fragment.glsl"
                                db              0
fragmentShader  dd              fragmentShaderText

fragmentShaderSeaText:
                                file            "./shaders/fragmentSea.glsl"
                                db              0
fragmentShaderSea  dd           fragmentShaderSeaText

fragmentShaderRocketText:
                                file            "./shaders/fragmentRocket.glsl"
                                db              0
fragmentShaderRocket  dd        fragmentShaderRocketText
        

include 'PlayersData.asm'

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
          user32, 'USER32.DLL',\
    gdi32, 'GDI32.DLL',\
    opengl32, 'OPENGL32.DLL',\
    glu32, 'GLU32.DLL' 

  include 'api/kernel32.inc'
  include 'api/user32.inc'