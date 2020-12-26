module two_dir_fir #(
parameter       DATA_WIDTH      = 8,
parameter       ADDR_WIDTH      = 32,
parameter       TAP_NUMS        = 3,
parameter       COEFF_WIDTH     = 14,
parameter       PIXEL_NUM       = 4096,
parameter		LINE_CNT		= 12,
parameter       REPEAT_NUN      = 2
)
(
input                                   clk,
input                                   rst_n,
input                                   ce_i,
input                                   valid_i,
output									ready_o,
input [DATA_WIDTH-1:0]                  data_i,
input [COEFF_WIDTH-1:0]                 coeff00_v_i,
input [COEFF_WIDTH-1:0]                 coeff10_v_i,
input [COEFF_WIDTH-1:0]                 coeff20_v_i,
input [COEFF_WIDTH-1:0]                 coeff00_h_i,
input [COEFF_WIDTH-1:0]                 coeff01_h_i,
input [COEFF_WIDTH-1:0]                 coeff02_h_i,
input [LINE_CNT-1:0]                    h_size_i,
input [LINE_CNT-1:0]                    v_size_i,
output                                  valid_o,
output [DATA_WIDTH-1:0]                 data_o
);

reg [LINE_CNT-1:0]                      pixel_cnt_r;
wire [LINE_CNT-1:0]                     pixel_cnt_nxt_c;
wire [LINE_CNT-1:0]                     h_end_c;
reg [LINE_CNT-1:0]                      v_cnt_r;
wire [LINE_CNT-1:0]                     v_cnt_nxt_c;
wire [LINE_CNT-1:0]                     v_end_c;
//wire                                  first_last_line_flag_c;
wire                                    first_ln_c;

reg [DATA_WIDTH-1:0]                    data_in_r;
wire [DATA_WIDTH-1:0]                   data_in_nxt_c;

wire [TAP_NUMS*DATA_WIDTH-1:0]          ln_data_out_c;
wire                                    ln_data_out_en_c;
wire                                    ln_rd_en_c;

wire [ADDR_WIDTH-1:0]                   rd_addr_c;
wire [(TAP_NUMS-1)*DATA_WIDTH-1:0]      rd_data_c;

wire                                    wr_en_c;
wire [ADDR_WIDTH-1:0]                   wr_addr_c;
wire [(TAP_NUMS-1)*DATA_WIDTH-1:0]      wr_data_c;

wire [DATA_WIDTH-1:0]                   center_v_c;
wire [DATA_WIDTH-1:0]                   center_h_c;

wire [DATA_WIDTH-1:0]                   dataout_v_c;
wire [DATA_WIDTH-1:0]                   dataout_h_c;

wire									valid_v_out_c;
wire									valid_h_out_c;

//edge repeate
//
assign h_end_c = h_size_i-1'b1;
assign pixel_cnt_nxt_c = ce_i?((pixel_cnt_r==h_end_c)?{LINE_CNT{1'b0}}
                                                    :(pixel_cnt_r+1'b1)):{LINE_CNT{1'b0}};
always@(posedge clk)
begin
    if(!rst_n)
            pixel_cnt_r <= {LINE_CNT{1'b0}};
    else if(valid_i)
            pixel_cnt_r <= pixel_cnt_nxt_c;
end

//fixed me -for last line
assign v_end_c = v_size_i-1'b1;
assign v_cnt_nxt_c = ce_i?((v_cnt_r == v_end_c)?{LINE_CNT{1'b0}}
                            :(pixel_cnt_r==h_end_c)?(v_cnt_r+1'b1):v_cnt_r):{LINE_CNT{1'b0}};
always@(posedge clk)
begin
    if(!rst_n)
            v_cnt_r <= {LINE_CNT{1'b0}};
    else if(valid_i)
            v_cnt_r <= v_cnt_nxt_c;
end

assign first_ln_c = (v_cnt_r=={LINE_CNT{1'b0}})&ce_i&valid_i;
//assign first_last_line_flag_c = ((v_cnt_r=={LINE_CNT{1'b0}})|(v_cnt_r == v_end_c))&ce_i;
//assign first_last_pixel_flag_c = ((pixel_cnt_r=={LINE_CNT{1'b0}})|(pixel_cnt_r == h_end_c))&ce_i;
//assign ln_data_out_en_c = ((v_cnt_r > (TAP_NUMS-1))&ce_i;

assign data_in_nxt_c = ce_i?((v_cnt_r==v_end_c)?ln_data_out_c[TAP_NUMS*DATA_WIDTH-1-:DATA_WIDTH]:data_i):{DATA_WIDTH{1'b0}};
always@(posedge clk)
begin
    if(!rst_n)
            data_in_r <= {DATA_WIDTH{1'b0}};
    else if(valid_i)
            data_in_r <= data_in_nxt_c;
end

//linebuff ctrl
linebuff_ctrl #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
	.LINE_CNT(LINE_CNT),
    .TAP_NUMS(TAP_NUMS)
)
linbuf_ctrl
(
    .clk(clk),
    .rst_n(rst_n),
    .ce_i(valid_i),
    .data_pixel_i(data_in_r),
    .first_ln_i(first_ln_c),
	.h_size_i(h_size_i),
    .rd_en_i(ln_rd_en_c),
    .rd_addr_o(rd_addr_c),
    .rd_data_i(rd_data_c),
    .wr_en_o(wr_en_c),
    .wr_addr_o(wr_addr_c),
    .wr_data_o(wr_data_c),
    .output_en_o(ln_data_out_en_c),//fixed me
    .output_data_o(ln_data_out_c)
);

assign ln_rd_en_c = valid_i?1'b1:1'b0;//valid_i?((v_cnt_r > (REPEAT_NUN-1'b1))?1'b1:1'b0):1'b0;

sram #(
.DATA_WIDTH((TAP_NUMS-1)*DATA_WIDTH),
.ADDR_WIDTH(ADDR_WIDTH)
)
linebuf_16x2048
(
    .wr_en(wr_en_c),
    .clk_wr(clk),
    .wr_ptr(wr_addr_c),
    .data_in(wr_data_c),
    .rd_en(ln_rd_en_c),//fixed me
    .clk_rd(clk),
    .rd_ptr(rd_addr_c),
    .data_out(rd_data_c)
);

vfilter #(
	.DATA_WIDTH(DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .TAP_NUMS(TAP_NUMS)
)
vfilter_3tap
(
	.clk(clk),
    .rst_n(rst_n),
	.valid_i(ln_data_out_en_c),
	.ready_o(),
	.coeff00_v_i(coeff00_v_i),
	.coeff10_v_i(coeff10_v_i),
	.coeff20_v_i(coeff20_v_i),
	.data_i(ln_data_out_c),
	.center_o(center_v_c),
	.valid_o(valid_v_out_c),
	.data_o(dataout_v_c)
);

hfilter  #(
	.DATA_WIDTH(DATA_WIDTH),
    .COEFF_WIDTH(COEFF_WIDTH),
    .TAP_NUMS(TAP_NUMS)
)
hfilter_3tap
(
	.clk(clk),
    .rst_n(rst_n),
	.valid_i(valid_v_out_c),
	.ready_o(),
	.coeff00_h_i(coeff00_h_i),
	.coeff01_h_i(coeff01_h_i),
	.coeff02_h_i(coeff02_h_i),
	.data_i(dataout_v_c),
	.center_i(center_v_c),
	.data_o(dataout_h_c),
	.center_o(center_h_c),
	.valid_o(valid_h_out_c)
);

//assign ln_data_out_en_c = ((v_cnt_r > (TAP_NUMS-1))&ce_i;
endmodule