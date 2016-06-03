//  Model for an internal memory controller
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module controls an internal memory 

module imemcntl(clk, rst_l, 
  PBusAddr, PBusDataIn, PBusDataOut, PBusReq, PBusBE, PBusRdy
  , addr, we, writedata, readdata
  );

  parameter awidth = 3;

  input clk;
  input rst_l;

  // PBus Inteface
  input [15:1] PBusAddr;
  input [15:0] PBusDataIn;
  output [15:0] PBusDataOut;
  input [1:0] PBusReq;
  input [1:0] PBusBE;
  output PBusRdy;

  output [awidth-1:0] addr;
  output [1:0] we;
  output [15:0] writedata;
  input  [15:0] readdata;

  /**************** PBus interface *****************************/

  `define PBUS_IDLE 2'b00
  `define PBUS_DOING 2'b01
  `define PBUS_DOING2 2'b10
  `define PBUS_DONE 2'b11

  reg [15:0] PBusDataOut;

  reg [1:0] pbus_state;

  // main state machine

  reg dowrite;
  assign PBusRdy = pbus_state == `PBUS_IDLE || 
    pbus_state == `PBUS_DONE;
  assign we = PBusBE & {2{dowrite}};
  assign writedata = PBusDataIn;
  assign addr = PBusAddr[awidth:1];

  // state register and data registers
  always @(posedge clk or negedge rst_l)
    if (~rst_l) begin
      pbus_state <= `PBUS_IDLE;
      PBusDataOut <= 16'h0000;
      dowrite <= 1'b0;
    end else begin
      case (pbus_state)
        `PBUS_IDLE : 
          if (PBusReq[0]) begin 
            pbus_state <= #1 `PBUS_DOING; 
            dowrite <= #1 ~PBusReq[1];
          end
          `PBUS_DOING :  pbus_state <= #1 `PBUS_DOING2;
          `PBUS_DOING2 :  begin
            pbus_state <= #1 `PBUS_DONE;
            dowrite <= #1 1'b0;
          end
          `PBUS_DONE : pbus_state <= #1 `PBUS_IDLE;
          default : pbus_state <= #1 `PBUS_IDLE;
        endcase
        if (~dowrite && pbus_state == `PBUS_DOING2) PBusDataOut <= #1 readdata;
      end

    endmodule

