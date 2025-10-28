`timescale 1ns / 1ps

module epf_tb;

    reg clk=0;
    reg en;
    reg rstn;
    
    reg precode_en = 0;
    

	wire [31:0] total_bits;
	wire [31:0] total_bit_errors;
	

    wire binary_data;
    wire binary_data_valid;
    
    prbs31  prbs (
        .clk(clk),
        .en(en),
        .rstn(rstn),
        .data_out(binary_data),
        .data_out_valid(binary_data_valid));
        
    
    wire [1:0] symbol;
    wire symbol_valid;
    
    grey_encode ge(
        .clk(clk),
        .data(binary_data),
        .en(binary_data_valid),
        .rstn(rstn),
        .symbol(symbol),
        .valid(symbol_valid));
    
    wire [1:0] symbol_precode;
    wire symbol_precode_valid;
    
    precode_tx pre_tx(
                .clk(clk),
                .rstn(rstn),
                .symbol_in(symbol),
                .en(symbol_valid),
                .mode(precode_en),
                .symbol_out(symbol_precode),
                .valid(symbol_precode_valid));
    
    wire [1:0] symbol_r_precode;
    wire symbol_r_precode_valid;

    epf_channel #(
        .RSER(64'b0000000000000010100111110001011010110001000111000110110100011110),
        .EPF(64'b0000000000000000000000000000000000000000000000000000000000000000)) channel (
        .symbol_in(symbol_precode),
        .en(symbol_precode_valid ),
        .clk(clk),
        .rstn(rstn),
        .symbol_out(symbol_r_precode),
        .valid(symbol_r_precode_valid));
        
    wire [1:0] symbol_r;
    wire symbol_r_valid;
    
    precode_rx pre_rx(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol_r_precode),
        .en(symbol_r_precode_valid),
        .mode(precode_en),
        .symbol_out(symbol_r),
        .valid(symbol_r_valid));
            
    wire binary_data_r;    
    wire binary_data_r_valid;
    
    grey_decode gd(
        .clk(clk),
        .symbol(symbol_r),
        .rstn(rstn),
        .en(symbol_r_valid),
        .data(binary_data_r),
        .valid(binary_data_r_valid));
        
        
    prbs31_checker  fec (
        .clk(clk),
        .data_in(binary_data_r),
        .data_in_valid(binary_data_r_valid),
        .rstn(rstn),
        .total_bits(total_bits),
        .total_bit_errors(total_bit_errors));
	           
    always #10 clk = ~clk;
    
    
    
    initial begin
    
        en<= 0;
        rstn<=0;
        #20
        en<=1;
        rstn <= 1;  
        
    end

endmodule
