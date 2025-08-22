module sigin (
    data,
    clk,
    en,
    rst_n
);
    input wire clk;  // clock input  
    input wire rst_n;  // active low asynchronous reset  
    input wire en;  // enable signal  
    output  reg [7:0] data;  // data output  

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data <= 8'd0;
        end else if (en) begin
            data <= data + 8'd1;
        end
    end
endmodule

module sigin_lut (
    data,
    address
);
    input [7:0] address;
    output [7:0] data;
    reg [7:0] data;

    // an arbitrary data source here
    always @(address) data = address + 1;
endmodule
