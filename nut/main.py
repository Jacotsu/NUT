#!/usr/bin/env python3
import gi
from gi.repository import Gtk
import logging
import gettext
import meal
import db

gi.require_version('Gtk', '3.0')
_ = gettext.gettext


class Handler:
    def __init__(self, db_man):
        self._db_man = db_man

    def onDestroy(self, *args):
        Gtk.main_quit()

    def onButtonPressed(self, button):
        print("Hello World!")

    def RecordMealsSliderChanged(self, adj_object):
        val = adj_object.get_value() - 50
        # Gets current meal
        selected_meal = self._db_man.get_meal_from_offset_rel_to_current(val)
        logging.debug(f'Current meal set to {selected_meal}')
        self._db_man.current_meal = selected_meal
        adj_object.set_value(50)


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.DEBUG)

    dp = db.DBMan()

    builder = Gtk.Builder()
    builder.add_from_file("GTK_gui.glade")
    builder.connect_signals(Handler(dp))

    window = builder.get_object("main_window")
    rm_menu = builder.get_object("rm_menu")
    rm_anal = builder.get_object("rm_analysis")
    am_anal = builder.get_object("am_analysis")
    searchable_food_list = builder.get_object("search_food_list")

    import sqlite3
    for food in dp.food_list:
        try:
            searchable_food_list.append(food)
        except sqlite3.OperationalError as db_error:
            logging.error(db_error)

    ntr = dp.defined_nutrients
    meal.Food(rm_menu, ntr, None)
    meal.Analysis(rm_anal, None, ntr, None)
    meal.Analysis(am_anal, None, ntr, None)
    window.show_all()
    Gtk.main()
