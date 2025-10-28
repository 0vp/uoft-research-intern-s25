`timescale 1ns / 1ps

module prbs_pam_4_tb;
    reg clk = 0;
    reg clk2 = 0;
    reg en = 0;
    reg rstn = 0;
    
    parameter SIGNAL_RESOLUTION = 8;
    
    parameter SYMBOL_SEPERATION = 48;
    
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
        
//    wire [1:0] symbol;
//    wire symbol_valid;
    
//    prbs31 #(.SEED(31'b1101000101011010010010100011000))prbs(
//        .clk(clk),
//        .rstn(rstn),
//        .en(en),
//        .data_out(binary_data),
//        .data_out_valid(binary_data_valid));
    
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
    wire [SIGNAL_RESOLUTION-1:0] signal;
    wire signal_valid;
    
    pam_4_encode #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION), .SYMBOL_SEPERATION(SYMBOL_SEPERATION)) pe(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol),
	    .symbol_in_valid(symbol_valid),
        .signal_out(signal),
        .signal_out_valid(signal_valid));
        
        
//    wire [SIGNAL_RESOLUTION-1:0] ch_out;
//    wire ch_out_valid;
    
//    reg [SIGNAL_RESOLUTION+1:0] channel_coefficient=0;
//    reg [7:0] channel_coefficient_idx=8'hFF;
    
//    //Pass though ISI Channel
//    ISI_channel_new #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION), .PULSE_RESPONSE_LENGTH(2)) ch(
//        .clk(clk),
//        .rstn(rstn),
//        .signal_in(signal),
//	    .signal_in_valid(signal_valid),
//        .signal_out(ch_out),
//        .signal_out_valid(ch_out_valid),
//        .channel_coefficient(channel_coefficient),
//        .channel_coefficient_idx(channel_coefficient_idx)
//        );
     
     
    
    wire signed [SIGNAL_RESOLUTION-1:0] noise;
    wire noise_valid;
    
    reg [63:0] probability;
    reg [31:0] probability_idx;
    
    random_noise #(.NOISE_RESOLUTION(SIGNAL_RESOLUTION),
        .RNG_SEED0(64'd12892204793827)) r_noise(
        .clk(clk2),
        .rstn(rstn),
        .en(en),
        .noise_out(noise),
        .valid(noise_valid),
        .probability_in(probability),
        .probability_idx(probability_idx)
        );
        
    wire signed [SIGNAL_RESOLUTION-1:0] ch_noise;
    wire ch_noise_valid;
        
    noise_adder #(.NOISE_RESOLUTION(SIGNAL_RESOLUTION)) na(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .noise_in(noise),
        .noise_in_valid(noise_valid),
        .signal_in(signal),
        .signal_in_valid(signal_valid),
        .signal_out(ch_noise),
        .valid(ch_noise_valid)
        );
        
    wire [1:0] symbol_r;
    wire [4:0] llr;
    wire llr_sign;
    wire symbol_r_valid;
    
    soft_slicer_new #(.LLR_RESOLUTION(LLR_RESOLUTION),
        .SIGNAL_RESOLUTION(SIGNAL_RESOLUTION),
        .SYMBOL_SEPERATION(SYMBOL_SEPERATION)) slicer(
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
        
    wire data_r;    
    wire data_r_valid;
    
    grey_decode gd(
        .clk(clk),
        .symbol(symbol_r),
        .rstn(rstn),
        .en(symbol_r_valid),
        .data(data_r),
        .valid(data_r_valid));
    
    wire data_r_np;    
    wire data_r_np_valid;
    
    remove_parity_bits rvp (
        .clk(clk),
        .data_in(data_r),
        .rstn(rstn),
        .data_in_valid(data_r_valid),
        .data_out(data_r_np),
        .valid(data_r_np_valid));
    
    wire [63:0] total_bits_2;
    wire [63:0] total_bit_errors_pre;
    wire [63:0] total_bit_errors_post_2;
    wire [63:0] total_frames_2;
    wire [63:0] total_frame_errors_2;
    
    prbs63_ci_IL_FEC_checker_new #(
        .SEED(SEED),
        .LATENCY(0),
        .W(1)) fec2 (
        .clk(clk),
        .data(data_r_np),
        .en(data_r_np_valid),
        .rstn(rstn),
        .total_bits(total_bits_2),
        .total_bit_errors_pre(total_bit_errors_pre),
        .total_bit_errors_post(total_bit_errors_post_2),
        .total_frames(total_frames_2),
        .total_frame_errors(total_frame_errors_2));
    
    
    wire data_dec;
    wire data_dec_valid;
    
    SD_decoder_top #(.LLR_RESOLUTION(LLR_RESOLUTION),
        .Q(6),
        .N_TP(42)) dec(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol_r),
        .symbol_in_valid(symbol_r_valid),
        .llr_in(llr),
        .llr_sign(llr_sign),
        .data_out(data_dec),
        .valid(data_dec_valid)
        );
        	               
    wire [63:0] total_bits;
    wire [63:0] total_bit_errors_post_hamming;
    wire [63:0] total_bit_errors_post_KP4;
    wire [63:0] total_frames;
    wire [63:0] total_frame_errors;
    
    prbs63_ci_IL_FEC_checker_new #(
        .SEED(SEED),
        .LATENCY(0),
        .W(1)) fec (
        .clk(clk),
        .data(data_dec),
        .en(data_dec_valid),
        .rstn(rstn),
        .total_bits(total_bits),
        .total_bit_errors_pre(total_bit_errors_post_hamming),
        .total_bit_errors_post(total_bit_errors_post_KP4),
        .total_frames(total_frames),
        .total_frame_errors(total_frame_errors));
        
    always #10 clk = ~clk;
    always #20 clk2 = ~clk2;
    
    integer i;
    reg [63:0] probability_mem [63:0];
    
    initial begin
    
        en<=0;
        rstn <= 0;
        
        $readmemh("noise15dB.mem", probability_mem);
        
        
        for (i=0;i<64;i=i+1) begin
            #40
            probability_idx <= i;
            probability <= probability_mem[i];
        end
        
        #20
        probability_idx <= 32'hFFFFFFFF;

//        #20 
        
//        #20
//        channel_coefficient_idx <= 0;
//        channel_coefficient <=10'b0100000000;
        
//        #20
//        channel_coefficient_idx <= 1;
//        channel_coefficient <=10'b1101001101;

//               #20
//        channel_coefficient_idx <= 8'hFF;

        #20 
        en<= 1;
        rstn <=1;        
        
//        #400
//        en<=0;
//        #100
//        en<=1;
        

    end
endmodule