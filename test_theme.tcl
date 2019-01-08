#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

source src/01_high_contrast.tcl
set ::magnify [expr {[winfo vrootheight .] / 711.0}]

ttk::style theme use HighContrast

pack [ttk::menubutton .tc\
  -text "Customary Meals" \
  -direction right]
pack [ttk::menubutton .normal\
  -text "Customary Meals" \
  -direction right]


.tc configure -style "HighContrast.meal.TButton"
