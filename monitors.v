//  COS/ELE 375 Project 2 debug monitors
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang

module monitors;

// Place your monitor code (code for debugging which you don't wish
// to be synthesized) in this module.  An example is given.

// Example 1: this example dumps the registers whenever a new instruction
//            is fetched.  It then disassembles the new instruction.
//            Actually, it does
//            this at the falling edge of the next cycle so we see the
//            *new* values, not the old ones....
  always @(posedge testbench.UUT.MAIN.FPGA.clk) 
    if (testbench.UUT.MAIN.FPGA.clk) 
      if (testbench.UUT.MAIN.FPGA.DATA.IR_Enable == 1'b1) begin
        @(negedge testbench.UUT.MAIN.FPGA.clk)
        // check that we're not still waiting for memory
        if (testbench.UUT.MAIN.FPGA.DATA.IR_Enable == 1'b0) begin 
          testbench.UUT.MAIN.FPGA.DATA.RF.dumpRegs;
          $display("  CC: N=%b Z=%b C=%b V=%b\n",
            testbench.UUT.MAIN.FPGA.DATA.FLAG_N,
            testbench.UUT.MAIN.FPGA.DATA.FLAG_Z,
            testbench.UUT.MAIN.FPGA.DATA.FLAG_C,
            testbench.UUT.MAIN.FPGA.DATA.FLAG_V);
          testbench.UTILS.disassemble(testbench.UUT.MAIN.FPGA.DATA.IR,
            {testbench.UUT.MAIN.FPGA.DATA.RF.datah[15],
            testbench.UUT.MAIN.FPGA.DATA.RF.datal[15]});
          $display;
        end
      end

endmodule
