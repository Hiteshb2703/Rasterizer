`timescale 1ns/1ps

module tb_zbuffer;

reg clk;
reg read_en;
reg write_en;
reg [5:0] read_x;
reg [5:0] read_y;
reg [5:0] write_x;
reg [5:0] write_y;
reg [15:0] depth_in;
wire [15:0] depth_out;

zbuffer dut(
    .clk(clk),
    .read_en(read_en),
    .write_en(write_en),
    .read_x(read_x),
    .read_y(read_y),
    .write_x(write_x),
    .write_y(write_y),
    .depth_in(depth_in),
    .depth_out(depth_out)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    read_en = 0;
    write_en = 0;

    repeat(2) @(posedge clk);

    @(posedge clk);
    write_en = 1;
    write_x  = 6'd10;
    write_y  = 6'd20;
    depth_in = 16'h1234;

    @(posedge clk);
    write_en = 0;

    @(posedge clk);
    read_en = 1;
    read_x  = 6'd10;
    read_y  = 6'd20;
    @(posedge clk);
    read_en = 0;

    @(posedge clk);
    if(depth_out == 16'h1234)
        $display("PASS");
    else
        $display("FAIL depth=%h",depth_out);

    $finish;
end

endmodule