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

    // small helper task: load one triangle, kick off raster_start,
    // and wait for the tile-iteration state machine to finish
    task draw_triangle;
        input [15:0] tv0x, tv0y, tv1x, tv1y, tv2x, tv2y;
        input [7:0]  tcolor;
        input [15:0] tdepth;
        begin
            v0x = tv0x; v0y = tv0y;
            v1x = tv1x; v1y = tv1y;
            v2x = tv2x; v2y = tv2y;
            tri_color = tcolor;
            tri_depth = tdepth;

            @(posedge clk);
            raster_start = 1;
            @(posedge clk);
            raster_start = 0;

            wait (dut.state == 3'd4); // T_DONE
            @(posedge clk);           // let it fall back to T_IDLE
        end
    endtask

    initial begin
        rst = 1;
        raster_start = 0;
        dump_en = 0;
        #20;
        rst = 0;
        #20;

        // Triangle A: the "back" triangle, farther away (larger depth)
        draw_triangle(16'd10, 16'd10, 16'd45, 16'd10, 16'd10, 16'd45, 8'hF0, 16'd200);

        // Triangle B: the "front" triangle, overlaps A's bottom-right
        // corner, closer to the camera (smaller depth). Because it is
        // rasterized second and has a smaller depth value, the z-buffer
        // test in output_merger.v (s2_depth < zbuf_depth_out) should
        // let it win only in the region where the two triangles overlap.
        draw_triangle(16'd20, 16'd20, 16'd55, 16'd20, 16'd20, 16'd55, 8'h0F, 16'd100);

        #50;

        @(posedge clk);
        dump_en = 1;
        @(posedge clk);
        dump_en = 0;

        $display("Image saved to framebuffer_dump.hex");
        #50;
        $finish;
    end

    initial begin
        $dumpfile("gpu_top_overlap.vcd");
        $dumpvars(0, gpu_top_tb);
    end

endmodule