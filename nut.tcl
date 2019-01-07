#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# NUT nutrition software
# Copyright (C) 1996-2018 by Jim Jozwiak.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#
# beginning of easy user changes
#

# DiskDB is the location of your NUTsqlite database
set DiskDB nut.db

# appSize is a factor to create fonts and windows that match screen resolution.
# 0.0 works well on Windows and the Mac, but on Linux,
# appSizes between 0.7 and 1.3 go between small to almost fullscreen
# and look the same at all screen resolutions when you don't have a
# resolution-independent window manager.

 set appSize 0.7
#set appSize 1.3

# Do you need to cd to the right directory before the program starts?
# If so, edit and uncomment the following line:

# cd /home/jim/src/nut

#
# end of easy user changes
#

package require sqlite3
sqlite3 db $DiskDB
db timeout 10000

if {[catch { db eval {select code from z_tcl_code where name = 'Main'} { } }]} {
 package require Tk
 set ::magnify [expr {[winfo vrootheight .] / 711.0}]
 if {[string is double -strict $appSize] && $appSize > 0.0} {
  set ::magnify [expr {$::magnify * $appSize}]
  }
 if {$appSize == 0.0} {set ::magnify 1.0}
 foreach font [font names] {
  font configure $font -size [expr {int($::magnify * [font configure $font -size])}]
  }
 option add *Dialog.msg.wrapLength [expr {400 * $::magnify}]
 option add *Dialog.dtl.wrapLength [expr {400 * $::magnify}]
 tk_messageBox -type ok -title "NUTsqlite" -message "Run the \"updateNUT.tcl\" script before the first invocation of NUT in order to create the SQLite database with its code inside it.  The \"updateNUT.tcl\" script is distributed with \"nut.tcl\" from http://nut.sourceforge.net and you will also have to download the USDA Nutrient Database from the same webpage.  After this, \"updateNUT.tcl\" is not required for anything and can be deleted, and then you run \"nut.tcl\" to start NUTsqlite."
 exit 0
 } else {
 eval $code
 }
