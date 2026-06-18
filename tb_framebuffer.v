`timescale 1ns/1ps

module tb_framebuffer;

reg clk;
reg write_en;
reg [5:0] write_x;
reg [5:0] write_y;
reg [7:0] write_color;
reg read_en;
reg [5:0] read_x;
reg [5:0] read_y;
wire [7:0] read_color;
reg dump_en;

framebuffer dut(
    .clk(clk),
    .write_en(write_en),
    .write_x(write_x),
    .write_y(write_y),
    .write_color(write_color),
    .read_en(read_en),
    .read_x(read_x),
    .read_y(read_y),
    .read_color(read_color),
    .dump_en(dump_en)
);

always #5 clk=~clk;

initial begin
    clk=0;
    write_en=0;
    read_en=0;
    dump_en=0;

    repeat(2) @(posedge clk);

    @(posedge clk);
    write_en=1;
    write_x=5;
    write_y=6;
    write_color=8'hAA;

    @(posedge clk);
    write_en=0;
    @(posedge clk);
    read_en=1;
    read_x=5;
    read_y=6;
    @(posedge clk);
    read_en=0;

    @(posedge clk);
    if(read_color==8'hAA)
        $display("PASS");
    else
        $display("FAIL");

    @(posedge clk);
    dump_en=1;
    @(posedge clk);
    dump_en=0;
    $finish;
end

endmodule