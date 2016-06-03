/* mux.v - Four-way multiplexor.
 
 Use sel=2'b00 to select in0, sel=2'b01 to select in1, etc.
 
 This defaults to a 16-bit mux, but you can also specify other bit widths, 
 using a parameter assignment:
 
 mux4 #(4) MX4_4b(foo, i3, i2, i1, i0, bar) // instantiates a 4-bit mux
 
 mux4 #(8) MX4_8b(bout, a3, a2, a1, a0, bsel) // instantiates an 8-bit mux
 
*/

module mux4(out, in3, in2, in1, in0, sel);
   parameter width = 16;
   output [width-1:0] out;
   input [width-1:0] in3, in2, in1, in0;
   input [1:0] 	     sel;

   assign out = (sel[1]) ? ((sel[0]) ? in3 : in2) :
	 ((sel[0]) ? in1 : in0);
   
endmodule // mux4

   