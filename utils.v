//  COS/ELE 375 Project 2 Utilities
//  COS/ELE 375 - Fall 2015
//  Hansen Zhang

module utils;

   /************************** Disassembly functions ******************/

   // Say that an instruction was illegal
   task report_illegal;
   begin 
     $display("Illegal instruction");
   end
   endtask
  
   // Disassemble an instruction...
   task disassemble;
    input [15:0] instr;
    input [15:0] pc;

      reg [3:0] reald;
      reg [15:0] effaddr;
    begin
      $write($time,," %h: %h ",pc,instr[15:0]);
      casex (instr[15:10])
        6'b000000 :
	  $display("halt");
        6'b001xxx : 
	  case (instr[12:11])
    	    2'b00 : $display("mov r%d, #%d", instr[10:8],instr[7:0]);
	    2'b01 : $display("cmp r%d, #%d", instr[10:8],instr[7:0]);
	    default: report_illegal;
	  endcase
	6'b010000 : // format 4
	  case (instr[9:6])
	    4'b0000: $display("and r%d, r%d", instr[2:0],instr[5:3]);
	    4'b0001: $display("eor r%d, r%d", instr[2:0],instr[5:3]);
	    4'b0010: $display("asr r%d, r%d", instr[2:0],instr[5:3]);
	    4'b0011: $display("tst r%d, r%d", instr[2:0],instr[5:3]);
	    4'b0100: $display("neg r%d, r%d", instr[2:0],instr[5:3]);
	    4'b0101: $display("cmp r%d, r%d", instr[2:0],instr[5:3]);
	    default: report_illegal;
	  endcase
	6'b010001 : // format 5
	  begin 
	    reald = {instr[7],instr[2:0]};
	    case (instr[9:8])
	      2'b00: $display("add r%d, r%d", reald[3:0],instr[6:3]);
	      2'b01: $display("cmp r%d, r%d", reald[3:0],instr[6:3]);
	      2'b10: $display("mov r%d, r%d", reald[3:0],instr[6:3]);
	      default: report_illegal;
	    endcase
	  end
	6'b011xxx : // format 9
	  case (instr[12:11])
	    2'b00: $display("str r%d, [r%d,#%d]", instr[2:0],instr[5:3],
		  {instr[10:6],2'b0});
	    2'b01: $display("ldr r%d, [r%d,#%d]", instr[2:0],instr[5:3],
		  {instr[10:6],2'b0});
	    2'b10: $display("strb r%d, [r%d,#%d]", instr[2:0],instr[5:3],
		  instr[10:6]);
	    2'b11: $display("ldrb r%d, [r%d,#%d]", instr[2:0],instr[5:3],
		  instr[10:6]);
	    default: report_illegal;
	  endcase
	6'b1010xx : // format 12
	  if (instr[11]==1'b0) begin 
	    $display("add r%d, pc, #%d", instr[10:8],{instr[7:0],2'b0});
	  end
	  else report_illegal;
	6'b1101xx : // format 16
	  begin 
	    effaddr = pc + {{7{instr[7]}},instr[7:0],1'b0};
	    case (instr[11:8])
	      4'b0000: $display("beq %4h", effaddr);
	      4'b0001: $display("bne %4h", effaddr);
	      4'b0010: $display("bcs %4h", effaddr);
	      4'b0011: $display("bcc %4h", effaddr);
	      4'b0100: $display("bmi %4h", effaddr);
	      4'b0101: $display("bpl %4h", effaddr);
	      4'b0110: $display("bvs %4h", effaddr);
	      4'b0111: $display("bvc %4h", effaddr);
	      4'b1000: $display("bhi %4h", effaddr);
	      4'b1001: $display("bls %4h", effaddr);
	      4'b1010: $display("bge %4h", effaddr);
	      4'b1011: $display("blt %4h", effaddr);
	      4'b1100: $display("bgt %4h", effaddr);
	      4'b1101: $display("ble %4h", effaddr);
	      default: report_illegal;
	    endcase
	  end
	default: report_illegal;
      endcase
  end
    
  endtask //of disassemble

endmodule //of utils
