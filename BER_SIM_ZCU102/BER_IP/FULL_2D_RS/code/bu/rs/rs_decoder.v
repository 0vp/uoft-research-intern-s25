module rs_decoder (
    x,
    error,
    with_error,
    enable,
    valid,
    k,
    clk,
    rst_n
);
    input enable, clk, rst_n;
    input [7:0] k, x;
    output [7:0] error;
    wire [7:0] error;
    output with_error, valid;
    reg with_error, valid;

    wire [7:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, 
s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31;
    wire [7:0] lambda, omega, alpha;
    reg [ 5:0] count;
    reg [32:0] phase;
    wire [7:0] D0, D1, DI;
    reg [7:0] D, D2;
    reg [7:0] u, length0, length1, length2, length3;
    reg syn_enable, syn_init, syn_shift, berl_enable;
    reg chien_search, chien_load, shorten;

    always @(chien_search or shorten) valid = chien_search & ~shorten;

    rsdec_syn rsdec_syn_inst (
        s0,
        s1,
        s2,
        s3,
        s4,
        s5,
        s6,
        s7,
        s8,
        s9,
        s10,
        s11,
        s12,
        s13,
        s14,
        s15,
        s16,
        s17,
        s18,
        s19,
        s20,
        s21,
        s22,
        s23,
        s24,
        s25,
        s26,
        s27,
        s28,
        s29,
        s30,
        s31,
        u,
        syn_enable,
        syn_shift & phase[0],
        syn_init,
        clk,
        rst_n
    );
    rsdec_berl rsdec_berl_inst (
        lambda,
        omega,
        s0,
        s31,
        s30,
        s29,
        s28,
        s27,
        s26,
        s25,
        s24,
        s23,
        s22,
        s21,
        s20,
        s19,
        s18,
        s17,
        s16,
        s15,
        s14,
        s13,
        s12,
        s11,
        s10,
        s9,
        s8,
        s7,
        s6,
        s5,
        s4,
        s3,
        s2,
        s1,
        D0,
        D2,
        count,
        phase[0],
        phase[32],
        berl_enable,
        clk,
        rst_n
    );
    rsdec_chien rsdec_chien_inst (
        error,
        alpha,
        lambda,
        omega,
        D1,
        DI,
        chien_search,
        chien_load,
        shorten,
        clk,
        rst_n
    );
    inverse inverse_inst (
        DI,
        D
    );

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            syn_enable <= 0;
            syn_shift <= 0;
            berl_enable <= 0;
            chien_search <= 1;
            chien_load <= 0;


            length0 <= 0;
            length2 <= 255 - k;
            count <= -1;
            phase <= 1;
            u <= 0;
            shorten <= 1;
            syn_init <= 0;
        end else begin
            if (enable & ~syn_enable & ~syn_shift) begin
                syn_enable <= 1;
                syn_init   <= 1;
            end
            if (syn_enable) begin
                length0  <= length1;
                syn_init <= 0;
                if (length1 == k) begin
                    syn_enable  <= 0;
                    syn_shift   <= 1;
                    berl_enable <= 1;
                end
            end
            if (berl_enable & with_error) begin
                if (phase[0]) begin
                    count <= count + 1;
                    if (count == 31) begin
                        syn_shift <= 0;
                        length0 <= 0;
                        chien_load <= 1;
                        length2 <= length0;
                    end
                end
                phase <= {phase[31:0], phase[32]};
            end
            if (berl_enable & ~with_error)
                if (&count) begin
                    syn_shift <= 0;
                    length0 <= 0;


                    berl_enable <= 0;
                end else phase <= {phase[31:0], phase[32]};
            if (chien_load & phase[32]) begin
                berl_enable <= 0;
                chien_load <= 0;
                chien_search <= 1;
                count <= -1;
                phase <= 1;
            end
            if (chien_search) begin
                length2 <= length3;
                if (length3 == 0) chien_search <= 0;
            end
            if (enable) u <= x;
            if (shorten == 1 && length2 == 0) shorten <= 0;
        end

    end

    always @(chien_search or D0 or D1)
        if (chien_search) D = D1;
        else D = D0;

    always @(DI or alpha or chien_load)
        if (chien_load) D2 = alpha;
        else D2 = DI;

    always @(length0) length1 = length0 + 1;
    always @(length2) length3 = length2 - 1;
    always @ (syn_shift or s0 or s1 or s2 or s3 or s4 or s5 or s6 or s7 or s8 or s9  or s10 or s11 
or s12 or s13 or s14 or s15 or s16 or s17 or s18 or s19 or s20 or s21 or s22 or s23 or s24 or s25 or 
s26 or s27 or s28 or s29 or s30 or s31)
        if (syn_shift && (s0 | s1 | s2 | s3 | s4 | s5 | s6 | s7 | s8 | s9 | s10 | s11 | s12 | s13 | s14 
| s15 | s16 | s17 | s18 | s19 | s20 | s21 | s22 | s23 | s24 | s25 | s26 | s27 | s28 | s29 | s30 | s31)!= 0)
            with_error = 1;
        else with_error = 0;

endmodule
