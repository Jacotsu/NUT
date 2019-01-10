package require Tk 8.6.0

namespace eval ttk::theme::HighContrast {

    variable version 0.1
    package provide ttk::theme::HighContrast $version

    variable colors
    array set colors {
        -fg             "#31363b"
        -bg             "#eff0f1"

        -disabledbg     "#e3e5e6"
        -disabledfg     "#a8a9aa"

        -selectbg       "#3daee9"
        -selectfg       "white"

        -window         "#eff0f1"
        -focuscolor     "#3daee9"
        -checklight     "#94d0eb"

				analyzeMealsBg  "#00FFFF"
				recordMealsBg   "#FF7F00"
				analyzeRecordBg "#7FBF00"
				viewFoodsBg			"#00FF00"
				persOptionsBg		"#5454FF"
				theStoryBg			"#FFFF00"
    }


    ttk::style theme create HighContrast -parent default -settings {
        ttk::style configure . \
            -background $colors(-bg) \
            -foreground $colors(-fg) \
            -troughcolor $colors(-bg) \
            -selectbackground $colors(-selectbg) \
            -selectforeground $colors(-selectfg) \
            -fieldbackground $colors(-window) \
            -borderwidth 1 \
            -focuscolor $colors(-focuscolor)

        ttk::style map . -foreground [list disabled $colors(-disabledfg)]

#
        # Layouts:
        #
        ttk::style layout rm.Horizontal.TScale {
        	Horizontal.Scale.trough -sticky ew
        }



        #
        # Settings:
        #

        ttk::style configure nutrient.TButton \
					-relief raised \
					-anchor center \
					-background "#FFFF00"

				ttk::style configure nutrient.am.TLabel \
					-background $colors(analyzeMealsBg) \
					-anchor e
				ttk::style configure nutrient.rm.TLabel \
					-background $colors(recordMealsBg) \
					-anchor e
				ttk::style configure nutrient.vf.TLabel \
					-background $colors(viewFoodsBg) \
					-anchor e
				ttk::style configure nutrient.ar.TLabel \
					-background $colors(analyzeRecordBg) \
					-anchor e
				ttk::style configure nutrient.am.w.TLabel \
					-background $colors(analyzeMealsBg) \
					-anchor w
				ttk::style configure nutrient.rm.w.TLabel \
					-background $colors(recordMealsBg) \
					-anchor w
				ttk::style configure nutrient.vf.w.TLabel \
					-background $colors(viewFoodsBg) \
					-anchor w
				ttk::style configure nutrient.ar.w.TLabel \
					-background $colors(analyzeRecordBg) \
					-anchor w



				ttk::style configure am.TFrame \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TLabel \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TNotebook \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TSpinbox \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.ar.name \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.ar.numserv \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.ar.servunit \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.ar.servnum \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.ar.weight \
					-background $colors(analyzeMealsBg)


				ttk::style configure ar.TButton \
					-background "#BFD780"
				ttk::style configure .nut.ar.cancel \
					-background "#BFD780"

				ttk::style configure ar.TFrame \
					-background $colors(analyzeRecordBg)
				ttk::style configure ar.TLabel \
					-background $colors(analyzeRecordBg)
				ttk::style configure ar.TNotebook \
					-background $colors(analyzeRecordBg)
				ttk::style configure ar.TRadiobutton \
					-background $colors(analyzeRecordBg)

				ttk::style configure lf.Horizontal.TProgressbar \
					-background "#006400"

				ttk::style configure lightmeal.TButton \
					-background "#FF9428"
				ttk::style configure meal.TMenubutton \
					-background "#FF9428"
				ttk::style configure rm.Horizontal.TScale \
					-background "#FF9428"
				ttk::style configure rm.Horizontal.TScale \
					-background "#FF9428"
				ttk::style configure rm.TMenubutton \
  				-relief raised \
					-background "#FF9428"
				ttk::style configure rm.center.TMenubutton \
  				-relief raised \
  				-anchor center \
					-background "#FF9428"
				ttk::style configure .nut.rm.theusual \
					-background "#FF9428"
				ttk::style configure .nut.rm.recipebutton \
					-background "#FF9428"
				ttk::style configure .nut.rm.analysismeal \
					-background "#FF9428"
				ttk::style configure .nut.rm.setmpd \
					-background "#FF9428"
				ttk::style configure .nut.vf.meal \
					-background "#FF9428"


				ttk::style configure meal.TButton \
  				-relief raised \
  				-anchor center \
					-background $colors(recordMealsBg)
				ttk::style configure meal.TRadiobutton \
					-background $colors(recordMealsBg)
				ttk::style configure nut.TCombobox \
					-background $colors(recordMealsBg)
				ttk::style configure rm.TCombobox \
					-background $colors(recordMealsBg)
				ttk::style configure rm.TFrame \
					-background $colors(recordMealsBg)
				ttk::style configure rm.TLabel \
					-background $colors(recordMealsBg)
				ttk::style configure rmright.TLabel \
					-background $colors(recordMealsBg) \
					-anchor e
				ttk::style configure rm.TNotebook \
					-background $colors(recordMealsBg)
				ttk::style configure rm.TSpinbox \
					-padding 0 \
					-background $colors(recordMealsBg)
				ttk::style configure .nut.rm.frlistbox.listbox \
					-background $colors(recordMealsBg)
				ttk::style configure .nut.rm.frmenu.menu \
					-background $colors(recordMealsBg)



				ttk::style configure nutbutton.TButton \
					-background $colors(theStoryBg)
				ttk::style configure .nut.ts.frgraph \
					-background $colors(theStoryBg)
				ttk::style configure .nut.ts.frgraph.canvas \
					-background $colors(theStoryBg)


				ttk::style configure po.TButton \
  				-relief raised \
					-anchor center \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
				ttk::style configure po.TMenubutton \
  				-relief raised \
					-background "#FF9428"
				ttk::style configure po.TCheckbutton \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
				ttk::style configure po.TLabel \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg) \
					-anchor e
				ttk::style configure po.TMenubutton \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
				ttk::style configure po.TSpinbox \
					-background $colors(persOptionsBg) \
					-foreground "#000000"

				ttk::style configure .nut.po.pane \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)

				ttk::style configure ts.TFrame \
					-background $colors(theStoryBg)
				ttk::style configure ts.TLabel \
					-background $colors(theStoryBg)



				ttk::style configure po.TFrame \
					-background $colors(persOptionsBg)


				ttk::style configure po.red.TButton \
					-background $colors(persOptionsBg) \
					-foreground "#FF0000"

				ttk::style configure recipe.TButton \
					-background $colors(analyzeRecordBg)

				ttk::style configure ts.TCheckbutton \
					-background $colors(viewFoodsBg) \
					-foreground "#000000"
				ttk::style configure ts.TCombobox \
					-background $colors(viewFoodsBg)


				ttk::style configure vf.TButton \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TCombobox \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TMenubutton \
  				-relief raised \
					-anchor center \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TFrame \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TLabel \
					-background $colors(viewFoodsBg)
				ttk::style configure vfleft.TLabel \
					-background $colors(viewFoodsBg) \
					-anchor w
				ttk::style configure vfright.TLabel \
					-background $colors(viewFoodsBg) \
					-anchor e
				ttk::style configure vftop.TLabel \
					-background $colors(viewFoodsBg) \
					-anchor n
				ttk::style configure vf.TNotebook \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TSpinbox \
					-padding 0 \
					-background $colors(viewFoodsBg)
				ttk::style configure meal.Horizontal.TProgressbar \
					-background $colors(viewFoodsBg)
				ttk::style configure nut.Treeview \
					-background $colors(viewFoodsBg)
				ttk::style configure .nut.vf.sb0 \
					-background $colors(viewFoodsBg)
				ttk::style configure .nut.vf.sb1 \
					-buttonbackground $colors(viewFoodsBg)
				ttk::style configure .nut.vf.sb1 \
					-buttonbackground $colors(viewFoodsBg)
				ttk::style configure .nut.vf.sb2 \
					-buttonbackground $colors(viewFoodsBg)
				ttk::style configure .nut.vf.sb3 \
					-buttonbackground $colors(viewFoodsBg)
				ttk::style configure .nut.vf.refusemb \
					-background $colors(viewFoodsBg)
				ttk::style configure .nut.vf.refusemb.m \
					-background $colors(viewFoodsBg)
				ttk::style configure .nut.ar.save \
					-background $colors(viewFoodsBg)


				ttk::style configure rm.searchcancel.TButton \
					-anchor center \
					-background $colors(viewFoodsBg)
				ttk::style configure rm.analysis.TButton \
					-anchor center \
					-background $colors(recordMealsBg)
				ttk::style configure vf.searchcancel.TButton \
					-anchor center \
					-background $colors(recordMealsBg)



				# Maps
				ttk::style map ar.TRadiobutton \
					-indicatorcolor { selected "#FF0000" }
				ttk::style map meal.TRadiobutton \
					-indicatorcolor { selected "#FF0000" }
				ttk::style map po.TCheckbutton \
					-indicatorcolor { selected "#FF0000" }
				ttk::style map po.red.TButton \
					-foreground { active "#FF0000" }


				ttk::style map nut.TCombobox \
					-fieldbackground { readonly $colors(theStoryBg) }
				ttk::style map nut.TCombobox \
					-selectbackground { readonly $colors(theStoryBg) }

				ttk::style map nut.TCombobox \
					-selectforeground { readonly "#000000" }
				ttk::style map po.TButton \
					-foreground { active "#000000" }
				ttk::style map po.TCheckbutton \
					-foreground { active "#000000" }
				ttk::style map po.TMenubutton \
					-foreground { active "#000000" }
				ttk::style map po.TSpinbox \
					-disabledforeground { active "#000000" }
				ttk::style map rm.TCombobox \
					-selectforeground { readonly "#000000" }
				ttk::style map ts.TCheckbutton \
					-foreground { active "#000000" }
				ttk::style map ts.TCombobox \
					-selectforeground { readonly "#000000" }

				ttk::style map po.TCombobox \
					-fieldbackground { readonly "#FFFFFF" }
				ttk::style map rm.TCombobox \
					-fieldbackground { readonly "#FF9428" }
				ttk::style map rm.TCombobox \
					-selectbackground { readonly "#FF9428" }

				ttk::style map ts.TCheckbutton \
					-background { active $colors(viewFoodsBg) }
				ttk::style map ts.TCombobox \
					-fieldbackground { readonly $colors(viewFoodsBg) }
				ttk::style map ts.TCombobox \
					-selectbackground { readonly $colors(viewFoodsBg) }
				ttk::style map vf.TCombobox \
					-fieldbackground { readonly $colors(viewFoodsBg) }

				ttk::style map ts.TCheckbutton \
					-indicatorcolor { selected "#FF0000" }


    }
}
