module framebuffer (
    input  wire clk,
    input  wire rst,
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

    reg [7:0] fb [0:63][0:63];
    integer i, j;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 64; i = i + 1)
                for (j = 0; j < 64; j = j + 1)
                    fb[i][j] <= 8'h00;
        end else begin
            if (write_en)
                fb[write_y][write_x] <= write_color;

            if (read_en)
                read_color <= fb[read_y][read_x];

            if (dump_en) begin
                begin : dump_block
                    integer fd;
                    fd = $fopen("framebuffer_dump.hex", "w");
                    for (i = 0; i < 64; i = i + 1)
                        for (j = 0; j < 64; j = j + 1)
                            $fwrite(fd, "%02h\n", fb[i][j]);
                    $fclose(fd);
                end
            end
        end
    end

endmodule