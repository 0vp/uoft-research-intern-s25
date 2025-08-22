module rsdec_syn_m0 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[7];
        y[1] = x[0] ^ x[7];
        y[2] = x[1] ^ x[7];
        y[3] = x[2];
        y[4] = x[3];
        y[5] = x[4];
        y[6] = x[5];
        y[7] = x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m1 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[6] ^ x[7];
        y[1] = x[6];
        y[2] = x[0] ^ x[6];
        y[3] = x[1] ^ x[7];
        y[4] = x[2];
        y[5] = x[3];
        y[6] = x[4];
        y[7] = x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m2 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[5] ^ x[6] ^ x[7];
        y[1] = x[5];
        y[2] = x[5] ^ x[7];
        y[3] = x[0] ^ x[6];


        y[4] = x[1] ^ x[7];
        y[5] = x[2];
        y[6] = x[3];
        y[7] = x[4] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m3 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[4] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[4];
        y[2] = x[4] ^ x[6] ^ x[7];
        y[3] = x[5] ^ x[7];
        y[4] = x[0] ^ x[6];
        y[5] = x[1] ^ x[7];
        y[6] = x[2];
        y[7] = x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m4 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[3];
        y[2] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[4] ^ x[6] ^ x[7];
        y[4] = x[5] ^ x[7];
        y[5] = x[0] ^ x[6];
        y[6] = x[1] ^ x[7];
        y[7] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m5 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[2];
        y[2] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[4] ^ x[6] ^ x[7];
        y[5] = x[5] ^ x[7];
        y[6] = x[0] ^ x[6];
        y[7] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    end
endmodule

module rsdec_syn_m6 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[1] = x[1] ^ x[7];
        y[2] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[3] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[4] ^ x[6] ^ x[7];
        y[6] = x[5] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
    end
endmodule

module rsdec_syn_m7 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[1] = x[0] ^ x[6];
        y[2] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[3] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[4] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[4] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
    end
endmodule



module rsdec_syn_m8 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[7];
        y[1] = x[5] ^ x[7];
        y[2] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[3] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[4] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[5] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6];
    end
endmodule

module rsdec_syn_m9 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[6];
        y[1] = x[4] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[4] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[5] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[6] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[7];
    end
endmodule

module rsdec_syn_m10 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[5] ^ x[7];
        y[1] = x[3] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[5] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];


        y[6] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[7] = x[0] ^ x[1] ^ x[4] ^ x[6];
    end
endmodule

module rsdec_syn_m11 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[4] ^ x[6];
        y[1] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[7] = x[0] ^ x[3] ^ x[5];
    end
endmodule

module rsdec_syn_m12 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[3] ^ x[5];
        y[1] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[2] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[3] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[5] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[7] = x[2] ^ x[4] ^ x[7];
    end
endmodule

module rsdec_syn_m13 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[2] ^ x[4] ^ x[7];


        y[1] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[2] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[4] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[5] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[6] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[1] ^ x[3] ^ x[6];
    end
endmodule

module rsdec_syn_m14 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[3] ^ x[6];
        y[1] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[5] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[6] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[7] = x[0] ^ x[2] ^ x[5] ^ x[7];
    end
endmodule

module rsdec_syn_m15 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[2] ^ x[5] ^ x[7];
        y[1] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[6] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[7] = x[1] ^ x[4] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m16 (
    y,
    x
);
    input [7:0] x;


    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[4] ^ x[6] ^ x[7];
        y[1] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6];
        y[2] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[3] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[3] ^ x[5] ^ x[6];
    end
endmodule

module rsdec_syn_m17 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[3] ^ x[5] ^ x[6];
        y[1] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[2] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[3] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[4] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[5] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[2] ^ x[4] ^ x[5] ^ x[7];
    end
endmodule

module rsdec_syn_m18 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[2] ^ x[4] ^ x[5] ^ x[7];
        y[1] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[3] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[4] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[5] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[6] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[1] ^ x[3] ^ x[4] ^ x[6];


    end
endmodule

module rsdec_syn_m19 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[3] ^ x[4] ^ x[6];
        y[1] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[4] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[5] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[6] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[7] = x[0] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
    end
endmodule

module rsdec_syn_m20 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
        y[1] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[6];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[5] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[7] = x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m21 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
        y[1] = x[0] ^ x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[2] = x[0] ^ x[5];


        y[3] = x[0] ^ x[1] ^ x[6];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[5] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[6] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[7] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m22 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[2] = x[4] ^ x[7];
        y[3] = x[0] ^ x[5];
        y[4] = x[0] ^ x[1] ^ x[6];
        y[5] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[6] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[7] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m23 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[1] ^ x[2] ^ x[3] ^ x[4];
        y[2] = x[3] ^ x[6] ^ x[7];
        y[3] = x[4] ^ x[7];
        y[4] = x[0] ^ x[5];
        y[5] = x[0] ^ x[1] ^ x[6];
        y[6] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[7] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m24 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;


    always @(x) begin
        y[0] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
        y[1] = x[0] ^ x[1] ^ x[2] ^ x[3];
        y[2] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[3] = x[3] ^ x[6] ^ x[7];
        y[4] = x[4] ^ x[7];
        y[5] = x[0] ^ x[5];
        y[6] = x[0] ^ x[1] ^ x[6];
        y[7] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
    end
endmodule

module rsdec_syn_m25 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
        y[1] = x[0] ^ x[1] ^ x[2] ^ x[7];
        y[2] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[3] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[4] = x[3] ^ x[6] ^ x[7];
        y[5] = x[4] ^ x[7];
        y[6] = x[0] ^ x[5];
        y[7] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
    end
endmodule

module rsdec_syn_m26 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
        y[1] = x[0] ^ x[1] ^ x[6];
        y[2] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[3] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[4] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[5] = x[3] ^ x[6] ^ x[7];
        y[6] = x[4] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4];
    end
endmodule



module rsdec_syn_m27 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4];
        y[1] = x[0] ^ x[5];
        y[2] = x[2] ^ x[3] ^ x[4] ^ x[6];
        y[3] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[4] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[5] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[6] = x[3] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[7];
    end
endmodule

module rsdec_syn_m28 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[7];
        y[1] = x[4] ^ x[7];
        y[2] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
        y[3] = x[2] ^ x[3] ^ x[4] ^ x[6];
        y[4] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[5] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[6] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[7] = x[0] ^ x[1] ^ x[2] ^ x[6];
    end
endmodule

module rsdec_syn_m29 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[2] ^ x[6];
        y[1] = x[3] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
        y[3] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
        y[4] = x[2] ^ x[3] ^ x[4] ^ x[6];


        y[5] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[6] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[7] = x[0] ^ x[1] ^ x[5] ^ x[7];
    end
endmodule

module rsdec_syn_m30 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[1] ^ x[5] ^ x[7];
        y[1] = x[2] ^ x[5] ^ x[6] ^ x[7];
        y[2] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6];
        y[3] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
        y[4] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
        y[5] = x[2] ^ x[3] ^ x[4] ^ x[6];
        y[6] = x[0] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
        y[7] = x[0] ^ x[4] ^ x[6] ^ x[7];
    end
endmodule

module rsdec_syn_m31 (
    y,
    x
);
    input [7:0] x;
    output [7:0] y;
    reg [7:0] y;
    always @(x) begin
        y[0] = x[0] ^ x[4] ^ x[6] ^ x[7];
        y[1] = x[1] ^ x[4] ^ x[5] ^ x[6];
        y[2] = x[0] ^ x[2] ^ x[4] ^ x[5];
        y[3] = x[0] ^ x[1] ^ x[3] ^ x[5] ^ x[6];
        y[4] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
        y[5] = x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
        y[6] = x[2] ^ x[3] ^ x[4] ^ x[6];
        y[7] = x[3] ^ x[5] ^ x[6];
    end
endmodule

module rsdec_syn (
    y0,
    y1,
    y2,
    y3,
    y4,
    y5,
    y6,
    y7,
    y8,
    y9,
    y10,
    y11,
    y12,
    y13,
    y14,
    y15,
    y16,
    y17,
    y18,
    y19,
    y20,
    y21,
    y22,
    y23,
    y24,
    y25,
    y26,
    y27,
    y28,
    y29,
    y30,
    y31,
    u,
    enable,
    shift,
    init,
    clk,
    rst_n
);
    input [7:0] u;
    input clk, rst_n, shift, init, enable;
    output [7:0] y0;


    output [7:0] y1;
    output [7:0] y2;
    output [7:0] y3;
    output [7:0] y4;
    output [7:0] y5;
    output [7:0] y6;
    output [7:0] y7;
    output [7:0] y8;
    output [7:0] y9;
    output [7:0] y10;
    output [7:0] y11;
    output [7:0] y12;
    output [7:0] y13;
    output [7:0] y14;
    output [7:0] y15;
    output [7:0] y16;
    output [7:0] y17;
    output [7:0] y18;
    output [7:0] y19;
    output [7:0] y20;
    output [7:0] y21;
    output [7:0] y22;
    output [7:0] y23;
    output [7:0] y24;
    output [7 : 0] y25;
    output [7:0] y26;
    output [7:0] y27;
    output [7:0] y28;
    output [7:0] y29;
    output [7:0] y30;
    output [7:0] y31;
    reg  [7:0] y0;
    reg  [7:0] y1;
    reg  [7:0] y2;
    reg  [7:0] y3;
    reg  [7:0] y4;
    reg  [7:0] y5;
    reg  [7:0] y6;
    reg  [7:0] y7;
    reg  [7:0] y8;
    reg  [7:0] y9;
    reg  [7:0] y10;
    reg  [7:0] y11;
    reg  [7:0] y12;
    reg  [7:0] y13;
    reg  [7:0] y14;


    reg  [7:0] y15;
    reg  [7:0] y16;
    reg  [7:0] y17;
    reg  [7:0] y18;
    reg  [7:0] y19;
    reg  [7:0] y20;
    reg  [7:0] y21;
    reg  [7:0] y22;
    reg  [7:0] y23;
    reg  [7:0] y24;
    reg  [7:0] y25;
    reg  [7:0] y26;
    reg  [7:0] y27;
    reg  [7:0] y28;
    reg  [7:0] y29;
    reg  [7:0] y30;
    reg  [7:0] y31;

    wire [7:0] scale0;
    wire [7:0] scale1;
    wire [7:0] scale2;
    wire [7:0] scale3;
    wire [7:0] scale4;
    wire [7:0] scale5;
    wire [7:0] scale6;
    wire [7:0] scale7;
    wire [7:0] scale8;
    wire [7:0] scale9;
    wire [7:0] scale10;
    wire [7:0] scale11;
    wire [7:0] scale12;
    wire [7:0] scale13;
    wire [7:0] scale14;
    wire [7:0] scale15;
    wire [7:0] scale16;
    wire [7:0] scale17;
    wire [7:0] scale18;
    wire [7:0] scale19;
    wire [7:0] scale20;
    wire [7:0] scale21;
    wire [7:0] scale22;
    wire [7:0] scale23;
    wire [7:0] scale24;
    wire [7:0] scale25;
    wire [7:0] scale26;
    wire [7:0] scale27;


    wire [7:0] scale28;
    wire [7:0] scale29;
    wire [7:0] scale30;
    wire [7:0] scale31;

    rsdec_syn_m0 rsdec_syn_m0_inst (
        scale0,
        y0
    );
    rsdec_syn_m1 rsdec_syn_m1_inst (
        scale1,
        y1
    );
    rsdec_syn_m2 rsdec_syn_m2_inst (
        scale2,
        y2
    );
    rsdec_syn_m3 rsdec_syn_m3_inst (
        scale3,
        y3
    );
    rsdec_syn_m4 rsdec_syn_m4_inst (
        scale4,
        y4
    );
    rsdec_syn_m5 rsdec_syn_m5_inst (
        scale5,
        y5
    );
    rsdec_syn_m6 rsdec_syn_m6_inst (
        scale6,
        y6
    );
    rsdec_syn_m7 rsdec_syn_m7_inst (
        scale7,
        y7
    );
    rsdec_syn_m8 rsdec_syn_m8_inst (
        scale8,
        y8
    );
    rsdec_syn_m9 rsdec_syn_m9_inst (
        scale9,
        y9
    );
    rsdec_syn_m10 rsdec_syn_m10_inst (
        scale10,
        y10
    );
    rsdec_syn_m11 rsdec_syn_m11_inst (
        scale11,
        y11
    );
    rsdec_syn_m12 rsdec_syn_m12_inst (
        scale12,
        y12
    );
    rsdec_syn_m13 rsdec_syn_m13_inst (
        scale13,
        y13
    );
    rsdec_syn_m14 rsdec_syn_m14_inst (
        scale14,
        y14
    );
    rsdec_syn_m15 rsdec_syn_m15_inst (
        scale15,
        y15
    );
    rsdec_syn_m16 rsdec_syn_m16_inst (
        scale16,
        y16
    );
    rsdec_syn_m17 rsdec_syn_m17_inst (
        scale17,
        y17
    );
    rsdec_syn_m18 rsdec_syn_m18_inst (
        scale18,
        y18
    );
    rsdec_syn_m19 rsdec_syn_m19_inst (
        scale19,
        y19
    );
    rsdec_syn_m20 rsdec_syn_m20_inst (
        scale20,
        y20
    );
    rsdec_syn_m21 rsdec_syn_m21_inst (
        scale21,
        y21
    );
    rsdec_syn_m22 rsdec_syn_m22_inst (
        scale22,
        y22
    );
    rsdec_syn_m23 rsdec_syn_m23_inst (
        scale23,
        y23
    );
    rsdec_syn_m24 rsdec_syn_m24_inst (
        scale24,
        y24
    );
    rsdec_syn_m25 rsdec_syn_m25_inst (
        scale25,
        y25
    );
    rsdec_syn_m26 rsdec_syn_m26_inst (
        scale26,
        y26
    );
    rsdec_syn_m27 rsdec_syn_m27_inst (
        scale27,
        y27
    );
    rsdec_syn_m28 rsdec_syn_m28_inst (
        scale28,
        y28
    );
    rsdec_syn_m29 rsdec_syn_m29_inst (
        scale29,
        y29
    );
    rsdec_syn_m30 rsdec_syn_m30_inst (
        scale30,
        y30
    );
    rsdec_syn_m31 rsdec_syn_m31_inst (
        scale31,
        y31
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            y0  <= 0;
            y1  <= 0;
            y2  <= 0;
            y3  <= 0;


            y4  <= 0;
            y5  <= 0;
            y6  <= 0;
            y7  <= 0;
            y8  <= 0;
            y9  <= 0;
            y10 <= 0;
            y11 <= 0;
            y12 <= 0;
            y13 <= 0;
            y14 <= 0;
            y15 <= 0;
            y16 <= 0;
            y17 <= 0;
            y18 <= 0;
            y19 <= 0;
            y20 <= 0;
            y21 <= 0;
            y22 <= 0;
            y23 <= 0;
            y24 <= 0;
            y25 <= 0;
            y26 <= 0;
            y27 <= 0;
            y28 <= 0;
            y29 <= 0;
            y30 <= 0;
            y31 <= 0;
        end else if (init) begin
            y0  <= u;
            y1  <= u;
            y2  <= u;
            y3  <= u;
            y4  <= u;
            y5  <= u;
            y6  <= u;
            y7  <= u;
            y8  <= u;
            y9  <= u;
            y10 <= u;
            y11 <= u;
            y12 <= u;
            y13 <= u;
            y14 <= u;


            y15 <= u;
            y16 <= u;
            y17 <= u;
            y18 <= u;
            y19 <= u;
            y20 <= u;
            y21 <= u;
            y22 <= u;
            y23 <= u;
            y24 <= u;
            y25 <= u;
            y26 <= u;
            y27 <= u;
            y28 <= u;
            y29 <= u;
            y30 <= u;
            y31 <= u;
        end else if (enable) begin
            y0  <= scale0 ^ u;
            y1  <= scale1 ^ u;
            y2  <= scale2 ^ u;
            y3  <= scale3 ^ u;
            y4  <= scale4 ^ u;
            y5  <= scale5 ^ u;
            y6  <= scale6 ^ u;
            y7  <= scale7 ^ u;
            y8  <= scale8 ^ u;
            y9  <= scale9 ^ u;
            y10 <= scale10 ^ u;
            y11 <= scale11 ^ u;
            y12 <= scale12 ^ u;
            y13 <= scale13 ^ u;
            y14 <= scale14 ^ u;
            y15 <= scale15 ^ u;
            y16 <= scale16 ^ u;
            y17 <= scale17 ^ u;
            y18 <= scale18 ^ u;
            y19 <= scale19 ^ u;
            y20 <= scale20 ^ u;
            y21 <= scale21 ^ u;
            y22 <= scale22 ^ u;
            y23 <= scale23 ^ u;
            y24 <= scale24 ^ u;
            y25 <= scale25 ^ u;


            y26 <= scale26 ^ u;
            y27 <= scale27 ^ u;
            y28 <= scale28 ^ u;
            y29 <= scale29 ^ u;
            y30 <= scale30 ^ u;
            y31 <= scale31 ^ u;
        end else if (shift) begin
            y0  <= y1;
            y1  <= y2;
            y2  <= y3;
            y3  <= y4;
            y4  <= y5;
            y5  <= y6;
            y6  <= y7;
            y7  <= y8;
            y8  <= y9;
            y9  <= y10;
            y10 <= y11;
            y11 <= y12;
            y12 <= y13;
            y13 <= y14;
            y14 <= y15;
            y15 <= y16;
            y16 <= y17;
            y17 <= y18;
            y18 <= y19;
            y19 <= y20;
            y20 <= y21;
            y21 <= y22;
            y22 <= y23;
            y23 <= y24;
            y24 <= y25;
            y25 <= y26;
            y26 <= y27;
            y27 <= y28;
            y28 <= y29;
            y29 <= y30;
            y30 <= y31;
            y31 <= y0;
        end
    end

endmodule
