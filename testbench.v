//  COS/ELE 375 Project 2 Top Level Test Bench 
//	COS/ELE 375 - Fall 2015
//	Hansen Zhang
`timescale 1 ns / 1ns

module testbench();

// Inputs
reg EXTbtn;
reg [15:0] EXTswitches;
reg [4:0] EXTbuttons;
reg [15:0] EXTleds;
reg [15:0] EXTssds;
reg EXTps2clk;
reg EXTps2dat;

// Outputs
wire [3:0] EXTvgaR;
wire [3:0] EXTvgaG;
wire [3:0] EXTvgaB;
wire EXTvgaVS;
wire EXTvgaHS;

// Instantiate the UUT
system UUT (
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


// Initialize Inputs
`ifdef auto_init

  initial begin
    RXD = 0;
    RTS = 0;
    PWE = 0;
    PDS = 0;
    PRS = 0;
    PAS = 0;
  end

`endif

wire clock = UUT.MAIN.FPGA.clk;
// buttons input
wire [4:0] INTbuttons = UUT.MAIN.FPGA.IOCNTL.buttonsCOP;

initial begin
  $timeformat(-6,3,"us",15);
  // Force to be in simulator
  force UUT.MAIN.FPGA.in_sim = 1;
end

monitors MONITORS();
utils UTILS();

// ****************** USEFUL TASKS ******************************

parameter speed = 2;

task waitClocks;
  input [31:0] numclocks;
  begin
    repeat (numclocks) @(posedge clock);
    # 5;
  end
endtask

//task pushButton;
//  input [3:0] bno;
//  begin
//    EXTbuttons[bno] = 1'b1;
//    #3;
//    while (INTbuttons[bno] != EXTbuttons[bno]) @(posedge clock);
//    #3;
//    EXTbuttons[bno] = 1'b0;
//    #3;
//    while (INTbuttons[bno] != EXTbuttons[bno]) @(posedge clock);
//  end
//endtask

task pushButton;
  input [3:0] bno;
  begin 
    EXTbuttons[bno] = 1'b1;
    #100;
    EXTbuttons[bno] = 1'b0;
  end
endtask

task readData;
  begin
    waitClocks(speed);
    pushButton(5);
  end
endtask

task finish_sim;
  begin
    // you can uncomment this later!
    UUT.MAIN.FPGA.DATA.RF.dumpRegs;
    $finish;
  end
endtask //of finish_sim

// ************************** YOUR CODE GOES HERE *******************
//
// This section is for you to play with; you can change the buttons 
// and switches to test different things....

initial begin
  EXTps2clk = 1'bz;
  EXTps2dat = 1'bz;
  EXTswitches = 16'h0;
  EXTbuttons = 'h0;
  EXTbtn = 1'b0;
  # 100 EXTbtn = 1'b1;

  pushButton(0);   // free-run mode

  //write_to_reg(0,'h5634);
  //read_from_reg(0);
end

// you can use this block to set up variables to dump...

initial begin
  $dumpfile("verilog.vcd");
  $dumpvars(0,testbench);  // Dump everything in the system
end

// and this block to set behavior when the CPU halts...
always @(posedge UUT.MAIN.FPGA.halted)
  finish_sim;

endmodule

