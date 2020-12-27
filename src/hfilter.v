module hfilter #(
parameter       DATA_WIDTH      = 8,
parameter       TAP_NUMS        = 3,
parameter       COEFF_WIDTH     = 14
)
(
input                                   clk,
input                                   rst_n,
input									valid_i,
output									ready_o,
input [COEFF_WIDTH-1:0]                 coeff00_h_i,
input [COEFF_WIDTH-1:0]                 coeff01_h_i,
input [COEFF_WIDTH-1:0]                 coeff02_h_i,
input [DATA_WIDTH-1:0] 					data_i,
input [DATA_WIDTH-1:0]					center_i,
output [DATA_WIDTH-1:0]				    data_o,
output [DATA_WIDTH-1:0]					center_o,
output									valid_o
);

reg [DATA_WIDTH-1:0]                    data00_h_r;
reg [DATA_WIDTH-1:0]                    data01_h_r;
reg [DATA_WIDTH-1:0]                    data02_h_r;

reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult00_h_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult01_h_r;
reg [COEFF_WIDTH+DATA_WIDTH-1:0]        mult02_h_r;

wire [COEFF_WIDTH+DATA_WIDTH+2:0]       mult_h_nxt_c;
reg [COEFF_WIDTH+DATA_WIDTH+2:0]        mult_h_r;

reg [DATA_WIDTH-1:0]                    center_pre_r;
reg [DATA_WIDTH-1:0]                    center_cur_r;

reg										valid_st0_r;
reg										valid_st1_r;

reg [DATA_WIDTH-1:0]					data_out_r;

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
        data00_h_r <= {(DATA_WIDTH+1){1'b0}};
        data01_h_r <= {(DATA_WIDTH+1){1'b0}}; 
        data02_h_r <= {(DATA_WIDTH+1){1'b0}};
		center_pre_r <= {DATA_WIDTH{1'b0}};
		center_cur_r <= {DATA_WIDTH{1'b0}};
    end
    else if(valid_i)//fixed me
    begin
        data00_h_r <= data_i;
        data01_h_r <= data00_h_r;
        data02_h_r <= data01_h_r;
		center_pre_r <= center_i;
		center_cur_r <= center_pre_r;
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
    else if(valid_st0_r)
    begin
        mult00_h_r <= {{(COEFF_WIDTH-1){data00_h_r[DATA_WIDTH-1]}},data00_h_r}*
                        {{(DATA_WIDTH-1){coeff00_h_i[COEFF_WIDTH-1]}},coeff00_h_i};
        mult01_h_r <= {{(COEFF_WIDTH-1){data01_h_r[DATA_WIDTH-1]}},data01_h_r}*
                        {{(DATA_WIDTH-1){coeff01_h_i[COEFF_WIDTH-1]}},coeff01_h_i};
        mult02_h_r <= {{(COEFF_WIDTH-1){data02_h_r[DATA_WIDTH-1]}},data02_h_r}*
                        {{(DATA_WIDTH-1){coeff02_h_i[COEFF_WIDTH-1]}},coeff02_h_i};
    end
end

assign mult_h_nxt_c = {{2{mult00_h_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult00_h_r}+{{2{mult01_h_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult01_h_r}
                                +{{2{mult02_h_r[COEFF_WIDTH+DATA_WIDTH-1]}},mult02_h_r};

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
    begin
        mult_h_r <= {(COEFF_WIDTH+DATA_WIDTH+1){1'b0}};
    end
    else if(valid_st1_r)
    begin
        mult_h_r <= mult_h_nxt_c;
    end
end

//round 
always @(*)
begin
	//negtive
	if(mult_h_r[COEFF_WIDTH+DATA_WIDTH+2-1]==1'b1)
		data_out_r = 'd0;
	else if(|mult_h_r[COEFF_WIDTH+DATA_WIDTH+2-2:COEFF_WIDTH+DATA_WIDTH-2])
		data_out_r = {DATA_WIDTH{1'b1}};
	else if(mult_h_r[COEFF_WIDTH-3]==1'b1)
		data_out_r = mult_h_r[(COEFF_WIDTH+DATA_WIDTH-2)-1:COEFF_WIDTH-2]+1'b1;
	else
		data_out_r = mult_h_r[(COEFF_WIDTH+DATA_WIDTH-2)-1:COEFF_WIDTH-2];
	
end
assign center_o = center_cur_r;
assign valid_o = valid_st1_r;
assign data_o = data_out_r;
endmodule