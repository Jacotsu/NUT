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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

package require sqlite3

sqlite3 db nut.db

db eval {pragma journal_mode = wal}

db eval {create table if not exists z_tcl_code(name text primary key,
	code text)}

db eval {create table if not exists z_tcl_version(serial integer primary key,
  version text, update_cd text)}

db eval {CREATE TABLE if not exists z_tcl_jobqueue (
  jobnum integer primary key,
  jobtype text,
  jobint integer,
  jobreal real,
  jobtext text)
}
db eval {create view if not exists z_tcl_macropct as with vals as (
  select
    fd.NDB_No as NDB_No,
    ENERC_KCAL.Nutr_Val as cals,
    PROT_KCAL.Nutr_Val as pcals,
    CHO_KCAL.Nutr_Val as ccals,
    FAT_KCAL.Nutr_Val as fcals,
    ifnull(ALC.Nutr_Val, 0.0) * 6.93 as acals,
    case when ENERC_KCAL.Nutr_Val <= 0.0 then 0.0 else (
      PROT_KCAL.Nutr_Val + CHO_KCAL.Nutr_Val + FAT_KCAL.Nutr_Val +
				ifnull(ALC.Nutr_Val, 0.0)
    ) / ENERC_KCAL.Nutr_Val end as factor
  from
    food_des fd
    left join nut_data ENERC_KCAL on fd.NDB_No = ENERC_KCAL.NDB_No
    and ENERC_KCAL.Nutr_No = 208
    left join nut_data PROT_KCAL on fd.NDB_No = PROT_KCAL.NDB_No
    and PROT_KCAL.Nutr_No = 3000
    left join nut_data CHO_KCAL on fd.NDB_No = CHO_KCAL.NDB_No
    and CHO_KCAL.Nutr_No = 3002
    left join nut_data FAT_KCAL on fd.NDB_No = FAT_KCAL.NDB_No
    and FAT_KCAL.Nutr_No = 3001
    left join nut_data ALC on fd.NDB_No = ALC.NDB_No
    and ALC.Nutr_No = 221
)
select
  NDB_No,
  case when factor = 0.0 then '0 / 0 / 0' else cast(
    cast(round(100.0 * pcals / cals / factor) as int) as text
  ) || ' / ' || cast(
    cast(round(100.0 * ccals / cals / factor) as int) as text
  ) || ' / ' || cast(
    cast(round(100.0 * fcals / cals / factor) as int) as text
  ) end as macropct
from
  vals; }

db eval {
create view if not exists z_tcl_n6hufa as with format as (
  with n6range as (
    with calc as (
      with calpct as (
        with vals as (
          select
            fd.NDB_No as NDB_No,
            max(
              ifnull(ENERC_KCAL.Nutr_Val, 0.000000001),
              0.000000001
            ) as ENERC_KCAL,
            max(
              ifnull(SHORT6.Nutr_Val, 0.000000001),
              0.000000001
            ) as SHORT6,
            max(
              ifnull(SHORT3.Nutr_Val, 0.000000001),
              0.000000001
            ) as SHORT3,
            max(ifnull(LONG6.Nutr_Val, 0.000000001), 0.000000001) as LONG6,
            max(ifnull(LONG3.Nutr_Val, 0.000000001), 0.000000001) as LONG3,
            max(ifnull(FASAT.Nutr_Val, 0.000000001), 0.000000001) as FASAT,
            max(ifnull(FAMS.Nutr_Val, 0.000000001), 0.000000001) as FAMS,
            max(ifnull(FAPU.Nutr_Val, 0.000000001), 0.000000001) as FAPU,
            FAPU.Nutr_Val as fapugm
          from
            food_des fd
            left join nut_data ENERC_KCAL on fd.NDB_No = ENERC_KCAL.NDB_No
            and ENERC_KCAL.Nutr_No = 208
            left join nut_data SHORT3 on fd.NDB_No = SHORT3.NDB_No
            and SHORT3.Nutr_No = 3005
            left join nut_data LONG3 on fd.NDB_No = LONG3.NDB_No
            and LONG3.Nutr_No = 3006
            left join nut_data SHORT6 on fd.NDB_No = SHORT6.NDB_No
            and SHORT6.Nutr_No = 3003
            left join nut_data LONG6 on fd.NDB_No = LONG6.NDB_No
            and LONG6.Nutr_No = 3004
            left join nut_data FASAT on fd.NDB_No = FASAT.NDB_No
            and FASAT.Nutr_No = 606
            left join nut_data FAMS on fd.NDB_No = FAMS.NDB_No
            and FAMS.Nutr_No = 645
            left join nut_data FAPU on fd.NDB_No = FAPU.NDB_No
            and FAPU.Nutr_No = 646
        )
        select
          NDB_No,
          900.0 * SHORT6 / ENERC_KCAL as SHORT6,
          900.0 * SHORT3 / ENERC_KCAL as SHORT3,
          900.0 * LONG6 / ENERC_KCAL as LONG6,
          900.0 * LONG3 / ENERC_KCAL as LONG3,
          900.0 * (
            FASAT + FAMS + FAPU - SHORT6 - SHORT3 - LONG6 - LONG3
          ) / ENERC_KCAL as OTHER,
          fapugm
        from
          vals
      )
      select
        NDB_No,
        100.0 / (1.0 + (0.7 / LONG6) * (1.0 + (LONG3 / 3.0))) + 100 / (
          1.0 + (0.0441 / SHORT6) * (
            1.0 + (SHORT3 / 0.0555) + (LONG3 / 0.005) + (OTHER / 5.0) +
						(SHORT6 / 0.175)
          )
        ) as n6hufa,
        fapugm
      from
        calpct
    )
    select
      *
    from
      calc
  )
  select
    NDB_No,
    case when n6hufa > 90.0 then 90 when n6hufa < 15.0 then 15 else
			cast(round(n6hufa) as int) end as n6hufa,
    fapugm
  from
    n6range
)
select
  NDB_No,
  case when fapugm is null then null when fapugm = 0.0 then '0 / 0' else
		cast(n6hufa as text) || ' / ' || cast(100 - n6hufa as text) end
		as n6balance
from
  format
}

db eval {
create view if not exists z_tcl_wlsumm as
select
  case when (
    select
      weightn
    from
      z_wslope
  ) = 0 then '0 data points so far...' when (
    select
      weightn
    from
      z_wslope
  ) = 1 then '1 data point so far...' else 'Based on the trend of ' || (
    select
      cast(cast(weightn as int) as text)
    from
      z_wslope
  ) || ' data points so far...' || char(13) || char(10) || char(10) ||
			'Predicted lean mass today = ' || (
    select
      cast(
        round(10.0 * (weightyintercept - fatyintercept)) / 10.0 as text
      )
    from
      z_wslope,
      z_fslope
  ) || char(13) || char(10) || 'Predicted fat mass today  =  ' || (
    select
      cast(round(fatyintercept, 1) as text)
    from
      z_fslope
  ) || char(13) || char(10) || char(10) ||
		'If the predictions are correct, you ' || case when (
    select
      weightslope - fatslope
    from
      z_wslope,
      z_fslope
  ) >= 0.0 then 'gained ' else 'lost ' end || (
    select
      cast(
        abs(
          round((weightslope - fatslope) * span * 1000.0) / 1000.0
        ) as text
      )
    from
      z_wslope,
      z_fslope,
      z_span
  ) || ' lean mass over ' || (
    select
      span
    from
      z_span
  ) || case when (
    select
      span
    from
      z_span
  ) = 1 then ' day' else ' days' end || case when (
    select
      fatslope
    from
      z_fslope
  ) > 0.0 then ' and gained ' else ' and lost ' end || (
    select
      cast(
        abs(round(fatslope * span * 1000.0) / 1000.0) as text
      )
    from
      z_fslope,
      z_span
  ) || ' fat mass.' || char(13) || char(10) end as verbiage

}

set Main {

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

set DiskDB [file nativename $DiskDB]

db eval {
	select
		version as "::version"
	from
		z_tcl_version
	where
		serial = (
			select
				max(serial)
			from
				z_tcl_version
		)
} { }

db eval {select code from z_tcl_code where name = 'get_procs_from_db'} {
 eval $code
 }
get_procs_from_db

package require Tk
package require Thread
set ::GUI_THREAD [thread::id]
set ::SQL_THREAD [thread::create " package require sqlite3 ; sqlite3 db $DiskDB; db timeout 10000 ; set ::GUI_THREAD $::GUI_THREAD ; set ::DiskDB $DiskDB ; [info body get_procs_from_db] ; thread::wait"]

if {$appSize != 0.0} {
 set ::ALTGUI 1
 db eval {select code from z_tcl_code where name = 'Make_GUI_Linux'} { }
 eval $code
 return
 } else {
 set ::ALTGUI 0
 db eval {select code from z_tcl_code where name = 'Make_GUI_WinMac'} { }
 eval $code
 }

#end Main
}

set Make_GUI_WinMac {

wm title . $::version
catch {set im [image create photo -file nuticon.gif]}
catch {wm iconphoto . -default $im}
bind . <Destroy> {
 thread::send -async $::SQL_THREAD {db close}
 db close
 thread::release $::SQL_THREAD
 exit 0
 }

set ::magnify 1.0
set i [font measure TkDefaultFont -displayof . "  TransMonoenoic  "]
set ::column18 [expr {int(round($i / 3.0))}]
set ::column15 [expr {int(round(2.0 * $i / 5.0))}]
option add *Dialog.msg.wrapLength [expr {400 * $::magnify}]
option add *Dialog.dtl.wrapLength [expr {400 * $::magnify}]

trace add variable ::FIRSTMEALam write SetMealRange_am
trace add variable ::LASTMEALam write SetMealRange_am
ttk::style configure nutbutton.TButton
ttk::style configure recipe.TButton
ttk::style configure meal.TButton
ttk::style configure lightmeal.TButton
ttk::style configure meal.TRadiobutton
ttk::style configure ar.TRadiobutton
ttk::style configure po.TButton
ttk::style configure po.red.TButton
ttk::style configure po.TCheckbutton
ttk::style map po.TCheckbutton
ttk::style map po.TButton
ttk::style map po.red.TButton
ttk::style map po.TCheckbutton
ttk::style configure ts.TCheckbutton
ttk::style map ts.TCheckbutton
ttk::style map ts.TCheckbutton
ttk::style map ts.TCheckbutton
ttk::style map meal.TRadiobutton
ttk::style map ar.TRadiobutton
ttk::style configure vf.TButton
ttk::style configure am.TFrame
ttk::style configure rm.TFrame
ttk::style configure vf.TFrame
ttk::style configure po.TFrame
ttk::style configure ts.TFrame
ttk::style configure ar.TFrame
ttk::style configure am.TLabel
ttk::style configure rm.TLabel
ttk::style configure ar.TLabel
ttk::style configure vf.TLabel
ttk::style configure po.TLabel
ttk::style configure po.TMenubutton
ttk::style map po.TMenubutton
ttk::style configure am.TNotebook
ttk::style configure rm.TNotebook
ttk::style configure vf.TNotebook
ttk::style configure ar.TNotebook
ttk::style configure rm.TCombobox
ttk::style configure nut.TCombobox
ttk::style configure vf.TCombobox
ttk::style configure ts.TCombobox
ttk::style map po.TCombobox
ttk::style map rm.TCombobox
ttk::style map nut.TCombobox
ttk::style map ts.TCombobox
ttk::style map rm.TCombobox
ttk::style map nut.TCombobox
ttk::style map ts.TCombobox
ttk::style map rm.TCombobox
ttk::style map nut.TCombobox
ttk::style map ts.TCombobox
ttk::style map vf.TCombobox
ttk::style configure vf.TSpinbox
ttk::style configure am.TSpinbox
ttk::style configure rm.TSpinbox
ttk::style configure lf.Horizontal.TProgressbar
ttk::style configure meal.Horizontal.TProgressbar
ttk::style configure meal.TMenubutton
ttk::style configure ar.TButton
if {$::magnify > 0.0} {
  ttk::style configure nut.Treeview
  -font TkFixedFont
  -rowheight [expr {
    int(round($::magnify * 15.0))}]
  } else {
    ttk::style configure nut.Treeview
    -font TkFixedFont
  }

grid [ttk::notebook .nut]
ttk::frame .nut.am -padding [expr {$::magnify * 2}] -style "am.TFrame"
ttk::frame .nut.rm -padding [expr {$::magnify * 2}] -style "rm.TFrame"
ttk::frame .nut.ar -padding [expr {$::magnify * 2}] -style "ar.TFrame"
ttk::frame .nut.vf -padding [expr {$::magnify * 2}] -style "vf.TFrame"
ttk::frame .nut.po -padding [expr {$::magnify * 2}] -style "po.TFrame"
ttk::frame .nut.ts -padding [expr {$::magnify * 2}] -style "ts.TFrame"
ttk::frame .nut.qn -padding [expr {$::magnify * 2}]
grid [ttk::label .nut.am.herelabel
  -text "Here are \"Daily Value\" average percentages for your previous "
  -style am.TLabel] -row 2 -column 1 -columnspan 9 -sticky e
grid [tk::spinbox .nut.am.mealsb \
  -width 5 \
  -justify right \
  -from 1 -to 999999 \
  -increment 1 \
  -textvariable ::meals_to_analyze_am -buttonbackground "#00FFFF"] \
  -row 2 \
  -column 10 \
  -columnspan 2 \
  -sticky we
grid [ttk::label .nut.am.meallabel -text " meals:" -style am.TLabel] \
  -row 2 \
  -column 12 \
  -columnspan 2 \
  -sticky w
grid [ttk::label .nut.am.rangelabel \
  -textvariable mealrange \
  -style am.TLabel] \
  -row 3 \
  -column 0 \
  -columnspan 15

set ::SetDefanalPreviousValue 0
set ::LastSetDefanal 0

set ::MealfoodSequence 0
set ::MealfoodStatus {}
set ::MealfoodPCF {}
set ::MealfoodPCFfactor {}

set ::lastrmq 0
set ::lastamrm 0
set ::lastac 0
set ::lastbubble 0
set ::BubbleMachineStatus 0

set ::realmealchange 0
grid [scale .nut.rm.scale \
  -background "#FF9428" \
  -width [expr {$::magnify * 11}] \
  -sliderlength [expr {$::magnify * 20}] \
  -length [expr {10 + ($::column15 * 4)}] \
  -showvalue 0 \
  -orient horizontal \
  -variable ::mealoffset \
  -from -100 -to 100 \
  -command mealchange]\
  -row 0\
  -rowspan 2\
  -column 0\
  -columnspan 4\
  -sticky w

grid [ttk::menubutton .nut.rm.theusual \
  -style meal.TMenubutton \
  -text "Customary Meals" \
  -direction right \
  -menu .nut.rm.theusual.m]\
  -row 2 \
  -column 0 \
  -columnspan 4 \
  -sticky nsw \
grid [ttk::button .nut.rm.recipebutton \
  -style ar.TButton \
  -width 16 \
  -text "Save as a Recipe" \
  -state disabled \
  -command RecipeSaveAs] \
  -row 3 \
  -rowspan 2 \
  -column 0 \
  -columnspan 2 \
  -pady [expr {$::magnify * 5.0}] \
  -sticky w
menu .nut.rm.theusual.m \
  -background "#FF9428" \
  -tearoff 0 \
  -postcommand theusualPopulateMenu
.nut.rm.theusual.m add cascade \
  -label "Add Customary Meal to this meal" \
  -menu .nut.rm.theusual.m.add \
  -background "#FF9428"
.nut.rm.theusual.m add cascade \
  -label "Save this meal as a Customary Meal" \
  -menu .nut.rm.theusual.m.save \
  -background "#FF9428"
.nut.rm.theusual.m add cascade \
  -label "Delete a Customary Meal" \
  -menu .nut.rm.theusual.m.delete \
  -background "#FF9428"
menu .nut.rm.theusual.m.add -tearoff 0
menu .nut.rm.theusual.m.save -tearoff 0
menu .nut.rm.theusual.m.delete -tearoff 0

grid [ttk::label .nut.rm.newtheusuallabel \
  -style rm.TLabel \
  -text "Type new Customary Meal name and press Save" \
  -wraplength [expr {4 * $::column15}]] \
  -row 0 \
  -rowspan 2 \
  -column 5 \
  -columnspan 4 \
  -sticky ws
grid [ttk::entry .nut.rm.newtheusualentry \
  -textvariable ::newtheusual] \
  -row 2 \
  -rowspan 2 \
  -column 5 \
  -columnspan 4 \
  -sticky w
grid [ttk::button .nut.rm.newtheusualbutton \
  -text "Save" \
  -command theusualNewName \
  -width 5] \
  -row 2 \
  -rowspan 2 \
  -column 9 \
  -columnspan 2 \
  -sticky w
set ::newtheusual ""
grid remove .nut.rm.newtheusuallabel
grid remove .nut.rm.newtheusualentry
grid remove .nut.rm.newtheusualbutton

grid [ttk::radiobutton .nut.rm.grams \
  -text "Grams" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 1 \
  -style meal.TRadiobutton] \
  -row 0 \
  -column 13 \
  -columnspan 3 \
  -sticky nsw
grid [ttk::radiobutton .nut.rm.ounces \
  -text "Ounces" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 0 \
  -style meal.TRadiobutton] \
  -row 1 \
  -column 13 \
  -columnspan 3 \
  -sticky nsw
grid [ttk::button .nut.rm.analysismeal \
  -text "Analysis" \
  -command SwitchToAnalysis \
  -style lightmeal.TButton] \
  -row 3 \
  -rowspan 2 \
  -column 13 \
  -columnspan 3 \
  -sticky nw
grid remove .nut.rm.grams
grid remove .nut.rm.ounces
grid remove .nut.rm.analysismeal
grid [menubutton .nut.rm.setmpd \
  -background "#FF9428" \
  -text "Delete All Meals and Set Meals Per Day" \
  -relief raised \
  -menu .nut.rm.setmpd.m] \
  -row 0 \
  -column 8 \
  -columnspan 8 \
  -sticky e
grid [ttk::label .nut.rm.fslabel \
  -text "Food Search" \
  -style rm.TLabel] \
  -row 4 \
  -column 4 \
  -columnspan 2 \
  -sticky e
grid [ttk::combobox .nut.rm.fsentry \
  -textvariable ::like_this_rm \
  -style rm.TCombobox] \
  -padx [expr {$::magnify * 5}] \
  -row 4 \
  -column 6 \
  -columnspan 7 \
  -sticky we
grid [ttk::progressbar .nut.rm.bubblemachine \
  -style meal.Horizontal.TProgressbar \
  -orient horizontal \
  -mode indeterminate] \
  -row 4 \
  -column 6 \
  -columnspan 7 \
  -sticky nswe
grid remove .nut.rm.bubblemachine

grid [ttk::button .nut.rm.searchcancel \
  -text "Cancel" \
  -width 6 \
  -command CancelSearch \
  -style vf.TButton] \
  -row 3 \
  -rowspan 2 \
  -column 13 \
  -columnspan 3 \
  -sticky sw
grid remove .nut.rm.searchcancel
grid [ttk::frame .nut.rm.frlistbox \
  -style rm.TFrame \
  -width [expr {15 * $::column15}] ] \
  -row 5 \
  -rowspan 16 \
  -column 0 \
  -columnspan 15 \
  -sticky nswe
grid [tk::listbox .nut.rm.frlistbox.listbox \
  -listvariable foodsrm \
  -yscrollcommand ".nut.rm.frlistbox.scrollv set" \
  -xscrollcommand ".nut.rm.frlistbox.scrollh set" \
  -height 22 \
  -width 85 \
  -background "#FF7F00" \
  -setgrid 1] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.rm.frlistbox.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.rm.frlistbox.listbox yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.rm.frlistbox.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.rm.frlistbox.listbox xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe
grid rowconfig .nut.rm.frlistbox 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.rm.frlistbox 0 \
  -weight 1 \
  -minsize 0
grid propagate .nut.rm.frlistbox 0

bind .nut.rm.frlistbox.listbox <<ListboxSelect>> FoodChoicerm
trace add variable ::like_this_rm write FindFoodrm
bind .nut.rm.fsentry <FocusIn> FoodSearchrm
grid remove .nut.rm.frlistbox
grid [ttk::label .nut.vf.label \
  -textvariable Long_Desc \
  -style vf.TLabel \
  -wraplength [expr {$::magnify * 250}]] \
  -row 0 \
  -column 3 \
  -columnspan 9 \
  -rowspan 3

set gramsvf 0
set ouncesvf 0.0
set caloriesvf 0
set Amountvf 0.0
set ounce2gram 0.0
set cal2gram 0
set Amount2gram 0.0

grid [tk::spinbox .nut.vf.sb0 \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable gramsvf \
  -buttonbackground "#00FF00"] \
  -row 0 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [tk::spinbox .nut.vf.sb1 \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable ouncesvf \
  -buttonbackground "#00FF00"] \
  -row 1 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [tk::spinbox .nut.vf.sb2 \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable caloriesvf \
  -buttonbackground "#00FF00"] \
  -row 2 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [tk::spinbox .nut.vf.sb3 \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable Amountvf \
  -buttonbackground "#00FF00"] \
  -row 3 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::label .nut.vf.sbl0 \
  -text "gm." \
  -style vf.TLabel] \
  -row 0 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w
grid [ttk::label .nut.vf.sbl1 \
  -text "oz." \
  -style vf.TLabel] \
  -row 1 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w
grid [ttk::label .nut.vf.sbl2 \
  -text "cal." \
  -style vf.TLabel] \
  -row 2 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w
grid [menubutton .nut.vf.refusemb \
  -background "#00FF00" \
  -text "Refuse"  \
  -direction below \
  -relief raised \
  -menu .nut.vf.refusemb.m ] \
  -row 4 \
  -column 0 \
  -columnspan 2 \
  -sticky e
menu .nut.vf.refusemb.m \
  -tearoff 0 \
  -background "#00FF00"
.nut.vf.refusemb.m add command \
  -label "No refuse description provided"
grid [ttk::label .nut.vf.refusevalue \
  -textvariable Refusevf \
  -style vf.TLabel] \
  -row 4 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -columnspan 2 \
  -sticky w
grid [ttk::button .nut.vf.meal \
  -text "Add to Meal" \
  -state disabled \
  -command vf2rm \
  -style meal.TButton] \
  -row 1 \
  -rowspan 2 \
  -column 12 \
  -columnspan 3 \
  -sticky nw
grid [ttk::label .nut.vf.fslabel \
  -text "Food Search" \
  -style vf.TLabel] \
  -row 4 \
  -column 4 \
  -columnspan 2 \
  -sticky e
grid [ttk::combobox .nut.vf.cb \
  -textvariable Msre_Descvf \
  -state readonly \
  -style vf.TCombobox] \
  -padx [expr {$::magnify * 5}] \
  -row 3 \
  -column 2 \
  -columnspan 11 \
  -sticky we
grid [ttk::combobox .nut.vf.fsentry \
  -textvariable like_this_vf \
  -style vf.TCombobox] \
  -padx [expr {$::magnify * 5}] \
  -row 4 \
  -column 6 \
  -columnspan 7 \
  -sticky we

grid [ttk::label .nut.ar.name \
  -text "Recipe Name" \
  -style ar.TLabel] \
  -row 0 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::entry .nut.ar.name_entry \
  -textvariable ::RecipeName ] \
  -row 0 \
  -column 2 \
  -columnspan 11 \
  -padx [expr {$::magnify * 5}] \
  -sticky we

grid [ttk::label .nut.ar.numserv \
  -text "Number of servings recipe makes" \
  -style ar.TLabel] \
  -row 1 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::entry .nut.ar.numserv_entry \
  -textvariable ::RecipeServNum \
  -width 7] \
  -row 1 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w

grid [ttk::label .nut.ar.servunit \
  -text "Serving Unit (cup, piece, tbsp, etc.)" \
  -style ar.TLabel] \
  -row 2 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::entry .nut.ar.servunit_entry \
  -textvariable ::RecipeServUnit] \
  -row 2 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w

grid [ttk::label .nut.ar.servnum \
  -text "Number of units in one serving" \
  -style ar.TLabel] \
  -row 3 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::entry .nut.ar.servnum_entry \
  -textvariable ::RecipeServUnitNum \
  -width 7] \
  -row 3 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w

grid [ttk::label .nut.ar.weight \
  -text "Weight of one serving (if known)" \
  -style ar.TLabel] \
  -row 4 \
  -column 0 \
  -columnspan 2 \
  -sticky e
grid [ttk::entry .nut.ar.weight_entry \
  -textvariable ::RecipeServWeight \
  -width 7] \
  -row 4 \
  -column 2 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -sticky w

grid [ttk::button .nut.ar.save \
  -text "Save" \
  -command RecipeDone \
  -style vf.TButton] \
  -row 3 \
  -column 13 \
  -columnspan 3 \
  -sticky e
grid [ttk::button .nut.ar.cancel \
  -text "Cancel" \
  -command RecipeCancel \
  -style ar.TButton] \
  -row 4 \
  -column 13 \
  -columnspan 3 \
  -sticky e

grid [ttk::radiobutton .nut.ar.grams \
  -text "Grams" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 1 \
  -style ar.TRadiobutton] \
  -row 0 \
  -column 13 \
  -columnspan 3 \
  -sticky nsw
grid [ttk::radiobutton .nut.ar.ounces \
  -text "Ounces" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 0 \
  -style ar.TRadiobutton] \
  -row 1 \
  -column 13 \
  -columnspan 3 \
  -sticky nsw

panedwindow .nut.po.pane \
  -orient horizontal \
  -showhandle 0 \
  -handlesize [expr {round($::magnify * 10.0)}] \
  -background "#5454FF" \
  -relief solid
ttk::frame .nut.po.pane.optframe \
  -style po.TFrame
ttk::frame .nut.po.pane.wlogframe \
  -style po.TFrame
.nut.po.pane add .nut.po.pane.optframe .nut.po.pane.wlogframe
grid .nut.po.pane \
  -in .nut.po \
  -sticky nsew \
  -row 0 \
  -column 0

grid rowconfigure .nut.po.pane.wlogframe all \
  -uniform 1
grid columnconfigure .nut.po.pane.wlogframe all \
  -uniform 1

grid [ttk::label .nut.po.pane.wlogframe.weight_l \
  -text "Weight" \
  -style "po.TLabel" \
  -justify right] \
  -row 0 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.wlogframe.weight_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::weightyintercept \
  -disabledforeground "#000000" ] \
  -row 0 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::label .nut.po.pane.wlogframe.bf_l \
  -text "Body Fat %" \
  -style "po.TLabel" \
  -justify right] \
  -row 1 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.wlogframe.bf_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::currentbfp \
  -disabledforeground "#000000" ] \
  -row 1 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::button .nut.po.pane.wlogframe.accept \
  -text "Accept New\nMeasurements" \
  -command AcceptNewMeasurements] \
  -row 2 \
  -rowspan 2 \
  -column 0 \
  -columnspan 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [ttk::button .nut.po.pane.wlogframe.clear \
  -text "Clear Weight Log" \
  -command ClearWeightLog] \
  -row 10 \
  -column 0 \
  -columnspan 3 \
  -padx [expr {$::magnify * 5}] \
  -sticky e

grid [ttk::label .nut.po.pane.wlogframe.summary \
  -wraplength [expr {$::magnify * 150}] \
  -textvariable ::wlogsummary \
  -justify right \
  -style po.TLabel] \
  -row 4 \
  -rowspan 6 \
  -column 0 \
  -columnspan 3 \
  -padx [expr {$::magnify * 5}] \
  -sticky e

grid rowconfigure .nut.po.pane.optframe all \
  -uniform 1
grid columnconfigure .nut.po.pane.optframe all \
  -uniform 1

grid [ttk::label .nut.po.pane.optframe.cal_l \
  -text "Calories kc" \
  -style "po.TLabel" \
  -justify right] \
  -row 0 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.cal_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::ENERC_KCALopt \
  -disabledforeground "#000000" ] \
  -row 0 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
set ::ENERC_KCALpo 0
grid [ttk::checkbutton .nut.po.pane.optframe.cal_cb1 \
  -text "Adjust to my meals" \
  -variable ::ENERC_KCALpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions ENERC_KCAL]] \
  -row 0 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.cal_cb2 \
  -text "Auto-Set" \
  -variable ::ENERC_KCALpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions ENERC_KCAL]] \
  -row 0 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.fat_l \
  -text "Total Fat g" \
  -style "po.TLabel" \
  -justify right] \
  -row 1 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.fat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FATopt \
  -disabledforeground "#000000" ] \
  -row 1 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.fat_cb1 \
  -text "Adjust to my meals" \
  -variable ::FATpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAT]] \
  -row 1 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.fat_cb2 \
  -text "DV 36% of Calories" \
  -variable ::FATpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAT]] \
  -row 1 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.prot_l \
  -text "Protein g" \
  -style "po.TLabel" \
  -justify right] \
  -row 2 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.prot_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::PROCNTopt \
  -disabledforeground "#000000" ] \
  -row 2 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.prot_cb1 \
  -text "Adjust to my meals" \
  -variable ::PROCNTpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions PROCNT]] \
  -row 2 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.prot_cb2 \
  -text "DV 10% of Calories" \
  -variable ::PROCNTpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions PROCNT]] \
  -row 2 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.nfc_l \
  -text "Non-Fiber Carb g" \
  -style "po.TLabel" \
  -justify right] \
  -row 3 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.nfc_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::CHO_NONFIBopt \
  -disabledforeground "#000000" ] \
  -row 3 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.nfc_cb1 \
  -text "Adjust to my meals" \
  -variable ::CHO_NONFIBpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions CHO_NONFIB]] \
  -row 3 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.nfc_cb2 \
  -text "Balance of Calories" \
  -variable ::CHO_NONFIBpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions CHO_NONFIB]] \
  -row 3 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.fiber_l \
  -text "Fiber g" \
  -style "po.TLabel" \
  -justify right] \
  -row 4 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.fiber_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FIBTGopt \
  -disabledforeground "#000000" ] \
  -row 4 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.fiber_cb1 \
  -text "Adjust to my meals" \
  -variable ::FIBTGpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FIBTG]] \
  -row 4 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.fiber_cb2 \
  -text "Daily Value Default" \
  -variable ::FIBTGpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FIBTG]] \
  -row 4 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.sat_l \
  -text "Saturated Fat g" \
  -style "po.TLabel" \
  -justify right] \
  -row 5 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.sat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FASATopt \
  -disabledforeground "#000000" ] \
  -row 5 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.sat_cb1 \
  -text "Adjust to my meals" \
  -variable ::FASATpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FASAT]] \
  -row 5 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.sat_cb2 \
  -text "DV 10% of Calories" \
  -variable ::FASATpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FASAT]] \
  -row 5 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.efa_l \
  -text "Essential Fatty Acids g" \
  -style "po.TLabel" \
  -justify right] \
  -row 6 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.efa_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FAPUopt \
  -disabledforeground "#000000" ] \
  -row 6 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.efa_cb1 \
  -text "Adjust to my meals" \
  -variable ::FAPUpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAPU]] \
  -row 6 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.efa_cb2 \
  -text "4% of Calories" \
  -variable ::FAPUpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAPU]] \
  -row 6 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w

grid [ttk::label .nut.po.pane.optframe.fish_l \
  -text "Omega-6/3 Balance" \
  -style "po.TLabel" \
  -justify right] \
  -row 7 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
set ::balvals {}
for {set i 15} {$i < 91} {incr i} {
 lappend ::balvals "$i / [expr {100 - $i}]"
 }
grid [ttk::combobox .nut.po.pane.optframe.fish_s \
  -width 7 \
  -justify right \
  -textvariable ::FAPU1po \
  -values $::balvals \
  -state readonly \
  -style po.TCombobox] \
  -row 7 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
trace add variable ::FAPU1po write [list ChangePersonalOptions FAPU1]
grid [ttk::menubutton .nut.po.pane.optframe.dv_mb \
  -style po.TMenubutton \
  -text "Daily Values for Individual Micronutrients" \
  -direction right \
  -menu .nut.po.pane.optframe.dv_mb.m] \
  -row 8 \
  -column 0 \
  -columnspan 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
menu .nut.po.pane.optframe.dv_mb.m \
  -tearoff 0foreach nut {{Vitamin A} Thiamin Riboflavin Niacin {Panto. Acid} {Vitamin B6} Folate {Vitamin B12} Choline {Vitamin C} {Vitamin D} {Vitamin E} {Vitamin K1} Calcium Copper Iron Magnesium Manganese Phosphorus Potassium Selenium Sodium Zinc Glycine Retinol} {
 .nut.po.pane.optframe.dv_mb.m add command \
  -label $nut \
  -command [list changedv_vitmin $nut]
 }

grid [ttk::label .nut.po.pane.optframe.vite_l \
  -text "vite" \
  -style "po.TLabel" \
  -justify right] \
  -row 9 \
  -column 0 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky e
grid [tk::spinbox .nut.po.pane.optframe.vite_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::NULLopt \
  -disabledforeground "#000000" ] \
  -row 9 \
  -column 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}]
grid [ttk::checkbutton .nut.po.pane.optframe.vite_cb1 \
  -text "Adjust to my meals" \
  -variable ::vitminpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton] \
  -row 9 \
  -column 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid [ttk::checkbutton .nut.po.pane.optframe.vite_cb2 \
  -text "Daily Value Default" \
  -variable ::vitminpo \
  -onvalue 2 \
  -style po.TCheckbutton] \
  -row 9 \
  -column 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 10}] \
  -sticky w
grid remove .nut.po.pane.optframe.vite_l
grid remove .nut.po.pane.optframe.vite_s
grid remove .nut.po.pane.optframe.vite_cb1
grid remove .nut.po.pane.optframe.vite_cb2

ttk::frame .nut.ts.frranking \
  -style vf.TFrame
grid propagate .nut.ts.frranking 0

grid [ttk::combobox .nut.ts.rankchoice \
  -state readonly \
  -justify center \
  -style ts.TCombobox] \
  -row 0 \
  -column 0 \
  -sticky we
grid [ttk::combobox .nut.ts.fdgroupchoice \
  -textvariable ::fdgroupchoice \
  -state readonly \
  -justify center \
  -style ts.TCombobox] \
  -row 0 \
  -column 1 \
  -sticky we
grid .nut.ts.frranking \
  -in .nut.ts \
  -sticky nsew \
  -row 1 \
  -column 0 \
  -columnspan 2
pack .nut.ts \
  -fill both \
  -expand 1
grid column .nut.ts 0 \
  -weight 1
grid column .nut.ts 1 \
  -weight 1
grid row .nut.ts 1 \
  -weight 4
grid [labelframe .nut.ts.frgraph \
  -background "#FFFF00"] \
  -row 2 \
  -column 0 \
  -columnspan 2 \
  -sticky nsew
canvas .nut.ts.frgraph.canvas \
  -relief flat \
  -background "#FFFF00"grid .nut.ts.frgraph.canvas \
  -in .nut.ts.frgraph \
  -sticky nsew
grid row .nut.ts 2 \
  -weight 2
grid propagate .nut.ts.frgraph 0

grid [ttk::treeview .nut.ts.frranking.ranking \
  -yscrollcommand [list .nut.ts.frranking.vsb set] \
  -style nut.Treeview \
  -columns {food field1 field2} \
  -show headings] \
  -row 0 \
  -column 0 \
  -sticky nsew
.nut.ts.frranking.ranking column 0 \
  -minwidth [expr {10 * $::column15}]
.nut.ts.frranking.ranking column 1 \
  -minwidth [expr {2 * $::column15}]
.nut.ts.frranking.ranking column 2 \
  -minwidth [expr {3 * $::column15}]
grid [scrollbar .nut.ts.frranking.vsb \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command [list .nut.ts.frranking.ranking yview]] \
  -row 0 \
  -column 1 \
  -sticky nsew

grid columnconfigure .nut.ts.frranking 0 \
  -weight 1 \
  -minsize 0
grid rowconfigure .nut.ts.frranking 0 \
  -weight 1 \
  -minsize 0

bind .nut.ts.frranking.ranking <<TreeviewSelect>> rank2vf

tuneinvf

trace add variable like_this_vf write FindFoodvf
bind .nut.vf.fsentry <FocusIn> FoodSearchvf
pack [ttk::label .nut.qn.label \
  -text "\nNUT has ended."]
.nut add .nut.am \
  -text "Analyze Meals" \
  -sticky nsew
.nut add .nut.rm \
  -text "Record Meals & Recipes" \
  -sticky nsew
.nut add .nut.ar \
  -text "Record Meals & Recipes" \
  -sticky nsew
.nut add .nut.vf \
  -text "View Foods" \
  -sticky nsew
.nut add .nut.po \
  -text "Personal Options"
.nut add .nut.ts \
  -text "The Story"
#.nut hide .nut.rm
.nut hide .nut.ar
.nut hide .nut.ts
.nut add .nut.qn \
  -text "Quit NUT"
bind .nut <<NotebookTabChanged>> NutTabChange
grid [ttk::frame .nut.vf.frlistbox \
  -style vf.TFrame \
  -width [expr {15 * $::column15}] ] \
  -row 5 \
  -rowspan 16 \
  -column 0 \
  -columnspan 15 \
  -sticky nsew
grid propagate .nut.vf.frlistbox 0
grid [tk::listbox .nut.vf.frlistbox.listbox \
  -width 85 \
  -height 22 \
  -listvariable foodsvf \
  -yscrollcommand ".nut.vf.frlistbox.scrollv set" \
  -xscrollcommand ".nut.vf.frlistbox.scrollh set" \
  -background "#00FF00" \
  -setgrid 1] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.vf.frlistbox.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.vf.frlistbox.listbox yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.vf.frlistbox.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.vf.frlistbox.listbox xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe
grid rowconfig .nut.vf.frlistbox 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.vf.frlistbox 0 \
  -weight 1 \
  -minsize 0
bind .nut.vf.frlistbox.listbox <<ListboxSelect>> FoodChoicevf
grid remove .nut.vf.frlistbox

grid [ttk::frame .nut.rm.frmenu \
  -style rm.TFrame \
  -width [expr {15 * $::column15}] ] \
  -row 5 \
  -rowspan 16 \
  -column 0 \
  -columnspan 15
grid propagate .nut.rm.frmenu 0
grid [tk::text .nut.rm.frmenu.menu \
  -yscrollcommand ".nut.rm.frmenu.scrollv set" \
  -state disabled \
  -wrap none \
  -height 32 \
  -width 99 \
  -inactiveselectbackground {} \
  -background "#FF7F00" \
  -cursor [. cget \
  -cursor] ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.rm.frmenu.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.rm.frmenu.menu yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid rowconfig .nut.rm.frmenu 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.rm.frmenu 0 \
  -weight 1 \
  -minsize 0

set ::PCFchoices {{No Auto Portion Control} {Protein} {Non-Fiber Carb} {Total Fat} {Vitamin A} {Thiamin} {Riboflavin} {Niacin} {Panto. Acid} {Vitamin B6} {Folate} {Vitamin B12} {Choline} {Vitamin C} {Vitamin D} {Vitamin E} {Vitamin K1} {Calcium} {Copper} {Iron} {Magnesium} {Manganese} {Phosphorus} {Potassium} {Selenium} {Sodium} {Zinc} {Glycine} {Retinol} {Fiber}}
set ::rmMenu .nut.rm.frmenu
grid remove .nut.rm.frmenu

foreach x {am rm vf ar} {
 grid [ttk::notebook .nut.${x}.nbw \
  -style ${x}.TNotebook] \
  -row 5 \
  -rowspan 16 \
  -column 0 \
  -columnspan 15 \
  -sticky s
 for {set i 0} {$i < 16} {incr i} {
  grid columnconfigure .nut.${x} $i \
  -uniform 1
  }
 for {set i 0} {$i < 5} {incr i} {
  grid rowconfigure .nut.${x} $i \
  -uniform 1 \
  -weight 1
  }
 for {set i 5} {$i < 21} {incr i} {
  grid rowconfigure .nut.${x} $i \
  -uniform 1
  }
 ttk::frame .nut.${x}.nbw.screen0 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen1 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen2 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen3 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen4 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen5 \
  -style ${x}.TFrame
 .nut.${x}.nbw add .nut.${x}.nbw.screen0 \
  -text "Daily Value %"
 .nut.${x}.nbw add .nut.${x}.nbw.screen1 \
  -text "DV Amounts"
 .nut.${x}.nbw add .nut.${x}.nbw.screen2 \
  -text "Carbs & Amino Acids"
 .nut.${x}.nbw add .nut.${x}.nbw.screen3 \
  -text "Miscellaneous"
 .nut.${x}.nbw add .nut.${x}.nbw.screen4 \
  -text "Sat & Mono FA"
 .nut.${x}.nbw add .nut.${x}.nbw.screen5 \
  -text "Poly & Trans FA"
 set screen 0
 set row 0
 set bcol 0
 set valcol 3
 set ucol 5
 foreach nut {ENERC_KCAL} {
  if {$x != "ar"} {grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::caloriebutton \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we} else {grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Calories (2000)" \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we}
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 foreach nut {ENERC_KCAL1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 3
  incr row
  }
 set row 4
 foreach nut {FAT FASAT FAMS FAPU OMEGA6 LA AA OMEGA3 ALA EPA DHA CHOLE} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 0
 set bcol 6
 set valcol 9
 set ucol 11
 foreach nut {CHOCDF FIBTG} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 3
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC VITD_BOTH VITE VITK1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 0
 set bcol 12
 set valcol 15
 set ucol 17
 foreach nut {PROCNT} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 foreach nut {CHO_NONFIB} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
   if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}1 \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}1 \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
   grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w

#uncomment these two lines and comment out the previous two if user insists he
#must see CHO_NONFIB percentage of DV instead of grams

#   if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}1 \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
#   grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 4
 foreach nut {CA CU FE MG MN P K SE NA ZN} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 15
 foreach nut {FAPU1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Omega-6/3 Bal." \
  -command "NewStory FAPU $x" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 3
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 set screen 1
 set row 0
 set bcol 0
 set valcol 3
 set ucol 5
 foreach nut {ENERC_KCAL} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 foreach nut {ENERC_KCAL1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 3
  incr row
  }
 set row 4
 foreach nut {FAT FASAT FAMS FAPU OMEGA6 LA AA OMEGA3 ALA EPA DHA CHOLE} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 0
 set bcol 6
 set valcol 9
 set ucol 11
 foreach nut {CHOCDF FIBTG} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 3
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC VITD_BOTH VITE VITK1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 0
 set bcol 12
 set valcol 15
 set ucol 17
 foreach nut {PROCNT CHO_NONFIB} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 4
 foreach nut {CA CU FE MG MN P K SE NA ZN} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 15
 foreach nut {FAPU1} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Omega-6/3 Bal." \
  -command "NewStory FAPU $x" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 3
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 set screen 2
 set row 2
 set bcol 0
 set valcol 3
 set ucol 5
 foreach nut {CHOCDF FIBTG STARCH SUGAR FRUS GALS GLUS LACS MALS SUCS} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 2
 set bcol 6
 set valcol 9
 set ucol 11
 foreach nut {PROCNT ADPROT ALA_G ARG_G ASP_G CYS_G GLU_G GLY_G HISTN_G HYP ILE_G} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 2
 set bcol 12
 set valcol 15
 set ucol 17
 foreach nut {LEU_G LYS_G MET_G PHE_G PRO_G SER_G THR_G TRP_G TYR_G VAL_G} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 set screen 3
 set row 1
 set bcol 0
 set valcol 3
 set ucol 5
 foreach nut {ENERC_KJ ASH WATER CAFFN THEBRN ALC FLD BETN CHOLN FOLAC FOLFD FOLDFE RETOL} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 1
 set bcol 6
 set valcol 9
 set ucol 11
 foreach nut {VITA_IU ERGCAL CHOCAL VITD VITB12_ADDED VITE_ADDED VITK1D MK4 TOCPHA TOCPHB TOCPHG TOCPHD TOCTRA} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 1
 set bcol 12
 set valcol 15
 set ucol 17
 foreach nut {TOCTRB TOCTRG TOCTRD CARTA CARTB CRYPX LUT_ZEA LYCPN CHOLE PHYSTR SITSTR CAMD5 STID7} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 set screen 4
 set row 0
 set bcol 3
 set valcol 6
 set ucol 8
 foreach nut {FASAT F4D0 F6D0 F8D0 F10D0 F12D0 F13D0 F14D0 F15D0 F16D0 F17D0 F18D0 F20D0 F22D0 F24D0} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 1
 set bcol 9
 set valcol 12
 set ucol 14
 foreach nut {FAMS F14D1 F15D1 F16D1 F16D1C F17D1 F18D1 F18D1C F20D1 F22D1 F22D1C F24D1C} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 set screen 5
 set row 3
 set bcol 0
 set valcol 3
 set ucol 5
 foreach nut {FAPU F18D2 F18D2CN6 F18D3 F18D3CN3 F18D3CN6 F18D4 F20D2CN6} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 2
 set bcol 6
 set valcol 9
 set ucol 11
 foreach nut {F20D3 F20D3N3 F20D3N6 F20D4 F20D4N6 F20D5 F21D5 F22D4 F22D5 F22D6} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 set row 1
 set bcol 12
 set valcol 15
 set ucol 17
 foreach nut {FATRN FATRNM F16D1T F18D1T F18D1TN7 F22D1T FATRNP F18D2I F18D2T F18D2TT F18D2CLA F18D3I} {
  grid [ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutbutton.TButton"] \
  -row $row \
  -column $bcol \
  -columnspan 3 \
  -sticky we
  if {$x == "ar"} {grid [ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right \
  -width 8] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e} else {grid [ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -style ${x}.TLabel] \
  -row $row \
  -column $valcol \
  -columnspan 2 \
  -sticky e}
  grid [ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style ${x}.TLabel] \
  -row $row \
  -column $ucol \
  -sticky w
  incr row
  }
 for {set i 0} {$i < 18} {incr i} {
  grid columnconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1 \
  -minsize $::column18
  }
 for {set i 0} {$i < 15} {incr i} {
  grid rowconfigure .nut.${x}.nbw.screen${screen} $i \
  -uniform 1
  }
 }
bind .nut.am.nbw <<NotebookTabChanged>> NBWamTabChange
bind .nut.rm.nbw <<NotebookTabChanged>> NBWrmTabChange
bind .nut.vf.nbw <<NotebookTabChanged>> NBWvfTabChange
bind .nut.ar.nbw <<NotebookTabChanged>> NBWarTabChange

if {[file exists "NUTR_DEF.txt"]} {

 toplevel .loadframe
 wm title .loadframe $::version
 wm withdraw .
 grid [ttk::label .loadframe.mainlabel \
  -text "Updating USDA Nutrient Database"] \
  -column 0 \
  -row 0 \
  -columnspan 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}]
 set ::pbprog1counter 0

 for {set i 1} {$i < 9} {incr i} {
  set pbar($i) 0.0
  grid [ttk::progressbar .loadframe.pbar${i} \
  -style lf.Horizontal.TProgressbar \
  -variable pbar($i) \
  -orient horizontal \
  -length [expr {$::magnify * 100}] \
  -mode determinate] \
  -column 0 \
  -row $i \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}]
  }
 grid [ttk::label .loadframe.label1 \
  -text "Load Nutrient Definitions"] \
  -column 1 \
  -row 1 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label2 \
  -text "Load Food Groups"] \
  -column 1 \
  -row 2 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label3 \
  -text "Load Foods"] \
  -column 1 \
  -row 3 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label4 \
  -text "Load Serving Sizes"] \
  -column 1 \
  -row 4 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label5 \
  -text "Load Nutrient Values"] \
  -column 1 \
  -row 5 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label6 \
  -text "Compute Derived Nutrient Values"] \
  -column 1 \
  -row 6 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label7 \
  -text "Load NUT Logic"] \
  -column 1 \
  -row 7 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
 grid [ttk::label .loadframe.label8 \
  -text "Load Legacy Database if it exists"] \
  -column 1 \
  -row 8 \
  -padx [expr {$::magnify * 5}] \
  -pady [expr {$::magnify * 5}] \
  -sticky w
db eval {select code from z_tcl_code where name = 'ComputeDerivedValues'} { }
eval $code
db eval {select code from z_tcl_code where name = 'InitialLoad'} { }
eval $code
 } else {
 set tablename [db eval {select name from sqlite_master where type='table' and name = "nutr_def"}]
 if { $tablename == "" } {
  set ::meals_to_analyze_am 0
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "NUT requires the USDA Nutrient Database to be present initially in order to be loaded into SQLite.  Download it in the full ascii version from \"https://data.nal.usda.gov/dataset/composition-foods-raw-processed-prepared-usda-national-nutrient-database-standard-referen-11\" or from \"http://nut.sourceforge.net\" and unzip it in this directory, [pwd]." \
  -detail "Follow this same procedure later when you want to upgrade the USDA database yet retain your personal data.  After USDA files have been loaded into NUT they can be deleted.\n\nIf you really do want to reload a USDA database that you have already loaded, rename the file \"NUTR_DEF.txt.loaded\" to \"NUTR_DEF.txt\"."
  rename unknown ""
  rename _original_unknown unknown
  destroy .
  } else {
  db eval {select code from z_tcl_code where name = 'Start_NUT'} { }
  eval $code
  }
 }

#end Make_GUI_WinMac
}

set Make_GUI_Linux {

set need_load 0
if {[file exists "NUTR_DEF.txt"]} {set need_load 1}

if {$need_load} {
 if {![catch {package require Thread}]} {
  set ::THREADS 1
  set ::GUI_THREAD [thread::id]
  set ::SQL_THREAD [thread::create " package require sqlite3 ; sqlite3 db $DiskDB; db timeout 10000 ; [info body get_procs_from_db] ; set ::THREADS 1 ; set ::GUI_THREAD $::GUI_THREAD ; set ::DiskDB $DiskDB ; thread::wait"]
  }
 }

if {$appSize > 1.3} {set appSize 1.3}
if {$appSize < 0.7} {set appSize 0.7}
set gr 1.6180339887
if {[winfo vrootheight .] * $gr > [winfo vrootwidth .]} {
 set vroothGR [expr {int([winfo vrootwidth .] / $gr)}]
 set vrootwGR [winfo vrootwidth .]
 } else {
 set vroothGR [winfo vrootheight .]
 set vrootwGR [expr {int([winfo vrootheight .] * $gr)}]
 }
set ::magnify [expr {$appSize / 1.3 * $vroothGR / 500.0}]
foreach font [font names] {
 font configure $font \
  -size [expr {int($::magnify * [font configure $font \
  -size])}]
 }
option add *Dialog.msg.wrapLength [expr {400 * $::magnify}]
option add *Dialog.dtl.wrapLength [expr {400 * $::magnify}]

wm geometry . [expr {int($appSize / 1.3 * $vrootwGR)}]x[expr {int($appSize / 1.3 * $vroothGR)}]
wm title . $::version
catch {set im [image create photo \
  -file nuticon.gif]}
catch {wm iconphoto . \
  -default $im}
bind . <Destroy> { thread::send \
  -async $::SQL_THREAD {db close}
 db close
 thread::release $::SQL_THREAD
 exit 0
 }

ttk::style theme use default
ttk::style configure lf.Horizontal.TProgressbar \
  -background "#006400"
if {$::magnify > 0.0} {ttk::style configure nut.Treeview \
  -font TkFixedFont \
  -background "#00FF00" \
  -rowheight [expr {int(round($::magnify * 15.0))}]} else {ttk::style configure nut.Treeview \
  -font TkFixedFont \
  -background "#00FF00"}
ttk::style configure am.TFrame \
  -background "#00FFFF"
ttk::style configure am.TLabel \
  -background "#00FFFF"
ttk::style configure am.TNotebook \
  -background "#00FFFF"
ttk::style configure am.TSpinbox \
  -background "#00FFFF"
ttk::style configure ar.TButton \
  -background "#BFD780"
ttk::style configure ar.TFrame \
  -background "#7FBF00"
ttk::style configure ar.TLabel \
  -background "#7FBF00"
ttk::style configure ar.TNotebook \
  -background "#7FBF00"
ttk::style configure ar.TRadiobutton \
  -background "#7FBF00"
ttk::style configure lf.Horizontal.TProgressbar \
  -background "#006400"
ttk::style configure lightmeal.TButton \
  -background "#FF9428"
ttk::style configure meal.Horizontal.TProgressbar \
  -background "#00FF00"
ttk::style configure meal.TButton \
  -background "#FF7F00"
ttk::style configure meal.TMenubutton \
  -background "#FF9428"
ttk::style configure meal.TRadiobutton \
  -background "#FF7F00"
ttk::style configure nut.TCombobox \
  -background "#FF7F00"
ttk::style configure nutbutton.TButton \
  -background "#FFFF00"
ttk::style configure po.TButton \
  -background "#5454FF" \
  -foreground "#FFFF00"
ttk::style configure po.TCheckbutton \
  -background "#5454FF" \
  -foreground "#FFFF00"
ttk::style configure po.TFrame \
  -background "#5454FF"
ttk::style configure po.TLabel \
  -background "#5454FF" \
  -foreground "#FFFF00"
ttk::style configure po.TMenubutton \
  -background "#5454FF" \
  -foreground "#FFFF00"
ttk::style configure po.red.TButton \
  -background "#5454FF" \
  -foreground "#FF0000"
ttk::style configure recipe.TButton \
  -background "#7FBF00"
ttk::style configure rm.TCombobox \
  -background "#FF7F00"
ttk::style configure rm.TFrame \
  -background "#FF7F00"
ttk::style configure rm.TLabel \
  -background "#FF7F00"
ttk::style configure rmright.TLabel \
  -background "#FF7F00" \
  -anchor e
ttk::style configure rm.TNotebook \
  -background "#FF7F00"
ttk::style configure rm.TSpinbox \
  -background "#FF7F00"
ttk::style configure ts.TCheckbutton \
  -background "#00FF00" \
  -foreground "#000000"
ttk::style configure ts.TCombobox \
  -background "#00FF00"
ttk::style configure ts.TFrame \
  -background "#FFFF00"
ttk::style configure ts.TLabel \
  -background "#FFFF00"
ttk::style configure vf.TButton \
  -background "#00FF00"
ttk::style configure vf.TCombobox \
  -background "#00FF00"
ttk::style configure vf.TFrame \
  -background "#00FF00"
ttk::style configure vf.TLabel \
  -background "#00FF00"
ttk::style configure vfleft.TLabel \
  -background "#00FF00" \
  -anchor w
ttk::style configure vfright.TLabel \
  -background "#00FF00" \
  -anchor e
ttk::style configure vftop.TLabel \
  -background "#00FF00" \
  -anchor n
ttk::style configure vf.TNotebook \
  -background "#00FF00"
ttk::style configure vf.TSpinbox \
  -background "#00FF00"
ttk::style map ar.TRadiobutton \
  -indicatorcolor { selected "#FF0000" }
ttk::style map meal.TRadiobutton \
  -indicatorcolor { selected "#FF0000" }
ttk::style map nut.TCombobox \
  -fieldbackground { readonly "#FFFF00" }
ttk::style map nut.TCombobox \
  -selectbackground { readonly "#FFFF00" }
ttk::style map nut.TCombobox \
  -selectforeground { readonly "#000000" }
ttk::style map po.TButton \
  -foreground { active "#000000" }
ttk::style map po.TCheckbutton \
  -foreground { active "#000000" }
ttk::style map po.TCheckbutton \
  -indicatorcolor { selected "#FF0000" }
ttk::style map po.TCombobox \
  -fieldbackground { readonly "#FFFFFF" }
ttk::style map po.TMenubutton \
  -foreground { active "#000000" }
ttk::style map po.red.TButton \
  -foreground { active "#FF0000" }
ttk::style map rm.TCombobox \
  -fieldbackground { readonly "#FF9428" }
ttk::style map rm.TCombobox \
  -selectbackground { readonly "#FF9428" }
ttk::style map rm.TCombobox \
  -selectforeground { readonly "#000000" }
ttk::style map ts.TCheckbutton \
  -background { active "#00FF00" }
ttk::style map ts.TCheckbutton \
  -foreground { active "#000000" }
ttk::style map ts.TCheckbutton \
  -indicatorcolor { selected "#FF0000" }
ttk::style map ts.TCombobox \
  -fieldbackground { readonly "#00FF00" }
ttk::style map ts.TCombobox \
  -selectbackground { readonly "#00FF00" }
ttk::style map ts.TCombobox \
  -selectforeground { readonly "#000000" }
ttk::style map vf.TCombobox \
  -fieldbackground { readonly "#00FF00" }
set background(am) "#00FFFF"
set background(rm) "#FF7F00"
set background(vf) "#00FF00"
set background(ar) "#7FBF00"

trace add variable ::FIRSTMEALam write SetMealRange_am
trace add variable ::LASTMEALam write SetMealRange_am

set ::SetDefanalPreviousValue 0
set ::LastSetDefanal 0
set ::MealfoodSequence 0
set ::MealfoodStatus {}
set ::MealfoodPCF {}
set ::MealfoodPCFfactor {}
set ::lastrmq 0
set ::lastamrm 0
set ::lastac 0
set ::lastbubble 0
set ::BubbleMachineStatus 0
set ::realmealchange 0
set ::newtheusual ""
set gramsvf 0
set ouncesvf 0.0
set caloriesvf 0
set Amountvf 0.0
set ounce2gram 0.0
set cal2gram 0
set Amount2gram 0.0
set ::PCFchoices {{No Auto Portion Control} {Protein} {Non-Fiber Carb} {Total Fat} {Vitamin A} {Thiamin} {Riboflavin} {Niacin} {Panto. Acid} {Vitamin B6} {Folate} {Vitamin B12} {Choline} {Vitamin C} {Vitamin D} {Vitamin E} {Vitamin K1} {Calcium} {Copper} {Iron} {Magnesium} {Manganese} {Phosphorus} {Potassium} {Selenium} {Sodium} {Zinc} {Glycine} {Retinol} {Fiber}}
set ::rmMenu .nut.rm.frmenu

ttk::notebook .nut
place .nut \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 1.0
frame .nut.am \
  -background "#00FFFF"
frame .nut.rm \
  -background "#FF7F00"
frame .nut.ar \
  -background "#7FBF00"
frame .nut.vf \
  -background "#00FF00"
frame .nut.po \
  -background "#5454FF"
frame .nut.ts \
  -background "#FFFF00"
frame .nut.qn
.nut add .nut.am \
  -text "Analyze Meals"
.nut add .nut.rm \
  -text "Record Meals & Recipes"
.nut add .nut.ar \
  -text "Record Meals & Recipes"
.nut add .nut.vf \
  -text "View Foods"
.nut add .nut.po \
  -text "Personal Options"
.nut add .nut.ts \
  -text "The Story"
.nut add .nut.qn \
  -text "Quit NUT"
.nut hide .nut.ar
.nut hide .nut.ts

pack [ttk::label .nut.qn.label \
  -text "\nNUT has ended."]
bind .nut <<NotebookTabChanged>> NutTabChange

ttk::label .nut.am.herelabel \
  -text "Here are \"Daily Value\" average percentages for your previous " \
  -style am.TLabel \
  -anchor e
spinbox .nut.am.mealsb \
  -width 5 \
  -justify right \
  -from 1 \
  -to 999999 \
  -increment 1 \
  -textvariable ::meals_to_analyze_am \
  -buttonbackground "#00FFFF"
ttk::label .nut.am.meallabel \
  -text " meals:" \
  -style am.TLabel
ttk::label .nut.am.rangelabel \
  -textvariable mealrange \
  -style am.TLabel \
  -anchor center
place .nut.am.herelabel \
  -relx 0.0 \
  -rely 0.088148146  \
  -relheight 0.044444444 \
  -relwidth 0.64
place .nut.am.mealsb \
  -relx 0.64 \
  -rely 0.088148146  \
  -relheight 0.044444444 \
  -relwidth 0.12
place .nut.am.meallabel \
  -relx 0.76 \
  -rely 0.088148146  \
  -relheight 0.044444444 \
  -relwidth 0.12
place .nut.am.rangelabel \
  -relx 0.0 \
  -rely 0.15  \
  -relheight 0.044444444 \
  -relwidth 1.0

scale .nut.rm.scale \
  -background "#FF9428" \
  -width [expr {$::magnify * 11}] \
  -sliderlength [expr {$::magnify * 20}] \
  -showvalue 0 \
  -orient horizontal \
  -variable ::mealoffset \
  -from \
  -100 \
  -to 100 \
  -command mealchange
place .nut.rm.scale \
  -relx 0.0058 \
  -rely 0.0046296296 \
  -relheight 0.1 \
  -relwidth 0.24

menubutton .nut.rm.theusual \
  -text "Customary Meals" \
  -direction right \
  -background "#FF9428" \
  -anchor center \
  -relief raised \
  -menu .nut.rm.theusual.m
place .nut.rm.theusual \
  -relx 0.0058 \
  -rely 0.12 \
  -relheight 0.05 \
  -relwidth 0.2
menu .nut.rm.theusual.m \
  -background "#FF9428" \
  -tearoff 0 \
  -postcommand theusualPopulateMenu
.nut.rm.theusual.m add cascade \
  -label "Add Customary Meal to this meal" \
  -menu .nut.rm.theusual.m.add \
  -background "#FF9428"
.nut.rm.theusual.m add cascade \
  -label "Save this meal as a Customary Meal" \
  -menu .nut.rm.theusual.m.save \
  -background "#FF9428"
.nut.rm.theusual.m add cascade \
  -label "Delete a Customary Meal" \
  -menu .nut.rm.theusual.m.delete \
  -background "#FF9428"
menu .nut.rm.theusual.m.add \
  -tearoff 0
menu .nut.rm.theusual.m.save \
  -tearoff 0
menu .nut.rm.theusual.m.delete \
  -tearoff 0

button .nut.rm.recipebutton \
  -background "#FF9428" \
  -anchor center \
  -text "Save as a Recipe" \
  -relief raised \
  -state disabled \
  -command RecipeSaveAs
place .nut.rm.recipebutton \
  -relx 0.0058 \
  -rely 0.185 \
  -relheight 0.045 \
  -relwidth 0.2

ttk::label .nut.rm.newtheusuallabel \
  -style rm.TLabel \
  -text "Type new Customary Meal name and press Save" \
  -wraplength [expr {$::magnify * 175}] \
  -justify center
#place .nut.rm.newtheusuallabel \
  -relx 0.39 \
  -rely 0.03 \
  -relheight 0.09 \
  -relwidth 0.33

ttk::entry .nut.rm.newtheusualentry \
  -textvariable ::newtheusual
set ::newtheusual ""
#place .nut.rm.newtheusualentry \
  -relx 0.31 \
  -rely 0.12 \
  -relheight 0.045 \
  -relwidth 0.33

button .nut.rm.newtheusualbutton \
  -anchor center \
  -text "Save" \
  -command theusualNewName
#place .nut.rm.newtheusualbutton \
  -relx 0.65 \
  -rely 0.12 \
  -relheight 0.045 \
  -relwidth 0.07

ttk::radiobutton .nut.rm.grams \
  -text "Grams" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 1 \
  -style meal.TRadiobutton
ttk::radiobutton .nut.rm.ounces \
  -text "Ounces" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 0 \
  -style meal.TRadiobutton
#place .nut.rm.grams \
  -relx 0.87 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.11
#place .nut.rm.ounces \
  -relx 0.87 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.11
button .nut.rm.analysismeal \
  -text "Analysis" \
  -background "#FF9428" \
  -command SwitchToAnalysis \
  -relief raised
#place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11

menubutton .nut.rm.setmpd \
  -background "#FF9428" \
  -text "Delete All Meals and Set Meals Per Day" \
  -relief raised \
  -menu .nut.rm.setmpd.m
place .nut.rm.setmpd \
  -relx 0.667 \
  -rely 0.006 \
  -relheight 0.045 \
  -relwidth 0.33

ttk::label .nut.rm.fslabel \
  -text "Food Search" \
  -style rmright.TLabel
place .nut.rm.fslabel \
  -relx 0.29 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.1
ttk::combobox .nut.rm.fsentry \
  -takefocus 0 \
  -textvariable ::like_this_rm \
  -style rm.TCombobox
place .nut.rm.fsentry \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45
ttk::progressbar .nut.rm.bubblemachine \
  -style meal.Horizontal.TProgressbar \
  -orient horizontal \
  -mode indeterminate
#place .nut.rm.bubblemachine \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45

button .nut.rm.searchcancel \
  -text "Cancel" \
  -width 6 \
  -command CancelSearch \
  -background "#00FF00"
#place .nut.rm.searchcancel \
  -relx 0.86 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.09

ttk::frame .nut.rm.frlistbox \
  -style rm.TFrame
#place .nut.rm.frlistbox \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
grid propagate .nut.rm.frlistbox 0
grid [tk::listbox .nut.rm.frlistbox.listbox \
  -listvariable foodsrm \
  -yscrollcommand ".nut.rm.frlistbox.scrollv set" \
  -xscrollcommand ".nut.rm.frlistbox.scrollh set" \
  -background "#FF7F00" ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.rm.frlistbox.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.rm.frlistbox.listbox yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.rm.frlistbox.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.rm.frlistbox.listbox xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe
grid rowconfig .nut.rm.frlistbox 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.rm.frlistbox 0 \
  -weight 1 \
  -minsize 0

bind .nut.rm.frlistbox.listbox <<ListboxSelect>> FoodChoicerm
trace add variable ::like_this_rm write FindFoodrm
bind .nut.rm.fsentry <FocusIn> FoodSearchrm

ttk::frame .nut.rm.frmenu \
  -style rm.TFrame
#place .nut.rm.frmenu \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
grid propagate .nut.rm.frmenu 0
grid [tk::text .nut.rm.frmenu.menu \
  -yscrollcommand ".nut.rm.frmenu.scrollv set" \
  -state disabled \
  -wrap none \
  -inactiveselectbackground {} \
  -background "#FF7F00" \
  -cursor [. cget \
  -cursor] ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.rm.frmenu.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.rm.frmenu.menu yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid rowconfig .nut.rm.frmenu 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.rm.frmenu 0 \
  -weight 1 \
  -minsize 0

ttk::label .nut.vf.label \
  -textvariable Long_Desc \
  -style vftop.TLabel \
  -wraplength [expr {$::magnify * 250}]
place .nut.vf.label \
  -relx 0.33 \
  -rely 0.015 \
  -relheight 0.12759259 \
  -relwidth 0.33

set ratio_widget_height_to_spacer 9.6
tk::spinbox .nut.vf.sb0 \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable gramsvf \
  -buttonbackground "#00FF00"
tk::spinbox .nut.vf.sb1 \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable ouncesvf \
  -buttonbackground "#00FF00"
tk::spinbox .nut.vf.sb2 \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable caloriesvf \
  -buttonbackground "#00FF00"
tk::spinbox .nut.vf.sb3 \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable Amountvf \
  -buttonbackground "#00FF00"
menubutton .nut.vf.refusemb \
  -background "#00FF00" \
  -text "Refuse" \
  -direction below \
  -relief raised \
  -menu .nut.vf.refusemb.m
menu .nut.vf.refusemb.m \
  -tearoff 0 \
  -background "#00FF00"
.nut.vf.refusemb.m add command \
  -label "No refuse description provided"
place .nut.vf.sb0 \
  -relx 0.0458 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.08
place .nut.vf.sb1 \
  -relx 0.0458 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.08
place .nut.vf.sb2 \
  -relx 0.0458 \
  -rely 0.098148146  \
  -relheight 0.044444444 \
  -relwidth 0.08
place .nut.vf.sb3 \
  -relx 0.0458 \
  -rely 0.14722222   \
  -relheight 0.044444444 \
  -relwidth 0.08
place .nut.vf.refusemb \
  -relx 0.0458 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.08

ttk::label .nut.vf.sbl0 \
  -text "gm." \
  -style vfleft.TLabel
ttk::label .nut.vf.sbl1 \
  -text "oz." \
  -style vfleft.TLabel
ttk::label .nut.vf.sbl2 \
  -text "cal." \
  -style vfleft.TLabel
ttk::label .nut.vf.refusevalue \
  -textvariable Refusevf \
  -style vfleft.TLabel
set Refusevf "0%"
place .nut.vf.sbl0 \
  -relx 0.133 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.05
place .nut.vf.sbl1 \
  -relx 0.133 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.05
place .nut.vf.sbl2 \
  -relx 0.133 \
  -rely 0.098148146  \
  -relheight 0.044444444 \
  -relwidth 0.05
place .nut.vf.refusevalue \
  -relx 0.133 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.05

button .nut.vf.meal \
  -text "Add to Meal" \
  -state disabled \
  -background "#FF9428" \
  -relief raised \
  -command vf2rm
place .nut.vf.meal \
  -relx 0.78 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.12
ttk::label .nut.vf.fslabel \
  -text "Food Search" \
  -style vfright.TLabel
place .nut.vf.fslabel \
  -relx 0.29 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.1
ttk::combobox .nut.vf.cb \
  -textvariable Msre_Descvf \
  -state readonly \
  -style vf.TCombobox
place .nut.vf.cb \
  -relx 0.133 \
  -rely 0.14722222  \
  -relheight 0.044444444 \
  -relwidth 0.717
ttk::combobox .nut.vf.fsentry \
  -textvariable like_this_vf \
  -style vf.TCombobox
place .nut.vf.fsentry \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45

ttk::frame .nut.vf.frlistbox \
  -style vf.TFrame
#place .nut.vf.frlistbox \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
grid propagate .nut.vf.frlistbox 0
grid [tk::listbox .nut.vf.frlistbox.listbox \
  -width 85 \
  -height 22 \
  -listvariable foodsvf \
  -yscrollcommand ".nut.vf.frlistbox.scrollv set" \
  -xscrollcommand ".nut.vf.frlistbox.scrollh set" \
  -background "#00FF00" ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.vf.frlistbox.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.vf.frlistbox.listbox yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.vf.frlistbox.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.vf.frlistbox.listbox xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe
grid rowconfig .nut.vf.frlistbox 0 \
  -weight 1 \
  -minsize 0
grid columnconfig .nut.vf.frlistbox 0 \
  -weight 1 \
  -minsize 0
bind .nut.vf.frlistbox.listbox <<ListboxSelect>> FoodChoicevf

label .nut.ar.name \
  -text "Recipe Name" \
  -background "#7FBF00" \
  -anchor e
place .nut.ar.name \
  -relx 0.0 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.28
ttk::entry .nut.ar.name_entry \
  -textvariable ::RecipeName
place .nut.ar.name_entry \
  -relx 0.28 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.55

label .nut.ar.numserv \
  -text "Number of servings recipe makes" \
  -background "#7FBF00" \
  -anchor e
place .nut.ar.numserv \
  -relx 0.0 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.28
ttk::entry .nut.ar.numserv_entry \
  -textvariable ::RecipeServNum
place .nut.ar.numserv_entry \
  -relx 0.28 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.1
label .nut.ar.servunit \
  -text "Serving Unit (cup, piece, tbsp, etc.)" \
  -background "#7FBF00" \
  -anchor e
place .nut.ar.servunit \
  -relx 0.0 \
  -rely 0.098148146  \
  -relheight 0.044444444 \
  -relwidth 0.28
ttk::entry .nut.ar.servunit_entry \
  -textvariable ::RecipeServUnit
place .nut.ar.servunit_entry \
  -relx 0.28 \
  -rely 0.098148146  \
  -relheight 0.044444444 \
  -relwidth 0.2

label .nut.ar.servnum \
  -text "Number of units in one serving" \
  -background "#7FBF00" \
  -anchor e
place .nut.ar.servnum \
  -relx 0.0 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.28
ttk::entry .nut.ar.servnum_entry \
  -textvariable ::RecipeServUnitNum
place .nut.ar.servnum_entry \
  -relx 0.28 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.1

label .nut.ar.weight \
  -text "Weight of one serving (if known)" \
  -background "#7FBF00" \
  -anchor e
place .nut.ar.weight \
  -relx 0.0 \
  -rely 0.19629629 \
  -relheight 0.044444444 \
  -relwidth 0.27
ttk::entry .nut.ar.weight_entry \
  -textvariable ::RecipeServWeight
place .nut.ar.weight_entry \
  -relx 0.28 \
  -rely 0.19629629 \
  -relheight 0.044444444 \
  -relwidth 0.1

button .nut.ar.save \
  -text "Save" \
  -command RecipeDone \
  -background "#00FF00"
place .nut.ar.save \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
button .nut.ar.cancel \
  -text "Cancel" \
  -command RecipeCancel \
  -background "#BFD780"
place .nut.ar.cancel \
  -relx 0.87 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.11

ttk::radiobutton .nut.ar.grams \
  -text "Grams" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 1 \
  -style ar.TRadiobutton
ttk::radiobutton .nut.ar.ounces \
  -text "Ounces" \
  -width 6 \
  -variable ::GRAMSopt \
  -value 0 \
  -style ar.TRadiobutton
place .nut.ar.grams \
  -relx 0.87 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.11
place .nut.ar.ounces \
  -relx 0.87 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.11

ttk::frame .nut.po.pane \
  -style po.TFrame
place .nut.po.pane \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 1.0
ttk::frame .nut.po.pane.optframe \
  -style po.TFrame
place .nut.po.pane.optframe \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 0.75
ttk::frame .nut.po.pane.wlogframe \
  -style po.TFrame
place .nut.po.pane.wlogframe \
  -relx 0.75 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 0.25
label .nut.po.pane.wlogframe.weight_l \
  -text "Weight" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.wlogframe.weight_l \
  -relx 0.0 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.45
tk::spinbox .nut.po.pane.wlogframe.weight_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::weightyintercept \
  -disabledforeground "#000000"
place .nut.po.pane.wlogframe.weight_s \
  -relx 0.5 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.4

label .nut.po.pane.wlogframe.bf_l \
  -text "Body Fat %" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.wlogframe.bf_l \
  -relx 0.0 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.45
tk::spinbox .nut.po.pane.wlogframe.bf_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::currentbfp \
  -disabledforeground "#000000"
place .nut.po.pane.wlogframe.bf_s \
  -relx 0.5 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.4

button .nut.po.pane.wlogframe.accept \
  -text "Accept New\nMeasurements" \
  -command AcceptNewMeasurements
place .nut.po.pane.wlogframe.accept \
  -relx 0.36 \
  -rely 0.2 \
  -relheight 0.1 \
  -relwidth 0.55

label .nut.po.pane.wlogframe.summary \
  -wraplength [expr {$::magnify * 150}] \
  -textvariable ::wlogsummary \
  -justify right \
  -anchor ne \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.wlogframe.summary \
  -relx 0.0 \
  -rely 0.34 \
  -relheight 0.6 \
  -relwidth 0.93

button .nut.po.pane.wlogframe.clear \
  -text "Clear Weight Log" \
  -command ClearWeightLog
#place .nut.po.pane.wlogframe.clear \
  -relx 0.3 \
  -rely 0.89 \
  -relheight 0.06 \
  -relwidth 0.63


label .nut.po.pane.optframe.cal_l \
  -text "Calories kc" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.cal_l \
  -relx 0.0 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.cal_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::ENERC_KCALopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.cal_s \
  -relx 0.265 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.14
set ::ENERC_KCALpo 0
ttk::checkbutton .nut.po.pane.optframe.cal_cb1 \
  -text "Adjust to my meals" \
  -variable ::ENERC_KCALpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions ENERC_KCAL]
place .nut.po.pane.optframe.cal_cb1 \
  -relx 0.44 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.cal_cb2 \
  -text "Auto-Set" \
  -variable ::ENERC_KCALpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions ENERC_KCAL]
place .nut.po.pane.optframe.cal_cb2 \
  -relx 0.69 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.fat_l \
  -text "Total Fat g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.fat_l \
  -relx 0.0 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.fat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FATopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.fat_s \
  -relx 0.265 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.fat_cb1 \
  -text "Adjust to my meals" \
  -variable ::FATpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAT]
place .nut.po.pane.optframe.fat_cb1 \
  -relx 0.44 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.fat_cb2 \
  -text "DV 36% of Calories" \
  -variable ::FATpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAT]
place .nut.po.pane.optframe.fat_cb2 \
  -relx 0.69 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.prot_l \
  -text "Protein g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.prot_l \
  -relx 0.0 \
  -rely 0.19 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.prot_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::PROCNTopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.prot_s \
  -relx 0.265 \
  -rely 0.19 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.prot_cb1 \
  -text "Adjust to my meals" \
  -variable ::PROCNTpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions PROCNT]
place .nut.po.pane.optframe.prot_cb1 \
  -relx 0.44 \
  -rely 0.19 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.prot_cb2 \
  -text "DV 10% of Calories" \
  -variable ::PROCNTpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions PROCNT]
place .nut.po.pane.optframe.prot_cb2 \
  -relx 0.69 \
  -rely 0.19 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.nfc_l \
  -text "Non-Fiber Carb g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.nfc_l \
  -relx 0.0 \
  -rely 0.27 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.nfc_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::CHO_NONFIBopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.nfc_s \
  -relx 0.265 \
  -rely 0.27 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.nfc_cb1 \
  -text "Adjust to my meals" \
  -variable ::CHO_NONFIBpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions CHO_NONFIB]
place .nut.po.pane.optframe.nfc_cb1 \
  -relx 0.44 \
  -rely 0.27 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.nfc_cb2 \
  -text "Balance of Calories" \
  -variable ::CHO_NONFIBpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions CHO_NONFIB]
place .nut.po.pane.optframe.nfc_cb2 \
  -relx 0.69 \
  -rely 0.27 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.fiber_l \
  -text "Fiber g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.fiber_l \
  -relx 0.0 \
  -rely 0.35 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.fiber_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FIBTGopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.fiber_s \
  -relx 0.265 \
  -rely 0.35 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.fiber_cb1 \
  -text "Adjust to my meals" \
  -variable ::FIBTGpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FIBTG]
place .nut.po.pane.optframe.fiber_cb1 \
  -relx 0.44 \
  -rely 0.35 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.fiber_cb2 \
  -text "Daily Value Default" \
  -variable ::FIBTGpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FIBTG]
place .nut.po.pane.optframe.fiber_cb2 \
  -relx 0.69 \
  -rely 0.35 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.sat_l \
  -text "Saturated Fat g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.sat_l \
  -relx 0.0 \
  -rely 0.43 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.sat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FASATopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.sat_s \
  -relx 0.265 \
  -rely 0.43 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.sat_cb1 \
  -text "Adjust to my meals" \
  -variable ::FASATpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FASAT]
place .nut.po.pane.optframe.sat_cb1 \
  -relx 0.44 \
  -rely 0.43 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.sat_cb2 \
  -text "DV 10% of Calories" \
  -variable ::FASATpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FASAT]
place .nut.po.pane.optframe.sat_cb2 \
  -relx 0.69 \
  -rely 0.43 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.efa_l \
  -text "Essential Fatty Acids g" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.efa_l \
  -relx 0.0 \
  -rely 0.51 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.efa_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FAPUopt \
  -disabledforeground "#000000"
place .nut.po.pane.optframe.efa_s \
  -relx 0.265 \
  -rely 0.51 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.efa_cb1 \
  -text "Adjust to my meals" \
  -variable ::FAPUpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAPU]
place .nut.po.pane.optframe.efa_cb1 \
  -relx 0.44 \
  -rely 0.51 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.efa_cb2 \
  -text "4% of Calories" \
  -variable ::FAPUpo \
  -onvalue 2 \
  -style po.TCheckbutton \
  -command [list ChangePersonalOptions FAPU]
place .nut.po.pane.optframe.efa_cb2 \
  -relx 0.69 \
  -rely 0.51 \
  -relheight 0.04444444 \
  -relwidth 0.23
label .nut.po.pane.optframe.fish_l \
  -text "Omega-6/3 Balance" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
place .nut.po.pane.optframe.fish_l \
  -relx 0.0 \
  -rely 0.59 \
  -relheight 0.04444444 \
  -relwidth 0.25
set ::balvals {}
for {set i 15} {$i < 91} {incr i} {
 lappend ::balvals "$i / [expr {100 - $i}]"
 }
ttk::combobox .nut.po.pane.optframe.fish_s \
  -width 7 \
  -justify right \
  -textvariable ::FAPU1po \
  -values $::balvals \
  -state readonly \
  -style po.TCombobox
trace add variable ::FAPU1po write [list ChangePersonalOptions FAPU1]
place .nut.po.pane.optframe.fish_s \
  -relx 0.265 \
  -rely 0.59 \
  -relheight 0.04444444 \
  -relwidth 0.14
menubutton .nut.po.pane.optframe.dv_mb \
  -background "#5454FF" \
  -foreground "#FFFF00" \
  -relief raised \
  -text "Daily Values for Individual Micronutrients" \
  -direction right \
  -menu .nut.po.pane.optframe.dv_mb.m
menu .nut.po.pane.optframe.dv_mb.m \
  -tearoff 0
foreach nut {{Vitamin A} Thiamin Riboflavin Niacin {Panto. Acid} {Vitamin B6} Folate {Vitamin B12} {Choline} {Vitamin C} {Vitamin D} {Vitamin E} {Vitamin K1} Calcium Copper Iron Magnesium Manganese Phosphorus Potassium Selenium Sodium Zinc Glycine Retinol} {
 .nut.po.pane.optframe.dv_mb.m add command \
  -label $nut \
  -command [list changedv_vitmin $nut]
 }
place .nut.po.pane.optframe.dv_mb \
  -relx 0.02 \
  -rely 0.67 \
  -relheight 0.04444444 \
  -relwidth 0.55
label .nut.po.pane.optframe.vite_l \
  -text "vite" \
  -anchor e \
  -background "#5454FF" \
  -foreground "#FFFF00"
#place .nut.po.pane.optframe.vite_l \
  -relx 0.0 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.25
tk::spinbox .nut.po.pane.optframe.vite_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::NULLopt \
  -disabledforeground "#000000"
#place .nut.po.pane.optframe.vite_s \
  -relx 0.265 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.14
ttk::checkbutton .nut.po.pane.optframe.vite_cb1 \
  -text "Adjust to my meals" \
  -variable ::vitminpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton
#place .nut.po.pane.optframe.vite_cb1 \
  -relx 0.44 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::checkbutton .nut.po.pane.optframe.vite_cb2 \
  -text "Daily Value Default" \
  -variable ::vitminpo \
  -onvalue 2 \
  -style po.TCheckbutton
#place .nut.po.pane.optframe.vite_cb2 \
  -relx 0.69 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.23
ttk::frame .nut.ts.frranking \
  -style vf.TFrame
place .nut.ts.frranking \
  -relx 0.0 \
  -rely 0.05 \
  -relheight 0.7 \
  -relwidth 1.0
grid propagate .nut.ts.frranking 0
ttk::combobox .nut.ts.rankchoice \
  -state readonly \
  -justify center \
  -style ts.TCombobox
place .nut.ts.rankchoice \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 0.05 \
  -relwidth 0.5
ttk::combobox .nut.ts.fdgroupchoice \
  -textvariable ::fdgroupchoice \
  -state readonly \
  -justify center \
  -style ts.TCombobox
place .nut.ts.fdgroupchoice \
  -relx 0.5 \
  -rely 0.0 \
  -relheight 0.05 \
  -relwidth 0.5

labelframe .nut.ts.frgraph \
  -background "#FFFF00"
place .nut.ts.frgraph \
  -relx 0.0 \
  -rely 0.75 \
  -relheight 0.25 \
  -relwidth 1.0

canvas .nut.ts.frgraph.canvas \
  -relief flat \
  -background "#FFFF00"
place .nut.ts.frgraph.canvas \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 1.0

grid [ttk::treeview .nut.ts.frranking.ranking \
  -yscrollcommand [list .nut.ts.frranking.vsb set] \
  -style nut.Treeview \
  -columns {food field1 field2} \
  -show headings] \
  -row 0 \
  -column 0 \
  -sticky nsew
.nut.ts.frranking.ranking column 0 \
  -minwidth [expr {int(10 * $vrootwGR * $appSize / 1.3 / 15)}]
.nut.ts.frranking.ranking column 1 \
  -minwidth [expr {int(2 * $vrootwGR * $appSize / 1.3 / 15)}]
.nut.ts.frranking.ranking column 2 \
  -minwidth [expr {int(3 * $vrootwGR * $appSize / 1.3 / 15)}]
grid [scrollbar .nut.ts.frranking.vsb \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command [list .nut.ts.frranking.ranking yview]] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid columnconfigure .nut.ts.frranking 0 \
  -weight 1 \
  -minsize 0
grid rowconfigure .nut.ts.frranking 0 \
  -weight 1 \
  -minsize 0

bind .nut.ts.frranking.ranking <<TreeviewSelect>> rank2vf

tuneinvf

trace add variable like_this_vf write FindFoodvf
bind .nut.vf.fsentry <FocusIn> FoodSearchvf

foreach x {am rm vf ar} {
 ttk::notebook .nut.${x}.nbw \
  -style ${x}.TNotebook
 ttk::frame .nut.${x}.nbw.screen0 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen1 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen2 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen3 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen4 \
  -style ${x}.TFrame
 ttk::frame .nut.${x}.nbw.screen5 \
  -style ${x}.TFrame
 .nut.${x}.nbw add .nut.${x}.nbw.screen0 \
  -text "Daily Value %"
 .nut.${x}.nbw add .nut.${x}.nbw.screen1 \
  -text "DV Amounts"
 .nut.${x}.nbw add .nut.${x}.nbw.screen2 \
  -text "Carbs & Amino Acids"
 .nut.${x}.nbw add .nut.${x}.nbw.screen3 \
  -text "Miscellaneous"
 .nut.${x}.nbw add .nut.${x}.nbw.screen4 \
  -text "Sat & Mono Fatty Acids"
 .nut.${x}.nbw add .nut.${x}.nbw.screen5 \
  -text "Poly & Trans Fatty Acids"
 place .nut.${x}.nbw \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0

 set screen 0
 foreach nut {ENERC_KCAL} {
  if {$x != "ar"} {
   button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::caloriebutton \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"   } else {
   button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Calories (2000)" \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"    }
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.055
  }
 foreach nut {ENERC_KCAL1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -background "#FFFF00"
  label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor center
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely 0.0725 \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely 0.0725 \
  -relheight 0.06 \
  -relwidth 0.165
  }
 set rely 0.252109375
#set rely 0.205
 foreach nut {FAT FASAT FAMS FAPU OMEGA6 LA AA OMEGA3 ALA EPA DHA CHOLE} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.00625
 foreach nut {CHOCDF FIBTG} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.19
#set rely 0.205
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC VITD_BOTH VITE VITK1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.00625
 foreach nut {PROCNT} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 foreach nut {CHO_NONFIB} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}1 \
  -justify right
   } else {
    label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}1 \
  -background $background($x) \
  -anchor e

#uncomment this line and comment out the previous if user insists he
#must see CHO_NONFIB percentage of DV instead of grams

#    label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
   label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w

#uncomment this line and comment out the previous if user insists he
#must see CHO_NONFIB percentage of DV instead of grams

#   label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.252109375
#set rely [expr {$rely + 0.062109375}]
 foreach nut {CA CU FE MG MN P K SE NA ZN} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely [expr {$rely + 0.062109375}]
 foreach nut {FAPU1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Omega-6/3 Balance" \
  -command "NewStory FAPU $x" \
  -background "#FFFF00"
  label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  }
 set screen 1
 foreach nut {ENERC_KCAL} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely 0.00625 \
  -relheight 0.06 \
  -relwidth 0.055
  }
 foreach nut {ENERC_KCAL1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -background "#FFFF00"
  label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor center
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely 0.0725 \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely 0.0725 \
  -relheight 0.06 \
  -relwidth 0.165
  }
 set rely 0.252109375
#set rely 0.205
 foreach nut {FAT FASAT FAMS FAPU OMEGA6 LA AA OMEGA3 ALA EPA DHA CHOLE} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.00625
 foreach nut {CHOCDF FIBTG} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.19
#set rely 0.205
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC VITD_BOTH VITE VITK1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.00625
 foreach nut {PROCNT} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 foreach nut {CHO_NONFIB} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.252109375
#set rely [expr {$rely + 0.062109375}]
 foreach nut {CA CU FE MG MN P K SE NA ZN} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely [expr {$rely + 0.062109375}]
 foreach nut {FAPU1} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Omega-6/3 Balance" \
  -command "NewStory FAPU $x" \
  -background "#FFFF00"
  label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor center
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  }
 set screen 2
 set rely 0.13875
 foreach nut {CHOCDF FIBTG STARCH SUGAR FRUS GALS GLUS LACS MALS SUCS} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.13875
 foreach nut {PROCNT ADPROT ALA_G ARG_G ASP_G CYS_G GLU_G GLY_G HISTN_G HYP ILE_G} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.13875
 foreach nut {LEU_G LYS_G MET_G PHE_G PRO_G SER_G THR_G TRP_G TYR_G VAL_G} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set screen 3
 set rely 0.0725
 foreach nut {ENERC_KJ ASH WATER CAFFN THEBRN ALC FLD BETN CHOLN FOLAC FOLFD FOLDFE RETOL} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.0725
 foreach nut {VITA_IU ERGCAL CHOCAL VITD VITB12_ADDED VITE_ADDED VITK1D MK4 TOCPHA TOCPHB TOCPHG TOCPHD TOCTRA} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.0725
 foreach nut {TOCTRB TOCTRG TOCTRD CARTA CARTB CRYPX LUT_ZEA LYCPN CHOLE PHYSTR SITSTR CAMD5 STID7} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set screen 4
 set rely 0.00625
 foreach nut {FASAT F4D0 F6D0 F8D0 F10D0 F12D0 F13D0 F14D0 F15D0 F16D0 F17D0 F18D0 F20D0 F22D0 F24D0} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.17 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.345 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.445 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.0725
 foreach nut {FAMS F14D1 F15D1 F16D1 F16D1C F17D1 F18D1 F18D1C F20D1 F22D1 F22D1C F24D1C} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.5 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.675 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.775 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set screen 5
 set rely 0.205
 foreach nut {FAPU F18D2 F18D2CN6 F18D3 F18D3CN3 F18D3CN6 F18D4 F20D2CN6} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.005 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.18 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.28 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.13875
 foreach nut {F20D3 F20D3N3 F20D3N6 F20D4 F20D4N6 F20D5 F21D5 F22D4 F22D5 F22D6} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.335 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.51 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.61 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 set rely 0.0725
 foreach nut {FATRN FATRNM F16D1T F18D1T F18D1TN7 F22D1T FATRNP F18D2I F18D2T F18D2TT F18D2CLA F18D3I} {
  button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -background "#FFFF00"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -background $background($x) \
  -anchor e
   }
  label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -background $background($x) \
  -anchor w
  place .nut.${x}.nbw.screen${screen}.b${nut} \
  -relx 0.665 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.165
  place .nut.${x}.nbw.screen${screen}.l${nut} \
  -relx 0.84 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.1
  place .nut.${x}.nbw.screen${screen}.lu${nut} \
  -relx 0.94 \
  -rely $rely \
  -relheight 0.06 \
  -relwidth 0.055
  set rely [expr {$rely + 0.062109375}]
  }
 }

bind .nut.am.nbw <<NotebookTabChanged>> NBWamTabChange
bind .nut.rm.nbw <<NotebookTabChanged>> NBWrmTabChange
bind .nut.vf.nbw <<NotebookTabChanged>> NBWvfTabChange
bind .nut.ar.nbw <<NotebookTabChanged>> NBWarTabChange

if {$need_load == 1} {

 toplevel .loadframe
 wm title .loadframe $::version
 wm withdraw .
# modified from the artistic analog clock by Wolf-Dieter Busch at http://wiki.tcl.tk/1011
 set ::clockscale [expr {$::magnify * 0.42}]
 set cheight 350
 set cwidth  650
grid [canvas .loadframe.c \
  -width [expr {$::magnify * $cwidth}] \
  -height [expr {$::magnify * $cheight}] \
  -highlightthickness 0] \
  -padx [expr {$::clockscale * 20}] \
  -pady [expr {$::clockscale * 20}]
 set PI [expr {asin(1)*2}]
 set sekundenzeigerlaenge [expr {$::clockscale * 85}]
 set minutenzeigerlaenge  [expr {$::clockscale * 75}]
 set stundenzeigerlaenge  [expr {$::clockscale * 60}]
 drawClock
 showTime
 .loadframe.c create text [expr {$::magnify * $cwidth / 2}] [expr {$::clockscale * 100}] \
  -anchor center \
  -text "Updating USDA Nutrient Database"
 ttk::style configure lf.Horizontal.TProgressbar \
  -background "#006400"
 for {set i 1} {$i < 9} {incr i} {
  set ::pbar($i) 0.0
  ttk::progressbar .loadframe.pbar${i} \
  -style lf.Horizontal.TProgressbar \
  -variable pbar($i) \
  -orient horizontal \
  -length [expr {$::magnify * 100}] \
  -mode determinate  .loadframe.c create window [expr {$::clockscale * 150 + 0.38 * $i * $::clockscale * 200}] [expr {$::clockscale * 160 + 0.38 * $i * $::clockscale * 200}] \
  -anchor w \
  -height [expr {18.0 * $::magnify}] \
  -window .loadframe.pbar${i}
  set p_label_x($i) [expr {$::clockscale * 150 + 0.38 * $i * $::clockscale * 200 + $::magnify * 100 + $::clockscale * 20}]
  set p_label_y($i) [expr {$::clockscale * 160 + 0.38 * $i * $::clockscale * 200}]
  }
 .loadframe.c create text $p_label_x(1) $p_label_y(1) \
  -anchor w \
  -text "Load Nutrient Definitions"
 .loadframe.c create text $p_label_x(2) $p_label_y(2) \
  -anchor w \
  -text "Load Food Groups"
 .loadframe.c create text $p_label_x(3) $p_label_y(3) \
  -anchor w \
  -text "Load Foods"
 .loadframe.c create text $p_label_x(4) $p_label_y(4) \
  -anchor w \
  -text "Load Serving Sizes"
 .loadframe.c create text $p_label_x(5) $p_label_y(5) \
  -anchor w \
  -text "Load Nutrient Values"
 .loadframe.c create text $p_label_x(6) $p_label_y(6) \
  -anchor w \
  -text "Compute Derived Nutrient Values"
 .loadframe.c create text $p_label_x(7) $p_label_y(7) \
  -anchor w \
  -text "Load NUT Logic"
 .loadframe.c create text $p_label_x(8) $p_label_y(8) \
  -anchor w \
  -text "Load Legacy Database if it exists"
 update
 thread::send \
  -async $::SQL_THREAD {db eval {select code from z_tcl_code where name = 'InitialLoad_alt_GUI'} { } ; eval $code}
 } else {
 set tablename [db eval {select name from sqlite_master where type='table' and name = "nutr_def"}]
 if { $tablename == "" } {
  set ::meals_to_analyze_am 0
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "NUT requires the USDA Nutrient Database to be present initially in order to be loaded into SQLite.  Download it in the full ascii version from \"https://data.nal.usda.gov/dataset/composition-foods-raw-processed-prepared-usda-national-nutrient-database-standard-referen-11\" or from \"http://nut.sourceforge.net\" and unzip it in this directory, [pwd]." \
  -detail "Follow this same procedure later when you want to upgrade the USDA database yet retain your personal data.  After USDA files have been loaded into NUT they can be deleted.\n\nIf you really do want to reload a USDA database that you have already loaded, rename the file \"NUTR_DEF.txt.loaded\" to \"NUTR_DEF.txt\"."
  rename unknown ""
  rename _original_unknown unknown
  destroy .
  exit 0
  } else {
  db eval {select code from z_tcl_code where name = 'Start_NUT'} { }
  eval $code
  }
 }

#end Make_GUI_Linux
}

set ComputeDerivedValues {

proc ComputeDerivedValues {db table} {

dbmem eval {
/* NUT has derived nutrient values that are handled as if they are
   USDA nutrients to save a lot of computation and confusion at runtime
   because the values are already there */

  --insert VITE records into nut_data
insert or replace into nut_data select f.NDB_No, 2008,  ifnull(vite_added.Nutr_Val, 0.0) + ifnull(tocpha.Nutr_Val, 0.0) from food_des f left join nut_data tocpha on f.NDB_No = tocpha.NDB_No and tocpha.Nutr_No = 323 left join nut_data vite_added on f.NDB_No = vite_added.NDB_No and vite_added.Nutr_No = 573 where tocpha.Nutr_Val is not null or vite_added.Nutr_Val is not null;
   --insert LA records into nut_data
insert or replace into nut_data select f.NDB_No, 2001, case when f18d2cn6.Nutr_Val is not null then f18d2cn6.Nutr_Val when f18d2.Nutr_Val is not null then f18d2.Nutr_Val - ifnull(f18d2t.Nutr_Val, 0.0) - ifnull(f18d2tt.Nutr_Val, 0.0) - ifnull(f18d2i.Nutr_Val, 0.0) - ifnull(f18d2cla.Nutr_Val, 0.0) end from food_des f left join nut_data f18d2 on f.NDB_No = f18d2.NDB_No and f18d2.Nutr_No = 618 left join nut_data f18d2cn6 on f.NDB_No = f18d2cn6.NDB_No and f18d2cn6.Nutr_No = 675 left join nut_data f18d2t on f.NDB_No = f18d2t.NDB_No and f18d2t.Nutr_No = 665 left join nut_data f18d2tt on f.NDB_No = f18d2tt.NDB_No and f18d2tt.Nutr_No = 669 left join nut_data f18d2i on f.NDB_No = f18d2i.NDB_No and f18d2i.Nutr_No = 666 left join nut_data f18d2cla on f.NDB_No = f18d2cla.NDB_No and f18d2cla.Nutr_No = 670 where f18d2.Nutr_Val is not null or f18d2cn6.Nutr_Val is not null or f18d2t.Nutr_Val is not null or f18d2tt.Nutr_Val is not null or f18d2i.Nutr_Val is not null or f18d2cla.Nutr_Val is not null;
   --insert ALA records into nut_data
insert or replace into nut_data select f.NDB_No, 2003, case when f18d3cn3.Nutr_Val is not null then f18d3cn3.Nutr_Val when f18d3.Nutr_Val is not null then f18d3.Nutr_Val - ifnull(f18d3cn6.Nutr_Val, 0.0) - ifnull(f18d3i.Nutr_Val, 0.0) end from food_des f left join nut_data f18d3 on f.NDB_No = f18d3.NDB_No and f18d3.Nutr_No = 619 left join nut_data f18d3cn3 on f.NDB_No = f18d3cn3.NDB_No and f18d3cn3.Nutr_No = 851 left join nut_data f18d3cn6 on f.NDB_No = f18d3cn6.NDB_No and f18d3cn6.Nutr_No = 685 left join nut_data f18d3i on f.NDB_No = f18d3i.NDB_No and f18d3i.Nutr_No = 856 where f18d3.Nutr_Val is not null or f18d3cn3.Nutr_Val is not null or f18d3cn6.Nutr_Val is not null or f18d3i.Nutr_Val is not null;
   --insert SHORT6 records into nut_data
insert or replace into nut_data select f.NDB_No, 3003, ifnull(la.Nutr_Val, 0.0) + ifnull(f18d3cn6.Nutr_Val, 0.0) from food_des f left join nut_data la on f.NDB_No = la.NDB_No and la.Nutr_No = 2001 left join nut_data f18d3cn6 on f.NDB_No = f18d3cn6.NDB_No and f18d3cn6.Nutr_No = 685 where la.Nutr_Val is not null or f18d3cn6.Nutr_Val is not null;
   --insert SHORT3 records into nut_data
insert or replace into nut_data select f.NDB_No, 3005, ifnull(ala.Nutr_Val, 0.0) + ifnull(f18d4.Nutr_Val, 0.0) from food_des f left join nut_data ala on f.NDB_No = ala.NDB_No and ala.Nutr_No = 2003 left join nut_data f18d4 on f.NDB_No = f18d4.NDB_No and f18d4.Nutr_No = 627 where ala.Nutr_Val is not null or f18d4.Nutr_Val is not null;
   --insert AA records into nut_data
insert or replace into nut_data select f.NDB_No, 2002, case when f20d4n6.Nutr_Val is not null then f20d4n6.Nutr_Val else f20d4.Nutr_Val end from food_des f left join nut_data f20d4 on f.NDB_No = f20d4.NDB_No and f20d4.Nutr_No = 620 left join nut_data f20d4n6 on f.NDB_No = f20d4n6.NDB_No and f20d4n6.Nutr_No = 855 where f20d4.Nutr_Val is not null or f20d4n6.Nutr_Val is not null;
   --insert LONG6 records into nut_data
insert or replace into nut_data select f.NDB_No, 3004, case when f20d3n6.Nutr_Val is not null then ifnull(aa.Nutr_Val,0.0) + f20d3n6.Nutr_Val + ifnull(f22d4.Nutr_Val,0.0) else ifnull(aa.Nutr_Val,0.0) + ifnull(f20d3.Nutr_Val,0.0) + ifnull(f22d4.Nutr_Val, 0.0) end from food_des f left join nut_data aa on f.NDB_No = aa.NDB_No and aa.Nutr_No = 2002 left join nut_data f20d3n6 on f.NDB_No = f20d3n6.NDB_No and f20d3n6.Nutr_No = 853 left join nut_data f20d3 on f.NDB_No = f20d3.NDB_No and f20d3.Nutr_No = 689 left join nut_data f22d4 on f.NDB_No = f22d4.NDB_No and f22d4.Nutr_No = 858 where aa.Nutr_Val is not null or f20d3n6.Nutr_Val is not null or f20d3.Nutr_Val is not null or f22d4.Nutr_Val is not null;
   --insert EPA records into nut_data
insert or replace into nut_data select f.NDB_No, 2004, f20d5.Nutr_Val from food_des f left join nut_data f20d5 on f.NDB_No = f20d5.NDB_No and f20d5.Nutr_No = 629 where f20d5.Nutr_Val is not null;
   --insert DHA records into nut_data
insert or replace into nut_data select f.NDB_No, 2005, f22d6.Nutr_Val from food_des f left join nut_data f22d6 on f.NDB_No = f22d6.NDB_No and f22d6.Nutr_No = 621 where f22d6.Nutr_Val is not null;
   --insert LONG3 records into nut_data
insert or replace into nut_data select f.NDB_No, 3006, ifnull(epa.Nutr_Val, 0.0) + ifnull(dha.Nutr_Val, 0.0) + ifnull(f20d3n3.Nutr_Val, 0.0) + ifnull(f22d5.Nutr_Val, 0.0) from food_des f left join nut_data epa on f.NDB_No = epa.NDB_No and epa.Nutr_No = 2004 left join nut_data dha on f.NDB_No = dha.NDB_No and dha.Nutr_No = 2005 left join nut_data f20d3n3 on f.NDB_No = f20d3n3.NDB_No and f20d3n3.Nutr_No = 852 left join nut_data f22d5 on f.NDB_No = f22d5.NDB_No and f22d5.Nutr_No = 631 where epa.Nutr_Val is not null or dha.Nutr_Val is not null or f20d3n3.Nutr_Val is not null or f22d5.Nutr_Val is not null;
   --insert OMEGA6 records into nut_data
insert or replace into nut_data select f.NDB_No, 2006, ifnull(short6.Nutr_Val, 0.0) + ifnull(long6.Nutr_Val, 0.0) from food_des f left join nut_data short6 on f.NDB_No = short6.NDB_No and short6.Nutr_No = 3003 left join nut_data long6 on f.NDB_No = long6.NDB_No and long6.Nutr_No = 3004 where short6.Nutr_Val is not null or long6.Nutr_Val is not null;
   --insert OMEGA3 records into nut_data
insert or replace into nut_data select f.NDB_No, 2007, ifnull(short3.Nutr_Val, 0.0) + ifnull(long3.Nutr_Val, 0.0) from food_des f left join nut_data short3 on f.NDB_No = short3.NDB_No and short3.Nutr_No = 3005 left join nut_data long3 on f.NDB_No = long3.NDB_No and long3.Nutr_No = 3006 where short3.Nutr_Val is not null or long3.Nutr_Val is not null;
   --insert CHO_NONFIB records into nut_data
insert or replace into nut_data select f.NDB_No, 2000, case when chocdf.Nutr_Val - ifnull(fibtg.Nutr_Val, 0.0) < 0.0 then 0.0 else chocdf.Nutr_Val - ifnull(fibtg.Nutr_Val, 0.0) end from food_des f left join nut_data chocdf on f.NDB_No = chocdf.NDB_No and chocdf.Nutr_No = 205 left join nut_data fibtg on f.NDB_No = fibtg.NDB_No and fibtg.Nutr_No = 291 where chocdf.Nutr_Val is not null;
   --replace empty strings with values for macronutrient factors in food_des
update food_des set Pro_Factor = 4.0 where Pro_Factor = '' or Pro_Factor is null;
update food_des set Fat_Factor = 9.0 where Fat_Factor = '' or Fat_Factor is null;
update food_des set CHO_Factor = 4.0 where CHO_Factor = '' or CHO_Factor is null;
   --insert calories from macronutrients into nut_data
insert or replace into nut_data select f.NDB_No, 3000, f.Pro_Factor * procnt.Nutr_Val from food_des f join nut_data procnt on f.NDB_No = procnt.NDB_No and procnt.Nutr_No = 203;
insert or replace into nut_data select f.NDB_No, 3001, f.Fat_Factor * fat.Nutr_Val from food_des f join nut_data fat on f.NDB_No = fat.NDB_No and fat.Nutr_No = 204;
insert or replace into nut_data select f.NDB_No, 3002, f.CHO_Factor * chocdf.Nutr_Val from food_des f join nut_data chocdf on f.NDB_No = chocdf.NDB_No and chocdf.Nutr_No = 205;
 /* NUT needs some additional permanent tables for options, mealfoods, archive
   of mealfoods if meals per day changes, customary meals (theusual), and
   the weight log */

/* This table is global options:     defanal_am    how many meals to analyze starting at the latest and going
                  back in time
    FAPU1         the "target" for Omega-6/3 balance
    meals_per_day yes, meals per day
    grams         boolean true means grams, false means ounces avoirdupois and
                  never means fluid ounces
    currentmeal   10 digit integer YYYYMMDDxx where xx is daily meal number
    wltweak       Part of the automatic calorie set feature.  If NUT moves the
                  calories during a cycle to attempt better body composition,
                  wltweak is true.  It is always changed to false at the
                  beginning of a cycle.  However, current algorithm doesn't use it.
    wlpolarity    In order not to favor gaining lean mass over losing fat mass,
                  NUT cycles this between true and false to alternate strategies.
                  However, current algorithm doesn't use it.
    autocal       0 means no autocal feature, 2 means feature turned on.
                  The autocal feature moves calories to try to achieve
                  a calorie level that allows both fat mass loss and lean mass
                  gain.
*/

create table if not exists options(protect integer primary key, defanal_am integer default 2147123119, FAPU1 real default 0.0, meals_per_day int default 3, grams int default 1, currentmeal int default 0, wltweak integer default 0, wlpolarity integer default 0, autocal integer default 0);

/*
   The table of what and how much eaten at each meal, plus a place for a
   nutrient number to signify automatic portion control on this serving.
   Automatic portion control (PCF) means add up everything from this meal
   for this single nutrient and then adjust the quantity of this particular
   food so that the daily value is exactly satisfied.
*/
create table if not exists mealfoods(meal_id int, NDB_No int, Gm_Wgt real, Nutr_No int, primary key(meal_id, NDB_No));

/*   There is no easy way to analyze a meal where each day can have a   different number of meals per day because you have to do a lot of computation
   to combine the meals, and for any particular meal, you cannot provide   guidance because you don't know how many more meals are coming for the day.
   So, when the user changes meals_per_day we archive the non-compliant meals
   (different number of meals per day from new setting)  and restore the
   compliant ones (same number of meals per day as new setting).
*/

create table if not exists archive_mealfoods(meal_id int, NDB_No int, Gm_Wgt real, meals_per_day integer, primary key(meal_id desc, NDB_No asc, meals_per_day));

/* Table of customary meals which also has has Nutr_No for specification of
   PCF or automatic portion control.  We call it z_tu so we can define a
   "theusual" view later to better control user interaction.
*/

create table if not exists z_tu(meal_name text, NDB_No int, Nutr_No int, primary key(meal_name, NDB_No), unique(meal_name, Nutr_No));

/* The weight log.  When the weight log is "cleared" the info is not erased.
   Null cleardates identify the current log.  As we have been doing, we call
   the real table z_wl, so we can have a couple of views that allow us to
   control user interaction, wlog and wlsummary.
*/

create table if not exists z_wl(weight real, bodyfat real, wldate int, cleardate int, primary key(wldate, cleardate));

/* To protect table options from extraneous inserts we create a trigger */

drop trigger if exists protect_options;
create trigger protect_options after insert on options begin delete from options where protect != 1; end;

/* This insert will have no effect if options are already there */

insert into options default values;

drop trigger protect_options;
vacuum;
}
}

#end ComputeDerivedValues
}

set load_logic {

proc load_logic {args} {

dbmem eval {
/*   This begins the NUT application logic which is implemented as SQL
   tables and triggers in order that the NUT code be independent of the
   GUI and its language, be implemented in C for performance,
   and be implemented by SQLite for portability.
*/
begin;
   /*   First we create various tables just for internal computation
    The following tables are for intermediate values in the computation
   of Daily Values
*/
 DROP TABLE if exists z_vars1;
CREATE TABLE z_vars1 (am_cals2gram_pro real, am_cals2gram_fat real, am_cals2gram_cho real, am_alccals real, am_fa2fat real, balance_of_calories int);

DROP TABLE if exists z_vars2;
CREATE TABLE z_vars2 (am_fat_dv_not_boc real, am_cho_nonfib_dv_not_boc real, am_chocdf_dv_not_boc real);

DROP TABLE if exists z_vars3;
CREATE TABLE z_vars3 (am_fat_dv_boc real, am_chocdf_dv_boc real, am_cho_nonfib_dv_boc real);

DROP TABLE if exists z_vars4;
CREATE TABLE z_vars4 (Nutr_No int, dv real, Nutr_Val real);
 /*
  The following table is used in conjunction with recursive triggers to
  compute essential fatty acid reference values
*/ 
DROP TABLE if exists z_n6;
CREATE TABLE z_n6 (n6hufa real, FAPU1 real, pufa_reduction real, iter int, reduce int, p3 real, p6 real, h3 real, h6 real, o real);

/*    The following table is the am analysis minus the currentmeal.  That way,
   we avoid the overhead of reanalyzing everything while we are
   doing automatic portion control.  The "am_analysis" view is the
   sum of the analyses in this table and those in the "rm_analysis"
   table, the analysis of the current meal.  Of course, this means we
   have to redo this table whenever the currentmeal changes to a
   different meal, and we always need to have a good rm_analysis
   before we can see a good am_analysis.
*/
 drop table if exists z_anal;
create table z_anal (Nutr_No int primary key, null_value int, Nutr_Val real);

/*      The following tables and views are intermediates for functions in NUT.
   The prefixes are:
	am	Analyze meals
	rm	Record meals aka currentmeal
*/   
/* An "analysis header" is various info that is not specifically nutrient
   values:
   maxmeal is maximum number of meals the user can get no matter how many he
              asks for
   mealcount is actual number of meals being analyzed
   meals_per_day is yes, meals per day
   firstmeal is earliest meal in the analysis
   lastmeal is latest meal in the analysis
   currentmeal is the current meal as specified in the options table
   caloriebutton - NUT has a calorie button that specifies the calorie DV, so
                   here it is
   macropct is the percentages of protein, carbs, and fat calories in the
               analysis
   n6balance is the supposed percentages of omega-6 and omega-3 in tissue
             phospholipids according to William Lands' equation if these fatty
             acids saturate the phospholipids as they probably do due to
             excessive omega-6 in modern diets
*/

drop table if exists am_analysis_header;
create table am_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebutton text, macropct text, n6balance text);

/* This table lists the nutrient and its computed Daily Value or dv.  It also
   has the cryptically named dvpct_offset which is the percentage by which the
   actual nutrient value is off from 100% of the DV.  So if you have 99% of the
   DV for potassium the dvpct_offset is \
  -1.0, if you have 103% the dvpct_offset
   is 3.0.  So, you get the % of the DV by adding 100.0 to the dvpct_offset.
*/

drop table if exists am_dv;
create table am_dv (Nutr_No int primary key asc, dv real, dvpct_offset real);
   drop table if exists rm_analysis_header;
create table rm_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebutton text, macropct text, n6balance text);

drop table if exists rm_analysis;
create table rm_analysis (Nutr_No int primary key asc, null_value int, Nutr_Val real);

drop table if exists rm_dv;
create table rm_dv (Nutr_No int primary key asc, dv real, dvpct_offset real);

drop view if exists am_analysis;
create view am_analysis as select am.Nutr_No as Nutr_No, case when currentmeal between firstmeal and lastmeal and am.null_value = 1 and rm.null_value = 1 then 1 when currentmeal not between firstmeal and lastmeal and am.null_value = 1 then 1 else 0 end as null_value, case when currentmeal between firstmeal and lastmeal then ifnull(am.Nutr_Val,0.0) + 1.0 / mealcount * ifnull(rm.Nutr_Val, 0.0) else am.Nutr_Val end as Nutr_Val from z_anal am left join rm_analysis rm on am.Nutr_No = rm.Nutr_No join am_analysis_header;
   /*
   PCF is automatic portion control; aka protein/carb/fat which was extended
   to include all DV nutrients.  The idea is you can control macronutrients
   per meal, but also include a modicum of micronutrients for which
   experience has shown that one's diet never achieves the nutrition standard
   otherwise.  PCF means to adjust the quantity of a particular food to
   achieve a particular nutrition standard for an entire meal.  PCF processing
   only applies to the currentmeal and is accomplished by complicated recursive
   triggers instead of linear algebra.

   Triggers for PCF have to be in "user.sqlite3" because if they are always
   turned on, it is impossible to do any bulk update of the database.
*/

/*
   Some of the triggers need repetitive elements since we don't have
   a lot of choices for how they flow.  Thus this table is used to
   to start triggers so we can use the same code in different
   triggers without literally repeating it in every trigger that
   needs it
*/ 
drop table if exists z_trig_ctl;
CREATE TABLE z_trig_ctl(am_analysis_header integer default 0, rm_analysis_header integer default 0, am_analysis_minus_currentmeal integer default 0, am_analysis_null integer default 0, am_analysis integer default 0, rm_analysis integer default 0, rm_analysis_null integer default 0, am_dv integer default 0, PCF_processing integer default 0, block_setting_preferred_weight integer default 0, block_mealfoods_insert_trigger default 0, block_mealfoods_delete_trigger integer default 0);
insert into z_trig_ctl default values;
 /*
   Procedures implemented as triggers started by a true bool in z_trig_ctl
*/ 
drop trigger if exists am_analysis_header_trigger;
CREATE TRIGGER am_analysis_header_trigger after update of am_analysis_header on z_trig_ctl when NEW.am_analysis_header = 1 beginupdate z_trig_ctl set am_analysis_header = 0;
delete from am_analysis_header;
insert into am_analysis_header select (select count(distinct meal_id) from mealfoods) as maxmeal, count(meal_id) as mealcount, meals_per_day, ifnull(min(meal_id),0) as firstmeal, ifnull(max(meal_id),0) as lastmeal, currentmeal, NULL as caloriebutton, NULL as macropct, NULL as n6balance from options left join (select distinct meal_id from mealfoods order by meal_id desc limit (select defanal_am from options));
end;
 drop trigger if exists rm_analysis_header_trigger;
CREATE TRIGGER rm_analysis_header_trigger after update of rm_analysis_header on z_trig_ctl when NEW.rm_analysis_header = 1 beginupdate z_trig_ctl set rm_analysis_header = 0;
delete from rm_analysis_header;
insert into rm_analysis_header select maxmeal, case when (select count(*) from mealfoods where meal_id = currentmeal) = 0 then 0 else 1 end as mealcount, meals_per_day, currentmeal as firstmeal, currentmeal as lastmeal, currentmeal as currentmeal, NULL as caloriebutton, '0 / 0 / 0' as macropct, '0 / 0' as n6balance from am_analysis_header;
end;
   drop trigger if exists am_analysis_minus_currentmeal_trigger;
CREATE TRIGGER am_analysis_minus_currentmeal_trigger after update of am_analysis_minus_currentmeal on z_trig_ctl when NEW.am_analysis_minus_currentmeal = 1 beginupdate z_trig_ctl set am_analysis_minus_currentmeal = 0;
delete from z_anal;
insert into z_anal select Nutr_No, case when sum(mhectograms * Nutr_Val) is null then 1 else 0 end, ifnull(sum(mhectograms * Nutr_Val), 0.0) from (select NDB_No, total(Gm_Wgt / 100.0 / mealcount * meals_per_day) as mhectograms from mealfoods join am_analysis_header where meal_id between firstmeal and lastmeal and meal_id != currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
end;
 /*  We need null triggers because processing is so different when the analysis
    is null; i.e. there is no food in the analysis.
*/

drop trigger if exists am_analysis_null_trigger;
CREATE TRIGGER am_analysis_null_trigger after update of am_analysis_null on z_trig_ctl when NEW.am_analysis_null = 1 beginupdate z_trig_ctl set am_analysis_null = 0;
delete from z_anal;
insert into z_anal select nutr_no, 1, 0.0 from nutr_def join am_analysis_header where firstmeal = currentmeal and lastmeal = currentmeal;
insert into z_anal select nutr_no, 0, 0.0 from nutr_def join am_analysis_header where firstmeal != currentmeal or lastmeal != currentmeal;
update am_analysis_header set macropct = '0 / 0 / 0', n6balance = '0 / 0';
end;
  drop trigger if exists rm_analysis_null_trigger;
CREATE TRIGGER rm_analysis_null_trigger after update of rm_analysis_null on z_trig_ctl when NEW.rm_analysis_null = 1 beginupdate z_trig_ctl set rm_analysis_null = 0;
delete from rm_analysis;
insert into rm_analysis select Nutr_No, 0, 0.0 from nutr_def;
update rm_analysis_header set caloriebutton = (select caloriebutton from am_analysis_header), macropct = '0 / 0 / 0', n6balance = '0 / 0';
end;

/*   These triggers are gnarly because many DVs require the results of other DVs
   so it takes many steps.  And also, figuring the omega-6/3 balance and
   the essential fatty acid DVs requires division; however, the values
   themselves are often the divisors so we get division by zero unless we fudge
   and put a trace of the nutrient in when the value is actually zero.  Plus
   we need a lot of joins to get all the necessary nutrient values together
   for computation.
*/
 drop trigger if exists am_analysis_trigger;
CREATE TRIGGER am_analysis_trigger after update of am_analysis on z_trig_ctl when NEW.am_analysis = 1 beginupdate z_trig_ctl set am_analysis = 0;
update am_analysis_header set macropct = (select cast (ifnull(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) from am_analysis ENERC_KCAL join am_analysis PROT_KCAL on ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join am_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join am_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001);
delete from z_n6;
insert into z_n6 select NULL, NULL, NULL, 1, 1, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end from am_analysis SHORT3 join am_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 on LONG3.Nutr_No = 3006 join am_analysis LONG6 on LONG6.Nutr_No = 3004 join am_analysis FAPUval on FAPUval.Nutr_No = 646 join am_analysis FASAT on FASAT.Nutr_No = 606 join am_analysis FAMS on FAMS.Nutr_No = 645 join am_analysis FAPU on FAPU.Nutr_No = 646 join am_analysis ENERC_KCAL on ENERC_KCAL.Nutr_No = 208;
update am_analysis_header set n6balance = (select case when n6hufa_int = 0 or n6hufa_int is null then 0 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end || ' / ' || (100 - case when n6hufa_int = 0 then 100 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end) from (select cast (round(n6hufa,0) as int) as n6hufa_int from z_n6));
update am_analysis_header set n6balance = case when n6balance is null then '0 / 0' else n6balance end;
end;

drop trigger if exists rm_analysis_trigger;
CREATE TRIGGER rm_analysis_trigger after update of rm_analysis on z_trig_ctl when NEW.rm_analysis = 1 beginupdate z_trig_ctl set rm_analysis = 0;
delete from rm_analysis;
insert into rm_analysis select Nutr_No, case when sum(mhectograms * Nutr_Val) is null then 1 else 0 end, ifnull(sum(mhectograms * Nutr_Val), 0.0) from (select NDB_No, total(Gm_Wgt / 100.0 * meals_per_day) as mhectograms from mealfoods join am_analysis_header where meal_id = currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
update rm_analysis_header set caloriebutton = (select caloriebutton from am_analysis_header), macropct = (select cast (ifnull(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) from rm_analysis ENERC_KCAL join rm_analysis PROT_KCAL on ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join rm_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join rm_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001);
delete from z_n6;
insert into z_n6 select NULL, NULL, NULL, 1, 1, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end from rm_analysis SHORT3 join rm_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join rm_analysis LONG3 on LONG3.Nutr_No = 3006 join rm_analysis LONG6 on LONG6.Nutr_No = 3004 join rm_analysis FAPUval on FAPUval.Nutr_No = 646 join rm_analysis FASAT on FASAT.Nutr_No = 606 join rm_analysis FAMS on FAMS.Nutr_No = 645 join rm_analysis FAPU on FAPU.Nutr_No = 646 join rm_analysis ENERC_KCAL on ENERC_KCAL.Nutr_No = 208;
update rm_analysis_header set n6balance = (select case when n6hufa_int = 0 or n6hufa_int is null then 0 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end || ' / ' || (100 - case when n6hufa_int = 0 then 100 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end) from (select cast (round(n6hufa,0) as int) as n6hufa_int from z_n6));
end;

drop trigger if exists am_dv_trigger;
CREATE TRIGGER am_dv_trigger after update of am_dv on z_trig_ctl when NEW.am_dv = 1 beginupdate z_trig_ctl set am_dv = 0;
delete from am_dv;
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select Nutr_No, Nutr_Val, case when nutopt = 0.0 then dv_default when nutopt = \
  -1.0 and Nutr_Val > 0.0 then Nutr_Val when nutopt = \
  -1.0 and Nutr_Val <= 0.0 then dv_default else nutopt end as dv from nutr_def natural join am_analysis where dv_default > 0.0 and (Nutr_No = 208 or Nutr_No between 301 and 601 or Nutr_No = 2008));
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select Nutr_No, Nutr_Val, case when nutopt = 0.0 and (select dv from am_dv where Nutr_No = 208) > 0.0 then (select dv from am_dv where Nutr_No = 208) / 2000.0 * dv_default when nutopt = 0.0 then dv_default when nutopt = \
  -1.0 and Nutr_Val > 0.0 then Nutr_Val when nutopt = \
  -1.0 and Nutr_Val <= 0.0 then (select dv from am_dv where Nutr_No = 208) / 2000.0 * dv_default else nutopt end as dv from nutr_def natural join am_analysis where Nutr_No = 291);
delete from z_vars1;
insert into z_vars1 select ifnull(PROT_KCAL.Nutr_Val / PROCNT.Nutr_Val, 4.0), ifnull(FAT_KCAL.Nutr_Val / FAT.Nutr_Val, 9.0), ifnull(CHO_KCAL.Nutr_Val / CHOCDF.Nutr_Val, 4.0), ifnull(ALC.Nutr_Val * 6.93, 0.0), ifnull((FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val) / FAT.Nutr_Val, 0.94615385), case when ENERC_KCALopt.nutopt = \
  -1 then 208 when FATopt.nutopt <= 0.0 and CHO_NONFIBopt.nutopt = 0.0 then 2000 else 204 end from am_analysis PROT_KCAL join am_analysis PROCNT on PROT_KCAL.Nutr_No = 3000 and PROCNT.Nutr_No = 203 join am_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001 join am_analysis FAT on FAT.Nutr_No = 204 join am_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join am_analysis CHOCDF on CHOCDF.Nutr_No = 205 join am_analysis ALC on ALC.Nutr_No = 221 join am_analysis FASAT on FASAT.Nutr_No = 606 join am_analysis FAMS on FAMS.Nutr_No = 645 join am_analysis FAPU on FAPU.Nutr_No = 646 join nutr_def ENERC_KCALopt on ENERC_KCALopt.Nutr_No = 208 join nutr_def FATopt on FATopt.Nutr_No = 204 join nutr_def CHO_NONFIBopt on CHO_NONFIBopt.Nutr_No = 2000;
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select PROCNTnd.Nutr_No, case when (PROCNTnd.nutopt = 0.0 and ENERC_KCAL.dv > 0.0) or (PROCNTnd.nutopt = \
  -1.0 and PROCNT.Nutr_Val <= 0.0) then PROCNTnd.dv_default * ENERC_KCAL.dv / 2000.0 when PROCNTnd.nutopt > 0.0 then PROCNTnd.nutopt else PROCNT.Nutr_Val end as dv, PROCNT.Nutr_Val from nutr_def PROCNTnd natural join am_analysis PROCNT join z_vars1 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 where PROCNTnd.Nutr_No = 203);
delete from z_vars2;
insert into z_vars2 select am_fat_dv_not_boc, am_cho_nonfib_dv_not_boc, am_cho_nonfib_dv_not_boc + FIBTGdv from (select case when FATnd.nutopt = \
  -1 and FAT.Nutr_Val > 0.0 then FAT.Nutr_Val when FATnd.nutopt > 0.0 then FATnd.nutopt else FATnd.dv_default * ENERC_KCAL.dv / 2000.0 end as am_fat_dv_not_boc, case when CHO_NONFIBnd.nutopt = \
  -1 and CHO_NONFIB.Nutr_Val > 0.0 then CHO_NONFIB.Nutr_Val when CHO_NONFIBnd.nutopt > 0.0 then CHO_NONFIBnd.nutopt else (CHOCDFnd.dv_default * ENERC_KCAL.dv / 2000.0) - FIBTG.dv end as am_cho_nonfib_dv_not_boc, FIBTG.dv as FIBTGdv from z_vars1 join am_analysis FAT on FAT.Nutr_No = 204 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join nutr_def FATnd on FATnd.Nutr_No = 204 join nutr_def CHOCDFnd on CHOCDFnd.Nutr_No = 205 join nutr_def CHO_NONFIBnd on CHO_NONFIBnd.Nutr_No = 2000 join am_analysis CHO_NONFIB on CHO_NONFIB.Nutr_No = 2000 join am_dv FIBTG on FIBTG.Nutr_No = 291);
delete from z_vars3;
insert into z_vars3 select am_fat_dv_boc, am_chocdf_dv_boc, am_chocdf_dv_boc - FIBTGdv from (select (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_chocdf_dv_not_boc * am_cals2gram_cho)) / am_cals2gram_fat as am_fat_dv_boc, (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_fat_dv_not_boc * am_cals2gram_fat)) / am_cals2gram_cho as am_chocdf_dv_boc, FIBTG.dv as FIBTGdv from z_vars1 join z_vars2 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_dv PROCNT on PROCNT.Nutr_No = 203 join am_dv FIBTG on FIBTG.Nutr_No = 291);
insert into am_dv select Nutr_No, case when balance_of_calories = 204 then am_fat_dv_boc else am_fat_dv_not_boc end, case when balance_of_calories = 204 then 100.0 * Nutr_Val / am_fat_dv_boc - 100.0 else 100.0 * Nutr_Val / am_fat_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 204 natural join am_analysis;
insert into am_dv select Nutr_No, case when balance_of_calories = 2000 then am_cho_nonfib_dv_boc else am_cho_nonfib_dv_not_boc end, case when balance_of_calories = 2000 then 100.0 * Nutr_Val / am_cho_nonfib_dv_boc - 100.0 else 100.0 * Nutr_Val / am_cho_nonfib_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 2000 natural join am_analysis;
insert into am_dv select Nutr_No, case when balance_of_calories = 2000 then am_chocdf_dv_boc else am_chocdf_dv_not_boc end, case when balance_of_calories = 2000 then 100.0 * Nutr_Val / am_chocdf_dv_boc - 100.0 else 100.0 * Nutr_Val / am_chocdf_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 205 natural join am_analysis;
insert into am_dv select FASATnd.Nutr_No, case when FASATnd.nutopt = \
  -1.0 and FASAT.Nutr_Val > 0.0 then FASAT.Nutr_Val when FASATnd.nutopt > 0.0 then FASATnd.nutopt else ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default end, case when FASATnd.nutopt = \
  -1.0 and FASAT.Nutr_Val > 0.0 then 0.0 when FASATnd.nutopt > 0.0 then 100.0 * FASAT.Nutr_Val / FASATnd.nutopt - 100.0 else 100.0 * FASAT.Nutr_Val / (ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default) - 100.0 end from z_vars1 join nutr_def FASATnd on FASATnd.Nutr_No = 606 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_analysis FASAT on FASAT.Nutr_No = 606;
insert into am_dv select FAPUnd.Nutr_No, case when FAPUnd.nutopt = \
  -1.0 and FAPU.Nutr_Val > 0.0 then FAPU.Nutr_Val when FAPUnd.nutopt > 0.0 then FAPUnd.nutopt else ENERC_KCAL.dv * 0.04 / am_cals2gram_fat end, case when FAPUnd.nutopt = \
  -1.0 and FAPU.Nutr_Val > 0.0 then 0.0 when FAPUnd.nutopt > 0.0 then 100.0 * FAPU.Nutr_Val / FAPUnd.nutopt - 100.0 else 100.0 * FAPU.Nutr_Val / (ENERC_KCAL.dv * 0.04 / am_cals2gram_fat) - 100.0 end from z_vars1 join nutr_def FAPUnd on FAPUnd.Nutr_No = 646 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_analysis FAPU on FAPU.Nutr_No = 646;
insert into am_dv select FAMSnd.Nutr_No, (FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv, 100.0 * FAMS.Nutr_Val / ((FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv) - 100.0 from z_vars1 join am_dv FAT on FAT.Nutr_No = 204 join am_dv FASAT on FASAT.Nutr_No = 606 join am_dv FAPU on FAPU.Nutr_No = 646 join nutr_def FAMSnd on FAMSnd.Nutr_No = 645 join am_analysis FAMS on FAMS.Nutr_No = 645;
delete from z_n6;
insert into z_n6 select NULL, case when FAPU1 = 0.0 then 50.0 when FAPU1 < 15.0 then 15.0 when FAPU1 > 90.0 then 90.0 else FAPU1 end, case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 1, 0, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv / case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv / case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 900.0 * (FASAT.dv + FAMS.dv + FAPU.dv - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / ENERC_KCAL.dv from am_analysis SHORT3 join am_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 on LONG3.Nutr_No = 3006 join am_analysis LONG6 on LONG6.Nutr_No = 3004 join am_analysis FAPUval on FAPUval.Nutr_No = 646 join am_dv FASAT on FASAT.Nutr_No = 606 join am_dv FAMS on FAMS.Nutr_No = 645 join am_dv FAPU on FAPU.Nutr_No = 646 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join options;
delete from z_vars4;
insert into z_vars4 select Nutr_No, case when Nutr_Val > 0.0 and reduce = 3 then Nutr_Val / pufa_reduction when Nutr_Val > 0.0 and reduce = 6 then Nutr_Val / pufa_reduction - Nutr_Val / pufa_reduction * 0.01 * (iter - 1) else dv_default end, Nutr_Val from nutr_def natural join am_analysis join z_n6 where Nutr_No in (2006, 2001, 2002);
insert into z_vars4 select Nutr_No, case when Nutr_Val > 0.0 and reduce = 6 then Nutr_Val when Nutr_Val > 0.0 and reduce = 3 then Nutr_Val - Nutr_Val * 0.01 * (iter - 2) else dv_default end, Nutr_Val from nutr_def natural join am_analysis join z_n6 where Nutr_No in (2007, 2003, 2004, 2005);
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from z_vars4;
update am_analysis_header set caloriebutton = 'Calories (' || (select cast (round(dv) as int) from am_dv where Nutr_No = 208) || ')';
delete from rm_dv;
insert into rm_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from rm_analysis natural join am_dv;
insert or replace into mealfoods select meal_id, NDB_No, Gm_Wgt - dv * dvpct_offset / (select meals_per_day from options) / Nutr_Val, Nutr_No from rm_dv natural join nut_data natural join mealfoods where abs(dvpct_offset) > 0.001 order by abs(dvpct_offset) desc limit 1;
end;

/*
  This view is NUT's idea how to update mealfoods to achieve portion control.
  We need it now because it is referenced in the following trigger.
*/

drop view if exists z_pcf;
create view z_pcf as select meal_id,NDB_No, Gm_Wgt + dv / meals_per_day * dvpct_offset / Nutr_Val * \
  -1.0 as Gm_Wgt, Nutr_No
from mealfoods natural join rm_dv natural join nut_data join optionswhere abs(dvpct_offset) >= 0.05 order by abs(dvpct_offset);

drop trigger if exists PCF_processing;
CREATE TRIGGER PCF_processing after update of PCF_processing on z_trig_ctl when NEW.PCF_processing = 1 beginupdate z_trig_ctl set PCF_processing = 0;
replace into mealfoods select * from z_pcf limit 1;
update z_trig_ctl set block_mealfoods_delete_trigger = 0;
end;
 /*
   Now start the actual triggers that kick off when something happens.
   They replay the previous procedures as required by the different
   circumstances that update the appropriate column in z_trig_ctl to true.
*/ 
/*
   Update to defanal_am in options (number of meals to analyze)
   so we need to rewrite the am_analysis and am_dv and thus practically
   everything
*/
 drop trigger if exists defanal_am_trigger;
CREATE TRIGGER defanal_am_trigger after update of defanal_am on options beginupdate z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;
 /*
   Update to currentmeal in options
   so we need to rewrite practically everything
*/ 
drop trigger if exists currentmeal_trigger;
CREATE TRIGGER currentmeal_trigger after update of currentmeal on options beginupdate mealfoods set Nutr_No = null where Nutr_No is not null;
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;
 /*
   Input: table z_n6 to compute column n6hufa
   Output column:  n6hufa
   Purpose:  First step to set reference value for essential fatty acids
             Compute Lands' n6hufa % and set up for following triggers to
             determine reference values
*/
drop trigger if exists z_n6_insert_trigger;
CREATE TRIGGER z_n6_insert_trigger after insert on z_n6 beginupdate z_n6 set n6hufa = (select 100.0 / (1.0 + 0.0441 / p6 * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + h3 / 3.0))), reduce = 0, iter = 0;
end;
   /*
   Input:  If column "reduce" is set right, this trigger recursively
           subtracts omega-6 fatty acids to produce n6hufa numbers to match the
           option for Omega-6/3 balance
   Output:  recursive
   Purpose:  determine daily values for n-6 when we know n-6 is excessive
             because n6hufa > target FAPU1 from options
*/

drop trigger if exists z_n6_reduce6_trigger;
CREATE TRIGGER z_n6_reduce6_trigger after update on z_n6 when NEW.n6hufa > OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 6) beginupdate z_n6 set iter = iter + 1, reduce = 6, n6hufa = (select 100.0 / (1.0 + 0.0441 / (p6 - iter * .01 * p6) * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / (h6 - iter * .01 * h6) * (1.0 + h3 / 3.0)));
end;
   /*
   Input:  If column "reduce" is set right, this trigger recursively
           subtracts omega-3 fatty acids to produce n6hufa numbers to match the
           option for Omega-6/3 balance
   Output:  recursive
   Purpose:  determine daily values for n-3 when we know n-3 is excessive
             because n6hufa < target FAPU1
*/
 drop trigger if exists z_n6_reduce3_trigger;
CREATE TRIGGER z_n6_reduce3_trigger after update of n6hufa on z_n6 when NEW.n6hufa < OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 3) beginupdate z_n6 set iter = iter + 1, reduce = 3, n6hufa = (select 100.0 / (1.0 + 0.0441 / p6 * (1.0 + (p3 - iter * .01 * p3) / 0.0555 + (h3 - iter * .01 * h3) / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + (h3 - iter * .01 * h3) / 3.0)));
end;
   /*
  First insert into currentmeal is special because it changes everything!
*/

drop trigger if exists insert_mealfoods_trigger;
CREATE TRIGGER insert_mealfoods_trigger after insert on mealfoods when NEW.meal_id = (select currentmeal from options) and (select count(*) from mealfoods where meal_id = NEW.meal_id) = 1 beginupdate z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;
 /*
  Last delete from currentmeal is special because it changes everything!
*/
 drop trigger if exists delete_mealfoods_trigger;
CREATE TRIGGER delete_mealfoods_trigger after delete on mealfoods when OLD.meal_id = (select currentmeal from options) and (select count(*) from mealfoods where meal_id = OLD.meal_id) = 0 beginupdate mealfoods set Nutr_No = null where Nutr_No is not null;
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;
 /*
  Input: mealfoods modified Gm_Wgt
  Output: weight Gm_Wgt
  Purpose:  NUT remembers user serving size preference in first weight record
            when ordered by Seq (although origSeq is the actual key).
*/
   drop trigger if exists update_mealfoods2weight_trigger;
CREATE TRIGGER update_mealfoods2weight_trigger AFTER UPDATE ON mealfoods when NEW.Gm_Wgt > 0.0 and (select block_setting_preferred_weight from z_trig_ctl) = 0 BEGINupdate weight set Gm_Wgt = NEW.Gm_Wgt where NDB_No = NEW.NDB_No and Seq = (select min(Seq) from weight where NDB_No = NEW.NDB_No) ;
end;
   drop trigger if exists insert_mealfoods2weight_trigger;
CREATE TRIGGER insert_mealfoods2weight_trigger AFTER INSERT ON mealfoods when NEW.Gm_Wgt > 0.0 and (select block_setting_preferred_weight from z_trig_ctl) = 0 BEGINupdate weight set Gm_Wgt = NEW.Gm_Wgt where NDB_No = NEW.NDB_No and Seq = (select min(Seq) from weight where NDB_No = NEW.NDB_No) ;
end;
      /*
  If you follow the weight saga so far, you realize that if the user wants to
  always see a different serving unit, you have to change the Seq to 0 for that
  record.  Here are convenience triggers that change the current Seq = 0
  record back to the original Seq immediately before the change so you don't
  have to explicitly do it:
*/

drop trigger if exists update_weight_Seq;
create trigger update_weight_Seq BEFORE update of Seq on weight when NEW.Seq = 0 BEGIN
update weight set Seq = origSeq, Gm_Wgt = origGm_Wgt where NDB_No = NEW.NDB_No;
end;

drop trigger if exists insert_weight_Seq;
create trigger insert_weight_Seq BEFORE insert on weight when NEW.Seq = 0 BEGIN
update weight set Seq = origSeq, Gm_Wgt = origGm_Wgt where NDB_No = NEW.NDB_No;
end;

/*
  Now we need some stuff to support the weight log mini-application.  First,
  a view to figure the slope and y-intercept of uncleared weight records.
  The slope is the average daily weight gain or loss in the user's units,
  whatever they might be; the y-intercept is the prediction for today; and
  finally we present "n" which is the sample count.  We use linear regression
  to get all these values.
*/

drop view if exists z_wslope;
CREATE VIEW z_wslope as select ifnull(weightslope,0.0) as "weightslope", ifnull(round(sumy / n - weightslope * sumx / n,1),0.0) as "weightyintercept", n as "weightn" from (select (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as weightslope, sumy, n, sumx from (select sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n from (select cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, weight as y, cast ((select count(*) from z_wl where cleardate is null) as real) as n from z_wl where cleardate is null)));

/*
  Basically the same thing for the slope, y-intercept, and "n" of fat mass.
*/

drop view if exists z_fslope;
CREATE VIEW z_fslope as select ifnull(fatslope,0.0) as "fatslope", ifnull(round(sumy / n - fatslope * sumx / n,1),0.0) as "fatyintercept", n as "fatn" from (select (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as fatslope, sumy, n, sumx from (select sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n from (select cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, bodyfat * weight / 100.0 as y, cast ((select count(*) from z_wl where ifnull(bodyfat,0.0) > 0.0 and cleardate is null) as real) as n from z_wl where ifnull(bodyfat,0.0) > 0.0 and cleardate is null)));

/*
  In our computations we not only need the number of samples, we also need the
  "span" which enumerates how many days from the first measurement to the
  present.
*/

drop view if exists z_span;
create view z_span as select abs(min(cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int))) as span from z_wl where cleardate is null;

/*
  Here's the user's view of the weight log which we provide only so we can
  control inserts.
*/

drop view if exists wlog;
create view wlog as select * from z_wl;

/*
  Insert to wlog.  User supplies weight and bodyfat percentage plus two
  nulls, but we supply today's date.
*/

drop trigger if exists wlog_insert;
create trigger wlog_insert instead of insert on wlog begin
insert or replace into z_wl values (NEW.weight, NEW.bodyfat, (select strftime('%Y%m%d', 'now', 'localtime')), null);
end;

/*
  Here's the user's view of the weight log with some additional interesting
  columns.
*/

drop view if exists wlview;
CREATE VIEW wlview as select wldate, weight, bodyfat, round(weight - weight * bodyfat / 100, 1) as leanmass, round(weight * bodyfat / 100, 1) as fatmass, round(weight - 2 * weight * bodyfat / 100) as bodycomp, cleardate from z_wl;

/*
  Here's the verbiage associated with analysis of the user's measurements.
*/

drop view if exists wlsummary;
create view wlsummary as select casewhen (select weightn from z_wslope) > 1 then
'Weight:  ' || (select round(weightyintercept,1) from z_wslope) || char(13) || char(10) ||
'Bodyfat:  ' || case when (select weightyintercept from z_wslope) > 0.0 then round(1000.0 * (select fatyintercept from z_fslope) / (select weightyintercept from z_wslope)) / 10.0 else 0.0 end || '%' || char(13) || char(10)
when (select weightn from z_wslope) = 1 then
'Weight:  ' || (select weight from z_wl where cleardate is null) || char(13) || char(10) ||'Bodyfat:  ' || (select bodyfat from z_wl where cleardate is null) || '%'
else'Weight:  0.0' || char(13) || char(10) ||'Bodyfat:  0.0%'
end || char(13) || char(10) ||
'Today' || "'" || 's Calorie level = ' || (select cast(round(nutopt) as int) from nutr_def where Nutr_No = 208)
|| char(13) || char(10)
|| char(13) || char(10) ||
case when (select weightn from z_wslope) = 0 then '0 data points so far...'when (select weightn from z_wslope) = 1 then '1 data point so far...'else
'Based on the trend of ' || (select cast(cast(weightn as int) as text) from z_wslope) || ' data points so far...' || char(13) || char(10) || char(10) ||
'Predicted lean mass today = ' ||
(select cast(round(10.0 * (weightyintercept - fatyintercept)) / 10.0 as text) from z_wslope, z_fslope) || char(13) || char(10) ||
'Predicted fat mass today  =  ' ||
(select cast(round(fatyintercept, 1) as text) from z_fslope) || char(13) || char(10) || char(10) ||
'If the predictions are correct, you ' ||
case when (select weightslope - fatslope from z_wslope, z_fslope) >= 0.0 then 'gained ' else 'lost ' end ||
(select cast(abs(round((weightslope - fatslope) * span * 1000.0) / 1000.0) as text) from z_wslope, z_fslope, z_span) ||
' lean mass over ' ||
(select span from z_span) ||case when (select span from z_span) = 1 then ' day' else ' days' end || char(13) || char(10) ||
case when (select fatslope from z_fslope) > 0.0 then 'and gained ' else 'and lost ' end ||
(select cast(abs(round(fatslope * span * 1000.0) / 1000.0) as text) from z_fslope, z_span) || ' fat mass.'

end
as verbiage;

/*
  The user indicates he wants to clear the weight log
  with an "insert into wlsummary select 'clear'" but we only actually clear if
  the user is not using the calorie autoset feature.
*/

drop trigger if exists clear_wlsummary;
create trigger clear_wlsummary instead of insert on wlsummary
when (select autocal from options) = 0
begin
update z_wl set cleardate = (select strftime('%Y%m%d', 'now', 'localtime'))
where cleardate is null;
insert into z_wl select weight, bodyfat, wldate, null from z_wl
where wldate = (select max(wldate) from z_wl);
end;

/*
  When the user takes the autocal function, we initialize wltweak, a boolean
  that indicates if calorie level has been "tweaked" and wlpolarity, a boolean
  that bounces between true and false to balance bias between fat mass loss
  and lean mass gain.

  Note:  These bools are not operative in the current version of autocal.
*/

drop trigger if exists autocal_initialization;
create trigger autocal_initialization after update of autocal on options
when NEW.autocal in (1, 2, 3) and OLD.autocal not in (1, 2, 3)
begin
update options set wltweak = 0, wlpolarity = 0;
end;

/*
  Updating meals_per_day on options results in archiving the meals at the old
  meals_per_day and restoring meals archived from the new meals_per_day
*/

drop trigger if exists mpd_archive;
create trigger mpd_archive after update of meals_per_day on options
when NEW.meals_per_day != OLD.meals_per_day
begin
insert or ignore into archive_mealfoods select meal_id, NDB_No, Gm_Wgt, OLD.meals_per_day from mealfoods;
delete from mealfoods;
insert or ignore into mealfoods select meal_id, NDB_No, Gm_Wgt, null from archive_mealfoods where meals_per_day = NEW.meals_per_day;
delete from archive_mealfoods where meals_per_day = NEW.meals_per_day;
update options set defanal_am = (select count(distinct meal_id) from mealfoods);
end;

/*
  Now we're done with setting it all up and we need to initialize after the load
  because NUT expects the analysis to already be there when it comes up.
  So, write the first analysis after a USDA load and initialize nutopts if
  necessary.
*/
 update nutr_def set nutopt = 0.0 where nutopt is null;
update options set currentmeal = case when currentmeal is null then 0 else currentmeal end;
update options set defanal_am = case when defanal_am is null then 0 else defanal_am end;
   /*  SQLite supposedly performs better if it has analyzed how big the tables are
*/

commit;
analyze main;

/*
  End of NUT application logic implemented by SQL tables and triggers
*/

}
}

#end load_logic
}

set InitialLoad {

sqlite3 dbmem :memory:
dbmem function n6hufa n6hufa
dbmem function setRefDesc setRefDesc
dbmem function format_meal_id format_meal_id

if {[catch {dbmem restore main $DiskDB}]} {

# Duplicate the schema of appdata1.xyz into the in-memory db database

 db eval { } {
	SELECT
		sql
	FROM
		sqlite_master
	WHERE
		sql NOT NULL
		and type = 'table'
		and name not like '%sqlite_%'
		dbmem eval $sql
  }

# Copy data content from appdata1.xyz into memory
 dbmem eval {ATTACH $::DiskDB AS app}
 dbmem eval {SELECT name FROM sqlite_master WHERE type='table'} {
  dbmem eval "INSERT INTO $name SELECT * FROM app.$name"
  }
 dbmem eval {DETACH app}
 }

dbmem eval {PRAGMA synchronous = 0}

dbmem progress 1920 {pbprog 1 1.0 }
load_nutr_def

set ::pbar(1) 100.0
dbmem progress 10 {pbprog 2 1.0 }
load_fd_group

set ::pbar(2) 100.0
dbmem progress 8000 {pbprog 3 1.0 }
load_food_des1

dbmem eval {select count(*) as count from food_des} {
 if {$count != 0} {
  dbmem progress 32000 {pbprog 3 1.0 }
  }
 }

set ::pbar(3) 100.0
dbmem progress 9000 {pbprog 4 1.0 }
load_weight

set ::pbar(4) 100.0
set ::pbar(5) 0.5
dbmem progress 26 {pbprog1}
load_nut_data1

dbmem progress 300000 {pbprog 5 1.0 }

set ::pbar(5) 100.0

dbmem progress 240000 {pbprog 6 1.0 }
ComputeDerivedValues dbmem food_des

set ::pbar(6) 100.0
dbmem progress [expr {[dbmem eval {select count(NDB_No) from food_des}] * 120}] {pbprog 7 1.0 }

load_logic

set ::pbar(7) 100.0
dbmem progress 4000 {update}

.loadframe.pbar8 configure \
  -mode indeterminate
.loadframe.pbar8 start
load_legacy

dbmem progress 0 ""
.loadframe.pbar8 stop
.loadframe.pbar8 configure \
  -mode determinate
set ::pbar(8) 80.0
update
dbmem eval {analyze main}
dbmem eval {PRAGMA synchronous = 2}
if {[catch {dbmem backup main $DiskDB}]} {

# Duplicate the schema of appdata1.xyz from the in-memory db database
 set sql_mast [db eval {SELECT name, type FROM sqlite_master where type != 'index'}]
 foreach {name type} $sql_mast {
  db eval "DROP $type if exists $name"
  }
 dbmem eval {SELECT sql FROM sqlite_master WHERE sql NOT NULL and type != 'trigger'} {
  db eval $sql
  }

# Copy data content into appdata1.xyz from memory
 dbmem eval {ATTACH $DiskDB AS app}
 dbmem eval {SELECT name FROM sqlite_master WHERE type='table'} {
  dbmem eval "INSERT INTO app.$name SELECT * FROM $name"
  }
 dbmem eval {SELECT sql FROM sqlite_master WHERE sql NOT NULL and type = 'trigger'} {
  db eval $sql
  }
 dbmem eval {DETACH app}
 }
dbmem close
set ::pbar(8) 90.0
update
db eval {vacuum}
file rename \
  -force "NUTR_DEF.txt" "NUTR_DEF.txt.loaded"
set ::pbar(8) 100.0
update
db eval {select code from z_tcl_code where name = 'Start_NUT'} { }
eval $codewm deiconify .
destroy .loadframe

#end InitialLoad
}

set Start_NUT {

db eval {select code from z_tcl_code where name = 'user_init'} {
 eval $code
 }
thread::send \
  -async $::SQL_THREAD "$code"
thread::send \
  -async $::SQL_THREAD {db eval {delete from z_tcl_jobqueue} ; db nullvalue "\[No Data\]"}


db eval {select Tagname, NutrDesc, case when Units != X'B567' then Units else 'mcg' end as Units from nutr_def} {
 set nut $Tagname
 set ::${nut}b $NutrDesc
 set ::${nut}u $Units
 }

db eval {select count(distinct meal_id) as "::mealcount", case when FAPU1 = 0.0 then 50.0 else FAPU1 end as "::FAPU1", defanal_am from mealfoods, options} {
 if {$defanal_am > 0} {
  set ::meals_to_analyze_am [expr {$defanal_am > $::mealcount ? $::mealcount : $defanal_am}]
  .nut.am.mealsb configure \
  -from 1
  } else {
  set ::meals_to_analyze_am $::mealcount
  if {$::mealcount > 0} {.nut.am.mealsb configure \
  -from 1} else {
   .nut.am.mealsb configure \
  -from 0 \
  -to 0
   }
  }
 if {$::mealcount > 0} {.nut.am.mealsb configure \
  -to $::mealcount}
 }

::trace add variable ::meals_to_analyze_am write SetDefanal

db eval {select grams as "::GRAMSopt" from options} { }
db eval {select '::' || Tagname || 'opt' as tag, nutopt from nutr_def where dv_default > 0.0;} {
 set $tag $nutopt
 }
db eval {select Tagname from nutr_def where dv_default > 0.0} {
 trace add variable ::${Tagname}opt write [list opt_change $Tagname]
 }
db eval {select "::" || Tagname || 'dv' as tag, round(dv, 1) as dv from am_dv natural join nutr_def} {
 set $tag $dv
 }
db eval {select '::' || Tagname || 'am' as tag, case when null_value = 0 then round(Nutr_Val, 1) else null end as val from am_analysis natural join nutr_def} {
 set $tag $val
 }
db eval {select '::' || Tagname || 'amdv' as tag, case when null_value = 0 then cast(round(100.0 + dvpct_offset, 0) as int) else null end as val from am_analysis natural join am_dv natural join nutr_def} {
 set $tag $val
 }
db eval {select maxmeal as "::mealcount", caloriebutton as "::caloriebutton", format_meal_id(firstmeal) as "::FIRSTMEALam", firstmeal as "::FIRSTMEALts", format_meal_id(lastmeal) as "::LASTMEALam", n6balance as "::FAPU1am", macropct as "::ENERC_KCAL1am" from am_analysis_header} { }
db eval {select case when null_value = 0 then cast(round(Nutr_Val, 0) as int) else null end as "::CHO_NONFIBam1" from am_analysis where Nutr_No = 2000} { }

db eval {select '::' || Tagname || 'rm' as tag from nutr_def} {
 set $tag 0.0
 }
db eval {select '::' || Tagname || 'rmdv' as tag from nutr_def where dv_default > 0.0} {
 set $tag 0
 }
set ::FAPU1rm "0 / 0"
set ::ENERC_KCAL1rm "0 / 0 / 0"
set ::CHO_NONFIBrm1 0

db eval {select '::' || Tagname || 'vfdv' as tag, 0 as val from nutr_def where dv_default > 0.0} {
 set $tag $val
 }

db eval {select '::' || Tagname || 'vf' as tag, 0.0 as val from nutr_def} {
 set $tag $val
 }

set ::ENERC_KCAL1vf "0 / 0 / 0"
set ::FAPU1vf "0 / 0"
set ::CHO_NONFIBvf1 0

db nullvalue "\[No Data\]"

SetMealBase
set ::rmMainPane .nut.rm.nbw

::trace add variable ::GRAMSopt write GO_change

set ::rankchoices { {Foods Ranked per 100 Grams} {Foods Ranked per 100 Calories} {Foods Ranked per one approximate Serving} {Foods Ranked per Daily Recorded Meals} }
set ::fdgroupchoices { {All Food Groups} }
db eval {select count(distinct meal_id) as "::mealcount" from mealfoods} { }
if {$::mealcount > 0} {
 set ::rankchoice {Foods Ranked per Daily Recorded Meals}
 } else {
 set ::rankchoice {Foods Ranked per 100 Grams}
 }
set ::fdgroupchoice {All Food Groups}
.nut.ts.rankchoice configure \
  -textvariable ::rankchoice \
  -values $::rankchoices

db eval {select FdGrp_Desc as fg from fd_group order by FdGrp_Desc} {
 lappend ::fdgroupchoices $fg
 }
.nut.ts.fdgroupchoice configure \
  -values $::fdgroupchoices
trace add variable ::rankchoice write [list NewStoryLater NULL ts]
trace add variable ::fdgroupchoice write [list NewStoryLater NULL ts]

menu .nut.rm.setmpd.m \
  -tearoff 0 \
  -background "#FF9428"
if {$::meals_per_day != 1} {
 .nut.rm.setmpd.m add command \
  -label "Set 1 meal per day" \
  -command [list SetMPD 1]
 } else {
 .nut.rm.setmpd.m add command \
  -label "Set 1 meal per day" \
  -command [list SetMPD 1] \
  -state disabled
 }
for {set i 2} {$i < 20} {incr i} {
 if {$i != $::meals_per_day} {
  .nut.rm.setmpd.m add command \
  -label "Set $i meals per day" \
  -command [list SetMPD $i]
  } else {
  .nut.rm.setmpd.m add command \
  -label "Set $i meals per day" \
  -command [list SetMPD $i] \
  -state disabled
  }
 }

if {!$::ALTGUI} {
 after 1000 {.nut.vf.frlistbox configure \
  -height [winfo height .nut.vf.nbw]}
 after 1000 {.nut.vf.frlistbox configure \
  -width [winfo width .nut.vf.nbw]}
 after 1000 {.nut.rm.frlistbox configure \
  -height [winfo height .nut.rm.nbw]}
 after 1000 {.nut.rm.frlistbox configure \
  -width [winfo width .nut.rm.nbw]}
 after 1000 {.nut.rm.frmenu configure \
  -height [winfo height .nut.rm.nbw]}
 after 1000 {.nut.rm.frmenu configure \
  -width [winfo width .nut.rm.nbw]}
 after 1000 {.nut.po.pane configure \
  -handlepad [expr 8 * {[winfo height .nut] / 19}]}
 after 1000 {.nut.po.pane configure \
  -height [expr {145 * [winfo height .nut] / 152}]}
 after 1000 {.nut.po.pane configure \
  -width [winfo width .nut.rm.nbw]}
 after 1000 {.nut.po.pane paneconfigure .nut.po.pane.wlogframe \
  -sticky ne}
 }

if {$::mealcount == 0} {
 db eval {select FAPU1 as "::FAPU1" from options} { }
 }
after 2000 InitializePersonalOptions
if {$::FAPU1rm == "\[No Data\]"} {
 thread::send \
  -async $::GUI_THREAD [list set ::FAPU1rm "0 / 0"]
 }
if {$::ENERC_KCAL1rm == "\[No Data\]"} {
 thread::send \
  -async $::GUI_THREAD [list set ::ENERC_KCAL1rm "0 / 0 / 0"]
 }

#end Start_NUT
}

set user_init {

db eval {
/*
  User initiated stuff goes here.  The following PRAGMA is essential at each
  invocation, but most of the stuff in this file isn't strictly necessary.  If it is
  necessary, with the exception of automatic portion control and weight log, it should go into  logic.sqlite3.  Just about everything in this init file is and should be "temp" so
  it goes away for you if you close the database connection, but it doesn't go away for the
  other connections that came in with the same user init.  The only exception is the
  shopping list which needs to be persistent.
*/

PRAGMA recursive_triggers = 1;

begin;

/*
  HEERE BEGYNNETH AUTOMATIC PORTION CONTROL (PCF)
*/

/*
  If a mealfoods replace causes the delete trigger to start, we get a
  recursive nightmare.  So we need a before insert trigger.
*/

drop trigger if exists before_mealfoods_insert_pcf;
create temp trigger before_mealfoods_insert_pcf before insert on mealfoods
when (select block_mealfoods_insert_trigger from z_trig_ctl) = 0
begin
update z_trig_ctl set block_mealfoods_delete_trigger = 1;
end;

/*
  A mealfoods insert trigger
*/

drop trigger if exists mealfoods_insert_pcf;
create temp trigger mealfoods_insert_pcf after insert on mealfoods
when NEW.meal_id = (select currentmeal from options)
and (select block_mealfoods_insert_trigger from z_trig_ctl) = 0
begin
update z_trig_ctl set rm_analysis = 1;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

/*
  A mealfoods update trigger
*/

drop trigger if exists mealfoods_update_pcf;
create temp trigger mealfoods_update_pcf after update on mealfoods
when OLD.meal_id = (select currentmeal from options)
begin
update z_trig_ctl set rm_analysis = 1;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

/*
  A mealfoods delete trigger
*/

drop trigger if exists mealfoods_delete_pcf;
create temp trigger mealfoods_delete_pcf after delete on mealfoods
when OLD.meal_id = (select currentmeal from options)
and (select block_mealfoods_delete_trigger from z_trig_ctl) = 0
begin
update z_trig_ctl set rm_analysis = 1;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

/*
  Another thing that can start automatic portion control is changing the
  nutopt in nutr_def which will change the Daily Values.  And then the same
  thing for FAPU1 in options.
*/

drop trigger if exists update_nutopt_pcf;
create temp trigger update_nutopt_pcf after update of nutopt on nutr_def
begin
update z_trig_ctl set rm_analysis = 1;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

drop trigger if exists update_FAPU1_pcf;
create temp trigger update_FAPU1_pcf after update of FAPU1 on options
begin
update z_trig_ctl set rm_analysis = 1;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

/*
  HEERE ENDETH AUTOMATIC PORTION CONTROL (PCF)
*/

/*
  We often want to grab the preferred weight for a food so we create a special
  view that dishes it up!  This view delivers the preferred Gm_Wgt and the
  newly computed Amount of the serving unit.  The preferred weight is never
  zero or negative, so if the Gm_Wgt might not be > 0.0 you need special logic.
*/

drop view if exists pref_Gm_Wgt;
create temp view pref_Gm_Wgt as select NDB_No, Seq, Gm_Wgt / origGm_Wgt * Amount as Amount, Msre_Desc, Gm_Wgt, origSeq, origGm_Wgt, Amount as origAmount from weight natural join (select NDB_No, min(Seq) as Seq from weight group by NDB_No);

/*
  Here's an "INSTEAD OF" trigger to allow updating the Gm_Wgt of the
  preferred weight record.
*/

drop trigger if exists pref_weight_Gm_Wgt;
create temp trigger pref_weight_Gm_Wgt instead of update of Gm_Wgt on pref_Gm_Wgt
when NEW.Gm_Wgt > 0.0 begin
update weight set Gm_Wgt = NEW.Gm_Wgt where NDB_No = NEW.NDB_No and Seq =
(select min(Seq) from weight where NDB_No = NEW.NDB_No);
end;
 /*
  This is a variant of the previous trigger to change the preferred Gm_Wgt
  of a food by specifying the Amount of the serving unit, the Msre_Desc.
  In addition, it proffers an update to the Gm_Wgt of the food in the
  current meal, just in case that is the reason for the update.
*/

drop trigger if exists pref_weight_Amount;
create temp trigger pref_weight_Amount instead of update of Amount on pref_Gm_Wgt
when NEW.Amount > 0.0 begin
update weight set Gm_Wgt = origGm_Wgt * NEW.Amount / Amount
where NDB_No = NEW.NDB_No and
Seq = (select min(Seq) from weight where NDB_No = NEW.NDB_No);
update currentmeal set Gm_Wgt = null where NDB_No = NEW.NDB_No;
end;
 /*
  Using the preferred weight, we can View Foods in various ways.
*/

drop view if exists view_foods;
create temp view view_foods as select NutrDesc, NDB_No, substr(Shrt_Desc,1,45), round(Nutr_Val * Gm_Wgt / 100.0,1) as Nutr_Val, Units, cast(cast(round(Nutr_Val * Gm_Wgt / dv) as int) as text) || '% DV' from nutr_def natural join nut_data left join am_dv using (Nutr_No) natural join food_des natural join pref_Gm_Wgt;

/*
  We create a convenience view of the current meal, aka mealfoods.
*/

drop view if exists currentmeal;
CREATE temp VIEW currentmeal as select mf.NDB_No as NDB_No, case when (select grams from options) then cast (cast (round(mf.Gm_Wgt) as int) as text) || ' g' else cast(round(mf.Gm_Wgt / 28.35 * 8.0) / 8.0 as text) || ' oz' end || ' (' || cast(round(case when mf.Gm_Wgt <= 0.0 or mf.Gm_Wgt != pGW.Gm_Wgt then mf.Gm_Wgt / origGm_Wgt * origAmount else Amount end * 8.0) / 8.0 as text) || ' ' || Msre_Desc || ') ' || Shrt_Desc || ' ' as Gm_Wgt, NutrDesc from mealfoods mf natural join food_des left join pref_Gm_Wgt pGW using (NDB_No) left join nutr_def using (Nutr_No) where meal_id = (select currentmeal from options) order by Shrt_Desc;

/*
  OK, now the INSTEAD OF trigger to simplify somewhat the insertion of a  meal food:
*/

drop trigger if exists currentmeal_insert;
create temp trigger currentmeal_insert instead of insert on currentmeal begin
update mealfoods set Nutr_No = null where Nutr_No = (select Nutr_No from
nutr_def where NutrDesc = NEW.NutrDesc);
insert or replace into mealfoods values ((select currentmeal from options),
NEW.NDB_No, case when NEW.Gm_Wgt is null then (select Gm_Wgt from pref_Gm_Wgt
where NDB_No = NEW.NDB_No) else NEW.Gm_Wgt end, case when NEW.NutrDesc is null
then null when (select count(*) from nutr_def where NutrDesc = NEW.NutrDesc
and dv_default > 0.0) = 1 then (select Nutr_No from nutr_def where NutrDesc
= NEW.NutrDesc) when (select count(*) from nutr_def where Nutr_No =
NEW.NutrDesc and dv_default > 0.0) = 1 then NEW.NutrDesc else null end);
end;

/*
  It's simpler to delete a mealfood with currentmeal than to just delete
  it from mealfoods because you don't have to specify the meal_id.
*/

drop trigger if exists currentmeal_delete;
create temp trigger currentmeal_delete instead of delete on currentmeal begin
delete from mealfoods where meal_id = (select currentmeal from options)
and NDB_No = OLD.NDB_No;
end;

/*
  We often want to update a Gm_Wgt in the current meal.
*/

drop trigger if exists currentmeal_upd_Gm_Wgt;
create temp trigger currentmeal_upd_Gm_Wgt instead of update of Gm_Wgt on
currentmeal begin
update mealfoods set Gm_Wgt = case when NEW.Gm_Wgt is null then (select Gm_Wgt from pref_Gm_Wgt where NDB_No = NEW.NDB_No) else NEW.Gm_Wgt end where NDB_No = NEW.NDB_No and
meal_id = (select currentmeal from options);
end;

/*
  And finally, we often want to modify automatic portion control on the
  current meal.
*/

drop trigger if exists currentmeal_upd_pcf;
create temp trigger currentmeal_upd_pcf instead of update of NutrDesc on
currentmeal begin
update mealfoods set Nutr_No = null
where Nutr_No = (select Nutr_No from nutr_def where NutrDesc = NEW.NutrDesc);
update mealfoods set Nutr_No = (select Nutr_No from nutr_def where NutrDesc =
NEW.NutrDesc) where NDB_No = NEW.NDB_No and
meal_id = (select currentmeal from options);
end;

/*
  Here's a convenience view of customary meals, aka theusual
*/

drop view if exists theusual;
create temp view theusual as select meal_name, NDB_No, Gm_Wgt, NutrDesc from
z_tu natural join pref_Gm_Wgt left join nutr_def using (Nutr_No);

/*
  We have the view, now we need the triggers.

  First, we handle inserts from the current meal.
*/

drop trigger if exists theusual_insert;
create temp trigger theusual_insert instead of insert on theusual
when NEW.meal_name is not null and NEW.NDB_No is null and NEW.Gm_Wgt is null
and NEW.NutrDesc is null
begin
delete from z_tu where meal_name = NEW.meal_name;
insert or ignore into z_tu select NEW.meal_name, mf.NDB_No, mf.Nutr_No from mealfoods mf left join nutr_def where meal_id = (select currentmeal from options);
end;

/*
  Now we allow customary meals to be deleted.
*/

drop trigger if exists theusual_delete;
create temp trigger theusual_delete instead of delete on theusual
when OLD.meal_name is not null
begin
delete from z_tu where meal_name = OLD.meal_name;
end;

/*
  Sorry I didn't write triggers to handle each theusual eventuality,
  but you can always work directly on z_tu for your intricate updating needs.
*/

/*
  We create convenience views to report which foods in the meal analysis are
  contributing to a nutrient intake.  Use it like this (for example):
	select * from nut_in_meals where NutrDesc = 'Protein';
	select * from nutdv_in_meals where NutrDesc = 'Zinc';

  nutdv_in_meals returns nothing if nutrient has no DV

  Then a view of average daily food consumption over the analysis period.
*/

drop view if exists nut_in_meals;
create temp view nut_in_meals as select NutrDesc, round(sum(Gm_Wgt * Nutr_Val / 100.0 / (select mealcount from am_analysis_header) * (select meals_per_day from options)),1) as Nutr_Val, Units, Shrt_Desc from mealfoods mf join food_des using (NDB_No) join nutr_def nd join nut_data data on mf.NDB_No = data.NDB_No and nd.Nutr_No = data.Nutr_No where meal_id >= (select firstmeal from am_analysis_header) group by mf.NDB_No, NutrDesc order by Nutr_Val desc;
drop view if exists nutdv_in_meals;
create temp view nutdv_in_meals as select NutrDesc, cast(cast(round(sum(Gm_Wgt * Nutr_Val / dv / (select mealcount from am_analysis_header) * (select meals_per_day from options))) as int) as text) || '%' as val, Shrt_Desc from mealfoods mf join food_des using (NDB_No) join nutr_def nd join nut_data data on mf.NDB_No = data.NDB_No and nd.Nutr_No = data.Nutr_No join am_dv on nd.Nutr_No = am_dv.Nutr_No where meal_id >= (select firstmeal from am_analysis_header) group by mf.NDB_No, NutrDesc order by cast(val as int) desc;
drop view if exists daily_food;
create temp view daily_food as select cast(round((sum(mf.Gm_Wgt) / mealcount * meals_per_day) / origGm_Wgt * origAmount * 8.0) / 8.0 as text) || ' ' || Msre_Desc || ' ' || Shrt_Desc as food from mealfoods mf natural join food_des join pref_Gm_Wgt using (NDB_No) join am_analysis_header where meal_id between firstmeal and lastmeal group by NDB_No order by Shrt_Desc;

/*
  The actual autocal triggers that run the weight log application have to be
  invoked by the user because they would really run amok during bulk updates.

  The autocal feature is kicked off by an insert to z_wl, the actual weight
  log table.  There are many combinations of responses, each implemented by
  a different trigger.

  First, the proceed or do nothing trigger.
*/

/*
drop trigger if exists autocal_proceed;
create temp trigger autocal_proceed after insert on z_wl
when (select autocal = 2 and weightn > 1 and (weightslope - fatslope) >= 0.0 and fatslope <= 0.0 from z_wslope, z_fslope, z_span, options)
begin
select null;
end;
*/

/*
  Just joking!  It doesn't do anything so we don't need it!  But as we change
  the conditions, the action changes.

  For instance, lean mass is going down or fat mass is going up, so we give up
  on this cycle and clear the weightlog to move to the next cycle.
  We always add a new entry to get a head start on the next cycle, but in this
  case we save the last y-intercepts as the new start.  We also make an
  adjustment to calories:  up 20 calories if both lean mass and fat mass are
  going down, or down 20 calories if they were both going up.  If fat was
  going up and and lean was going down we make no adjustment because, well,
  we just don't know!
*/

drop table if exists wlsave;
create temp table wlsave (weight real, fat real, wldate integer, span integer, today integer);

drop trigger if exists autocal_cutting;
create temp trigger autocal_cutting after insert on z_wl
when (select autocal = 2 and weightn > 1 and fatslope > 0.0 and (weightslope - fatslope) > 0.0 from z_wslope, z_fslope, options)
-- when (select autocal = 2 and weightn > 1 and fatslope > 0.0 and (weightslope - fatslope) > 0.0 and (weightslope - fatslope) < fatslope from z_wslope, z_fslope, options)
begin
delete from wlsave;
insert into wlsave select weightyintercept, fatyintercept, wldate, span, today from z_wslope, z_fslope, z_span, (select min(wldate) as wldate from z_wl where
cleardate is null), (select strftime('%Y%m%d', 'now', 'localtime') as today);
update z_wl set cleardate = (select today from wlsave) where cleardate is null;
insert into z_wl select weight, round(100.0 * fat / weight,1), today, null from wlsave;
update nutr_def set nutopt = nutopt - 20.0 where Nutr_No = 208;
end;

drop trigger if exists autocal_bulking;
create temp trigger autocal_bulking after insert on z_wl
when (select autocal = 2 and weightn > 1 and fatslope < 0.0 and (weightslope - fatslope) < 0.0 from z_wslope, z_fslope, options)
begin
delete from wlsave;
insert into wlsave select weightyintercept, fatyintercept, wldate, span, today from z_wslope, z_fslope, z_span, (select min(wldate) as wldate from z_wl where
cleardate is null), (select strftime('%Y%m%d', 'now', 'localtime') as today);
update z_wl set cleardate = (select today from wlsave) where cleardate is null;
insert into z_wl select weight, round(100.0 * fat / weight,1), today, null from wlsave;
update nutr_def set nutopt = nutopt + 20.0 where Nutr_No = 208;
end;

drop trigger if exists autocal_cycle_end;
create temp trigger autocal_cycle_end after insert on z_wl
when (select autocal = 2 and weightn > 1 and fatslope > 0.0 and (weightslope - fatslope) < 0.0 from z_wslope, z_fslope, options)
begin
delete from wlsave;
insert into wlsave select weightyintercept, fatyintercept, wldate, span, today from z_wslope, z_fslope, z_span, (select min(wldate) as wldate from z_wl where
cleardate is null), (select strftime('%Y%m%d', 'now', 'localtime') as today);
update z_wl set cleardate = (select today from wlsave) where cleardate is null;
insert into z_wl select weight, round(100.0 * fat / weight,1), today, null from wlsave;
end;

/*
  We create a shopping list where the "n" column automatically gives a serial
  number for easy deletion of obtained items, or we can delete by store.
  Insert into the table this way:
	INSERT into shopping values (null, 'potatoes', 'tj');
*/

CREATE TABLE if not exists shopping (n integer primary key, item text, store text);
drop view if exists shopview;
CREATE temp VIEW shopview as select 'Shopping List ' || group_concat(n || ': ' || item || ' (' || store || ')', ' ') from (select * from shopping order by store, item);

/*
  A purely personal view.  max_chick is about portion control for various parts
  of a cut-up chicken.
*/

drop view if exists max_chick;
CREATE temp VIEW max_chick as select NDB_No, Shrt_Desc, round(13.0 / Nutr_Val * 100 / origGm_Wgt * Amount * 8) / 8.0 as Amount, Msre_Desc from food_des natural join nut_data natural join weight where NDB_No > 99000 and Shrt_Desc like '%chick%mic%' and Nutr_No = 203 and Seq = (select min(Seq) from weight where NDB_No = food_des.NDB_No);

/*
  View showing daily macros and body composition index
*/

drop view if exists daily_macros;
create temp view daily_macros as
select day, round(sum(calories)) as calories,
cast(round(100.0 * sum(procals) / sum(calories)) as int) || '/' ||
cast(round(100.0 * sum(chocals) / sum(calories)) as int) || '/' ||
cast(round(100.0 * sum(fatcals) / sum(calories)) as int) as macropct,
round(sum(protein)) as protein,
round(sum(nfc)) as nfc, round(sum(fat)) as fat,
bodycomp
from(
select meal_id / 100 as day, NDB_No,
sum(Gm_Wgt / 100.0 * cals.Nutr_Val) as calories,
sum(Gm_Wgt / 100.0 * pro.Nutr_Val) as protein,
sum(Gm_Wgt / 100.0 * crb.Nutr_Val) as nfc,
sum(Gm_Wgt / 100.0 * totfat.Nutr_Val) as fat,
sum(Gm_Wgt / 100.0 * pcals.Nutr_Val) as procals,
sum(Gm_Wgt / 100.0 * ccals.Nutr_Val) as chocals,
sum(Gm_Wgt / 100.0 * fcals.Nutr_Val) as fatcals,
bodycomp
from mealfoods join nut_data cals using (NDB_No)
join nut_data pro using (NDB_No)
join nut_data crb using (NDB_No)
join nut_data totfat using (NDB_No)
join nut_data pcals using (NDB_No)
join nut_data ccals using (NDB_No)
join nut_data fcals using (NDB_No)
left join (select * from wlview group by wldate) on day = wldate
where cals.Nutr_No = 208 and
pro.Nutr_No = 203 and
crb.Nutr_No = 2000 and
totfat.Nutr_No = 204 and
pcals.Nutr_No = 3000 and
ccals.Nutr_No = 3002 and
fcals.Nutr_No = 3001
group by day, NDB_No) group by day;

/*
  This is the select that I use to look at the nutrient values for the current meal.
*/

drop view if exists ranalysis;
create temp view ranalysis as select NutrDesc, round(Nutr_Val, 1) || ' ' || Units, cast(cast(round(100.0 + dvpct_offset) as int) as text) || '%' from rm_analysis natural join rm_dv natural join nutr_def order by dvpct_offset desc;

/*
  This is the select that I use to look at the nutrient values for the
  whole analysis period.
*/

drop view if exists analysis;
create temp view analysis as select NutrDesc, round(Nutr_Val, 1) || ' ' || Units, cast(cast(round(100.0 + dvpct_offset) as int) as text) || '%' from am_analysis natural join am_dv natural join nutr_def order by dvpct_offset desc;

commit;

PRAGMA user_version = 20;}
set ::NDB_Novf 0

#end user_init
}

set AmountChangevf {

proc AmountChangevf {args} {

 uplevel #0 {
  if {![string is double \
  -strict $Amountvf]} { return }
  set gramsvf [expr {$Amountvf * $Amount2gram}]
  }
 }

#end AmountChangevf
}

set CalChangevf {

proc CalChangevf {args} {

 uplevel #0 {
  if {![string is double \
  -strict $caloriesvf]} { return }
  set gramsvf [expr {$caloriesvf * $cal2gram}]
  }
 }

#end CalChangevf
}

set CancelSearch {

proc CancelSearch {args} {

if {!$::ALTGUI} {
 grid remove .nut.rm.searchcancel
 grid remove .nut.rm.frlistbox
 grid .nut.rm.grams
 grid .nut.rm.ounces
 grid .nut.rm.analysismeal
 } else {
 place forget .nut.rm.searchcancel
 place forget .nut.rm.frlistbox
 place .nut.rm.grams \
  -relx 0.87 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.11
 place .nut.rm.ounces \
  -relx 0.87 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.11
 place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
 }
 SwitchToMenu
 set ::like_this_rm ""
 focus .nut
 }

#end CancelSearch
}

set FindFoodrm {

proc FindFoodrm {args} {

 set ::needFindFoodrm 1
 after 350 FindFoodrm_later
 }

#end FindFoodrm
}

set FindFoodrm_later {

proc FindFoodrm_later {args} {

 if {! $::needFindFoodrm} {return}
 set ::needFindFoodrm 0
 uplevel #0 {
  set query "select Long_Desc from food_des where "
  regsub \
  -all {"} "$::like_this_rm" " " ::like_this_rm1
  regsub \
  -all "\{" "$::like_this_rm1" " " ::like_this_rm1
  if { $::like_this_rm == ""} {
   set foodsrm ""
   return
   }
  foreach token $::like_this_rm1 {
   append query "Long_Desc like \"%${token}%\" and "
   }
  append query "Long_Desc is not null order by Long_Desc collate nocase asc"
  set foodsrm [db eval $query]
  .nut.rm.frlistbox.listbox xview 0
  }
 }

#end FindFoodrm_later
}

set FindFoodvf {

proc FindFoodvf {args} {

 set ::needFindFoodvf 1
 after 350 FindFoodvf_later
 }

#end FindFoodvf
}

set FindFoodvf_later {

proc FindFoodvf_later {args} {

 if {! $::needFindFoodvf} {return}
 set ::needFindFoodvf 0
 uplevel #0 {
  set query "select Long_Desc from food_des where "
  regsub \
  -all {"} "$like_this_vf" " " like_this_vf1
  regsub \
  -all "\{" "$like_this_vf1" " " like_this_vf1
  if { $like_this_vf == ""} {
   set foodsvf ""
   return
   }
  foreach token $like_this_vf1 {
   append query "Long_Desc like \"%${token}%\" and "
   }
  append query "Long_Desc is not null order by Long_Desc collate nocase asc"
  set foodsvf [db eval $query]
  .nut.vf.frlistbox.listbox xview 0
  }
 }

#end FindFoodvf_later
}

set FoodChoicerm {

proc FoodChoicerm {args} {

 uplevel #0 {
  set ld "[lindex $foodsrm [.nut.rm.frlistbox.listbox curselection]]"
  if {$ld == ""} {return}
  db eval {select Shrt_Desc, food_des.NDB_No as NDB_No, Gm_Wgt from food_des natural join pref_Gm_Wgt where Long_Desc = $ld limit 1} {
   db eval {select count(*) as alreadythere from mealfoods where NDB_No = $NDB_No and meal_id = $::currentmeal} {
    if {$alreadythere == 0} {
     db eval {insert or replace into mealfoods values ($::currentmeal, $NDB_No, $Gm_Wgt, null)}
     MealfoodWidget $Shrt_Desc $NDB_No
     }
    }
   }
  if {!$::ALTGUI} {
   grid remove .nut.rm.frlistbox
   grid remove .nut.rm.searchcancel
   grid .nut.rm.analysismeal
   } else {
   place forget .nut.rm.frlistbox
   place forget .nut.rm.searchcancel
   place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
   }
  SwitchToMenu
  if { $::like_this_rm ni [.nut.rm.fsentry cget \
  -values]} {
   .nut.rm.fsentry configure \
  -values [linsert [.nut.rm.fsentry cget \
  -values] 0 $::like_this_rm]
   }
  set ::like_this_rm ""
  focus .nut
  }
 thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
 }

#end FoodChoicerm
}

set vf2rm {

proc vf2rm {args} {

db eval {select Shrt_Desc, food_des.NDB_No as NDB_No, Gm_Wgt from food_des natural join pref_Gm_Wgt where food_des.NDB_No = $::NDB_Novf limit 1} {
 db eval {insert or replace into mealfoods values ($::currentmeal, $NDB_No, $Gm_Wgt, null)}
 set seq [MealfoodWidget $Shrt_Desc $NDB_No]
 ${::rmMenu}.menu.foodspin${seq} configure  \
  -state readonly
 ${::rmMenu}.menu.foodPCF${seq} current 0
 ${::rmMenu}.menu.foodPCF${seq} configure  \
  -style rm.TCombobox
 }
if {!$::ALTGUI} {
 grid remove .nut.rm.setmpd
 grid .nut.rm.analysismeal
 } else {
 place forget .nut.rm.setmpd
 place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
 }
SwitchToMenu
.nut select .nut.rm
thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
}

#end vf2rm
}

set FoodChoicevf {

proc FoodChoicevf {args} {

 uplevel #0 {
  set ld "[lindex $foodsvf [.nut.vf.frlistbox.listbox curselection]]"
  if {$ld == ""} {return}
  .nut.vf.meal configure \
  -state normal
  .nut.vf.sb1 configure \
  -format {%0.3f}  .nut.vf.sb3 configure \
  -format {%0.3f}  dropoutvf
  db eval {select NDB_No as NDB_Novf from food_des where Long_Desc = $ld limit 1} { }
  db eval {insert into z_tcl_jobqueue values (null, 'view_foods', $NDB_Novf, null, null)}
  thread::send \
  -async $::SQL_THREAD {job_view_foods}
  set Long_Desc $ld
  db eval {select case when Refuse is not null then Refuse || "%" else Refuse end as Refusevf, setRefDesc(Ref_desc) from food_des where NDB_No = $NDB_Novf} { }
  db eval {select cast(round(Gm_Wgt) as int) as gramsvf, round(8.0 * Gm_Wgt / 28.35, 0) / 8.0 as ouncesvf, cast(round(Gm_Wgt * 0.01 * Nutr_Val) as int) as caloriesvf, round(8.0 * Amount, 0) / 8.0 as Amountvf, Msre_Desc as Msre_Descvf, 28.349523 as ounce2gram, case when Nutr_Val is null or Nutr_Val = 0.0 then 0.0 else 100.0/Nutr_Val end as cal2gram, origGm_Wgt/origAmount as Amount2gram from pref_Gm_Wgt join nut_data using (NDB_No) where NDB_No = $NDB_Novf and Nutr_No = 208} { }
  set servingsizes [db eval {select distinct Msre_Desc from weight where NDB_No = $NDB_Novf order by Seq limit 100 offset 1}]
  .nut.vf.cb configure \
  -values $servingsizes
  tuneinvf
  if {!$::ALTGUI} {
  grid remove .nut.vf.frlistbox
  grid .nut.vf.nbw
  grid .nut.vf.meal       } else {
  place forget .nut.vf.frlistbox
  place .nut.vf.nbw \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
  place .nut.vf.meal \
  -relx 0.78 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.12
  }
  if { $like_this_vf ni [.nut.vf.fsentry cget \
  -values]} {
   .nut.vf.fsentry configure \
  -values [linsert [.nut.vf.fsentry cget \
  -values] 0 $like_this_vf]
   }
  set like_this_vf ""
  focus .nut
  }
 }

#end FoodChoicevf
}

set job_view_foods {

proc job_view_foods {args} {

db eval {select count(*) as jobcount from z_tcl_jobqueue where jobtype = 'view_foods'} { }
if {$jobcount == 0} {return}

db eval {select jobnum, jobint as "::NDB_Novf", case when jobreal is null then (select Gm_Wgt from pref_Gm_Wgt where NDB_No = jobint) else jobreal end as "::Gm_Wgtvf" from z_tcl_jobqueue where jobtype = 'view_foods' order by jobnum desc limit 1} { }

db eval {select n6balance, macropct from z_tcl_n6hufa natural join z_tcl_macropct where NDB_No = $::NDB_Novf} {
 thread::send \
  -async $::GUI_THREAD [list set ::FAPU1vf $n6balance]
 thread::send \
  -async $::GUI_THREAD [list set ::ENERC_KCAL1vf $macropct]
 }
db eval {select '::' || Tagname || 'vfdv' as tag, cast(round($::Gm_Wgtvf * Nutr_Val / dv) as int) as val from nutr_def nd left join am_dv ad on nd.Nutr_No = ad.Nutr_No left join nut_data d on d.NDB_No = $::NDB_Novf and nd.Nutr_No = d.Nutr_No where dv_default > 0.0} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }

db eval {select '::' || Tagname || 'vf' as tag, round($::Gm_Wgtvf * 0.01 * Nutr_Val, 1) as val from nutr_def nd left join nut_data d on d.NDB_No = $::NDB_Novf and nd.Nutr_No = d.Nutr_No} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }

db eval {select cast(round($::Gm_Wgtvf * 0.01 * Nutr_Val) as int) as CHO_NONFIBvf1 from nut_data where NDB_No = $::NDB_Novf and Nutr_No = 2000} {
 thread::send \
  -async $::GUI_THREAD [list set ::CHO_NONFIBvf1 $CHO_NONFIBvf1]
 }

}

#end job_view_foods
}

set job_view_foods_Gm_Wgt {

proc job_view_foods_Gm_Wgt {args} {

db eval {select count(*) as jobcount from z_tcl_jobqueue where jobtype = 'view_foods_Gm_Wgt'} { }
if {$jobcount == 0} {return}

db eval {select jobnum, jobreal from z_tcl_jobqueue where jobtype = 'view_foods_Gm_Wgt' order by jobnum desc limit 1} {
 set ::Gm_Wgtvf $jobreal
 }

db eval {delete from z_tcl_jobqueue where jobtype = 'view_foods_Gm_Wgt' and jobnum <= $jobnum}

if {$::Gm_Wgtvf > 0.0} {
 db eval {update pref_Gm_Wgt set Gm_Wgt = $::Gm_Wgtvf where NDB_No = $::NDB_Novf}
 }

thread::send \
  -async $::GUI_THREAD {GramChangevfResult}

db eval {select '::' || Tagname || 'vfdv' as tag, cast(round($::Gm_Wgtvf * Nutr_Val / dv) as int) as val from nutr_def nd left join am_dv ad on nd.Nutr_No = ad.Nutr_No left join nut_data d on d.NDB_No = $::NDB_Novf and nd.Nutr_No = d.Nutr_No where dv_default > 0.0} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }

db eval {select '::' || Tagname || 'vf' as tag, round($::Gm_Wgtvf * 0.01 * Nutr_Val, 1) as val from nutr_def nd left join nut_data d on d.NDB_No = $::NDB_Novf and nd.Nutr_No = d.Nutr_No} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }

db eval {select cast(round($::Gm_Wgtvf * 0.01 * Nutr_Val) as int) as CHO_NONFIBvf1 from nut_data where NDB_No = $::NDB_Novf and Nutr_No = 2000} {
 thread::send \
  -async $::GUI_THREAD [list set ::CHO_NONFIBvf1 $CHO_NONFIBvf1]
 }

}

#end job_view_foods_Gm_Wgt
}

set FoodChoicevf_alt {

proc FoodChoicevf_alt {ndb grams upd} {

set ::NDB_Novf $ndb
set ::Gm_Wgtvf $grams
uplevel #0 {
 set NDB_Novf $::NDB_Novf
 set ld {*}[db eval {select Long_Desc from food_des where NDB_No = $::NDB_Novf}]
 .nut.vf.meal configure \
  -state normal
 dropoutvf
 db eval {insert into z_tcl_jobqueue values (null, 'view_foods', $::NDB_Novf, $::Gm_Wgtvf, null)}
 thread::send \
  -async $::SQL_THREAD {job_view_foods}
 db eval {select case when Refuse is not null then Refuse || "%" else Refuse end as Refusevf, setRefDesc(Ref_desc), Long_Desc from food_des where NDB_No = $::NDB_Novf} { }
 db eval {select cast(round($::Gm_Wgtvf) as int) as gramsvf, round(8.0 * $::Gm_Wgtvf / 28.35, 0) / 8.0 as ouncesvf, cast(round($::Gm_Wgtvf * 0.01 * Nutr_Val) as int) as caloriesvf, round(8.0 * $::Gm_Wgtvf / origGm_Wgt * origAmount, 0) / 8.0 as Amountvf, Msre_Desc as Msre_Descvf, 28.349523 as ounce2gram, case when Nutr_Val is null or Nutr_Val = 0.0 then 0.0 else 100.0/Nutr_Val end as cal2gram, origGm_Wgt/origAmount as Amount2gram from pref_Gm_Wgt join nut_data using (NDB_No) where NDB_No = $::NDB_Novf and Nutr_No = 208} { }
 set servingsizes [db eval {select distinct Msre_Desc from weight where NDB_No = $::NDB_Novf order by Seq limit 100 offset 1}]
 .nut.vf.cb configure \
  -values $servingsizes
 tuneinvf
 .nut.vf.cb configure \
  -values $servingsizes
 if {!$::ALTGUI} {
  grid remove .nut.vf.frlistbox
  grid .nut.vf.nbw
  grid .nut.vf.meal       } else {
  place forget .nut.vf.frlistbox
  place .nut.vf.nbw \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
  place .nut.vf.meal \
  -relx 0.78 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.12
  }
 set like_this_vf ""
 .nut select .nut.vf
 focus .nut
 }
}

#end FoodChoicevf_alt
}

set FoodSearchrm {

proc FoodSearchrm {args} {

 uplevel #0 {
  if {!$::ALTGUI} {
   grid remove $::rmMainPane
   grid remove .nut.rm.setmpd
   grid remove .nut.rm.analysismeal
   grid remove .nut.rm.grams
   grid remove .nut.rm.ounces
   set ::rmMainPane .nut.rm.frmenu
   focus .nut.rm.fsentry
   grid .nut.rm.frlistbox
   grid .nut.rm.searchcancel
   after 400 {focus .nut.rm.fsentry}
   } else {
   place forget $::rmMainPane
   place forget .nut.rm.setmpd
   place forget .nut.rm.analysismeal
   place forget .nut.rm.grams
   place forget .nut.rm.ounces
   set ::rmMainPane .nut.rm.frmenu
   focus .nut.rm.fsentry
   place .nut.rm.frlistbox \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
   place .nut.rm.searchcancel \
  -relx 0.86 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.09
   after 400 {focus .nut.rm.fsentry}
   }
  }
 }

#end FoodSearchrm
}

set FoodSearchvf {

proc FoodSearchvf {args} {

 uplevel #0 {
  dropoutvf
  if {!$::ALTGUI} {
   grid remove .nut.vf.nbw
   grid .nut.vf.frlistbox
   grid remove .nut.vf.meal
   } else {
   place forget .nut.vf.nbw
   place .nut.vf.frlistbox \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
   place forget .nut.vf.meal
   }

  set Long_Desc ""
  set Msre_Descvf ""
  .nut.vf.sb0 set ""
  .nut.vf.sb1 set ""
  .nut.vf.sb2 set ""
  .nut.vf.sb3 set ""
  .nut.vf.cb configure \
  -values ""
  set Refusevf ""
  .nut.vf.refusemb.m entryconfigure 0 \
  -label "No refuse description provided"
  tuneinvf
  after 400 {focus .nut.vf.fsentry}
  }
 }

#end FoodSearchvf
}

set GramChangevf {

proc GramChangevf {args} {

 if {![string is double \
  -strict $::gramsvf]} { return }
 db eval {insert into z_tcl_jobqueue values (null, 'view_foods_Gm_Wgt', null, $::gramsvf, null)}
 thread::send \
  -async $::SQL_THREAD {job_view_foods_Gm_Wgt}
 }

#end GramChangevf
}

set GramChangevfResult {

proc GramChangevfResult {args} {

 uplevel #0 {
  dropoutvf
  db eval {select round(8.0 * $gramsvf / 28.35, 0) / 8.0 as ouncesvf, ifnull(cast(round($gramsvf / $cal2gram) as int),0) as caloriesvf, round(8.0 * $gramsvf / $Amount2gram,0) / 8.0 as Amountvf, cast(round($gramsvf) as int) as gramsvf} { }
  tuneinvf
  }
 }

#end GramChangevfResult
}

set InitializePersonalOptions {

proc InitializePersonalOptions {args} {

 db eval {select autocal, wltweak from options} { }

 if {$::ENERC_KCALopt == \
  -1.0} {
  .nut.po.pane.optframe.cal_s configure \
  -state disabled \
  -textvariable ::ENERC_KCALdv
  set ::ENERC_KCALpo \
  -1
  } elseif {$::ENERC_KCALopt == 0.0} {
  .nut.po.pane.optframe.cal_s configure \
  -state normal \
  -textvariable ::ENERC_KCALopt
  set ::ENERC_KCALopt 2000.0
  set ::ENERC_KCALpo 0
  } else {
  .nut.po.pane.optframe.cal_s configure \
  -state normal \
  -textvariable ::ENERC_KCALopt
  set ::ENERC_KCALpo 0  }
 if {$autocal == 2} {
  set ::ENERC_KCALpo 2
  }

 if {$::FATopt == \
  -1.0} {
  .nut.po.pane.optframe.fat_s configure \
  -state disabled \
  -textvariable ::FATdv
  set ::FATpo \
  -1
  } elseif {$::FATopt == 0.0} {
  .nut.po.pane.optframe.fat_s configure \
  -state disabled \
  -textvariable ::FATdv
  set ::FATpo 2
  } else {
  .nut.po.pane.optframe.fat_s configure \
  -state normal \
  -textvariable ::FATopt
  set ::FATpo 0  }

 if {$::PROCNTopt == \
  -1.0} {
  .nut.po.pane.optframe.prot_s configure \
  -state disabled \
  -textvariable ::PROCNTdv
  set ::PROCNTpo \
  -1
  } elseif {$::PROCNTopt == 0.0} {
  .nut.po.pane.optframe.prot_s configure \
  -state disabled \
  -textvariable ::PROCNTdv
  set ::PROCNTpo 2
  } else {
  .nut.po.pane.optframe.prot_s configure \
  -state normal \
  -textvariable ::PROCNTopt
  set ::PROCNTpo 0  }

 if {$::CHO_NONFIBopt == \
  -1.0} {
  .nut.po.pane.optframe.nfc_s configure \
  -state disabled \
  -textvariable ::CHO_NONFIBdv
  set ::CHO_NONFIBpo \
  -1
  .nut.po.pane.optframe.fat_cb2 configure \
  -text "Balance of Calories"
  } elseif {$::CHO_NONFIBopt == 0.0} {
  .nut.po.pane.optframe.nfc_s configure \
  -state disabled \
  -textvariable ::CHO_NONFIBdv
  set ::CHO_NONFIBpo 2
  .nut.po.pane.optframe.fat_cb2 configure \
  -text "DV 36% of Calories"
  } else {
  .nut.po.pane.optframe.nfc_s configure \
  -state normal \
  -textvariable ::CHO_NONFIBopt
  set ::CHO_NONFIBpo 0  .nut.po.pane.optframe.fat_cb2 configure \
  -text "Balance of Calories"
  }
 if {$::ENERC_KCALopt == \
  -1.0} {
  .nut.po.pane.optframe.fat_cb2 configure \
  -text "DV 36% of Calories"
  .nut.po.pane.optframe.nfc_cb2 configure \
  -text "DV 54% of Calories"
  }
 
 if {$::FIBTGopt == \
  -1.0} {
  .nut.po.pane.optframe.fiber_s configure \
  -state disabled \
  -textvariable ::FIBTGdv
  set ::FIBTGpo \
  -1
  } elseif {$::FIBTGopt == 0.0} {
  .nut.po.pane.optframe.fiber_s configure \
  -state disabled \
  -textvariable ::FIBTGdv
  set ::FIBTGpo 2
  } else {
  .nut.po.pane.optframe.fiber_s configure \
  -state normal \
  -textvariable ::FIBTGopt
  set ::FIBTGpo 0  }

 if {$::FASATopt == \
  -1.0} {
  .nut.po.pane.optframe.sat_s configure \
  -state disabled \
  -textvariable ::FASATdv
  set ::FASATpo \
  -1
  } elseif {$::FASATopt == 0.0} {
  .nut.po.pane.optframe.sat_s configure \
  -state disabled \
  -textvariable ::FASATdv
  set ::FASATpo 2
  } else {
  .nut.po.pane.optframe.sat_s configure \
  -state normal \
  -textvariable ::FASATopt
  set ::FASATpo 0  }

 if {$::FAPUopt == \
  -1.0} {
  .nut.po.pane.optframe.efa_s configure \
  -state disabled \
  -textvariable ::FAPUdv
  set ::FAPUpo \
  -1
  } elseif {$::FAPUopt == 0.0} {
  .nut.po.pane.optframe.efa_s configure \
  -state disabled \
  -textvariable ::FAPUdv
  set ::FAPUpo 2
  } else {
  .nut.po.pane.optframe.efa_s configure \
  -state normal \
  -textvariable ::FAPUopt
  set ::FAPUpo 0  }

 if {$::FAPU1 == 0.0} {
  .nut.po.pane.optframe.fish_s set {50 / 50}
  } else {
  set n6 [expr {int($::FAPU1)}]
  .nut.po.pane.optframe.fish_s set "$n6 / [expr {100 - $n6}]"
  }

 }

#end InitializePersonalOptions
}

set ChangePersonalOptions {

proc ChangePersonalOptions {nuttag args} {
 set var "::${nuttag}po"
 upvar #0 $var povar

 if {$nuttag == "ENERC_KCAL"} {
  if {$povar == 2} {
   db eval {update options set autocal = 2}
   set ::ENERC_KCALopt $::ENERC_KCALdv
   .nut.po.pane.optframe.cal_s configure \
  -state normal \
  -textvariable ::ENERC_KCALopt
#  .nut.po.pane.optframe.nfc_cb2 configure \
  -text "Balance of Calories"
#  .nut.po.pane.optframe.nfc_cb2 invoke
   } elseif {$povar == 0} {
   db eval {update options set autocal = 0}
   set ::ENERC_KCALopt $::ENERC_KCALdv
   .nut.po.pane.optframe.cal_s configure \
  -state normal \
  -textvariable ::ENERC_KCALopt
#  .nut.po.pane.optframe.nfc_cb2 configure \
  -text "Balance of Calories"
#  .nut.po.pane.optframe.nfc_cb2 invoke
   } else {
   db eval {update options set autocal = 0}
   .nut.po.pane.optframe.cal_s configure \
  -state disabled \
  -textvariable ::ENERC_KCALdv
   set ::ENERC_KCALopt \
  -1
   .nut.po.pane.optframe.fat_cb2 configure \
  -text "DV 36% of Calories"
   .nut.po.pane.optframe.nfc_cb2 configure \
  -text "DV 54% of Calories"
   }
  RefreshWeightLog
  } elseif {$nuttag == "FAT"} {
  if {$povar == 2} {
   set ::FATopt 0.0
   .nut.po.pane.optframe.fat_s configure \
  -state disabled \
  -textvariable ::FATdv
   } elseif {$povar == 0} {
   set ::FATopt $::FATdv
   .nut.po.pane.optframe.fat_s configure \
  -state normal \
  -textvariable ::FATopt
   if {$::CHO_NONFIBopt != 0.0 && $::ENERC_KCALopt >= 0.0} {
    .nut.po.pane.optframe.nfc_cb2 invoke
    }
   } else {
   .nut.po.pane.optframe.fat_s configure \
  -state disabled \
  -textvariable ::FATdv
   set ::FATopt \
  -1
   if {$::CHO_NONFIBopt != 0.0 && $::ENERC_KCALopt >= 0.0} {
    .nut.po.pane.optframe.nfc_cb2 invoke
    }
   }
  } elseif {$nuttag == "PROCNT"} {
  if {$povar == 2} {
   set ::PROCNTopt 0.0
   .nut.po.pane.optframe.prot_s configure \
  -state disabled \
  -textvariable ::PROCNTdv
   } elseif {$povar == 0} {
   set ::PROCNTopt $::PROCNTdv
   .nut.po.pane.optframe.prot_s configure \
  -state normal \
  -textvariable ::PROCNTopt
   } else {
   .nut.po.pane.optframe.prot_s configure \
  -state disabled \
  -textvariable ::PROCNTdv
   set ::PROCNTopt \
  -1
   }
  } elseif {$nuttag == "CHO_NONFIB"} {
  if {$povar == 2} {
   set ::CHO_NONFIBopt 0.0
   .nut.po.pane.optframe.nfc_s configure \
  -state disabled \
  -textvariable ::CHO_NONFIBdv
   .nut.po.pane.optframe.fat_cb2 configure \
  -text "DV 36% of Calories"
   } elseif {$povar == 0} {
   set ::CHO_NONFIBopt $::CHO_NONFIBdv
   .nut.po.pane.optframe.nfc_s configure \
  -state normal \
  -textvariable ::CHO_NONFIBopt
   .nut.po.pane.optframe.fat_cb2 configure \
  -text "Balance of Calories"
   if {$::FATopt != 0.0 && $::ENERC_KCALopt >= 0.0} {
    .nut.po.pane.optframe.fat_cb2 invoke
    }
   } else {
   .nut.po.pane.optframe.nfc_s configure \
  -state disabled \
  -textvariable ::CHO_NONFIBdv
   set ::CHO_NONFIBopt \
  -1
   .nut.po.pane.optframe.fat_cb2 configure \
  -text "Balance of Calories"
   if {$::FATopt != 0.0 && $::ENERC_KCALopt >= 0.0} {
    .nut.po.pane.optframe.fat_cb2 invoke
    }
   }
  } elseif {$nuttag == "FIBTG"} {
  if {$povar == 2} {
   set ::FIBTGopt 0.0
   .nut.po.pane.optframe.fiber_s configure \
  -state disabled \
  -textvariable ::FIBTGdv
   } elseif {$povar == 0} {
   set ::FIBTGopt $::FIBTGdv
   .nut.po.pane.optframe.fiber_s configure \
  -state normal \
  -textvariable ::FIBTGopt
   } else {
   .nut.po.pane.optframe.fiber_s configure \
  -state disabled \
  -textvariable ::FIBTGdv
   set ::FIBTGopt \
  -1
   }
  } elseif {$nuttag == "FASAT"} {
  if {$povar == 2} {
   set ::FASATopt 0.0
   .nut.po.pane.optframe.sat_s configure \
  -state disabled \
  -textvariable ::FASATdv
   } elseif {$povar == 0} {
   set ::FASATopt $::FASATdv
   .nut.po.pane.optframe.sat_s configure \
  -state normal \
  -textvariable ::FASATopt
   } else {
   .nut.po.pane.optframe.sat_s configure \
  -state disabled \
  -textvariable ::FASATdv
   set ::FASATopt \
  -1
   }
  } elseif {$nuttag == "FAPU"} {
  if {$povar == 2} {
   set ::FAPUopt 0.0
   .nut.po.pane.optframe.efa_s configure \
  -state disabled \
  -textvariable ::FAPUdv
   } elseif {$povar == 0} {
   set ::FAPUopt $::FAPUdv
   .nut.po.pane.optframe.efa_s configure \
  -state normal \
  -textvariable ::FAPUopt
   } else {
   .nut.po.pane.optframe.efa_s configure \
  -state disabled \
  -textvariable ::FAPUdv
   set ::FAPUopt \
  -1
   }
  } elseif {$nuttag == "FAPU1"} {
  set ::FAPU1 [string range $::FAPU1po 0 1]
  db eval {update options set FAPU1 = $::FAPU1}
  thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
  } else {
  if {$::vitminpo == 2} {
   set ::${nuttag}opt 0.0
   .nut.po.pane.optframe.vite_s configure \
  -state disabled \
  -textvariable ::${nuttag}dv
   } elseif {$::vitminpo == 0} {
   set ::${nuttag}opt [db eval {select dv_default from nutr_def where Tagname = $nuttag}]
   .nut.po.pane.optframe.vite_s configure \
  -state normal \
  -textvariable ::${nuttag}opt
   } else {
   .nut.po.pane.optframe.vite_s configure \
  -state disabled \
  -textvariable ::${nuttag}dv
   set ::${nuttag}opt \
  -1
   }
  }
 }

#end ChangePersonalOptions
}

set RefreshWeightLog {

proc RefreshWeightLog {args} {
 db eval {select *, "::weightslope" - "::fatslope" as leanslope, round(weightyintercept,1) as "::weightyintercept", round(100.0 * fatyintercept / weightyintercept, 1) as "::currentbfp" from z_wslope, z_fslope} { }
 if {$weightn == 0} {
  set ::currentbfp 0.0
  }
 if {$weightn == 1} {
  db eval {select weight as "::weightyintercept", bodyfat as "::currentbfp" from z_wl where cleardate is null} { }
  }
 db eval {select autocal, wlpolarity, wltweak from options} { }
 if {$autocal == 2} {
  if {!$::ALTGUI} {
   grid remove .nut.po.pane.wlogframe.clear
   } else {
   place forget .nut.po.pane.wlogframe.clear
   }
  } else {
  set counter [db eval {select count(*) from wlog where cleardate is null}]
  if {$counter > 1} {
   if {!$::ALTGUI} {
    grid .nut.po.pane.wlogframe.clear
    } else {
    place .nut.po.pane.wlogframe.clear \
  -relx 0.3 \
  -rely 0.89 \
  -relheight 0.06 \
  -relwidth 0.63
    }
   } else {
    if {!$::ALTGUI} {
    grid remove .nut.po.pane.wlogframe.clear
    } else {
    place forget .nut.po.pane.wlogframe.clear
    }
   }
  }
 set measurements_not_entered [db eval { select abs(max(cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int))) from wlog where cleardate is null } ]
 if {$measurements_not_entered == 0} {
  .nut.po.pane.wlogframe.accept configure \
  -state disabled
  .nut.po.pane.wlogframe.weight_s configure \
  -state disabled
  .nut.po.pane.wlogframe.bf_s configure \
  -state disabled
  } else {
.nut.po.pane.wlogframe.accept configure \
  -state normal
  .nut.po.pane.wlogframe.weight_s configure \
  -state normal
  .nut.po.pane.wlogframe.bf_s configure \
  -state normal
  }

 set ::wlogsummary [db onecolumn {select verbiage from z_tcl_wlsumm}]
 }

#end RefreshWeightLog
}

set ClearWeightLog {

proc ClearWeightLog {args} {

db eval {insert into wlsummary select 'clear'}
RefreshWeightLog
}

#end ClearWeightLog
}

set AcceptNewMeasurements {

proc AcceptNewMeasurements {args} {
db eval {insert into wlog values ( $::weightyintercept, $::currentbfp, null, NULL)}
RefreshWeightLog
if {$::ENERC_KCALpo == 2} {
 db eval {select nutopt as newopt from nutr_def where Nutr_No = 208} { }
 if {$newopt != $::ENERC_KCALopt} {
  set ::ENERC_KCALopt $newopt
  thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
  }
 }
}

#end AcceptNewMeasurements
}

set RefreshMealfoodQuantities {

proc RefreshMealfoodQuantities {args} {
 db eval {drop view if exists pcf}
 if {[db eval {select count(*) from mealfoods where meal_id = $::currentmeal}] > 0} {
  set selectstring "select * from ("
  set viewstring "drop view if exists pcf; create temp view pcf as select * from ("
  db eval {select NDB_No from mealfoods where meal_id = $::currentmeal} {
   if {$::GRAMSopt} {
    append selectstring "(select cast (round(Gm_Wgt) as integer) as \"::${NDB_No}\" from mealfoods where NDB_No = $NDB_No and meal_id = $::currentmeal), "
    } else {
    append selectstring "(select round(8.0 * Gm_Wgt / 28.349523,0) / 8.0 as \"::${NDB_No}\" from mealfoods where NDB_No = $NDB_No and meal_id = $::currentmeal), "
    }
   if {[lindex $::MealfoodPCF [lsearch $::MealfoodStatus $NDB_No]] != "NULL"} {    if {$::GRAMSopt} {
     append viewstring "(select cast (round(Gm_Wgt) as integer) as \"::${NDB_No}\" from mealfoods where NDB_No = $NDB_No and meal_id = $::currentmeal), "
     } else {
     append viewstring "(select round(8.0 * Gm_Wgt / 28.349523,0) / 8.0 as \"::${NDB_No}\" from mealfoods where NDB_No = $NDB_No and meal_id = $::currentmeal), "
     }
    } else {
    append viewstring "(select NULL), "
    }
   }
  set selectstring [string trimright $selectstring " "]
  set selectstring [string trimright $selectstring ","]
  append selectstring ")"
  db eval $selectstring { }
  set viewstring [string trimright $viewstring " "]
  set viewstring [string trimright $viewstring ","]
  append viewstring ")"
  db eval $viewstring { }
  }
 }

#end RefreshMealfoodQuantities
}

set MealfoodDelete {

proc MealfoodDelete {seq ndb dbdelete} {

 ${::rmMenu}.menu tag configure foodwidget${seq} \
  -elide 1
 if {[lsearch \
  -exact $::MealfoodStatus $ndb] != $seq} {return}
 set prevtag [lindex $::MealfoodPCF $seq]
 if {$prevtag != "NULL"} {
  trace remove variable ::${prevtag}dv write "PCF ${seq} ${ndb}"
  trace remove variable ::${prevtag}rm write "PCF ${seq} ${ndb}"
  set ::MealfoodPCF [lreplace $::MealfoodPCF $seq $seq "NULL"]
  thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
  }
 ::trace remove variable ::PCFchoice${ndb} write "setPCF ${seq} ${ndb}"
 unset ::PCFchoice${ndb} ::${ndb}
 set ::MealfoodStatus [lreplace $::MealfoodStatus $seq $seq Hidden]
 ${::rmMenu}.menu.foodPCF${seq} configure  \
  -style rm.TCombobox
 ${::rmMenu}.menu.foodspin${seq} configure  \
  -state readonly
 set lastone [expr {$::MealfoodSequence - 1}]
 if {[lindex $::MealfoodStatus $lastone] == "Hidden"} {
  set ::MealfoodStatus [lreplace $::MealfoodStatus $lastone $lastone Available]
  }
 while {[lindex $::MealfoodStatus $lastone] == "Available" && $lastone > 0} {
  incr lastone \
  -1
  if {[lindex $::MealfoodStatus $lastone] == "Hidden"} {
   set ::MealfoodStatus [lreplace $::MealfoodStatus $lastone $lastone Available]
   }
  }
 if {$dbdelete} {
  db eval {delete from currentmeal where NDB_No = $ndb}
  thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
  }
 }

#end MealfoodDelete
}

set MealfoodSetWeight {

proc MealfoodSetWeight {newval ndb ndbVarName args} {

if {![string is double \
  -strict $newval]} {
 set newval 0.0
 {*}"set ::${ndb} $newval"
 } else {
 if {! $::GRAMSopt} { {*}"set ::${ndb} [expr {$newval * 1.0}]" }
 after 300 [list MealfoodSetWeightLater $newval $ndb $ndbVarName]
 }

}

#end MealfoodSetWeight
}

set MealfoodSetWeightLater {

proc MealfoodSetWeightLater {newval ndb ndbVarName args} {

if {![string is double \
  -strict $newval]} {
 set newval 0.0
 {*}"set ::${ndb} $newval"
 } else {
 upvar 0 $ndbVarName ndbvar
 if {$newval == $ndbvar} {
  if {$::GRAMSopt} {
   set grams $ndbvar
   } else {
   set grams [expr {$ndbvar * 28.349523}]
   }
  thread::send \
  -async $::SQL_THREAD [list db eval "insert into z_tcl_jobqueue values (null, 'mealfood_qty', $ndb, $grams, $::currentmeal)"]
  thread::send \
  -async $::SQL_THREAD [list job_mealfood_qty $ndb]
  }
 }}

#end MealfoodSetWeightLater
}

set MealfoodWidget {

proc MealfoodWidget {Shrt_Desc NDB_No} {

 set noThereThere [lsearch \
  -exact $::MealfoodStatus $NDB_No]
 if {$noThereThere > \
  -1} {return $noThereThere}
 if {$noThereThere == \
  -1} {
  set seq ${::MealfoodSequence}
  incr ::MealfoodSequence
  lappend ::MealfoodStatus $NDB_No
  lappend ::MealfoodPCF "NULL"
  lappend ::MealfoodPCFfactor 0.0
  ttk::button ${::rmMenu}.menu.foodbutton${seq} \
  -text $Shrt_Desc \
  -command [list rm2vf $seq] \
  -width 46 \
  -style vf.TButton
  tk::spinbox ${::rmMenu}.menu.foodspin${seq} \
  -textvariable ::${NDB_No} \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -cursor [. cget \
  -cursor] \
  -buttonbackground "#FF9428" \
  -disabledforeground "#000000" \
  -readonlybackground "#FFE3CA" \
  -state readonly \
  -command "MealfoodSetWeight %s ${NDB_No} ::${NDB_No}"
  if {! $::GRAMSopt} {
   ${::rmMenu}.menu.foodspin${seq} configure \
  -format {%0.3f} \
  -from \
  -999.9 \
  -to 999.9 \
  -increment 0.125
   }
  ttk::combobox ${::rmMenu}.menu.foodPCF${seq} \
  -textvariable ::PCFchoice${NDB_No} \
  -state readonly \
  -values $::PCFchoices \
  -style rm.TCombobox \
  -width 20 \
  -justify center
  ttk::button ${::rmMenu}.menu.fooddel${seq} \
  -text "DEL" \
  -width 3 \
  -command "MealfoodDelete $seq $NDB_No 1" \
  -style vf.TButton
  ${::rmMenu}.menu configure \
  -state normal
  ${::rmMenu}.menu window create end \
  -window ${::rmMenu}.menu.foodbutton${seq} \
  -pady $::magnify \
  -padx [expr {$::magnify * 3}]
  ${::rmMenu}.menu window create end \
  -window ${::rmMenu}.menu.foodspin${seq} \
  -pady $::magnify \
  -padx [expr {$::magnify * 3}]
  ${::rmMenu}.menu window create end \
  -window ${::rmMenu}.menu.foodPCF${seq} \
  -pady $::magnify \
  -padx [expr {$::magnify * 3}]
  ${::rmMenu}.menu window create end \
  -window ${::rmMenu}.menu.fooddel${seq} \
  -pady $::magnify \
  -padx [expr {$::magnify * 3}]
  ${::rmMenu}.menu insert end "\n"
  set startrange [expr {$seq + 1.0}]
  set endrange [expr {$seq + 2.0}]
  ${::rmMenu}.menu tag add foodwidget${seq} $startrange $endrange
  ${::rmMenu}.menu tag configure foodwidget${seq} \
  -justify center
  ${::rmMenu}.menu configure \
  -state disabled
  } else {
  set seq [lsearch \
  -exact $::MealfoodStatus Available]
  set ::MealfoodStatus [lreplace $::MealfoodStatus $seq $seq $NDB_No]
  ${::rmMenu}.menu.foodbutton${seq} configure \
  -text $Shrt_Desc
  ${::rmMenu}.menu.foodspin${seq} configure \
  -textvariable ::${NDB_No} \
  -command "MealfoodSetWeight %s ${NDB_No} ::${NDB_No}"
  if {! $::GRAMSopt} {
   ${::rmMenu}.menu.foodspin${seq} configure \
  -format {%0.3f} \
  -from \
  -999.9 \
  -to 999.9 \
  -increment 0.125
   } else {
   ${::rmMenu}.menu.foodspin${seq} configure \
  -from \
  -9999 \
  -to 9999 \
  -increment 1
   }
  ${::rmMenu}.menu.foodPCF${seq} configure \
  -textvariable ::PCFchoice${NDB_No}
  ${::rmMenu}.menu.fooddel${seq} configure \
  -command "MealfoodDelete $seq $NDB_No 1"
  ${::rmMenu}.menu tag configure foodwidget${seq} \
  -elide 0
  }
 {*}"set ::PCFchoice${NDB_No} {No Auto Portion Control}"
 ::trace add variable ::PCFchoice${NDB_No} write "setPCF ${seq} ${NDB_No}"
 ${::rmMenu}.menu.foodspin${seq} configure \
  -command "MealfoodSetWeight %s ${NDB_No} ::${NDB_No}"
 set ::MealfoodPCF [lreplace $::MealfoodPCF $seq $seq "NULL"]
 if {$::mealcount == 0} {
  set ::mealcount 1
  set ::meals_to_analyze_am 1
  }
 return $seq
 }

#end MealfoodWidget
}

set NBWamTabChange {

proc NBWamTabChange {} {

 uplevel #0 {
  set tabindex [.nut.am.nbw index [.nut.am.nbw select]]
  if {$tabindex == 0} {.nut.am.herelabel configure \
  -text "Here are \"Daily Value\" average percentages for your previous "} else {.nut.am.herelabel configure \
  -text "Here are average daily nutrient levels for your previous "}
  if {$tabindex != [.nut.rm.nbw index [.nut.rm.nbw select]]} {.nut.rm.nbw select .nut.rm.nbw.screen${tabindex}}
  if {$tabindex != [.nut.vf.nbw index [.nut.vf.nbw select]]} {.nut.vf.nbw select .nut.vf.nbw.screen${tabindex}}
  if {$tabindex != [.nut.ar.nbw index [.nut.ar.nbw select]]} {.nut.ar.nbw select .nut.ar.nbw.screen${tabindex}}
  }
 }

#end NBWamTabChange
}

set NBWrmTabChange {

proc NBWrmTabChange {} {

 uplevel #0 {
  set tabindex [.nut.rm.nbw index [.nut.rm.nbw select]]
  if {$tabindex != [.nut.am.nbw index [.nut.am.nbw select]]} {.nut.am.nbw select .nut.am.nbw.screen${tabindex}}
  if {$tabindex != [.nut.vf.nbw index [.nut.vf.nbw select]]} {.nut.vf.nbw select .nut.vf.nbw.screen${tabindex}}
  if {$tabindex != [.nut.ar.nbw index [.nut.ar.nbw select]]} {.nut.ar.nbw select .nut.ar.nbw.screen${tabindex}}
  }
 }

#end NBWrmTabChange
}

set NBWvfTabChange {

proc NBWvfTabChange {} {

 uplevel #0 {
  set tabindex [.nut.vf.nbw index [.nut.vf.nbw select]]
  if {$tabindex != [.nut.am.nbw index [.nut.am.nbw select]]} {.nut.am.nbw select .nut.am.nbw.screen${tabindex}}
  if {$tabindex != [.nut.rm.nbw index [.nut.rm.nbw select]]} {.nut.rm.nbw select .nut.rm.nbw.screen${tabindex}}
  if {$tabindex != [.nut.ar.nbw index [.nut.ar.nbw select]]} {.nut.ar.nbw select .nut.ar.nbw.screen${tabindex}}
  }
 }

#end NBWvfTabChange
}

set NBWarTabChange {

proc NBWarTabChange {} {

 uplevel #0 {
  set tabindex [.nut.ar.nbw index [.nut.ar.nbw select]]
  if {$tabindex != [.nut.am.nbw index [.nut.am.nbw select]]} {.nut.am.nbw select .nut.am.nbw.screen${tabindex}}
  if {$tabindex != [.nut.rm.nbw index [.nut.rm.nbw select]]} {.nut.rm.nbw select .nut.rm.nbw.screen${tabindex}}
  if {$tabindex != [.nut.vf.nbw index [.nut.vf.nbw select]]} {.nut.vf.nbw select .nut.vf.nbw.screen${tabindex}}
  }
 }

#end NBWarTabChange
}

set NewStoryLater {

proc NewStoryLater {storynut screen args} {
 after idle [list NewStory $storynut $screen]
 }

#end NewStoryLater
}

set NewStory {

proc NewStory {storynut screen} {

 set ::StoryIsStale 0

 if {$storynut != "NULL"} {
  set ::oldstorynut $storynut
  set ::oldstoryscreen $screen
  append storynut "b"
  upvar #0 $storynut ::newstory
  db eval {select Tagname, case when Units != X'B567' then Units else 'mcg' end as Units from nutr_def where NutrDesc = $::newstory} { }
  .nut tab .nut.ts \
  -text [list The {*}$::newstory Story]
  .nut.ts.frgraph configure \
  -text [list Graph of daily {*}$::newstory for this analysis period]
  .nut.ts.frgraph.canvas delete all
  .nut add .nut.ts
  .nut select .nut.ts
  .nut.ts.frranking.ranking delete [.nut.ts.frranking.ranking children {}]
  } else {
  db eval {select Tagname, case when Units != X'B567' then Units else 'mcg' end as Units from nutr_def where NutrDesc = $::newstory} { }
  .nut.ts.frranking.ranking delete [.nut.ts.frranking.ranking children {}]
  set screen $::oldstoryscreen
  }
 set FdGrp_Cd 0
 db eval {select FdGrp_Cd from fd_group where FdGrp_Desc = $::fdgroupchoice} { }

 foreach col {food field1 field2} {
  .nut.ts.frranking.ranking heading $col \
  -text ""
  }
 set savecursor [.nut.ts cget \
  -cursor]
 .nut.ts configure \
  -cursor watch
.nut.ts.frgraph.canvas configure \
  -width [winfo width .nut] \
  -height [expr {2 + [winfo height .nut] / 4}]
 update

 if {$::rankchoice == "Foods Ranked per 100 Grams"} {
  set storydata [db eval { select fd.NDB_No, 100, Shrt_Desc, monoright(case when $::GRAMSopt = 1 then '100 g' else '3.5 oz' end, 10), case when $screen = 0 then monoright(cast(round(100.0 * data.Nutr_Val / dv, 0) as int) || '% DV', 14) else monoright(round(data.Nutr_Val, 1) || ' ' || $Units, 14) end as Nutr_Val from food_des fd join nutr_def nd join nut_data data on fd.NDB_No = data.NDB_No and nd.Nutr_No = data.Nutr_No and data.Nutr_Val > 0.0 left join am_dv on nd.Nutr_No = am_dv.Nutr_No where Tagname = $Tagname and FdGrp_Cd = case when $FdGrp_Cd = 0 then FdGrp_Cd else $FdGrp_Cd end order by Nutr_Val desc }]

  } elseif {$::rankchoice == "Foods Ranked per 100 Calories"  && $Tagname != "ENERC_KCAL" && $Tagname != "ENERC_KJ"} {
  set storydata [db eval { select fd.NDB_No, 10000.0 / cals.Nutr_Val, Shrt_Desc, monoright(case when $::GRAMSopt = 1 then cast(round(10000.0 / cals.Nutr_Val) as int) || ' g' else round(10000.0 / cals.Nutr_Val / 28.249523,1) || ' oz' end, 10), case when $screen = 0 then monoright(cast(round(data.Nutr_Val / dv * 10000.0 / cals.Nutr_Val, 0) as int) || '% DV', 14) else monoright(round(data.Nutr_Val * 100.0 / cals.Nutr_Val, 1) || ' ' || $Units, 14) end as Nutr_Val from food_des fd join nut_data cals on fd.NDB_No = cals.NDB_No and cals.Nutr_No = 208 and cals.Nutr_Val > 0.0 join nutr_def nd join nut_data data on fd.NDB_No = data.NDB_No and nd.Nutr_No = data.Nutr_No and data.Nutr_Val > 0.0 left join am_dv on nd.Nutr_No = am_dv.Nutr_No where Tagname = $Tagname and FdGrp_Cd = case when $FdGrp_Cd = 0 then FdGrp_Cd else $FdGrp_Cd end order by Nutr_Val desc }]

  } elseif {$::rankchoice == "Foods Ranked per Daily Recorded Meals"} {
  set storydata [db eval { select mf.NDB_No, sum(Gm_Wgt / mealcount * meals_per_day), Shrt_Desc, monoright(case when $::GRAMSopt = 1 then cast(round(sum(Gm_Wgt / mealcount * meals_per_day)) as int) || ' g' else round(sum(Gm_Wgt / mealcount * meals_per_day / 28.35), 1) || ' oz' end, 10), case when $screen = 0 then monoright(cast(round(sum(Gm_Wgt * Nutr_Val / dv / mealcount * meals_per_day), 0) as int) || '% DV', 14) else monoright(round(sum(Gm_Wgt * Nutr_Val / 100.0 / mealcount * meals_per_day), 1) || ' ' || $Units, 14) end as Nutr_Val from mealfoods mf join food_des using (NDB_No) join nutr_def nd join nut_data data on mf.NDB_No= data.NDB_No and nd.Nutr_No = data.Nutr_no and data.Nutr_Val > 0.0 left join am_dv on nd.Nutr_No = am_dv.Nutr_No join am_analysis_header where meal_id >= firstmeal and Tagname = $Tagname and FdGrp_Cd = case when $FdGrp_Cd = 0 then FdGrp_Cd else $FdGrp_Cd end group by mf.NDB_No, NutrDesc order by Nutr_Val desc }]

  } elseif {$::rankchoice == "Foods Ranked per one approximate Serving"} {
  set storydata [db eval {select fd.NDB_No, cast (round(water.Nutr_Val) as int), Shrt_Desc, monoright(case when $::GRAMSopt = 1 then cast(round(water.Nutr_Val) as int) || ' g' else round(water.Nutr_Val / 28.249523,1) || ' oz' end, 10), case when $screen = 0 then monoright(cast(round(data.Nutr_Val / dv * water.Nutr_Val, 0) as int) || '% DV', 14) else monoright(round(data.Nutr_Val / 100.0 * water.Nutr_Val, 1) || ' ' || $Units, 14) end as Nutr_Val from food_des fd join nut_data water on fd.NDB_No = water.NDB_No and water.Nutr_No = 255 and water.Nutr_Val > 0.0 join nutr_def nd join nut_data data on fd.NDB_No = data.NDB_No and nd.Nutr_No = data.Nutr_No and data.Nutr_Val > 0.0 left join am_dv on nd.Nutr_No = am_dv.Nutr_No where Tagname = $Tagname and FdGrp_Cd = case when $FdGrp_Cd = 0 then FdGrp_Cd else $FdGrp_Cd end order by Nutr_Val desc }]
  }
 if {![info exists storydata]} {set storydata " "}
 foreach col {food field1 field2} name [list Food Quantity $::newstory] {
  .nut.ts.frranking.ranking heading $col \
  -text $name
  .nut.ts.frranking.ranking column $col \
  -width [font measure TkFixedFont $name]
  }
 foreach {ndb grams food field1 field2} $storydata {
  .nut.ts.frranking.ranking insert {} end \
  -id [list $ndb $grams] \
  -values [list $food $field1 $field2]
  foreach col {food field1 field2} {
   set len [font measure TkFixedFont "[set $col]  "]
   }
  }
 .nut.ts configure \
  -cursor $savecursor
 set width [winfo width .nut.ts.frgraph.canvas]
 set height [expr {[winfo height .nut.ts.frgraph.canvas] - 1}]
 .nut.ts.frgraph.canvas delete all


 catch {.nut.ts.frgraph.canvas create line [db eval { with meals (meal_id, Nutr_Val) as (select meal_id, sum(Gm_Wgt * Nutr_Val / 100.0) from mealfoods mf join nutr_def def join nut_data nd on mf.NDB_No = nd.NDB_No and def.Nutr_No = nd.Nutr_No and Tagname = $Tagname and meal_id >= $::FIRSTMEALts group by meal_id) select $width * (strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2)) - (select min(strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2))) from meals where meal_id >= $::FIRSTMEALts)) / (select max((strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2)) - (select min(strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2))) from meals where meal_id >= $::FIRSTMEALts))) from meals where meal_id >= $::FIRSTMEALts) as x, $height - (($height-2) * total(Nutr_Val) / (select max(y) from (select (strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2)) - (select min(strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2))) from meals where meal_id >= $::FIRSTMEALts)) / (select max((strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2)) - (select min(strftime('%J', substr(meal_id,1,4) || '-' || substr(meal_id,5,2) || '-' || substr(meal_id,7,2))) from meals where meal_id >= $::FIRSTMEALts))) from meals where meal_id >= $::FIRSTMEALts) as x, total(Nutr_Val) as y from meals where meal_id >= $::FIRSTMEALts group by x))) as y from meals where meal_id >= $::FIRSTMEALts group by x }] \
  -width [expr {$::magnify * 2}] \
  -fill "#FF7F00"}
 }

#end NewStory
}

set NutTabChange {

proc NutTabChange {} {

 uplevel #0 {
  set pathid [.nut select]
  if { $pathid == ".nut.vf" } {
   } elseif { $pathid == ".nut.am" } {
   } elseif { $pathid == ".nut.rm" } {
   } elseif { $pathid == ".nut.ts" } {
   if {$::StoryIsStale} {
    NewStory $::oldstorynut $::oldstoryscreen
    }
   } elseif { $pathid == ".nut.po" } {
   RefreshWeightLog
   } elseif { $pathid == ".nut.qn" } {
   update
   after 1250
   rename unknown ""
   rename _original_unknown unknown
   destroy .
   }
  }
 }

#end NutTabChange
}

set OunceChangevf {

proc OunceChangevf {args} {

 uplevel #0 {
  if {![string is double \
  -strict $ouncesvf]} { return }
  set gramsvf [expr {$ouncesvf * $ounce2gram}]
  }
 }

#end OunceChangevf
}

set PCF {

proc PCF {seq ndb args} {

 if {! $::BubbleMachineStatus} {
  set ::BubbleMachineStatus 1
  db eval {BEGIN}
  if {!$::ALTGUI} {
   grid remove .nut.rm.fsentry
   grid .nut.rm.bubblemachine
   } else {
   place forget .nut.rm.fsentry
   place .nut.rm.bubblemachine \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45
   }
  .nut.rm.bubblemachine start
  set ::lastbubble [after 500 TurnOffTheBubbleMachine]
  } else {
  after cancel $::lastbubble
  set ::lastbubble [after 500 TurnOffTheBubbleMachine]
  }
 set ndbName "::${ndb}"
 set dvName "::[lindex $::MealfoodPCF $seq]dv"
 if {$dvName == "::NULLdv"} {return}
 set rmName "::[lindex $::MealfoodPCF $seq]rm"
 upvar 0 $ndbName ndbvar $dvName dvvar $rmName rmvar
 set factor [lindex $::MealfoodPCFfactor $seq]
 set ::nutvalchange [expr {($dvvar - $rmvar) * 100.0 / $dvvar}]
 if {$::nutvalchange < 0.2 && $::nutvalchange > \
  -0.2} {return}
 if {[expr {($dvvar - $rmvar)}] == 0.0} {return}
 if {($::GRAMSopt && abs($ndbvar) >= 1350.0) || (!$::GRAMSopt && abs($ndbvar) >= 135.0)} {
  if {$ndbvar > 0.0} {   set looong1 ""
   db eval {select Long_Desc as looong1, food_des.NDB_No as looong1ndb from food_des, mealfoods where food_des.NDB_No = mealfoods.NDB_No and meal_date = $::currentmeal / 100 and meal = $::currentmeal % 100 and mhectograms < 0.0 order by mhectograms asc limit 1} { }
   } else {
   db eval {select Long_Desc as looong1, food_des.NDB_No as looong1ndb from food_des, mealfoods where food_des.NDB_No = mealfoods.NDB_No and meal_date = $::currentmeal / 100 and meal = $::currentmeal % 100 and mhectograms > 0.0 order by mhectograms desc limit 1} { }
   }
  db eval {select Long_Desc as looong from food_des where NDB_No = $ndb} { }
  ${::rmMenu}.menu.foodPCF${seq} current 0
  catch [list badPCF $looong $looong1 NULL 1]
  if {$::GRAMSopt} {set ndbvar 0} else {set ndbvar 0.0}
  db eval {update mealfoods set mhectograms = 0.0 where NDB_No = $ndb and meal_date = $::currentmeal / 100 and meal = $::currentmeal % 100}
  db eval {update weight set Seq = origSeq, whectograms = orighectograms, Amount = origAmount where NDB_No = $ndb}
  setPCF $seq $ndb ::PCFchoice${ndb}
  return
  }
 set upd {update mealfoods set mhectograms = mhectograms + (0.5 * $factor * ($dvvar - $rmvar)) where NDB_No = $ndb and meal_date = $::currentmeal / 100 and meal = $::currentmeal % 100}

 db eval $upd

 after cancel $::lastrmq
 set ::lastrmq [after idle {
  db eval {select * from pcf} { }
  }]

 after cancel $::lastamrm
 set ::lastamrm [after idle {
  db eval {select * from rm} { }
  db eval {select * from am} { }
  }]

 after cancel $::lastac
 set ::lastac [after idle auto_cal]

 }

#end PCF
}

set RecipeSaveAs {

proc RecipeSaveAs {args} {

db eval {drop table if exists z_tcl_recipe_des; drop table if exists z_tcl_recipe_data; CREATE temp TABLE z_tcl_recipe_des (NDB_No int primary key, FdGrp_Cd int, Long_Desc text, Shrt_Desc text, Ref_desc text, Refuse integer, Pro_Factor real, Fat_Factor real, CHO_Factor real); CREATE temp TABLE z_tcl_recipe_data (NDB_No int, Nutr_No int, Nutr_Val real, primary key(NDB_No, Nutr_No));}
db eval {select count(*) as foodcount from mealfoods where meal_id = $::currentmeal} { }
if {$foodcount == 0} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "A recipe must include at least one food."
 return
 }
db eval {select total(Gm_Wgt) as "::RecipeWeight" from mealfoods where meal_id = $::currentmeal} { }
if {$::RecipeWeight <= 0.0} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "A recipe must have a weight greater than zero."
 return
 }
db eval {BEGIN}
db eval {select case when (select max(NDB_No) from food_des) > 98999 then (select max(NDB_No) from food_des) + 1 else 99000 end as recipe_NDB_No} { }
db eval {insert into z_tcl_recipe_data select $recipe_NDB_No, Nutr_No, Nutr_Val / (select meals_per_day from options) from rm_analysis}
db eval {select fdgrp_cd as recipe_fdgrp_cd, sum(gm_wgt) from mealfoods natural join food_des where meal_id = $::currentmeal group by recipe_fdgrp_cd limit 1} { }
db eval {insert into z_tcl_recipe_des values ($recipe_NDB_No, $recipe_fdgrp_cd, NULL, NULL, NULL, 0, (select nutr_val from z_tcl_recipe_data where nutr_no = 3000) / (select nutr_val from z_tcl_recipe_data where nutr_no = 203), (select nutr_val from z_tcl_recipe_data where nutr_no = 3001) / (select nutr_val from z_tcl_recipe_data where nutr_no = 204), (select nutr_val from z_tcl_recipe_data where nutr_no = 3002) / (select nutr_val from z_tcl_recipe_data where nutr_no = 205))}
db eval {COMMIT}
db nullvalue ""
db eval {select macropct as "::ENERC_KCAL1ar", n6balance as "::FAPU1ar" from rm_analysis_header} { }
db eval {select '::' || Tagname || 'ar' as var, round(nutr_val,1) as val from z_tcl_recipe_data join nutr_def using (nutr_no)} {
 set $var $val
 }
db eval {select '::' || Tagname || 'ardv' as var, cast(round(100.0 * nutr_val / dv_default) as int) as val from z_tcl_recipe_data join nutr_def using (nutr_no) where dv_default > 0.0} {
 set $var $val
 }
db eval {select '::CHO_NONFIBar1' as var, cast(round(nutr_val) as int) as val from z_tcl_recipe_data where nutr_no = 2000} {
 set $var $val
 }
#db eval {select * from ar} { }
db nullvalue "\[No Data\]"
.nut hide .nut.rm
.nut add .nut.ar
.nut select .nut.ar
foreach var [info vars ::*ar] {
 set tag [string range $var 2 end-2]
 trace add variable $var write [list RecipeMod $tag]
 }
foreach var [info vars ::*ardv] {
 set tag [string range $var 2 end-4]
 trace add variable $var write [list RecipeModdv $tag]
 }
trace add variable ::CHO_NONFIBar1 write RecipeMod1

set ::RecipeName {}
set ::RecipeServNum {}
set ::RecipeServUnit {}
set ::RecipeServUnitNum {}
set ::RecipeServWeight {}
}

#end RecipeSaveAs
}

set RecipeMod1 {

proc RecipeMod1 {args} {

db eval {select nutr_val as oldval from z_tcl_recipe_data where nutr_no = 2000} { }
db eval {update z_tcl_recipe_data set nutr_val = cast($::CHO_NONFIBar1 as real) where nutr_no = 2000}
db eval {select nutr_val - $oldval as diff from z_tcl_recipe_data where nutr_no = 2000} { }
trace remove variable ::CHO_NONFIBar write [list RecipeMod CHO_NONFIB]
db eval {select round(nutr_val,1) as "::CHO_NONFIBar" from z_tcl_recipe_data where nutr_no = 2000} { }
trace add variable ::CHO_NONFIBar write [list RecipeMod CHO_NONFIB]
trace remove variable ::CHOCDFar write [list RecipeMod CHOCDF]
trace remove variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 205}
db eval {select round(nutr_val,1) as "::CHOCDFar" from z_tcl_recipe_data where nutr_no = 205} { }
db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 205)) as int) as "::CHOCDFardv" from z_tcl_recipe_data where nutr_no = 205} { }
trace add variable ::CHOCDFar write [list RecipeMod CHOCDF]
trace add variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
db eval {update z_tcl_recipe_data set nutr_val = (select CHO_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 205) where nutr_no = 3002}

}

#end RecipeMod1
}

set RecipeModdv {

proc RecipeModdv {tag var args} {

set varstarget ::${tag}ar
db eval {select dv_default as thedv from nutr_def where tagname = $tag} { }
upvar #0 $var thevar $varstarget thevarstarget
if {[string is double \
  -strict $thevar]} {
set $varstarget [expr {$thedv * $thevar / 100.0}]
 } else {
set $varstarget {}
 }
}

#end RecipeModdv
}

set RecipeMod {

proc RecipeMod {tag var args} {

db eval "select dv_default, Nutr_No from nutr_def where tagname = '$tag'" { }
db eval {select nutr_val as oldval from z_tcl_recipe_data where nutr_no = $Nutr_No} { }
db eval "update z_tcl_recipe_data set nutr_val = cast($$var as real) where nutr_no = $Nutr_No"
db eval {select nutr_val - $oldval as diff from z_tcl_recipe_data where nutr_no = $Nutr_No} { }

set dvvar ::${tag}ardv
if {[info exists $dvvar]} {
 trace remove variable $dvvar write [list RecipeModdv $tag]
 db eval "select cast(round(100.0 * nutr_val / $dv_default) as int) as \"$dvvar\" from z_tcl_recipe_data where nutr_no = $Nutr_No" { }
 trace add variable $dvvar write [list RecipeModdv $tag]
 }

if {$tag == "CHO_NONFIB"} {
 if {[info exists ::CHO_NONFIBar1]} {
  trace remove variable ::CHO_NONFIBar1 write RecipeMod1
  db eval {select cast(round(nutr_val) as int) as "::CHO_NONFIBar1" from z_tcl_recipe_data where nutr_no = 2000} { }
  trace add variable ::CHO_NONFIBar1 write RecipeMod1
  }
 trace remove variable ::CHOCDFar write [list RecipeMod CHOCDF]
 trace remove variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 205}
 db eval {select round(nutr_val,1) as "::CHOCDFar" from z_tcl_recipe_data where nutr_no = 205} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 205)) as int) as "::CHOCDFardv" from z_tcl_recipe_data where nutr_no = 205} { }
 trace add variable ::CHOCDFar write [list RecipeMod CHOCDF]
 trace add variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
 db eval {update z_tcl_recipe_data set nutr_val = (select CHO_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 205) where nutr_no = 3002}

 } elseif {$tag == "FIBTG"} {
 trace remove variable ::CHOCDFar write [list RecipeMod CHOCDF]
 trace remove variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 205}
 db eval {select round(nutr_val,1) as "::CHOCDFar" from z_tcl_recipe_data where nutr_no = 205} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 205)) as int) as "::CHOCDFardv" from z_tcl_recipe_data where nutr_no = 205} { }
 trace add variable ::CHOCDFar write [list RecipeMod CHOCDF]
 trace add variable ::CHOCDFardv write [list RecipeModdv CHOCDF]
 db eval {update z_tcl_recipe_data set nutr_val = (select CHO_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 205) where nutr_no = 3002}

 } elseif {$tag == "CHOCDF"} {
 db eval {update z_tcl_recipe_data set nutr_val = (select CHO_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 205) where nutr_no = 3002}
 trace remove variable ::CHO_NONFIBar write [list RecipeMod CHO_NONFIB]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2000}
 db eval {select round(nutr_val,1) as "::CHO_NONFIBar" from z_tcl_recipe_data where nutr_no = 2000} { }
 trace add variable ::CHO_NONFIBar write [list RecipeMod CHO_NONFIB]
 if {[info exists ::CHO_NONFIBar1]} {
  trace remove variable ::CHO_NONFIBar1 write RecipeMod1
  db eval {select cast(round(nutr_val) as int) as "::CHO_NONFIBar1" from z_tcl_recipe_data where nutr_no = 2000} { }
  trace add variable ::CHO_NONFIBar1 write RecipeMod1
  }
 if {[info exists ::CHO_NONFIBardv]} {
  trace remove variable ::CHO_NONFIBardv write RecipeModdv
  db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2000)) as int) as "::CHO_NONFIBardv" from z_tcl_recipe_data where nutr_no = 2000} { }
  trace add variable ::CHO_NONFIBardv write RecipeModdv
  }

 } elseif {$tag == "PROCNT"} {
 db eval {update z_tcl_recipe_data set nutr_val = (select Pro_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 203) where nutr_no = 3000}

 } elseif {$tag == "FAT"} {
 db eval {update z_tcl_recipe_data set nutr_val = (select Fat_Factor from z_tcl_recipe_des) * (select nutr_val from z_tcl_recipe_data where nutr_no = 204) where nutr_no = 3001}

 } elseif {$tag == "ENERC_KJ"} {
 trace remove variable ::ENERC_KCALar write [list RecipeMod ENERC_KCAL]
 trace remove variable ::ENERC_KCALardv write [list RecipeModdv ENERC_KCAL]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 268) / 4.184 where nutr_no = 208}
 db eval {select round(nutr_val,1) as "::ENERC_KCALar", cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 208)) as int) as "::ENERC_KCALardv" from z_tcl_recipe_data where nutr_no = 208} { }
 trace add variable ::ENERC_KCALar write [list RecipeMod ENERC_KCAL]
 trace add variable ::ENERC_KCALardv write [list RecipeModdv ENERC_KCAL]

 } elseif {$tag == "ENERC_KCAL"} {
 trace remove variable ::ENERC_KJar write [list RecipeMod ENERC_KJ]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 208) * 4.184 where nutr_no = 268}
 db eval {select round(nutr_val,1) as "::ENERC_KJar" from z_tcl_recipe_data where nutr_no = 268} { }
 trace add variable ::ENERC_KJar write [list RecipeMod ENERC_KJ]

 } elseif {$tag == "VITE"} {
 trace remove variable ::TOCPHAar write [list RecipeMod TOCPHA]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2008) where nutr_no = 323}
 db eval {select round(nutr_val,1) as "::TOCPHAar" from z_tcl_recipe_data where nutr_no = 323} { }
 trace add variable ::TOCPHAar write [list RecipeMod TOCPHA]

 } elseif {$tag == "TOCPHA"} {
 trace remove variable ::VITEar write [list RecipeMod VITE]
 trace remove variable ::VITEardv write [list RecipeModdv VITE]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 323) where nutr_no = 2008}
 db eval {select round(nutr_val,1) as "::VITEar" from z_tcl_recipe_data where nutr_no = 323} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2008),0) as int) as "::VITEardv" from z_tcl_recipe_data where nutr_no = 2008} { }
 trace add variable ::VITEar write [list RecipeMod VITE]
 trace add variable ::VITEardv write [list RecipeModdv VITE]

 } elseif {$tag == "EPA"} {
 trace remove variable ::F20D5ar write [list RecipeMod F20D5]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2004) where nutr_no = 629}
 db eval {select round(nutr_val,1) as "::F20D5ar" from z_tcl_recipe_data where nutr_no = 629} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::F20D5ar write [list RecipeMod F20D5]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F20D5"} {
 trace remove variable ::EPAar write [list RecipeMod EPA]
 trace remove variable ::EPAardv write [list RecipeModdv EPA]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 629) where nutr_no = 2004}
 db eval {select round(nutr_val,1) as "::EPAar" from z_tcl_recipe_data where nutr_no = 2004} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2004),0) as int) as "::EPAardv" from z_tcl_recipe_data where nutr_no = 2004} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::EPAar write [list RecipeMod EPA]
 trace add variable ::EPAardv write [list RecipeModdv EPA]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "DHA"} {
 trace remove variable ::F22D6ar write [list RecipeMod F22D6]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2005) where nutr_no = 621}
 db eval {select round(nutr_val,1) as "::F22D6ar" from z_tcl_recipe_data where nutr_no = 621} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::F22D6ar write [list RecipeMod F22D6]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F22D6"} {
 trace remove variable ::DHAar write [list RecipeMod DHA]
 trace remove variable ::DHAardv write [list RecipeModdv DHA]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 621) where nutr_no = 2005}
 db eval {select round(nutr_val,1) as "::DHAar" from z_tcl_recipe_data where nutr_no = 2005} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2005),0) as int) as "::DHAardv" from z_tcl_recipe_data where nutr_no = 2005} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::DHAar write [list RecipeMod DHA]
 trace add variable ::DHAardv write [list RecipeModdv DHA]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F20D3N3"} {
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F21D5"} {
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F22D5"} {
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3006}
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "ALA"} {
 trace remove variable ::F18D3ar write [list RecipeMod F18D3]
 trace remove variable ::F18D3CN3ar write [list RecipeMod F18D3CN3]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 619}
 db eval {select round(nutr_val,1) as "::F18D3ar" from z_tcl_recipe_data where nutr_no = 619} { }
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2003) where nutr_no = 851}
 db eval {select round(nutr_val,1) as "::F18D3CN3ar" from z_tcl_recipe_data where nutr_no = 851} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3005}
 trace add variable ::F18D3ar write [list RecipeMod F18D3]
 trace add variable ::F18D3CN3ar write [list RecipeMod F18D3CN3]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F18D3CN3"} {
 db eval {select nutr_val as oldval from z_tcl_recipe_data where nutr_no = 2003} { }
 trace remove variable ::ALAar write [list RecipeMod ALA]
 trace remove variable ::F18D3ar write [list RecipeMod F18D3]
 trace remove variable ::ALAardv write [list RecipeModdv ALA]
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 851) where nutr_no = 2003}
 db eval {select nutr_val - $oldval as diff from z_tcl_recipe_data where nutr_no = 2003} { }
 db eval {select round(nutr_val,1) as "::ALAar" from z_tcl_recipe_data where nutr_no = 2003} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2003),0) as int) as "::ALAardv" from z_tcl_recipe_data where nutr_no = 2003} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3005}
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 619}
 db eval {select round(nutr_val,1) as "::F18D3ar" from z_tcl_recipe_data where nutr_no = 619} { }
 trace add variable ::ALAar write [list RecipeMod ALA]
 trace add variable ::F18D3ar write [list RecipeMod F18D3]
 trace add variable ::ALAardv write [list RecipeModdv ALA]
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "F18D4"} {
 trace remove variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace remove variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2007}
 db eval {select round(nutr_val,1) as "::OMEGA3ar" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2007),0) as int) as "::OMEGA3ardv" from z_tcl_recipe_data where nutr_no = 2007} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3005}
 trace add variable ::OMEGA3ar write [list RecipeMod OMEGA3]
 trace add variable ::OMEGA3ardv write [list RecipeModdv OMEGA3]

 } elseif {$tag == "LA"} {
 trace remove variable ::F18D2ar write [list RecipeMod F18D2]
 trace remove variable ::F18D2CN6ar write [list RecipeMod F18D2CN6]
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 618}
 db eval {select round(nutr_val,1) as "::F18D2ar" from z_tcl_recipe_data where nutr_no = 618} { }
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2001) where nutr_no = 675}
 db eval {select round(nutr_val,1) as "::F18D2CN6ar" from z_tcl_recipe_data where nutr_no = 675} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3003}
 trace add variable ::F18D2ar write [list RecipeMod F18D2]
 trace add variable ::F18D2CN6ar write [list RecipeMod F18D2CN6]
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 } elseif {$tag == "F18D2CN6"} {
 db eval {select nutr_val as oldval from z_tcl_recipe_data where nutr_no = 2001} { }
 trace remove variable ::LAar write [list RecipeMod LA]
 trace remove variable ::F18D2ar write [list RecipeMod F18D2]
 trace remove variable ::LAardv write [list RecipeModdv LA]
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 675) where nutr_no = 2001}
 db eval {select nutr_val - $oldval as diff from z_tcl_recipe_data where nutr_no = 2001} { }
 db eval {select round(nutr_val,1) as "::LAar" from z_tcl_recipe_data where nutr_no = 2001} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2001),0) as int) as "::LAardv" from z_tcl_recipe_data where nutr_no = 2001} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3003}
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 618}
 db eval {select round(nutr_val,1) as "::F18D2ar" from z_tcl_recipe_data where nutr_no = 618} { }
 trace add variable ::LAar write [list RecipeMod LA]
 trace add variable ::F18D2ar write [list RecipeMod F18D2]
 trace add variable ::LAardv write [list RecipeModdv LA]
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 } elseif {$tag == "F20D3N6"} {
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3004}
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 } elseif {$tag == "AA"} {
 trace remove variable ::F20D4ar write [list RecipeMod F20D4]
 trace remove variable ::F20D4N6ar write [list RecipeMod F20D4N6]
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 620}
 db eval {select round(nutr_val,1) as "::F20D4ar" from z_tcl_recipe_data where nutr_no = 620} { }
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 2001) where nutr_no = 855}
 db eval {select round(nutr_val,1) as "::F20D4N6ar" from z_tcl_recipe_data where nutr_no = 855} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3003}
 trace add variable ::F20D4ar write [list RecipeMod F20D4]
 trace add variable ::F20D4N6ar write [list RecipeMod F20D4N6]
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 } elseif {$tag == "F20D4N6"} {
 db eval {select nutr_val as oldval from z_tcl_recipe_data where nutr_no = 2002} { }
 trace remove variable ::AAar write [list RecipeMod AA]
 trace remove variable ::F20D4ar write [list RecipeMod F20D4]
 trace remove variable ::AAardv write [list RecipeModdv AA]
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = (select nutr_val from z_tcl_recipe_data where nutr_no = 855) where nutr_no = 2002}
 db eval {select nutr_val - $oldval as diff from z_tcl_recipe_data where nutr_no = 2002} { }
 db eval {select round(nutr_val,1) as "::AAar" from z_tcl_recipe_data where nutr_no = 2002} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2002),0) as int) as "::AAardv" from z_tcl_recipe_data where nutr_no = 2002} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3004}
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 620}
 db eval {select round(nutr_val,1) as "::F20D4ar" from z_tcl_recipe_data where nutr_no = 620} { }
 trace add variable ::AAar write [list RecipeMod AA]
 trace add variable ::F20D4ar write [list RecipeMod F20D4]
 trace add variable ::AAardv write [list RecipeModdv AA]
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 } elseif {$tag == "F22D4"} {
 trace remove variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace remove variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 2006}
 db eval {select round(nutr_val,1) as "::OMEGA6ar" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {select cast(round(100.0 * nutr_val / (select dv_default from nutr_def where nutr_no = 2006),0) as int) as "::OMEGA6ardv" from z_tcl_recipe_data where nutr_no = 2006} { }
 db eval {update z_tcl_recipe_data set nutr_val = nutr_val + $diff where nutr_no = 3004}
 trace add variable ::OMEGA6ar write [list RecipeMod OMEGA6]
 trace add variable ::OMEGA6ardv write [list RecipeModdv OMEGA6]

 }
}

#end RecipeMod
}

set RecipeCancel {

proc RecipeCancel {args} {
.nut hide .nut.ar
.nut add .nut.rm
.nut select .nut.rm
db eval {drop table z_tcl_recipe_data; drop table z_tcl_recipe_des}
foreach var [info vars ::*ar] {
 set tag [string range $var 2 end-2]
 trace remove variable $var write [list RecipeMod $tag]
 }
foreach var [info vars ::*ardv] {
 set tag [string range $var 2 end-4]
 trace remove variable $var write [list RecipeModdv $tag]
 }
trace remove variable ::CHO_NONFIBar1 write RecipeMod1
}

#end RecipeCancel
}

set RecipeDone {

proc RecipeDone {args} {
set ::RecipeName [string trimright $::RecipeName " "]
if {$::RecipeName == {}} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "The recipe name must not be blank."
 return
 }
db eval {update z_tcl_recipe_des set Long_Desc = $::RecipeName, Shrt_Desc = substr($::RecipeName,1,60)}
set count [db eval {select count(*) from food_des where Long_Desc = (select Long_Desc from z_tcl_recipe_des) or Shrt_Desc = (select Shrt_Desc from z_tcl_recipe_des)}]
if {$count > 0} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "This recipe name is a duplicate of a food name already in the database."
 return
 }
if {![string is double \
  -strict $::RecipeServNum]} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"Number of servings recipe makes\" must be a decimal number greater than zero."
 return
 } elseif {$::RecipeServNum <= 0.0} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"Number of servings recipe makes\" must be a decimal number greater than zero."
 return
 }
if {$::RecipeServUnit == {}} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "The \"Serving Unit\" must not be blank."
 return
 }
if {![string is double \
  -strict $::RecipeServUnitNum]} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"Number of units in one serving\" must be a decimal number greater than zero."
 return
 } elseif {$::RecipeServUnitNum <= 0.0} {
 tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"Number of units in one serving\" must be a decimal number greater than zero."
 return
 }
if {[string is double \
  -strict $::RecipeServWeight]} {
 if {$::GRAMSopt} {
  set newweight [expr {$::RecipeServWeight * $::RecipeServNum / 100.0}]
  } else {
  set newweight [expr {$::RecipeServWeight * $::RecipeServNum * .28349523}]
  }
 set diff [expr {100.0 * ($newweight - $::RecipeWeight)}] db eval {update z_tcl_recipe_data set nutr_val = case when nutr_val + $diff < 0.0 then 0.0 else nutr_val + $diff end where nutr_no = 255}
 set ::RecipeWeight $newweight
 }
db eval {update z_tcl_recipe_data set nutr_val = 100.0 * nutr_val / $::RecipeWeight}
set ndb [db eval {select NDB_No from z_tcl_recipe_des}]
db eval {insert into food_des select * from z_tcl_recipe_des}
db eval {insert into nut_data select * from z_tcl_recipe_data}
db eval {insert into weight select $ndb, 99, 100, 'grams', 100, 99, 100}
db eval {insert into weight select $ndb, 1, $::RecipeServUnitNum, $::RecipeServUnit, $::RecipeWeight / $::RecipeServNum, 1, $::RecipeWeight / $::RecipeServNum}
 thread::send \
  -async $::SQL_THREAD [list db eval {delete from currentmeal}]
thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
set count \
  -1
foreach mf $::MealfoodStatus {
 incr count
 if {$mf == "Hidden" || $mf == "Available"} {continue}
 after 300 [list MealfoodDelete $count $mf 0]
 }
RecipeCancel
FoodChoicevf_alt $ndb [expr {$::RecipeWeight / $::RecipeServNum}] 0
}

#end RecipeDone
}

set ServingChange {

proc ServingChange {args} {

 uplevel #0 {
  db eval {update weight set Seq = "0" where NDB_No = $NDB_Novf and Msre_Desc = $Msre_Descvf}
  dropoutvf
  db eval {select NDB_No as NDB_Novf from food_des where Long_Desc = $ld limit 1} {
   db eval {insert into z_tcl_jobqueue values (null, 'view_foods', $NDB_Novf, null, null)}
   thread::send \
  -async $::SQL_THREAD {job_view_foods}
   }
  set Long_Desc $ld
  db eval {select case when Refuse is not null then Refuse || "%" else Refuse end as Refusevf, setRefDesc(Ref_desc) from food_des where NDB_No = $NDB_Novf} { }
  db eval {select cast(round(Gm_Wgt) as int) as gramsvf, round(8.0 * Gm_Wgt / 28.35, 0) / 8.0 as ouncesvf, cast(round(Gm_Wgt * 0.01 * Nutr_Val) as int) as caloriesvf, round(8.0 * Amount, 0) / 8.0 as Amountvf, Msre_Desc as Msre_Descvf, 28.349523 as ounce2gram, case when Nutr_Val is null or Nutr_Val = 0.0 then 0.0 else 100.0/Nutr_Val end as cal2gram, origGm_Wgt/origAmount as Amount2gram from pref_Gm_Wgt join nut_data using (NDB_No) where NDB_No = $NDB_Novf and Nutr_No = 208} { }
  set servingsizes [db eval {select distinct Msre_Desc from weight where NDB_No = $NDB_Novf order by Seq limit 100 offset 1}]
  .nut.vf.cb configure \
  -values $servingsizes
  tuneinvf
  }
 }

#end ServingChange
}

set SetDefanal {

proc SetDefanal {args} {

if {![string is integer \
  -strict $::meals_to_analyze_am]} {return}

thread::send \
  -async $::SQL_THREAD [list db eval "insert into z_tcl_jobqueue values (null, 'defanal_am', cast($::meals_to_analyze_am as int), null, null)"]
thread::send \
  -async $::SQL_THREAD [list after idle job_defanal_am]
}

#end SetDefanal
}

set job_defanal_am {

proc job_defanal_am {args} {

db eval {select count(*) as jobcount from z_tcl_jobqueue where jobtype = 'defanal_am'} { }
if {$jobcount == 0} {return}

db eval {select jobnum, jobint from z_tcl_jobqueue where jobtype = 'defanal_am' order by jobnum desc limit 1} { }

db eval {delete from z_tcl_jobqueue where jobtype = 'defanal_am' and jobnum <= $jobnum; update options set defanal_am = $jobint}

db eval {select maxmeal from am_analysis_header} { }

if {$maxmeal < $jobint} {
 thread::send \
  -async $::GUI_THREAD [list set ::meals_to_analyze_am $maxmeal]
 return
 }

job_daily_value_refresh
}

#end job_defanal_am
}

set job_mealfood_qty {

proc job_mealfood_qty {ndb} {

db eval {select count(*) as jobcount from z_tcl_jobqueue where jobtype = 'mealfood_qty' and jobint = $ndb} { }
if {$jobcount == 0} {return}

db eval {select jobreal, jobtext from z_tcl_jobqueue where jobnum = (select max(jobnum) from z_tcl_jobqueue where jobtype = 'mealfood_qty' and jobint = $ndb)} { }

db eval {delete from z_tcl_jobqueue where jobtype = 'mealfood_qty' and jobint = $ndb and jobnum <= $jobnum}

db eval {select long_desc from food_des where ndb_no = $ndb} { }
if {[catch { db eval {update mealfoods set Gm_Wgt = $jobreal where NDB_No = $ndb and meal_id = cast($jobtext as int)} }]} {
 thread::send \
  -async $::GUI_THREAD [list badPCF null null null 4]
 return
 }

job_daily_value_refresh $ndb
}

#end job_mealfood_qty
}

set job_opt_change {

proc job_opt_change {tag} {

db eval {select count(*) as jobcount from z_tcl_jobqueue where jobtype = 'opt_change' and jobtext = $tag} { }
if {$jobcount == 0} {return}

db eval {select jobnum, jobreal from z_tcl_jobqueue where jobnum = (select max(jobnum) from z_tcl_jobqueue where jobtype = 'opt_change' and jobtext = $tag)} { }

db eval {delete from z_tcl_jobqueue where jobtype = 'opt_change' and jobtext = $tag and jobnum <= $jobnum}

db eval {update nutr_def set nutopt = $jobreal where tagname = $tag}

job_daily_value_refresh $tag
}

#end job_opt_change
}

set job_daily_value_refresh {

proc job_daily_value_refresh {args} {

db eval {select maxmeal, mealcount, caloriebutton as "::caloriebutton", format_meal_id(firstmeal) as "::FIRSTMEALam", firstmeal as "::FIRSTMEALts", format_meal_id(lastmeal) as "::LASTMEALam", n6balance as "::FAPU1am", macropct as "::ENERC_KCAL1am" from am_analysis_header} {thread::send \
  -async $::GUI_THREAD [list set ::caloriebutton $::caloriebutton]
thread::send \
  -async $::GUI_THREAD [list set ::FIRSTMEALam $::FIRSTMEALam]
thread::send \
  -async $::GUI_THREAD [list set ::FIRSTMEALts $::FIRSTMEALts]
thread::send \
  -async $::GUI_THREAD [list set ::LASTMEALam $::LASTMEALam]
thread::send \
  -async $::GUI_THREAD [list set ::FAPU1am $::FAPU1am]
thread::send \
  -async $::GUI_THREAD [list set ::ENERC_KCAL1am $::ENERC_KCAL1am]
thread::send \
  -async $::GUI_THREAD [list set ::mealcount $mealcount]
thread::send \
  -async $::GUI_THREAD {if {$::mealcount < $::meals_to_analyze_am} {SetDefanal}}
if {$maxmeal == 0} {
 thread::send \
  -async $::GUI_THREAD {.nut.am.mealsb configure \
  -from 0 \
  -to 0}
 } else {
 thread::send \
  -async $::GUI_THREAD [list .nut.am.mealsb configure \
  -from 1 \
  -to $maxmeal]
 }

}

if {$maxmeal < $mealcount} {
 thread::send \
  -async $::GUI_THREAD [list set ::meals_to_analyze_am $maxmeal]
 }

db eval {select "::" || Tagname || 'dv' as tag, round(dv, 1) as dv from am_dv natural join nutr_def} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $dv]
 }
db eval {select '::' || Tagname || 'am' as tag, case when null_value = 0 then round(Nutr_Val, 1) else null end as val from am_analysis natural join nutr_def} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }
db eval {select '::' || Tagname || 'amdv' as tag, case when null_value = 0 then cast(round(100.0 + dvpct_offset, 0) as int) else null end as val from am_analysis natural join am_dv natural join nutr_def} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }
db eval {select case when null_value = 0 then cast(round(Nutr_Val, 0) as int) else null end as "::CHO_NONFIBam1" from am_analysis where Nutr_No = 2000} {
thread::send \
  -async $::GUI_THREAD [list set ::CHO_NONFIBam1 $::CHO_NONFIBam1]
 }

if {$::NDB_Novf != 0} {
 db eval {select '::' || Tagname || 'vfdv' as tag, cast(round($::Gm_Wgtvf * Nutr_Val / dv) as int) as val from nutr_def nd left join am_dv ad on nd.Nutr_No = ad.Nutr_No left join nut_data d on d.NDB_No = $::NDB_Novf and nd.Nutr_No = d.Nutr_No where dv_default > 0.0} {
  thread::send \
  -async $::GUI_THREAD [list set $tag $val]
  }
 }

set parm [lindex $args 0]
if {[string is integer \
  -strict $parm]} {
 db eval {select '::' || ndb_no as var, case when grams = 1 then cast(round(gm_wgt,0) as int) else round(8.0 * Gm_Wgt / 28.349523,0) / 8.0 end as val from mealfoods, options where meal_id = currentmeal and nutr_no is not null and ndb_no != $parm} {
  thread::send \
  -async $::GUI_THREAD [list set $var $val]
  }
 } elseif {$parm == "" } {
  thread::send \
  -async $::GUI_THREAD {RefreshMealfoodQuantities}
 } else {
 db eval {select '::' || ndb_no as var, case when grams = 1 then cast(round(gm_wgt,0) as int) else round(8.0 * Gm_Wgt / 28.3495231,0) / 8.0 end as val from mealfoods, options where meal_id = currentmeal and nutr_no is not null} {
  thread::send \
  -async $::GUI_THREAD [list set $var $val]
  }
 }

db eval {select n6balance as "::FAPU1rm", macropct as "::ENERC_KCAL1rm" from rm_analysis_header} {thread::send \
  -async $::GUI_THREAD [list set ::FAPU1rm $::FAPU1rm]
thread::send \
  -async $::GUI_THREAD [list set ::ENERC_KCAL1rm $::ENERC_KCAL1rm]
if {$::FAPU1rm == "\[No Data\]"} {
 thread::send \
  -async $::GUI_THREAD [list set ::FAPU1rm "0 / 0"]
 }
if {$::ENERC_KCAL1rm == "\[No Data\]"} {
 thread::send \
  -async $::GUI_THREAD [list set ::ENERC_KCAL1rm "0 / 0 / 0"]
 }

}

db eval {select '::' || Tagname || 'rm' as tag, case when null_value = 0 then round(Nutr_Val, 1) else null end as val from rm_analysis natural join nutr_def} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }
db eval {select '::' || Tagname || 'rmdv' as tag, case when null_value = 0 then cast(round(100.0 + dvpct_offset, 0) as int) else null end as val from rm_analysis natural join rm_dv natural join nutr_def} {
 thread::send \
  -async $::GUI_THREAD [list set $tag $val]
 }
db eval {select case when null_value = 0 then cast(round(Nutr_Val, 0) as int) else null end as "::CHO_NONFIBrm1" from rm_analysis where Nutr_No = 2000} {
thread::send \
  -async $::GUI_THREAD [list set ::CHO_NONFIBrm1 $::CHO_NONFIBrm1]
 }
thread::send \
  -async $::GUI_THREAD [list set ::StoryIsStale 1]
}

#end job_daily_value_refresh
}

set SetMealRange_am {

proc SetMealRange_am {args} {

 uplevel #0 {
  if { $::FIRSTMEALam == "" } {
   set mealrange ""
   .nut.am.meallabel configure \
  -text " meals:"
   return
   }
  if { $::FIRSTMEALam == $::LASTMEALam } {
   set mealrange "Meal $::FIRSTMEALam"
   .nut.am.meallabel configure \
  -text " meal:"
   } else {
   set mealrange "Meals $::FIRSTMEALam through $::LASTMEALam"
   .nut.am.meallabel configure \
  -text " meals:"
   }
  }
 }

#end SetMealRange_am
}

set SetMPD {

proc SetMPD {mpd} {

thread::send \
  -async $::SQL_THREAD [list job_SetMPD $mpd]
set ::oldmpd $::meals_per_day
set ::meals_per_day $mpd

.nut.rm.setmpd.m delete 0 end
if {$::meals_per_day != 1} {
 .nut.rm.setmpd.m add command \
  -label "Set 1 meal per day" \
  -command [list SetMPD 1]
 } else {
 .nut.rm.setmpd.m add command \
  -label "Set 1 meal per day" \
  -command [list SetMPD 1] \
  -state disabled
 }
for {set i 2} {$i < 20} {incr i} {
 if {$i != $::meals_per_day} {
  .nut.rm.setmpd.m add command \
  -label "Set $i meals per day" \
  -command [list SetMPD $i]
  } else {
  .nut.rm.setmpd.m add command \
  -label "Set $i meals per day" \
  -command [list SetMPD $i] \
  -state disabled
  }
 }

}

#end SetMPD
}

set job_SetMPD {

proc job_SetMPD {mpd} {

db eval {update options set meals_per_day = $mpd}
thread::send \
  -async $::GUI_THREAD [list SetMealBase]
thread::send \
  -async $::GUI_THREAD {tk_messageBox \
  -type ok \
  -title $::version \
  -message "Meals per day changed from $::oldmpd to $::meals_per_day.  Existing meals were archived and will be copied back into the active table if meals per day is ever changed back to $::oldmpd."}
db eval {select defanal_am as "::meals_to_analyze_am" from options} { }
thread::send \
  -async $::GUI_THREAD [list set ::meals_to_analyze_am $::meals_to_analyze_am]
thread::send \
  -async $::GUI_THREAD [list job_daily_value_refresh]

}

#end job_SetMPD
}

set SwitchToAnalysis {

proc SwitchToAnalysis {args} {

 .nut.rm.analysismeal configure \
  -text "Menu" \
  -command SwitchToMenu
 if {!$::ALTGUI} {
  grid remove $::rmMainPane
  grid remove .nut.rm.grams
  grid remove .nut.rm.ounces
 #grid remove .nut.rm.recipebutton
  set ::rmMainPane .nut.rm.nbw
  grid $::rmMainPane
  } else {
  place forget $::rmMainPane
  place forget .nut.rm.grams
  place forget .nut.rm.ounces
 #place forget .nut.rm.recipebutton
  set ::rmMainPane .nut.rm.nbw
  place $::rmMainPane \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
  }
 }

#end SwitchToAnalysis
}

set SwitchToMenu {

proc SwitchToMenu {args} {

.nut.rm.analysismeal configure \
  -text "Analysis" \
  -command SwitchToAnalysis
if {!$::ALTGUI} {
 grid remove $::rmMainPane
 grid .nut.rm.grams
 grid .nut.rm.ounces
#grid .nut.rm.recipebutton
 set ::rmMainPane .nut.rm.frmenu
 grid $::rmMainPane
 grid remove .nut.rm.searchcancel
 } else {
 place forget $::rmMainPane
 place .nut.rm.grams \
  -relx 0.87 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.11
 place .nut.rm.ounces \
  -relx 0.87 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.11
#place .nut.rm.recipebutton \
  -relx 0.0058 \
  -rely 0.185 \
  -relheight 0.045 \
  -relwidth 0.2
 set ::rmMainPane .nut.rm.frmenu
 place $::rmMainPane \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
 place forget .nut.rm.searchcancel
 }
 .nut.rm.recipebutton configure \
  -state normal

 }

#end SwitchToMenu
}

set TurnOffTheBubbleMachine {

proc TurnOffTheBubbleMachine {} {

 set ::BubbleMachineStatus [expr {$::BubbleMachineStatus - 1}]
 if {$::BubbleMachineStatus > 0} {return}
 .nut.rm.bubblemachine stop
 if {!$::ALTGUI} {
  grid remove .nut.rm.bubblemachine
  grid .nut.rm.fsentry
  } else {
  place forget .nut.rm.bubblemachine
  place .nut.rm.fsentry \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45
  }
 }

#end TurnOffTheBubbleMachine
}

set TurnOnTheBubbleMachine {

proc TurnOnTheBubbleMachine {} {

 set ::BubbleMachineStatus [expr {$::BubbleMachineStatus + 1}]
 if {$::BubbleMachineStatus > 1} {return}
  if {!$::ALTGUI} {
   grid remove .nut.rm.fsentry
   grid .nut.rm.bubblemachine
   } else {
   place forget .nut.rm.fsentry
   place .nut.rm.bubblemachine \
  -relx 0.4 \
  -rely 0.19629629  \
  -relheight 0.044444444 \
  -relwidth 0.45
   }
  .nut.rm.bubblemachine start
  update
 }

#end TurnOnTheBubbleMachine
}

set badPCF {

proc badPCF {food food1 selection message} {

 if {$message == 0} {
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"$food\" does not have a value for $selection."
  } elseif {$message == 1} {
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "\"$food\" is too similar in nutrient composition to another food, \"$food1\"."
  } elseif {$message == 2} {
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "$selection is set to \"Adjust to my meals\"."
  } elseif {$message == 3} {
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "Portion control for $selection causes too much recursion in the algorithm probably due to a conflicting requirement."
  } elseif {$message == 4} {
  tk_messageBox \
  -type ok \
  -title $::version \
  -message "Changing quantity for \"$food\" causes too much recursion in the portion control algorithm probably due to a conflicting requirement from other portion control settings."
  }
 }

#end badPCF
}

set dropoutvf {

proc dropoutvf {args} {

# drop out, tune in, turn on the traces so we can update them without making
# a vicious recursive loop

 uplevel #0 {
  trace remove variable gramsvf write GramChangevf
  trace remove variable ouncesvf write OunceChangevf
  trace remove variable caloriesvf write CalChangevf
  trace remove variable Amountvf write AmountChangevf
  trace remove variable Msre_Descvf write ServingChange
  }
 }

#end dropoutvf
}

set format_meal_id {

proc format_meal_id {meal_id} {
 if {$meal_id == ""} {return ""}
 set mealno [string range $meal_id 8 9]
 if {$mealno == ""} {return}
 if {$mealno == "08"} {set mealno 8}
 set mealno [expr {int($mealno)}]
 return \"[clock format [clock scan [string range $meal_id 0 7] \
  -format {%Y%m%d}] \
  -format {%a %b %e, %Y #}]${mealno}\"
 }

#end format_meal_id
}

set mealchange {

proc mealchange {args} {

 if {! $::realmealchange} {
 set ::realmealchange 1
 return
 }
 CancelSearch
 if {!$::ALTGUI} {
  grid remove $::rmMainPane
  grid remove .nut.rm.setmpd
  .nut.rm.recipebutton configure \
  -state normal
  set ::rmMainPane .nut.rm.frmenu
  grid $::rmMainPane
  grid .nut.rm.grams
  grid .nut.rm.ounces
  grid .nut.rm.analysismeal
  } else {
  place forget $::rmMainPane
  place forget .nut.rm.setmpd
  .nut.rm.recipebutton configure \
  -state normal
  set ::rmMainPane .nut.rm.frmenu
  place $::rmMainPane \
  -relx 0.0 \
  -rely 0.25 \
  -relheight 0.75 \
  -relwidth 1.0
  place .nut.rm.grams \
  -relx 0.87 \
  -rely 0.0046296296 \
  -relheight 0.044444444 \
  -relwidth 0.11
  place .nut.rm.ounces \
  -relx 0.87 \
  -rely 0.0490740736 \
  -relheight 0.044444444 \
  -relwidth 0.11
  place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
  }
 set julian [expr { ($::mealoffset / $::meals_per_day) + [clock format [clock scan [expr {$::mealbase / 100}] \
  -format {%Y%m%d}] \
  -format {%J}] }]
 set mealnum [expr { $::mealbase % 100 + $::mealoffset % $::meals_per_day }]
 if {$mealnum > $::meals_per_day} {
  set julian [expr {$julian + 1}]
  set mealnum [expr {$mealnum - $::meals_per_day}]
  }
 set ::currentmeal [clock format [clock scan $julian \
  -format {%J}] \
  -format {%Y%m%d}]
 set ::currentmeal [expr {$::currentmeal * 100 + $mealnum}]
 set ::mealchoice "Meal [format_meal_id $::currentmeal]"
 .nut.rm.scale configure \
  -label $::mealchoice
 if {abs($::mealoffset) == 100} {after 500 recenterscale $::currentmeal}
 set count \
  -1
 foreach mf $::MealfoodStatus {
  incr count
  if {$mf == "Hidden" || $mf == "Available"} {continue}
  MealfoodDelete $count $mf 0
  }
 db eval {update options set currentmeal = $::currentmeal}
 if {[db eval {select count(NDB_No) from mealfoods where meal_id = $::currentmeal}] > 0} {
  db eval {select mealfoods.NDB_No, Shrt_Desc from mealfoods, food_des where meal_id = $::currentmeal and food_des.NDB_No = mealfoods.NDB_No order by Shrt_Desc} {
   MealfoodWidget $Shrt_Desc $NDB_No
   }
  }
 thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
 }

#end mealchange
}

set n6hufa {

proc n6hufa {short3 short6 long3 long6 sat mono trans pufa cals float} {

 if {$short3 == "" &&  $short6 == "" && $long3 == "" && $long6 == ""} {
  if {!$float} {return "\[No Data\]"} else {return 0.0}
  }
 if {![string is double \
  -strict $short3]} {set short3 0.0}
 if {![string is double \
  -strict $short6]} {set short6 0.0}
 if {![string is double \
  -strict $long3]} {set long3 0.0}
 if {![string is double \
  -strict $long6]} {set long6 0.0}
 if {![string is double \
  -strict $sat]} {set sat 0.0}
 if {![string is double \
  -strict $mono]} {set mono 0.0}
 if {![string is double \
  -strict $trans]} {set trans 0.0}
 if {![string is double \
  -strict $pufa]} {set pufa 0.0}
 if {![string is double \
  -strict $cals]} {set cals 0.0}
 if { $cals == 0.0 } {
  if {!$float} {return "0 / 0"} else {return 0.0}
  }
 if { $short3 == 0.0 && $short6 == 0.0 && $long3 == 0.0 && $long6 == 0.0 } {
  if {!$float} {return "\[No Data\]"} else {return 0.0}
  }
 set p3 [expr { 900.0 * $short3 / $cals }]
 set p6 [expr { 900.0 * $short6 / $cals }]
 set h3 [expr { 900.0 * $long3 / $cals }]
 set h6 [expr { 900.0 * $long6 / $cals }]
 set o  [expr { 900.0 * ($sat + $mono + $pufa - $short3 - $short6 - $long3 - $long6) / $cals }]
 if { $p6 == 0.0 } {set p6 0.000000001}
 if { $h6 == 0.0 } {set h6 0.000000001}
 set answer [db eval {select 100.0 / (1.0 + 0.0441/$p6 * (1.0 + $p3/0.0555 + $h3/0.005 + $o/5.0 + $p6/0.175)) + 100.0 / (1.0 + 0.7/$h6 * (1.0 + $h3/3.0))}]
 if { $answer > 90.0 } {
  if {!$float} {return "90 / 10"} else {return 90.0}
  } elseif { $answer < 15.0 } {
  if {!$float} {return "15 / 85"} else {return 15.0}
  } else {
  if {!$float} {
   set answer [expr {round($answer)}]
   return "$answer / [expr {100 - $answer}]"
   } else {
   return $answer
   }
  }
 }

#end n6hufa
}

set recenterscale {

proc recenterscale {currentmeal} {

 set ::mealoffset 0 set ::mealbase $currentmeal
 }

#end recenterscale
}

set setPCF {

proc setPCF {seqno ndb varNameSel args} {

 upvar 0 $varNameSel selection
 if {$selection != "No Auto Portion Control"} {
  db eval {select Tagname, Nutr_No from nutr_def where NutrDesc = $selection} { }
  set PCFfactor "\[No Data\]"
  db eval "select 1.0 / Nutr_Val / cast ($::meals_per_day as real) as PCFfactor from nutr_def left natural join nut_data where NDB_No = $ndb and Tagname = '$Tagname'" { }
  if {$PCFfactor == "\[No Data\]"} {
   set saveselection $selection
   db eval {select Long_Desc from food_des where NDB_No = $ndb} { }
   ${::rmMenu}.menu.foodPCF${seqno} current 0
   ${::rmMenu}.menu.foodPCF${seqno} configure  \
  -style rm.TCombobox
   after idle [list badPCF $Long_Desc NULL $saveselection 0]
   return
   }
  set opt [db eval {select nutopt from nutr_def where NutrDesc = $selection}]
  if {$opt == \
  -1} {
   set saveselection $selection
   set Long_Desc {}
   ${::rmMenu}.menu.foodPCF${seqno} current 0
   ${::rmMenu}.menu.foodPCF${seqno} configure  \
  -style rm.TCombobox
   ${::rmMenu}.menu.foodspin${seqno} configure  \
  -state readonly
   after idle [list badPCF $Long_Desc NULL $saveselection 2]
   return
   }
  set ::saveit $selection
  if {[catch { db eval {update currentmeal set NutrDesc = $selection where NDB_No = $ndb} }]} {
   db eval {update currentmeal set NutrDesc = null where NDB_no = $ndb}
   ${::rmMenu}.menu.foodPCF${seqno} current 0
   ${::rmMenu}.menu.foodPCF${seqno} configure  \
  -style rm.TCombobox
   ${::rmMenu}.menu.foodspin${seqno} configure  \
  -state readonly
   after idle [list badPCF NULL NULL $::saveit 3]
   return
   }
  set prevseqno [lsearch \
  -exact $::MealfoodPCF $Tagname]
  set prevndb [lindex $::MealfoodStatus $prevseqno]
  if {$prevseqno > \
  -1 && $prevseqno != $seqno} {
   set ::MealfoodPCF [lreplace $::MealfoodPCF $prevseqno $prevseqno "NULL"]
   ${::rmMenu}.menu.foodPCF${prevseqno} current 0
   ${::rmMenu}.menu.foodPCF${prevseqno} configure  \
  -style rm.TCombobox
   ${::rmMenu}.menu.foodspin${prevseqno} configure  \
  -state readonly
#  trace remove variable ::${Tagname}dv write "PCF $prevseqno $prevndb"
#  trace remove variable ::${Tagname}rm write "PCF $prevseqno $prevndb"
   }
  set oldtag [lindex $::MealfoodPCF $seqno]
# if {$oldtag != "NULL" && $prevseqno != $seqno} {
#  trace remove variable ::${oldtag}dv write "PCF $seqno $ndb"
#  trace remove variable ::${oldtag}rm write "PCF $seqno $ndb"
#  }
  set ::MealfoodPCF [lreplace $::MealfoodPCF $seqno $seqno $Tagname]
# set ::MealfoodPCFfactor [lreplace $::MealfoodPCFfactor $seqno $seqno $PCFfactor]
  ${::rmMenu}.menu.foodPCF${seqno} configure  \
  -style nut.TCombobox
  ${::rmMenu}.menu.foodspin${seqno} configure  \
  -state disabled
# if {$prevseqno != $seqno} {
#  trace add variable ::${Tagname}dv write "PCF $seqno $ndb"
#  trace add variable ::${Tagname}rm write "PCF $seqno $ndb"
#  RefreshMealfoodQuantities
#  PCF $seqno $ndb
#  }
  } else {
  db eval {update currentmeal set NutrDesc = null where NDB_No = $ndb}
  set oldtag [lindex $::MealfoodPCF $seqno]
  if {$oldtag == "NULL"} {return}
  set ::MealfoodPCF [lreplace $::MealfoodPCF $seqno $seqno "NULL"]
  ${::rmMenu}.menu.foodPCF${seqno} configure  \
  -style rm.TCombobox
  ${::rmMenu}.menu.foodspin${seqno} configure  \
  -state readonly
# trace remove variable ::${oldtag}dv write "PCF $seqno $ndb"
# trace remove variable ::${oldtag}rm write "PCF $seqno $ndb"
  }
 thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
 }

#end setPCF
}


set setRefDesc {

proc setRefDesc {ref_desc} {

 if {$ref_desc == ""} {
  .nut.vf.refusemb.m entryconfigure 0 \
  -label "No refuse description provided"  } else {
  .nut.vf.refusemb.m entryconfigure 0 \
  -label $ref_desc
  }
 }

#end setRefDesc
}

set tuneinvf {

proc tuneinvf {args} {

 uplevel #0 {
  trace add variable gramsvf write GramChangevf
  trace add variable ouncesvf write OunceChangevf
  trace add variable caloriesvf write CalChangevf
  trace add variable Amountvf write AmountChangevf
  trace add variable Msre_Descvf write ServingChange
  }
 }

#end tuneinvf
}

set pbprog {

proc pbprog {barnum bailey} {
 set ::pbar($barnum) [expr {$::pbar($barnum) + $bailey}]
 update
 }

#end pbprog
}

set pbprog1 {

proc pbprog1 { } {
 incr ::pbprog1counter
 if {$::pbprog1counter % 250 == 0} {
  set ::pbar(5) [expr {$::pbar(5) + 0.10}]
  update
  }
 }

#end pbprog1
}

set theusualPopulateMenu {

proc theusualPopulateMenu { } {

 .nut.rm.theusual.m.add delete 0 end
 .nut.rm.theusual.m.save delete 0 end
 .nut.rm.theusual.m.delete delete 0 end
 set tu_names [db eval {select distinct meal_name from theusual}]
 foreach name $tu_names {
  .nut.rm.theusual.m.add add command \
  -label "Add $name" \
  -command [list theusualAdd $name] \
  -background "#FF9428"
  .nut.rm.theusual.m.save add command \
  -label "Save $name" \
  -command [list theusualSave $name] \
  -background "#FF9428"
  .nut.rm.theusual.m.delete add command \
  -label "Delete $name" \
  -command [list theusualDelete $name] \
  -background "#FF9428"
  }
 .nut.rm.theusual.m.save add separator \
  -background "#FF9428"
 .nut.rm.theusual.m.save add command \
  -label "Save as ..." \
  -command theusualSaveNew \
  -background "#FF9428"
 }

#end theusualPopulateMenu
}

set theusualAdd {

proc theusualAdd {mealname} {

 TurnOnTheBubbleMachine
 set addlist [db eval {select t.NDB_No, case when NutrDesc is null then 'No Auto Portion Control' else NutrDesc end as PCF, Shrt_Desc from theusual t, food_des f using (NDB_No) where meal_name = $mealname order by Shrt_Desc asc}]
 if {[llength $addlist] > 0} {
  if {!$::ALTGUI} {
   grid remove .nut.rm.setmpd
   grid remove .nut.rm.frlistbox
   grid remove .nut.rm.searchcancel
   grid .nut.rm.analysismeal
   } else {
   place forget .nut.rm.setmpd
   place forget .nut.rm.frlistbox
   place forget .nut.rm.searchcancel
   place .nut.rm.analysismeal \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
   }
  SwitchToMenu
  db eval {begin}
  foreach {ndb pcf Shrt_Desc} $addlist {
   db eval {select Gm_Wgt from pref_Gm_Wgt where NDB_No = $ndb} {
    db eval {insert into currentmeal values ($ndb, $Gm_Wgt, $pcf)}
    set seq [MealfoodWidget $Shrt_Desc $ndb]
    ${::rmMenu}.menu.foodPCF${seq} set $pcf
    if {$pcf != "No Auto Portion Control"} {
     ${::rmMenu}.menu.foodPCF${seq} configure \
  -style nut.TCombobox
     } else {
     ${::rmMenu}.menu.foodPCF${seq} configure \
  -style rm.TCombobox
     }
    }
   }
  db eval {commit}
  thread::send \
  -async $::SQL_THREAD {job_daily_value_refresh}
  }
 TurnOffTheBubbleMachine
 }

#end theusualAdd
}

set theusualSave {

proc theusualSave {mealname} {
 set ndblist [db eval {select NDB_No from mealfoods where meal_id = $::currentmeal}]
 if {[llength $ndblist] > 0} {
  db eval {insert into theusual values ( $mealname, null, null, null)}
  }
 }

#end theusualSave
}

set theusualSaveNew {

proc theusualSaveNew {args} {
 if {!$::ALTGUI} {
  grid .nut.rm.newtheusuallabel
  grid .nut.rm.newtheusualentry
  grid .nut.rm.newtheusualbutton
  } else {
  place .nut.rm.newtheusuallabel \
  -relx 0.39 \
  -rely 0.03 \
  -relheight 0.09 \
  -relwidth 0.33
  place .nut.rm.newtheusualentry \
  -relx 0.31 \
  -rely 0.12 \
  -relheight 0.045 \
  -relwidth 0.33
  place .nut.rm.newtheusualbutton \
  -relx 0.65 \
  -rely 0.12 \
  -relheight 0.045 \
  -relwidth 0.07
  }
 }

#end theusualSaveNew
}

set theusualNewName {

proc theusualNewName {args} {
 if {$::newtheusual == ""} {set ::newtheusual default}
 theusualSave $::newtheusual
 if {!$::ALTGUI} {
  grid remove .nut.rm.newtheusuallabel
  grid remove .nut.rm.newtheusualentry
  grid remove .nut.rm.newtheusualbutton
  } else {
  place forget .nut.rm.newtheusuallabel
  place forget .nut.rm.newtheusualentry
  place forget .nut.rm.newtheusualbutton
  }
 set ::newtheusual ""
 }

#end theusualNewName
}

set theusualDelete {

proc theusualDelete {mealname} {
 db eval {delete from theusual where meal_name = $mealname}
 }

#end theusualDelete
}

set monoright {

proc monoright {string len} {
 set whatever "              $string"
 return [string range $whatever end-$len end]
 }

#end monoright
}

set rank2vf {

proc rank2vf {args} {
 set what {*}[.nut.ts.frranking.ranking selection]
 FoodChoicevf_alt [lindex $what 0] [lindex $what 1] 0
 }

#end rank2vf
}

set rm2vf {

proc rm2vf {seq} {
 set ndb [lindex $::MealfoodStatus $seq]
 set qty [db eval {select Gm_Wgt from mealfoods where NDB_No = $ndb and meal_id = $::currentmeal}]
 FoodChoicevf_alt $ndb $qty 1
 }

#end rm2vf
}

set changedv_vitmin {

proc changedv_vitmin {nut} {

 if {!$::ALTGUI} {
  grid .nut.po.pane.optframe.vite_l
  grid .nut.po.pane.optframe.vite_s
  grid .nut.po.pane.optframe.vite_cb1
  grid .nut.po.pane.optframe.vite_cb2
  } else {
  place .nut.po.pane.optframe.vite_l \
  -relx 0.0 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.25
  place .nut.po.pane.optframe.vite_s \
  -relx 0.265 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.14
  place .nut.po.pane.optframe.vite_cb1 \
  -relx 0.44 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.23
  place .nut.po.pane.optframe.vite_cb2 \
  -relx 0.69 \
  -rely 0.75 \
  -relheight 0.04444444 \
  -relwidth 0.23
  }

 db eval {select Tagname as tag, Units as un from nutr_def where NutrDesc = $nut} { }
 .nut.po.pane.optframe.vite_l configure \
  -text "$nut $un"
 .nut.po.pane.optframe.vite_cb1 configure \
  -command [list ChangePersonalOptions $tag]
 .nut.po.pane.optframe.vite_cb2 configure \
  -command [list ChangePersonalOptions $tag]
 set dvvar "::${tag}dv"
 set optvar "::${tag}opt"
 upvar #0 $dvvar vitmindv $optvar vitminopt
 if {$vitminopt == \
  -1.0} {
  .nut.po.pane.optframe.vite_s configure \
  -state disabled \
  -textvariable $dvvar
  set ::vitminpo \
  -1
  } elseif {$vitminopt == 0.0} {
  .nut.po.pane.optframe.vite_s configure \
  -state disabled \
  -textvariable $dvvar
  set ::vitminpo 2
  } else {
  .nut.po.pane.optframe.vite_s configure \
  -state normal \
  -textvariable $optvar
  set ::vitminpo 0  }

 }

#end changedv_vitmin
}

set drawClock {

proc drawClock {} {
    global PI
    global sekundenzeigerlaenge
    global minutenzeigerlaenge
    global stundenzeigerlaenge
    set aussenradius [expr {$::clockscale * 95.0}]
    set innenradius  [expr {$::clockscale * 83.0}]
    # Ziffernblatt
    .loadframe.c create rectangle 2 2 [expr {$::clockscale * 200 - 1}] [expr {$::clockscale * 200.0 - 1}] \
  -fill "#C7C3C7" \
  -outline ""
    .loadframe.c create line 1 [expr {$::clockscale * 200}] [expr {$::clockscale * 200}] [expr {$::clockscale * 200}] [expr {$::clockscale * 200}] 1 \
  -fill black    .loadframe.c create line 1 [expr {$::clockscale * 200 - 1}] [expr {$::clockscale * 200 - 1}] [expr {$::clockscale * 200 - 1}] [expr {$::clockscale * 200 - 1}] 1 \
  -fill "#8E8A8E"    .loadframe.c create line 0 [expr {$::clockscale * 200}] 0 0 [expr {$::clockscale * 200}] 0 \
  -fill "#F8F8F8"    .loadframe.c create line 1 [expr {$::clockscale * 200 - 2}] 1 1 [expr {$::clockscale * 200 - 2}] 1 \
  -fill "#D7D7D7"    # Zeiger
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}]     [expr {[expr {$::clockscale * 100}]+$stundenzeigerlaenge}] [expr {$::clockscale * 100}] \
  -tag stundenschatten
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {[expr {$::clockscale * 100}]-$minutenzeigerlaenge}]     \
  -tag minutenschatten
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {[expr {$::clockscale * 100}]+$sekundenzeigerlaenge}]    \
  -tag sekundenschatten
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}]     [expr {[expr {$::clockscale * 100}]+$stundenzeigerlaenge}] [expr {$::clockscale * 100}] \
  -tag {stundenzeiger zeiger}
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {[expr {$::clockscale * 100}]-$minutenzeigerlaenge}]     \
  -tag {minutenzeiger zeiger}
    .loadframe.c create line [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {$::clockscale * 100}] [expr {[expr {$::clockscale * 100}]+$sekundenzeigerlaenge}]    \
  -tag {sekundenzeiger zeiger}
    .loadframe.c itemconfigure stundenzeiger    \
  -width [expr {$::clockscale * 11}] \
  -fill "#554444"
    .loadframe.c itemconfigure minutenzeiger    \
  -width [expr {$::clockscale * 8}] \
  -fill "#554444"
    .loadframe.c itemconfigure sekundenzeiger   \
  -width [expr {$::clockscale * 4}] \
  -fill "#FFFF00"
    .loadframe.c itemconfigure stundenschatten  \
  -width [expr {$::clockscale * 11}] \
  -fill "#B0B0B0"
    .loadframe.c itemconfigure minutenschatten  \
  -width [expr {$::clockscale * 8}] \
  -fill "#B0B0B0"
    .loadframe.c itemconfigure sekundenschatten \
  -width [expr {$::clockscale * 4}] \
  -fill "#B0B0B0"
    # Ziffern
    for {set i 0} {$i < 60} {incr i} {
        set r0 [expr {$innenradius + 5}]
        set r1 [expr {$innenradius +10}]
        set x0 [expr {sin($PI/30*(30-$i))*$r0+[expr {$::clockscale * 100}]}]
        set y0 [expr {cos($PI/30*(30-$i))*$r0+[expr {$::clockscale * 100}]}]
        set x1 [expr {sin($PI/30*(30-$i))*$r1+[expr {$::clockscale * 100}]}]
        set y1 [expr {cos($PI/30*(30-$i))*$r1+[expr {$::clockscale * 100}]}]
        if {[expr {$i%5}]} {
        }
    }
    for {set i 0} {$i < 12} {incr i} {
        set x [expr {sin($PI/6*(6-$i))*$innenradius+[expr {$::clockscale * 100}]}]
        set y [expr {cos($PI/6*(6-$i))*$innenradius+[expr {$::clockscale * 100}]}]
        .loadframe.c create text $x $y \
                \
  -text [expr {$i ? $i : 12}] \
                \
  -font TkSmallCaptionFont \
                \
  -fill #000000 \
                \
  -tag ziffer
    }
}

#end drawClock
}

set stundenZeigerAuf {

proc stundenZeigerAuf {std} {
    global PI
    global stundenzeigerlaenge
    set x0 [expr {$::clockscale * 100}]
    set y0 [expr {$::clockscale * 100}]
    set dx [expr {sin ($PI/6*(6-$std))*$stundenzeigerlaenge}]
    set dy [expr {cos ($PI/6*(6-$std))*$stundenzeigerlaenge}]
    set x1 [expr {$x0 + $dx}]
    set y1 [expr {$y0 + $dy}]
    .loadframe.c coords stundenzeiger $x0 $y0 $x1 $y1
    set schattenabstand [expr {$::clockscale * 6}]
    set x0s [expr {$x0 + $schattenabstand}]
    set y0s [expr {$y0 + $schattenabstand}]
    set x1s [expr {$x1 + $schattenabstand}]
    set y1s [expr {$y1 + $schattenabstand}]
    .loadframe.c coords stundenschatten $x0s $y0s $x1s $y1s
}

#end stundenZeigerAuf
}

set minutenZeigerAuf {

proc minutenZeigerAuf {min} {
    global PI
    global minutenzeigerlaenge
    set x0 [expr {$::clockscale * 100}]
    set y0 [expr {$::clockscale * 100}]
    set dx [expr {sin ($PI/30*(30-$min))*$minutenzeigerlaenge}]
    set dy [expr {cos ($PI/30*(30-$min))*$minutenzeigerlaenge}]
    set x1 [expr {$x0 + $dx}]
    set y1 [expr {$y0 + $dy}]
    .loadframe.c coords minutenzeiger $x0 $y0 $x1 $y1
    set schattenabstand [expr {$::clockscale * 8}]
    set x0s [expr {$x0 + $schattenabstand}]
    set y0s [expr {$y0 + $schattenabstand}]
    set x1s [expr {$x1 + $schattenabstand}]
    set y1s [expr {$y1 + $schattenabstand}]
    .loadframe.c coords minutenschatten $x0s $y0s $x1s $y1s
}

#end minutenZeigerAuf
}

set sekundenZeigerAuf {

proc sekundenZeigerAuf {sec} {
    global PI
    global sekundenzeigerlaenge
    set x0 [expr {$::clockscale * 100}]
    set y0 [expr {$::clockscale * 100}]
    set dx [expr {sin ($PI/30*(30-$sec))*$sekundenzeigerlaenge}]
    set dy [expr {cos ($PI/30*(30-$sec))*$sekundenzeigerlaenge}]
    set x1 [expr {$x0 + $dx}]
    set y1 [expr {$y0 + $dy}]
    .loadframe.c coords sekundenzeiger $x0 $y0 $x1 $y1
    set schattenabstand [expr {$::clockscale * 10}]
    set x0s [expr {$x0 + $schattenabstand}]
    set y0s [expr {$y0 + $schattenabstand}]
    set x1s [expr {$x1 + $schattenabstand}]
    set y1s [expr {$y1 + $schattenabstand}]
    .loadframe.c coords sekundenschatten $x0s $y0s $x1s $y1s
}

#end sekundenZeigerAuf
}

set showTime {

proc showTime {} {
    after cancel showTime
    after 1000 showTime
    set secs [clock seconds]
    set l [clock format $secs \
  -format {%H %M %S} ]
    set std [lindex $l 0]
    set min [lindex $l 1]
    set sec [lindex $l 2]
    regsub ^0 $std "" std
    regsub ^0 $min "" min
    regsub ^0 $sec "" sec
    set min [expr {$min + 1.0 * $sec/60}]
    set std [expr {$std + 1.0 * $min/60}]
    stundenZeigerAuf $std
    minutenZeigerAuf $min
    sekundenZeigerAuf $sec
}
#end showTime
}

set InitialLoad_alt_GUI {

sqlite3 dbmem :memory:
dbmem function n6hufa n6hufa
dbmem function setRefDesc setRefDesc
dbmem function format_meal_id format_meal_id

if {[catch {dbmem restore main $::DiskDB}]} {

# Duplicate the schema of appdata1.xyz into the in-memory db database

 db eval {SELECT sql FROM sqlite_master WHERE sql NOT NULL and type = 'table' and name not like '%sqlite_%'} {
  dbmem eval $sql
  }

# Copy data content from appdata1.xyz into memory
 dbmem eval {ATTACH $::DiskDB AS app}
 dbmem eval {SELECT name FROM sqlite_master WHERE type='table'} {
  dbmem eval "INSERT INTO $name SELECT * FROM app.$name"
  }
 dbmem eval {DETACH app}
 }

dbmem eval {PRAGMA synchronous = 0}

if {$::THREADS} {
 dbmem progress 1920 [list thread::send \
  -async $::GUI_THREAD {pbprog_threaded 1 1.0 }]
 } else {
 dbmem progress 1920 {pbprog 1 1.0 }
 }
load_nutr_def

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(1) 100.0}
 dbmem progress 10 [list thread::send \
  -async $::GUI_THREAD {pbprog_threaded 2 1.0 }]
 } else {
 set ::pbar(1) 100.0
 dbmem progress 10 {pbprog 2 1.0 }
 }
load_fd_group

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(2) 100.0}
 dbmem progress 8000 [list thread::send \
  -async $::GUI_THREAD {pbprog_threaded 3 1.0 }]
 } else {
 set ::pbar(2) 100.0
 dbmem progress 8000 {pbprog 3 1.0 }
 }
load_food_des1

dbmem eval {select count(*) as count from food_des} {
 if {$count != 0} {
  if {$::THREADS} {
   dbmem progress 32000 [list thread::send \
  -async $::GUI_THREAD {pbprog_threaded 3 1.0 }]
   } else {
   dbmem progress 32000 {pbprog 3 1.0 }
   }
  }
 }

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(3) 100.0}
 dbmem progress 9000 [list thread::send \
  -async $::GUI_THREAD {pbprog_threaded 4 1.0 }]
 } else {
 set ::pbar(3) 100.0
 dbmem progress 9000 {pbprog 4 1.0 }
 }
load_weight

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(4) 100.0 ; pbprog1_threaded}
 dbmem progress 0 ""
 } else {
 set ::pbprog1counter 0
 set ::pbar(4) 100.0
 set ::pbar(5) 0.5
 dbmem progress 26 {pbprog1}
 }
load_nut_data1

if {$::THREADS} {
 dbmem progress 300000 {thread::send \
  -async $::GUI_THREAD {pbprog 5 1.0 }}
 } else {
 dbmem progress 300000 {pbprog 5 1.0 }
 }

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(5) 100.0}
 dbmem progress 240000 {thread::send \
  -async $::GUI_THREAD {pbprog 6 1.0 }}
 } else {
 set ::pbar(5) 100.0
 dbmem progress 120000 {pbprog 6 0.5 }
 }
ComputeDerivedValues dbmem food_des

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(6) 100.0}
 dbmem progress [expr {[dbmem eval {select count(NDB_No) from food_des}] * 120}] {thread::send \
  -async $::GUI_THREAD {pbprog 7 1.0 }}
 } else {
 set ::pbar(6) 100.0
 dbmem progress [expr {[dbmem eval {select count(NDB_No) from food_des}] * 60}] {pbprog 7 0.5 }
 }

load_logic

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(7) 100.0 ; .loadframe.pbar8 configure \
  -mode indeterminate ; .loadframe.pbar8 start}
 dbmem progress 0 ""
 } else {
 set ::pbar(7) 100.0
 dbmem progress 4000 {update}
 .loadframe.pbar8 configure \
  -mode indeterminate
 .loadframe.pbar8 start
 }
load_legacy

if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {.loadframe.pbar8 stop ; .loadframe.pbar8 configure \
  -mode determinate ; set ::pbar(8) 80.0}
 dbmem progress 0 ""
 } else {
 dbmem progress 0 ""
 .loadframe.pbar8 stop
 .loadframe.pbar8 configure \
  -mode determinate
 set ::pbar(8) 80.0
 update
 }
dbmem eval {analyze main}
dbmem eval {PRAGMA synchronous = 2}
if {[catch {dbmem backup main $::DiskDB}]} {

# Duplicate the schema of appdata1.xyz from the in-memory db database
 set sql_mast [db eval {SELECT name, type FROM sqlite_master where type != 'index'}]
 foreach {name type} $sql_mast {
  db eval "DROP $type if exists $name"
  }
 dbmem eval {SELECT sql FROM sqlite_master WHERE sql NOT NULL and type != 'trigger'} {
  db eval $sql
  }

# Copy data content into appdata1.xyz from memory
 dbmem eval {ATTACH $::DiskDB AS app}
 dbmem eval {SELECT name FROM sqlite_master WHERE type='table'} {
  dbmem eval "INSERT INTO app.$name SELECT * FROM $name"
  }
 dbmem eval {SELECT sql FROM sqlite_master WHERE sql NOT NULL and type = 'trigger'} {
  db eval $sql
  }
 dbmem eval {DETACH app}
 }
dbmem close
if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(8) 90.0}
 } else {
 set ::pbar(8) 90.0
 update
 }
db eval {vacuum}
file rename \
  -force "NUTR_DEF.txt" "NUTR_DEF.txt.loaded"
if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {set ::pbar(8) 100.0}
 } else {
 set ::pbar(8) 100.0
 update
 }
if {$::THREADS} {
 thread::send \
  -async $::GUI_THREAD {wm deiconify . ; after cancel showTime ; destroy .loadframe ; db eval {select code from z_tcl_code where name = 'Start_NUT'} { } ; eval $code}
 } else {
 wm deiconify .
 after cancel showTime
 destroy .loadframe
 db eval {select code from z_tcl_code where name = 'Start_NUT'} { }
 eval $code
 }

#end InitialLoad_alt_GUI
}

set pbprog_threaded {

proc pbprog_threaded {barnum bailey} {
 set ::pbar($barnum) [expr {$::pbar($barnum) + $bailey}]
 }

#end pbprog_threaded
}

set pbprog1_threaded {

proc pbprog1_threaded { } {
 for {set i 0} {$i < 80} {incr i} {
  after [expr {$i * 1000}] {set ::pbar(5) [expr {$::pbar(5) + 0.5}]}
  }
 }

#end pbprog1_threaded
}

set opt_change {

proc opt_change {tag args} {

set var "::${tag}opt"
upvar #0 $var optvar
if {[string is double \
  -strict $optvar]} {
 after 300 [list opt_change_later $optvar $tag]
 }

}

#end opt_change
}

set opt_change_later {

proc opt_change_later {newval tag args} {

set var "::${tag}opt"
upvar #0 $var optvar
if {$newval == $optvar} {
 thread::send \
  -async $::SQL_THREAD [list db eval "insert into z_tcl_jobqueue values (null, 'opt_change', null, $optvar, '$tag')"]
 thread::send \
  -async $::SQL_THREAD [list job_opt_change $tag]
 }
}

#end opt_change_later
}

set SetMealBase {

proc SetMealBase {args} {
db eval {select meals_per_day as "::meals_per_day" from options} { }
db eval {select mealcount as "::mealcount" from am_analysis_header} { }
set ::mealnumbase_time [expr {int(([db eval {select julianday('now','localtime') + 0.5}] - [clock format [clock seconds] \
  -format {%J}] + (1.0 / $::meals_per_day)) * $::meals_per_day)}]
set ::mealdatebase_time [clock format [clock seconds] \
  -format {%Y%m%d}]
set ::mealbase_time [expr {$::mealdatebase_time * 100 + $::mealnumbase_time}]
if {$::mealcount > 0} {
 db eval {select max(meal_id) / 100 as "::mealdatebase_max", max(meal_id) % 100 + 1 "::mealnumbase_max" from mealfoods} { }
 if {$::mealnumbase_max > $::meals_per_day} {
  set ::mealnumbase_max [expr {$::mealnumbase_max - $::meals_per_day}]
  set ::mealdatebase_max [expr {1 + [clock format [clock scan $::mealdatebase_max \
  -format {%Y%m%d}] \
  -format {%J}]}]
  set ::mealdatebase_max [clock format [clock scan $::mealdatebase_max \
  -format {%J}] \
  -format {%Y%m%d}]
  }
 set ::mealbase_max [expr {$::mealdatebase_max * 100 + $::mealnumbase_max}]
 } else {
 set ::mealbase_max 0
 }
if {$::mealbase_time >= $::mealbase_max} {
 set ::mealbase $::mealbase_time
 set ::mealchoice "Meal [format_meal_id $::mealbase_time]"
 } else {
 set ::mealbase $::mealbase_max
 set ::mealchoice "Meal [format_meal_id $::mealbase_max]"
 }
set ::currentmeal $::mealbase
db eval {update options set currentmeal = $::currentmeal}
.nut.rm.scale configure \
  -label $::mealchoice
}

#end SetMealBase
}

set GO_change {

proc GO_change {args} {

 db eval {update options set grams = $::GRAMSopt}
 set ::StoryIsStale 1
 if {$::GRAMSopt == 1} {
  for {set i 0} {$i < $::MealfoodSequence} {incr i} {
   ${::rmMenu}.menu.foodspin${i} configure \
  -format {%0.0f} \
  -from \
  -9999 \
  -to 9999 \
  -increment 1
   }
  } elseif {$::GRAMSopt == 0} {
  for {set i 0} {$i < $::MealfoodSequence} {incr i} {
   ${::rmMenu}.menu.foodspin${i} configure \
  -format {%0.3f} \
  -from \
  -999.9 \
  -to 999.9 \
  -increment 0.125
   }
  }
 RefreshMealfoodQuantities
 }

#end GO_change
}

set get_procs_from_db {

proc get_procs_from_db {args} {

# Save the original one so we can chain to it
rename unknown _original_unknown

# Provide our own implementation
proc unknown args {
 set pname [lindex $args 0]
 set arglist [lrange $args 1 end]
 set count [db eval {select count(*) from z_tcl_code where name = $pname}]
 if {$count == 1} {
  set pcode [db eval {select code from z_tcl_code where name = $pname}]
  uplevel 1 {*}$pcode
  $pname {*}$arglist
  } else {
  uplevel 1 [list _original_unknown {*}$args]
  }
 }

db function format_meal_id format_meal_id
db function n6hufa n6hufa
db function setRefDesc setRefDesc
db function monoright monoright

}

#end get_procs_from_db
}

set load_nutr_def {

proc load_nutr_def {args} {
dbmem eval {
/* Especially when you add a GUI and a second thread to handle the database, the
   application runs much faster with write-ahead logging.  However, to put the
   database back into one file, issue the command "pragma journal_mode = delete;".
   You would do this if you wanted to move the database to another system.  If
   you delete nut.db-wal and/or nut.db-shm manually, you will corrupt the database.

PRAGMA journal_mode = WAL;
*/

begin;
  /* These temp tables must start out corresponding exactly to the USDA schemas
   for import from the USDA's distributed files but in some cases we need
   transitional temp tables to safely add what's new from the USDA to what the
   user already has.*/

/* For NUTR_DEF, we get rid of the tildes which escape non-numeric USDA fields,
   and add two fields:  dv_default to use when Daily Value is undefined, and
   nutopt which has three basic values:  \
  -1 which means DV is whatever is in
   the user's analysis unless null or <= 0.0 in which case the dv_default is
   used; 0.0 which means the default Daily Value or computation; and > 0.0 which
   is a specific gram amount of the nutrient.

   We also shorten the names of nutrients so they can better fit on the screen
   and add some nutrients that are derived from USDA values.
*/

create temp table ttnutr_def (Nutr_No text, Units text, Tagname text, NutrDesc text, Num_Dec text, SR_Order int);
create temp table tnutr_def (Nutr_No int primary key, Units text, Tagname text, NutrDesc text, dv_default real, nutopt real);

/* FD_GROUP
*/

create temp table tfd_group (FdGrp_Cd int, FdGrp_Desc text);

/* FOOD_DES gets a new Long_Desc which is the USDA Long_Desc with the SciName
   appended in parenthesis.  If the new Long_Desc is <= 60 characters, it
   replaces the USDA's Shrt_Desc, which is sometimes unnecessarily cryptic.
*/

create temp table tfood_des (NDB_No text, FdGrp_Cd text, Long_Desc text, Shrt_Desc text, ComName text, ManufacName text, Survey text, Ref_desc text, Refuse integer, SciName text, N_Factor real, Pro_Factor real, Fat_Factor real, CHO_Factor real);

/* WEIGHT gets two new fields, origSeq and origGm_Wgt.  USDA Seq numbers start
   at one, so we change the Seq to 0 when we want to save the user's serving
   unit preference.  origSeq allows us to put the record back to normal if the
   user later chooses another Serving Unit.  The first record for a food when
   ordered by Seq can have its Gm_Wgt changed, and later we will define views
   that present the Amount of the serving unit as Gm_Wgt / origGm_Wgt * Amount.
*/

create temp table tweight (NDB_No text, Seq text, Amount real, Msre_Desc text, Gm_Wgt real, Num_Data_P int, Std_Dev real);
create temp table zweight (NDB_No int, Seq int, Amount real, Msre_Desc text, Gm_Wgt real, origSeq int, origGm_Wgt real, primary key(NDB_No, origSeq));
create temp table tnut_data (NDB_No text, Nutr_No text, Nutr_Val real, Num_Data_Pts int, Std_Error real, Src_Cd text, Deriv_Cd text, Ref_NDB_No text, Add_Nutr_Mark text, Num_Studies int, Min real, Max real, DF int, Low_EB real, Up_EB real, Stat_cmt text, AddMod_Date text, CC text);

/* The USDA uses a caret as a column separator and has no special end-of-line */

/* We import the USDA data to the temp tables */}

dbmem copy fail ttnutr_def NUTR_DEF.txt "^" ""
dbmem copy fail tfd_group FD_GROUP.txt "^" ""
dbmem copy fail tfood_des FOOD_DES.txt "^" ""
dbmem copy fail tweight WEIGHT.txt "^" ""
dbmem copy fail tnut_data NUT_DATA.txt "^" ""

dbmem eval {
/* These real NUT tables may already exist and contain user data */

create table if not exists nutr_def (Nutr_No int primary key, Units text, Tagname text, NutrDesc text, dv_default real, nutopt real);create table if not exists fd_group (FdGrp_Cd int primary key, FdGrp_Desc text);
create table if not exists food_des (NDB_No int primary key, FdGrp_Cd int, Long_Desc text, Shrt_Desc text, Ref_desc text, Refuse integer, Pro_Factor real, Fat_Factor real, CHO_Factor real);
create table if not exists weight (NDB_No int, Seq int, Amount real, Msre_Desc text, Gm_Wgt real, origSeq int, origGm_Wgt real, primary key(NDB_No, origSeq));
create table if not exists nut_data (NDB_No int, Nutr_No int, Nutr_Val real, primary key(NDB_No, Nutr_No));

/* Update table nutr_def. */

insert into tnutr_def select * from nutr_def;
insert or ignore into tnutr_def select trim(Nutr_No, '~'), trim(Units, '~'), trim(Tagname, '~'), trim(NutrDesc, '~'), NULL, NULL from ttnutr_def;
update tnutr_def set Tagname = 'ADPROT' where Nutr_No = 257;
update tnutr_def set Tagname = 'VITD_BOTH' where Nutr_No = 328;
update tnutr_def set Tagname = 'LUT_ZEA' where Nutr_No = 338;
update tnutr_def set Tagname = 'VITE_ADDED' where Nutr_No = 573;
update tnutr_def set Tagname = 'VITB12_ADDED' where Nutr_No = 578;
update tnutr_def set Tagname = 'F22D1T' where Nutr_No = 664;
update tnutr_def set Tagname = 'F18D2T' where Nutr_No = 665;
update tnutr_def set Tagname = 'F18D2I' where Nutr_No = 666;
update tnutr_def set Tagname = 'F22D1C' where Nutr_No = 676;
update tnutr_def set Tagname = 'F18D3I' where Nutr_No = 856;
-- following line can be commented out if gui can handle micro char
update tnutr_def set Units = 'mcg' where hex(Units) = 'B567';
update tnutr_def set Units = 'kc' where Nutr_No = 208;
update tnutr_def set NutrDesc = 'Protein' where Nutr_No = 203;
update tnutr_def set NutrDesc = 'Total Fat' where Nutr_No = 204;
update tnutr_def set NutrDesc = 'Total Carb' where Nutr_No = 205;
update tnutr_def set NutrDesc = 'Ash' where Nutr_No = 207;
update tnutr_def set NutrDesc = 'Calories' where Nutr_No = 208;
update tnutr_def set NutrDesc = 'Starch' where Nutr_No = 209;
update tnutr_def set NutrDesc = 'Sucrose' where Nutr_No = 210;
update tnutr_def set NutrDesc = 'Glucose' where Nutr_No = 211;
update tnutr_def set NutrDesc = 'Fructose' where Nutr_No = 212;
update tnutr_def set NutrDesc = 'Lactose' where Nutr_No = 213;
update tnutr_def set NutrDesc = 'Maltose' where Nutr_No = 214;
update tnutr_def set NutrDesc = 'Ethyl Alcohol' where Nutr_No = 221;
update tnutr_def set NutrDesc = 'Water' where Nutr_No = 255;
update tnutr_def set NutrDesc = 'Adj. Protein' where Nutr_No = 257;
update tnutr_def set NutrDesc = 'Caffeine' where Nutr_No = 262;
update tnutr_def set NutrDesc = 'Theobromine' where Nutr_No = 263;
update tnutr_def set NutrDesc = 'Sugars' where Nutr_No = 269;
update tnutr_def set NutrDesc = 'Galactose' where Nutr_No = 287;
update tnutr_def set NutrDesc = 'Fiber' where Nutr_No = 291;
update tnutr_def set NutrDesc = 'Calcium' where Nutr_No = 301;
update tnutr_def set NutrDesc = 'Iron' where Nutr_No = 303;
update tnutr_def set NutrDesc = 'Magnesium' where Nutr_No = 304;
update tnutr_def set NutrDesc = 'Phosphorus' where Nutr_No = 305;
update tnutr_def set NutrDesc = 'Potassium' where Nutr_No = 306;
update tnutr_def set NutrDesc = 'Sodium' where Nutr_No = 307;
update tnutr_def set NutrDesc = 'Zinc' where Nutr_No = 309;
update tnutr_def set NutrDesc = 'Copper' where Nutr_No = 312;
update tnutr_def set NutrDesc = 'Fluoride' where Nutr_No = 313;
update tnutr_def set NutrDesc = 'Manganese' where Nutr_No = 315;
update tnutr_def set NutrDesc = 'Selenium' where Nutr_No = 317;
update tnutr_def set NutrDesc = 'Vit. A, IU' where Nutr_No = 318;
update tnutr_def set NutrDesc = 'Retinol', dv_default = 900.0 where Nutr_No = 319;
update tnutr_def set NutrDesc = 'Vitamin A' where Nutr_No = 320;
update tnutr_def set NutrDesc = 'B-Carotene' where Nutr_No = 321;
update tnutr_def set NutrDesc = 'A-Carotene' where Nutr_No = 322;
update tnutr_def set NutrDesc = 'A-Tocopherol' where Nutr_No = 323;
update tnutr_def set NutrDesc = 'Vit. D, IU' where Nutr_No = 324;
update tnutr_def set NutrDesc = 'Vitamin D2' where Nutr_No = 325;
update tnutr_def set NutrDesc = 'Vitamin D3' where Nutr_No = 326;
update tnutr_def set NutrDesc = 'Vitamin D' where Nutr_No = 328;
update tnutr_def set NutrDesc = 'B-Cryptoxanth.' where Nutr_No = 334;
update tnutr_def set NutrDesc = 'Lycopene' where Nutr_No = 337;
update tnutr_def set NutrDesc = 'Lutein+Zeaxan.' where Nutr_No = 338;
update tnutr_def set NutrDesc = 'B-Tocopherol' where Nutr_No = 341;
update tnutr_def set NutrDesc = 'G-Tocopherol' where Nutr_No = 342;
update tnutr_def set NutrDesc = 'D-Tocopherol' where Nutr_No = 343;
update tnutr_def set NutrDesc = 'A-Tocotrienol' where Nutr_No = 344;
update tnutr_def set NutrDesc = 'B-Tocotrienol' where Nutr_No = 345;
update tnutr_def set NutrDesc = 'G-Tocotrienol' where Nutr_No = 346;
update tnutr_def set NutrDesc = 'D-Tocotrienol' where Nutr_No = 347;
update tnutr_def set NutrDesc = 'Vitamin C' where Nutr_No = 401;
update tnutr_def set NutrDesc = 'Thiamin' where Nutr_No = 404;
update tnutr_def set NutrDesc = 'Riboflavin' where Nutr_No = 405;
update tnutr_def set NutrDesc = 'Niacin' where Nutr_No = 406;
update tnutr_def set NutrDesc = 'Panto. Acid' where Nutr_No = 410;
update tnutr_def set NutrDesc = 'Vitamin B6' where Nutr_No = 415;
update tnutr_def set NutrDesc = 'Folate' where Nutr_No = 417;
update tnutr_def set NutrDesc = 'Vitamin B12' where Nutr_No = 418;
update tnutr_def set NutrDesc = 'Choline' where Nutr_No = 421;
update tnutr_def set NutrDesc = 'Menaquinone-4' where Nutr_No = 428;
update tnutr_def set NutrDesc = 'Dihydro-K1' where Nutr_No = 429;
update tnutr_def set NutrDesc = 'Vitamin K1' where Nutr_No = 430;
update tnutr_def set NutrDesc = 'Folic Acid' where Nutr_No = 431;
update tnutr_def set NutrDesc = 'Folate, food' where Nutr_No = 432;
update tnutr_def set NutrDesc = 'Folate, DFE' where Nutr_No = 435;
update tnutr_def set NutrDesc = 'Betaine' where Nutr_No = 454;
update tnutr_def set NutrDesc = 'Tryptophan' where Nutr_No = 501;
update tnutr_def set NutrDesc = 'Threonine' where Nutr_No = 502;
update tnutr_def set NutrDesc = 'Isoleucine' where Nutr_No = 503;
update tnutr_def set NutrDesc = 'Leucine' where Nutr_No = 504;
update tnutr_def set NutrDesc = 'Lysine' where Nutr_No = 505;
update tnutr_def set NutrDesc = 'Methionine' where Nutr_No = 506;
update tnutr_def set NutrDesc = 'Cystine' where Nutr_No = 507;
update tnutr_def set NutrDesc = 'Phenylalanine' where Nutr_No = 508;
update tnutr_def set NutrDesc = 'Tyrosine' where Nutr_No = 509;
update tnutr_def set NutrDesc = 'Valine' where Nutr_No = 510;
update tnutr_def set NutrDesc = 'Arginine' where Nutr_No = 511;
update tnutr_def set NutrDesc = 'Histidine' where Nutr_No = 512;
update tnutr_def set NutrDesc = 'Alanine' where Nutr_No = 513;
update tnutr_def set NutrDesc = 'Aspartic acid' where Nutr_No = 514;
update tnutr_def set NutrDesc = 'Glutamic acid' where Nutr_No = 515;
update tnutr_def set NutrDesc = 'Glycine', dv_default = 5.0 where Nutr_No = 516;
update tnutr_def set NutrDesc = 'Proline' where Nutr_No = 517;
update tnutr_def set NutrDesc = 'Serine' where Nutr_No = 518;
update tnutr_def set NutrDesc = 'Hydroxyproline' where Nutr_No = 521;
update tnutr_def set NutrDesc = 'Vit. E added' where Nutr_No = 573;
update tnutr_def set NutrDesc = 'Vit. B12 added' where Nutr_No = 578;
update tnutr_def set NutrDesc = 'Cholesterol' where Nutr_No = 601;
update tnutr_def set NutrDesc = 'Trans Fat' where Nutr_No = 605;
update tnutr_def set NutrDesc = 'Sat Fat' where Nutr_No = 606;
update tnutr_def set NutrDesc = '4:0' where Nutr_No = 607;
update tnutr_def set NutrDesc = '6:0' where Nutr_No = 608;
update tnutr_def set NutrDesc = '8:0' where Nutr_No = 609;
update tnutr_def set NutrDesc = '10:0' where Nutr_No = 610;
update tnutr_def set NutrDesc = '12:0' where Nutr_No = 611;
update tnutr_def set NutrDesc = '14:0' where Nutr_No = 612;
update tnutr_def set NutrDesc = '16:0' where Nutr_No = 613;
update tnutr_def set NutrDesc = '18:0' where Nutr_No = 614;
update tnutr_def set NutrDesc = '20:0' where Nutr_No = 615;
update tnutr_def set NutrDesc = '18:1' where Nutr_No = 617;
update tnutr_def set NutrDesc = '18:2' where Nutr_No = 618;
update tnutr_def set NutrDesc = '18:3' where Nutr_No = 619;
update tnutr_def set NutrDesc = '20:4' where Nutr_No = 620;
update tnutr_def set NutrDesc = '22:6n-3' where Nutr_No = 621;
update tnutr_def set NutrDesc = '22:0' where Nutr_No = 624;
update tnutr_def set NutrDesc = '14:1' where Nutr_No = 625;
update tnutr_def set NutrDesc = '16:1' where Nutr_No = 626;
update tnutr_def set NutrDesc = '18:4' where Nutr_No = 627;
update tnutr_def set NutrDesc = '20:1' where Nutr_No = 628;
update tnutr_def set NutrDesc = '20:5n-3' where Nutr_No = 629;
update tnutr_def set NutrDesc = '22:1' where Nutr_No = 630;
update tnutr_def set NutrDesc = '22:5n-3' where Nutr_No = 631;
update tnutr_def set NutrDesc = 'Phytosterols' where Nutr_No = 636;
update tnutr_def set NutrDesc = 'Stigmasterol' where Nutr_No = 638;
update tnutr_def set NutrDesc = 'Campesterol' where Nutr_No = 639;
update tnutr_def set NutrDesc = 'BetaSitosterol' where Nutr_No = 641;
update tnutr_def set NutrDesc = 'Mono Fat' where Nutr_No = 645;
update tnutr_def set NutrDesc = 'Poly Fat' where Nutr_No = 646;
update tnutr_def set NutrDesc = '15:0' where Nutr_No = 652;
update tnutr_def set NutrDesc = '17:0' where Nutr_No = 653;
update tnutr_def set NutrDesc = '24:0' where Nutr_No = 654;
update tnutr_def set NutrDesc = '16:1t' where Nutr_No = 662;
update tnutr_def set NutrDesc = '18:1t' where Nutr_No = 663;
update tnutr_def set NutrDesc = '22:1t' where Nutr_No = 664;
update tnutr_def set NutrDesc = '18:2t' where Nutr_No = 665;
update tnutr_def set NutrDesc = '18:2i' where Nutr_No = 666;
update tnutr_def set NutrDesc = '18:2t,t' where Nutr_No = 669;
update tnutr_def set NutrDesc = '18:2CLA' where Nutr_No = 670;
update tnutr_def set NutrDesc = '24:1c' where Nutr_No = 671;
update tnutr_def set NutrDesc = '20:2n-6c,c' where Nutr_No = 672;
update tnutr_def set NutrDesc = '16:1c' where Nutr_No = 673;
update tnutr_def set NutrDesc = '18:1c' where Nutr_No = 674;
update tnutr_def set NutrDesc = '18:2n-6c,c' where Nutr_No = 675;
update tnutr_def set NutrDesc = '22:1c' where Nutr_No = 676;
update tnutr_def set NutrDesc = '18:3n-6c,c,c' where Nutr_No = 685;
update tnutr_def set NutrDesc = '17:1' where Nutr_No = 687;
update tnutr_def set NutrDesc = '20:3' where Nutr_No = 689;
update tnutr_def set NutrDesc = 'TransMonoenoic' where Nutr_No = 693;
update tnutr_def set NutrDesc = 'TransPolyenoic' where Nutr_No = 695;
update tnutr_def set NutrDesc = '13:0' where Nutr_No = 696;
update tnutr_def set NutrDesc = '15:1' where Nutr_No = 697;
update tnutr_def set NutrDesc = '18:3n-3c,c,c' where Nutr_No = 851;
update tnutr_def set NutrDesc = '20:3n-3' where Nutr_No = 852;
update tnutr_def set NutrDesc = '20:3n-6' where Nutr_No = 853;
update tnutr_def set NutrDesc = '20:4n-6' where Nutr_No = 855;
update tnutr_def set NutrDesc = '18:3i' where Nutr_No = 856;
update tnutr_def set NutrDesc = '21:5' where Nutr_No = 857;
update tnutr_def set NutrDesc = '22:4' where Nutr_No = 858;
update tnutr_def set NutrDesc = '18:1n-7t' where Nutr_No = 859;
insert or ignore into tnutr_def values(3000,'kc','PROT_KCAL','Protein Calories', NULL, NULL);
insert or ignore into tnutr_def values(3001,'kc','FAT_KCAL','Fat Calories', NULL, NULL);
insert or ignore into tnutr_def values(3002,'kc','CHO_KCAL','Carb Calories', NULL, NULL);
insert or ignore into tnutr_def values(2000,'g','CHO_NONFIB','Non-Fiber Carb', NULL, NULL);
insert or ignore into tnutr_def values(2001,'g','LA','LA', NULL, NULL);
insert or ignore into tnutr_def values(2002,'g','AA','AA', NULL, NULL);
insert or ignore into tnutr_def values(2003,'g','ALA','ALA', NULL, NULL);
insert or ignore into tnutr_def values(2004,'g','EPA','EPA', NULL, NULL);
insert or ignore into tnutr_def values(2005,'g','DHA','DHA', NULL, NULL);
insert or ignore into tnutr_def values(2006,'g','OMEGA6','Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(3003,'g','SHORT6','Short-chain Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(3004,'g','LONG6','Long-chain Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(2007,'g','OMEGA3','Omega-3', NULL, NULL);
insert or ignore into tnutr_def values(3005,'g','SHORT3','Short-chain Omega-3', NULL, NULL);
insert or ignore into tnutr_def values(3006,'g','LONG3','Long-chain Omega-3', NULL, NULL);

-- These are the new "daily value" labeling standards minus "ADDED SUGARS" which
-- have not yet appeared in the USDA data.

insert or ignore into tnutr_def values(2008,'mg','VITE','Vitamin E', NULL, NULL);
update tnutr_def set dv_default = 2000.0 where Tagname = 'ENERC_KCAL';
update tnutr_def set dv_default = 50.0 where Tagname = 'PROCNT';
update tnutr_def set dv_default = 78.0 where Tagname = 'FAT';
update tnutr_def set dv_default = 275.0 where Tagname = 'CHOCDF';
update tnutr_def set dv_default = 28.0 where Tagname = 'FIBTG';
update tnutr_def set dv_default = 247.0 where Tagname = 'CHO_NONFIB';
update tnutr_def set dv_default = 1300.0 where Tagname = 'CA';
update tnutr_def set dv_default = 1250.0 where Tagname = 'P';
update tnutr_def set dv_default = 18.0 where Tagname = 'FE';
update tnutr_def set dv_default = 2300.0 where Tagname = 'NA';
update tnutr_def set dv_default = 4700.0 where Tagname = 'K';
update tnutr_def set dv_default = 420.0 where Tagname = 'MG';
update tnutr_def set dv_default = 11.0 where Tagname = 'ZN';
update tnutr_def set dv_default = 0.9 where Tagname = 'CU';
update tnutr_def set dv_default = 2.3 where Tagname = 'MN';
update tnutr_def set dv_default = 55.0 where Tagname = 'SE';
update tnutr_def set dv_default = null where Tagname = 'VITA_IU';
update tnutr_def set dv_default = 900.0 where Tagname = 'VITA_RAE';
update tnutr_def set dv_default = 15.0 where Tagname = 'VITE';
update tnutr_def set dv_default = 120.0 where Tagname = 'VITK1';
update tnutr_def set dv_default = 1.2 where Tagname = 'THIA';
update tnutr_def set dv_default = 1.3 where Tagname = 'RIBF';
update tnutr_def set dv_default = 16.0 where Tagname = 'NIA';
update tnutr_def set dv_default = 5.0 where Tagname = 'PANTAC';
update tnutr_def set dv_default = 1.7 where Tagname = 'VITB6A';
update tnutr_def set dv_default = 400.0 where Tagname = 'FOL';
update tnutr_def set dv_default = 2.4 where Tagname = 'VITB12';
update tnutr_def set dv_default = 550.0 where Tagname = 'CHOLN';
update tnutr_def set dv_default = 90.0 where Tagname = 'VITC';
update tnutr_def set dv_default = 20.0 where Tagname = 'FASAT';
update tnutr_def set dv_default = 300.0 where Tagname = 'CHOLE';
update tnutr_def set dv_default = null where Tagname = 'VITD';
update tnutr_def set dv_default = 20.0 where Tagname = 'VITD_BOTH';
update tnutr_def set dv_default = 8.9 where Tagname = 'FAPU';
update tnutr_def set dv_default = 0.2 where Tagname = 'AA';
update tnutr_def set dv_default = 3.8 where Tagname = 'ALA';
update tnutr_def set dv_default = 0.1 where Tagname = 'EPA';
update tnutr_def set dv_default = 0.1 where Tagname = 'DHA';
update tnutr_def set dv_default = 4.7 where Tagname = 'LA';
update tnutr_def set dv_default = 4.0 where Tagname = 'OMEGA3';
update tnutr_def set dv_default = 4.9 where Tagname = 'OMEGA6';
update tnutr_def set dv_default = 32.6 where Tagname = 'FAMS';
update tnutr_def set nutopt = 0.0 where dv_default > 0.0 and nutopt is null;
delete from nutr_def;
insert into nutr_def select * from tnutr_def;
create index if not exists tagname_index on nutr_def (Tagname asc);
drop table ttnutr_def;
drop table tnutr_def;
}
}

#end load_nutr_def
}

set load_fd_group {

proc load_fd_group {args} {

dbmem eval {
/* Update table fg_group */

insert or replace into fd_group select trim(FdGrp_Cd, '~'), trim(trim(FdGrp_Desc, x'0D'), '~') from tfd_group;
insert or replace into fd_group values (9999, 'Added Recipes');
drop table tfd_group;
}
}

#end load_fd_group
}

set load_food_des1 {

proc load_food_des1 {args} {
dbmem eval {
/* Update table food_des. */

INSERT OR REPLACE INTO food_des (NDB_No, FdGrp_Cd, Long_Desc, Shrt_Desc, Ref_desc, Refuse, Pro_Factor, Fat_Factor, CHO_Factor) select trim(NDB_No, '~'), trim(FdGrp_Cd, '~'), replace(trim(trim(Long_Desc, '~') || ' (' || trim(SciName, '~') || ')',' ('),' ()',''), upper(substr(trim(Shrt_Desc, '~'),1,1)) || lower(substr(trim(Shrt_Desc, '~'),2)), trim(Ref_desc, '~'), Refuse, Pro_Factor, Fat_Factor, CHO_Factor from tfood_des;
update food_des set Shrt_Desc = Long_Desc where length(Long_Desc) <= 60;
update food_des set CHO_Factor = 4.0 where hex(CHO_Factor) = '0D';
 drop table tfood_des;
}
}

#end load_food_des1
}

set load_weight {

proc load_weight {args} {

dbmem eval {
/*   the weight table is next, and needs a little explanation.  The Seq
   column is a key and starts at 1 from the USDA; however, we want
   the user to be able to select his own serving unit, and we do that
   by changing the serving unit the user wants to Seq = 0, while saving
   what the original Seq was in the origSeq column so that we can get back
   later.  Furthermore, a min(Seq) as grouped by NDB_No can have its weight
   modified in order to save a preferred serving size, so we also make a copy
   of the original weight of the serving unit called origGm_Wgt.  Thus we
   always get the Amount of the serving to be displayed by the equation:
	Amount displayed = Gm_Wgt / origGm_Wgt * Amount
*/

update tweight set NDB_No = trim(NDB_No,'~');
update tweight set Seq = trim(Seq,'~');
update tweight set Msre_Desc = trim(Msre_Desc,'~');

--We want every food to have a weight, so we make a '100 grams' weight
insert or replace into zweight select NDB_No, 99, 100, 'grams', 100, 99, 100 from food_des;

--Now we update zweight with the user's existing weight preferences
insert or replace into zweight select * from weight where Seq != origSeq or Gm_Wgt != origGm_Wgt;

--We overwrite real weight table with new USDA records
INSERT OR REPLACE INTO weight select NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, Seq, Gm_Wgt from tweight;

--We overwrite the real weight table with the original user mods
insert or replace into weight select * from zweight;
drop table tweight;
drop table zweight;
}
}

#end load_weight
}

set load_nut_data1 {

proc load_nut_data1 {args} {

dbmem eval {
/* Update table nut_data */

insert or replace into nut_data select trim(NDB_No, '~'), trim(Nutr_No, '~'), Nutr_Val from tnut_data;
drop table tnut_data;
}
}

#end load_nut_data1
}

set load_legacy {

proc load_legacy {args} {
set lite [file nativename nut.sqlite]

if {![file exists $lite]} {return}
dbmem eval {select count(*) as noload from z_tcl_version where update_cd like '%nut.sqlite%'} { }
if {$noload > 0} {return}

dbmem eval {ATTACH $lite AS lite}
dbmem eval {begin}
dbmem eval {update options set currentmeal = 0}
dbmem eval {delete from mealfoods; insert into mealfoods select meal_date * 100 + meal, NDB_No, mhectograms * 100, null from lite.mealfoods}
dbmem eval {delete from archive_mealfoods; insert into archive_mealfoods select meal_date * 100 + meal, NDB_No, mhectograms * 100, meals_per_day from lite.archive_mealfoods}
dbmem eval {delete from z_wl; insert into z_wl select * from lite.wlog order by wldate, cleardate}
dbmem eval {delete from z_tu; insert into z_tu select meal_name, NDB_No, Nutr_No from lite.theusual left join lite.nutr_def on NutrDesc = PCF}
dbmem eval {select Tagname, Nutr_No, nutopt from lite.nutr_def} {
 dbmem eval "insert or ignore into nut_data select NDB_No, $Nutr_No, $Tagname from lite.food_des where NDB_No >= 99000 and $Tagname is not null"
 dbmem eval {update nutr_def set nutopt = $nutopt where Nutr_No = $Nutr_No}
 }
dbmem eval {insert or ignore into food_des select NDB_No, FdGrp_Cd, Long_Desc, Shrt_Desc, Ref_desc, Refuse, Pro_Factor, Fat_Factor, CHO_Factor from lite.food_des where NDB_No >= 99000}
dbmem eval {create temp table zweight (NDB_No int, Seq int, Amount real, Msre_Desc text, Gm_Wgt real, origSeq int, origGm_Wgt, primary key(NDB_No, origSeq))}
dbmem eval {insert or ignore into zweight select * from weight}
dbmem eval {insert or replace into zweight select NDB_No, Seq, origAmount, Msre_Desc, whectograms * 100.0, origSeq, orighectograms * 100.0 from lite.weight where NDB_No >= 99000 or Seq != origSeq or whectograms != orighectograms}
dbmem eval {insert or replace into weight select * from zweight}
dbmem eval {drop table zweight}
dbmem eval {PRAGMA recursive_triggers = 1; analyze main}
dbmem eval {update options set defanal_am = case when (select defanal_am from lite.options) = 0 then 2147123119 else (select defanal_am from lite.options) end, currentmeal = (select lastmeal_rm from lite.options), FAPU1 = (select FAPU1 from lite.options), grams = (select grams from lite.options), wltweak = (select wltweak from lite.options), wlpolarity = (select wlpolarity from lite.options), autocal = (select autocal from lite.options)}
dbmem eval {delete from shopping; insert into shopping select * from lite.shopping}
dbmem eval {update z_tcl_version set update_cd = 'nut.sqlite' where serial = (select max(serial) from z_tcl_version)}

dbmem eval {commit}

}

#end load_legacy
}

db eval {BEGIN}
db eval {insert or ignore into z_tcl_version values(null, 'NUTsqlite 2.0.6', NULL)}
db eval {delete from z_tcl_code}
db eval {insert or replace into z_tcl_code values('Main',$Main)}
db eval {insert or replace into z_tcl_code values('Make_GUI_WinMac',$Make_GUI_WinMac)}
db eval {insert or replace into z_tcl_code values('Make_GUI_Linux',$Make_GUI_Linux)}
db eval {insert or replace into z_tcl_code values('InitialLoad',$InitialLoad)}
db eval {insert or replace into z_tcl_code values('ComputeDerivedValues',$ComputeDerivedValues)}
db eval {insert or replace into z_tcl_code values('load_logic',$load_logic)}
db eval {insert or replace into z_tcl_code values('Start_NUT',$Start_NUT)}
db eval {insert or replace into z_tcl_code values('user_init',$user_init)}
db eval {insert or replace into z_tcl_code values('AmountChangevf',$AmountChangevf)}
db eval {insert or replace into z_tcl_code values('CalChangevf',$CalChangevf)}
db eval {insert or replace into z_tcl_code values('CancelSearch',$CancelSearch)}
db eval {insert or replace into z_tcl_code values('FindFoodrm',$FindFoodrm)}
db eval {insert or replace into z_tcl_code values('FindFoodrm_later',$FindFoodrm_later)}
db eval {insert or replace into z_tcl_code values('FindFoodvf',$FindFoodvf)}
db eval {insert or replace into z_tcl_code values('FindFoodvf_later',$FindFoodvf_later)}
db eval {insert or replace into z_tcl_code values('FoodChoicerm',$FoodChoicerm)}
db eval {insert or replace into z_tcl_code values('vf2rm',$vf2rm)}
db eval {insert or replace into z_tcl_code values('FoodChoicevf',$FoodChoicevf)}
db eval {insert or replace into z_tcl_code values('job_view_foods',$job_view_foods)}
db eval {insert or replace into z_tcl_code values('job_view_foods_Gm_Wgt',$job_view_foods_Gm_Wgt)}
db eval {insert or replace into z_tcl_code values('FoodChoicevf_alt',$FoodChoicevf_alt)}
db eval {insert or replace into z_tcl_code values('FoodSearchrm',$FoodSearchrm)}
db eval {insert or replace into z_tcl_code values('FoodSearchvf',$FoodSearchvf)}
db eval {insert or replace into z_tcl_code values('GramChangevf',$GramChangevf)}
db eval {insert or replace into z_tcl_code values('GramChangevfResult',$GramChangevfResult)}
db eval {insert or replace into z_tcl_code values('InitializePersonalOptions',$InitializePersonalOptions)}
db eval {insert or replace into z_tcl_code values('ChangePersonalOptions',$ChangePersonalOptions)}
db eval {insert or replace into z_tcl_code values('RefreshWeightLog',$RefreshWeightLog)}
db eval {insert or replace into z_tcl_code values('ClearWeightLog',$ClearWeightLog)}
db eval {insert or replace into z_tcl_code values('AcceptNewMeasurements',$AcceptNewMeasurements)}
db eval {insert or replace into z_tcl_code values('MealfoodDelete',$MealfoodDelete)}
db eval {insert or replace into z_tcl_code values('MealfoodSetWeight',$MealfoodSetWeight)}
db eval {insert or replace into z_tcl_code values('MealfoodSetWeightLater',$MealfoodSetWeightLater)}
db eval {insert or replace into z_tcl_code values('MealfoodWidget',$MealfoodWidget)}
db eval {insert or replace into z_tcl_code values('NBWamTabChange',$NBWamTabChange)}
db eval {insert or replace into z_tcl_code values('NBWrmTabChange',$NBWrmTabChange)}
db eval {insert or replace into z_tcl_code values('NBWarTabChange',$NBWarTabChange)}
db eval {insert or replace into z_tcl_code values('NBWvfTabChange',$NBWvfTabChange)}
db eval {insert or replace into z_tcl_code values('NewStoryLater',$NewStoryLater)}
db eval {insert or replace into z_tcl_code values('NewStory',$NewStory)}
db eval {insert or replace into z_tcl_code values('NutTabChange',$NutTabChange)}
db eval {insert or replace into z_tcl_code values('OunceChangevf',$OunceChangevf)}
db eval {insert or replace into z_tcl_code values('PCF',$PCF)}
db eval {insert or replace into z_tcl_code values('RefreshMealfoodQuantities',$RefreshMealfoodQuantities)}
db eval {insert or replace into z_tcl_code values('RecipeSaveAs',$RecipeSaveAs)}
db eval {insert or replace into z_tcl_code values('RecipeMod1',$RecipeMod1)}
db eval {insert or replace into z_tcl_code values('RecipeModdv',$RecipeModdv)}
db eval {insert or replace into z_tcl_code values('RecipeMod',$RecipeMod)}
db eval {insert or replace into z_tcl_code values('RecipeCancel',$RecipeCancel)}
db eval {insert or replace into z_tcl_code values('RecipeDone',$RecipeDone)}
db eval {insert or replace into z_tcl_code values('ServingChange',$ServingChange)}
db eval {insert or replace into z_tcl_code values('SetDefanal',$SetDefanal)}
db eval {insert or replace into z_tcl_code values('job_defanal_am',$job_defanal_am)}
db eval {insert or replace into z_tcl_code values('job_mealfood_qty',$job_mealfood_qty)}
db eval {insert or replace into z_tcl_code values('job_opt_change',$job_opt_change)}
db eval {insert or replace into z_tcl_code values('job_daily_value_refresh',$job_daily_value_refresh)}
db eval {insert or replace into z_tcl_code values('SetMealRange_am',$SetMealRange_am)}
db eval {insert or replace into z_tcl_code values('SetMPD',$SetMPD)}
db eval {insert or replace into z_tcl_code values('job_SetMPD',$job_SetMPD)}
db eval {insert or replace into z_tcl_code values('SwitchToAnalysis',$SwitchToAnalysis)}
db eval {insert or replace into z_tcl_code values('SwitchToMenu',$SwitchToMenu)}
db eval {insert or replace into z_tcl_code values('TurnOffTheBubbleMachine',$TurnOffTheBubbleMachine)}
db eval {insert or replace into z_tcl_code values('TurnOnTheBubbleMachine',$TurnOnTheBubbleMachine)}
db eval {insert or replace into z_tcl_code values('badPCF',$badPCF)}
db eval {insert or replace into z_tcl_code values('dropoutvf',$dropoutvf)}
db eval {insert or replace into z_tcl_code values('format_meal_id',$format_meal_id)}
db eval {insert or replace into z_tcl_code values('mealchange',$mealchange)}
db eval {insert or replace into z_tcl_code values('n6hufa',$n6hufa)}
db eval {insert or replace into z_tcl_code values('recenterscale',$recenterscale)}
db eval {insert or replace into z_tcl_code values('setPCF',$setPCF)}
db eval {insert or replace into z_tcl_code values('setRefDesc',$setRefDesc)}
db eval {insert or replace into z_tcl_code values('tuneinvf',$tuneinvf)}
db eval {insert or replace into z_tcl_code values('pbprog',$pbprog)}
db eval {insert or replace into z_tcl_code values('pbprog1',$pbprog1)}
db eval {insert or replace into z_tcl_code values('theusualPopulateMenu',$theusualPopulateMenu)}
db eval {insert or replace into z_tcl_code values('theusualAdd',$theusualAdd)}
db eval {insert or replace into z_tcl_code values('theusualSave',$theusualSave)}
db eval {insert or replace into z_tcl_code values('theusualSaveNew',$theusualSaveNew)}
db eval {insert or replace into z_tcl_code values('theusualNewName',$theusualNewName)}
db eval {insert or replace into z_tcl_code values('theusualDelete',$theusualDelete)}
db eval {insert or replace into z_tcl_code values('monoright',$monoright)}
db eval {insert or replace into z_tcl_code values('rank2vf',$rank2vf)}
db eval {insert or replace into z_tcl_code values('rm2vf',$rm2vf)}
db eval {insert or replace into z_tcl_code values('changedv_vitmin',$changedv_vitmin)}
db eval {insert or replace into z_tcl_code values('drawClock',$drawClock)}
db eval {insert or replace into z_tcl_code values('stundenZeigerAuf',$stundenZeigerAuf)}
db eval {insert or replace into z_tcl_code values('minutenZeigerAuf',$minutenZeigerAuf)}
db eval {insert or replace into z_tcl_code values('sekundenZeigerAuf',$sekundenZeigerAuf)}
db eval {insert or replace into z_tcl_code values('showTime',$showTime)}
db eval {insert or replace into z_tcl_code values('InitialLoad_alt_GUI',$InitialLoad_alt_GUI)}
db eval {insert or replace into z_tcl_code values('pbprog_threaded',$pbprog_threaded)}
db eval {insert or replace into z_tcl_code values('pbprog1_threaded',$pbprog1_threaded)}
db eval {insert or replace into z_tcl_code values('opt_change',$opt_change)}
db eval {insert or replace into z_tcl_code values('opt_change_later',$opt_change_later)}
db eval {insert or replace into z_tcl_code values('SetMealBase',$SetMealBase)}
db eval {insert or replace into z_tcl_code values('GO_change',$GO_change)}
db eval {insert or replace into z_tcl_code values('get_procs_from_db',$get_procs_from_db)}
db eval {insert or replace into z_tcl_code values('load_nutr_def',$load_nutr_def)}
db eval {insert or replace into z_tcl_code values('load_fd_group',$load_fd_group)}
db eval {insert or replace into z_tcl_code values('load_food_des1',$load_food_des1)}
db eval {insert or replace into z_tcl_code values('load_weight',$load_weight)}
db eval {insert or replace into z_tcl_code values('load_nut_data1',$load_nut_data1)}
db eval {insert or replace into z_tcl_code values('load_legacy',$load_legacy)}
db eval {COMMIT}

package require Tk

wm geometry . 1x1
set appSize 0.0
set ::magnify [expr {[winfo vrootheight .] / 711.0}]
if {[string is double \
  -strict $appSize] && $appSize > 0.0} {
 set ::magnify [expr {$::magnify * $appSize}]
 }
if {$appSize == 0.0} {set ::magnify 1.0}
foreach font [font names] {
 font configure $font \
  -size [expr {int($::magnify * [font configure $font \
  -size]
)}]
 }
set i [font measure TkDefaultFont \
  -displayof . "  TransMonoenoic  "]
set ::column18 [expr {int(round($i / 3.0))}]
set ::column15 [expr {int(round(2.0 * $i / 5.0))}]
option add *Dialog.msg.wrapLength [expr {400 * $::magnify}]
option add *Dialog.dtl.wrapLength [expr {400 * $::magnify}]

db eval {select max(version) as "::version" from z_tcl_version} { }

tk_messageBox \
  -type ok \
  -title "updateNUT.tcl Completion" \
  -message "There\'s a signpost up ahead.\n\nNext stop:  ${::version}"
exit 0

