module gpu_wrapper(
    input  wire clk,
    input  wire rst,
    output wire debug_done
);

    wire fb_write_en;
    wire [5:0] fb_write_x;
    wire [5:0] fb_write_y;
    wire [7:0] fb_write_color;

    reg raster_start;

    // One-cycle start pulse
    always @(posedge clk) begin
        if (rst)
            raster_start <= 1'b1;
        else
            raster_start <= 1'b0;
    end

    gpu_top DUT (

        .clk(clk),
        .rst(rst),

        .v0x(16'd10),
        .v0y(16'd10),

        .v1x(16'd50),
        .v1y(16'd10),

        .v2x(16'd20),
        .v2y(16'd40),

        .tri_color(8'hFF),
        .tri_depth(16'd100),

        .raster_start(raster_start),
        .dump_en(1'b0),

        .fb_write_en_out(fb_write_en),
        .fb_write_x_out(fb_write_x),
        .fb_write_y_out(fb_write_y),
        .fb_write_color_out(fb_write_color)
    );

    assign debug_done = fb_write_en;

endmodule