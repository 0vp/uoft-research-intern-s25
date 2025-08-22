module rs_encoder (
    clk,
    rst_n,
    din,
    din_en,
    din_syn,
    dout,
    dout_en,
    dout_syn
);
    input wire clk;  // clock input  
    input wire rst_n;  // active low asynchronous reset  
    input wire [7:0] din;  // data input  
    input wire din_en;  // data input valid  
    input wire din_syn;  // synchronous for counter  
    output wire dout_en;
    output wire dout_syn;
    output wire [7:0] dout;  // data output  
    //g(X) = 45+216X+239X2 +24X3 +253X4 +104X5 +27X6 +40X7 +107X8 +50X9 +163X1 0 +210X11  
    //      +227X12 +134X13 +224X14 +158X15 +119X16 +13X17 +158X18 +X19 +238X20 +164X21  
    //      +82X22 +43X23 +15X24 +232X25 +246X26 +142X27 +50X28 +189X29 +29X32 +232X31 +X32  

    reg [7:0] cnt_255;

    // declaration of shift regis ters 
    reg [7:0] shift0;
    reg [7:0] shift1;
    reg [7:0] shift2;
    reg [7:0] shift3;
    reg [7:0] shift4;
    reg [7:0] shift5;
    reg [7:0] shift6;
    reg [7:0] shift7;
    reg [7:0] shift8;
    reg [7:0] shift9;
    reg [7:0] shift10;
    reg [7:0] shift11;
    reg [7:0] shift12;
    reg [7:0] shift13;
    reg [7:0] shift14;
    reg [7:0] shift15;
    reg [7:0] shift16;
    reg [7:0] shift17;
    reg [7:0] shift18;
    reg [7:0] shift19;
    reg [7:0] shift20;
    reg [7:0] shift21;
    reg [7:0] shift22;


    reg [7:0] shift23;
    reg [7:0] shift24;
    reg [7:0] shift25;
    reg [7:0] shift26;
    reg [7:0] shift27;
    reg [7:0] shift28;
    reg [7:0] shift29;
    reg [7:0] shift30;
    reg [7:0] shift31;

    reg [7:0] xor_feedback;  // xor feedback from shift registers  


    wire          [7:0]             g0_a18_mul45;                                 // coefficient g0  of the generator polynomial multiply with feedback  
    wire          [7:0]             g1_a251_mul216;                               // coefficient g1  of the generator polynomial multiply with feedback  
    wire          [7:0]             g2_a215_mul239;                               // coefficient g2  of the generator polynomial multiply with feedback  
    wire          [7:0]             g3_a28_mul24;                                 // coefficient g3  of the generator polynomial multiply with feedback  
    wire          [7:0]             g4_a80_mul253;                                // coefficient g4  of the generator polynomial multiply with feedback  
    wire          [7:0]             g5_a107_mul104;                               // coefficient g5  of the generator polynomial multiply with feedback  
    wire          [7:0]             g6_a248_mul27;                                // coefficient g6  of the generator polynomial multiply with feedback  
    wire          [7:0]             g7_a53_mul40;                                 // coefficient g7  of the generator polynomial multiply with feedback  
    wire          [7:0]             g8_a84_mul107;                                // coefficient g8  of the generator polynomial multiply with feedback  
    wire          [7:0]             g9_a194_mul50;                                // coefficient g9  of the  generator polynomial multiply with feedback  
    wire          [7:0]             g10_a91_mul163;                               // coefficient g10 of the generator polynomial multiply with feedback  
    wire          [7:0]             g11_a59_mul210;                               // coefficient g11 of the generator polynomial multiply with feedback  
    wire          [7:0]             g12_a176_mul227;                              // coefficient g12 of the generator polynomial multiply with feedback  
    wire          [7:0]             g13_a99_mul134;                               // coefficient g13 of the generator polynomial multiply with feedback  
    wire          [7:0]             g14_a203_mul224;                              // coefficient g14 of the generator polynomial multiply with feedback  
    wire          [7:0]             g15_a137_mul158;                              // coefficient g15 of the generator polynomial multiply with feedback  
    wire          [7:0]             g16_a43_mul119;                               // coefficient g16 of the generator polynomial multiply with feedback  
    wire          [7:0]             g17_a104_mul13;                               // coefficient g17 of the generator polynomial multiply with feedback  
    wire          [7:0]             g18_a137_mul158;                              // coefficient g18 of the generator polynomial multiply with feedback  
    wire [7:0] g19_a0_mul1;  // coefficient g19 of the generator polynomial multiply with feedback  
    wire          [7:0]             g20_a44_mul238;                               // coefficient g20 of the generator polynomial multiply with feedback  
    wire          [7:0]             g21_a149_mul164;                              // coefficient g21 of the generator polynomial multiply with feedback  
    wire          [7:0]             g22_a148_mul82;                               // coefficient g22 of the generator polynomial multiply with feedback  
    wire          [7:0]             g23_a218_mul43;                               // coefficient g23 of the generator polynomial multiply with feedback  
    wire          [7:0]             g24_a75_mul15;                                // coefficient g24 of the generator polynomial multiply with feedback  
    wire          [7:0]             g25_a11_mul232;                               // coefficient g25 of the generator polynomial multiply with feedback  
    wire          [7:0]             g26_a173_mul246;                              // coefficient g26  of the generator polynomial multiply with feedback  
    wire          [7:0]             g27_a254_mul142;                              // coefficient g27 of the generator polynomial multiply with feedback  
    wire          [7:0]             g28_a194_mul50;                               // coefficient g28 of the generator polynomial multiply with feedback  
    wire          [7:0]             g29_a109_mul189;                              // coefficient g29 of the generator polynomial multiply with feedback  
    wire          [7:0]             g30_a8_mul29;                                 // coefficient g30 of the generator polynomial multiply with feedback  
    wire          [7:0]             g31_a11_mul232;                               // coefficient g31 of the generator polynomial multiply with feedback  


    // multiple xor_feedback with 45: g0  
    assign g0_a18_mul45[7] = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g0_a18_mul45[6] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[5];
    assign g0_a18_mul45[5] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4];
    assign g0_a18_mul45[4] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3];
    assign g0_a18_mul45[3]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g0_a18_mul45[2] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[6];


    assign g0_a18_mul45[1] = xor_feedback[1] ^ xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g0_a18_mul45[0]  = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];

    // multiple xor_feedback with 216: g1  
    assign g1_a251_mul216[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4];
    assign g1_a251_mul216[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[7];
    assign g1_a251_mul216[5] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[6];
    assign g1_a251_mul216[4] = xor_feedback[1] ^ xor_feedback[5];
    assign g1_a251_mul216[3] = xor_feedback[1] ^ xor_feedback[2];
    assign g1_a251_mul216[2] = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[7];
    assign g1_a251_mul216[1]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6];
    assign g1_a251_mul216[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5];

    // multiple xor_feedback with 239: g2  
    assign g2_a215_mul239[7 ]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[6];
    assign g2_a215_mul239[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g2_a215_mul239[5]  = xor_feedback[ 0] ^ xor_feedback[1] ^ xor_feedback[4] ^ 
xor_feedback[6];
    assign g2_a215_mul239[4] = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[5];
    assign g2_a215_mul239[3]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[ 6];
    assign g2_a215_mul239[2]  = xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g2_a215_mul239[1]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5];
    assign g2_a215_mul239[0]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[7];

    // multiple xor_feedback with 24: g3  
    assign g3_a28_mul24[7] = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[7];
    assign g3_a28_mul24[6] = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[6];
    assign g3_a28_mul24[5] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[5];
    assign g3_a28_mul24[4] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[4] ^ xor_feedback[7];
    assign g3_a28_mul24[3] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g3_a28_mul24[2] = xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];


    assign g3_a28_mul24[1] = xor_feedback[5] ^ xor_feedback[6];
    assign g3_a28_mul24[0] = xor_feedback[4] ^ xor_feedback[5];

    // multiple xor_feedback with 253: g4  
    assign g4_a80_mul253[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g4_a80_mul253[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g4_a80_mul253[5]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g4_a80_mul253[4]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g4_a80_mul253[3] = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[7];
    assign g4_a80_mul253[2] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g4_a80_mul253[1]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g4_a80_mul253[0]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];

    // multiple xor_feedback with 104: g5  
    assign g5_a107_mul104[7]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5];
    assign g5_a107_mul104[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4];
    assign g5_a107_mul104[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[7];
    assign g5_a107_mul104[4]  = xor_feedback[1 ] ^ xor_feedback[2] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g5_a107_mul104[3]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g5_a107_mul104[2]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g5_a107_mul104[1]  = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g5_a107_mul104[0]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[6];

    // multiple xor_feedback with 27: g6  
    assign g6_a248_mul27[7] = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g6_a248_mul27[6] = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[5];
    assign g6_a248_mul27[5] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4];
    assign g6_a248_mul27[4] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3];
    assign g6_a248_mul27[3]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6];


    assign g6_a248_mul27[2]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g6_a248_mul27[1] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g6_a248_mul27[0] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];

    // multiple xor_feedback with 40: g7  
    assign g7_a53_mul40[7] = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g7_a53_mul40[6] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g7_a53_mul40[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g7_a53_mul40[4]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g7_a53_mul40[3]  = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g7_a53_mul40[2] = xor_feedback[3];
    assign g7_a53_mul40[1] = xor_feedback[4] ^ xor_feedback[6];
    assign g7_a53_mul40[0] = xor_feedback[3] ^ xor_feedback[5] ^ xor_feedback[7];

    // multiple xor_feedback with 107: g8  
    assign g8_a84_mul107[7]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g8_a84_mul107[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g8_a84_mul107[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g8_a84_mul107[4]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6];
    assign g8_a84_mul107[3] = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g8_a84_mul107[2] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g8_a84_mul107[1]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g8_a84_mul107[0]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];

    // multiple xor_feedback with 50: g9  
    assign g9_a194_mul50[7] = xor_feedback[2] ^ xor_feedback[3];
    assign g9_a194_mul50[6] = xor_feedback[1] ^ xor_feedback[2];
    assign g9_a194_mul50[5] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[7];
    assign g9_a194_mul50[4] = xor_feedback[0] ^ xor_feedback[6] ^ xor_feedback[7];


    assign g9_a194_mul50[3]  = xor_feedback[2] ^ xor_feedback[3] ^  xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g9_a194_mul50[2]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g9_a194_mul50[1] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[5];
    assign g9_a194_mul50[0] = xor_feedback[3] ^ xor_feedback[4];

    // multiple xor_feedback with 163: g10  
    assign g10_a91_mul163[7]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g10_a91_mul163[6]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g10_a91_mul163[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6];
    assign g10_a91_mul163[4]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5];
    assign g10_a91_mul163[3] = xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g10_a91_mul163[2] = xor_feedback[2] ^ xor_feedback[6];
    assign g10_a91_mul163[1]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g10_a91_mul163[0]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];

    // multiple xor_feedback with 210: g1 1 
    assign g11_a59_mul210[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[6];
    assign g11_a59_mul210[6]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g11_a59_mul210[5]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g11_a59_mul210[4]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g11_a59_mul210[3]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g11_a59_mul210[2]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[6];
    assign g11_a59_mul210[1]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g11_a59_mul210[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];

    // multiple xor_feedback with 227: g12  
    assign g12_a176_mul227[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[7];
    assign g12_a176_mul227[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[6] ^ xor_feedback[7];


    assign g12_a176_mul227[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5] ^ 
xor_feedback[6];
    assign g12_a176_mul227[4] = xor_feedback[1] ^ xor_feedback[4] ^ xor_feedback[5];
    assign g12_a176_mul227[3] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3];
    assign g12_a176_mul227[2] = xor_feedback[4] ^ xor_feedback[7];
    assign g12_a176_mul227[1]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g12_a176_mul227[0]  = xor_feedback[0] ^ xor_feedback[1] ^  xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[5];

    // multiple xor_feedback with 134: g13  
    assign g13_a99_mul134[7] = xor_feedback[0] ^ xor_feedback[4];
    assign g13_a99_mul134[6] = xor_feedback[3];
    assign g13_a99_mul134[5] = xor_feedback[2] ^ xor_feedback[7];
    assign g13_a99_mul134[4] = xor_feedback[1] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g13_a99_mul134[3] = xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6];
    assign g13_a99_mul134[2]  = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[7];
    assign g13_a99_mul134[1] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[6];
    assign g13_a99_mul134[0] = xor_feedback[1] ^ xor_feedback[5];

    // multiple xor_feedback with 224: g14  
    assign g14_a203_mul224[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[6];
    assign g14_a203_mul224[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g14_a203_mul224[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[6];
    assign g14_a203_mul224[4]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[7];
    assign g14_a203_mul224[3] = xor_feedback[1] ^ xor_feedback[7];
    assign g14_a203_mul224[2] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4];
    assign g14_a203_mul224[1]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[6];
    assign g14_a203_mul224[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[7];

    // multiple xor_feedback with 158: g15  
    assign g15_a137_mul158[7] = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[7];
    assign g15_a137_mul158[6] = xor_feedback[2] ^ xor_feedback[6];
    assign g15_a137_mul158[5] = xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g15_a137_mul158[4] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g15_a137_mul158[3] = xor_feedback[0] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g15_a137_mul158[2]  = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[6];
    assign g15_a137_mul158[1] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5];


    assign g15_a137_mul158[0] = xor_feedback[1] ^ xor_feedback[4];

    // mu ltiple xor_feedback with 119: g16  
    assign g16_a43_mul119[7]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[6];
    assign g16_a43_mul119[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[5];
    assign g16_a43_mul119[5] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[4];
    assign g16_a43_mul119[4] = xor_feedback[0] ^ xor_feedback[3];
    assign g16_a43_mul119[3] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[6];
    assign g16_a43_mul119[2]  = xor_feedback[0]  ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g16_a43_mul119[1]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5];
    assign g16_a43_mul119[0]  = xor_feedback[0]  ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[7];

    // multiple xor_feedback with 13: g17  
    assign g17_a104_mul13[7] = xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g17_a104_mul13[6]  = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g17_a104_mul13[5]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[6];
    assign g17_a104_mul13[4]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5];
    assign g17_a104_mul13[3]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g17_a104_mul13[2]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g17_a104_mul13[1] = xor_feedback[1] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g17_a104_mul13[0] = xor_feedback[0] ^ xor_feedback[5] ^ xor_feedback[6];

    // multiple xor_feedback with 158: g18  
    assign g18_a137_mul158 = g15_a137_mul158;

    // multiple xor_feedback with 1: g19  
    assign g19_a0_mul1 = xor_feedback;

    // multiple xor_feedback with 238: g20  
    assign g20_a44_mul238[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[5];
    assign g20_a44_mul238[6] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[4];
    assign g20_a44_mul238[5] = xor_feedback[0] ^ xor_feedback[3];
    assign g20_a44_mul238[4] = xor_feedback[2];
    assign g20_a44_mul238[3]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5] ^ 
xor_feedback[7];
    assign g20_a44_mul238[2]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g20_a44_mul238[1]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[7];
    assign g20_a44_mul238[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[6];

    // multiple xor_feedback with 164: g21  
    assign g21_a149_mul164[7]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[7] ;
    assign g21_a149_mul164[6]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g21_a149_mul164[5]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g21_a149_mul164[4]  = xor_feedback[1] ^ xor_feedback[4] ^ xor_feedback[5] ^ 
xor_feedback[6];
    assign g21_a149_mul164[3] = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[5];
    assign g21_a149_mul164[2] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[7];
    assign g21_a149_mul164[1] = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g21_a149_mul164[0] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[5];

    // multiple xor_feedback with 82: g22  
    assign g22_a148_mul82[7] = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[5];
    assign g22_a148_mul82[6]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[7];
    assign g22_a148_mul82[5]  = xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g22_a148_mul82[4]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g22_a148_mul82[3] = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign g22_a148_mul82[2] = xor_feedback[1] ^ xor_feedback[2];
    assign g22_a148_mul82[1]  = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[5] ^ 
xor_feedback[7];
    assign g22_a148_mul82[0] = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[6];

    // multiple xor_feedback with 43: g23  
    assign g23_a218_mul43[7] = xor_feedback[2] ^ xor_feedback[4];
    assign g23_a218_mul43[6] = xor_feedback[1] ^ xor_feedback[3];
    assign g23_a218_mul43[5] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[7];
    assign g23_a218_mul43[4] = xor_feedback[1] ^ xor_feedback[6];
    assign g23_a218_mul43[3]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5];
    assign g23_a218_mul43[2]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[7];
    assign g23_a218_mul43[1]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[4] ^ 
xor_feedback[6];


    assign g23_a218_mul43[0] = xor_feedback[0] ^ xor_feedback[3] ^ xor_feedback[5];

    // multiple xor_feedback with 15: g24  
    assign g24_a75_mul15[7] = xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g24_a75_mul15[6]  = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g24_a75_mul15[5]  = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g24_a75_mul15[4]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g24_a75_mul15[3]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[5];
    assign g24_a75_mul15[2]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[5] ^ xor_feedback[6];
    assign g24_a75_mul15[1] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g24_a75_mul15[0] = xor_feedback[0] ^ xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];

    // multiple xor_feedback with 232: g25  
    assign g25_a11_mul232[7]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[6];
    assign g25_a11_mul232[6] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[5];
    assign g25_a11_mul232[5] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[7];
    assign g25_a11_mul232[4] = xor_feedback[3] ^ xor_feedback[6];
    assign g25_a11_mul232[3]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g25_a11_mul232[2]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g25_a11_mul232[1] = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4];
    assign g25_a11_mul232[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[7];

    // multiple xor_feedback with 246: g26  
    assign g26_a173_mul246[7]  = xor_feedback[0]  ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[7];
    assign g26_a173_mul246[6]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[6];
    assign  g26_a173_mul246[5]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[3] ^ xor_feedback[5];
    assign g26_a173_mul246[4]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[7];
    assign g26_a173_mul246[3]  = xor_feedback[2] ^ xor_feedback[4] ^ xor_feedback[5] ^ 
xor_feedback[6];
    assign g26_a173_mul246[2] = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[7];


    assign g26_a173_mul246[1]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g26_a173_mul246[0]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6];

    // multiple xor_feedback with 142: g27  
    assign g27_a254_mul142[7] = xor_feedback[0];
    assign g27_a254_mul142[6] = xor_feedback[7];
    assign g27_a254_mul142[5] = xor_feedback[6];
    assign g27_a254_mul142[4] = xor_feedback[5];
    assign g27_a254_mul142[3] = xor_feedback[0] ^ xor_feedback[4];
    assign g27_a254_mul142[2] = xor_feedback[0] ^ xor_feedback[3];
    assign g27_a254_mul142[1] = xor_feedback[0] ^ xor_feedback[2];
    assign g27_a254_mul142[0] = xor_feedback[1];

    // multiple xor_feedback with 50: g28  
    assign g28_a194_mul50 = g9_a194_mul50;

    // multiple xor_feedback with 189: g29  
    assign g29_a109_mul189[7]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[3] ^ 
xor_feedback[7];
    assign g29_a109_mul189[6]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[6] ^ 
xor_feedback[7];
    assign g29_a109_mul189[5]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g29_a109_mul189[4]  = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[5] ^ 
xor_feedback[6] ^ xor_feedback[7];
    assign g29_a109_mul189[3]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g29_a109_mul189[2]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ 
xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6] ;
    assign g29_a109_mul189[1]  = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5];
    assign g29_a109_mul189[0]  = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ 
xor_feedback[4];

    // multiple xor_feedback with 29: g30  
    assign g30_a8_mul29[7] = xor_feedback[3] ^ xor_feedback[4] ^ xor_feedback[5];
    assign g30_a8_mul29[6] = xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[4];
    assign g30_a8_mul29[5] = xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[3] ^ xor_feedback[7];
    assign g30_a8_mul29[4] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[2] ^ xor_feedback[6];
    assign g30_a8_mul29[3] = xor_feedback[0] ^ xor_feedback[1] ^ xor_feedback[3] ^ xor_feedback[4];


    assign g30_a8_mul29[2]  = xor_feedback[0] ^ xor_feedback[2] ^ xor_feedback[4] ^ 
xor_feedback[5] ^ xor_feedback[7];
    assign g30_a8_mul29[1] = xor_feedback[1] ^ xor_feedback[5] ^ xor_feedback[6] ^ xor_feedback[7];
    assign g30_a8_mul29[0] = xor_feedback[0] ^ xor_feedback[4] ^ xor_feedback[5] ^ xor_feedback[6];

    // multiple xor_feedback with 29: g31  
    assign g31_a11_mul232 = g25_a11_mul232;

    //-------------------------------------------------------------------------  
    // process for counter  
    //---------------------------------------------------------------------- --- 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_255 <= 8'd0;
        end else if (din_en) begin
            if (din_syn) cnt_255 <= 8'd0;
            else begin
                cnt_255 <= (cnt_255 < 8'd255) ? (cnt_255 + 1'b1) : 8'd0;
            end
        end else begin
            cnt_255 <= cnt_255;
        end
    end

    //-------------------------------------------------------------------------  
    // process for shift register  
    //-------------------------------------------------------------------------  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift0  <= 8'd0;
            shift1  <= 8'd0;
            shift2  <= 8'd0;
            shift3  <= 8'd0;
            shift4  <= 8'd0;
            shift5  <= 8'd0;
            shift6  <= 8'd0;
            shift7  <= 8'd0;
            shift8  <= 8'd0;
            shift9  <= 8'd0;
            shift10 <= 8'd0;
            shift11 <= 8'd0;


            shift12 <= 8'd0;
            shift13 <= 8'd0;
            shift14 <= 8'd0;
            shift15 <= 8'd0;
            shift16 <= 8'd0;
            shift17 <= 8'd0;
            shift18 <= 8'd0;
            shift19 <= 8'd0;
            shift20 <= 8'd0;
            shift21 <= 8'd0;
            shift22 <= 8'd0;
            shift23 <= 8'd0;
            shift24 <= 8'd0;
            shift25 <= 8'd0;
            shift26 <= 8'd0;
            shift27 <= 8'd0;
            shift28 <= 8'd0;
            shift29 <= 8'd0;
            shift30 <= 8'd0;
            shift31 <= 8'd0;
        end else if (din_en) begin
            shift0  <= g0_a18_mul45;
            shift1  <= shift0 ^ g1_a251_mul216;
            shift2  <= shift1 ^ g2_a215_mul239;
            shift3  <= shift2 ^ g3_a28_mul24;
            shift4  <= shift3 ^ g4_a80_mul253;
            shift5  <= shift4 ^ g5_a107_mul104;
            shift6  <= shift5 ^ g6_a248_mul27;
            shift7  <= shift6 ^ g7_a53_mul40;
            shift8  <= shift7 ^ g8_a84_mul107;
            shift9  <= shift8 ^ g9_a194_mul50;
            shift10 <= shift9 ^ g10_a91_mul163;
            shift11 <= shift10 ^ g11_a59_mul210;
            shift12 <= shift11 ^ g12_a176_mul227;
            shift13 <= shift12 ^ g13_a99_mul134;
            shift14 <= shift13 ^ g14_a203_mul224;
            shift15 <= shift14 ^ g15_a137_mul158;
            shift16 <= shift15 ^ g16_a43_mul119;
            shift17 <= shift16 ^ g17_a104_mul13;
            shift18 <= shift17 ^ g18_a137_mul158;
            shift19 <= shift18 ^ g19_a0_mul1;
            shift20 <= shift19 ^ g20_a44_mul238;
            shift21 <= shift20 ^ g21_a149_mul164;
            shift22 <= shift21 ^ g22_a148_mul82;
            shift23 <= shift22 ^ g23_a218_mul43;


            shift24 <= shift23 ^ g24_a75_mul15;
            shift25 <= shift24 ^ g25_a11_mul232;
            shift26 <= shift25 ^ g26_a173_mul246;
            shift27 <= shift26 ^ g27_a254_mul142;
            shift28 <= shift27 ^ g28_a194_mul50;
            shift29 <= shift28 ^ g29_a109_mul189;
            shift30 <= shift29 ^ g30_a8_mul29;
            shift31 <= shift30 ^ g31_a11_mul232;
        end
    end
    assign dout = (cnt_255 < 8'd224) ? din : shift31;
    assign dout_en = din_en;
    assign dout_syn = din_syn;

    //-------------------------------------------------------------------------  
    // process for shift register  
    //-------------------------------------------------------------------------  
    always @(din or shift15) begin
        xor_feedback = (cnt_255 > 8'd223) ? 8'd0 : din ^ shift31;
    end

endmodule
