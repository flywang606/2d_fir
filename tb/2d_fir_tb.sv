module two_dir_fir_tb;

logic			clk;
logic			rst_n;
logic			ce_i;
logic			valid_o;
logic [8-1:0]   data_in;
logic [8-1:0]   data_out;

initial 
begin
    clk = 1'b0;
    forever begin
        #5 clk = ~clk;
    end
end

initial 
begin
	#5 rst_n = 1'b0;
    #10 rst_n = 1'b1;
	
	repeat(64) 
	begin
      @(posedge clk);
		ce_i ='d1;
        data_in = 'd1;//(DATA_WIDTH)'($urandom_range(0,2 ** DATA_WIDTH));
    end
	//ce_i ='d0;
	
	#5000 rst_n = 1'b0;
    $stop();
end

two_dir_fir #
(
	.DATA_WIDTH('d8),
	.ADDR_WIDTH('d32),
	.TAP_NUMS(3),
	.COEFF_WIDTH(14),
	.PIXEL_NUM(1024),
	.REPEAT_NUN(2)
)
two_dir_fir_top
(
	.clk(clk),
	.rst_n(rst_n),
	.ce_i(ce_i),
	.ready_o(),
	.data_i(data_in),
	.coeff00_v_i(32'h500),
	.coeff10_v_i(32'h1000),
	.coeff20_v_i(32'h500),
	.coeff00_h_i(32'h500),
	.coeff01_h_i(32'h1000),
	.coeff02_h_i(32'h500),
	.h_size_i('d64),
	.v_size_i('d64),
	.valid_o(valid_o),
	.data_o(data_out)
);

endmodule