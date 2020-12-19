module 2d_fir_top #(
parameter		DATA_WIDTH		=	8,
parameter		ADDR_WIDTH		=	32,
parameter		TAP_NUMS		= 3,
parameter		COEFF_WIDTH		= 14,
parameter		PIXEL_NUM		= 2048
)
)
(
input									clk,
input									rst_n,
input									ce_i,
input [DATA_WIDTH-1:0]					data_i,
input [COEFF_WIDTH-1:0]					coeff00_v_i;
input [COEFF_WIDTH-1:0]					coeff10_v_i;
input [COEFF_WIDTH-1:0]					coeff20_v_i;
input [COEFF_WIDTH-1:0]					coeff00_h_i;
input [COEFF_WIDTH-1:0]					coeff01_h_i;
input [COEFF_WIDTH-1:0]					coeff02_h_i;
input [PIXEL_NUM-1:0]					h_size_i,
input [PIXEL_NUM-1:0]					v_size_i
output									valid_o,
output [DATA_WIDTH-1:0]					data_o,
);

reg [PIXEL_NUM-1:0]						h_cnt_r;
wire [PIXEL_NUM-1:0]					h_cnt_nxt_c;
wire [PIXEL_NUM-1:0]					h_end_c;
reg [PIXEL_NUM-1:0]						v_cnt_r;
wire [PIXEL_NUM-1:0]					v_cnt_nxt_c;
wire [PIXEL_NUM-1:0]					v_end_c;
//wire									first_last_line_flag_c;
wire									first_ln_c;

reg [DATA_WIDTH-1:0]					data_in_r;
wire [DATA_WIDTH-1:0]					data_in_nxt_c;

reg [DATA_WIDTH-1:0]					data00_v_r;
reg [DATA_WIDTH-1:0]					data10_v_r;
reg [DATA_WIDTH-1:0]					data20_v_r;

reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult00_v_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult10_v_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult20_v_r;


wire [COEFF_WIDTH+DATA_WIDTH+2:0]		mult_v_nxt_c;
reg [COEFF_WIDTH+DATA_WIDTH+2:0]		mult_v_r;

wire [DATA_WIDTH-1:0]					data_h_nxt_in_c;
reg [DATA_WIDTH-1:0]					data00_h_r;
reg [DATA_WIDTH-1:0]					data01_h_r;
reg [DATA_WIDTH-1:0]					data02_h_r;

reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult00_h_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult01_h_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]		mult02_h_r;

wire [COEFF_WIDTH+DATA_WIDTH+2:0]		mult_h_nxt_c;
reg [COEFF_WIDTH+DATA_WIDTH+2:0]		mult_h_r;


wire [TAP_NUMS*DATA_WIDTH-1:0]			ln_data_out_c;
wire									ln_data_out_en_c;
wire									ln_rd_en_c;

wire [ADDR_WIDTH-1:0]					rd_addr_c;
wire [(TAP_NUMS-1)*DATA_WIDTH-1:0]		rd_data_c;

wire									wr_en_c;
wire [ADDR_WIDTH-1:0]					wr_addr_c;
wire [(TAP_NUMS-1)*DATA_WIDTH-1:0]		wr_data_c;

//edge repeate
//
assign h_end_c = h_size_i-1'b1;
assign pixel_cnt_nxt_c = ce_i?((pixel_cnt_r==h_end_c)?{PIXEL_NUM{1'b0}}
													:(pixel_cnt_r+1'b1)):pixel_cnt_r;
always@(posedge clk)
begin
	if(!rst)
			pixel_cnt_r <= {PIXEL_NUM{1'b0}};
	else if(ce_i)
			pixel_cnt_r <= pixel_cnt_nxt_c;
end

//fixed me -for last line
assign v_end_c = v_size_i;
assign v_cnt_nxt_c = ce_i?((v_cnt_r == v_end_c)?{PIXEL_NUM{1'b0}}
						:(pixel_cnt_r==h_end_c)?(v_cnt_r+1'b1):v_cnt_r):v_cnt_r;
always@(posedge clk)
begin
	if(!rst)
			v_cnt_r <= {PIXEL_NUM{1'b0}};
	else if(ce_i)
			v_cnt_r <= v_cnt_nxt_c;
end

assign first_ln_c = (v_cnt_r=={PIXEL_NUM{1'b0}})&ce_i;
//assign first_last_line_flag_c = ((v_cnt_r=={PIXEL_NUM{1'b0}})|(v_cnt_r == v_end_c))&ce_i;
//assign first_last_pixel_flag_c = ((pixel_cnt_r=={PIXEL_NUM{1'b0}})|(pixel_cnt_r == h_end_c))&ce_i;
assign ln_data_out_en_c = ((v_cnt_r > (TAP_NUMS-1))&ce_i;

assign data_in_nxt_c = ce_i?((v_cnt_r==v_end_c)?data20_v_r:data_i):{DATA_WIDTH{1'b0}};
always@(posedge clk)
begin
	if(!rst)
			data_in_r <= {DATA_WIDTH{1'b0}};
	else if(ce_i)
			data_in_r <= data_in_nxt_c;
end

//linebuff ctrl
linebuff_ctrl #(
.DATA_WIDTH(DATA_WIDTH),
.ADDR_WIDTH(ADDR_WIDTH),
.TAP_NUMS(TAP_NUMS)
)
linbuf_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.ce_i(ce_i),
	.data_pixel_i(data_in_r),
	.first_ln_i(first_ln_c),
	.rd_en_i(ln_rd_en_c),
	.rd_addr_o(rd_addr_c),
	.rd_data_i(rd_data_c),
	.wr_en_o(wr_en_c),
	.wr_addr_o(wr_addr_c),
	.wr_data_o(wr_data_c),
	.output_en_o(ln_data_out_en_c),//fixed me
	.output_data_o(ln_data_out_c),
);
assign ln_rd_en_c = ce_i?((v_cnt_r > (TAP_NUMS-'d2))?1'b1:1'b0):1'b0;
//assign rd_data_c[DATA_WIDTH-1:0] = !ln_rd_en_c?data_in_r:rd_data_c[DATA_WIDTH-1:0];
sram linebuf_16x2048#(

)
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

//assign ln_data_out_en_c = ((v_cnt_r > (TAP_NUMS-1))&ce_i;
//v direction
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		data00_v_r <= {DATA_WIDTH{1'b0}};
		data10_v_r <= {DATA_WIDTH{1'b0}};
		data20_v_r <= {DATA_WIDTH{1'b0}};
	end
	else if(ln_data_out_en_c)
	begin
		{data20_v_r,data10_v_r,data00_v_r} <= ln_data_out_c;
	end
end

//mul		
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		mult00_v_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
		mult10_v_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
		mult20_v_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
	end
	else if(ln_data_out_en_c)
	begin
		mult00_v_r <= {{(COEFF_WIDTH-1){data00_v_r[DATA_WIDTH-1]}},data00_v_r}*
						{{(DATA_WIDTH-1){coeff00_v_i[COEFF_WIDTH-1]}},coeff00_v_i};
		mult10_v_r <= {{(COEFF_WIDTH-1){data10_v_r[DATA_WIDTH-1]}},data10_v_r}*
						{{(DATA_WIDTH-1){coeff10_v_i[COEFF_WIDTH-1]}},coeff10_v_i};
		mult20_v_r <= {{(COEFF_WIDTH-1){data20_v_r[DATA_WIDTH-1]}},data20_v_r}*
						{{(DATA_WIDTH-1){coeff20_v_i[COEFF_WIDTH-1]}},coeff20_v_i};
	end
end
		
//	
assign mult_v_nxt_c = {2{mult00_v_r[COEFF_WIDTH+DATA_WIDTH-1]},mult00_v_r}+{2{mult10_v_r[COEFF_WIDTH+DATA_WIDTH-1]},mult10_v_r}
								+{2{mult20_v_r[COEFF_WIDTH+DATA_WIDTH-1]},mult20_v_r};

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		mult_v_r <= {(COEFF_WIDTH+DATA_WIDTH+1){1'b0}};
	end
	else if(ce_i)//fixed me
	begin
		mult_v_r <= mult_v_nxt_c;
	end
end

//fixed me max min

//h direction
assign data_h_nxt_in_c = mult_v_r[];//fixed me

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		data00_h_r <= {(DATA_WIDTH+1){1'b0}};
		data01_h_r <= {(DATA_WIDTH+1){1'b0}}; 
		data02_h_r <= {(DATA_WIDTH+1){1'b0}};
	end
	else if(ce_i)//fixed me
	begin
		data00_h_r <= data_h_nxt_in_c;
		data01_h_r <= data01_h_r;
		data02_h_r <= data01_h_r;
	end
end

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		mult00_h_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
		mult01_h_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
		mult02_h_r <= {(COEFF_WIDTH+DATA_WIDTH){1'b0}};
	end
	else if(ce_i)
	begin
		mult00_h_r <= {{(COEFF_WIDTH-1){data00_h_r[DATA_WIDTH-1]}},data00_h_r}*
						{{(DATA_WIDTH-1){coeff00_h_i[COEFF_WIDTH-1]}},coeff00_h_i};
		mult01_h_r <= {{(COEFF_WIDTH-1){data01_h_r[DATA_WIDTH-1]}},data01_h_r}*
						{{(DATA_WIDTH-1){coeff01_h_i[COEFF_WIDTH-1]}},coeff01_h_i};
		mult02_h_r <= {{(COEFF_WIDTH-1){data02_h_r[DATA_WIDTH-1]}},data02_h_r}*
						{{(DATA_WIDTH-1){coeff02_h_i[COEFF_WIDTH-1]}},coeff02_h_i};
	end
end

assign mult_h_nxt_c = {2{mult00_h_r[COEFF_WIDTH+DATA_WIDTH-1]},mult00_h_r}+{2{mult01_h_r[COEFF_WIDTH+DATA_WIDTH-1]},mult01_h_r}
								+{2{mult02_h_r[COEFF_WIDTH+DATA_WIDTH-1]},mult02_h_r};

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		mult_h_r <= {(COEFF_WIDTH+DATA_WIDTH+1){1'b0}};
	end
	else if(ce_i)//fixed me
	begin
		mult_h_r <= mult_h_nxt_c;
	end
end

//fixed me max min

assign data_o = mult_h_r[];//fixed me

endmodule