//  Model for the FPGA on the Nexys 4 board
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module is the COP 
//
// The COP has a PBus master interface, but no target interface

module cop(clk, rst_l, in_sim,
  buttons, switches, leds, ssds,
  output_override, in_debug,
  PBusAddr, PBusDataIn, PBusDataOut, PBusReq, PBusBE, PBusRdy,
  PBusASpace, PBusGnt,
  halted, cpu_clk_en);

  input clk;
  input rst_l;
  input in_sim;

  // user input
  input [4:0] buttons;
  input [15:0] switches;
  
  // output
  output [15:0] leds;
  output [31:0] ssds;
  output output_override;
  output in_debug;

  // PBus interface
  output [15:1] PBusAddr;
  input [15:0] PBusDataIn;
  output [15:0] PBusDataOut;
  output [1:0] PBusReq;
  output [1:0] PBusBE;
  output PBusASpace;
  input PBusRdy;
  input PBusGnt;

  // CPU interface
  input halted;
  output cpu_clk_en;

  `define COP_HALT 2'b00
  `define COP_FREERUN 2'b01
  `define COP_STEPRUN 2'b10
  `define COP_MEM 2'b11

  wire start_up, step_up, mem_up, stop_up, read_up;
  reg [1:0] cop_state;

  always @(posedge clk or negedge rst_l) 
    if (~rst_l) cop_state <= `COP_HALT;
    else case (cop_state)
    `COP_HALT : 
      if (start_up) cop_state <= #1 `COP_FREERUN;
      else if (step_up) cop_state <= #1 `COP_STEPRUN;
      else if (mem_up) cop_state <= #1 `COP_MEM;
      else cop_state <= #1 `COP_HALT;
    `COP_FREERUN :
      if (stop_up || halted) cop_state <= #1 `COP_HALT;
      else cop_state <= #1 `COP_FREERUN;
    `COP_STEPRUN :
      if (stop_up || halted) cop_state <= #1 `COP_HALT;
      else cop_state <= #1 `COP_STEPRUN;
    `COP_MEM :
      if (mem_up) cop_state <= #1 `COP_HALT;
      else cop_state <= #1 `COP_MEM;
    endcase
  
  reg [15:0] dbcnt;
  always @(posedge clk or negedge rst_l)
    if (~rst_l) dbcnt <= 0;
    else if (|buttons) dbcnt <= #1 dbcnt + 1'b1;
    else dbcnt <= 0;

  assign {read_up,stop_up,mem_up,step_up,start_up} = buttons & {5{dbcnt >= 16'd2}};

  assign in_debug = (cop_state == `COP_MEM) || (cop_state==`COP_HALT);
  assign output_override = in_debug & read_up;

  reg [15:0] maddr;
  always @(posedge clk or negedge rst_l) begin
    if (~rst_l) maddr <= 0;
    else if (in_debug && read_up) begin
      maddr <= #1 switches;
    end
    else begin
      maddr <= maddr;
    end 
  end

  reg cpu_clk_en;
  always @(negedge clk) begin
    cpu_clk_en <= #1 cop_state == `COP_FREERUN || (cop_state == `COP_STEPRUN && step_up);
  end

  // state machine for PBus access
  `define PBUSM_IDLE 2'b00
  `define PBUSM_DEAD 2'b10
  `define PBUSM_WAIT 2'b11

  reg [1:0] pbus_state;
  reg [15:0] mem_data;

  // start a new request whenever we've pressed an appropriate button
  wire start_req = in_debug && pbus_state == `PBUSM_IDLE && read_up;

  reg [1:0] PBusReq;
  reg [15:1] PBusAddr;
  reg [1:0] PBusBE;
  reg PBusASpace;
  reg [15:0] PBusDataOut;
  wire finished = PBusRdy && pbus_state == `PBUSM_WAIT;

  always @(posedge clk or negedge rst_l) 
    if (~rst_l) begin
      pbus_state <= `PBUSM_IDLE;
      PBusReq <= 2'b00;
      mem_data <= 0;
    end 
    else begin
      case (pbus_state) 
      `PBUSM_IDLE :
        if (start_req) begin
          pbus_state <= #1 `PBUSM_DEAD;
          PBusReq <= #1 {(read_up), 1'b1};
          PBusAddr <= #1 maddr[15:1];
          PBusBE <= #1 { maddr[0], ~maddr[0] };
          PBusASpace <= #1 cop_state != `COP_MEM; 
          PBusDataOut <= #1 16'b0;
        end
      `PBUSM_DEAD :
        if (PBusGnt) pbus_state <= #1 `PBUSM_WAIT;
      `PBUSM_WAIT :
        if (PBusRdy) begin
          pbus_state <= #1 `PBUSM_IDLE;
          PBusReq <= #1 2'b00;
          if (PBusReq[1]) mem_data <= #1 PBusDataIn;
        end
      endcase
    end

  // final LED&SSD assignment
  assign leds = {output_override, 2'h0, buttons & {5{dbcnt >= 16'd2}}, 3'h0, pbus_state, 1'b0, cop_state};
  assign ssds = {maddr,mem_data};


endmodule

