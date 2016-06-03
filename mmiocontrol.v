//  Model for the Memory Mapped IO -- Monitor & Keyboard 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
//
// This module contains the monitor and keyboard.  

module mmiocontrol (
  clk, rst_l,
  vga_hs, vga_vs, vga_r, vga_g, vga_b,
  ps2_clk, ps2_dat,
  PBusAddr, PBusData, PBusBE,
  PBusDataMONI, PBusDataKEYB, 
  PBusReqToMONI,PBusReqToKEYB,
  PBusRdyMONI, PBusRdyKEYB
  );

  input clk;
  input rst_l;

  // VGA interface
  output vga_hs;
  output vga_vs;
  output reg [3:0] vga_r;
  output reg [3:0] vga_g;
  output reg [3:0] vga_b;

  // PS2 interface
  input ps2_clk;
  input ps2_dat;

  // PBus Inteface
  input [15:1] PBusAddr;
  input [15:0] PBusData;
  input [1:0] PBusBE;
  output [15:0] PBusDataMONI; 
  output reg [15:0] PBusDataKEYB;
  input [1:0] PBusReqToMONI, PBusReqToKEYB;
  output PBusRdyMONI, PBusRdyKEYB;

  // **************** Keyboard controller *********************
  wire [7:0] scan_code;
  reg [7:0] ascii_code;
  reg keyup = 0;
  reg shifted = 0;
  reg key_valid;
  wire parity;
  reg ready = 0;
  reg [9:0] buffer = 0;
  reg [3:0] cnt = 0;

  // Reverse data bits
  genvar i;
  for (i=0; i<8; i=i+1) assign scan_code[i] = buffer[9-i];
  assign parity = buffer[1];
  // Receive data logic
  always @(negedge ps2_clk)
  begin
    if (cnt == 4'hb) begin
      buffer <= 10'h0;
      cnt <= 4'h1;
    end
    else begin
      buffer <= {buffer[8:0], ps2_dat};
      cnt <= cnt + 1'b1;
    end
  end
  // Parity logic
  always @(posedge ps2_clk)
  begin
    if (cnt == 4'hb) begin
      if (parity != ^scan_code) begin
        ready <= 1'b1;
      end
    end
    else begin
      ready <= 1'b0;
    end
  end
  // Shift and keyup logic
  always @(posedge ps2_clk)
  if (cnt == 4'hb) begin
    case(scan_code)
      8'hf0: begin
        key_valid <= 1'b0;   //keyup
        keyup <= 1'b1;
      end
      8'h12: begin
        key_valid <= 1'b0;   //shifted
        shifted <= 1'b1;
      end
      8'h1c: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h41;  //A
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h61;  //a
          key_valid <= 1'b1;
        end
      end
      8'h32: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b1;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h42;  //B
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h62;  //b
          key_valid <= 1'b1;
        end
      end
      8'h21: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h43;  //C
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h63;  //c
          key_valid <= 1'b1;
        end
      end
      8'h23: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h44;  //D
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h64;  //d
          key_valid <= 1'b1;
        end
      end
      8'h24: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h45;  //E
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h65;  //e
          key_valid <= 1'b1;
        end
      end
      8'h2b: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h46;  //F
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h66;  //f
          key_valid <= 1'b1;
        end
      end
      8'h34: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h47;  //G
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h67;  //g
          key_valid <= 1'b1;
        end
      end
      8'h33: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h48;  //H
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h68;  //h
          key_valid <= 1'b1;
        end
      end
      8'h43: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h49;  //I
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h69;  //i
          key_valid <= 1'b1;
        end
      end
      8'h3b: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4a;  //J
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6a;  //j
          key_valid <= 1'b1;
        end
      end
      8'h42: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4b;  //K
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6b;  //k
          key_valid <= 1'b1;
        end
      end
      8'h4b: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4c;  //L
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6c;  //l
          key_valid <= 1'b1;
        end
      end
      8'h3a: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4d;  //M
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6d;  //m
          key_valid <= 1'b1;
        end
      end
      8'h31: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4e;  //N
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6e;  //n
          key_valid <= 1'b1;
        end
      end
      8'h44: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h4f;  //O
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h6f;  //o
          key_valid <= 1'b1;
        end
      end
      8'h4d: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h50;  //P
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h70;  //p
          key_valid <= 1'b1;
        end
      end
      8'h15: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h51;  //Q
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h71;  //q
          key_valid <= 1'b1;
        end
      end
      8'h2d: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h52;  //R
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h72;  //r
          key_valid <= 1'b1;
        end
      end
      8'h1b: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h53;  //S
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h73;  //s
          key_valid <= 1'b1;
        end
      end
      8'h2c: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h54;  //T
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h74;  //t
          key_valid <= 1'b1;
        end
      end
      8'h3c: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h55;  //U
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h75;  //u
          key_valid <= 1'b1;
        end
      end
      8'h2a: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h56;  //V
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h76;  //v
          key_valid <= 1'b1;
        end
      end
      8'h1d: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h57;  //W
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h77;  //w
          key_valid <= 1'b1;
        end
      end
      8'h22: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h58;  //X
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h78;  //x
          key_valid <= 1'b1;
        end
      end
      8'h35: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h59;  //Y
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h79;  //y
          key_valid <= 1'b1;
        end
      end
      8'h1a: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h5a;  //Z
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h7a;  //z
          key_valid <= 1'b1;
        end
      end
      8'h45: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h30;  //0^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h30;  //0
          key_valid <= 1'b1;
        end
      end
      8'h16: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h31;  //1^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h31;  //1
          key_valid <= 1'b1;
        end
      end
      8'h1e: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h32;  //2^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h32;  //2
          key_valid <= 1'b1;
        end
      end
      8'h26: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h33;  //3^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h33;  //3
          key_valid <= 1'b1;
        end
      end
      8'h25: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h34;  //2^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h34;  //4
          key_valid <= 1'b1;
        end
      end
      8'h2e: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h35;  //5^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h35;  //5
          key_valid <= 1'b1;
        end
      end
      8'h36: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h36;  //6^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h36;  //6
          key_valid <= 1'b1;
        end
      end
      8'h3d: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h37;  //7^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h37;  //7
          key_valid <= 1'b1;
        end
      end
      8'h3e: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h2a;  //*
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h38;  //8
          key_valid <= 1'b1;
        end
      end
      8'h46: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h39;  //9^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h39;  //9
          key_valid <= 1'b1;
        end
      end
      8'h4e: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h2d;  // -^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h2d;  // -
          key_valid <= 1'b1;
        end
      end
      8'h4a: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h2f;  // /^
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h2f;  // /
          key_valid <= 1'b1;
        end
      end
      8'h55: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h2b;  // + 
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h3d;  // =
          key_valid <= 1'b1;
        end
      end
      8'h29: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h20;  // space 
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h20;  // space
          key_valid <= 1'b1;
        end
      end
      8'h66: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h08;  // backspace 
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h08;  // backspace
          key_valid <= 1'b1;
        end
      end
      8'h5a: begin
        if (keyup == 1'b1) begin
          keyup <= 1'b0;
          key_valid <= 1'b0;
        end
        else if (shifted == 1'b1) begin
          shifted <= 1'b0;
          ascii_code <= 8'h0d;  // carriage return
          key_valid <= 1'b1;
        end
        else begin
          ascii_code <= 8'h0d;  // carriage return
          key_valid <= 1'b1;
        end
      end
      default: begin
        ascii_code <= 8'hff;  //blank
        key_valid <= 1'b0;
      end

    endcase
  end
  // Pulse generation
  reg ready_r=0;
  reg ready_p=0;
  reg ready_v=0;
  always @(posedge clk) begin
    ready_r <= ready;
    ready_p <= ready & ~ready_r;
    ready_v <= ready_p & key_valid;
  end

  // Keyboard PBus Interface
  // main state machine
  `define PBUS_IDLE 2'b00
  `define PBUS_DOINGA 2'b10
  `define PBUS_DONE 2'b11

  reg [1:0] pbus_state_keyb, next_pbus_state_keyb;
  always @(pbus_state_keyb or PBusReqToKEYB[0] or ready_p) 
    case (pbus_state_keyb)
    `PBUS_IDLE : 
      if (PBusReqToKEYB[0]) next_pbus_state_keyb = `PBUS_DOINGA; 
      else next_pbus_state_keyb = `PBUS_IDLE;
    `PBUS_DOINGA : 
      if (ready_v) next_pbus_state_keyb = `PBUS_DONE;
      else next_pbus_state_keyb = `PBUS_DOINGA;
    `PBUS_DONE : next_pbus_state_keyb = `PBUS_IDLE;
    default : next_pbus_state_keyb = `PBUS_IDLE;
    endcase
  
  always @(posedge clk or negedge rst_l)
    if (~rst_l) begin
      pbus_state_keyb <= `PBUS_IDLE;
    end
    else begin
      pbus_state_keyb <= #1 next_pbus_state_keyb;
    end

  always @(PBusAddr or ascii_code)
  casex (PBusAddr[15:12]) 
    4'hb: //keyboard
      if(PBusBE[0] == 1'b1) begin
        PBusDataKEYB = {8'h0, ascii_code};
      end
      else begin
        PBusDataKEYB = {ascii_code, 8'h0};
      end

    default: PBusDataKEYB = 16'b0;
  endcase

  assign PBusRdyKEYB = pbus_state_keyb == `PBUS_IDLE || pbus_state_keyb == `PBUS_DONE;

  // **************** VGA Memory controller *********************
  parameter monibits = 13;
  wire [monibits-1:0] moniaddr;
  wire [1:0] moniwe;
  wire [15:0] monireaddata, moniwritedata;

  imemcntl MONIC (
    .clk(clk),
    .rst_l(rst_l),

    .PBusAddr(PBusAddr),
    .PBusDataIn(PBusData),
    .PBusDataOut(PBusDataMONI),
    .PBusReq(PBusReqToMONI),
    .PBusBE(PBusBE),
    .PBusRdy(PBusRdyMONI),

    .addr(moniaddr),
    .we(moniwe),
    .readdata(monireaddata),
    .writedata(moniwritedata)
    );

	defparam MONIC.awidth = monibits;

	reg [7:0] monil[(1<<monibits)-1:0];
	reg [7:0] monih[(1<<monibits)-1:0];

	reg    [monibits-1:0] moniaddr_dell; 
	reg    [monibits-1:0] moniaddr_delh; 
 
	always @(posedge clk) begin 
 	  if (moniwe[1]) 
      monih[moniaddr] <= moniwritedata[15:8]; 
      moniaddr_delh <= moniaddr; 
    end 
	assign monireaddata[15:8] = monih[moniaddr_delh];
 
	always @(posedge clk) begin 
 	  if (moniwe[0]) 
      monil[moniaddr] <= moniwritedata[7:0]; 
      moniaddr_dell <= moniaddr; 
	  end 
	assign monireaddata[7:0] = monil[moniaddr_dell];
 
  // **************** VGA Logic controller *********************
  parameter HMAX_pic = 128;//640;
  parameter VMAX_pic = 128;//480;
  wire blank;
  wire [10:0] hcounter;
  wire [10:0] vcounter;
  reg pic_on;
  reg [7:0] pixel_dat;
  reg [monibits:0] pixel_address;

  reg [1:0] count = 2'h0;
  parameter n = 4;
  wire clk_25M;
  always @(posedge clk)
    count <= (count == n-1)? 1'b0:count+1'b1;
  assign clk_25M = (count>=n-2)? 1'b1:1'b0;

  vgacontrol VGAC (
    .clk(clk_25M),
    .rst(~rst_l),
    .HS(vga_hs),
    .VS(vga_vs),
    .hcounter(hcounter),
    .vcounter(vcounter),
    .blank(blank)
  );

  always @(hcounter or vcounter)
  begin
    if (hcounter > 11'd0 && hcounter <= (HMAX_pic)
      && vcounter >= 11'd0 && vcounter < (VMAX_pic)) begin
        pic_on <=1;
    end
  	else pic_on <=0;
  end

  always @(*)
  begin
    if(~rst_l || blank || ~pic_on)begin
      vga_r = 4'h0;
      vga_g = 4'h0;
      vga_b = 4'h0;
    end
    else begin
      pixel_address = (hcounter) + (vcounter<<7);
      if (pixel_address[0]) begin
        pixel_dat = monih[pixel_address[monibits:1]];
        vga_r = {pixel_dat[7:5],1'b0};
        vga_g = {pixel_dat[4:2],1'b0};
        vga_b = {pixel_dat[1:0],2'h0};
      end
      else begin
        pixel_dat = monil[pixel_address[monibits:1]];
        vga_r = {pixel_dat[7:5],1'b0};
        vga_g = {pixel_dat[4:2],1'b0};
        vga_b = {pixel_dat[1:0],2'h0};
      end
    end
  end

endmodule

