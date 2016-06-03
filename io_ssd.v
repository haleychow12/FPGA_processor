//  Model for the Seven Segment Display 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module controls the Seven Segment Display

module io_ssd(clk, rst_l,
  i_digits,
  o_ssds
  );

input clk;
input rst_l;
input [31:0] i_digits;
output [15:0] o_ssds;

// cnt is used as a prescaler
reg [15:0] cnt = 16'd0;
always @(posedge clk) cnt <= cnt+24'h1;
wire cntovf = &cnt;

// BCD is a counter that counts from 0 to 7
reg [2:0] BCD = 3'd0;
reg [15:0] ssd = 16'd0;
always @(posedge clk) 
  if(cntovf) begin
    BCD <= (BCD==3'h7 ? 3'h0 : BCD+3'h1);
    case(BCD)
      3'h0: ssd = {digits2ssd(i_digits[ 3: 0]), 8'b00000001};
      3'h1: ssd = {digits2ssd(i_digits[ 7: 4]), 8'b00000010};
      3'h2: ssd = {digits2ssd(i_digits[11: 8]), 8'b00000100};
      3'h3: ssd = {digits2ssd(i_digits[15:12]), 8'b00001000};
      3'h4: ssd = {digits2ssd(i_digits[19:16]), 8'b00010000};
      3'h5: ssd = {digits2ssd(i_digits[23:20]), 8'b00100000};
      3'h6: ssd = {digits2ssd(i_digits[27:24]), 8'b01000000};
      3'h7: ssd = {digits2ssd(i_digits[31:28]), 8'b10000000};
    endcase
  end


function [7:0] digits2ssd;
input [3:0] digits;
  begin
  digits2ssd = 
              (digits == 4'h0) ? 8'b11111100 :
              (digits == 4'h1) ? 8'b01100000 :
              (digits == 4'h2) ? 8'b11011010 :
              (digits == 4'h3) ? 8'b11110010 :
              (digits == 4'h4) ? 8'b01100110 :
              (digits == 4'h5) ? 8'b10110110 :
              (digits == 4'h6) ? 8'b10111110 :
              (digits == 4'h7) ? 8'b11100000 :
              (digits == 4'h8) ? 8'b11111110 :
              (digits == 4'h9) ? 8'b11110110 :
              (digits == 4'ha) ? 8'b11101110 :
              (digits == 4'hb) ? 8'b00111110 :
              (digits == 4'hc) ? 8'b10011100 :
              (digits == 4'hd) ? 8'b01111010 :
              (digits == 4'he) ? 8'b10011110 :
              (digits == 4'hf) ? 8'b10001110 :
                                 8'b00000000 ;
  end
endfunction


assign o_ssds = ~ssd;

endmodule
