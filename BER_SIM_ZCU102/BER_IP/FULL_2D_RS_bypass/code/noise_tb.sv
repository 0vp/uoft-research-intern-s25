`timescale 1ns / 1ps

module noise_tb;
    reg clk = 0;
    reg en = 0;
    reg rstn = 0;
    
    parameter NOISE_RESOLUTION = 7;
    
    wire signed [NOISE_RESOLUTION-1:0] noise_out;
    wire noise_out_valid;
    
    reg [63:0] probability;
    reg [31:0] probability_idx;
    
    random_noise #(.NOISE_RESOLUTION(NOISE_RESOLUTION)) noise(
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .noise_out(noise_out),
        .valid(noise_out_valid),
        .probability_in(probability),
        .probability_idx(probability_idx)
        );
     
    always #10 clk = ~clk;

    integer i;
  
    reg [63:0] probability_mem [63:0];
    
    reg [63:0] counter [127:0] = '{default:'0};
    reg [63:0] bit_counter = 0;
    reg [63:0] bit_error_counter = 0;
    
    always @ (posedge clk) begin
        if (noise_out_valid ==1) begin
            counter[noise_out+63] <= counter[noise_out+63] + 1;
            bit_counter <= bit_counter +1;
            
            if (noise_out > 24 || noise_out < -23) begin
                bit_error_counter <= bit_error_counter+1;
            end
        end
    end
    
    initial begin
    
        en<=0;
        rstn <= 0;
        $readmemh("noise15dB.mem", probability_mem);
        
        for (i=0;i<64;i=i+1) begin
            #20
            probability_idx <= i;
            probability <= probability_mem[i];
        end
        
        #20
        probability_idx <= 32'hFFFFFFFF;

        #20 
        en<= 1;
        rstn <=1;             
        
        
    end
endmodule