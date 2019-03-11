#!/usr/bin/env python3
import logging
import gettext
from GTK_gui import GTKGui


_ = gettext.gettext


# Need to define a main function as a setup.py entrypoint
def main():
    logging.getLogger().setLevel(logging.DEBUG)
    GTKGui()


if __name__ == '__main__':
    main()
