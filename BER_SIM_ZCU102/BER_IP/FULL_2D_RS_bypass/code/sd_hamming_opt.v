`timescale 1ns / 1ps

module llr_adder_opt #(
    parameter LLR_RESOLUTION = 5)(
    input wire [LLR_RESOLUTION-1:0] in0,
    input wire [LLR_RESOLUTION-1:0] in1,
    input wire [LLR_RESOLUTION-1:0] in2,
    input wire [LLR_RESOLUTION-1:0] in3,
    input wire [LLR_RESOLUTION-1:0] in4,
    input wire [LLR_RESOLUTION-1:0] in5,
    output wire [15:0] out);
    
    assign out = in0+in1+in2+in3+in4+in5;

endmodule

module hamming_dec_opt #(
    //bit resolution of LLR output
    parameter LLR_RESOLUTION = 5,
    
    //number of low-reliability bits that are tested with test patterns
    parameter Q = 6,
    
    //number of test patterns for chase decoder
    parameter N_TP = 42)(
    input clk,
    input rstn,
    input [1:0] symbol_in,
    input symbol_in_valid,
    input [LLR_RESOLUTION-1:0] llr_in,
    input llr_sign,
    input en,
    output reg data_out,
    output reg valid = 0);
    
    //take absolute value of log-likelihood ratio
    //wire [LLR_RESOLUTION-1:0] abs_llr;
    //assign abs_llr = llr_in[LLR_RESOLUTION-1] ? -llr_in : llr_in;

    //look-up table for to map syndrome values to error locations. 
    //syndrome_lut[syndrome] is error location. if syndrome_lut[s] = 8'hFF, decoder failure
    (*rom_style = "block" *) reg [7:0] syndrome_lut [255:0];
    initial $readmemh("syndrome_lut.mem", syndrome_lut);
    
    
    //test patterns for least reliable Q bits 
    (*rom_style = "block" *) reg [Q-1:0] test_patterns [N_TP-1:0];
    initial $readmemh("test_patterns.mem", test_patterns);
    
    //state 0: input new codeword and output decoded codeword (binary)
    //state 1: 
    //state 2: 
    //state 3: 
    //state 4: 
    
    //FSM state
    reg [7:0] state = 0;
    
    //track input symbol index
    reg [7:0] counter = 0;
    
    //track test pattern index
    reg [7:0] test_pattern_idx = 0;
    
    //input binary codeword
    (*ram_style = "block" *) reg [119:0] data1_reg;
    
    //reg to hold corrected binary codeword 
    (*ram_style = "block" *) reg [119:0] data_output_reg;
    
    //reg to hold input to decoder (first 60b are xored PAM symbols, last 8 parity bits are from 4 PAM symbols)
    (*ram_style = "block" *) reg [67:0] symbol1_reg;
    //LLrs of the corresponding PAM symbols
    (*ram_style = "block" *) reg [LLR_RESOLUTION-1:0] llr1_reg [63:0];
    //Sign of LLRs indicating if error in MSB or LSB
    (*ram_style = "block" *) reg llr1_sign_reg [63:0];
    
    //reg to hold index ot the least reliable Q symbols
    reg [7:0] least_reliable_symbol0;
    reg [7:0] least_reliable_symbol1;
    reg [7:0] least_reliable_symbol2;
    reg [7:0] least_reliable_symbol3;
    reg [7:0] least_reliable_symbol4;
    reg [7:0] least_reliable_symbol5;
    
    
    
    
    
    //reg to hold absolut value of the least Q LLRs 
    
    reg [LLR_RESOLUTION-1:0] least_llr0 = {LLR_RESOLUTION{1'b1}};
    reg [LLR_RESOLUTION-1:0] least_llr1 = {LLR_RESOLUTION{1'b1}};
    reg [LLR_RESOLUTION-1:0] least_llr2 = {LLR_RESOLUTION{1'b1}};
    reg [LLR_RESOLUTION-1:0] least_llr3 = {LLR_RESOLUTION{1'b1}};
    reg [LLR_RESOLUTION-1:0] least_llr4 = {LLR_RESOLUTION{1'b1}};
    reg [LLR_RESOLUTION-1:0] least_llr5 = {LLR_RESOLUTION{1'b1}};
    
    
   
    //syndrome
    wire [7:0] syndrome1;
    
    //error location corresponding to syndrome
    reg [7:0] error_location;
    
    //reg at input to combinational decoder block
    reg [67:0] dec1_in;
    
    
    //combinational decoder block, calculates syndrome
    dec dec1 (
        .data_in(dec1_in),
        .syndrome(syndrome1));
   
    //reg to sum up LLRS for all bits flipped in test pattern
    reg [LLR_RESOLUTION-1:0] adder_in0;
    reg [LLR_RESOLUTION-1:0] adder_in1;
    reg [LLR_RESOLUTION-1:0] adder_in2;
    reg [LLR_RESOLUTION-1:0] adder_in3;
    reg [LLR_RESOLUTION-1:0] adder_in4;
    reg [LLR_RESOLUTION-1:0] adder_in5;
    //sum of adder_in
    wire [15:0] tp_wt;
    
    //module to add up LLRs for each bit flip in test pattern
    llr_adder_opt #(.LLR_RESOLUTION(LLR_RESOLUTION)) adder(
        .in0(adder_in0),
        .in1(adder_in1),
        .in2(adder_in2),
        .in3(adder_in3),
        .in4(adder_in4),
        .in5(adder_in5),
        .out(tp_wt));
    
    //variables to track info about test-pattern that results in most-reliable codeword
    reg [15:0] most_reliable_tp_wt = 16'hFFFF;
    reg [15:0] most_reliable_tp_idx = 0;
    reg [7:0] most_reliable_error_location = 0;
    reg [15:0] current_tp_reliability = 16'hFFFF;
    
    // flag when codeword is ready for output
    reg output_ready = 0;
    //counter for output bits
    reg [7:0] output_counter = 0;
       
    always @ (posedge clk) begin
        
        if (!rstn) begin
            state <= 0;
            counter <= 0;
            test_pattern_idx <=0;
            valid <=0;
            output_ready <=0;
            output_counter <=0;
            
            most_reliable_tp_wt <= 16'hFFFF;
            most_reliable_tp_idx <= 0;
            most_reliable_error_location <= 0;
            current_tp_reliability <= 16'hFFFF;
            
            adder_in0 <= 0;
            adder_in1 <= 0;
            adder_in2 <= 0;
            adder_in3 <= 0;
            adder_in4 <= 0;
            adder_in5 <= 0;
            
            least_llr0 <= {LLR_RESOLUTION{1'b1}};
            least_llr1 <= {LLR_RESOLUTION{1'b1}};
            least_llr2 <= {LLR_RESOLUTION{1'b1}};
            least_llr3 <= {LLR_RESOLUTION{1'b1}};
            least_llr4 <= {LLR_RESOLUTION{1'b1}};
            least_llr5 <= {LLR_RESOLUTION{1'b1}};
            
            
        end else begin
        
            
            if (state == 0) begin
            
                if (output_ready) begin
                
                        data_out <= data_output_reg[output_counter];
                        valid <=1;
                        output_counter <= output_counter+1;
                        
                        if (output_counter == 119) begin
                            output_ready <= 0;
                            output_counter <= 0;
                        end
                end else begin
                    valid <=0;
                end
            
                if  (symbol_in_valid == 1) begin
                
                    counter <= counter + 1;
                    
                    //record new symbol reliability                                 
                    llr1_reg[counter] <= llr_in;
                    //record sign of llr
                    llr1_sign_reg[counter] <= llr_sign;
                    
                    //record grey decoded data as well as xored data for information bits
                    if (counter<60) begin
                        if (symbol_in == 0) begin
                            data1_reg[counter*2] <= 1'b0;
                            data1_reg[counter*2+1] <= 1'b0;
                            symbol1_reg[counter] <= 1'b0;
                            
                        end else if (symbol_in == 1) begin 
                            data1_reg[counter*2] <= 1'b0;
                            data1_reg[counter*2+1] <= 1'b1;
                            symbol1_reg[counter] <= 1'b1;
                            
                        end else if (symbol_in ==2) begin
                            data1_reg[counter*2] <= 1'b1;
                            data1_reg[counter*2+1] <= 1'b1;
                            symbol1_reg[counter] <= 1'b0;
                            
                        end else begin
                            data1_reg[counter*2] <= 1'b1;
                            data1_reg[counter*2+1] <= 1'b0;
                            symbol1_reg[counter] <= 1'b1;
                        end
                        
                    //record parity bits
                    end else begin
                        if (symbol_in == 0) begin
                            symbol1_reg[60+(counter-60)*2] <= 1'b0;
                            symbol1_reg[60+(counter-60)*2+1] <= 1'b0;
                            
                        end else if (symbol_in == 1) begin 
                            symbol1_reg[60+(counter-60)*2] <= 1'b0;
                            symbol1_reg[60+(counter-60)*2+1] <= 1'b1;
                            
                        end else if (symbol_in ==2) begin
                            symbol1_reg[60+(counter-60)*2] <= 1'b1;
                            symbol1_reg[60+(counter-60)*2+1] <= 1'b1;
                            
                        end else begin
                            symbol1_reg[60+(counter-60)*2] <= 1'b1;
                            symbol1_reg[60+(counter-60)*2+1] <= 1'b0;
                        end

                    end
                                       
                    //sort least reliable Q symbols as they come in
                    if (llr_in<least_llr0) begin
                        least_llr0 <= llr_in;
                        least_reliable_symbol0 <= counter;
                        
                        least_llr1<=least_llr0;
                        least_llr2<=least_llr1;
                        least_llr3<=least_llr2;
                        least_llr4<=least_llr3;
                        least_llr5<=least_llr4;
                        
                        least_reliable_symbol1<=least_reliable_symbol0;
                        least_reliable_symbol2<=least_reliable_symbol1;
                        least_reliable_symbol3<=least_reliable_symbol2;
                        least_reliable_symbol4<=least_reliable_symbol3;
                        least_reliable_symbol5<=least_reliable_symbol4;
                        
                    end else if (llr_in<least_llr1) begin
                        least_llr1 <= llr_in;
                        least_reliable_symbol1 <= counter;
                        
                        least_llr2<=least_llr1;
                        least_llr3<=least_llr2;
                        least_llr4<=least_llr3;
                        least_llr5<=least_llr4;
                        
                        least_reliable_symbol2<=least_reliable_symbol1;
                        least_reliable_symbol3<=least_reliable_symbol2;
                        least_reliable_symbol4<=least_reliable_symbol3;
                        least_reliable_symbol5<=least_reliable_symbol4;
                        
                    end else if  (llr_in<least_llr2) begin
                        least_llr2 <= llr_in;
                        least_reliable_symbol2 <= counter;
                                                
                        least_llr3<=least_llr2;
                        least_llr4<=least_llr3;
                        least_llr5<=least_llr4;
                        
                        least_reliable_symbol3<=least_reliable_symbol2;
                        least_reliable_symbol4<=least_reliable_symbol3;
                        least_reliable_symbol5<=least_reliable_symbol4;
                        
                    end else if  (llr_in<least_llr3) begin
                        least_llr3 <= llr_in;
                        least_reliable_symbol3 <= counter;
                                                
                        least_llr4<=least_llr3;
                        least_llr5<=least_llr4;

                        least_reliable_symbol4<=least_reliable_symbol3;
                        least_reliable_symbol5<=least_reliable_symbol4;
                        
                    end else if  (llr_in<least_llr4) begin
                        least_llr4 <= llr_in;
                        least_reliable_symbol4 <= counter;
                        
                                                
                        least_llr5<=least_llr4;
                        
                        least_reliable_symbol5<=least_reliable_symbol4;
                        
                    end else if  (llr_in<least_llr5) begin
                        
                        least_llr5 <= llr_in;
                        least_reliable_symbol5 <= counter;
                    end
                    //when full codeword is received, go to next state
                    if (counter == 63) begin
                        state <= 1;
                        counter <= 0;
                    end
                end                
               
            end else if (state ==1) begin
            
                //enter ML recieved sequence to decoder input
                dec1_in <= symbol1_reg;
                state <= 2;
            
            //apply test_pattern and calculate analog weight for just test pattern
            end else if (state ==2) begin
            
                if (test_patterns[test_pattern_idx][0] == 1) begin
                    adder_in0 <= least_llr0;
                    //bit flip is in info bits
                    if (least_reliable_symbol0 <60) begin
                       dec1_in[least_reliable_symbol0] <= ~ dec1_in[least_reliable_symbol0];
                       //bit flip is in party bits
                   end else begin
                        dec1_in[60+(least_reliable_symbol0-60)*2+llr1_sign_reg[least_reliable_symbol0]] <= ~ dec1_in[60+(least_reliable_symbol0-60)*2+llr1_sign_reg[least_reliable_symbol0]];
                   end
                    
                end if (test_patterns[test_pattern_idx][1] == 1) begin
                    adder_in1 <= least_llr1;
                    //bit flip is in info bits
                    if (least_reliable_symbol1 <60) begin
                       dec1_in[least_reliable_symbol1] <= ~ dec1_in[least_reliable_symbol1];
                       //bit flip is in party bits
                   end else begin
                        dec1_in[60+(least_reliable_symbol1-60)*2+llr1_sign_reg[least_reliable_symbol1]] <= ~ dec1_in[60+(least_reliable_symbol1-60)*2+llr1_sign_reg[least_reliable_symbol1]];
                   end
                    
                end if (test_patterns[test_pattern_idx][2] == 1) begin
                    adder_in2 <= least_llr2;
                        //bit flip is in info bits
                    if (least_reliable_symbol2 <60) begin
                       dec1_in[least_reliable_symbol2] <= ~ dec1_in[least_reliable_symbol2];
                       //bit flip is in party bits
                   end else begin
                        dec1_in[60+(least_reliable_symbol2-60)*2+llr1_sign_reg[least_reliable_symbol2]] <= ~ dec1_in[60+(least_reliable_symbol2-60)*2+llr1_sign_reg[least_reliable_symbol2]];
                   end
                    
                end if (test_patterns[test_pattern_idx][3] == 1) begin
                    adder_in3 <= least_llr3;
                                            //bit flip is in info bits
                    if (least_reliable_symbol3 <60) begin
                       dec1_in[least_reliable_symbol3] <= ~ dec1_in[least_reliable_symbol3];
                       //bit flip is in party bits
                   end else begin
                        dec1_in[60+(least_reliable_symbol3-60)*2+llr1_sign_reg[least_reliable_symbol3]] <= ~ dec1_in[60+(least_reliable_symbol3-60)*2+llr1_sign_reg[least_reliable_symbol3]];
                   end
                    
                end if (test_patterns[test_pattern_idx][4] == 1) begin
                    adder_in4 <= least_llr4;
                                            //bit flip is in info bits
                    if (least_reliable_symbol4 <60) begin
                       dec1_in[least_reliable_symbol4] <= ~ dec1_in[least_reliable_symbol4];
                       //bit flip is in party bits
                   end else begin
                        dec1_in[60+(least_reliable_symbol4-60)*2+llr1_sign_reg[least_reliable_symbol4]] <= ~ dec1_in[60+(least_reliable_symbol4-60)*2+llr1_sign_reg[least_reliable_symbol4]];
                   end
                    
                end if (test_patterns[test_pattern_idx][5] == 1) begin
                    adder_in5 <= least_llr4;
                                            //bit flip is in info bits
                    if (least_reliable_symbol5 <60) begin
                       dec1_in[least_reliable_symbol5] <= ~ dec1_in[least_reliable_symbol5];
                       //bit flip is in party bits
                   end else begin
                       dec1_in[60+(least_reliable_symbol5-60)*2+llr1_sign_reg[least_reliable_symbol5]] <= ~ dec1_in[60+(least_reliable_symbol5-60)*2+llr1_sign_reg[least_reliable_symbol5]];
                   end
                end
            
                state <= 3;
            
            //find error location
            end else if (state == 3) begin
                
                //test_pattern_weights[test_pattern_idx] <= tp_wt;
                current_tp_reliability <= tp_wt;
                error_location <= syndrome_lut[syndrome1];
                state <= 4;
                
                adder_in0 <= 0;
                adder_in1 <= 0;
                adder_in2 <= 0;
                adder_in3 <= 0;
                adder_in4 <= 0;
                adder_in5 <= 0;
            
            //calculate analog weight with correction
            end else if (state == 4) begin
            
                //no added weight for valid codeword
                if (syndrome1 == 8'h00) begin
                    //check if most reliable
                    if (current_tp_reliability < most_reliable_tp_wt) begin
                        most_reliable_tp_wt <= current_tp_reliability;
                        most_reliable_tp_idx <= test_pattern_idx;                        
                        most_reliable_error_location <= 8'hFF;
                    end
                end else if (error_location == 8'hFF) begin
                    //not valid codeword, don't consider it
                    
                //add weight for error bit and check if most reliable
                end else if (current_tp_reliability+llr1_reg[error_location] < most_reliable_tp_wt) begin
                    most_reliable_tp_wt <= current_tp_reliability+llr1_reg[error_location];
                    most_reliable_tp_idx <= test_pattern_idx;  
                    most_reliable_error_location <= error_location;
                
                end
                
                if (test_pattern_idx < 41) begin
                    test_pattern_idx <= test_pattern_idx + 1;
                    state <= 1;
                end else begin
                    state <= 5;
                end
                
            //perform correction for most reliable test pattern
            end else if (state == 5) begin
            
                // only correct if in info bits
                if (test_patterns[most_reliable_tp_idx][0] == 1 && least_reliable_symbol0<60) begin
                    data1_reg[least_reliable_symbol0*2+llr1_sign_reg[least_reliable_symbol0]] <= ~data1_reg[least_reliable_symbol0*2+llr1_sign_reg[least_reliable_symbol0]];
                    
                end if (test_patterns[most_reliable_tp_idx][1] == 1 && least_reliable_symbol1<60) begin
                    data1_reg[least_reliable_symbol1*2+llr1_sign_reg[least_reliable_symbol1]] <= ~data1_reg[least_reliable_symbol1*2+llr1_sign_reg[least_reliable_symbol1]];
                    
                end if (test_patterns[most_reliable_tp_idx][2] == 1 && least_reliable_symbol2<60) begin
                    data1_reg[least_reliable_symbol2*2+llr1_sign_reg[least_reliable_symbol2]] <= ~data1_reg[least_reliable_symbol2*2+llr1_sign_reg[least_reliable_symbol2]];
                    
                end if (test_patterns[most_reliable_tp_idx][3] == 1 && least_reliable_symbol3<60) begin
                    data1_reg[least_reliable_symbol3*2+llr1_sign_reg[least_reliable_symbol3]] <= ~data1_reg[least_reliable_symbol3*2+llr1_sign_reg[least_reliable_symbol3]];
                    
                end if (test_patterns[most_reliable_tp_idx][4] == 1 && least_reliable_symbol4<60) begin
                    data1_reg[least_reliable_symbol4*2+llr1_sign_reg[least_reliable_symbol4]] <= ~data1_reg[least_reliable_symbol4*2+llr1_sign_reg[least_reliable_symbol4]];
                    
                end if (test_patterns[most_reliable_tp_idx][5] == 1 && least_reliable_symbol5<60) begin
                    data1_reg[least_reliable_symbol5*2+llr1_sign_reg[least_reliable_symbol5]] <= ~data1_reg[least_reliable_symbol5*2+llr1_sign_reg[least_reliable_symbol5]];
                    
                end if (most_reliable_error_location<60) begin
                    data1_reg[most_reliable_error_location*2+llr1_sign_reg[most_reliable_error_location]] <= ~data1_reg[most_reliable_error_location*2+llr1_sign_reg[most_reliable_error_location]];
                    
                end
                
                state <= 6;
                
            end else if (state==6) begin
            
                data_output_reg <= data1_reg;
                output_ready <= 1;
                output_counter <=0;
                
                test_pattern_idx <=0;
                
                least_llr0 <= {LLR_RESOLUTION{1'b1}};
                least_llr1 <= {LLR_RESOLUTION{1'b1}};
                least_llr2 <= {LLR_RESOLUTION{1'b1}};
                least_llr3 <= {LLR_RESOLUTION{1'b1}};
                least_llr4 <= {LLR_RESOLUTION{1'b1}};
                least_llr5 <= {LLR_RESOLUTION{1'b1}};
                
                most_reliable_tp_wt <= 16'hFFFF;
                most_reliable_tp_idx <= 0;
                most_reliable_error_location <= 0;
                current_tp_reliability <= 16'hFFFF;
                state <=7;
                
            end else if (state==7) begin
                if (en) begin
                    state <= 0;
                end
            end
        end
    end
endmodule

    