import gi
from gi.repository import Gtk
import db
import logging
import meal
from matplotlib.backends.backend_gtk3agg import (
    FigureCanvasGTK3Agg as FigureCanvas)
from matplotlib.figure import Figure
import numpy as np
gi.require_version('Gtk', '3.0')


class Handler:
    def __init__(self, window):
        self._window = window

    def on_destroy(self, *args):
        Gtk.main_quit()

    def record_meals_slider_changed(self, adj_object):
        val = adj_object.get_value() - 50
        # Gets current meal
        db = self._window._db
        selected_meal = str(db.get_meal_from_offset_rel_to_current(val))
        logging.debug(f'Current meal set to {selected_meal}')
        self._window._rm_meal_label \
            .set_text(f'Meal {self._window._db.current_meal_string}')
        db.current_meal = selected_meal
        adj_object.set_value(50)

    def record_meals_set_pcf(self, cell_renderer_combo, path_string, new_iter):
        NDB_No = cell_renderer_combo.props.model.get_value(new_iter, 0)
        Nutrient_name = cell_renderer_combo.props.model.get_value(new_iter, 1)
        #cell_renderer_combo.props.model.set_value(new_iter, 5, Nutrient_name)
        logging.debug(f'Selected PCF: {NDB_No} {Nutrient_name}')

    def analysis_meal_no_changed(self, adj_object):
        val = adj_object.get_value()
        logging.debug(f'Number of meal to analyze set to {val}')
        self._window._db.am_analysis_meal_no = val

    def add_food_to_meal(self, button):
        #meal.Food(self._rm_menu, self._ntr, None)
        logging.debug('Add food clicked')

    def view_food(self, button):
        logging.debug('View food clicked')

    def set_omega6_balance(self, widget):
        logging.debug(f'Setting omega6-3 balance to')

    def set_calories_dv(self, widget):
        calories = widget.get_value()
        logging.debug(f'Setting calories dv to {calories}')
        self._window._db.set_nutrient_DV('ENERC_KCAL', calories)

    def accept_measurements(self, button):
        settings_wdgs = self._window._settings_widgets
        self._window._db\
                .insert_weight_log(settings_wdgs['weight_sp'].get_value(),
                                   settings_wdgs['bodyfat_sp'].get_value())
        self._window._update_GUI_settings()


#208|Calories
#204|Total Fat
#203|Protein
#2000|Non-Fiber Carb
#291|Fiber
#606|Sat Fat
#Essential fatty acids
#
#
#205|Total Carb
#301|Calcium
#303|Iron
#304|Magnesium
#305|Phosphorus
#306|Potassium
#307|Sodium
#309|Zinc
#312|Copper
#315|Manganese
#317|Selenium
#319|Retinol
#320|Vitamin A
#328|Vitamin D
#401|Vitamin C
#404|Thiamin
#405|Riboflavin
#406|Niacin
#410|Panto. Acid
#415|Vitamin B6
#417|Folate
#418|Vitamin B12
#421|Choline
#430|Vitamin K1
#516|Glycine
#601|Cholesterol
#645|Mono Fat
#646|Poly Fat
#2001|LA
#2002|AA
#2003|ALA
#2004|EPA
#2005|DHA
#2006|Omega-6
#2007|Omega-3
#2008|Vitamin E

class GTKGui:
    def __init__(self):
        self._db = db.DBMan()
        self._ntr = self._db.defined_nutrients
        self._handler = Handler(self)

        builder = Gtk.Builder()
        builder.add_from_file("GTK_gui.glade")

        self._window = builder.get_object("main_window")
        self._rm_menu = builder.get_object("rm_menu")
        self._rm_anal = builder.get_object("rm_analysis")
        self._am_anal = builder.get_object("am_analysis")
        self._rm_meal_label = builder.get_object("rm_selected_meal_label")

        self._settings_widgets = {
            'weight_sp': builder.get_object('weight_sp_setting'),
            'bodyfat_sp': builder.get_object('bodyfat_sp_setting'),
            'calories_sp': builder.get_object('settings_calories_sp'),
            'total_fat_sp': builder.get_object('settings_total_fat_sp'),
            'protein_sp': builder.get_object('settings_protein_sp'),
            'non_fiber_carb_sp': builder
            .get_object('settings_non_fiber_carb_sp'),
            'fiber_sp': builder.get_object('settings_fiber_sp'),
            'sat_fat_sp': builder.get_object('settings_saturated_fat_sp'),
            'essential_fatty_acid_sp': builder
            .get_object('settings_essential_fatty_acid_sp'),
            'omega6_3_cmb': builder.get_object('omega_6_3_balance_settings'),
            'omega6_3_cb': builder.get_object('omega_6_3_balance_cb'),
            'omega6_3_list': builder.get_object('omega_6_3_balance_settings'),
            'weight_log_info': builder.get_object('weight_log_info')
        }

        omega6_3_bl_choices = builder.get_object('omega_6_3_balance_settings')
        for ch in range(15, 91):
            omega6_3_bl_choices.append([f'{ch}/{100-ch}'])

        self._searchable_food_list = builder.get_object("search_food_list")
        for food in self._db.food_list:
            self._searchable_food_list.append(food)

        am_meal_no_sp = builder.get_object('am_meals_no')
        am_meal_no_sp.set_value(self._db.am_analysis_meal_no)

        builder.connect_signals(self._handler)

        ntr = self._db.defined_nutrients
        self._update_GUI_settings()

        anal_header = self._db.rm_analysis_header
        #ntr['Prot/Carb/Fat'] = anal_header[7]
        #ntr['Omega-6/3 Balance'] = anal_header[8]
        meal.Food(self._rm_menu, ntr, 'test')
        meal.Food(self._rm_menu, ntr, 'test2')
        meal.Analysis(self._rm_anal, None, self._db.rm_analysis_nutrients)
        meal.Analysis(self._am_anal, None, self._db.am_analysis_nutrients)

        self._window.show_all()
        Gtk.main()

    def _update_GUI_settings(self):
        nutrients = self._ntr
        weight = self._db.last_weight
        logging.debug(f'Setting last weight to: {weight}')
        self._settings_widgets['weight_sp'].set_value(weight)
        bf = self._db.last_bodyfat
        logging.debug(f'Setting last bodyfat to: {bf}')
        self._settings_widgets['bodyfat_sp'].set_value(bf)
        self._settings_widgets['calories_sp'].set_value(nutrients[208][4])
        self._settings_widgets['total_fat_sp'].set_value(nutrients[204][4])
        self._settings_widgets['protein_sp'].set_value(nutrients[203][4])
        self._settings_widgets['non_fiber_carb_sp']\
            .set_value(nutrients[2000][4])
        self._settings_widgets['fiber_sp'].set_value(nutrients[291][4])
        self._settings_widgets['sat_fat_sp'].set_value(nutrients[606][4])
        self._settings_widgets['essential_fatty_acid_sp'].set_value(0)

        summary = self._db.weight_summary
        logging.debug(f'Setting weight log summary to: \n{summary}')
        self._settings_widgets['weight_log_info'].set_text(summary)

        for row in self._settings_widgets['omega6_3_list']:
            if row[0] == '/'.join(self._db.omega6_3_balance):
                self._settings_widgets['omega6_3_cb']\
                    .set_active_iter(row.iter)


class TheStory:
    def __init__(self):
        pass

    def draw_graph(self):
        f = Figure(figsize=(5, 4), dpi=100)
        a = f.add_subplot(111)
        t = np.arange(0.0, 3.0, 0.01)
        s = np.sin(2*np.pi*t)
        a.plot(t, s)

        sw = Gtk.ScrolledWindow()
        win.add(sw)
        # A scrolled window border goes outside the scrollbars and viewport
        sw.set_border_width(10)

        canvas = FigureCanvas(f)  # a Gtk.DrawingArea
        canvas.set_size_request(800, 600)
        sw.add_with_viewport(canvas)

        win.show_all()
        Gtk.main()

class FoodTopCellRendererCellRendererButton(Gtk.CellRenderer):
    """
    This class is a custom renderer that is used to render PCF combobox,
    or DV
    see this for info https://lazka.github.io/pgi-docs/Gtk-3.0/classes/TreeViewColumn.html#Gtk.TreeViewColumn.pack_start
    """
    def __init__(self):
        Gtk.CellRenderer.__init__(self)

    def do_get_size(self, widget, cell_area):
        buttonHeight = cell_area.height
        buttonWidth = buttonHeight
        return (0, 0, buttonWidth, buttonHeight)

    def do_render(self, window, widget, background_area, cell_area,
                  expose_area, flags):
        style = widget.get_style()
        x, y, buttonWidth, buttonHeight = self.get_size()
        style.paint_box(window, widget.get_state(), Gtk.SHADOW_ETCHED_OUT,
                        expose_area, widget, None, 0, 0, buttonWidth,
                        buttonHeight)
