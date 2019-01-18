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
    def onDestroy(self, *args):
        Gtk.main_quit()

    def onButtonPressed(self, button):
        print("Hello World!")


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.DEBUG)

    dp = db.DBMan()
    dp.search_food('taco')

    builder = Gtk.Builder()
    builder.add_from_file("GTK_gui.glade")
    builder.connect_signals(Handler())

    window = builder.get_object("main_window")
    rm_menu = builder.get_object("rm_menu")
    rm_anal = builder.get_object("rm_analysis")
    am_anal = builder.get_object("am_analysis")

    ntr = dp.defined_nutrients
    meal.Food(rm_menu, ntr, None)
    meal.Analysis(rm_anal, None, ntr, None)
    meal.Analysis(am_anal, None, ntr, None)
    window.show_all()
    Gtk.main()
