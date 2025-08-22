`timescale 1ns / 1ps

module channel_model_tb;
    reg clk = 0;
    reg en = 0;
    reg rstn = 0;

    // generate data through prbs->grey_code->pam_4
    // Generate random data
    wire binary_data;
    wire binary_data_valid;
    
    parameter SIGNAL_RESOLUTION = 8;
    parameter SYMBOL_SEPARATION = 48;
    parameter LLR_RESOLUTION = 5;
    
    prbs31 prbs(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .data_out(binary_data),
        .data_out_valid(binary_data_valid));
    
    // Generate grey-coded PAM-4 symbols
    wire [1:0] symbol;
    wire symbol_valid;
    
    grey_encode ge(
        .clk(clk),
        .data(binary_data),
        .en(binary_data_valid),
        .rstn(rstn),
        .symbol(symbol),
        .valid(symbol_valid));

//    // Generate voltage levels
//    wire [7:0] signal;
//    wire signal_valid;
    
//    pam_4_encode #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION), .SYMBOL_SEPARATION(SYMBOL_SEPARATION)) pe(
//        .clk(clk),
//        .rstn(rstn),
//        .symbol_in(symbol),
//	    .symbol_in_valid(symbol_valid),
//        .signal_out(signal),
//        .signal_out_valid(signal_valid));


//    reg signed [SIGNAL_RESOLUTION+1:0] channel_coefficient;
//    reg [7:0] channel_coefficient_idx;
//    wire signed [SIGNAL_RESOLUTION-1:0] ch_out;
//    wire ch_out_valid;
    
//    ISI_channel #(.PULSE_RESPONSE_LENGTH(2), .SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) channel(
//        .clk(clk),
//        .rstn(rstn),
//        .signal_in(signal),
//        .signal_in_valid(signal_valid),
        
//        .signal_out(ch_out),
//        .signal_out_valid(ch_out_valid),
//        .channel_coefficient(channel_coefficient),
//        .channel_coefficient_idx(channel_coefficient_idx));

    wire signed [SIGNAL_RESOLUTION-1:0] ch_out;
    wire ch_out_valid;
    
    ISI_channel_one_tap #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) channel(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol),
        .symbol_in_valid(symbol_valid),
        
        .signal_out(ch_out),
        .signal_out_valid(ch_out_valid));
        
    wire signed [SIGNAL_RESOLUTION-1:0] noise;
    wire noise_valid;
    
    reg [63:0] probability_in;
    reg [31:0] probability_idx;
    
    random_noise #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) r_noise(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .noise_out(noise),
        .valid(noise_valid),
        .probability_in(probability_in),
        .probability_idx(probability_idx)
        );
        
    wire signed [SIGNAL_RESOLUTION-1:0] ch_noise;
    wire ch_noise_valid;
        
    noise_adder #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) na(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .noise_in(noise),
        .noise_in_valid(noise_valid),
        .signal_in(ch_out),
        .signal_in_valid(ch_out_valid),
        //.signal_in(signal),
        //.signal_in_valid(signal_valid),
        .signal_out(ch_noise),
        .valid(ch_noise_valid)
        );
        
     wire [1:0] symbol_mlse;
     wire symbol_mlse_valid;
    
    MLSE  #(.ALPHA(0.5)) mlse (
        .clk(clk),
        .rstn(rstn),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_mlse),
        .valid(symbol_mlse_valid)
        );
        
    wire binary_data_mlse;    
    wire binary_data_mlse_valid;
    
    grey_decode gd3(
        .clk(clk),
        .symbol(symbol_mlse),
        .rstn(rstn),
        .en(symbol_mlse_valid),
        .data(binary_data_mlse),
        .valid(binary_data_mlse_valid));
        
        
    wire [31:0] total_bits_mlse;
    wire [31:0] total_bit_errors_mlse;
    
    prbs31_checker fec3(
        .clk(clk),
        .rstn(rstn),
        .data_in(binary_data_mlse),
        .data_in_valid(binary_data_mlse_valid),
        .total_bits(total_bits_mlse),
        .total_bit_errors(total_bit_errors_mlse));
    

     wire [1:0] symbol_sova;
     wire symbol_sova_valid;
     
     wire [4:0] llr_sova;
    wire llr_sova_sign;
    
    SOVA  #(.ALPHA(0.5), .TRACEBACK(20)) sova (
        .clk(clk),
        .rstn(rstn),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_sova),
        .valid(symbol_sova_valid),
        .llr(llr_sova),
        .llr_sign(llr_sova_sign)
        );
        
    wire binary_data_sova;    
    wire binary_data_sova_valid;
    
    grey_decode gd2(
        .clk(clk),
        .symbol(symbol_sova),
        .rstn(rstn),
        .en(symbol_sova_valid),
        .data(binary_data_sova),
        .valid(binary_data_sova_valid));
        
        
    wire [31:0] total_bits_sova;
    wire [31:0] total_bit_errors_sova;
    
    prbs31_checker fec2(
        .clk(clk),
        .rstn(rstn),
        .data_in(binary_data_sova),
        .data_in_valid(binary_data_sova_valid),
        .total_bits(total_bits_sova),
        .total_bit_errors(total_bit_errors_sova));
    
    wire [1:0] symbol_r;
    wire [4:0] llr;
    wire llr_sign;
    wire symbol_r_valid;
    
    soft_slicer #(.LLR_RESOLUTION(LLR_RESOLUTION),
        .SIGNAL_RESOLUTION(SIGNAL_RESOLUTION),
        .SYMBOL_SEPARATION(SYMBOL_SEPARATION)) slicer(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_r),
        .llr(llr),
        .llr_sign(llr_sign),
        .valid(symbol_r_valid)
        );
        
    wire binary_data_r;    
    wire binary_data_r_valid;
    
    grey_decode gd(
        .clk(clk),
        .symbol(symbol_r),
        .rstn(rstn),
        .en(symbol_r_valid),
        .data(binary_data_r),
        .valid(binary_data_r_valid));
        
        
    wire [31:0] total_bits;
    wire [31:0] total_bit_errors;
    
    prbs31_checker fec(
        .clk(clk),
        .rstn(rstn),
        .data_in(binary_data_r),
        .data_in_valid(binary_data_r_valid),
        .total_bits(total_bits),
        .total_bit_errors(total_bit_errors));
 
     always #10 clk = ~clk;
    
    integer i;
  
    reg [63:0] probability_mem [63:0];
    
    initial begin
        en<=0;
        rstn <= 0;
        
//        #20
//        channel_coefficient_idx <= 0;
//        channel_coefficient <=10'b0100000000;
        
//        #20
//        channel_coefficient_idx <= 1;
//        //channel_coefficient <=10'b0000011010;
//        channel_coefficient <=10'b0010000000;
            
        
        $readmemh("noise15dB.mem", probability_mem);
        
        for (i=0;i<64;i=i+1) begin
            #20
            probability_idx <= i;
            //probability_in <= probability_mem[i];
            probability_in <= 64'hffffffffffffffff;
        end
        
        #20
        probability_idx <= 32'hFFFFFFFF;

        #20 
        en<= 1;
        rstn <=1;     
    end   
        
endmodule