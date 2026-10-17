# Golden model for the two-triangle overlap test in tb_gpu_top.v.
# Usage: run the sim (writes framebuffer_dump.hex), then: python3 golden_check.py
import numpy as np

W = H = 64
fb = np.array([int(l, 16) for l in open("framebuffer_dump.hex") if l.strip()]).reshape(H, W)

def inside(tri, px, py):
    for (a, b), (c, d) in zip(tri, tri[1:] + tri[:1]):
        ex, ey = c - a, d - b
        r = (px - a) * ey - (py - b) * ex
        inclusive = (c < a) or (c == a and d < b)   # same tie-break as edge_function.v
        if not (r <= 0 if inclusive else r < 0):
            return False
    return True

# (vertices, color, depth) in draw order -- keep in sync with tb_gpu_top.v
tris = [([(10, 10), (45, 10), (10, 45)], 0xF0, 200),
        ([(20, 20), (55, 20), (20, 55)], 0x0F, 100)]

z = np.full((H, W), 0xFFFF)
exp = np.zeros((H, W), dtype=int)
for tri, col, dep in tris:
    for y in range(H):
        for x in range(W):
            if inside(tri, x, y) and dep < z[y, x]:
                z[y, x], exp[y, x] = dep, col

bad = int((fb != exp).sum())
print(f"mismatching pixels vs golden model: {bad}")
print("PASS" if bad == 0 else "FAIL")