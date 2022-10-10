PFD_FLAGS =       PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER or PFD_DRAW_TO_WINDOW
COLOR_DEPTH =     24
WINDOW_STYLE =    WS_VISIBLE or WS_MAXIMIZE or WS_POPUP

WAIT_TIME               =               2000
STEP_TIME       =       5000
TIME_BAR_SIZE   =       10.0

NUM_OF_CHARACTERS = 128

macro JumpIf value, label
  {
      cmp eax, value
      je label
  }