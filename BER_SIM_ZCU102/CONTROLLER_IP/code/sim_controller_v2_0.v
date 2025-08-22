
`timescale 1 ns / 1 ps

	module sim_controller_v2_0 #
	(
		// Users to add parameters here
        parameter integer FRAME_ERROR_STOP_CRITERION = 1000,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4,

		// Parameters of Axi Master Bus Interface M00_AXI
		// parameter  C_M00_AXI_START_DATA_VALUE	= 32'hAA000000,
		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'hC0000000,
		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 32,
		parameter integer C_M00_AXI_TRANSACTIONS_NUM	= 10
	)
	(
		// Users to add ports here
		input wire [63:0] total_bits,
		input wire [63:0] total_bit_errors_pre,
		input wire [63:0] total_bit_errors_post,
        input wire [63:0] total_frames,
		input wire [63:0] total_frame_errors,
		
		output reg en_prbs =0,
		output reg rstn_blocks =0,
		//output wire [31:0] sim_no,
		output wire precode_en,
		output wire [3:0] n_interleave,
		output wire [4:0] max_iterations_2d,  // 5 bits for 0-31 range
		
		output wire [63:0] probability_out,
		output wire [31:0] probability_idx,
		
		//output wire tx_init,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXI
		//input wire  m00_axi_init_axi_txn,
		output wire  m00_axi_error,
		output wire  m00_axi_txn_done,
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [2 : 0] m00_axi_awprot,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [1 : 0] m00_axi_bresp,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [2 : 0] m00_axi_arprot,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready
	);
	
    wire start_req;
    wire stop_req;
    wire report_req;
    
    //reg load_req = 0;
	   
    reg  m00_axi_init_axi_txn = 0;
	
	//assign tx_init = m00_axi_init_axi_txn;
	
	reg [63:0] bits_reg = 0;
	reg [63:0] bit_errors_pre_reg = 0;
	reg [63:0] bit_errors_post_reg  =0;
	reg [63:0] frames_reg = 0;
	reg [63:0] frame_errors_reg = 0;
	
	
	reg [7:0] state = 0;
	   
// Instantiation of Axi Bus Interface S00_AXI
	sim_controller_v2_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) sim_controller_v2_0_S00_AXI_inst (
      
        //.N_FRAMES(n_frames),
		//.N_FRAME_ERRORS(n_frame_errors),
		
		//.EN_PRBS(en_prbs),
		//.RSTN_BLOCKS(rstn_blocks),
		
		.START_REQ(start_req),
		.REPORT_REQ(report_req),
		.STOP_REQ(stop_req),
		//.SIM_NO(sim_no),
		.PRECODE_EN(precode_en),
		.N_INTERLEAVE(n_interleave),
		.MAX_ITERATIONS_2D(max_iterations_2d),
		
		//.LOAD_REQ(load_req),
		.PROBABILITY_OUT(probability_out),
		.PROBABILITY_IDX(probability_idx),
		
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Instantiation of Axi Bus Interface M00_AXI
	sim_controller_v2_0_M00_AXI # ( 
		//.C_M_START_DATA_VALUE(C_M00_AXI_START_DATA_VALUE),
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_TRANSACTIONS_NUM(C_M00_AXI_TRANSACTIONS_NUM)
	) sim_controller_v2_0_M00_AXI_inst (
	   
	   .TOTAL_BITS(bits_reg),
	   .TOTAL_BIT_ERRORS_PRE(bit_errors_pre_reg),
	   .TOTAL_BIT_ERRORS_POST(bit_errors_post_reg),
	   .TOTAL_FRAMES(frames_reg),
	   .TOTAL_FRAME_ERRORS(frame_errors_reg),
	   
		.INIT_AXI_TXN(m00_axi_init_axi_txn),
		.ERROR(m00_axi_error),
		.TXN_DONE(m00_axi_txn_done),
		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);

	// Add user logic here
	
	// this FSM gets reqest to start, report or stop simulation from the axi slave
	// accordingly, it sends enable and reset signals to the BER IP
	// it also sends simulation data to the axi Master to be written to BRAM
	// sim_no and precode settings are directly set by axi slave module, and do not need to be handled here
	// 
	
	
	reg stop_criterion_reached = 0;

	
	always @(posedge m00_axi_aclk) begin
	
	   //waiting for sim to start
	   if (state==0) begin
	   
	       stop_criterion_reached <= 0;
	       en_prbs<=0;
	       rstn_blocks <= 0;
	       
	       
	       //request from slave to start simulation
	       if (start_req == 1) begin
	           //load_req <= 1;
	           en_prbs <=1;
               rstn_blocks<= 1;
	           state <= 1;
	       end
	      
	   //sim is started
	   end else if (state==1) begin
	   
	       if (report_req) begin
	           //send info to axi master and initiate write to bram
	           bits_reg <= total_bits;
	           bit_errors_pre_reg <= total_bit_errors_pre;
	           bit_errors_post_reg <= total_bit_errors_post;
	           frames_reg <= total_frames;
	           frame_errors_reg <= total_frame_errors;
	           m00_axi_init_axi_txn <= 1;
	           state <= 2;
                  
	       end else if (stop_req) begin
	           //send info to axi master and initiate write to bram
               state <= 3;
	           bits_reg <= total_bits;
	           bit_errors_pre_reg <= total_bit_errors_pre;
	           bit_errors_post_reg <= total_bit_errors_post;
	           frames_reg <= total_frames;
	           frame_errors_reg <= total_frame_errors;
	           m00_axi_init_axi_txn <= 1;
                      
          //automatically report sim status when more than 1000 frame errors, but only do it once per simulation and keep sim running
	       end else if (total_frame_errors >= FRAME_ERROR_STOP_CRITERION && stop_criterion_reached == 0) begin
	       
	           //send info to axi master and initiate write to bram
	           stop_criterion_reached <= 1;
	           state <= 2;
	           bits_reg <= total_bits;
	           bit_errors_pre_reg <= total_bit_errors_pre;
	           bit_errors_post_reg <= total_bit_errors_post;
	           frames_reg <= total_frames;
	           frame_errors_reg <= total_frame_errors;
	           m00_axi_init_axi_txn <= 1;
            end	       
	       
	   //end tx pulse and keep sim running
	   end else if (state == 2) begin
	       m00_axi_init_axi_txn <= 0;
	       state <= 1;
       
       //end tx pulse and reset simulation
       end else if (state == 3) begin
           m00_axi_init_axi_txn <= 0;
           state <= 0;
       end
       
       
       
       
    end

	// User logic ends

	endmodule

