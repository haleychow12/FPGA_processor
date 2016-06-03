//  Model for the FPGA on the Nexys 4 board
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module is the top-level of the FPGA which will contain the processor.
// It contains mainly routing and pad-manipulation stuff.  The real work
// is done inside the modules which it instantiates
//
// WARNINGs: 1) Do not change the ports unless you are really, really sure 
//              about what you are doing.
//	         2) You probably will not need to change any code until
//              you get to the line where it says you should start work...
 
module proc_fpga(
  clk,reset,
  buttons,
  switches, // 16 DIP switches
  leds, // 16 LEDs
  ssds, // 8 seven-segment-displays
  vga_hs, vga_vs, vga_r, vga_g, vga_b, // add vga stuff
  ps2_clk, ps2_data
  );

  // clock and reset
  input clk;
  input reset;

  // connectors
  input [4:0] buttons;
  input [15:0] switches;
  output [15:0] leds;
  output [15:0] ssds;
  output [3:0] vga_r;
  output [3:0] vga_g;
  output [3:0] vga_b;
  output vga_hs;
  output vga_vs;
  input ps2_clk;
  input ps2_data;



  // ***************** Special clock and reset nonsense ************
	wire rst_l = reset;

  // ************ Even more special "simulation" nonsense ********/
  // * DO NOT CHANGE THIS!!!! *
  // This wire can be forced by the testbench to speed up dividers
  // for simulation...
  wire in_sim = 0;

  // ********************* PBus signals **************************/

	wire [15:1] PBusAddr, PBusAddrCOP, PBusAddrCPU;
	wire [15:0] PBusData, PBusDataCOP, PBusDataCPU;
	wire [1:0] PBusReq, PBusReqCOP, PBusReqCPU;
	wire [1:0] PBusBE, PBusBECOP, PBusBECPU;
	wire PBusASpace, PBusASpaceCOP, PBusASpaceCPU;
	wire PBusGntCOP, PBusGntCPU;

	wire [15:0] PBusDataIO, PBusDataEROM,
		    PBusDataIROM, PBusDataERAM, PBusDataIRAM,
        PBusDataKEYB, PBusDataMONI;
	wire PBusRdy, PBusRdyIO, PBusRdyCPU, PBusRdyEROM, 
	     PBusRdyIROM, PBusRdyERAM, PBusRdyIRAM,
       PBusRdyKEYB, PBusRdyMONI;

	// AND together all the rdy signals	
	assign PBusRdy = PBusRdyIO & PBusRdyCPU & PBusRdyEROM &
		         PBusRdyIROM & PBusRdyERAM & PBusRdyIRAM &
             PBusRdyKEYB & PBusRdyMONI;

	assign PBusRdyEROM = 1'b1;
	assign PBusRdyERAM = 1'b1;

  // ********************** PBus arbiter **************************/

	wire PBus_going;   // is someone granted the bus?
	reg PBus_grantee; // who is it? 1 = COP, 0 = CPU

	wire [1:0] PBusReqToMONI = (!PBusASpace && PBusAddr[15:14] == 2'h3)
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToKEYB = (!PBusASpace && PBusAddr[15:12] == 4'hb)
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToERAM = (!PBusASpace && PBusAddr[15:12] >= 4'h4 && PBusAddr[15:12] <= 4'ha) 
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToEROM = (!PBusASpace && PBusAddr[15:13] == 3'h1) 
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToIRAM = (!PBusASpace && PBusAddr[15:12] == 4'h1) 
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToIROM = (!PBusASpace && PBusAddr[15:11] == 5'h00) 
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToIO = (!PBusASpace && PBusAddr[15:11] == 5'h01) 
					? PBusReq : 2'b00;
	wire [1:0] PBusReqToCPU = PBusASpace ? PBusReq : 2'b00;

	assign PBusReq = ~PBus_going ? 2'b0 : 
		(PBus_grantee ? PBusReqCOP : PBusReqCPU);

	assign PBusAddr = PBus_grantee ? PBusAddrCOP : PBusAddrCPU;
	assign PBusData = (PBus_going & PBusReq[1]) ? // read?
		(PBusASpace ? PBusDataCPU : 
		 PBusReqToERAM ? PBusDataERAM :
		   PBusReqToEROM ? PBusDataEROM :
		     PBusReqToIRAM ? PBusDataIRAM :
		       PBusReqToIROM ? PBusDataIROM : 
             PBusReqToKEYB ? PBusDataKEYB :
               PBusReqToMONI ? PBusDataMONI : PBusDataIO
		) : // targets
		(PBus_grantee ? PBusDataCOP : PBusDataCPU); // masters
	assign PBusBE = PBus_grantee ? PBusBECOP : PBusBECPU;
	assign PBusASpace = PBus_grantee ? PBusASpaceCOP : PBusASpaceCPU;

	assign PBusGntCOP = PBus_grantee & PBus_going;
	assign PBusGntCPU = ~PBus_grantee & PBus_going;

	// state machine for PBus access
       `define PBUS_IDLE 2'b00
       `define PBUS_DEAD 2'b01
       `define PBUS_WAIT 2'b10

	reg [1:0] pbus_state;
	assign PBus_going = (pbus_state == `PBUS_DEAD || 
			     pbus_state == `PBUS_WAIT);
	// basically we give the bus to COP whenever it wants it.
	always @(posedge clk or negedge rst_l) begin
	  if (~rst_l) begin
	    pbus_state <= `PBUS_IDLE;
	    PBus_grantee <= 0;
	  end else begin
	    case (pbus_state) 
	    `PBUS_IDLE : 
		if (PBusReqCOP[0] || PBusReqCPU[0] ) begin
		  PBus_grantee <= #1 PBusReqCOP[0];
		  pbus_state <= #1 `PBUS_DEAD;
		end
	    `PBUS_DEAD :
		pbus_state <= #1 `PBUS_WAIT;
	    `PBUS_WAIT :
		if (PBusRdy) pbus_state <= #1 `PBUS_IDLE;
	    endcase
	  end
	end

  // ********************** The IO controller *********************/

  // Interface with COP
  wire [15:0] switchesCOP;
  wire [4:0] buttonsCOP;
  wire [15:0] ledsCOP;
  wire [31:0] ssdsCOP;

	iocontrol IOCNTL (
		.clk(clk),
		.rst_l(rst_l),
		.in_sim(in_sim),
		.output_override(output_override),

		.i_switches(switches),
		.i_buttons(buttons),
		.o_leds(leds),
		.o_ssds(ssds),

    // To COP
		.switchesCOP(switchesCOP),
		.buttonsCOP(buttonsCOP),
    // From COP
    .ledsCOP(ledsCOP),
    .ssdsCOP(ssdsCOP),

		.PBusAddr(PBusAddr[5:1]),
		.PBusDataIn(PBusData),
		.PBusDataOut(PBusDataIO),
		.PBusReq(PBusReqToIO),
		.PBusBE(PBusBE),
		.PBusRdy(PBusRdyIO)
		);

  // ********************** The VGA controller *********************/
   
  mmiocontrol MMIO (
    .clk(clk), 
    .rst_l(rst_l),

		.vga_hs(vga_hs),
		.vga_vs(vga_vs),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),

		.ps2_clk(ps2_clk),
		.ps2_dat(ps2_data),

		.PBusAddr(PBusAddr), 
		.PBusData(PBusData),
		.PBusBE(PBusBE),
		.PBusDataMONI(PBusDataMONI), 
    .PBusDataKEYB(PBusDataKEYB), 
		.PBusReqToMONI(PBusReqToMONI),
		.PBusReqToKEYB(PBusReqToKEYB),
		.PBusRdyMONI(PBusRdyMONI), 
    .PBusRdyKEYB(PBusRdyKEYB)
		);

  // **************** Internal memories *********************

	imemories IMEMS (
		.clk(clk),
		.rst_l(rst_l),

		.PBusAddr(PBusAddr),
		.PBusData(PBusData),
		.PBusBE(PBusBE),
		.PBusDataIRAM(PBusDataIRAM),
		.PBusDataIROM(PBusDataIROM),
		.PBusReqToIRAM(PBusReqToIRAM),
		.PBusReqToIROM(PBusReqToIROM),
		.PBusRdyIRAM(PBusRdyIRAM),
		.PBusRdyIROM(PBusRdyIROM)
  );

  // **************** Instantiate the COP *************************
	wire halted;
	wire cpu_clk_en;

	cop COP (.clk(clk), .rst_l(rst_l), .in_sim(in_sim),
		.buttons(buttonsCOP), .switches(switchesCOP),
		.leds(ledsCOP), .ssds(ssdsCOP),
		.output_override(output_override),
		.in_debug(in_debug),
		.PBusAddr(PBusAddrCOP),
		.PBusDataIn(PBusData),
		.PBusDataOut(PBusDataCOP),
		.PBusReq(PBusReqCOP),
		.PBusBE(PBusBECOP),
		.PBusRdy(PBusRdy),
		.PBusASpace(PBusASpaceCOP),
		.PBusGnt(PBusGntCOP),
		.halted(halted),
		.cpu_clk_en(cpu_clk_en)
  );

  // ****************************************************************
  // ****************************************************************
  // ****************************************************************
  // ********* INSERT YOUR CODE AFTER THIS POINT ********************
  // ****************************************************************
  // ****************************************************************
  // ****************************************************************

  // *****************************************************************
  // *              Internal signal definitions                      *
  // *****************************************************************


endmodule

