module zbuffer (
    input  wire clk,
    input  wire read_en,
    input  wire write_en,
    input  wire [5:0]  read_x,
    input  wire [5:0]  read_y,
    input  wire [5:0]  write_x,
    input  wire [5:0]  write_y,
    input  wire [15:0] depth_in,
    output reg  [15:0] depth_out
);

    reg [15:0] zbuf [0:4095];
    wire [11:0] write_addr = {write_y, write_x};  // In binary, multiplying by 64 is just shifting left by 6.
    wire [11:0] read_addr  = {read_y, read_x};    // So we just concatenate {y, x}.

    always @(posedge clk) begin
        if (write_en) begin
            zbuf[write_addr] <= depth_in;
        end

        if (read_en) begin
            depth_out <= zbuf[read_addr];
        end
    end

integer k;
    initial begin
        for (k = 0; k < 4096; k = k + 1) begin
            zbuf[k] = 16'hFFFF;
        end
    end
endmodule