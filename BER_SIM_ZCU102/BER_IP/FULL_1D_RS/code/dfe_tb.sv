`timescale 1ns / 1ps

module dfe_tb;
    reg clk = 0;
    reg en = 0;
    reg rstn = 0;

    wire binary_data;
    wire binary_data_valid;
    
    parameter SIGNAL_RESOLUTION = 8;
    parameter SYMBOL_SEPARATION = 48;
    
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
        
     wire [1:0] symbol_dfe;
     wire symbol_dfe_valid;
    
    DFE  #(.ALPHA(0.5)) dfe (
        .clk(clk),
        .rstn(rstn),
        .signal_in(ch_noise),
        .signal_in_valid(ch_noise_valid),
        .symbol_out(symbol_dfe),
        .valid(symbol_dfe_valid)
        );
        
    wire binary_data_dfe;    
    wire binary_data_dfe_valid;
    
    grey_decode gd(
        .clk(clk),
        .symbol(symbol_dfe),
        .rstn(rstn),
        .en(symbol_dfe_valid),
        .data(binary_data_dfe),
        .valid(binary_data_dfe_valid));
        
        
    wire [31:0] total_bits_dfe;
    wire [31:0] total_bit_errors_dfe;
    
    prbs31_checker fec(
        .clk(clk),
        .rstn(rstn),
        .data_in(binary_data_dfe),
        .data_in_valid(binary_data_dfe_valid),
        .total_bits(total_bits_dfe),
        .total_bit_errors(total_bit_errors_dfe));
        
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
    
     always #10 clk = ~clk;
    
    integer i;
  
    reg [63:0] probability_mem [63:0];
    
    initial begin
        en<=0;
        rstn <= 0;
                    
        
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
