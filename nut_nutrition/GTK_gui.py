import gi
from gi.repository import Gtk
import db
import logging
import gettext
import meal
from pprint import pformat
from utils import set_cells_data_func, set_pcf_combobox_cells_data_func
from matplotlib.backends.backend_gtk3agg import (
    FigureCanvasGTK3Agg as FigureCanvas)
from matplotlib.figure import Figure

gi.require_version('Gtk', '3.0')
_ = gettext.gettext


class MainHandler:
    def __init__(self, manager):
        self._manager = manager

    def on_destroy(self, *args):
        Gtk.main_quit()

    def delete_pressed_in_rm_meal_menu(self, widget, key_event):
        # Delete
        if key_event.get_keycode()[1] == 119:
            selection = widget.get_selection()
            treestore, selected_treepaths = selection.get_selected_rows()
            for path in selected_treepaths:
                food = treestore[path]
                db = self._manager._db
                db.remove_food_from_meal(food[0])
                logging.debug(f'Deleted {food[0,1]} from  current meal')
            self._manager._update_current_meal_menu()

        # Propagate event
        return False

    def record_meals_slider_changed(self, adj_object):
        """
        When the meal selection is changed this function selects the meal
        that is at distance n from the current meal, where n is the number
        of the steps from the center of the sliders. Then the slider is
        reset to the center
        """
        val = adj_object.get_value() - 50
        # Gets current meal
        db = self._manager._db
        selected_meal = str(db.get_meal_from_offset_rel_to_current(val))
        logging.debug(f'Current meal set to {selected_meal}')
        self._manager._rm_meal_label \
            .set_text(f'Meal {self._manager._db.current_meal_string}')
        db.current_meal = selected_meal
        adj_object.set_value(50)
        self._manager._update_current_meal_menu()

    def record_meals_set_pcf(self, cell_renderer_combo, path_string, new_iter):
        pcf_list = cell_renderer_combo.props.model
        Nutr_No = pcf_list.get_value(new_iter, 0)
        Nutrient_name = pcf_list.get_value(new_iter, 1)

        # When you edit the pcf, the gtk treeview should select only
        # the row that you're editing, so this code seems to be rialiable
        selection = self._manager._rm_menu_treeview.get_selection()
        treestore, selected_treepaths = selection.get_selected_rows()
        food = treestore[selected_treepaths[0]]

        NDB_No = food[0]
        self._manager._db.set_food_pcf(NDB_No, Nutr_No)
        logging.debug(f'Selected PCF: {NDB_No} {Nutrient_name}')
        self._manager._update_current_meal_menu()

    def analysis_meal_no_changed(self, adj_object):
        """
        When the number of meals to be analyzed is changed this function
        updates the database and the analysis view
        """
        val = adj_object.get_value()
        logging.debug(f'Number of meal to analyze set to {val}')
        self._manager._db.am_analysis_meal_no = val
        self._manager._update_am_analysis()

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
            TheStory(nutrient[0])
        else:
            logging.info(f'{nutrient} Nutrient group clicked')

    def food_clicked(self, treeview, path, view_column):
        """
        When a food nutrient is clicked this function will shown the story
        of the nutrient relative to the analysis period
        """
        data = treeview.get_model()
        tree_iter = data.get_iter(path)
        NDB_No = data.get(tree_iter, 0)[0]
        logging.debug(f'{NDB_No} Food clicked')
        ViewFood(NDB_No)

    def view_searched_food(self, widget):
        """
        When a food description is entered in the search field and the view
        button is clicked, matching foods will be viewed
        """
        long_desc = self._manager._rm_search_entry.get_text()
        logging.debug(f'Selected {long_desc}')
        for food in self._manager._db.search_food(long_desc):
            logging.debug(f'Inserted {food}')
            ViewFood(food[0])

    def add_food_to_meal(self, widget):
        """
        When a food description is entered in the search field and the add
        button is clicked, or the enter key is pressed all the
        matching foods will be added to the current meal
        """
        long_desc = self._manager._rm_search_entry.get_text()
        logging.debug(f'Selected {long_desc}')
        for food in self._manager._db.search_food(long_desc):
            logging.debug(f'Inserted {food}')
            self._manager._db.insert_food_into_meal(food[0])
        self._manager._update_current_meal_menu()

    def view_food(self, button):
        logging.debug('View food clicked')

    def set_omega6_balance(self, widget):
        logging.debug(f'Setting omega6-3 balance to')

    def set_calories_dv(self, widget):
        calories = widget.get_adjustment().get_value()
        logging.debug(f'Setting calories dv to {calories}')
        self._manager._db.set_nutrient_dv('ENERC_KCAL', calories)

    def accept_measurements(self, button):
        settings_wdgs = self._manager._settings_widgets
        self._manager._db\
            .insert_weight_log(settings_wdgs['weight_sp'].get_value(),
                               settings_wdgs['bodyfat_sp'].get_value())
        self._manager._update_GUI_settings()


class TheStoryHandler:
    def __init__(self, manager):
        self._manager = manager

    def plot_area_resize(self, widget, event):
        logging.debug(_('The story plot area resized to ({}, {})')
                      .format(1, 1))

    def start_date_selected(self, calendar):
        date = calendar.get_date()
        self._manager._start_date = f'{date[0]:02}{date[1]:02}{date[2]:02}'
        logging.debug(_('Start date set to {}')
                      .format(self._manager._start_date))
        self._manager._update_data()

    def end_date_selected(self, calendar):
        date = calendar.get_date()
        self._manager._end_date = f'{date[0]:02}{date[1]:02}{date[2]:02}'
        logging.debug(_('End date set to {}').format(self._manager._end_date))
        self._manager._update_data()

    def food_clicked(self, treeview, path, view_column):
        """
        This event is activated when a user double clicks a valid
        food in the treeview
        """
        data = treeview.get_model()
        tree_iter = data.get_iter(path)
        food_info = data.get(tree_iter, 0)
        logging.debug(f'{food_info} Food clicked')
        # Placeholder nutrient 20421 pasta
        ViewFood(20421)

    def update_data(self, *args):
        FdGrp_Cd_iter = self._manager._fd_group_cb.get_active_iter()
        FdGrp_Cd = self._manager._fd_group.get_value(FdGrp_Cd_iter, 0)

        rank_iter = self._manager._food_rank_cb.get_active_iter()
        rank = self._manager._food_rank_choices.get_value(rank_iter, 1)

        foods = self._manager._db.get_ranked_foods(self._manager._Nutr_No,
                                                   rank,
                                                   FdGrp_Cd)

        # Need to improve performance
        self._manager._story_food.clear()
        for food in foods:
            self._manager._story_food.append(food)


class GTKGui:
    def __init__(self):
        self._db = db.DBMan()
        self._ntr = self._db.defined_nutrients

        builder = Gtk.Builder()
        builder.add_from_file("GTK_gui.glade")

        self._window = builder.get_object("main_window")
        self._rm_menu = builder.get_object("rm_menu")
        self._rm_menu_treeview = builder.get_object("rm_menu_treeview")
        self._rm_anal = builder.get_object("rm_analysis")
        self._rm_search_entry = builder.get_object("rm_search_entry")
        self._am_anal = builder.get_object("am_analysis")
        self._rm_meal_label = builder.get_object("rm_selected_meal_label")
        self._pcf_choices_cb = builder.get_object("pcf_choices")

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

        self._update_GUI_settings()

        pcf_choices = [203,  # Protein
                       2000,  # Non-Fiber Carb
                       204,  # Total Fat
                       320,  # Vitamin A
                       404,  # Thiamin
                       405,  # Riboflavin
                       406,  # Niacin
                       410,  # Panto. Acid
                       415,  # Vitamin B6
                       417,  # Folate
                       418,  # Vitamin B12
                       421,  # Choline
                       401,  # Vitamin C
                       328,  # Vitamin D
                       2008,  # Vitamin E
                       430,  # Vitamin K1
                       301,  # Calcium
                       312,  # Copper
                       303,  # Iron
                       304,  # Magnesium
                       315,  # Manganese
                       305,  # Phosphorus
                       306,  # Potassium
                       317,  # Selenium
                       307,  # Sodium
                       309,  # Zinc
                       516,  # Glycine
                       319,  # Retinol
                       291  # Fiber
                       ]
        self._load_pcf_choiches(pcf_choices)
        set_cells_data_func(builder, ['rm_menu_treeview',
                                      'rm_analysis_treeview',
                                      'am_analysis_treeview']
                            )
        set_pcf_combobox_cells_data_func(builder, ['rm_menu_treeview'])
        self._update_current_meal_menu()
        self._update_am_analysis()

        self._window.show_all()
        Gtk.main()

    def _load_pcf_choiches(self, choices):
        for Nutr_No in choices:
            self._pcf_choices_cb.append((Nutr_No,
                                        _(self._db.get_nutrient_name(Nutr_No)))
                                        )

    def _update_current_meal_menu(self):
        """
        This function updates the visualization of the current menu meal, the
        database is left untouched
        """
        self._rm_menu.clear()
        for food in self._db.current_meal_menu:
            logging.debug(f'Inserting food into menu: {food}')
            meal.Food(self._rm_menu,
                      food[0],
                      self._db.get_food_nutrients(food[0]),
                      food[1],
                      food[2],
                      food[3])
        self._update_rm_analysis()

    def _update_rm_analysis(self):
        """
        This function updates the visualization of the current menu meal
        analysis, the database is left untouched
        """
        self._rm_anal.clear()
        self._rm_meal_label\
                .set_text(f'Analysis of meal: {self._db.current_meal_string}')
        meal.Analysis(self._rm_anal, None, self._db.rm_analysis_nutrients)

    def _update_am_analysis(self):
        """
        This function updates the visualization of the current period
        analysis, the database is left untouched
        """
        self._am_anal.clear()
        meal.Analysis(self._am_anal, None, self._db.am_analysis_nutrients)

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
        self._fd_group = builder.get_object("fd_group")
        self._fd_group_cb = builder.get_object("fd_group_cb")
        self._food_rank_choices = builder.get_object("food_ranking_choices")
        self._food_rank_cb = builder.get_object("food_rank_cb")
        self._story_food = builder.get_object("story_food")
        self._ts_nutrient_header = builder.get_object("ts_nutrient_header")

        builder.connect_signals(TheStoryHandler(self))

        fd_group_list = builder.get_object("fd_group")
        for food_group in self._db.food_groups:
            fd_group_list.append(food_group)

        self._window.set_title(_("The {} story")
                               .format(_(self._nutrient_name)))
        self._ts_nutrient_header.set_title(_(self._nutrient_name))

        logging.debug(_("{} story window created")
                      .format(_(self._nutrient_name)))
        self._setup_plot()
        self._update_data()
        set_cells_data_func(builder, ['story_food_view'])

        self._window.show_all()

    def _setup_plot(self):
        figure = Figure(figsize=(5, 4), dpi=100)
        ax = figure.add_subplot(111)
        ax.tick_params(axis='x', labelrotation=30)
        ax.set_autoscale_on(True)

        ax.set_ylabel(_('{} intake ({})').format(_(self._nutrient_name),
                                                 'unit'))
        ax.set_xlabel(_('Date'))
        self._plot_lines, = ax.plot_date([], [], 'o-')

        canvas = FigureCanvas(figure)  # a Gtk.DrawingArea

        self.replace_widget(self._graph_canvas, canvas)
        self._graph_canvas = canvas

        self._graph_canvas.set_size_request(400, 650)

    def _update_data(self):
        logging.debug(_("Updating story plot from {} to {}"
                        .format(self._start_date, self._end_date)))
        data = self._db.get_nutrient_story(self._Nutr_No,
                                           self._start_date,
                                           self._end_date)
        # Need to improve this code
        x_data = []
        y_data = []
        for point in data:
            x_data.append(point[0])
            y_data.append(point[1])

        logging.debug(f'Story data: {x_data} {y_data}')
        self._plot_lines.set_data(x_data,
                                  y_data)

        # REMEMBER TO RELIM THE AXES
        ax = self._plot_lines.figure.axes[0]
        ax.relim()
        ax.autoscale_view(True, True, True)
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
        self._vf_analysis = builder.get_object("vf_analysis")
        self._db = db.DBMan()

        # Must change with actual food selected
        self._food = self._db.get_food_by_NDB_No(NDB_No)
        self._window.set_title(_("Viewing {}").format(self._food[2]))
        logging.debug(_("View {} window created").format(self._food[2]))

        self._searchable_food_list = builder.get_object("search_food_list")
        for food in self._db.food_list:
            self._searchable_food_list.append(food)
        logging.debug(_("Food list loaded in view {} window")
                      .format(self._food[2]))

        set_cells_data_func(builder, ['vf_analysis_treeview'])
        meal.Analysis(self._vf_analysis,
                      None,
                      self._db.get_food_nutrients(NDB_No))
        self._window.show_all()

    def _load_food(self, NDB_No):
        raise NotImplementedError
