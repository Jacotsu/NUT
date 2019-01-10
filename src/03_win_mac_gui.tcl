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

set ::ENERC_KCALpo 0

set ::balvals {}

set ::PCFchoices {{No Auto Portion Control} {Protein} {Non-Fiber Carb} {Total Fat} {Vitamin A} {Thiamin} {Riboflavin} {Niacin} {Panto. Acid} {Vitamin B6} {Folate} {Vitamin B12} {Choline} {Vitamin C} {Vitamin D} {Vitamin E} {Vitamin K1} {Calcium} {Copper} {Iron} {Magnesium} {Manganese} {Phosphorus} {Potassium} {Selenium} {Sodium} {Zinc} {Glycine} {Retinol} {Fiber}}
set ::rmMenu .nut.rm.frmenu

set screen 0
set row 0
set bcol 0
set valcol 3
set ucol 5


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

grid [ttk::label .nut.am.herelabel\
  -text "Here are \"Daily Value\" average percentages for your previous "\
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
