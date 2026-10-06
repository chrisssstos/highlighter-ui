"""Renders HighlighterUI's industrial-look assets into HighlighterUI/textures.

Run from the repo root:  python tools/render_assets.py

- Faceplates get a fine powder-coat grain (rendered noise, softened), as a
  light/dark overlay so it sits on any Theme colour.
- Knob caps and screws are rendered like a plugin's knob sprites: lit from
  the upper left, supersampled 4x and scaled down.
Needs numpy and Pillow.
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageFilter

SRC = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = os.path.join(os.path.dirname(__file__), "..", "HighlighterUI", "textures")
LIGHT = np.array([-0.55, -0.65, 0.52])   # from the upper left, a little in front
LIGHT /= np.linalg.norm(LIGHT)


def overlay_from_scan(path, size, strength, blur=0):
    """A scan's luminance as an overlay: lighter than its mean -> white with
    alpha, darker -> black with alpha. Keeps the scan's detail, drops its colour."""
    im = Image.open(path).convert("L").resize((size, size), Image.LANCZOS)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    a = np.asarray(im, dtype=np.float32)
    d = (a - a.mean()) / (a.std() + 1e-6)
    d = np.clip(d / 2.5, -1, 1)
    alpha = (np.abs(d) * strength).astype(np.uint8)
    rgb = np.where(d[..., None] > 0, 255, 0).astype(np.uint8).repeat(3, axis=2)
    return Image.fromarray(np.dstack([rgb, alpha]), "RGBA")


def powder(n=128, strength=11):
    """A satin powder-coat: a fine, even, quiet grain, tiling."""
    rng = np.random.default_rng(5)
    a = rng.normal(0, 1, (n, n)).astype(np.float32)
    d = np.clip(a / 2.2, -1, 1)
    alpha = (np.abs(d) * strength).astype(np.uint8)
    rgb = np.where(d[..., None] > 0, 255, 0).astype(np.uint8).repeat(3, axis=2)
    return Image.fromarray(np.dstack([rgb, alpha]), "RGBA")


def grid(n):
    """Pixel-centre coordinates in -1..1 for an n x n canvas."""
    c = (np.arange(n) + 0.5) / n * 2 - 1
    return np.meshgrid(c, c)


def lit(nx, ny, nz):
    return np.clip(nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2], 0, 1)


def knob_cap(n=256, ss=4):
    """A knob without its pointer (the pointer turns, the light doesn't)."""
    N = n * ss
    x, y = grid(N)
    r = np.hypot(x, y)
    th = np.arctan2(y, x)
    rgb = np.zeros((N, N, 3), np.float32)
    alpha = np.zeros((N, N), np.float32)

    R_SKIRT, R_CHAMF, R_CAP = 0.90, 0.70, 0.62
    # drop shadow, down and right
    sh = np.hypot(x - 0.05, y - 0.08)
    shadow = np.clip((0.97 - sh) / 0.10, 0, 1) * 0.55
    # knurled skirt: dark plastic, ridges lit by which way they face
    sk = (r <= R_SKIRT) & (r > R_CHAMF)
    ridges = 64
    phase = th * ridges
    facing = np.cos(th - math.atan2(LIGHT[1], LIGHT[0]))       # 1 on the lit side
    ridge = 0.5 + 0.5 * np.cos(phase)
    side = np.sin(phase) * 0.5                                  # each ridge's flank
    sk_l = 0.16 + 0.10 * ridge + 0.10 * side * facing + 0.06 * facing
    # the skirt rolls off at its outer edge
    roll = np.clip((R_SKIRT - r) / 0.05, 0, 1)
    sk_l = sk_l * (0.55 + 0.45 * roll)
    # chamfer: a bevel facing up and out, bright upper left, dark lower right
    ch = (r <= R_CHAMF) & (r > R_CAP)
    nrm_r = 0.75
    ch_l = 0.30 + 0.85 * lit(np.cos(th) * nrm_r, np.sin(th) * nrm_r, np.sqrt(1 - nrm_r ** 2))
    # cap: spun aluminium, the cone of light running across it
    cp = r <= R_CAP
    ang = th - math.atan2(LIGHT[1], LIGHT[0])
    cone = np.abs(np.cos(ang + math.pi / 2)) ** 6                # streaks across the light
    rng = np.random.default_rng(3)
    rings = rng.normal(0, 1, 2048)
    ring_tex = np.interp(r * 2047 / R_CAP, np.arange(2048), np.convolve(rings, np.ones(5) / 5, "same"))
    cp_l = 0.47 + 0.36 * cone + 0.025 * ring_tex - 0.08 * (y * 0.5 + 0.5)
    base = np.array([0.62, 0.65, 0.64])                          # the kit's grey, as metal
    plastic = np.array([0.55, 0.57, 0.56])
    for m, l, col in ((sk, sk_l, plastic), (ch, ch_l, base), (cp, cp_l, base)):
        rgb[m] = (np.clip(l[m], 0, 1)[:, None] * col)
        alpha[m] = 1
    # a dark line where the chamfer meets the skirt, and the skirt's outer edge
    edge = (np.abs(r - R_CHAMF) < 0.012) | (np.abs(r - R_SKIRT) < 0.010)
    rgb[edge] *= 0.45
    # composite over the shadow
    a = alpha + shadow * (1 - alpha)
    out = np.zeros((N, N, 4), np.float32)
    out[..., :3] = rgb * alpha[..., None] / np.maximum(a, 1e-6)[..., None]
    out[..., 3] = a
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    return img.resize((n, n), Image.LANCZOS)


def screw(n=64, ss=4):
    """A domed Phillips head in a countersunk hole."""
    N = n * ss
    x, y = grid(N)
    r = np.hypot(x, y)
    out = np.zeros((N, N, 4), np.float32)
    hole = r <= 1.0
    out[hole, 3] = 1
    out[hole, :3] = 0.10                                          # the hole's dark ring
    head = r <= 0.82
    nz = np.sqrt(np.clip(1 - (r / 0.95) ** 2, 0, 1))              # a low dome
    l = 0.25 + 0.75 * lit(x / 0.95, y / 0.95, nz)
    col = np.array([0.66, 0.69, 0.68])
    out[head, :3] = (l[head, None] * col)
    # the cross recess: dark, its lower right lip catching light
    w = 0.075
    cross = head & (((np.abs(x) < w) & (np.abs(y) < 0.5)) | ((np.abs(y) < w) & (np.abs(x) < 0.5)))
    out[cross, :3] = 0.12
    lip = head & ~cross & ((((np.abs(x) < w + 0.05) & (np.abs(y) < 0.55)) | ((np.abs(y) < w + 0.05) & (np.abs(x) < 0.55))))
    lipl = np.where((x + y) > 0, 0.80, 0.38)
    out[lip, :3] = (lipl[lip, None] * col)
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


def vignette(n=256):
    """The dark falloff to a scope screen's edges."""
    x, y = grid(n)
    d = np.clip((np.maximum(np.abs(x), np.abs(y)) ** 3), 0, 1)
    a = (d * 150).astype(np.uint8)
    z = np.zeros_like(a)
    return Image.fromarray(np.dstack([z, z, z, a]), "RGBA")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    powder().save(os.path.join(OUT, "powder.png"))
    knob_cap().save(os.path.join(OUT, "knob.png"))
    screw().save(os.path.join(OUT, "screw.png"))
    sheen().save(os.path.join(OUT, "sheen.png"))
    vignette().save(os.path.join(OUT, "vignette.png"))
    print("rendered into", os.path.normpath(OUT))
