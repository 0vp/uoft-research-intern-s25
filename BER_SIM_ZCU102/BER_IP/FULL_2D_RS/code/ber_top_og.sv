`timescale 1ns/1ps

//Author: Richard Barrie

//---A---AUI1---B---PMD---C---AUI2---D---

module ber_top #(
    
    parameter SIGNAL_RESOLUTION = 8,
    parameter SYMBOL_SEPARATION = 48,
    
    //bits for llr
    parameter LLR_RESOLUTION = 5,    
    
    //number of low-reliability bits that are tested with test patterns
    parameter Q = 6,
    
    //random seeds
    parameter [63:0] RANDOM_64 [9:0] = {64'h2629488426294884, 64'h588f503226294884, 64'h2629188426294884, 64'h2645841236254785,64'h2622488426294884, 64'h588f509384294884, 64'h2629488095294884, 64'h2642931236454785,64'h2629483926294884, 64'h588f513226294884},
    
    //parameter RSER = 0,
    //parameter EPF = 0,
    parameter ALPHA = 0.5,
    //number of test patterns for chase decoder
    parameter N_TP = 42,
    
    parameter N_PCS = 1,
    //CI params
    parameter M = 10,
    parameter W = 4,
    parameter P = 3,
    parameter D = 192,
    
    parameter LATENCY=46080)(
    
    input wire clk,
    input wire en,
    input wire rstn,
    
    //enable 1/(1+D) precoding for PMD link
    input wire precode_en,
        
    //enable inner hamming(120,128,1) FEC
    //input wire ifec_en,
    
    //amount of RS FEC symbol IL
    //input wire [3:0] n_interleave,
    
    //for loading markov model probabilities during reset
    input wire [63:0] probability_in,
    input wire [31:0] probability_idx,
       
	output wire [63:0] total_bits,
	output wire [63:0] total_bit_errors_pre,
	output wire [63:0] total_bit_errors_post,
	output wire [63:0] total_frames,
	output wire [63:0] total_frame_errors);
	
    //parameter [63:0] RANDOM_64 [3:0] = {64'h2629488426294884, 64'h588f503226294884, 64'h2629488426294884, 64'h2645841236454785};
    
    wire binary_data;
    wire binary_data_valid;
    
    prbs63_120_8 #(
        .SEED(RANDOM_64[0])) prbs (
        .clk(clk),
        .en(en),
        .rstn(rstn),
        .data(binary_data),
        .valid(binary_data_valid));
        
    wire [1:0] symbol_A;
    wire symbol_A_valid;
    
    grey_encode ge1(
        .clk(clk),
        .data(binary_data),
        .en(binary_data_valid),
        .rstn(rstn),
        .symbol(symbol_A),
        .valid(symbol_A_valid));
    
    wire [1:0] symbol_A_precode;
    wire symbol_A_precode_valid;
    
    precode_tx pre_tx1(
                .clk(clk),
                .rstn(rstn),
                .symbol_in(symbol_A),
                .en(symbol_A_valid),
                .mode(precode_en),
                .symbol_out(symbol_A_precode),
                .valid(symbol_A_precode_valid));
    
    wire [1:0] symbol_B_precode;
    wire symbol_B_precode_valid;

    epf_channel #(
        .RNG_SEED0(RANDOM_64[1]),
        .RNG_SEED1(RANDOM_64[2]),
        .RNG_SEED2(RANDOM_64[3]),
        .RSER(64'b0000000000000010100111110001011010110001000111000110110100011110)) channel1 (
        .symbol_in(symbol_A_precode),
        .en(symbol_A_precode_valid ),
        .clk(clk),
        .rstn(rstn),
        .epf_en(precode_en),
        .symbol_out(symbol_B_precode),
        .valid(symbol_B_precode_valid));
        
    wire [1:0] symbol_B;
    wire symbol_B_valid;
    
    precode_rx pre_rx1(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol_B_precode),
        .en(symbol_B_precode_valid),
        .mode(precode_en),
        .symbol_out(symbol_B),
        .valid(symbol_B_valid));
            
    wire binary_data_B;    
    wire binary_data_B_valid;
    
    grey_decode gd1(
        .clk(clk),
        .symbol(symbol_B),
        .rstn(rstn),
        .en(symbol_B_valid),
        .data(binary_data_B),
        .valid(binary_data_B_valid));
        
    wire binary_data_conv;
    wire binary_data_conv_valid;
        
    convolutional_interleaver #(
        .P(P),
        .D(D),
        .W(W),
        .M(10),
        .N_PCS(1)) ci (
        .clk(clk),
        .rstn(rstn),
        .data_in(binary_data_B),
        .en(binary_data_B_valid),
        .data_out(binary_data_conv),
        .valid(binary_data_conv_valid));
        
        
    wire binary_data_enc;
    wire binary_data_enc_valid;
    
    hamming_enc encoder (
            .clk(clk),
            .rstn(rstn),
            .data_in(binary_data_conv),
            .data_in_valid(binary_data_conv_valid),
            .data_out(binary_data_enc),
            .valid(binary_data_enc_valid));
    
    wire [1:0] symbol;
    wire symbol_valid;
    
    grey_encode ge(
        .clk(clk),
        .data(binary_data_enc),
        .en(binary_data_enc_valid),
        .rstn(rstn),
        .symbol(symbol),
        .valid(symbol_valid));
    
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
    
    random_noise #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION),
        .RNG_SEED0(RANDOM_64[4]),
        .RNG_SEED1(RANDOM_64[5]),
        .RNG_SEED2(RANDOM_64[6])) r_noise(
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
        .signal_out(ch_noise),
        .valid(ch_noise_valid)
        );
    // Generate voltage levels
//    wire [SIGNAL_RESOLUTION-1:0] signal;
//    wire signal_valid;
    
//    pam_4_encode #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION), .SYMBOL_SEPARATION(SYMBOL_SEPARATION)) pe(
//        .clk(clk),
//        .rstn(rstn),
//        .symbol_in(symbol),
//	    .symbol_in_valid(symbol_valid),
//        .signal_out(signal),
//        .signal_out_valid(signal_valid));
        
    
//    wire signed [SIGNAL_RESOLUTION-1:0] noise;
//    wire noise_valid;
    
//    reg [63:0] probability;
//    reg [31:0] probability_idx;
    
//    random_noise #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION),
//        .RNG_SEED0(RANDOM_64[4]),
//        .RNG_SEED1(RANDOM_64[5]),
//        .RNG_SEED2(RANDOM_64[6])) r_noise(
//        .clk(clk),
//        .rstn(rstn),
//        .en(en),
//        .noise_out(noise),
//        .valid(noise_valid),
//        .probability_in(probability_in),
//        .probability_idx(probability_idx)
//        );
        
//    wire signed [SIGNAL_RESOLUTION-1:0] ch_noise;
//    wire ch_noise_valid;
        
//    noise_adder #(.SIGNAL_RESOLUTION(SIGNAL_RESOLUTION)) na(
//        .clk(clk),
//        .rstn(rstn),
//        .en(en),
//        .noise_in(noise),
//        .noise_in_valid(noise_valid),
//        .signal_in(signal),
//        .signal_in_valid(signal_valid),
//        .signal_out(ch_noise),
//        .valid(ch_noise_valid)
//        );
        
    wire [1:0] symbol_r;
    wire [4:0] llr;
    wire llr_sign;
    wire symbol_r_valid;
    
//    soft_slicer #(.LLR_RESOLUTION(LLR_RESOLUTION),
//        .SIGNAL_RESOLUTION(SIGNAL_RESOLUTION),
//        .SYMBOL_SEPARATION(SYMBOL_SEPARATION)) slicer(
//        .clk(clk),
//        .rstn(rstn),
//        .en(en),
//        .signal_in(ch_noise),
//        .signal_in_valid(ch_noise_valid),
//        .symbol_out(symbol_r),
//        .llr(llr),
//        .llr_sign(llr_sign),
//        .valid(symbol_r_valid)
//        );
   SOVA  #(.ALPHA(ALPHA), .TRACEBACK(10)) sova (
        .clk(clk),
        .rstn(rstn),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_r),
        .valid(symbol_r_valid),
        .llr(llr),
        .llr_sign(llr_sign)
        );
        
 
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
        	
    wire data_deconv;
    wire data_deconv_valid;
    
    convolutional_deinterleaver #(
        .P(P),
        .D(D),
        .W(W),
        .M(M),
        .N_PCS(N_PCS)) cdi (
        .clk(clk),
        .rstn(rstn),
        .data_in(data_dec),
        .en(data_dec_valid),
        .data_out(data_deconv),
        .valid(data_deconv_valid));
        
     wire [1:0] symbol_C;
    wire symbol_C_valid;
    
    grey_encode ge2(
        .clk(clk),
        .data(data_deconv),
        .en(data_deconv_valid),
        .rstn(rstn),
        .symbol(symbol_C),
        .valid(symbol_C_valid));
    
    wire [1:0] symbol_C_precode;
    wire symbol_C_precode_valid;
    
    precode_tx pre_tx2(
                .clk(clk),
                .rstn(rstn),
                .symbol_in(symbol_C),
                .en(symbol_C_valid),
                .mode(precode_en),
                .symbol_out(symbol_C_precode),
                .valid(symbol_C_precode_valid));
    
    wire [1:0] symbol_D_precode;
    wire symbol_D_precode_valid;

    epf_channel #(
        .RNG_SEED0(RANDOM_64[7]),
        .RNG_SEED1(RANDOM_64[8]),
        .RNG_SEED2(RANDOM_64[9]),
        .RSER(64'b0000000000000010100111110001011010110001000111000110110100011110)) channel3 (
        .symbol_in(symbol_C_precode),
        .en(symbol_C_precode_valid ),
        .clk(clk),
        .rstn(rstn),
        .epf_en(precode_en),
        .symbol_out(symbol_D_precode),
        .valid(symbol_D_precode_valid));
        
    wire [1:0] symbol_D;
    wire symbol_D_valid;
    
    precode_rx pre_rx2(
        .clk(clk),
        .rstn(rstn),
        .symbol_in(symbol_D_precode),
        .en(symbol_D_precode_valid),
        .mode(precode_en),
        .symbol_out(symbol_D),
        .valid(symbol_D_valid));
            
    wire binary_data_D;    
    wire binary_data_D_valid;
    
    grey_decode gd2(
        .clk(clk),
        .symbol(symbol_D),
        .rstn(rstn),
        .en(symbol_D_valid),
        .data(binary_data_D),
        .valid(binary_data_D_valid));
                
    prbs63_ci_IL_FEC_checker #(
        .SEED(RANDOM_64[0]),
        .W(W),
        .LATENCY(LATENCY)) fec (
        .clk(clk),
        .data(binary_data_D),
        .en(binary_data_D_valid),
        .rstn(rstn),
        //.n_interleave_in(n_interleave),
        .total_bits(total_bits),
        .total_bit_errors_post(total_bit_errors_post),
        .total_bit_errors_pre(total_bit_errors_pre),
        .total_frames(total_frames),
        .total_frame_errors(total_frame_errors));
		
endmodule




module parallel_ber_top #(

    //ncores should be at most 50
    parameter N_CORES =  10)
    
    (input wire clk,
    input wire en,
    input wire rstn,
    
    input wire precode_en,
    //input wire [3:0] n_interleave,
   // input wire ifec_en,
    
    //for loading markov model probabilities during reset
    input wire [63:0] probability_in,
    input wire [31:0] probability_idx,
    
	output wire [63:0] total_bits,
	output wire [63:0] total_bit_errors_pre,
	output wire [63:0] total_bit_errors_post,
	output wire [63:0] total_frames,
	output wire [63:0] total_frame_errors);
	
	//random seed values
    parameter [63:0] RANDOM_64 [512*4-1:0] = {...};
    //parameter [31:0] RANDOM_32 [256*9-1:0] = {...};
    
    wire [63:0] bits [N_CORES-1:0];
	wire [63:0] bit_errors_pre[N_CORES-1:0];
	wire [63:0] bit_errors_post[N_CORES-1:0];
	wire [63:0] frames[N_CORES-1:0];
	wire [63:0] frame_errors[N_CORES-1:0];
    
    genvar i;
    
    generate
        for (i=0; i < N_CORES; i=i+1) begin
            ber_top #(
                .RANDOM_64(RANDOM_64[(i+1)*10-1:i*10])
                ) core (
                .clk(clk),
                .rstn(rstn),
                .en(en),
                .probability_in(probability_in),
                .probability_idx(probability_idx),
                .precode_en(precode_en),
                //.n_interleave(n_interleave),
                //.ifec_en(ifec_en),
               .total_bits(bits[i]),
               .total_bit_errors_pre(bit_errors_pre[i]),
               .total_bit_errors_post(bit_errors_post[i]),
               .total_frames(frames[i]),
               .total_frame_errors(frame_errors[i]));
        end
    endgenerate 
    
    
    // below is to sum all bits and bit errors across cores
    wire [63:0] bits_summation [N_CORES-1 : 0];
    wire [63:0] bit_errors_pre_summation [N_CORES-1 : 0];
    wire [63:0] bit_errors_post_summation [N_CORES-1 : 0];
    wire [63:0] frames_summation [N_CORES-1 : 0];
    wire [63:0] frame_errors_summation [N_CORES-1 : 0];
    
    generate
        
        for(i=0; i<N_CORES; i=i+1) begin
        
            if (i == 0) begin
                assign bits_summation[0] = bits[0];
                assign bit_errors_pre_summation[0] = bit_errors_pre[0];
                assign bit_errors_post_summation[0] = bit_errors_post[0];
                assign frames_summation[0] = frames[0];
                assign frame_errors_summation[0] = frame_errors[0];

                
            end else begin
                assign bits_summation[i] = bits_summation[i-1] + bits[i];
                assign bit_errors_pre_summation[i] = bit_errors_pre_summation[i-1] + bit_errors_pre[i];
                assign bit_errors_post_summation[i] = bit_errors_post_summation[i-1] + bit_errors_post[i];
                assign frames_summation[i] = frames_summation[i-1] + frames[i];
                assign frame_errors_summation[i] = frame_errors_summation[i-1] + frame_errors[i];

            end
        end
    endgenerate
    
    assign total_bits = bits_summation[N_CORES-1];
    assign total_bit_errors_pre = bit_errors_pre_summation[N_CORES-1];
    assign total_bit_errors_post = bit_errors_post_summation[N_CORES-1];
    assign total_frames = frames_summation[N_CORES-1];
    assign total_frame_errors = frame_errors_summation[N_CORES-1];
    
endmodule


