`timescale 1ns / 1ps

module tb_dlfloat16_top;

    // Inputs
    reg [3:0] ena;
    reg [2:0] rm;
    reg [2:0] sel2;
    reg op;
    reg [1:0] sel1;
    reg [15:0] op1, op2, op3;
    reg signed [31:0] in_int;

    // Outputs
    wire invalid, inexact, overflow, underflow, div_by_zero;
    wire [15:0] result;
    wire [31:0] out_1;

    // Instantiate the Unit Under Test (UUT)
    dlfloat16_top uut (
        .ena(ena),
        .rm(rm),
        .sel2(sel2),
        .op(op),
        .sel1(sel1),
        .op1(op1),
        .op2(op2),
        .op3(op3),
        .in_int(in_int),
        .invalid(invalid),
        .inexact(inexact),
        .overflow(overflow),
        .underflow(underflow),
        .div_by_zero(div_by_zero),
        .result(result),
        .out_1(out_1)
    );

    initial begin
        // Initialize Inputs
        ena = 4'b0000;
        rm = 3'b000;
        sel2 = 3'b000;
        op = 0;
        sel1 = 2'b00;
        op1 = 16'h0000;
        op2 = 16'h0000;
        op3 = 16'h0000;
        in_int = 32'h00000000;

        // Wait for global reset
        #100;

        // Test Addition
        ena = 4'b0001; // Enable addition
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h4000; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        
        ena = 4'b0001; // Enable addition
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h4000; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        
        ena = 4'b0001; // Enable addition
        op1 = 16'h0000; // 1.0 in dlfloat16
        op2 = 16'h0000; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        
        ena = 4'b0001; // Enable addition
        op1 = 16'hffff; // 1.0 in dlfloat16
        op2 = 16'h0000; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        
        ena = 4'b0001; // Enable addition
        op1 = 16'hffff; // 1.0 in dlfloat16
        op2 = 16'hffff; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        

        // Test Subtraction
        ena = 4'b0001; // Enable subtraction
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        op = 1; // Subtraction
        #100;
        
        ena = 4'b0001; // Enable subtraction
        op1 = 16'h4000; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        op = 1; // Subtraction
        #100;
        
        ena = 4'b0001; // Enable subtraction
        op1 = 16'h4200; // 1.0 in dlfloat16
        op2 = 16'h4480; // 1.0 in dlfloat16
        op = 1; // Subtraction
        #100;
        
        ena = 4'b0001; // Enable subtraction
        op1 = 16'hffff; // 1.0 in dlfloat16
        op2 = 16'h0000; // 1.0 in dlfloat16
        op = 1; // Subtraction
        #100;
        
        ena = 4'b0001; // Enable subtraction
        op1 = 16'h4480; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        op = 1; // Subtraction
        #100;
        
        // Test Multiplication
        ena = 4'b0010; // Enable multiplication
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        #100;
        
        // Test Division
        ena = 4'b0011; // Enable division
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        #100;
        
        // Test Square Root
        ena = 4'b0100; // Enable square root
        op1 = 16'h3C00; // 1.0 in dlfloat16
        #100;
        
        // Test Sign Injection
        ena = 4'b0101; // Enable sign injection
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'hBC00; // -1.0 in dlfloat16
        sel1 = 2'b01; // Sign injection normalized
        #100;
        
        // Test Comparison (Min)
        ena = 4'b0110; // Enable comparison
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        sel2 = 3'b001; // Min
        #100;
        
        // Test Integer to Float Conversion
        ena = 4'b0111; // Enable integer to float conversion
        in_int = 32'h00000001; // Integer 1
        #100;
        
        // Test Float to Integer Conversion
        ena = 4'b1000; // Enable float to integer conversion
        op1 = 16'h3C00; // 1.0 in dlfloat16
        #100;
       
        // Test MAC (Multiply-Accumulate)
        ena = 4'b1001; // Enable MAC
        op1 = 16'h3C00; // 1.0 in dlfloat16
        op2 = 16'h3C00; // 1.0 in dlfloat16
        op3 = 16'h3C00; // 1.0 in dlfloat16
        op = 0; // Addition
        #100;
        
        // Finish simulation
        #100;
        $finish;
    end

endmodule