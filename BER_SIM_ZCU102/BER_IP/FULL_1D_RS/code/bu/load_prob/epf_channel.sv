`timescale 1ns / 1ps



module epf_channel #(
    parameter RNG_SEED0 = 64'h937285FF37486972,
    parameter RNG_SEED1 = 64'h10FF563829563892,
    parameter RNG_SEED2 = 64'h72074007FFFF2084,
    
    parameter RSER = 64'h0000000000000000,
    parameter EPF = 64'b1100000000000000000000000000000000000000000000000000000000000000)(
    //parameter EPF = 64'h0000000000000000) (
    input clk,
    input [1:0] symbol_in,
    input rstn,
    input en,
    input epf_en,
    input [63:0] rng_seed0,
    input [63:0] rng_seed1,
    input [63:0] rng_seed2,
    
    output reg [1:0] symbol_out,
    output reg valid = 0);
    
    //reg [63:0] EPF;
        
    wire [63:0] random;
    
    //state 0 corresponds to no error, 1 corresponds to an error
    reg state = 0;
    
    reg err_sign = 0;
    
    reg mode = 0;
            
    urng_64 rng (
        .clk(clk),
        .rstn(rstn),
        .en(en),
        .rng_seed0(rng_seed0),
        .rng_seed1(rng_seed1),
        .rng_seed2(rng_seed2),
        .data_out(random));
        
        
    always @ (posedge clk) begin
        
        if (!rstn) begin
            valid <= 0;
            state <= 0;
            err_sign <= 0;
            
            mode <= epf_en;
//            if (epf_en ==1) begin
//                EPF <= 64'b1100000000000000000000000000000000000000000000000000000000000000;
//            end else begin
//                EPF <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
//            end
            
            
        end else begin
        
            if (en) begin
                valid <=1;
                
                if (mode==0) begin
                    symbol_out <= symbol_in;
                
                end else begin
                
                case (state)
                
                    1'b0: begin
                        symbol_out <= symbol_in;
                        
                        if (random < RSER) begin
                            state <= 1;
                        end
                    end
                    
                    1'b1: begin
                        
                        err_sign <= ~err_sign;
                    
                        case (err_sign)
                        
                            1'b0: symbol_out <= symbol_in+1;
                            1'b1: symbol_out <= symbol_in-1;
                        
                        endcase
                        
                        if (random >= EPF) begin
                            state<= 0;
                        end
                    end
                endcase
                end
                
            end else begin
                valid <= 0;
            end
        end
    end
        
endmodule





