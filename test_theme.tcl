#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

source src/00_packages.tcl

set appSize 0.7
set ::magnify [expr {[winfo vrootheight .] / 711.0}]
set ::version test

source src/01_high_contrast.tcl
source src/02_linux_gui.tcl

proc tuneinvf {args} {

 uplevel #0 {
  trace add variable gramsvf write GramChangevf
  trace add variable ouncesvf write OunceChangevf
  trace add variable caloriesvf write CalChangevf
  trace add variable Amountvf write AmountChangevf
  trace add variable Msre_Descvf write ServingChange
  }
 }

eval $Make_GUI_Linux

ttk::style theme use HighContrast

