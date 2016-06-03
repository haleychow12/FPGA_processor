//  Model for the internal memories
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module contains the internal memories.  

module imemories(clk, rst_l,
  PBusAddr, PBusData, PBusBE,
  PBusDataIRAM, PBusDataIROM, 
  PBusReqToIRAM, PBusReqToIROM,
  PBusRdyIRAM, PBusRdyIROM
  );

	parameter awidth = 3;

  input clk;
  input rst_l;

  // PBus Inteface
  input [15:1] PBusAddr;
  input [15:0] PBusData;
  input [1:0] PBusBE;
  output [15:0] PBusDataIRAM, PBusDataIROM;
  input [1:0] PBusReqToIRAM, PBusReqToIROM;
  output PBusRdyIRAM, PBusRdyIROM;

  // **************** Internal RAM controller *********************

  parameter irambits = 11;
  wire [irambits-1:0] iramaddr;
  wire [1:0] iramwe;
  wire [15:0] iramreaddata, iramwritedata;

  imemcntl IRAMC (
    .clk(clk),
    .rst_l(rst_l),

    .PBusAddr(PBusAddr),
    .PBusDataIn(PBusData),
    .PBusDataOut(PBusDataIRAM),
    .PBusReq(PBusReqToIRAM),
    .PBusBE(PBusBE),
    .PBusRdy(PBusRdyIRAM),

    .addr(iramaddr),
    .we(iramwe),
    .readdata(iramreaddata),
    .writedata(iramwritedata)
    );

	defparam IRAMC.awidth = irambits;

	reg [7:0] iraml[(1<<irambits)-1:0];
	reg [7:0] iramh[(1<<irambits)-1:0];

	reg    [10:0] iramaddr_dell; 
	reg    [10:0] iramaddr_delh; 
 
	always @(posedge clk) begin 
 	  if (iramwe[1]) 
 		iramh[iramaddr] <= iramwritedata[15:8]; 
 	  iramaddr_delh <= iramaddr; 
	 end 
	assign iramreaddata[15:8] = iramh[iramaddr_delh];
 
	always @(posedge clk) begin 
 	  if (iramwe[0]) 
 		iraml[iramaddr] <= iramwritedata[7:0]; 
 	  iramaddr_dell <= iramaddr; 
	 end 
	assign iramreaddata[7:0] = iraml[iramaddr_dell];
 
  // **************** Internal ROM controller *********************

	parameter irombits = 10;
	wire [irombits-1:0] iromaddr;
	wire [1:0] iromwe;
	wire [15:0] iromwritedata;
	reg [15:0] iromreaddata;

	imemcntl IROMC (
		.clk(clk),
		.rst_l(rst_l),

		.PBusAddr(PBusAddr),
		.PBusDataIn(PBusData),
		.PBusDataOut(PBusDataIROM),
		.PBusReq(PBusReqToIROM),
		.PBusBE(PBusBE),
		.PBusRdy(PBusRdyIROM),

		.addr(iromaddr),
		.we(iromwe),
		.readdata(iromreaddata),
		.writedata(iromwritedata)
		);
	defparam IROMC.awidth = irombits;

	reg [15:0] irom[(1<<irombits)-1:0];

	always @(iromaddr) begin
	  case (iromaddr) 
	`include "iromcontents.v"
	  default :
		iromreaddata <= #1 0;
	  endcase

	end
 
endmodule

