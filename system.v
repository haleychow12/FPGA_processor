//  Model for the entire FPGA board 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module is for the entire system as students are supposed to
// construct it.  It does not include FPGA programming stuff...

module system(
  EXTbtn,
  EXTbuttons, EXTswitches, EXTleds, EXTssds,
  EXTps2clk, EXTps2dat,
  EXTvgaR, EXTvgaG, EXTvgaB, EXTvgaVS, EXTvgaHS
);

// I/O to/from main board
input EXTbtn;
input [4:0] EXTbuttons;
input [15:0] EXTswitches;
input [15:0] EXTleds;
input [15:0] EXTssds;
input EXTps2clk;
input EXTps2dat;
output EXTvgaHS;
output EXTvgaVS;
output [3:0] EXTvgaR;
output [3:0] EXTvgaG;
output [3:0] EXTvgaB;

// Instantiate the digilab2 board
nexys4 MAIN (
  .EXTbtn(EXTbtn), 
  .EXTbuttons(EXTbuttons),
  .EXTswitches(EXTswitches),
  .EXTleds(EXTleds),
  .EXTssds(EXTssds),
  .EXTps2clk(EXTps2clk),
  .EXTps2dat(EXTps2dat),
  .EXTvgaHS(EXTvgaHS),
  .EXTvgaVS(EXTvgaVS),
  .EXTvgaR(EXTvgaR),
  .EXTvgaG(EXTvgaG),
  .EXTvgaB(EXTvgaB)
);

endmodule





