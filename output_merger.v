module output_merger (
    input  wire clk,
    input  wire rst,
    input  wire pixel_valid_in,
    input  wire [5:0]  pixel_x,
    input  wire [5:0]  pixel_y,
    input  wire [7:0]  pixel_color_in,
    input  wire [15:0] pixel_depth_in,

    output reg  zbuf_read_en,
    output reg  [5:0]  zbuf_read_x,
    output reg  [5:0]  zbuf_read_y,
    input  wire [15:0] zbuf_depth_out,
    output reg  zbuf_write_en,
    output reg  [5:0]  zbuf_write_x,
    output reg  [5:0]  zbuf_write_y,
    output reg  [15:0] zbuf_depth_in,

    output reg  fb_write_en,
    output reg  [5:0]  fb_write_x,
    output reg  [5:0]  fb_write_y,
    output reg  [7:0]  fb_write_color
);

    reg s1_valid;
    reg [5:0]  s1_x, s1_y;
    reg [7:0]  s1_color;
    reg [15:0] s1_depth;

    always @(posedge clk) begin
        if (rst) begin
            zbuf_read_en  <= 0;
            zbuf_write_en <= 0;
            fb_write_en   <= 0;
            s1_valid      <= 0;
        end else begin
            zbuf_write_en <= 0;
            fb_write_en   <= 0;
            zbuf_read_en <= pixel_valid_in;
            zbuf_read_x  <= pixel_x;
            zbuf_read_y  <= pixel_y;
            s1_valid     <= pixel_valid_in;
            s1_x         <= pixel_x;
            s1_y         <= pixel_y;
            s1_color     <= pixel_color_in;
            s1_depth     <= pixel_depth_in;

            if (s1_valid) begin
                if (s1_depth < zbuf_depth_out) begin
                    zbuf_write_en <= 1;
                    zbuf_write_x  <= s1_x;
                    zbuf_write_y  <= s1_y;
                    zbuf_depth_in <= s1_depth;
                    fb_write_en    <= 1;
                    fb_write_x     <= s1_x;
                    fb_write_y     <= s1_y;
                    fb_write_color <= s1_color;
                end
            end
        end
    end

endmodule