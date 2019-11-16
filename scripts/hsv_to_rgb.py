#!/usr/bin/env python

from rgb_to_hsv import *

property, offset = [ int(sys.argv[i]) for i in range(2, len(sys.argv)) ]

limit = 360 if property == 0 else 100
hsv[property] = limit_value(hsv[property] + offset, limit)

h, s, v = hsv
s /= 100
v /= 100

i = (h / 60)
c = v * s
x = c * (1.0 - abs((i % 2) - 1))
m = v - c

section = int(i % 6)

if section == 0:
    r, g, b = c, x, 0
elif section == 1:
    r, g, b = x, c, 0
elif section == 2:
    r, g, b = 0, c, x
elif section == 3:
    r, g, b = 0, x, c
elif section == 4:
    r, g, b = x, 0, c
elif section == 5:
    r, g, b = c, 0, x

r = limit_value((r + m) * 255)
g = limit_value((g + m) * 255)
b = limit_value((b + m) * 255)

print(f'{hsv[0]} {hsv[1]} {hsv[2]}-{r} {g} {b}')
