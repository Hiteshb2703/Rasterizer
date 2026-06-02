`include "params.v"
`timescale 1ns/1ps

module tb_tile_rasterizer;

    reg  clk, rst, start;
    reg  [`COORD_BITS-1:0] tile_ox, tile_oy;
    reg  [`COORD_BITS-1:0] v0x, v0y, v1x, v1y, v2x, v2y;
    reg  [`COLOR_BITS-1:0] color_in;

    wire pixel_valid;
    wire [`COORD_BITS-1:0]  pixel_x, pixel_y;
    wire [`COLOR_BITS-1:0]  pixel_color;
    wire done;

    tile_rasterizer dut (
        .clk(clk), .rst(rst), .start(start),
        .tile_ox(tile_ox), .tile_oy(tile_oy),
        .v0x(v0x), .v0y(v0y),
        .v1x(v1x), .v1y(v1y),
        .v2x(v2x), .v2y(v2y),
        .color_in(color_in),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .pixel_color(pixel_color),
        .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;
    reg seen [0:7][0:7];   
    integer i, j;

    always @(posedge clk) begin
        if (pixel_valid) begin
            $display("pixel_valid: (%0d, %0d) color=%0h", pixel_x, pixel_y, pixel_color);
            seen[pixel_y][pixel_x] <= 1'b1;
        end
    end
    
    reg expected [0:7][0:7];
    integer fail_count;

    initial begin
        rst = 1; start = 0;
        tile_ox = 0; tile_oy = 0;
        v0x = 0; v0y = 0;
        v1x = 7; v1y = 0;
        v2x = 0; v2y = 7;
        color_in = 8'hAB;

        for (i = 0; i < 8; i = i + 1)
            for (j = 0; j < 8; j = j + 1) begin
                seen[i][j]     = 0;
                expected[i][j] = 0;
            end

        expected[1][0]=1; expected[1][1]=1; expected[1][2]=1; expected[1][3]=1; expected[1][4]=1; expected[1][5]=1; expected[1][6]=1;
        expected[2][0]=1; expected[2][1]=1; expected[2][2]=1; expected[2][3]=1; expected[2][4]=1; expected[2][5]=1;
        expected[3][0]=1; expected[3][1]=1; expected[3][2]=1; expected[3][3]=1; expected[3][4]=1;
        expected[4][0]=1; expected[4][1]=1; expected[4][2]=1; expected[4][3]=1;
        expected[5][0]=1; expected[5][1]=1; expected[5][2]=1;
        expected[6][0]=1; expected[6][1]=1;
        expected[7][0]=1;

        @(posedge clk); @(posedge clk);
        rst = 0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        @(posedge done);
        @(posedge clk);  
        fail_count = 0;
        $display("\n--- RESULT CHECK ---");

        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (expected[i][j] && !seen[i][j]) begin
                    $display("FAIL: pixel (%0d,%0d) expected INSIDE but not seen", j, i);
                    fail_count = fail_count + 1;
                end
                if (!expected[i][j] && seen[i][j]) begin
                    $display("FAIL: pixel (%0d,%0d) fired but expected OUTSIDE", j, i);
                    fail_count = fail_count + 1;
                end
            end
        end

        if (fail_count == 0)
            $display("PASS: all pixels correct");
        else
            $display("FAIL: %0d pixel mismatches", fail_count);

        $finish;
    end

    initial begin
        $dumpfile("tb_tile_rasterizer.vcd");
        $dumpvars(0, tb_tile_rasterizer);
    end

endmodule