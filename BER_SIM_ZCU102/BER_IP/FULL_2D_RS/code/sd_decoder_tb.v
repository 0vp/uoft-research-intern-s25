`timescale 1ns / 1ps

module sd_decoder_tb;
    reg clk = 0;
    
    reg en = 0;
    reg rstn = 0;
    
    parameter SIGNAL_RESOLUTION = 8;
    
    parameter SYMBOL_SEPARATION = 48;
    
    parameter LLR_RESOLUTION = 5;
    
    parameter SEED = 63'hAAAFEF0123456789;

    // Generate random data
    wire data;
    wire data_valid;
    
    prbs63_120_8 #(.SEED(SEED)) prbs (
        .clk(clk),
        .en(en),
        .rstn(rstn),
        .data(data),
        .valid(data_valid));
        
    wire data_enc;
    wire data_enc_valid;
    
    hamming_enc encoder (
        .clk(clk),
        .rstn(rstn),
        .data_in(data),
        .data_in_valid(data_valid),
        .data_out(data_enc),
        .valid(data_enc_valid));
        
    // Generate grey-coded PAM-4 symbols
    wire [1:0] symbol;
    wire symbol_valid;
    
    grey_encode ge(
        .clk(clk),
        .rstn(rstn),
        .data(data_enc),
	    .en(data_enc_valid),
        .symbol(symbol),
        .valid(symbol_valid));
        
        // Generate voltage levels
    wire [7:0] signal;
    wire signal_valid;
    
    pam_4_encode #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION), .SYMBOL_SEPARATION(SYMBOL_SEPARATION)) pe(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol),
	    .symbol_in_valid(symbol_valid),
        .signal_out(signal),
        .signal_out_valid(signal_valid));

    reg signed [SIGNAL_RESOLUTION+1:0] channel_coefficient;
    reg [7:0] channel_coefficient_idx;
    wire signed [SIGNAL_RESOLUTION-1:0] ch_out;
    wire ch_out_valid;
    
    ISI_channel #(.PULSE_RESPONSE_LENGTH(2), .SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) channel(
        .clk(clk),
        .rstn(rstn),
        .signal_in(signal),
        .signal_in_valid(signal_valid),
        
        .signal_out(ch_out),
        .signal_out_valid(ch_out_valid),
        .channel_coefficient(channel_coefficient),
        .channel_coefficient_idx(channel_coefficient_idx));
        
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
        

     wire [1:0] symbol_sova;
     wire symbol_sova_valid;
     
     wire [4:0] llr_sova;
    wire llr_sova_sign;
    
    SOVA sova (
        .clk(clk),
        .rstn(rstn),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_sova),
        .valid(symbol_sova_valid),
        .llr(llr_sova),
        .llr_sign(llr_sova_sign)
        );
    
    wire data_dec;
    wire data_dec_valid;
    
    
    SD_decoder_top #(.LLR_RESOLUTION(LLR_RESOLUTION),
        .Q(6),
        .N_TP(42)) dec(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol_sova),
        .symbol_in_valid(symbol_sova_valid),
        .llr_in(llr_sova),
        .llr_sign(llr_sova_sign),
        .data_out(data_dec),
        .valid(data_dec_valid)
        );
        	
        	
    wire [63:0] total_bits;
    wire [63:0] total_bit_errors_pre;
    wire [63:0] total_bit_errors_post;
    wire [63:0] total_frames;
    wire [63:0] total_frame_errors ;             
        
prbs63_IL_FEC_checker  #(.SEED(SEED)) fec (
    .clk(clk),
    .data(data_dec),
    .en(data_dec_valid),
    .rstn(rstn),
    .n_interleave_in(1),
    
    .total_bits(total_bits),
    .total_bit_errors_pre(total_bit_errors_pre),
    .total_bit_errors_post(total_bit_errors_post),
    .total_frames(total_frames),
    .total_frame_errors(total_frame_errors)  
    );
        
        

     always #10 clk = ~clk;
    
    integer i;
  
    reg [63:0] probability_mem [63:0];
    
    initial begin
        en<=0;
        rstn <= 0;
        
        #20
        channel_coefficient_idx <= 0;
        channel_coefficient <=10'b0100000000;
        
        #20
        channel_coefficient_idx <= 1;
        channel_coefficient <=10'b0000011010;
            
        
        $readmemh("noise15dB.mem", probability_mem);
        
        for (i=0;i<64;i=i+1) begin
            #20
            probability_idx <= i;
            probability_in <= probability_mem[i];
            //probability_in <= 64'hffffffffffffffff;
        end
        
        #20
        probability_idx <= 32'hFFFFFFFF;

        #20 
        en<= 1;
        rstn <=1;     
    end   
        
endmodule