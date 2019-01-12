# requires high_contrast.tcl

set Make_GUI_Linux {


set gr 1.6180339887

if {[file exists "NUTR_DEF.txt"]} {
  set need_load 1
} else {
  set need_load 0
}

if {$appSize > 1.3} {
  set appSize 1.3
} elseif {$appSize < 0.7} {
  set appSize 0.7
}

if {$need_load} {
 if {![catch {package require Thread}]} {
  set ::THREADS 1
  set ::GUI_THREAD [thread::id]
  set ::SQL_THREAD [thread::create "
    package require sqlite3 ;
    sqlite3 db $DiskDB;
    db timeout 10000 ;
    [info body get_procs_from_db];
    set ::THREADS 1;
    set ::GUI_THREAD $::GUI_THREAD;
    set ::DiskDB $DiskDB;
    thread::wait"] }
 }


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

array set background {
  am "#00FFFF"
  rm "#FF7F00"
  vf "#00FF00"
  ar "#7FBF00"
}

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
set ::PCFchoices {
  {No Auto Portion Control}
  {Protein}
  {Non-Fiber Carb}
  {Total Fat}
  {Vitamin A}
  {Thiamin}
  {Riboflavin}
  {Niacin}
  {Panto. Acid}
  {Vitamin B6}
  {Folate}
  {Vitamin B12}
  {Choline}
  {Vitamin C}
  {Vitamin D}
  {Vitamin E}
  {Vitamin K1}
  {Calcium}
  {Copper}
  {Iron}
  {Magnesium}
  {Manganese}
  {Phosphorus}
  {Potassium}
  {Selenium}
  {Sodium}
  {Zinc}
  {Glycine}
  {Retinol}
  {Fiber}
}

set ::rmMenu .nut.rm.frmenu

set ::newtheusual ""

set ratio_widget_height_to_spacer 9.6
set Refusevf "0%"
set ::ENERC_KCALpo 0
set ::balvals {}
set screen 0
set rely 0.252109375


wm geometry . [expr {int($appSize / 1.3 * $vrootwGR)}]x[expr {int(\
  $appSize / 1.3 * $vroothGR)}]
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

if {$::magnify > 0.0} {
  ttk::style configure nut.Treeview \
    -font TkFixedFont \
    -rowheight [expr {int(round($::magnify * 15.0))}]
} else {
  ttk::style configure nut.Treeview \
    -font TkFixedFont \
}

trace add variable ::FIRSTMEALam write SetMealRange_am
trace add variable ::LASTMEALam write SetMealRange_am


ttk::notebook .nut
place .nut \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 1.0

ttk::frame .nut.am -style "am.TFrame"
ttk::frame .nut.rm -style "rm.TFrame"
ttk::frame .nut.ar -style "ar.TFrame"
ttk::frame .nut.vf -style "vf.TFrame"
ttk::frame .nut.po -style "po.TFrame"
ttk::frame .nut.ts -style "ts.TFrame"
ttk::frame .nut.qn -style "qn.TFrame"

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

bind .nut <<NotebookTabChanged>> {NutTabChange .nut}

ttk::label .nut.am.herelabel \
  -text "Here are \"Daily Value\" average percentages for your previous " \
  -style am.TLabel \
  -anchor e
ttk::spinbox .nut.am.mealsb \
  -style "am.TSpinbox" \
  -width 5 \
  -justify right \
  -from 1 \
  -to 999999 \
  -increment 1 \
  -textvariable ::meals_to_analyze_am
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

  #-width [expr {$::magnify * 11}] 
  #-sliderlength [expr {$::magnify * 20}] 
#-showvalue 0 

ttk::scale .nut.rm.scale \
  -orient horizontal \
	-style "rm.Horizontal.TScale" \
  -variable ::mealoffset \
  -from -100 \
  -to 100 \
  -command mealchange
ttk::label .nut.rm.scale.label \
  -style rm.TLabel \
  -text "None" \
  -wraplength [expr {$::magnify * 175}] \
  -justify center

place .nut.rm.scale.label \
  -relx 0.0058 \
  -rely 0.0056296296 \
  -relheight 0.1 \
  -relwidth 0.24

place .nut.rm.scale \
  -relx 0.0058 \
  -rely 0.0046296296 \
  -relheight 0.1 \
  -relwidth 0.24

ttk::menubutton .nut.rm.theusual \
	-style "rm.center.TMenubutton"\
  -text "Customary Meals" \
  -direction right \
  -menu .nut.rm.theusual.m
place .nut.rm.theusual \
  -relx 0.0058 \
  -rely 0.12 \
  -relheight 0.05 \
  -relwidth 0.2
menu .nut.rm.theusual.m \
  -tearoff 0 \
	-background "#FF7F00" \
  -postcommand theusualPopulateMenu
.nut.rm.theusual.m add cascade \
  -label "Add Customary Meal to this meal" \
  -menu .nut.rm.theusual.m.add
.nut.rm.theusual.m add cascade \
  -label "Save this meal as a Customary Meal" \
  -menu .nut.rm.theusual.m.save
.nut.rm.theusual.m add cascade \
  -label "Delete a Customary Meal" \
  -menu .nut.rm.theusual.m.delete
menu .nut.rm.theusual.m.add \
	-background "#FF7F00" \
  -tearoff 0
menu .nut.rm.theusual.m.save \
	-background "#FF7F00" \
  -tearoff 0
menu .nut.rm.theusual.m.delete \
	-background "#FF7F00" \
  -tearoff 0

ttk::button .nut.rm.recipebutton \
	-style "meal.TButton"\
  -text "Save as a Recipe" \
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

ttk::entry .nut.rm.newtheusualentry \
  -textvariable ::newtheusual

button .nut.rm.newtheusualbutton \
  -anchor center \
  -text "Save" \
  -command theusualNewName

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

ttk::button .nut.rm.analysismeal \
  -text "Analysis" \
	-style "rm.analysis.TButton" \
  -command SwitchToAnalysis

ttk::menubutton .nut.rm.setmpd \
  -text "Delete All Meals and Set Meals Per Day" \
	-style "rm.TMenubutton"\
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

ttk::button .nut.rm.searchcancel \
  -text "Cancel" \
  -width 6 \
	-style "rm.searchcancel.TButton" \
  -command CancelSearch

ttk::frame .nut.rm.frtreeview \
  -style rm.TFrame


grid propagate .nut.rm.frtreeview 0
grid [ttk::treeview .nut.rm.frtreeview.treeview \
  -style "rm.Treeview" \
  -columns "Long_Desc" \
  -show tree \
  -yscrollcommand ".nut.rm.frtreeview.scrollv set" \
  -xscrollcommand ".nut.rm.frtreeview.scrollh set" ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.rm.frtreeview.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.rm.frtreeview.treeview yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.rm.frtreeview.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.rm.frtreeview.treeview xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe

grid columnconfigure .nut.rm.frtreeview 0 \
  -weight 1 \
  -minsize 0
grid rowconfigure .nut.rm.frtreeview 0 \
  -weight 1 \
  -minsize 0

bind .nut.rm.frtreeview.treeview <<TreeviewSelect>> FoodChoicerm


trace add variable ::like_this_rm write FindFoodrm
bind .nut.rm.fsentry <FocusIn> FoodSearchrm

ttk::frame .nut.rm.frmenu \
  -style rm.TFrame

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

ttk::spinbox .nut.vf.sb0 \
  -style "vf.TSpinbox" \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable gramsvf
ttk::spinbox .nut.vf.sb1 \
  -style "vf.TSpinbox" \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable ouncesvf
ttk::spinbox .nut.vf.sb2 \
  -style "vf.TSpinbox" \
  -width 5 \
  -justify right \
  -from \
  -9999 \
  -to 9999 \
  -increment 1 \
  -textvariable caloriesvf
ttk::spinbox .nut.vf.sb3 \
  -style "vf.TSpinbox" \
  -width 5 \
  -justify right \
  -from \
  -999 \
  -to 999 \
  -increment 0.125 \
  -textvariable Amountvf
ttk::menubutton .nut.vf.refusemb \
	-style "vf.TMenubutton"\
  -text "Refuse" \
  -direction below \
  -menu .nut.vf.refusemb.m
menu .nut.vf.refusemb.m \
	-background "#00FF00" \
  -tearoff 0
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

ttk::button .nut.vf.meal \
  -text "Add to Meal" \
	-style "vf.searchcancel.TButton" \
  -state disabled \
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


ttk::frame .nut.vf.frtreeview \
  -style vf.TFrame

grid propagate .nut.vf.frtreeview 0
grid [ttk::treeview .nut.vf.frtreeview.treeview \
  -style "vf.Treeview" \
  -columns "Long_Desc" \
  -show tree \
  -yscrollcommand ".nut.vf.frtreeview.scrollv set" \
  -xscrollcommand ".nut.vf.frtreeview.scrollh set" ] \
  -row 0 \
  -column 0 \
  -sticky nsew
grid [scrollbar .nut.vf.frtreeview.scrollv \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient vertical \
  -command ".nut.vf.frtreeview.treeview yview"] \
  -row 0 \
  -column 1 \
  -sticky nsew
grid [scrollbar .nut.vf.frtreeview.scrollh \
  -width [expr {$::magnify * 5}] \
  -relief sunken \
  -orient horizontal \
  -command ".nut.vf.frtreeview.treeview xview"] \
  -row 1 \
  -column 0 \
  -sticky nswe

grid columnconfigure .nut.vf.frtreeview 0 \
  -weight 1 \
  -minsize 0
grid rowconfigure .nut.vf.frtreeview 0 \
  -weight 1 \
  -minsize 0

bind .nut.vf.frtreeview.treeview <<TreeviewSelect>> FoodChoicevf


ttk::label .nut.ar.name \
  -text "Recipe Name" \
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

ttk::label .nut.ar.numserv \
  -text "Number of servings recipe makes" \
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
ttk::label .nut.ar.servunit \
  -text "Serving Unit (cup, piece, tbsp, etc.)" \
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

ttk::label .nut.ar.servnum \
  -text "Number of units in one serving" \
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

ttk::label .nut.ar.weight \
  -text "Weight of one serving (if known)" \
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
  -command RecipeDone
place .nut.ar.save \
  -relx 0.87 \
  -rely 0.14722222 \
  -relheight 0.044444444 \
  -relwidth 0.11
button .nut.ar.cancel \
  -text "Cancel" \
  -command RecipeCancel
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

# ------------------------ Personal Options -----------------------------

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
ttk::label .nut.po.pane.wlogframe.weight_l \
  -text "Weight" \
	-style "po.TLabel"
place .nut.po.pane.wlogframe.weight_l \
  -relx 0.0 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.45
ttk::spinbox .nut.po.pane.wlogframe.weight_s \
  -style "po.TSpinbox" \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::weightyintercept
place .nut.po.pane.wlogframe.weight_s \
  -relx 0.5 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.4

ttk::label .nut.po.pane.wlogframe.bf_l \
  -text "Body Fat %" \
	-style "po.TLabel"
place .nut.po.pane.wlogframe.bf_l \
  -relx 0.0 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.45
ttk::spinbox .nut.po.pane.wlogframe.bf_s \
  -style "po.TSpinbox" \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::currentbfp
place .nut.po.pane.wlogframe.bf_s \
  -relx 0.5 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.4

ttk::button .nut.po.pane.wlogframe.accept \
  -text "Accept New\nMeasurements" \
  -style "po.TButton" \
  -command AcceptNewMeasurements
place .nut.po.pane.wlogframe.accept \
  -relx 0.36 \
  -rely 0.2 \
  -relheight 0.1 \
  -relwidth 0.55

ttk::label .nut.po.pane.wlogframe.summary \
  -wraplength [expr {$::magnify * 150}] \
  -textvariable ::wlogsummary \
  -justify right \
  -style "po.TLabel" \
  -anchor ne
place .nut.po.pane.wlogframe.summary \
  -relx 0.0 \
  -rely 0.34 \
  -relheight 0.6 \
  -relwidth 0.93

ttk::button .nut.po.pane.wlogframe.clear \
  -text "Clear Weight Log" \
  -command ClearWeightLog


ttk::label .nut.po.pane.optframe.cal_l \
  -text "Calories kc" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.cal_l \
  -relx 0.0 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.cal_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -style "po.TSpinbox" \
  -increment 0.1 \
  -textvariable ::ENERC_KCALopt
place .nut.po.pane.optframe.cal_s \
  -relx 0.265 \
  -rely 0.03 \
  -relheight 0.04444444 \
  -relwidth 0.14
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
ttk::label .nut.po.pane.optframe.fat_l \
  -text "Total Fat g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.fat_l \
  -relx 0.0 \
  -rely 0.11 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.fat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -style "po.TSpinbox" \
  -textvariable ::FATopt
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
ttk::label .nut.po.pane.optframe.prot_l \
  -text "Protein g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.prot_l \
  -relx 0.0 \
  -rely 0.19 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.prot_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::PROCNTopt \
  -style "po.TSpinbox"
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
ttk::label .nut.po.pane.optframe.nfc_l \
  -text "Non-Fiber Carb g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.nfc_l \
  -relx 0.0 \
  -rely 0.27 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.nfc_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::CHO_NONFIBopt \
  -style "po.TSpinbox"
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
ttk::label .nut.po.pane.optframe.fiber_l \
  -text "Fiber g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.fiber_l \
  -relx 0.0 \
  -rely 0.35 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.fiber_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FIBTGopt \
  -style "po.TSpinbox"
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
ttk::label .nut.po.pane.optframe.sat_l \
  -text "Saturated Fat g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.sat_l \
  -relx 0.0 \
  -rely 0.43 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.sat_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FASATopt \
  -style "po.TSpinbox"
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
ttk::label .nut.po.pane.optframe.efa_l \
  -text "Essential Fatty Acids g" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.efa_l \
  -relx 0.0 \
  -rely 0.51 \
  -relheight 0.04444444 \
  -relwidth 0.25
ttk::spinbox .nut.po.pane.optframe.efa_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::FAPUopt \
  -style "po.TSpinbox"
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
ttk::label .nut.po.pane.optframe.fish_l \
  -text "Omega-6/3 Balance" \
  -style "po.TLabel" \
  -anchor e
place .nut.po.pane.optframe.fish_l \
  -relx 0.0 \
  -rely 0.59 \
  -relheight 0.04444444 \
  -relwidth 0.25
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
ttk::menubutton .nut.po.pane.optframe.dv_mb \
	-style "po.TMenubutton"\
  -text "Daily Values for Individual Micronutrients" \
  -direction right \
  -menu .nut.po.pane.optframe.dv_mb.m
menu .nut.po.pane.optframe.dv_mb.m \
	-background "#5454FF" \
  -tearoff 0
foreach nut {
	{Vitamin A} Thiamin Riboflavin Niacin
	{Panto. Acid}
	{Vitamin B6} Folate
	{Vitamin B12}
	{Choline}
	{Vitamin C}
	{Vitamin D}
	{Vitamin E}
	{Vitamin K1}
	Calcium
	Copper
	Iron
	Magnesium
	Manganese
	Phosphorus
	Potassium
	Selenium
	Sodium
	Zinc
	Glycine
	Retinol
} {
 .nut.po.pane.optframe.dv_mb.m add command \
  -label $nut \
  -command [list changedv_vitmin $nut]
 }

place .nut.po.pane.optframe.dv_mb \
  -relx 0.02 \
  -rely 0.67 \
  -relheight 0.04444444 \
  -relwidth 0.55
ttk::label .nut.po.pane.optframe.vite_l \
  -text "vite" \
  -style "po.TLabel" \
  -anchor e
ttk::spinbox .nut.po.pane.optframe.vite_s \
  -width 7 \
  -justify right \
  -from 1 \
  -to 9999 \
  -increment 0.1 \
  -textvariable ::NULLopt \
  -style "po.TSpinbox"
ttk::checkbutton .nut.po.pane.optframe.vite_cb1 \
  -text "Adjust to my meals" \
  -variable ::vitminpo \
  -onvalue \
  -1 \
  -style po.TCheckbutton
ttk::checkbutton .nut.po.pane.optframe.vite_cb2 \
  -text "Daily Value Default" \
  -variable ::vitminpo \
  -onvalue 2 \
  -style po.TCheckbutton
ttk::frame .nut.ts.frranking \
	-style "frranking.TFrame"
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

labelframe .nut.ts.frgraph
place .nut.ts.frgraph \
  -relx 0.0 \
  -rely 0.75 \
  -relheight 0.25 \
  -relwidth 1.0

canvas .nut.ts.frgraph.canvas \
  -background "#FFFF00" \
  -relief flat
place .nut.ts.frgraph.canvas \
  -relx 0.0 \
  -rely 0.0 \
  -relheight 1.0 \
  -relwidth 1.0

grid [ttk::treeview .nut.ts.frranking.ranking \
  -yscrollcommand [list .nut.ts.frranking.vsb set] \
  -style "frranking.Treeview" \
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
   ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::caloriebutton \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton" } else {
   ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Calories (2000)" \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"    }
  if {$x == "ar"} {
     ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
        -textvariable ::${nut}${x}dv \
        -justify right
     } else {
     ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  			-anchor e \
        -textvariable ::${nut}${x}dv \
        -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -style "nutrient.TButton"
  ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"\
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
    -textvariable ::${nut}${x}dv \
    -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
    -textvariable ::${nut}${x}dv \
    -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -text "%" \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
    -textvariable ::${nut}${x}dv \
    -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
    -textvariable ::${nut}${x}dv \
    -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
    -text "%" \
    -style "nutrient.$x.w.TLabel"
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
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC
  VITD_BOTH VITE VITK1} {
    ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
      -textvariable ::${nut}b \
      -command "NewStory $nut $screen" \
      -style "nutrient.TButton"
    if {$x == "ar"} {
      ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
        -textvariable ::${nut}${x}dv \
        -justify right
    } else {
      ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  		-anchor e \
        -textvariable ::${nut}${x}dv \
        -style "nutrient.$x.TLabel"
     }
    ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
      -text "%" \
      -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
    -textvariable ::${nut}${x}dv \
    -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
    -textvariable ::${nut}${x}dv \
    -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
    -text "%" \
    -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
    -textvariable ::${nut}${x}1 \
    -justify right
   } else {
    ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
      -textvariable ::${nut}${x}1 \
      -style "nutrient.$x.TLabel"

#uncomment this line and comment out the previous if user insists he
#must see CHO_NONFIB percentage of DV instead of grams

#    label .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x}dv \
  -background $background($x) \
  -anchor e
   }
   ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"

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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
    -textvariable ::${nut}${x}dv \
    -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
    -textvariable ::${nut}${x}dv \
    -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
    -text "%" \
    -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -text "Omega-6/3 Balance" \
    -command "NewStory FAPU $x" \
    -style "nutrient.TButton"
  ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
    -textvariable ::${nut}${x} \
    -style "nutrient.$x.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
    ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
      -textvariable ::${nut}${x} \
      -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Prot / Carb / Fat" \
  -command "NewStory ENERC_KCAL $x" \
  -style "nutrient.TButton"
  ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"\
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
 foreach nut {FAT FASAT FAMS FAPU OMEGA6 LA AA OMEGA3 ALA EPA DHA CHOLE} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {VITA_RAE THIA RIBF NIA PANTAC VITB6A FOL VITB12 CHOLN VITC
  VITD_BOTH VITE VITK1} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {CA CU FE MG MN P K SE NA ZN} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -style "nutrient.$x.TLabel"\
  -textvariable ::${nut}${x} \
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -text "Omega-6/3 Balance" \
  -command "NewStory FAPU $x" \
  -style "nutrient.TButton"
  ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"\
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {PROCNT ADPROT ALA_G ARG_G ASP_G CYS_G GLU_G GLY_G HISTN_G HYP
  ILE_G} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {ENERC_KJ ASH WATER CAFFN THEBRN ALC FLD BETN CHOLN FOLAC FOLFD
  FOLDFE RETOL} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {VITA_IU ERGCAL CHOCAL VITD VITB12_ADDED VITE_ADDED VITK1D MK4
  TOCPHA TOCPHB TOCPHG TOCPHD TOCTRA} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {TOCTRB TOCTRG TOCTRD CARTA CARTB CRYPX LUT_ZEA LYCPN CHOLE
  PHYSTR SITSTR CAMD5 STID7} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"\
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {FASAT F4D0 F6D0 F8D0 F10D0 F12D0 F13D0 F14D0 F15D0 F16D0 F17D0
  F18D0 F20D0 F22D0 F24D0} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {FAMS F14D1 F15D1 F16D1 F16D1C F17D1 F18D1 F18D1C F20D1 F22D1
  F22D1C F24D1C} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"\
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
    -textvariable ::${nut}b \
    -command "NewStory $nut $screen" \
    -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
 foreach nut {F20D3 F20D3N3 F20D3N6 F20D4 F20D4N6 F20D5 F21D5 F22D4 F22D5
  F22D6} {
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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
  ttk::button .nut.${x}.nbw.screen${screen}.b${nut} \
  -textvariable ::${nut}b \
  -command "NewStory $nut $screen" \
  -style "nutrient.TButton"
  if {$x == "ar"} {
   ttk::entry .nut.${x}.nbw.screen${screen}.l${nut} \
  -textvariable ::${nut}${x} \
  -justify right
   } else {
   ttk::label .nut.${x}.nbw.screen${screen}.l${nut} \
  -anchor e \
  -textvariable ::${nut}${x} \
  -style "nutrient.$x.TLabel"
   }
  ttk::label .nut.${x}.nbw.screen${screen}.lu${nut} \
  -textvariable ::${nut}u \
  -style "nutrient.$x.w.TLabel"
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

bind .nut.am.nbw <<NotebookTabChanged>> {NBWTabChange .nut.am.nbw}
bind .nut.rm.nbw <<NotebookTabChanged>> {NBWTabChange .nut.rm.nbw}
bind .nut.vf.nbw <<NotebookTabChanged>> {NBWTabChange .nut.vf.nbw}
bind .nut.ar.nbw <<NotebookTabChanged>> {NBWTabChange .nut.ar.nbw}

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
  -mode determinate
 .loadframe.c create window [expr {$::clockscale * 150 + 0.38 * $i * $::clockscale * 200}] [expr {$::clockscale * 160 + 0.38 * $i * $::clockscale * 200}] \
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
  -message "NUT requires the USDA Nutrient Database to be present initially in
		order to be loaded into SQLite.  Download it in the full ascii version
		from \"https://data.nal.usda.gov/dataset/composition-foods-raw-processed-
		prepared-usda-national-nutrient-database-standard-referen-11\" or from
		\"http://nut.sourceforge.net\" and unzip it in this directory, [pwd]." \
#  -detail "Follow this same procedure later when you want to upgrade the USDA
		database yet retain your personal data.  After USDA files have been loaded
		into NUT they can be deleted.\n\nIf you really do want to reload a USDA
		database that you have already loaded, rename the file
		\"NUTR_DEF.txt.loaded\" to \"NUTR_DEF.txt\"."
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

set MealfoodWidget {

proc MealfoodWidget {Shrt_Desc NDB_No} {

	set noThereThere [lsearch \
	-exact $::MealfoodStatus $NDB_No]
	if {$noThereThere > -1} {
		return $noThereThere
	}	elseif {$noThereThere == -1} {
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
		ttk::spinbox ${::rmMenu}.menu.foodspin${seq} \
		-style "rm.TSpinbox" \
		-textvariable ::${NDB_No} \
		-width 5 \
		-justify right \
		-from 0 \
		-to 9999 \
		-increment 1 \
		-cursor [. cget \
		-cursor] \
				-state readonly \
		-command "MealfoodSetWeight %s ${NDB_No} ::${NDB_No}"
		if {! $::GRAMSopt} {
			${::rmMenu}.menu.foodspin${seq} configure \
			-format {%0.3f} \
			-from 0.0 \
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
			-from 0.0 \
			-to 999.9 \
			-increment 0.125
 		} else {
			${::rmMenu}.menu.foodspin${seq} configure \
			-from 0 \
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

set NBWTabChange {

proc NBWTabChange {notebook} {

	set tabindex [$notebook index [$notebook select]]

	foreach pane {am rm vf ar} {
		.nut.$pane.nbw select .nut.$pane.nbw.screen${tabindex}
	}
}
}

