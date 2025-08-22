module noise_adder #(
	parameter SIGNAL_RESOLUTION = 8) (
    input clk,
    input rstn,
    input en,
    input signed [SIGNAL_RESOLUTION-1:0] signal_in,
    input signal_in_valid,
    input signed [SIGNAL_RESOLUTION-1:0] noise_in,
    input noise_in_valid,
    output reg signed [SIGNAL_RESOLUTION-1:0] signal_out,
    output reg valid = 0);
    
    wire signed [SIGNAL_RESOLUTION:0] sum; 
    
    assign sum = signal_in+noise_in;
    
    wire signed [SIGNAL_RESOLUTION-1:0] sum_shift; 
    assign sum_shift = {sum[SIGNAL_RESOLUTION],sum[SIGNAL_RESOLUTION-2:0]};
    
    always @ (posedge clk)
        
        //all probability values are loaded while resetn is held low
        if (!rstn) begin
            valid <= 0;
        end else begin
            if (en == 1 && signal_in_valid == 1 && noise_in_valid ==1) begin
                if (sum[SIGNAL_RESOLUTION] == 1'b0 && sum[SIGNAL_RESOLUTION-1] == 1'b1) begin
                    signal_out <= {{1'b0},{(SIGNAL_RESOLUTION-1){1'b1}}};
                end else if (sum[SIGNAL_RESOLUTION] == 1'b1 && sum[SIGNAL_RESOLUTION-1] == 1'b0) begin
                    signal_out <= {{1'b1},{(SIGNAL_RESOLUTION-1){1'b0}}};
                end else begin
                    signal_out <= sum_shift;
                end
                valid<=1;
            end else begin
                valid <= 0;
            end
        end
    
endmodule


module random_noise #(
	parameter SIGNAL_RESOLUTION = 8,
    parameter RNG_SEED0 = 64'h1391A0B350391A0B,
    parameter RNG_SEED1 = 64'h50391A0B0392A7D3,
    parameter RNG_SEED2 = 64'h0392A7D350391A0B) (
    input clk,
    input rstn,
    input en,
    input [63:0] probability_in,
    input [31:0] probability_idx,
    input [63:0] rng_seed0,
    input [63:0] rng_seed1,
    input [63:0] rng_seed2,
    
    output wire signed [SIGNAL_RESOLUTION-1:0] noise_out,
    output reg valid = 0);
    
    
    reg [63:0] probability [63:0];    
    
    wire [63:0] random;
    
    //wire random_valid;
    
    urng_64 rng (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .rng_seed0(rng_seed0),
        .rng_seed1(rng_seed1),
        .rng_seed2(rng_seed2),
        .data_out(random));
        
    reg signed [SIGNAL_RESOLUTION-1:0] noise_mag;
    
    wire signed [1:0] sign;
    
    assign sign[1] = random[0];
    assign sign[0] = 1'b1;
    
    assign noise_out = noise_mag*sign;
        
    always @ (posedge clk)
        
        //all probability values are loaded while resetn is held low
        if (!rstn) begin
            valid <= 0;
            if (probability_idx != 32'hFFFFFFFF) begin
                probability[probability_idx] <= probability_in;
            end
            
            
        end else begin
        
            if (en) begin
                valid <=1;
                
                
                if (random <= probability[0]) begin 
                    noise_mag <= 7'd0;
                end else if (random <= probability[1]) begin 
                    noise_mag <= 7'd1;
                end else if (random <= probability[2]) begin 
                    noise_mag <= 7'd2;
                end else if (random <= probability[3]) begin 
                    noise_mag <= 7'd3;
                end else if (random <= probability[4]) begin 
                    noise_mag <= 7'd4;
                end else if (random <= probability[5]) begin 
                    noise_mag <= 7'd5;
                end else if (random <= probability[6]) begin 
                    noise_mag <= 7'd6;
                end else if (random <= probability[7]) begin 
                    noise_mag <= 7'd7;
                end else if (random <= probability[8]) begin 
                    noise_mag <= 7'd8;
                end else if (random <= probability[9]) begin 
                    noise_mag <= 7'd9;
                end else if (random <= probability[10]) begin 
                    noise_mag <= 7'd10;
                end else if (random <= probability[11]) begin 
                    noise_mag <= 7'd11;
                end else if (random <= probability[12]) begin 
                    noise_mag <= 7'd12;
                end else if (random <= probability[13]) begin 
                    noise_mag <= 7'd13;
                end else if (random <= probability[14]) begin 
                    noise_mag <= 7'd14;
                end else if (random <= probability[15]) begin 
                    noise_mag <= 7'd15;
                end else if (random <= probability[16]) begin 
                    noise_mag <= 7'd16;
                end else if (random <= probability[17]) begin 
                    noise_mag <= 7'd17;
                end else if (random <= probability[18]) begin 
                    noise_mag <= 7'd18;
                end else if (random <= probability[19]) begin 
                    noise_mag <= 7'd19;
                end else if (random <= probability[20]) begin 
                    noise_mag <= 7'd20;
                end else if (random <= probability[21]) begin 
                    noise_mag <= 7'd21;
                end else if (random <= probability[22]) begin 
                    noise_mag <= 7'd22;
                end else if (random <= probability[23]) begin 
                    noise_mag <= 7'd23;
                end else if (random <= probability[24]) begin 
                    noise_mag <= 7'd24;
                end else if (random <= probability[25]) begin 
                    noise_mag <= 7'd25;
                end else if (random <= probability[26]) begin 
                    noise_mag <= 7'd26;
                end else if (random <= probability[27]) begin 
                    noise_mag <= 7'd27;
                end else if (random <= probability[28]) begin 
                    noise_mag <= 7'd28;
                end else if (random <= probability[29]) begin 
                    noise_mag <= 7'd29;
                end else if (random <= probability[30]) begin 
                    noise_mag <= 7'd30;
                end else if (random <= probability[31]) begin 
                    noise_mag <= 7'd31;
                end else if (random <= probability[32]) begin 
                    noise_mag <= 7'd32;
                end else if (random <= probability[33]) begin 
                    noise_mag <= 7'd33;
                end else if (random <= probability[34]) begin 
                    noise_mag <= 7'd34;
                end else if (random <= probability[35]) begin 
                    noise_mag <= 7'd35;
                end else if (random <= probability[36]) begin 
                    noise_mag <= 7'd36;
                end else if (random <= probability[37]) begin 
                    noise_mag <= 7'd37;
                end else if (random <= probability[38]) begin 
                    noise_mag <= 7'd38;
                end else if (random <= probability[39]) begin 
                    noise_mag <= 7'd39;
                end else if (random <= probability[40]) begin 
                    noise_mag <= 7'd40;
                end else if (random <= probability[41]) begin 
                    noise_mag <= 7'd41;
                end else if (random <= probability[42]) begin 
                    noise_mag <= 7'd42;
                end else if (random <= probability[43]) begin 
                    noise_mag <= 7'd43;
                end else if (random <= probability[44]) begin 
                    noise_mag <= 7'd44;
                end else if (random <= probability[45]) begin 
                    noise_mag <= 7'd45;
                end else if (random <= probability[46]) begin 
                    noise_mag <= 7'd46;
                end else if (random <= probability[47]) begin 
                    noise_mag <= 7'd47;
                end else if (random <= probability[48]) begin 
                    noise_mag <= 7'd48;
                end else if (random <= probability[49]) begin 
                    noise_mag <= 7'd49;
                end else if (random <= probability[50]) begin 
                    noise_mag <= 7'd50;
                end else if (random <= probability[51]) begin 
                    noise_mag <= 7'd51;
                end else if (random <= probability[52]) begin 
                    noise_mag <= 7'd52;
                end else if (random <= probability[53]) begin 
                    noise_mag <= 7'd53;
                end else if (random <= probability[54]) begin 
                    noise_mag <= 7'd54;
                end else if (random <= probability[55]) begin 
                    noise_mag <= 7'd55;
                end else if (random <= probability[56]) begin 
                    noise_mag <= 7'd56;
                end else if (random <= probability[57]) begin 
                    noise_mag <= 7'd57;
                end else if (random <= probability[58]) begin 
                    noise_mag <= 7'd58;
                end else if (random <= probability[59]) begin 
                    noise_mag <= 7'd59;
                end else if (random <= probability[60]) begin 
                    noise_mag <= 7'd60;
                end else if (random <= probability[61]) begin 
                    noise_mag <= 7'd61;
                end else if (random <= probability[62]) begin 
                    noise_mag <= 7'd62;
                end else begin 
                    noise_mag <= 7'd63;
                end                    
                
            end else begin
                valid <= 0;
            end
        end
        
endmodule


module urng_64 #(
    parameter SEED0 = 64'd5030521883283424767,
    parameter SEED1 = 64'd18445829279364155008,
    parameter SEED2 = 64'd18436106298727503359
    )(
    // System signals
    input clk,                    // system clock
    input rstn,                   // system synchronous reset, active low

    // Data interface
    input en,                     // clock enable
    input [63:0] rng_seed0,
    input [63:0] rng_seed1,
    input [63:0] rng_seed2,
    output reg valid,         // output data valid
    output reg [63:0] data_out    // output data
    );

    // Local variables
    reg [63:0] z1, z2, z3;
    wire [63:0] z1_next, z2_next, z3_next;
    
    
    
    //assign data_out = data_out_full[31:0];
    
    // Update state
    assign z1_next = {z1[39:1], z1[58:34] ^ z1[63:39]};
    assign z2_next = {z2[50:6], z2[44:26] ^ z2[63:45]};
    assign z3_next = {z3[56:9], z3[39:24] ^ z3[63:48]};
    
    always @ (posedge clk) begin
        if (!rstn) begin
            z1 <= rng_seed0;
            z2 <= rng_seed1;
            z3 <= rng_seed2;
        end
        else if (en) begin
            z1 <= z1_next;
            z2 <= z2_next;
            z3 <= z3_next;
        end
    end
    
    
    // Output data
    always @ (posedge clk) begin
        if (!rstn)
            valid <= 1'b0;
        else
            valid <= en;
    end
    
    always @ (posedge clk) begin
        if (!rstn)
            data_out <= 64'd0;
        else
            data_out <= (z1_next ^ z2_next ^ z3_next);

    end
    
    
endmodule