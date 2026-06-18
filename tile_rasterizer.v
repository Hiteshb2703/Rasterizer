`include "params.v"

module tile_rasterizer (
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire [`COORD_BITS-1:0]  tile_ox,
    input  wire [`COORD_BITS-1:0]  tile_oy,

    input  wire [`COORD_BITS-1:0]  v0x, v0y,
    input  wire [`COORD_BITS-1:0]  v1x, v1y,
    input  wire [`COORD_BITS-1:0]  v2x, v2y,

    input  wire [`COLOR_BITS-1:0]  color_in,

    output wire pixel_valid,
    output wire [`COORD_BITS-1:0]  pixel_x,
    output wire [`COORD_BITS-1:0]  pixel_y,
    output wire [`COLOR_BITS-1:0]  pixel_color,
    output wire done
);

    localparam IDLE   = 2'd0;
    localparam LOAD   = 2'd1;
    localparam RASTER = 2'd2;
    localparam DONE_S = 2'd3;

    reg [1:0] state;

    reg [2:0] px, py;
    reg [`COORD_BITS-1:0] tile_ox_r, tile_oy_r;
    reg [`COORD_BITS-1:0] v0x_r, v0y_r;
    reg [`COORD_BITS-1:0] v1x_r, v1y_r;
    reg [`COORD_BITS-1:0] v2x_r, v2y_r;
    reg [`COLOR_BITS-1:0] color_r;

    wire signed [`COORD_BITS-1:0] abs_x = tile_ox_r + {{(`COORD_BITS-3){1'b0}}, px};
    wire signed [`COORD_BITS-1:0] abs_y = tile_oy_r + {{(`COORD_BITS-3){1'b0}}, py};

    wire inside0, inside1, inside2;
    edge_function ef0 (
        .x0(v0x_r), .y0(v0y_r),
        .x1(v1x_r), .y1(v1y_r),
        .px(abs_x),  .py(abs_y),
        .inside_flag(inside0)
    );

    edge_function ef1 (
        .x0(v1x_r), .y0(v1y_r),
        .x1(v2x_r), .y1(v2y_r),
        .px(abs_x),  .py(abs_y),
        .inside_flag(inside1)
    );

    edge_function ef2 (
        .x0(v2x_r), .y0(v2y_r),
        .x1(v0x_r), .y1(v0y_r),
        .px(abs_x),  .py(abs_y),
        .inside_flag(inside2)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tile_ox_r <= 0; 
            tile_oy_r <= 0;
            color_r   <= 0;
            px <= 0; py <= 0;
            v0x_r <= 0; v0y_r <= 0;
            v1x_r <= 0; v1y_r <= 0;
            v2x_r <= 0; v2y_r <= 0;
        end else begin
            case (state)

                IDLE: begin
                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    tile_ox_r <= tile_ox;
                    tile_oy_r <= tile_oy;
                    v0x_r <= v0x; v0y_r <= v0y;
                    v1x_r <= v1x; v1y_r <= v1y;
                    v2x_r <= v2x; v2y_r <= v2y;
                    color_r   <= color_in;
                    px <= 3'd0;
                    py <= 3'd0;
                    state <= RASTER;
                end

                RASTER: begin
                    if (px == 3'd7) begin
                        px <= 3'd0;
                        if (py == 3'd7)
                            state <= DONE_S;
                        else
                            py <= py + 3'd1;
                    end else begin
                        px <= px + 3'd1;
                    end
                end

                DONE_S: begin
                    state <= IDLE;
                end

            endcase
        end
    end

    assign pixel_valid  = (state == RASTER) && inside0 && inside1 && inside2;
    assign pixel_x      = abs_x;
    assign pixel_y      = abs_y;
    assign pixel_color  = color_r;
    assign done         = (state == DONE_S);

endmodule