`timescale 1ns / 1ps

module p_reg_file_tb;
  parameter REG_WIDTH = 64;
  
  reg clk;
  reg rst_n;
  reg [4:0] rs1_address;
  reg [4:0] rs2_address;
  reg [4:0] rs3_address;
  reg [4:0] rd_address;
  reg wr_enable;
  reg [REG_WIDTH-1:0] dataout_1;
  reg [REG_WIDTH-1:0] dataout_2;
  wire [REG_WIDTH-1:0] data1;
  wire [REG_WIDTH-1:0] data2;
  wire [REG_WIDTH-1:0] data3;

  p_reg_file #(REG_WIDTH) uut (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(rs1_address),
    .rs2_address(rs2_address),
    .rs3_address(rs3_address),
    .rd_address(rd_address),
    .wr_enable(wr_enable),
    .dataout_1(dataout_1),
    .dataout_2(dataout_2),
    .data1(data1),
    .data2(data2),
    .data3(data3)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("p_reg_file_tb.vcd");
    $dumpvars(0, p_reg_file_tb);

    clk = 0;
    rst_n = 1;
    wr_enable = 0;
    rs1_address = 5'b00000;
    rs2_address = 5'b00001;
    rs3_address = 5'b00010;
    rd_address = 5'b00000;
    dataout_1 = 64'hA5A5A5A5A5A5A5A5;
    dataout_2 = 64'h5A5A5A5A5A5A5A5A;
    
    // Apply reset
    #10 rst_n = 0;
    
    // Write to register
    #10 wr_enable = 1;
    #10 wr_enable = 0;
    
    // Read from registers
    #10 rs1_address = 5'b00000;
        rs2_address = 5'b00001;
        rs3_address = 5'b00010;
    
    #20;
    $finish;
  end
endmodule
