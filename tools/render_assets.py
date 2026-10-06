"""Renders HighlighterUI's classic-skin assets into HighlighterUI/textures.

Run from the repo root:  python tools/render_assets.py

- The knob is rendered like a plugin's knob sprite: lit from the upper
  left, supersampled 4x and scaled down.
Needs numpy and Pillow.
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageFilter

SRC = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = os.path.join(os.path.dirname(__file__), "..", "HighlighterUI", "textures")
LIGHT = np.array([-0.55, -0.65, 0.52])   # from the upper left, a little in front
LIGHT /= np.linalg.norm(LIGHT)


def grid(n):
    """Pixel-centre coordinates in -1..1 for an n x n canvas."""
    c = (np.arange(n) + 0.5) / n * 2 - 1
    return np.meshgrid(c, c)


def lit(nx, ny, nz):
    return np.clip(nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2], 0, 1)


def knob_glossy(n=256, ss=4):
    """The classic skin's knob: a glossy dark plastic dome with a bright rim
    and a soft highlight up and to the left, its pointer drawn by the kit."""
    N = n * ss
    x, y = grid(N)
    r = np.hypot(x, y)
    th = np.arctan2(y, x)
    R = 0.86
    sh = np.hypot(x - 0.04, y - 0.07)
    shadow = np.clip((0.95 - sh) / 0.09, 0, 1) * 0.5
    body = r <= R
    # a dome: normals tilt out towards the edge
    nz = np.sqrt(np.clip(1 - (r / (R * 1.02)) ** 2, 0, 1))
    nx, ny = x / (R * 1.02), y / (R * 1.02)
    diffuse = lit(nx, ny, nz)
    l = 0.10 + 0.32 * diffuse
    # a specular blob up and to the left
    hx, hy = x + 0.30, y + 0.36
    spec = np.exp(-(hx ** 2 + hy ** 2) / 0.06) * 0.55
    # a bright rim, strongest where it faces the light
    rim = np.clip(1 - np.abs(r - (R - 0.04)) / 0.035, 0, 1) * (0.25 + 0.45 * np.clip(-(x + y) / 1.2, 0, 1))
    l = l + spec + rim
    col = np.array([0.70, 0.78, 0.84])                          # a cool, bluish plastic
    rgb = np.zeros((N, N, 3), np.float32)
    rgb[body] = np.clip(l[body], 0, 1)[:, None] * col
    edge = body & (r > R - 0.012)
    rgb[edge] *= 0.35
    alpha = body.astype(np.float32)
    a = alpha + shadow * (1 - alpha)
    out = np.zeros((N, N, 4), np.float32)
    out[..., :3] = rgb * alpha[..., None] / np.maximum(a, 1e-6)[..., None]
    out[..., 3] = a
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    return img.resize((n, n), Image.LANCZOS)


def sheen(h=64):
    """A convex sheen for a button or a fill: light at the top, dark at the foot."""
    t = (np.arange(h) + 0.5) / h
    v = np.interp(t, [0, 0.08, 0.5, 0.92, 1], [0.55, 0.25, 0, -0.25, -0.5])
    a = (np.abs(v) * 255).astype(np.uint8)
    rgb = np.where(v > 0, 255, 0).astype(np.uint8)
    arr = np.stack([rgb, rgb, rgb, a], axis=1)[:, None, :].repeat(4, axis=1)
    return Image.fromarray(arr, "RGBA")




if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    knob_glossy().save(os.path.join(OUT, "knob_classic.png"))
    sheen().save(os.path.join(OUT, "sheen.png"))
    print("rendered into", os.path.normpath(OUT))
