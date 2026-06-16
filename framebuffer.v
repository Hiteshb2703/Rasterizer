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

    always @(posedge clk) begin
        if (write_en) begin
            fb[w_addr] <= write_color;
        end

        if (read_en) begin
            read_color <= fb[r_addr];
        end

        if (dump_en) begin
            begin : dump_block
                integer fd;
                integer i;
                fd = $fopen("framebuffer_dump.hex", "w");
                for (i = 0; i < 4096; i = i + 1) begin
                    $fwrite(fd, "%02h\n", fb[i]);
                end
                $fclose(fd);
            end
        end
    end

    integer k;

    initial begin
        for (k = 0; k < 4096; k = k + 1) fb[k] = 8'h00;
    end
endmodule