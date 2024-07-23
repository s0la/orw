#!/usr/bin/env python

from pynput.keyboard import Key, Listener

def on_press(key):
    if key == Key.enter: return False

with Listener(on_press=on_press) as listener:
    listener.join()
