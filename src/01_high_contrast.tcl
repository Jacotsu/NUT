# breeze.tcl --
#
# Breeze pixmap theme for the ttk package.
#
#

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

    #proc LoadImages {imgdir} {
    #    variable I
    #    foreach file [glob -directory $imgdir *.png] {
    #        set img [file tail [file rootname $file]]
    #        set I($img) [image create photo -file $file -format png]
    #    }
    #}

    #LoadImages [file join [file dirname [info script]] Breeze]

    ttk::style theme create HighContrast -parent default -settings {
        ttk::style configure . \
            -background $colors(-bg) \
            -foreground $colors(-fg) \
            -troughcolor $colors(-bg) \
            -selectbackground $colors(-selectbg) \
            -selectforeground $colors(-selectfg) \
            -fieldbackground $colors(-window) \
            -font "Helvetica 10" \
            -borderwidth 1 \
            -focuscolor $colors(-focuscolor)

        ttk::style map . -foreground [list disabled $colors(-disabledfg)]

        #
        # Layouts:
        #

        #ttk::style layout TButton {
        #    Button.button -children {
        #            Button.padding -children {
        #                Button.label -side left -expand true
        #            }
        #    }
        #}

        #ttk::style layout Toolbutton {
        #    Toolbutton.button -children {
        #        Toolbutton.focus -children {
        #            Toolbutton.padding -children {
        #                Toolbutton.label -side left -expand true
        #            }
        #        }
        #    }
        #}

        #ttk::style layout Vertical.TScrollbar {
        #    Vertical.Scrollbar.trough -sticky ns -children {
        #        Vertical.Scrollbar.thumb -expand true
        #    }
        #}

        #ttk::style layout Horizontal.TScrollbar {
        #    Horizontal.Scrollbar.trough -sticky ew -children {
        #        Horizontal.Scrollbar.thumb -expand true
        #    }
        #}

        #ttk::style layout TMenubutton {
        #    Menubutton.button -children {
        #        Menubutton.focus -children {
        #            Menubutton.padding -children {
        #                Menubutton.indicator -side right
        #                Menubutton.label -side right -expand true
        #            }
        #        }
        #    }
        #}
        #
        #ttk::style layout Item {
        #    Treeitem.padding -sticky nswe -children {
        #        Treeitem.indicator -side left -sticky {} Treeitem.image -side left -sticky {} -children {
        #            Treeitem.text -side left -sticky {}
        #            }
        #        }
        #}
        #   
        #
        # Elements:
        #

        #ttk::style element create Button.button image [list $I(button) \
        #        pressed     $I(button-active) \
        #        {active focus}       $I(button-active) \
        #        active      $I(button-hover) \
        #        focus       $I(button-focus) \
        #        disabled    $I(button-insensitive) \
        #    ] -border 3 -padding {3 2} -sticky ewns

        #ttk::style element create Toolbutton.button image [list $I(button-empty) \
        #        {active selected !disabled}  $I(button-active) \
        #        selected            $I(button-toggled) \
        #        pressed             $I(button-active) \
        #        {active !disabled}  $I(button-hover) \
        #    ] -border 3 -padding {3 2} -sticky news

        #ttk::style element create Checkbutton.indicator image [list $I(checkbox-unchecked) \
        #        disabled            $I(checkbox-unchecked-insensitive) \
        #        {pressed selected}  $I(checkbox-checked-pressed) \
        #        {active selected}   $I(checkbox-checked-active) \
        #        {pressed !selected} $I(checkbox-unchecked-pressed) \
        #        active              $I(checkbox-unchecked-active) \
        #        selected            $I(checkbox-checked) \
        #        {disabled selected} $I(checkbox-checked-insensitive) \
        #    ] -width 22 -sticky w

        #ttk::style element create Radiobutton.indicator image [list $I(radio-unchecked) \
        #        disabled            $I(radio-unchecked-insensitive) \
        #        {pressed selected}  $I(radio-checked-pressed) \
        #        {active selected}   $I(radio-checked-active) \
        #        {pressed !selected} $I(radio-unchecked-pressed) \
        #        active              $I(radio-unchecked-active) \
        #        selected            $I(radio-checked) \
        #        {disabled selected} $I(radio-checked-insensitive) \
        #    ] -width 22 -sticky w

        #    
        #ttk::style element create Horizontal.Scrollbar.trough image $I(scrollbar-trough-horiz-active) \
        #-border {6 0 6 0} -sticky ew
        #ttk::style element create Horizontal.Scrollbar.thumb \
        #     image [list $I(scrollbar-slider-horiz) \
        #                {active !disabled}  $I(scrollbar-slider-horiz-active) \
        #                disabled            $I(scrollbar-slider-insens) \
        #    ] -border {6 0 6 0} -sticky ew

        #ttk::style element create Vertical.Scrollbar.trough image $I(scrollbar-trough-vert-active) \
        #    -border {0 6 0 6} -sticky ns
        #ttk::style element create Vertical.Scrollbar.thumb \
        #    image [list $I(scrollbar-slider-vert) \
        #                {active !disabled}  $I(scrollbar-slider-vert-active) \
        #                disabled            $I(scrollbar-slider-insens) \
        #    ] -border {0 6 0 6} -sticky ns

        #
        #ttk::style element create Horizontal.Scale.trough \
        #    image [list $I(scrollbar-slider-horiz) disabled $I(scale-trough-horizontal)] \
        #    -border {8 5 8 5} -padding 0
        #ttk::style element create Horizontal.Scale.slider \
        #    image [list $I(scale-slider) \
        #        disabled $I(scale-slider-insensitive) \
        #        pressed $I(scale-slider-pressed)\
        #        active $I(scale-slider-active) \
        #        ] \
        #    -sticky {}
        #    
        #    
        #ttk::style element create Vertical.Scale.trough \
        #    image [list $I(scrollbar-slider-vert) disabled $I(scale-trough-vertical)] \
        #    -border {8 5 8 5} -padding 0
        #ttk::style element create Vertical.Scale.slider \
        #    image [list $I(scale-slider) \
        #        disabled $I(scale-slider-insensitive) \
        #        pressed $I(scale-slider-pressed)\
        #        active $I(scale-slider-active) \
        #        ] \
        #    -sticky {}

        #ttk::style element create Entry.field \
        #    image [list $I(entry) \
        #                {focus !disabled} $I(entry-focus) \
        #                {hover !disabled} $I(entry-active) \
        #                disabled $I(entry-insensitive)] \
        #    -border 3 -padding {6 4} -sticky news

        #ttk::style element create Labelframe.border image $I(labelframe) \
        #    -border 4 -padding 4 -sticky news

        #ttk::style element create Menubutton.button \
        #    image [list $I(button) \
        #                pressed  $I(button-active) \
        #                active   $I(button-hover) \
        #                disabled $I(button-insensitive) \
        #    ] -sticky news -border 3 -padding {3 2}
        #ttk::style element create Menubutton.indicator \
        #    image [list $I(arrow-down) \
        #                active   $I(arrow-down-prelight) \
        #                pressed  $I(arrow-down-prelight) \
        #                disabled $I(arrow-down-insens) \
        #    ] -sticky e -width 20

        #ttk::style element create Combobox.field \
        #    image [list $I(entry) \
        #        {readonly disabled}  $I(button-insensitive) \
        #        {readonly pressed}   $I(button-hover) \
        #        {readonly focus hover}     $I(button-active) \
        #        {readonly focus}     $I(button-focus) \
        #        {readonly hover}     $I(button-hover) \
        #        readonly             $I(button) \
        #        {disabled} $I(entry-insensitive) \
        #        {focus}    $I(entry-focus) \
        #        {focus hover}    $I(entry-focus) \
        #        {hover}    $I(entry-active) \
        #    ] -border 4 -padding 4
        #ttk::style element create Combobox.downarrow \
        #    image [list $I(arrow-down) \
        #                active    $I(arrow-down-prelight) \
        #                pressed   $I(arrow-down-prelight) \
        #                disabled  $I(arrow-down-insens) \
        #  ]  -border 4 -sticky {}

        #ttk::style element create Spinbox.field \
        #    image [list $I(entry) focus $I(entry-focus) hover $I(entry-active)] \
        #    -border 4 -padding 4 -sticky news
        #ttk::style element create Spinbox.uparrow \
        #    image [list $I(arrow-up-small) \
        #                active    $I(arrow-up-small-prelight) \
        #                pressed   $I(arrow-up-small-prelight) \
        #                disabled  $I(arrow-up-small-insens) \
        #    ] -border 4 -sticky {}
        #ttk::style element create Spinbox.downarrow \
        #    image [list $I(arrow-down-small) \
        #                active    $I(arrow-down-small-prelight) \
        #                pressed   $I(arrow-down-small-prelight) \
        #                disabled  $I(arrow-down-small-insens) \
        #  ] -border 4 -sticky {}

        #ttk::style element create Notebook.client \
        #    image $I(notebook-client) -border 1
        #ttk::style element create Notebook.tab \
        #    image [list $I(notebook-tab-top) \
        #                selected    $I(notebook-tab-top-active) \
        #                active      $I(notebook-tab-top-hover) \
        #    ] -padding {12 4 12 4} -border 2

        #    
        ## TODO Enhance
        #ttk::style element create Horizontal.Progressbar.trough \
        #    image $I(scrollbar-trough-horiz-active) -border {6 0 6 0} -sticky ew
        #ttk::style element create Horizontal.Progressbar.pbar \
        #    image $I(scrollbar-slider-horiz) -border {6 0 6 0} -sticky ew

        #ttk::style element create Vertical.Progressbar.trough \
        #    image $I(scrollbar-trough-vert-active) -border {0 6 0 6} -sticky ns
        #ttk::style element create Vertical.Progressbar.pbar \
        #    image $I(scrollbar-slider-vert) -border {0 6 0 6} -sticky ns

        ## TODO: Ab hier noch teilweise Arc style
        #ttk::style element create Treeview.field \
        #    image $I(treeview) -border 1
        #ttk::style element create Treeheading.cell \
        #    image [list $I(notebook-client) \
        #        active $I(treeheading-prelight)] \
        #    -border 1 -padding 4 -sticky ewns
        #
        ## TODO: arrow-* ist at the moment a little bit too big 
        ## the small version is too small :-)
        ## And at the moment there are no lines as in the Breeze theme
        ## And hover, pressed doesn't work
        #ttk::style element create Treeitem.indicator \
        #    image [list $I(arrow-right) \
        #        user2 $I(empty) \
        #        user1 $I(arrow-down) \
        #        ] \
        #    -width 15 -sticky w
        #    
        ## I don't know why Only with this I get a thin enough sash
        #ttk::style element create vsash image $I(transparent) -sticky e -padding 1 -width 1
	      #ttk::style element create hsash image $I(transparent) -sticky n -padding 1 -width 1

        #ttk::style element create Separator.separator image $I()

        #
        # Settings:
        #

        ttk::style configure TButton \
					-foreground red\
					-background "#FFFF00"\
					-padding {8 4 8 4} \
					-width -10 \
					-anchor center

        ttk::style configure TMenubutton -padding {8 4 4 4}
        ttk::style configure Toolbutton -anchor center
        ttk::style configure TCheckbutton -padding 4
        ttk::style configure TRadiobutton -padding 4
        ttk::style configure TSeparator -background $colors(-bg)

				ttk::style configure .nut.am \
					-background $colors(analyzeMealsBg)
				ttk::style configure .nut.rm \
					-background $colors(recordMealsBg)
				ttk::style configure .nut.ar \
					-background $colors(analyzeRecordBg)
				ttk::style configure .nut.vf \
					-background $colors(viewFoodsBg)
				ttk::style configure .nut.po \
					-background$colors(persOptionsBg)
				ttk::style configure .nut.ts \
					-background $colors(theStoryBg)



				ttk::style configure am.TFrame \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TLabel \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TNotebook \
					-background $colors(analyzeMealsBg)
				ttk::style configure am.TSpinbox \
					-background $colors(analyzeMealsBg)

				ttk::style configure ar.TButton \
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

				ttk::style configure meal.Horizontal.TProgressbar \
					-background $colors(viewFoodsBg)

				ttk::style configure meal.TButton \
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
					-background $colors(recordMealsBg)

				ttk::style configure nutbutton.TButton \
					-background $colors(theStoryBg)

				ttk::style configure po.TButton \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
				ttk::style configure po.TCheckbutton \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)

				ttk::style configure po.TFrame \
					-background $colors(persOptionsBg)
				ttk::style configure po.TLabel \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
				ttk::style configure po.TMenubutton \
					-background $colors(persOptionsBg) \
					-foreground $colors(theStoryBg)
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
				ttk::style configure ts.TFrame \
					-background $colors(theStoryBg)
				ttk::style configure ts.TLabel \
					-background $colors(theStoryBg)
				ttk::style configure vf.TButton \
					-background $colors(viewFoodsBg)
				ttk::style configure vf.TCombobox \
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
					-background $colors(viewFoodsBg)

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
