module framebuffer (
    input  wire clk,
    input  wire write_en,
    input  wire [5:0] write_x,
    input  wire [5:0] write_y,
    input  wire [7:0] write_color,
    input  wire read_en,
    input  wire [5:0] read_x,
    input  wire [5:0] read_y,
    output reg  [7:0] read_color,
    input  wire dump_en
);

    reg [7:0] fb [0:4095];
    wire [11:0] w_addr = {write_y, write_x};
    wire [11:0] r_addr = {read_y, read_x};

integer i;
initial begin
    for (i = 0; i < 4096; i = i + 1) begin
        fb[i] = 8'h00; 
    end
end
    always @(posedge clk) begin
        if (write_en) fb[w_addr] <= write_color;
        if (read_en)  read_color <= fb[r_addr];
    end

`ifndef SYNTHESIS
    // dump the framebuffer to a hex file
    always @(posedge clk) begin
        if (dump_en) begin : dump_block
            integer fd;
            integer k;
            fd = $fopen("framebuffer_dump.hex", "w");
            for (k = 0; k < 4096; k = k + 1)
                $fwrite(fd, "%02h\n", fb[k]);
            $fclose(fd);
        end
    end
`endif

endmodule