# Tile-Based Rasterizer 
A hardware level triangle rasterizer implemented in synthesizable Verilog, modelling the pipeline of a GPU's rasterization stage.
The design uses coarse tile clipping: the triangle’s bounding box is mapped to a range of 8×8 tiles, and only pixels in those tiles are evaluated. It is not a full tile-based deferred renderer. The Z-buffer and framebuffer are global 64×64 memories.

## Why Tile clipping?
A naïve rasterizer tests every screen pixel against every triangle. For a 1080p display with hundreds of triangles, this means millions of evaluations and repeated writes to the same pixel by multiple overlapping triangles, also known as Overdraw. 

Tile clipping cuts edge-function evaluations by skipping every tile outside the triangle's bounding box. Inside the box, all 64 pixels of each tile are still tested (no per-tile edge rejection yet): on the 35×35 test triangle that is 25 tiles / 1600 evaluations for 630 covered pixels. Overdraw is resolved, not reduced, by the Z-test: a farther fragment can never overwrite a nearer one regardless of draw order, but it is still rasterized.

## Synthesis & Implementation Results (Artix-7 xc7a35t)
| Resource | Used | Available | Utilization |
|-----------|-----:|----------:|------------:|
| LUTs | **477** | 20,800 | **2.29%** |
| Flip-Flops | **241** | 41,600 | **0.58%** |
| Block RAM | **2** | 50 | **4.00%** |
| DSP48E1 | **6** | 90 | **6.67%** |
| Worst Negative Slack (WNS)\* | **−0.573 ns** | — | — |
| Estimated Max Frequency (Fmax)\* | **≈94.6 MHz** | — | — |

> **Target FPGA:** Xilinx Artix-7 (xc7a35tcpg236-1)  
> **Clock Constraint:** 100 MHz (10 ns)

**Note:** The original rasterizer synthesized successfully but exceeded the target FPGA's available top-level I/O during implementation. A wrapper module was introduced to provide fixed test inputs and reduce external I/O, enabling successful timing analysis without modifying the rasterizer architecture.

\* Vivado 2026.1, post-synthesis & post-implementation, on `gpu_wrapper` with constant triangle inputs. Fmax ≈ 1 / (10 + 0.573) ns. BRAM = the 4096×16 Z-buffer only: the framebuffer's read port is unused in `gpu_top`, so its 4096×8 storage has no fanout and is optimized away (it would add one RAMB36 if scanned out). 6 DSP48E1 = 3 edge functions × 2 multipliers. LUT/FF counts are optimistic because constant vertex inputs let the binner logic fold away; DSP, BRAM and the critical path are representative.

## What it does
Given three 2D vertex coordinates and a color/depth value, the pipeline determines which pixels on a 64×64 screen
lie inside the triangle and writes them to a framebuffer, while using a Z-buffer to ensure correct depth visibility.

## pipeline
     tile_binner (bbox → tile range) → gpu_top tile-walk FSM (~5 cycles overhead per tile) → tile_rasterizer (1 pixel evaluated/cycle, 64 cycles/tile, 3× edge_function) → output_merger (3-cycle latency) ⇄ zbuffer → framebuffer
## Module Reference
    1. params.v : Global constants (screen size, tile size, bit widths)
    2. tile_binner.v : Bounding-box computation, tile index extraction
    3. tile_rasterizer.v : Pixel wise iterating FSM within tile bounds
    4.    4. edge_function.v : Signed edge equations with a consistent edge tie-break (an edge is inclusive if x1<x0 or (x1==x0 && y1<y0)); one winding order (CCW in y-up)
    5. zbuffer.v : 4096×16, initialised to 0xFFFF, synchronous read
    6. framebuffer.v : Color buffer, write on pass, hex dump on dump_en is simulation only
    7. output_merger.v : Z-test orchestration and framebuffer write control
    8. gpu_top.v : Top level integration and tile walk FSM
    9. gpu_wrapper.v : Synthesis-only wrapper with constant inputs (reduces I/O pins)
    10. final_output.py : Renders framebuffer_dump.hex as a 64×64 image

## Design Parameters
Defined in params.v. COORD_BITS and COLOR_BITS flow through the design. Screen/tile size are currently structurally fixed to 64×64 / 8×8 (6-bit addresses, 3-bit tile indices, 4096-entry memories); DEPTH_BITS and TILE_SIZE are informational. Generalizing requires deriving those widths from localparams.

## How to Run
**Requirements:** Icarus Verilog, Python 3 (numpy, matplotlib)

```bash
# Full pipeline
iverilog -g2005 -o gpu_sim.out gpu_top.v tile_binner.v tile_rasterizer.v edge_function.v zbuffer.v framebuffer.v output_merger.v tb_gpu_top.v
vvp gpu_sim.out                    # writes framebuffer_dump.hex
python final_output.py            # render image
python golden_check.py            # compare against Python golden model
gtkwave gpu_top_overlap.vcd

# Self-checking tests
iverilog -o t.out edge_function.v edge_function_tb.v && vvp t.out
iverilog -o t.out tile_binner.v tb_tile_binner.v && vvp t.out
iverilog -o t.out tile_rasterizer.v edge_function.v tb_tile_rasterizer.v && vvp t.out
iverilog -o t.out output_merger.v tb_outputmerger.v && vvp t.out
iverilog -o t.out zbuffer.v tb_zbuffer.v && vvp t.out
iverilog -o t.out framebuffer.v tb_framebuffer.v && vvp t.out
```

## Limitations
- Integer coordinates only (no sub-pixel / fractional bits).
- Depth is one constant per triangle (no per-pixel interpolation): intersecting or tilted triangles resolve incorrectly. Barycentric Z using the edge-function outputs is the planned fix.
- One winding order (CCW in y-up). Reverse-winding triangles draw nothing but still walk every bounding-box tile (no culling).
- No frame clear: Z-buffer (0xFFFF) and framebuffer (0x00) are set only by `initial` blocks (simulation / FPGA configuration). A second frame needs a clear FSM.
- Strict `<` depth test: depth 0xFFFF is never visible; equal depths keep the first-drawn triangle.
- Triangle inputs must be held stable until the tile-walk FSM returns to idle (no input latching or busy signal).
- Output-merger pipeline (3 cycles) assumes no two fragments hit the same pixel within 3 cycles; no forwarding logic.
- Single triangle per pass; fixed 64×64 screen; all 64 pixels of every bounding-box tile are evaluated (630 of 1600 on the test triangle).
- Timing not closed: WNS −0.573 ns at 100 MHz; critical path is the edge-function multiplies. Planned fix: pipeline them (or incremental edge evaluation).
- Fill-rule watertightness on shared edges is by construction (reversing an edge flips its inclusion) but not covered by an automated test.
