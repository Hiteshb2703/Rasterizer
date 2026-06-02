`timescale 1ns/1ps
`include "params.v"

module edge_function_tb;

    reg signed [`COORD_BITS-1:0] px, py;   
    localparam signed [`COORD_BITS-1:0] V0X = 16'sd2,  V0Y = 16'sd2;
    localparam signed [`COORD_BITS-1:0] V1X = 16'sd8,  V1Y = 16'sd2;
    localparam signed [`COORD_BITS-1:0] V2X = 16'sd5,  V2Y = 16'sd7;

    wire signed [32:0] result_e0, result_e1, result_e2;
    wire inside_flag_e0, inside_flag_e1, inside_flag_e2;
    wire inside_triangle = inside_flag_e0 & inside_flag_e1 & inside_flag_e2;

    edge_function #(
        .COORD_BITS(`COORD_BITS),
        .RESULT_BITS(33)
    ) edge0 (
        .x0(V0X), .y0(V0Y),
        .x1(V1X), .y1(V1Y),
        .px(px),  .py(py),
        .result(result_e0),
        .inside_flag(inside_flag_e0)
    );

    edge_function #(
        .COORD_BITS(`COORD_BITS),
        .RESULT_BITS(33)
    ) edge1 (
        .x0(V1X), .y0(V1Y),
        .x1(V2X), .y1(V2Y),
        .px(px),  .py(py),
        .result(result_e1),
        .inside_flag(inside_flag_e1)
    );

    edge_function #(
        .COORD_BITS(`COORD_BITS),
        .RESULT_BITS(33)
    ) edge2 (
        .x0(V2X), .y0(V2Y),
        .x1(V0X), .y1(V0Y),
        .px(px),  .py(py),
        .result(result_e2),
        .inside_flag(inside_flag_e2)
    );

    integer pass_count, fail_count;

    task check;
        input signed [`COORD_BITS-1:0] test_px, test_py;
        input expected_inside;
        input [127:0] label;  
        begin
            px = test_px;
            py = test_py;
            #1; 

            if (inside_triangle === expected_inside) begin
                $display("PASS | %s | px=%0d py=%0d | inside=%b (expected %b) | e0=%0d e1=%0d e2=%0d",
                    label, test_px, test_py, inside_triangle, expected_inside,
                    result_e0, result_e1, result_e2);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %s | px=%0d py=%0d | inside=%b (expected %b) | e0=%0d e1=%0d e2=%0d",
                    label, test_px, test_py, inside_triangle, expected_inside,
                    result_e0, result_e1, result_e2);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=================================================");
        $display("  edge_function_tb — Triangle (2,2),(8,2),(5,7)  ");
        $display("=================================================");

        check(16'sd5, 16'sd4, 1'b1, "INSIDE center   ");
        check(16'sd5, 16'sd1, 1'b0, "OUTSIDE above   ");
        check(16'sd0, 16'sd4, 1'b0, "OUTSIDE left    ");
        check(16'sd5, 16'sd2, 1'b0, "ON top edge     ");
        check(16'sd3, 16'sd4, 1'b0, "NEAR left edge  ");
        check(16'sd2, 16'sd2, 1'b0, "AT vertex V0    ");
        check(16'sd8, 16'sd2, 1'b0, "AT vertex V1    ");
        check(16'sd5, 16'sd7, 1'b1, "AT vertex V2    ");
        check(16'sd5, 16'sd6, 1'b1, "INSIDE near tip ");
        check(-16'sd5, -16'sd5, 1'b0, "OUTSIDE neg     ");

        $display("=================================================");
        $display("  RESULTS: %0d PASSED,  %0d FAILED", pass_count, fail_count);
        $display("=================================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
            
        $finish;
    end

    initial begin
        $dumpfile("edge_function_tb.vcd");
        $dumpvars(0, edge_function_tb);
    end

endmodule