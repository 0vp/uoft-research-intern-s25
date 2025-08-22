`timescale 1ns / 1ps
module tb_encode;
    reg        clk;  // clock input  
    reg        rst_n;  // active low asynchronous reset  
    wire [7:0] din;
    reg din_en, din_syn;
    wire [7:0] dout;
    reg  [7:0] address;
    reg        enc_trigger;
    reg  [7:0] k;

    always #50 clk = ~clk;

    //instantiate sigin  
    sigin sigin_inst (
        .clk  (clk  ),
        .rst_n(rst_n),
        .en   (din_en),
        .data (din  )
    );
    //instantiate encoder  
    rs_encoder rs_encoder_inst (
        .clk     (clk),
        .rst_n   (rst_n),
        .din     (din),
        .din_en  (din_en),
        .din_syn (din_syn),
        .dout_en (dout_en),
        .dout_syn(dout_syn),
        .dout    (dout)
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            din_en  <= 0;
            din_syn <= 0;
            address <= 0;
        end else begin
            if (enc_trigger && address == 0) begin
                din_en <= 1;
            end else if (address == k - 1) begin
                din_en <= 0;
            end else din_en <= din_en;

            if (address == k - 1) begin
                din_syn <= 1;
            end else begin
                din_syn <= 0;
            end
            if (din_en) address <= address + 1;
            else address <= 0;
        end
    end

    initial begin
        clk = 0;
        rst_n = 1;
        enc_trigger = 0;
        k = 255;
        #1 rst_n = 0;
        #20 rst_n = 1;
        #200;
        #100 enc_trigger = 1;
        #100 enc_trigger = 0;
        #30400 $finish;
    end
endmodule
