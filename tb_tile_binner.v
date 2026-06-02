`timescale 1ns/1ps

module tb_tile_binner;

    localparam COORD_BITS = 16;
    localparam SCREEN_W   = 64;
    localparam SCREEN_H   = 64;
    localparam TILE_SIZE  = 8;
    localparam TILE_BITS  = 3;

    reg  clk;
    reg  rst;
    reg  valid_in;

    reg  [COORD_BITS-1:0] v0x, v0y;
    reg  [COORD_BITS-1:0] v1x, v1y;
    reg  [COORD_BITS-1:0] v2x, v2y;

    wire [TILE_BITS-1:0]  tile_x_min;
    wire [TILE_BITS-1:0]  tile_x_max;
    wire [TILE_BITS-1:0]  tile_y_min;
    wire [TILE_BITS-1:0]  tile_y_max;

    wire valid_out;
    wire no_overlap;

    tile_binner #(
        .COORD_BITS(COORD_BITS),
        .SCREEN_W  (SCREEN_W),
        .SCREEN_H  (SCREEN_H),
        .TILE_SIZE (TILE_SIZE)
    ) dut (
        .V0x       (v0x),
        .V0y       (v0y),
        .V1x       (v1x),
        .V1y       (v1y),
        .V2x       (v2x),
        .V2y       (v2y),
        .tile_x_min(tile_x_min),
        .tile_x_max(tile_x_max),
        .tile_y_min(tile_y_min),
        .tile_y_max(tile_y_max),
        .valid_out (valid_out),
        .no_overlap(no_overlap)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_tile_binner.vcd");
        $dumpvars(0, tb_tile_binner);
    end

    integer pass_count;
    integer fail_count;
    integer test_id;

    task submit_and_check;
        input [COORD_BITS-1:0] i_v0x, i_v0y;
        input [COORD_BITS-1:0] i_v1x, i_v1y;
        input [COORD_BITS-1:0] i_v2x, i_v2y;
        input [TILE_BITS-1:0]  exp_tx_min, exp_tx_max;
        input [TILE_BITS-1:0]  exp_ty_min, exp_ty_max;
        input                  exp_no_overlap;
        begin
            v0x = i_v0x; v0y = i_v0y;
            v1x = i_v1x; v1y = i_v1y;
            v2x = i_v2x; v2y = i_v2y;

            @(posedge clk); #1;
            valid_in = 1'b1;
            @(posedge clk); #1;
            valid_in = 1'b0;

            @(posedge clk); #1;

            if (no_overlap !== exp_no_overlap) begin
                $display("FAIL [test %0d]: no_overlap = %b, expected %b",
                         test_id, no_overlap, exp_no_overlap);
                fail_count = fail_count + 1;
            end else if (exp_no_overlap) begin
                $display("PASS [test %0d]: triangle off-screen, no_overlap asserted", test_id);
                pass_count = pass_count + 1;
            end else if (tile_x_min !== exp_tx_min || tile_x_max !== exp_tx_max ||
                         tile_y_min !== exp_ty_min || tile_y_max !== exp_ty_max) begin
                $display("FAIL [test %0d]: got tx=[%0d:%0d] ty=[%0d:%0d], expected tx=[%0d:%0d] ty=[%0d:%0d]",
                         test_id,
                         tile_x_min, tile_x_max, tile_y_min, tile_y_max,
                         exp_tx_min, exp_tx_max, exp_ty_min, exp_ty_max);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [test %0d]: tx=[%0d:%0d] ty=[%0d:%0d]",
                         test_id, tile_x_min, tile_x_max, tile_y_min, tile_y_max);
                pass_count = pass_count + 1;
            end

            test_id = test_id + 1;
            @(posedge clk);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        test_id    = 1;

        rst      = 1'b1;
        valid_in = 1'b0;
        v0x = 0; v0y = 0;
        v1x = 0; v1y = 0;
        v2x = 0; v2y = 0;
        repeat(3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        submit_and_check(
            16'd0,  16'd0,
            16'd28, 16'd0,
            16'd0,  16'd28,
            3'd0, 3'd3,
            3'd0, 3'd3,
            1'b0
        );

        submit_and_check(
            16'd0,  16'd0,
            16'd63, 16'd0,
            16'd0,  16'd63,
            3'd0, 3'd7,
            3'd0, 3'd7,
            1'b0
        );

        submit_and_check(
            16'd80,  16'd80,
            16'd100, 16'd80,
            16'd80,  16'd100,
            3'd0, 3'd0,
            3'd0, 3'd0,
            1'b1
        );

        submit_and_check(
            16'd2, 16'd2,
            16'd5, 16'd2,
            16'd2, 16'd5,
            3'd0, 3'd0,
            3'd0, 3'd0,
            1'b0
        );

        $display("-------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED — check output above");
        $display("-------------------------------");

        $finish;
    end

    initial begin
        #10000;
        $display("TIMEOUT — simulation hung");
        $finish;
    end

endmodule