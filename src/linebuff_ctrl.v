module linebuff_ctrl #(
parameter       DATA_WIDTH      =   8,
parameter       ADDR_WIDTH      =   32,
parameter       TAP_NUMS        =   3,
parameter		LINE_CNT		=   12,
parameter       REPEAT_NUN      =   2
)
(
input                                   clk,
input                                   rst_n,
input                                   ce_i,
input [DATA_WIDTH-1:0]                  data_pixel_i,
input                                   first_ln_i,
input [LINE_CNT-1:0]                    h_size_i,
input                                   rd_en_i,
output [ADDR_WIDTH-1:0]                 rd_addr_o,
input [(TAP_NUMS-1)*DATA_WIDTH-1:0]     rd_data_i,
output                                  wr_en_o,
output [ADDR_WIDTH-1:0]                 wr_addr_o,
output [(TAP_NUMS-1)*DATA_WIDTH-1:0]    wr_data_o,
output                                  output_en_o,
output [TAP_NUMS*DATA_WIDTH-1:0]        output_data_o
);

reg [LINE_CNT-1:0]                      pixel_cnt_r;
reg [LINE_CNT-1:0]                      pixel_cnt_nxt_r;
wire [LINE_CNT-1:0]                     pixel_cnt_nxt_nxt_c;

reg [DATA_WIDTH-1:0]                    data_pixel_r;
reg [TAP_NUMS*DATA_WIDTH-1:0]           prccessing_data_r;
wire [TAP_NUMS*DATA_WIDTH-1:0]          prccessing_data_nxt_c;
reg [1:0]                               ce_shift_r;//fixed me

assign pixel_cnt_nxt_nxt_c = ((rd_en_i|wr_en_o)&&(pixel_cnt_nxt_r!=(h_size_i-1'b1)))?(pixel_cnt_nxt_r+1'b1):{ADDR_WIDTH{1'b0}};

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		pixel_cnt_r <= {LINE_CNT{1'b0}};
		pixel_cnt_nxt_r <= {LINE_CNT{1'b0}};
	end
	else if(ce_i)
	begin
		pixel_cnt_nxt_r <= pixel_cnt_nxt_nxt_c;
		pixel_cnt_r <= pixel_cnt_nxt_r;
	end
end

assign prccessing_data_nxt_c=first_ln_i?{data_pixel_r,{REPEAT_NUN{data_pixel_r}}}:{data_pixel_r,rd_data_i};
always @(posedge clk or negedge rst_n) 
begin
if(!rst_n)
begin
    data_pixel_r <= {DATA_WIDTH{1'b0}};
    prccessing_data_r <= {(TAP_NUMS*DATA_WIDTH){1'b0}};
    ce_shift_r <= {2{1'b0}};
end
else if(ce_i)
begin
    data_pixel_r <= data_pixel_i;
    prccessing_data_r <= prccessing_data_nxt_c;
    ce_shift_r[0] <= ce_i;
    ce_shift_r[1] <= ce_shift_r[0];
end
end

assign rd_addr_o = pixel_cnt_nxt_nxt_c;
assign output_en_o = ce_shift_r[1]&rd_en_i&(~first_ln_i);
assign output_data_o = prccessing_data_r;
assign wr_addr_o = pixel_cnt_r;
assign wr_en_o = ce_shift_r[0];
assign wr_data_o = prccessing_data_r[TAP_NUMS*DATA_WIDTH-1:DATA_WIDTH];

endmodule