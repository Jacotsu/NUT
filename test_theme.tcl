#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

source src/00_packages.tcl

sqlite3 db nut.db
set appSize 0.7
set ::magnify [expr {[winfo vrootheight .] / 711.0}]
set ::version test
set ::ALTGUI 1


source src/01_high_contrast.tcl
source src/02_code.tcl
source src/03_linux_gui.tcl

eval $tuneinvf
eval $Make_GUI_Linux

eval $ComputeDerivedValues
eval $load_logic
eval $AmountChangevf
eval $CalChangevf
eval $CancelSearch
eval $FindFoodrm
eval $FindFoodrm_later
eval $FindFoodvf
eval $FindFoodvf_later
eval $FoodChoicerm
eval $vf2rm
eval $FoodChoicevf
eval $job_view_foods
eval $job_view_foods_Gm_Wgt
eval $FoodChoicevf_alt
eval $FoodSearchrm
eval $FoodSearchvf
eval $GramChangevf
eval $GramChangevfResult
eval $InitializePersonalOptions
eval $ChangePersonalOptions
eval $RefreshWeightLog
eval $ClearWeightLog
eval $AcceptNewMeasurements
eval $RefreshMealfoodQuantities
eval $MealfoodDelete
eval $MealfoodSetWeight
eval $MealfoodSetWeightLater
eval $MealfoodWidget
eval $NBWamTabChange
eval $NBWrmTabChange
eval $NBWvfTabChange
eval $NBWarTabChange
eval $NewStoryLater
eval $NewStory
eval $NutTabChange
eval $OunceChangevf
eval $PCF
eval $RecipeSaveAs
eval $RecipeMod1
eval $RecipeModdv
eval $RecipeMod
eval $RecipeCancel
eval $RecipeDone
eval $ServingChange
eval $SetDefanal
eval $job_defanal_am
eval $job_mealfood_qty
eval $job_opt_change
eval $job_daily_value_refresh
eval $SetMealRange_am
eval $SetMPD
eval $job_SetMPD
eval $SwitchToAnalysis
eval $SwitchToMenu
eval $TurnOffTheBubbleMachine
eval $TurnOnTheBubbleMachine
eval $badPCF
eval $dropoutvf
eval $format_meal_id
eval $mealchange
eval $n6hufa
eval $recenterscale
eval $setPCF
eval $setRefDesc
eval $pbprog
eval $pbprog1
eval $theusualPopulateMenu
eval $theusualAdd
eval $theusualSave
eval $theusualSaveNew
eval $theusualNewName
eval $theusualDelete
eval $monoright
eval $rank2vf
eval $rm2vf
eval $changedv_vitmin
eval $drawClock
eval $stundenZeigerAuf
eval $minutenZeigerAuf
eval $sekundenZeigerAuf
eval $showTime
eval $pbprog_threaded
eval $pbprog1_threaded
eval $opt_change
eval $opt_change_later
eval $SetMealBase
eval $GO_change
eval $load_nutr_def
eval $load_fd_group
eval $load_food_des1
eval $load_weight
eval $load_nut_data1
eval $load_legacy



ttk::style theme use HighContrast

