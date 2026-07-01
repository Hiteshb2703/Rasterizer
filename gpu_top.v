module gpu_top (
    input  wire clk,
    input  wire rst,
    input  wire [15:0] v0x,
    input  wire [15:0] v0y,
    input  wire [15:0] v1x,
    input  wire [15:0] v1y,
    input  wire [15:0] v2x,
    input  wire [15:0] v2y,
    input  wire [7:0]  tri_color,
    input  wire [15:0] tri_depth,
    input  wire raster_start,
    input  wire dump_en,
    output wire fb_write_en_out,
    output wire [5:0] fb_write_x_out,
    output wire [5:0] fb_write_y_out,
    output wire [7:0] fb_write_color_out
);

    wire [2:0] tile_x_min;
    wire [2:0] tile_x_max;
    wire [2:0] tile_y_min;
    wire [2:0] tile_y_max;
    wire tile_valid;
    wire no_overlap;

    reg [2:0] state;
    localparam T_IDLE   = 3'd0, T_START  = 3'd1, T_WAIT   = 3'd2, T_NEXT   = 3'd3, T_DONE   = 3'd4;
    reg [2:0] curr_tile_x, curr_tile_y;
    reg rast_start_pulse;

    wire [2:0] safe_x_max = (tile_x_max > 3'd7) ? 3'd7 : tile_x_max[2:0];
    wire [2:0] safe_y_max = (tile_y_max > 3'd7) ? 3'd7 : tile_y_max[2:0];

    always @(posedge clk) begin
        if (rst) begin
            state <= T_IDLE;
            curr_tile_x <= 0;
            curr_tile_y <= 0;
            rast_start_pulse <= 0;
        end
        else begin
            rast_start_pulse <= 0; 

            case (state)
                T_IDLE: begin
                    if (raster_start) begin
                        if (tile_valid) begin 
                            curr_tile_x <= tile_x_min;
                            curr_tile_y <= tile_y_min;
                            state <= T_START;
                        end 
                        else begin
                            state <= T_DONE;
                        end
                    end
                end

                T_START: begin
                    rast_start_pulse <= 1; 
                    state <= T_WAIT;
                end

                T_WAIT: begin
                    if (raster_done) begin 
                       state <= T_NEXT;
                    end
                end

                T_NEXT: begin
                    if (curr_tile_x < safe_x_max) begin
                        curr_tile_x <= curr_tile_x + 1;
                        state <= T_START;
                    end else if (curr_tile_y < safe_y_max) begin
                        curr_tile_x <= tile_x_min;
                        curr_tile_y <= curr_tile_y + 1;
                        state <= T_START;
                    end else begin
                        state <= T_DONE;
                    end
                end

                T_DONE: begin
                    state <= T_IDLE;
                end
                default : state <= T_IDLE;
            endcase
        end
    end
    tile_binner binner (
        .V0x(v0x),
        .V0y(v0y),
        .V1x(v1x),
        .V1y(v1y),
        .V2x(v2x),
        .V2y(v2y),
        .tile_x_min(tile_x_min),
        .tile_x_max(tile_x_max),
        .tile_y_min(tile_y_min),
        .tile_y_max(tile_y_max),
        .valid_out(tile_valid),
        .no_overlap(no_overlap)
    );

    wire pixel_valid;
    wire [15:0] pixel_x;
    wire [15:0] pixel_y;
    wire [7:0] pixel_color;
    wire raster_done;

    tile_rasterizer rasterizer (
        .clk(clk),
        .rst(rst),
        .start(rast_start_pulse),
        .tile_ox({10'd0, curr_tile_x, 3'b000}),
        .tile_oy({10'd0, curr_tile_y, 3'b000}),
        .v0x(v0x),
        .v0y(v0y),
        .v1x(v1x),
        .v1y(v1y),
        .v2x(v2x),
        .v2y(v2y),
        .color_in(tri_color),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_color(pixel_color),
        .done(raster_done)
    );

    wire zbuf_read_en;
    wire [5:0] zbuf_read_x;
    wire [5:0] zbuf_read_y;
    wire zbuf_write_en;
    wire [5:0] zbuf_write_x;
    wire [5:0] zbuf_write_y;
    wire [15:0] zbuf_depth_in;
    wire [15:0] zbuf_depth_out;

    zbuffer zbuf (
        .clk(clk),
        .read_en(zbuf_read_en),
        .write_en(zbuf_write_en),
        .read_x(zbuf_read_x),
        .read_y(zbuf_read_y),
        .write_x(zbuf_write_x),
        .write_y(zbuf_write_y),
        .depth_in(zbuf_depth_in),
        .depth_out(zbuf_depth_out)
    );

    wire fb_write_en;
    wire [5:0] fb_write_x;
    wire [5:0] fb_write_y;
    wire [7:0] fb_write_color;

    output_merger merger (
        .clk(clk),
        .rst(rst),
        .pixel_valid_in(pixel_valid),
        .pixel_x(pixel_x[5:0]),
        .pixel_y(pixel_y[5:0]),
        .pixel_color_in(pixel_color),
        .pixel_depth_in(tri_depth),
        .zbuf_read_en(zbuf_read_en),
        .zbuf_read_x(zbuf_read_x),
        .zbuf_read_y(zbuf_read_y),
        .zbuf_depth_out(zbuf_depth_out),
        .zbuf_write_en(zbuf_write_en),
        .zbuf_write_x(zbuf_write_x),
        .zbuf_write_y(zbuf_write_y),
        .zbuf_depth_in(zbuf_depth_in),
        .fb_write_en(fb_write_en),
        .fb_write_x(fb_write_x),
        .fb_write_y(fb_write_y),
        .fb_write_color(fb_write_color)
    );

    framebuffer fb (
        .clk(clk),
        .write_en(fb_write_en),
        .write_x(fb_write_x),
        .write_y(fb_write_y),
        .write_color(fb_write_color),
        .read_en(1'b0),
        .read_x(6'd0),
        .read_y(6'd0),
        .read_color(),
        .dump_en(dump_en)
    );

    assign fb_write_en_out    = fb_write_en;
    assign fb_write_x_out     = fb_write_x;
    assign fb_write_y_out     = fb_write_y;
    assign fb_write_color_out = fb_write_color;
    
endmodule