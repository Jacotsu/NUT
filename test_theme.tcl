#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

source src/00_packages.tcl


if [file exist NUTR_DEF.txt.loaded] {
	file rename NUTR_DEF.txt.loaded NUTR_DEF.txt
}
file delete {*}[glob nutTest.db*]

set ::Debug 1
set DiskDB nutTest.db
set appSize 0.7
set ::version  "NUT test"

sqlite3 db $DiskDB


source src/01_high_contrast.tcl
source src/02_code.tcl
source src/03_linux_gui.tcl

initDB

ttk::style theme use HighContrast

eval $Main
