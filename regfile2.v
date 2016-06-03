/* regfile-sim.v  - Two-ported register file. 

 This register file has two ports that can be used for reading. Use 
 selA or selB to index, and dataOutA and dataOutB for data.
 
 
 This register file can not both read and write in the same cycle
 on port A, though it can read from port B while writing to port A.  
 However, you should be sure that port B does not have the same
 address as port A when you do this: this is not like the H&P register
 file which writes in one half of the cycle and reads in the next.
 
 To write, assert enable and use selA to choose the destination and dataIn 
 to specify the data. Don't try to read data during a write.

 The result of a register write is echoed to stdout.
 
 This module also contains a task "dumpRegs" that you can call to 
 periodically dump registers (e.g. after an instruction.) 

 Call it with the instantiation name for the register file, e.g.
          RF.dumpRegs;
 
*/

module regfile2(selA, selB, dataIn, dataOutA, dataOutB, enable, clk);
   input [3:0] selA, selB;
   input [15:0] dataIn;
   output [15:0] dataOutA, dataOutB;
   input [1:0] enable;
   input clk;

   reg [7:0] datal[0:15];
   reg [7:0] datah[0:15];

   assign     dataOutA = {datah[selA],datal[selA]};
   assign     dataOutB = {datah[selB],datal[selB]};
   
   always @ (posedge clk) begin
      if (enable[0]) datal[selA] <= #1 dataIn[7:0];
      if (enable[1]) datah[selA] <= #1 dataIn[15:8];
      if (enable[0] | enable[1])
	 $display("<%t> RegFile[%d] <-%2b %h", $time, selA, enable, dataIn);
   end // always @ (posedge clk)

   task dumpRegs;
      begin
	 $display("\n-------------- Begin Register File Dump ----------------");
	 $display(" R0:%4h\t R1:%4h\t R2:%4h\t R3:%4h",
		  {datah[0],datal[0]}, {datah[1], datal[1]},
		  {datah[2],datal[2]}, {datah[3], datal[3]});
	 $display(" R4:%4h\t R5:%4h\t R6:%4h\t R7:%4h",
		  {datah[4],datal[4]}, {datah[5], datal[5]},
		  {datah[6],datal[6]}, {datah[7], datal[7]});
	 $display(" R8:%4h\t R9:%4h\tR10:%4h\tR11:%4h",
		  {datah[8],datal[8]}, {datah[9], datal[9]},
		  {datah[10],datal[10]}, {datah[11], datal[11]});
	 $display("R12:%4h\tR13:%4h\tR14:%4h\tR15:%4h",
		  {datah[12],datal[12]}, {datah[13], datal[13]},
		  {datah[14],datal[14]}, {datah[15], datal[15]});
	 $display("----------------- End Register File Dump ---------------\n");
      end
   endtask // dumpRegs
   
endmodule // regfile
