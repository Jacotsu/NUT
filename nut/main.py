#!/usr/bin/env python3
import logging
import gettext
from GTK_gui import GTKGui


_ = gettext.gettext


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.DEBUG)
    gui = GTKGui()
