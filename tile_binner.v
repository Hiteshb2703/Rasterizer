`include "params.v"
module tile_binner #(
    parameter COORD_BITS = `COORD_BITS,
    parameter SCREEN_W   = `SCREEN_W,
    parameter SCREEN_H   = `SCREEN_H,
    parameter TILE_SIZE  = `TILE_SIZE,
    parameter TILE_SHIFT = 3,   
    parameter TILE_BITS  = 3          
)(
    input wire signed [COORD_BITS-1:0] V0x, V0y,
    input wire signed [COORD_BITS-1:0] V1x, V1y,
    input wire signed [COORD_BITS-1:0] V2x, V2y,

    output wire [TILE_BITS-1:0] tile_x_min, tile_x_max,
    output wire [TILE_BITS-1:0] tile_y_min, tile_y_max,
    output wire valid_out,
    output wire no_overlap
);

wire signed [COORD_BITS-1:0] min_x, min_y, max_x, max_y;

assign min_x = (V0x < V1x) ? ((V0x < V2x) ? V0x : V2x) : ((V1x < V2x) ? V1x : V2x);
assign min_y = (V0y < V1y) ? ((V0y < V2y) ? V0y : V2y) : ((V1y < V2y) ? V1y : V2y);
assign max_x = (V0x > V1x) ? ((V0x > V2x) ? V0x : V2x) : ((V1x > V2x) ? V1x : V2x);
assign max_y = (V0y > V1y) ? ((V0y > V2y) ? V0y : V2y) : ((V1y > V2y) ? V1y : V2y);

wire signed [COORD_BITS-1:0] clamped_x_min = (min_x < 0) ? 0 : ((min_x > SCREEN_W-1) ? SCREEN_W-1 : min_x);
wire signed [COORD_BITS-1:0] clamped_y_min = (min_y < 0) ? 0 : ((min_y > SCREEN_H-1) ? SCREEN_H-1 : min_y);
wire signed [COORD_BITS-1:0] clamped_x_max = (max_x < 0) ? 0 : ((max_x > SCREEN_W-1) ? SCREEN_W-1 : max_x);
wire signed [COORD_BITS-1:0] clamped_y_max = (max_y < 0) ? 0 : ((max_y > SCREEN_H-1) ? SCREEN_H-1 : max_y);

wire off_screen = (min_x >= SCREEN_W) || (min_y >= SCREEN_H) || (max_x < 0) || (max_y < 0);

assign tile_x_min = clamped_x_min[COORD_BITS-1:TILE_SHIFT];
assign tile_x_max = clamped_x_max[COORD_BITS-1:TILE_SHIFT];
assign tile_y_min = clamped_y_min[COORD_BITS-1:TILE_SHIFT];
assign tile_y_max = clamped_y_max[COORD_BITS-1:TILE_SHIFT];

assign valid_out = !off_screen;
assign no_overlap =  off_screen;

endmodule