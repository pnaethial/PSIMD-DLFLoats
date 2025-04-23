`timescale 1ns / 1ps

module tb_dlfloat16_sqrt;

    // Inputs
    reg [3:0] ena;
    reg [15:0] dl_in;

    // Outputs
    wire [19:0] dl_out_fin;
    wire [4:0] exceptions4;

    // Instantiate the Unit Under Test (UUT)
    dlfloat16_sqrt uut (
        .ena(ena),
        .dl_in(dl_in),
        .dl_out_fin(dl_out_fin),
        .exceptions4(exceptions4)
    );

    // Task to display output
    task print_output;
        begin
            $display("Input = %h | Output = %h | Exceptions = %b", dl_in, dl_out_fin, exceptions4);
        end
    endtask

    initial begin
        $display("Starting testbench...");
        ena = 4'b0100;

        // Test 1: Zero input
        dl_in = 16'h0000;
        #10; print_output();

        // Test 2: Positive normal number (1.0 in DLfloat16)
        // Sign = 0, Exp = 15 (bias 15), Mantissa = 0
        dl_in = 16'h3e00; // 1.0
        #10; print_output();

        // Test 3: Negative input (should return NaN and set invalid)
        dl_in = 16'h4440; // -2.0
        #10; print_output();

        // Test 4: Denormalized number (exp=0, mant!=0)
        dl_in = 16'h4200; // Smallest positive subnormal
        #10; print_output();

        // Test 5: Max value before overflow
        dl_in = 16'h4100; // Large value
        #10; print_output();

        // Test 6: Arbitrary number (e.g., sqrt(2) ≈ 1.414)
        dl_in = 16'h4480; // Approx 2.0
        #10; print_output();

        $display("Testbench complete.");
        $stop;
    end
endmodule

