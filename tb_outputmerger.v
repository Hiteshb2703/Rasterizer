`timescale 1ns/1ps

module tb_output_merger;

reg clk;
reg rst;
reg pixel_valid_in;
reg [5:0] pixel_x;
reg [5:0] pixel_y;
reg [7:0] pixel_color_in;
reg [15:0] pixel_depth_in;
wire zbuf_read_en;
wire [5:0] zbuf_read_x;
wire [5:0] zbuf_read_y;
reg  [15:0] zbuf_depth_out;
wire zbuf_write_en;
wire [5:0] zbuf_write_x;
wire [5:0] zbuf_write_y;
wire [15:0] zbuf_depth_in;
wire fb_write_en;
wire [5:0] fb_write_x;
wire [5:0] fb_write_y;
wire [7:0] fb_write_color;

output_merger dut (
    .clk(clk),
    .rst(rst),
    .pixel_valid_in(pixel_valid_in),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .pixel_color_in(pixel_color_in),
    .pixel_depth_in(pixel_depth_in),
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

always #5 clk = ~clk;
reg [15:0] fake_zbuf [0:63][0:63];
integer i,j;

always @(posedge clk) begin

    if(rst) begin
        for(i=0;i<64;i=i+1)
            for(j=0;j<64;j=j+1)
                fake_zbuf[i][j] <= 16'hFFFF;

        zbuf_depth_out <= 16'hFFFF;
    end

    else begin
        if(zbuf_read_en)
            zbuf_depth_out <= fake_zbuf[zbuf_read_y][zbuf_read_x];

        if(zbuf_write_en)
            fake_zbuf[zbuf_write_y][zbuf_write_x] <= zbuf_depth_in;
    end
end

initial begin

    clk = 0;
    rst = 1;
    pixel_valid_in = 0;
    pixel_x = 0;
    pixel_y = 0;
    pixel_color_in = 0;
    pixel_depth_in = 0;
    repeat(2) @(posedge clk);
    rst = 0;

    @(posedge clk);

    pixel_valid_in <= 1;
    pixel_x <= 10;
    pixel_y <= 10;
    pixel_color_in <= 8'h11;
    pixel_depth_in <= 16'd100;

    @(posedge clk);
    pixel_valid_in <= 0;
    repeat(2) @(posedge clk);

    if(fb_write_en && zbuf_write_en)
        $display("PASS: first fragment accepted");
    else
        $display("FAIL: first fragment rejected");

    @(posedge clk);

    pixel_valid_in <= 1;
    pixel_x <= 10;
    pixel_y <= 10;
    pixel_color_in <= 8'h22;
    pixel_depth_in <= 16'd200;
    @(posedge clk);
    pixel_valid_in <= 0;

    repeat(2) @(posedge clk);

    if(!fb_write_en && !zbuf_write_en)
        $display("PASS: farther fragment rejected");
    else
        $display("FAIL: farther fragment incorrectly accepted");

    @(posedge clk);

    pixel_valid_in <= 1;
    pixel_x <= 10;
    pixel_y <= 10;
    pixel_color_in <= 8'h33;
    pixel_depth_in <= 16'd50;
    @(posedge clk);
    pixel_valid_in <= 0;
    repeat(2) @(posedge clk);

    if(fb_write_en &&
       zbuf_write_en &&
       fb_write_color == 8'h33 &&
       zbuf_depth_in == 16'd50)
        $display("PASS: closer fragment accepted");
    else
        $display("FAIL: closer fragment not accepted");

    #20;

    if(fake_zbuf[10][10] == 16'd50)
        $display("PASS: final depth = 50");
    else
        $display("FAIL: final depth = %d",fake_zbuf[10][10]);

    $finish;
end

endmodule