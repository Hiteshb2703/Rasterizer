module zbuffer (
    input  wire clk,
    input  wire rst,
    input  wire read_en,
    input  wire write_en,
    input  wire [5:0]  read_x,
    input  wire [5:0]  read_y,
    input  wire [5:0]  write_x,
    input  wire [5:0]  write_y,
    input  wire [15:0] depth_in,
    output reg  [15:0] depth_out
);

    reg [15:0] zbuf [0:63][0:63];
    integer i, j;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1)
                for (j = 0; j < 64; j = j + 1)
                    zbuf[i][j] <= 16'hFFFF;
        end else begin
            if (write_en)
                zbuf[write_y][write_x] <= depth_in;

            if (read_en)
                depth_out <= zbuf[read_y][read_x];
        end
    end

endmodule