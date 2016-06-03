//  Model for the VGA controller
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module contains the monitor and keyboard.  

module vgacontrol(
  clk,rst,
  HS,VS,
  hcounter,vcounter,
  blank
  );

  input clk;
  input rst;
  output HS, VS, blank;
  output [10:0] hcounter;
  output [10:0] vcounter;
  parameter HMAX = 800; // maxium value for the horizontal pixel counter
  parameter VMAX = 525; // maxium value for the vertical pixel counter
  parameter HLINES = 640; // total number of visible columns
  parameter HFP = 656; // value for the horizontal counter where front porch ends
  parameter HSP = 752; // value for the horizontal counter where the synch pulse ends
  parameter VLINES = 480; // total number of visible lines
  parameter VFP = 490; // value for the vertical counter where the frone proch ends
  parameter VSP = 492; // value for the vertical counter where the synch pulse ends
  parameter SPP = 0;
  reg HS,VS;
  reg [10:0] hcounter = 0;
  reg [10:0] vcounter = 0;

  always@(posedge clk)begin
  if (rst) hcounter <= 11'b0;
    else begin
      if (hcounter == HMAX) hcounter <= 0;
      else hcounter <= hcounter + 1'b1;
    end
  end

  always@(posedge clk)begin
  if (rst) vcounter <= 11'b0;
    else begin
      if(hcounter == HMAX) begin
        if(vcounter == VMAX) vcounter <= 0;
        else vcounter <= vcounter + 1'b1; 
      end
      else begin
        vcounter <= vcounter;
      end
    end
  end

  always@(posedge clk)begin
  if(hcounter >= HFP && hcounter < HSP) HS <= SPP;
  else HS <= ~SPP; 
  end

  always@(posedge clk)begin
  if(vcounter >= VFP && vcounter < VSP) VS <= SPP;
  else VS <= ~SPP; 
  end 

  assign blank = (hcounter < HLINES && vcounter < VLINES) ? 1'b0 : 1'b1;

endmodule
