# Tile-Based Rasterizer
A hardware level triangle rasterizer implemented in Verilog, modelling the pipeline of a GPU's rasterization stage.
The design uses a tile-based rendering approach, the same principle used in modern mobile GPUs to limit memory bandwidth
by restricting pixel write to localized tile regions rather than the entire framebuffer.

## What it does
Given three 2D vertex coordinates and a color/depth value, the pipeline determines which pixels on a 64×64 screen
lie inside the triangle and writes them to a framebuffer, while using a Z-buffer to ensure correct depth visibility.

## pipeline
     tile_binner → tile_rasterizer → edge_function → output_merger → framebuffer.

## Module Reference
    1. params.v : Global constants (screen size, tile size, bit widths)
    2. tile_binner.v : Bounding-box computation, tile index extraction
    3. tile_rasterizer.v : Pixel wise iterating FSM within tile bounds
    4. edge_function.v : Inside-triangle test using signed edge equations
    5. zbuffer.v : Depth buffer, read/write per pixel address
    6. framebuffer.v : Color buffer, write on pass, hex dump on dump_en
    7. output_merger.v : Z-test orchestration and framebuffer write control
    8. gpu_top.v : Top level integration module

## Design Parameters 
    1. SCREEN_W/SCREEN_H : Screen resolution in pixels
    2. TILE_SIZE : Pixels per tile side 
    3. TILE_SHIFT : used for bit-shift to get tile index
    4. COORD_BITS : Signed coordinate width
    5. DEPTH_BITS : Z-buffer depth precision
    6. COLOR_BITS : Bits per pixel

## How to Run
**Requirements:** Icarus Verilog (`iverilog`).
 
```bash
# Compile and simulate the full GPU top level testbench
iverilog -o gpu_sim.out gpu_top.v tile_binner.v tile_rasterizer.v \
         edge_function.v zbuffer.v framebuffer.v output_merger.v \
         params.v tb_gpu_top.v
vvp gpu_sim.out
 
# View framebuffer output
cat framebuffer_dump.hex
 
# View waveforms
gtkwave gpu_top.vcd
```
## Limitations
 
- **Fixed point only:** Coordinates are 16-bit integers. fractional coordinates is not supported.
- **Single triangle per rasterization pass:** Real GPU rasterizers process thousands of triangles concurrently.
- **64×64 resolution:** Framebuffer is intentionally small for simulation speed.
