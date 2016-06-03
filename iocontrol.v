//  Model for the I/O controller 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module controls the I/O.  It offers two interfaces:
// 1) a direct signal interface for switches, leds, buttons, and seven-segs
// 2) a PBus interface for getting at the same things.  The PBus interface
//    makes it easier for programs to interface to it.

module iocontrol(clk, rst_l, in_sim
  // off-chip connects
  , i_buttons, i_switches, o_leds, o_ssds
  // on-chip connects
  , buttonsCOP, switchesCOP
  , ledsCOP, ssdsCOP
  , output_override
  , PBusAddr, PBusDataIn, PBusDataOut, PBusReq, PBusBE, PBusRdy
  );
  input clk;
  input rst_l;
  input in_sim;

  // off-chip connects
  input [4:0] i_buttons;
  input [15:0] i_switches;
  output [15:0] o_leds;
  output [15:0] o_ssds;

  // COP Interface
  output [4:0] buttonsCOP;
  output [15:0] switchesCOP;

  input [15:0] ledsCOP;
  input [31:0] ssdsCOP;

  // Direct interface
  input output_override;

  // PBus Inteface
  input [5:1] PBusAddr;
  input [15:0] PBusDataIn;
  output [15:0] PBusDataOut;
  input [1:0] PBusReq;
  input [1:0] PBusBE;
  output PBusRdy;

  reg [15:0] reg_leds = 16'd0; 
  reg [31:0] reg_ssds = 31'd0;
		 
  `define PBUS_IDLE 2'b00
  `define PBUS_DOINGA 2'b10
  `define PBUS_DONE 2'b11

  reg [1:0] pbus_state, next_pbus_state;

  // off-chip connects
  wire [15:0] switches;
  wire [4:0] buttons;

  assign switches = i_switches;
  assign switchesCOP = switches;
  assign buttons = i_buttons;
  assign buttonsCOP = buttons;

  // main state machine

  always @(pbus_state or PBusReq[0]) 
    case (pbus_state)
    `PBUS_IDLE : 
      if (PBusReq[0]) next_pbus_state = `PBUS_DOINGA; 
      else next_pbus_state = `PBUS_IDLE;
    `PBUS_DOINGA : next_pbus_state = `PBUS_DONE;
    `PBUS_DONE : next_pbus_state = `PBUS_IDLE;
    default : next_pbus_state = `PBUS_IDLE;
    endcase


  wire dowrite = ~PBusReq[1] && pbus_state == `PBUS_DOINGA;
  assign PBusRdy = pbus_state == `PBUS_IDLE || pbus_state == `PBUS_DONE;

  // state register and data registers
  always @(posedge clk or negedge rst_l)
    if (~rst_l) begin
      pbus_state <= `PBUS_IDLE;
      reg_ssds <= 0;
      reg_leds <= 0;
    end 
    else begin
      pbus_state <= #1 next_pbus_state;
      if (dowrite && PBusAddr == 5'h00 && PBusBE[0])
        reg_ssds[7:0] <= #1 PBusDataIn[7:0];
      if (dowrite && PBusAddr == 5'h00 && PBusBE[1])
        reg_ssds[15:8] <= #1 PBusDataIn[15:8];
      if (dowrite && PBusAddr == 5'h01 && PBusBE[0])
        reg_ssds[23:16] <= #1 PBusDataIn[7:0];
      if (dowrite && PBusAddr == 5'h01 && PBusBE[1])
        reg_ssds[31:24] <= #1 PBusDataIn[15:8];
      if (dowrite && PBusAddr == 5'h02 && PBusBE[0])
        reg_leds[7:0] <= PBusDataIn[7:0];
      if (dowrite && PBusAddr == 5'h02 && PBusBE[1])
        reg_leds[15:8] <= PBusDataIn[15:8];
    end

  reg [15:0] PBusDataOut;

  always @(PBusAddr or reg_ssds or reg_leds or 
	         buttons or switches)
  casex (PBusAddr) 
    5'h00 : // ssds
      PBusDataOut = reg_ssds[15:0];
    5'h01 : // ssds
      PBusDataOut = reg_ssds[31:16];
    5'h02 : // leds
      PBusDataOut = reg_leds;
    5'h04 : // buttons
      PBusDataOut = {11'b0,buttons};
    5'h06 : // switches
      PBusDataOut = switches;
    default: PBusDataOut = 16'b0;
  endcase
	 	
  /******************* Periphiral Controller **********************/

  // Seven Segment Display Control 
  io_ssd IO_SSD (
    .clk(clk),
    .rst_l(rst_l),
    .i_digits(output_override ? ssdsCOP : reg_ssds),
    .o_ssds(o_ssds)
    );

  // LED Control
  assign o_leds = output_override ? ledsCOP : reg_leds;

endmodule




