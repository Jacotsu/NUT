import gi
from gi.repository import Gtk
import db
import logging
import gettext
import meal
from matplotlib.backends.backend_gtk3agg import (
    FigureCanvasGTK3Agg as FigureCanvas)
import numpy as np
from matplotlib.figure import Figure
from datetime import datetime

gi.require_version('Gtk', '3.0')
_ = gettext.gettext


class MainHandler:
    def __init__(self, manager):
        self._manager = manager

    def on_destroy(self, *args):
        Gtk.main_quit()

    def record_meals_slider_changed(self, adj_object):
        val = adj_object.get_value() - 50
        # Gets current meal
        db = self._manager._db
        selected_meal = str(db.get_meal_from_offset_rel_to_current(val))
        logging.debug(f'Current meal set to {selected_meal}')
        self._manager._rm_meal_label \
            .set_text(f'Meal {self._manager._db.current_meal_string}')
        db.current_meal = selected_meal
        adj_object.set_value(50)

    def record_meals_set_pcf(self, cell_renderer_combo, path_string, new_iter):
        pcf_list = cell_renderer_combo.props.model
        NDB_No = pcf_list.get_value(new_iter, 0)
        Nutrient_name = pcf_list.model.get_value(new_iter, 1)
        #cell_renderer_combo.props.model.set_value(new_iter, 5, Nutrient_name)
        logging.debug(f'Selected PCF: {NDB_No} {Nutrient_name}')

    def analysis_meal_no_changed(self, adj_object):
        val = adj_object.get_value()
        logging.debug(f'Number of meal to analyze set to {val}')
        self._manager._db.am_analysis_meal_no = val

    def nutrient_clicked(self, treeview, path, view_column):
        """
        This event is activated when a user double clicks a valid
        nutrient in the treeview
        """
        data = treeview.get_model()
        tree_iter = data.get_iter(path)
        nutrient = data.get(tree_iter, 0, 1)
        # If this is None, the nutrient is just a grouping category and
        # doesn't have a story
        if nutrient[0]:
            logging.debug(f'{nutrient} Nutrient clicked')
            # Placeholder nutrient 203
            story_manager = TheStory(203)
        else:
            logging.info(f'{nutrient} Nutrient group clicked')

    def food_clicked(self, treeview, path, view_column):
        """
        This event is activated when a user double clicks a valid
        nutrient in the treeview
        """
        data = treeview.get_model()
        tree_iter = data.get_iter(path)
        food_info = data.get(tree_iter, 0)
        logging.debug(f'{food_info} Food clicked')
        # Placeholder nutrient 203
        ViewFood(203)


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
        self._manager._db.set_nutrient_DV('ENERC_KCAL', calories)

    def accept_measurements(self, button):
        settings_wdgs = self._manager._settings_widgets
        self._manager._db\
                .insert_weight_log(settings_wdgs['weight_sp'].get_value(),
                                   settings_wdgs['bodyfat_sp'].get_value())
        self._manager._update_GUI_settings()


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

class TheStoryHandler:
    def __init__(self, manager):
        self._manager = manager

    def plot_area_resize(self, widget, event):
        logging.debug(_('The story plot area resized to ({}, {})')
                      .format(1, 1))

    def start_date_selected(self, calendar):
        date = calendar.get_date()
        self._manager._start_date = f'{date[0]:02}{date[1]:02}{date[2]:02}'
        logging.debug(_('Start date set to {}').format(date))
        self._manager._update_data()

    def end_date_selected(self, calendar):
        date = calendar.get_date()
        self._manager._end_date = f'{date[0]:02}{date[1]:02}{date[2]:02}'
        logging.debug(_('End date set to {}').format(date))
        self._manager._update_data()




class GTKGui:
    def __init__(self):
        self._db = db.DBMan()
        self._ntr = self._db.defined_nutrients

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

        builder.connect_signals(MainHandler(self))

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
    def __init__(self, Nutr_No):
        self._db = db.DBMan()
        self._Nutr_No = Nutr_No
        self._nutrient_name = self._db.get_nutrient_name(Nutr_No)
        self._end_date = str(self._db.current_meal)[:-2]
        self._start_date = \
            str(self._db.get_meal_from_offset_rel_to_current(
                self._db.am_analysis_meal_no))[:-2]

        builder = Gtk.Builder()
        builder.add_from_file("the_story.glade")

        self._window = builder.get_object("story_window")
        self._graph_canvas = builder.get_object("story_graph")

        builder.connect_signals(TheStoryHandler(self))

        fd_group_list = builder.get_object("fd_group")
        fd_group_list.append((0, _('All food groups')))
        for food_group in self._db.food_groups:
            fd_group_list.append(food_group)

        self._window.set_title(_("The {} story")
                               .format(_(self._nutrient_name)))

        logging.debug(_("{} story window created")
                      .format(_(self._nutrient_name)))
        self._setup_plot()
        self._update_data()

        self._window.show_all()

    def _setup_plot(self):
        figure = Figure(figsize=(5, 4), dpi=100)
        ax = figure.add_subplot(111)
        ax.set_ylabel(_('{} intake').format(_(self._nutrient_name)))
        ax.set_xlabel(_('Date'))
        self._plot_lines, = ax.plot_date([datetime.strptime('20190102', '%Y%m%d'),datetime.strptime('20190103', '%Y%m%d'),datetime.strptime('20190104', '%Y%m%d')], [1,2,3], 'o-')

        canvas = FigureCanvas(figure)  # a Gtk.DrawingArea

        self.replace_widget(self._graph_canvas, canvas)
        self._graph_canvas = canvas

        self._graph_canvas.set_size_request(800, 600)

    def _update_data(self):
        logging.debug(_("Updating story plot"))
        data = self._db.get_nutrient_story(self._Nutr_No,
                                           self._start_date,
                                           self._end_date)
        # Need to fix this code
        x_data = []
        y_data = []
        for point in data:
            x_data.append(datetime.strptime(str(point[0]), '%Y%m%d'))
            y_data.append(point[1])
        logging.debug(x_data)
        logging.debug(y_data)
        self._plot_lines.set_data(np.array(x_data),
                                  np.array(y_data))
        self._graph_canvas.draw()

    @staticmethod
    def replace_widget(old, new):
        """
        https://stackoverflow.com/questions/27343166/gtk3-replace-child-widget-with-another-widget
        """
        parent = old.get_parent()

        props = {}
        for key in Gtk.ContainerClass.list_child_properties(type(parent)):
            props[key.name] = parent.child_get_property(old, key.name)

        parent.remove(old)
        parent.add(new)

        for name, value in props.items():
            parent.child_set_property(new, name, value)


class ViewFood:
    def __init__(self, NDB_No):
        builder = Gtk.Builder()
        builder.add_from_file("view_food_window.glade")
        self._window = builder.get_object("view_food")
        self._graph_canvas = builder.get_object("story_graph")
        self._db = db.DBMan()
        self._ntr = self._db.defined_nutrients

        # Must change with actual food selected
        self._window.set_title(_("view food"))
        logging.debug(_("view food window created"))

        self._searchable_food_list = builder.get_object("search_food_list")
        for food in self._db.food_list:
            self._searchable_food_list.append(food)
        logging.debug(_("Food list loaded in ViewFood window"))

        self._window.show_all()

    def _load_food(self, NDB_No):
        raise NotImplementedError
