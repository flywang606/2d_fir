module vfilter#(
parameter       DATA_WIDTH      = 8,
parameter       TAP_NUMS        = 3,
parameter       COEFF_WIDTH     = 14
)
(
input                                   clk,
input                                   rst_n,
input									valid_i,
output									ready_o,
input [COEFF_WIDTH-1:0]                 coeff00_v_i,
input [COEFF_WIDTH-1:0]                 coeff10_v_i,
input [COEFF_WIDTH-1:0]                 coeff20_v_i,
input [TAP_NUMS*DATA_WIDTH-1:0] 		data_i,
output [DATA_WIDTH-1:0]				    center_o,
output									valid_o,
output [DATA_WIDTH-1:0]				    data_o

);

reg [DATA_WIDTH-1:0]                    center_pre_r;
reg [DATA_WIDTH-1:0]                    center_cur_r;

reg [DATA_WIDTH-1:0]                    data00_v_r;
reg [DATA_WIDTH-1:0]                    data10_v_r;
reg [DATA_WIDTH-1:0]                    data20_v_r;

reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult00_v_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult10_v_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult20_v_r;

wire [COEFF_WIDTH+DATA_WIDTH+2:0]       mult_v_nxt_c;
reg [COEFF_WIDTH+DATA_WIDTH+2:0]        mult_v_r;

reg										valid_st0_r;
reg										valid_st1_r;

reg [DATA_WIDTH-1:0]					data_out_r;

//v direction
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		valid_st0_r <= 1'b0;
		valid_st1_r <= 1'b0;
	end
	else
	begin
		valid_st0_r <= valid_i;
		valid_st1_r <= valid_st0_r;
	end
	
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        data00_v_r <= {DATA_WIDTH{1'b0}};
        data10_v_r <= {DATA_WIDTH{1'b0}};
        data20_v_r <= {DATA_WIDTH{1'b0}};
		center_pre_r <= {DATA_WIDTH{1'b0}};
		center_cur_r <= {DATA_WIDTH{1'b0}};
    end
    else if(valid_i)
    begin
        {data20_v_r,data10_v_r,data00_v_r} <= data_i;
		center_pre_r<=data10_v_r;
		center_cur_r<=center_pre_r;
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
    else if(valid_st0_r)
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
assign mult_v_nxt_c = {{2{mult00_v_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult00_v_r}+{{2{mult10_v_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult10_v_r}
                                +{{2{mult20_v_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult20_v_r};

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        mult_v_r <= {(COEFF_WIDTH+DATA_WIDTH+1){1'b0}};
    end
    else if(valid_st1_r)//fixed me
    begin
        mult_v_r <= mult_v_nxt_c;
    end
end

//round 
always @*
begin
	//negtive
	if(mult_v_r[COEFF_WIDTH+DATA_WIDTH+2-1]==1'b1)
		data_out_r = 'd0;
	else if(|mult_v_r[COEFF_WIDTH+DATA_WIDTH+2-2:COEFF_WIDTH+DATA_WIDTH-2])
		data_out_r = {DATA_WIDTH{1'b1}};
	else if(mult_v_r[COEFF_WIDTH-3]==1'b1)
		data_out_r = mult_v_r[(COEFF_WIDTH+DATA_WIDTH-2)-1:COEFF_WIDTH-2]+1'b1;
	else
		data_out_r = mult_v_r[(COEFF_WIDTH+DATA_WIDTH-2)-1:COEFF_WIDTH-2];
	
end

assign center_o = center_cur_r;
assign valid_o = valid_st1_r;
assign data_o = data_out_r;

endmodule