`timescale 1ns/1ps

module gpu_top_tb;
    reg clk;
    reg rst;
    reg [15:0] v0x;
    reg [15:0] v0y;
    reg [15:0] v2x;
    reg [15:0] v2y;
    reg [15:0] v1x;
    reg [15:0] v1y;
    reg [7:0] tri_color;
    reg [15:0] tri_depth;
    reg raster_start;
    reg dump_en;

    gpu_top dut (
        .clk(clk),
        .rst(rst),
        .v0x(v0x),
        .v0y(v0y),
        .v2x(v2x),
        .v2y(v2y),
        .v1x(v1x),
        .v1y(v1y),
        .tri_color(tri_color),
        .tri_depth(tri_depth),
        .raster_start(raster_start),
        .dump_en(dump_en)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        rst = 1;
        raster_start = 0;
        dump_en = 0;
        #20;
        rst = 0;

        v0x = 16'd10;
        v0y = 16'd10;
        v1x = 16'd50;
        v1y = 16'd10;
        v2x = 16'd10;
        v2y = 16'd50;
        tri_color = 8'hFF;
        tri_depth = 16'd100;

        #20;
        raster_start = 1;
        #10;
        raster_start = 0;
        wait (dut.state == 3'd4);

      #200;

        @(posedge clk);
        dump_en = 1;
        @(posedge clk);
        dump_en = 0;

        $display("Image saved to framebuffer_dump.hex");
        #100;
        $finish;

    end

    initial begin
        $dumpfile("gpu_top.vcd");
        $dumpvars(0, gpu_top_tb);
    end

endmodule