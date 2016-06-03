//  Model for the Nexys 4 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module is for the Nexys 4 board in a functional mode; it does
// not include FPGA programming stuff....

module nexys4(
  EXTbtn,
  EXTbuttons,
  EXTswitches,
  EXTleds,
  EXTssds,
  EXTps2clk,
  EXTps2dat,
  EXTvgaHS,
  EXTvgaVS,
  EXTvgaR,
  EXTvgaG,
  EXTvgaB
);

  // the pushbutton
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

  // on-board signals
  reg clk1;
  wire EXTps2clk;
  wire EXTps2dat;

  // the FPGA

  proc_fpga FPGA (
    .clk(clk1),
    .reset(EXTbtn),
    .buttons(EXTbuttons),
    .switches(EXTswitches),
    .leds(EXTleds),
    .ssds(EXTssds),
    .vga_hs(EXTvgaHS),
    .vga_vs(EXTvgaVS),
    .vga_r(EXTvgaR),
    .vga_g(EXTvgaG),
    .vga_b(EXTvgaB),
    .ps2_clk(EXTps2clk),
    .ps2_data(EXTps2dat)
  );

  // the on-board clock process
  initial begin
    clk1 = 0;
    forever begin
      #10 clk1 = 1;
      #10 clk1 = 0;
    end
  end

endmodule






