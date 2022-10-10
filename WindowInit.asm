proc WinInit

        invoke GetProcessHeap
        mov    [hHeap], eax

        invoke GetModuleHandle, 0
        mov [wc.hInstance], eax
        invoke LoadIcon, 0, IDI_APPLICATION
        mov [wc.hIcon], eax
        invoke  LoadCursor, 0, IDC_ARROW
        mov [wc.hCursor], eax
        invoke RegisterClass, wc
        test eax, eax
        jz error

        invoke CreateWindowEx, ebx, _class, _title, WINDOW_STYLE,\
                        ebx, ebx, ebx, ebx, ebx, ebx, [wc.hInstance], ebx
                         
        mov [hMainWindow], eax
        test eax, eax
        jz error

        invoke GetTickCount
        mov    [time], eax
  
        invoke GetDC, [hMainWindow]
        mov [hdc], eax

        invoke ChoosePixelFormat, [hdc], pfd
        invoke SetPixelFormat, [hdc], eax, pfd

        ret

endp