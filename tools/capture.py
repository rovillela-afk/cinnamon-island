#!/usr/bin/env python3
"""Captures a piece of the real screen: capture.py X Y WIDTH HEIGHT out.png

Use this script, not gnome-screenshot, to check the glass: Cinnamon's own
capture repaints the scene off screen and shows the blur lagging behind.
"""
import sys

import gi
gi.require_version('Gdk', '3.0')
from gi.repository import Gdk

x, y, largura, altura = (int(v) for v in sys.argv[1:5])
raiz = Gdk.get_default_root_window()
Gdk.pixbuf_get_from_window(raiz, x, y, largura, altura).savev(sys.argv[5], 'png', [], [])
