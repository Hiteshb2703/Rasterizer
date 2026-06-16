`include "params.v" 
module edge_function #(
    parameter COORD_BITS  = `COORD_BITS,   
    parameter RESULT_BITS = 35             
)(
    input  wire signed [COORD_BITS-1:0] x0, y0,  
    input  wire signed [COORD_BITS-1:0] x1, y1,  
    input  wire signed [COORD_BITS-1:0] px, py,  

    output wire signed [RESULT_BITS-1:0] result, 
    output wire inside_flag
);

wire signed [COORD_BITS:0] dx = px - x0;   
wire signed [COORD_BITS:0] dy = py - y0;   
wire signed [COORD_BITS:0] ex = x1 - x0;   
wire signed [COORD_BITS:0] ey = y1 - y0;

assign result = (dx * ey) - (dy * ex);
wire is_top  = (y0 == y1) && (x1 < x0);   
wire is_left = (y1 < y0);                  
wire is_top_left = is_top || is_left;
assign inside_flag = is_top_left ? (result <= 0) : (result < 0);

endmodule