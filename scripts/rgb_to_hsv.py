#!/usr/bin/env python

import sys

def limit_value(value, limit=255):
    if value > 0:
        if value > limit:
            limited_value = (value % limit) if limit == 360 else limit
    elif value < 0:
        limited_value = value + limit if limit == 360 else 0

    return int(round(limited_value if 'limited_value' in locals() else value))

def main():
    r, g, b = [float(v) / 255 for v in sys.argv[1].split()]

    max_v = max(r, g, b)
    min_v = min(r, g, b)
    delta = max_v - min_v

    v = max_v

    if delta == 0:
        s = h = 0
    else:
        s = delta / max_v

        if max_v == r:
            h = (g - b) / delta
        elif max_v == g:
            h = 2 + (b - r) / delta
        else:
            h = 4 + (r - g) / delta

        h *= 60
        if h < 0: h += 360

    h = limit_value(h, 360)
    s = limit_value(s * 100, 100)
    v = limit_value(v * 100, 100)

    return [h, s, v]

hsv = main()

if __name__ == "__main__":
    print('{} {} {}'.format(*hsv))
