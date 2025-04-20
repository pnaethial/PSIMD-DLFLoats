module dlfloat16_top(
  input wire [31:0] instr,
  input wire [31:0] op1,op2,op3,
  output wire invalid, inexact, overflow,underflow, div_by_zero,
  output wire [31:0] result,
  input clk,rst_n);
  
  wire [3:0] ena;
  wire [2:0] rm;
  wire [2:0] sel2;
  wire [1:0] sel1;
  wire op;
  wire [15:0] src1,src2,src3;
  assign src1 = op1[15:0];
  assign src2 = op2[15:0];
  assign src3 = op3[15:0];
  wire [19:0] out_add_sub, out_mul,out_div,out_mac,out_sqrt,out_sign,out_i2f,out_comp;
  wire [31:0] out_muxed;
  wire [31:0] out_f2i;
  wire [4:0] exceptions;
  
  dlfloat16_decoder dec(.instr(instr), .ena(ena), .rm(rm), .sel2(sel2), .sel1(sel1), .op(op));
  
  dlfloat16_add_sub add_sub(.a(src1), .b(src2), .ena(ena), .op(op), .exceptions(exceptions), .c_out(out_add_sub),.clk(clk),.rst_n(rst_n));
  dlfloat16_mul mul(.a(src1), .b(src2), .ena(ena), .c_mul(out_mul), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_div div(.a(src1), .b(src2), .ena(ena), .c_div(out_div), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_sqrt sqrt(.dl_in(src1), .ena(ena), .dl_out_fin(out_sqrt), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_mac mac(.a(src1), .b(src2), .d(src3), .c_out(out_mac), .ena(ena), .op(op), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_sign_inv sign_inv(.in1(src1), .in2(src2), .ena(ena), .sel(sel1), .out(out_sign), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  int32_to_dlfloat16 i2f(.in_int(op1), .ena(ena), .float_out1(out_i2f), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_to_int32 f2i(.float_in(src1), .ena(ena), .int_out_fin(out_f2i), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  dlfloat16_comp comp(.a1(src1), .b1(src2), .ena(ena), .sel(sel2), .c_out(out_comp), .exceptions(exceptions),.clk(clk),.rst_n(rst_n));
  
  out_mux outmux(.ena(ena), .out_add_sub(out_add_sub), .out_mul(out_mul), .out_div(out_div), .out_mac(out_mac), .out_sqrt(out_sqrt), .out_sign(out_sign), .out_i2f(out_i2f), .out_comp(out_comp), .out_f2i(out_f2i), .out_muxed(out_muxed));
  dl_exception excep(.exceptions(exceptions),.invalid(invalid),.inexact(inexact),.overflow(overflow),.underflow(underflow),.div_zero(div_by_zero));
  dlfloat16_round round(.rm(rm), .ena(ena), .in(out_muxed) , .out(result),.clk(clk),.rst_n(rst_n));
  
endmodule

module out_mux(input wire [3:0] ena, input wire [31:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt,out_sign, out_i2f, out_comp,out_f2i, output reg [31:0] out_muxed);

  always@(*)
    begin
      case(ena)
        4'b0001: out_muxed = out_add_sub;
        4'b0010: out_muxed = out_mul;
        4'b0011: out_muxed = out_div;
        4'b0100: out_muxed = out_sqrt;
        4'b0101: out_muxed = out_sign;
        4'b0110: out_muxed = out_comp;
        4'b1001: out_muxed = out_mac;
        4'b0111: out_muxed = out_i2f;
        4'b1000: out_muxed = out_f2i;
        default: out_muxed = 32'b0;
      endcase
    end
endmodule

module int32_to_dlfloat16(
  input signed [31:0] in_int, 
  input clk,rst_n,
  input [3:0] ena,
  output reg [4:0] exceptions,
  output reg [31:0] float_out1  
);
    reg [5:0] exponent;   
    reg [8:0] mantissa;    
    reg sign;             
    reg [31:0] abs_input;
    reg [15:0] float_out;
    integer i;
   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            float_out1 <= 32'b0;
            exceptions <= 5'b0;
        end else begin
          float_out1 <= {16'b0,float_out};
          if(in_int>512)
            exceptions = 5'b01000;
        end
    end
       
    always @(*) begin
      if(ena != 4'b0111)
        float_out = 16'b0;
      else begin
      if (in_int == 32'b0) begin
        float_out = 16'b0;
      end
      
      sign = (in_int < 0) ? 1 : 0;
        
      //determine absolute value
      abs_input = (in_int < 0) ? -in_int : in_int;
        
        // Normalize the number 
        exponent = 0;
        mantissa = 0;
        //NOTE: might get synth warnings for else block path but when i tried to add else block to exit from the loop threw synth errros
      // Find the exponent (shift the number to be in the form 1.xxxx)
       for (i = 0; i < 32 ; i = i + 1) begin
        if (abs_input >= (1 << (exponent + 1))) begin
            exponent = exponent + 1; 
        end
       end        
        // Shift the number to form the normalized mantissa
        if ( exponent <= 9) begin
          mantissa = abs_input << (9 - exponent);  // Left shift for +ve exp
           end else begin
             mantissa = abs_input >> (exponent - 9);// Right shift for -ve exp
           end

        
        //Bias the exponent 
        exponent = exponent + 31;
      
      float_out = {sign,exponent,mantissa};
      end 
    end
    
endmodule

module dlfloat16_to_int32(
  input clk,rst_n,
	input wire [3:0] ena,
  output reg [4:0] exceptions,
  input [15:0] float_in,
  output reg signed [31:0] int_out_fin
);
  reg sign;
  reg [5:0] exponent;
  reg [9:0] mantissa; 
  reg signed [5:0] actual_exponent;
  reg signed [31:0] int_out, result;
    
   always @(posedge clk or negedge rst_n) begin
     
        if (!rst_n) begin
            int_out_fin <= 32'b0;
           exceptions = 5'b0;
        end else begin
            int_out_fin <= int_out;
		     exceptions = 5'b0;
        end
    end
  
  always @(*) begin
	  if(ena != 4'b1000)
		  int_out = 32'b0;
	  else begin
    // Extract fields
    sign = float_in[15];
    exponent = float_in[14:9];
    mantissa = {1'b1, float_in[8:0]}; 

    // Handle special cases
    if (exponent == 0) begin
      int_out = 0;
    end  
    else if (exponent == 6'b111111) begin
      // Infinity or NaN: saturate to max 32-bit signed integer
      int_out = sign ? -32'h80000000 : 32'h7FFFFFFF;
    end else begin
  
      actual_exponent = exponent - 31; // Unbias the exponent
      
      if (actual_exponent <=9) begin
        result = {23'b0, mantissa >> ( 9 - actual_exponent)};
        end else begin
        result = mantissa << (actual_exponent - 9);
      end 
    
      int_out = sign ? -result : result;

      // Clamp to 32-bit signed range
      if (int_out > 32'h7FFFFFFF) int_out = 32'h7FFFFFFF;
      if (int_out < -32'h80000000) int_out = -32'h80000000; 
    end
  end
  end
endmodule

// Code your design here
//module dlfloat16_sqrt(
//	input [3:0] ena,
//	input clk,rst_n,
//    input  [15:0] dl_in,              
//	output reg [31:0] dl_out_fin,         
//    output reg [4:0] exceptions  
//);
//    wire sign = dl_in[15];                
//    wire [5:0] exp_in = dl_in[14:9];      
//    wire [8:0] mant_in = dl_in[8:0];      

  
//  reg [12:0] x, x_next;  // Current and next estimates for the square root of mantissa
//  reg [12:0] diff;      
//reg done;              //convergence flag
//  reg [12:0] remainder; 
   
//    reg [9:0] mant_norm;
//    initial begin
//   if (exp_in == 0) // Denormalized case
//            mant_norm = {1'b0, mant_in};
//        else
//            mant_norm = {1'b1, mant_in}; // Normalized case (add implicit 1)
//    end
   
//    reg [5:0] exp_out;      
//    reg [12:0] mant_sqrt;    
//    integer i;
//  reg [5:0] ier;
//	reg [19:0] dl_out;
//    reg invalid, overflow, underflow, inexact;
//    reg div_by_zero = 1'b0;

//	 always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//            dl_out_fin <= 32'b0;
//            exceptions <= 5'b0;
//            end 
//         else begin
//		dl_out_fin <= {12'b0,dl_out};
//		exceptions <= {invalid, inexact, overflow, underflow, div_by_zero};
//            end
//    end

//    always @(*) begin
//       $display("hi");
//       $display(exp_in,mant_in,mant_norm);
//        invalid = 0;
//        overflow = 0;
//        underflow = 0;
//        inexact = 0;
//		ier = 6'b0;
//      mant_sqrt = 13'b0;
//	    if (ena!=4'b0100) 
//		    dl_out = 20'b0; 
//	    else begin
	    
//        //special cases
//        if (dl_in == 16'h0000) begin
//            // Zero input
//            dl_out = 20'h00000;  // Output is zero
//        end
//        if (sign == 1'b1) begin
//            // Negative input
//            dl_out = 20'hFFFFF;  // NaN representation
//            invalid = 1'b1;
//        end
//        else begin

//          if (exp_in == 6'b0) begin//Denormalized input
//                exp_out = 6'b0;  
//            end
//             else begin
//             $display("hel");
//              if(exp_in[0] ==1'b1)
//                begin
//                $display("heo");
//                  ier = (exp_in+1)/2;
////                  mant_norm = mant_norm >> 1;
//                    $display("1:%b",ier);
//                end
//              else
//                ier = exp_in/2;
//                $display(ier);
//            end
//			exp_out = ier +31; // Add bias
//            // square root of mantissa
//             // Edge case handling
//        $display(mant_norm);
//          if (mant_norm == 0) begin
//        mant_sqrt = 0;
//        $display("here??");
//          end else if (mant_norm == 1) begin
//        mant_sqrt = 1;
//        $display("are yoou");
//         for (i = 0; i < 8 && !done; i = i + 1) begin
//           x_next = (x + (mant_norm / x)) >> 1; // New estimate= average of x and num/x
//            diff = (x > x_next) ? (x - x_next) : (x_next - x); 
//          $display("Iteration %d | x: %d | x_next: %d | diff: %d", i, x, x_next, diff);
//            if (diff <= 1) begin
//                done = 1; 
//            end

//            x = x_next; 
//        end
//             $display("Iteration %d | x: %d | x_next: %d | diff: %d", i, x, x_next, diff);
//            mant_sqrt = x;
//            remainder = mant_norm - (x * x); //remainder calculated for better approximation
            
//            if (remainder >= (2 * x )) begin // round up if remainder is large
//            mant_sqrt = mant_sqrt + 1;
//        end
            
//            // Check for inexact result
//            if (mant_sqrt * mant_sqrt != (mant_norm << 3)) begin
//                inexact = 1'b1;
//            end

//            // Check for overflow and underflow
//            if (exp_out > 6'b111110) begin
//                overflow = 1'b1;
//                dl_out = 20'h7DFE0;  
//            end else if (exp_out == 6'b0 && mant_sqrt == 13'b0) begin
//                underflow = 1'b1;
//                dl_out = 20'h00000;  
//            end else begin
            
//                dl_out = {1'b0, exp_out, mant_sqrt};
//            end
//        end
//	end
//	end
//	end
//endmodule


//module dlfloat16_sqrt(
//    input [3:0] ena,    // Enable signal
//    input clk, rst_n,   // Clock and active-low reset
//    input [15:0] dl_in, // 16-bit DLFloat input
//    output reg [15:0] dl_out, // 16-bit DLFloat output
//    output reg [4:0] exceptions // Flags: {invalid, inexact, overflow, underflow, div_by_zero}
//);

//    // Extract DLFloat16 components
//    wire sign = dl_in[15];           // Sign bit
//    wire [5:0] exp_in = dl_in[14:9]-31 ; // Exponent
//    wire [8:0] mant_in = dl_in[8:0]; // Mantissa
//    // Internal registers
//    reg [12:0] x, x_next; // Newton-Raphson estimation
//    reg [12:0] diff;      // Difference between successive iterations
//    reg done;             // Convergence flag
//    reg [12:0] remainder; // Remainder for better approximation

//    reg [9:0] mant_norm; // Normalized mantissa
//    reg [5:0] exp_out;   // Output exponent
//    reg [12:0] mant_sqrt; // Square root of mantissa
//    reg [5:0] ier;       // Intermediate exponent representation

//    // Exception flags
//    reg invalid, overflow, underflow, inexact;
//    reg div_by_zero = 1'b0;

//    // Mantissa normalization
//    always @(*) begin
//        if (exp_in == 0) // Denormalized case
//            mant_norm = {1'b0, mant_in};
//        else
//            mant_norm = {1'b1, mant_in}; // Normalized case (add implicit 1)
//    end

//    always @(posedge clk or negedge rst_n) begin
//    $display("exp:%b, mantin:%b",exp_in, mant_in);
//        if (rst_n) begin
//            dl_out <= 16'b0;
//            exceptions <= 5'b0;
//        end 
//        else if (ena == 4'b0100) begin // Check enable signal
//            // Reset flags
//            invalid = 0;
//            overflow = 0;
//            underflow = 0;
//            inexact = 0;
//            ier = 6'b0;
//            mant_sqrt = 13'b0;
//            done = 0;
////                case (mant_in[8:4]) // Approximate sqrt(mantissa)
////                5'b00000: mant_sqrt=9'b000000000;
////                5'b00001: mant_sqrt = 9'b000101000;
////                5'b00010: mant_sqrt = 9'b001010000;
////                5'b00011: mant_sqrt = 9'b001101000;
////                5'b00100: mant_sqrt = 9'b010000000;
////                5'b00101: mant_sqrt = 9'b010011000;
////                5'b00110: mant_sqrt = 9'b010110000;
////                5'b00111: mant_sqrt = 9'b011001000;
////                default: mant_sqrt = 9'b011111111; // Max approximation
////                endcase


//        if (mant_norm == 0) begin
//          mant_sqrt = 0;
//          end else if (mant_norm == 1) begin
//          mant_sqrt = 1;
//         for (i = 0; i < 8 && !done; i = i + 1) begin
//           x_next = (x + (mant_norm / x)) >> 1; // New estimate= average of x and num/x
//            diff = (x > x_next) ? (x - x_next) : (x_next - x); 

//            if (diff <= 1) begin
//                done = 1; 
//            end

//            x = x_next; 
//        end

//            mant_sqrt = x;
//            remainder = mant_norm - (x * x); //remainder calculated for better approximation
            
//            if (remainder >= (2 * x )) begin // round up if remainder is large
//            mant_sqrt = mant_sqrt + 1;
//        end
            
//            // Check for inexact result
//            if (mant_sqrt * mant_sqrt != (mant_norm << 3)) begin
//                inexact = 1'b1;
//            end
//            // Special case: Zero input
//            if (dl_in == 16'h0000) begin
//                dl_out = 16'h0000; // Output is zero
//            end
//            // Special case: Negative input (invalid for sqrt)
//            else if (sign == 1'b1) begin
//                dl_out = 16'hFFFF; // NaN representation
//                invalid = 1'b1;
//            end
//            else begin
//                // Adjust exponent
//                $display("hi");
//                if (exp_in == 6'b0) begin // Denormalized input
//                    exp_out = 6'b0;
//                end
//                else begin
//                    if (exp_in[0] == 1'b1) begin
//                        ier = (exp_in + 1) >> 1;
//                        mant_norm = mant_norm >> 1;
//                    end
//                    else
//                        ier = exp_in >> 1;
//                end
//                exp_out = ier+31 ; // Adjusted exponent (bias)

            

//                // Check for overflow and underflow
//                if (exp_out > 6'b111110) begin
//                    exceptions[2] = 1'b1;    //overflow
//                    dl_out = 16'h7C00; // Maximum positive float
//                    $display("will1");
//                end 
//                else if (exp_out == 6'b0 && mant_sqrt == 13'b0) begin
//                    exceptions[1] = 1'b1;   //underflow
//                    dl_out = 16'h0000; // Zero
//                    $display("will2");
//                end 
              
//                else begin
//                $display("d_in,%h,%b,%b",dl_in,exp_out,mant_sqrt);
//                    dl_out = {1'b0, exp_out, mant_sqrt[8:0]};
//                end
//            end
//        end
//    end
//endmodule




//module dlfloat16_sqrt (
//    input logic [3:0] ena,   // Enable signal
//    input logic clk, rst_n,  // Clock and active-low reset
//    input logic [15:0] dl_in, // 16-bit DLFloat input
//    output logic [15:0] dl_out, // 16-bit DLFloat output
//    output logic [4:0] exceptions // Flags: {invalid, inexact, overflow, underflow, div_by_zero}
//);

//    // Extract DLFloat16 components
//    logic sign;
//    logic [5:0] exp_in;
//    logic [8:0] mant_in;
    
//    assign sign = dl_in[15];                 // Sign bit
//    assign exp_in = dl_in[14:9] - 31;         // Exponent (bias adjusted)
//    assign mant_in = dl_in[8:0];              // Mantissa

//    // Internal registers
//    logic [9:0] mant_norm;  // Normalized mantissa (implicit 1)
//    logic [4:0] exp_out;    // Output exponent
//    logic [9:0] mant_sqrt;  // Square root of mantissa
//    logic [9:0] temp;       // Temporary variable for root calculation
//    logic [9:0] bit;        // Current bit to check

//    // Exception flags
//    logic invalid, overflow, underflow, inexact;
//    assign exceptions = {invalid, inexact, overflow, underflow, 1'b0};

//    // Normalize mantissa (if denormalized)
//    always_comb begin
//        if (exp_in == 0)
//            mant_norm = {1'b0, mant_in}; // Denormalized case
//        else
//            mant_norm = {1'b1, mant_in}; // Normalized case (implicit 1)
//    end

//    // Bitwise square root computation
//    always_ff @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            dl_out <= 16'b0;
//            invalid <= 0;
//            overflow <= 0;
//            underflow <= 0;
//            inexact <= 0;
//        end 
//        else if (ena == 4'b0100) begin // Enable signal check
//            invalid <= 0;
//            overflow <= 0;
//            underflow <= 0;
//            inexact <= 0;
//            mant_sqrt <= 0;
//            temp <= 0;
//            bit <= 10'b1000000000; // Start with the highest bit

//            if (sign == 1'b1) begin
//                // Invalid input: Negative number
//                dl_out <= 16'hFFFF; // NaN representation
//                invalid <= 1'b1;
//            end 
//            else if (mant_norm == 0) begin
//                // Special case: Zero input
//                dl_out <= 16'h0000;
//            end 
//            else begin
//                // Perform bitwise square root computation
//                for (int i = 0; i < 10; i = i + 1) begin
//                    temp = mant_sqrt | bit;
//                    if (temp * temp <= mant_norm) begin
//                        mant_sqrt = temp;
//                    end
//                    bit = bit >> 1;
//                end

//                // Adjust exponent
//                if (exp_in[0] == 1'b1) begin
//                    exp_out = (exp_in + 1) >> 1; // Bias adjustment
//                end else begin
//                    exp_out = exp_in >> 1;
//                end
//                exp_out = exp_out + 31; // Reapply bias

//                // Check for overflow/underflow
//                if (exp_out > 6'b111110) begin
//                    overflow <= 1'b1;
//                    dl_out <= 16'h7C00; // Max positive float
//                end 
//                else if (exp_out == 6'b0 && mant_sqrt == 10'b0) begin
//                    underflow <= 1'b1;
//                    dl_out <= 16'h0000; // Zero output
//                end 
//                else begin
//                    dl_out <= {1'b0, exp_out, mant_sqrt[8:0]}; // Final result
//                end
//            end
//        end
//    end

//endmodule






//module dlfloat16_sqrt(
//    input [3:0] ena,    // Enable signal
//    input clk, rst_n,   // Clock and active-low reset
//    input [15:0] dl_in, // 16-bit DLFloat input
//    output reg [15:0] dl_out, // 16-bit DLFloat output
//    output reg [4:0] exceptions // Flags: {invalid, inexact, overflow, underflow, div_by_zero}
//);

//    // Extract DLFloat16 components
//    wire sign = dl_in[15];           // Sign bit
//    wire [5:0] exp_in = dl_in[14:9]-31 ; // Exponent
//    wire [8:0] mant_in = dl_in[8:0]; // Mantissa
//    // Internal registers
//    reg [12:0] x, x_next; // Newton-Raphson estimation
//    reg [12:0] diff;      // Difference between successive iterations
//    reg done;             // Convergence flag
//    reg [12:0] remainder; // Remainder for better approximation

//    reg [9:0] mant_norm; // Normalized mantissa
//    reg [5:0] exp_out;   // Output exponent
//    reg [12:0] mant_sqrt; // Square root of mantissa
//    reg [5:0] ier;       // Intermediate exponent representation

//    // Exception flags
//    reg invalid, overflow, underflow, inexact;
//    reg div_by_zero = 1'b0;

//    // Mantissa normalization
//    always @(*) begin
//        if (exp_in == 0) // Denormalized case
//            mant_norm = {1'b0, mant_in};
//        else
//            mant_norm = {1'b1, mant_in}; // Normalized case (add implicit 1)
//    end

//    always @(posedge clk or negedge rst_n) begin
//    $display("exp:%b, mantin:%b",exp_in, mant_in);
//        if (rst_n) begin
//            dl_out <= 16'b0;
//            exceptions <= 5'b0;
//        end 
//        else if (ena == 4'b0100) begin // Check enable signal
//            // Reset flags
//            invalid = 0;
//            overflow = 0;
//            underflow = 0;
//            inexact = 0;
//            ier = 6'b0;
//            mant_sqrt = 13'b0;
//            done = 0;

//            // Special case: Zero input
//            if (dl_in == 16'h0000) begin
//                dl_out = 16'h0000; // Output is zero
//            end
//            // Special case: Negative input (invalid for sqrt)
//            else if (sign == 1'b1) begin
//                dl_out = 16'hFFFF; // NaN representation
//                invalid = 1'b1;
//            end
//            else begin
//                // Adjust exponent
//                $display("hi");
//                if (exp_in == 6'b0) begin // Denormalized input
//                    exp_out = 6'b0;
//                end
//                else begin
//                    if (exp_in[0] == 1'b1) begin
//                        ier = (exp_in + 1) >> 1;
//                        mant_norm = mant_norm >> 1;
//                    end
//                    else
//                        ier = exp_in >> 1;
//                end
//                exp_out = ier+31 ; // Adjusted exponent (bias)

//                // Compute square root of mantissa using Newton-Raphson
//                x = mant_norm; // Initial guess
//                $display("mantin=%b",mant_in);
//                 $display("mant=%b",mant_norm);
//                done = 0;
//                x = mant_norm >> 1; // Initial approximation
            
//                for (integer i = 0; i < 8 && !done; i = i + 1) begin
//                    x_next = (x + (mant_norm / x)) >> 1; // Newton-Raphson update
//                    diff = (x > x_next) ? (x - x_next) : (x_next - x);
//                    $display("Iteration %0d: x=%b, x_next=%b, diff=%b", i, x, x_next, diff);
            
//                    if (diff == 0) begin
//                        done = 1;
//                    end
//                    x = x_next;
//                end
            
//                mant_sqrt = x; // Store final result
//                $display("final x=%b, x_next=%b,mant_sqrt", x, x_next,mant_sqrt);

//                remainder = mant_norm - (x * x);
//                $display("Rem:%b",remainder);
//                // Rounding
//                if (remainder >= (2 * x)) begin
//                    mant_sqrt = mant_sqrt + 1;
//                end

//                // Check for inexact result
//                if (mant_sqrt * mant_sqrt != (mant_norm << 3)) begin
//                $display("will");
//                    exceptions[3] = 1'b1;
                    
//                end

//                // Check for overflow and underflow
//                if (exp_out > 6'b111110) begin
//                    exceptions[2] = 1'b1;    //overflow
//                    dl_out = 16'h7C00; // Maximum positive float
//                    $display("will1");
//                end 
//                else if (exp_out == 6'b0 && mant_sqrt == 13'b0) begin
//                    exceptions[1] = 1'b1;   //underflow
//                    dl_out = 16'h0000; // Zero
//                    $display("will2");
//                end 
              
//                else begin
//                $display("d_in,%h,%b,%b",dl_in,exp_out,mant_sqrt);
//                    dl_out = {1'b0, exp_out, mant_sqrt[8:0]};
//                end
//            end
//        end
//    end
//endmodule



module dlfloat16_sign_inv (
  input [15:0] in1, 
  input [15:0] in2,  
  input [1:0] sel,
  input wire clk,rst_n,
	output reg [31:0] out,
	output reg [4:0] exceptions,
	 input [3:0] ena
);
 reg [15:0] out_comb;
always @(posedge clk or negedge rst_n) begin
  
        if (!rst_n) begin
            out <= 32'b0;
            exceptions <= 5'b0;
        end else begin
		out <= {16'b0,out_comb};
		exceptions <= 5'b0;
        end
    end
  always @(*) begin
	  if(ena !=4'b0101)
		  out_comb = 16'b0;
	  else begin
    case (sel)
      2'b00: out_comb = {~in1[15], in2[14:0]}; // invert
      2'b01: out_comb = {in1[15], in2[14:0]};  // sign injection normalized
      2'b10: out_comb = {~in1[15], in2[14:0]}; // sign injection inverse
      2'b11: out_comb = {in1[15] ^ in2[15], in2[14:0]}; // sign injection xor
      default: out_comb = 16'h0000;
    endcase
  end
  end


endmodule


module dlfloat16_round ( input [31:0] in, input [3:0] ena,
                      input [2:0] rm,
                      input rst_n,
                      input clk,
                        output reg [31:0] out);
  
  reg G_bit,R_bit, S1_bit , S2_bit, S_bit;
  reg [15:0]out1;
  reg sign;
  reg [5:0] exp;
  reg [9:0] mant1;
  reg [8:0] mant;
  reg [2:0] rm1;
  reg [19:0] in1;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out<= 32'b0;
    end else begin
      if(ena !=4'b1000)
      out <= {16'h0000,out1}; 
      else
        out <= in;
    end
  end
    always@(*) begin 
      in1 = in [19:0];
      G_bit  = in1[3];
      R_bit  = in1[2];
      S1_bit = in1[1];
      S2_bit = in1[0];
      mant1  = {1'b0, in1[12:4]};
      exp    = in1[18:13];
      sign   = in1[19];
      rm1    = rm;
      
      S_bit  = S1_bit | S2_bit;
      
      case(rm) 
        //ROUND TO NEAREST,TIES TO EVEN
        000: begin
          if(!G_bit) begin
            mant = mant1[8:0];//no rounding
          end
          else begin
            if ( R_bit + S_bit) begin
              if(in1[4])begin //if lsb of mant is 1 add 1 and change exp accordingly
                mant1 = mant1 + 1;
                mant = mant1[8:0];
                exp = mant1[9]? exp+1'b1: exp;
              end
              else begin
                mant = mant1[8:0];//if lsb is zero leave it as it is
              end
            end
            else begin //if R+S is zero add 1 to mant
                mant1 = mant1 + 1;
                mant = mant1[8:0];
                exp = mant1[9]? exp+1'b1: exp;
            end
          end//else block
        end//case block
        
        
        //ROUND TO ZERO
        001: begin 
          mant = mant1[8:0];//truncate GRS bits and leave it 
        end  
        
       //ROUND UP  
        010: begin
          if (G_bit + R_bit + S_bit) begin
            if(!sign)begin //add 1 to mant if num is +ve
                mant1 = mant1 + 1;
                mant = mant1[8:0];
                exp = mant1[9]? exp+1'b1: exp;
            end
            else begin //nothing if num is -ve
              mant = mant1[8:0];
            end
          end
          else begin //if g+r+s is zero no rounding
            mant = mant1[8:0];
          end
       end//case block
        
        //ROUND DOWN
        011: begin
           if (G_bit + R_bit + S_bit) begin
             if(sign)begin //add 1 to mant if num is -ve
                mant1 = mant1 + 1;
                mant = mant1[8:0];
                exp = mant1[9]? exp+1'b1: exp;
             end
            else begin //nothing if num is +ve
              mant = mant1[8:0];
            end
          end
          else begin //if g+r+s is zero no rounding
            mant = mant1[8:0];
          end
          
        end//case block
        
        default: rm1 = 3'b0;
            
      endcase
       
      out1 = {sign,exp,mant}; 
    end
  
endmodule  
      
    
// Code your design here
module dlfloat16_mul(a,b,ena,c_mul,clk,rst_n,exceptions);
  input  [15:0]a,b;
  input clk,rst_n;
	input [3:0] ena;
	output  reg [31:0] c_mul;
  output reg [4:0] exceptions;
    
    reg [9:0]ma,mb; //1 extra because 1.smthng
  reg [12:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
  reg [19:0] c_mul1;
	reg invalid, inexact, overflow, underflow, div_zero;

  always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_mul <= 32'b0;
            exceptions <= 5'b0;
        end else begin
		c_mul <= {12'b0,c_mul1};
		exceptions <= {invalid, inexact, overflow, underflow, div_zero};
        end
    end
  	
  always@(*) begin
    invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
        ma ={1'b1,a[8:0]};
        mb= {1'b1,b[8:0]};
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];
  	
       //to avoid latch inference
  	e_temp = 6'b0;
  	m_temp = 20'b0;
  	mant=9'b0;
  	exp= 6'b0;
  	s=0;
	  if(ena !=4'b0010)
		  c_mul1 =20'b0;
	  else begin

		  
  	//checking for underflow/overflow
    if (  (ea + eb) <= 31 ) begin
      underflow = 1'b1;
  		c_mul1=16'b0;//pushing to zero on underflow
  	end
    else if ( (ea + eb) > 94) begin
      overflow = 1'b1;
      if( (sa ^ sb) ) begin
          c_mul1=16'hFDFE;//pushing to largest -ve number on overflow
        end
      else begin
          c_mul1=16'h7DFE;//pushing to largest +ve number on overflow
      end
    end
        
  	else if ( (ea + eb) == 94 ) begin
      invalid = 1'b1;
		c_mul1=16'hFFFF;//pushing to inf if exp is all ones
 	end
        else begin	
        e_temp = ea + eb - 31;
        m_temp = ma * mb;
		
          mant = m_temp[19] ? m_temp[18:6] : m_temp[17:5];
        exp = m_temp[19] ? e_temp+1'b1 : e_temp;	
        s=sa ^ sb;
		
 	//checking for special cases	
         if( a==16'hFFFF | b==16'hFFFF ) begin
            c_mul1 =16'hFFFF;
         end
        else begin
           c_mul1 = (a==0 | b==0) ? 0 :{s,exp,mant};
         end 
 	end 
	  if(c_mul1[19:15] != 4'b0000)
      inexact = 1'b1;
    end 
  end
	wire _unused = &{m_temp[8:0], 9'b0};
endmodule 

 



module dlfloat16_div(
    input [3:0] ena,
    input [15:0] a, b,
    output reg [19:0] c_div,         // 1-bit sign, 6-bit exponent, 13-bit mantissa
    output reg [4:0] exceptions 
);
    reg [9:0] ma, mb;       
    reg [12:0] mant;        
    reg [12:0] m_temp;     
    reg [5:0] ea, eb, e_temp, exp;
    reg sa, sb, s;
    reg [19:0] c_div1;      

    reg div_by_zero, underflow, overflow, inexact, invalid;

            

    always @(*) begin
        c_div = c_div1;
        exceptions = {invalid, inexact, overflow, underflow, div_by_zero};
        ma = {1'b1, a[8:0]}; 
        mb = {1'b1, b[8:0]}; 
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];

        // Default values to avoid latch inference
        e_temp = 6'b0;
        m_temp = 16'b0;
        mant = 13'b0;
        exp = 6'b0;
        s = 0;
        c_div1 = 20'b0; 
        div_by_zero = 1'b0;
        underflow = 1'b0;
        overflow = 1'b0;
        inexact = 1'b0;
        invalid = 1'b0;
        if(ena != 4'b0011)
            c_div1 = 20'b0;
        else begin
        // Special Cases
      if(( b == 16'b0 || b==16'b1000000000000000) &&(a==16'b0 || a==16'b1000000000000000))
            begin
              c_div1 = {sa ^sb,15'b111111111111111,4'b0};
              invalid = 1'b1;
            end
      
       else if (b == 16'b0 || b == 16'b1000000000000000) begin
            
            div_by_zero = 1'b1;
            c_div1 = {sa ^ sb, 6'b111111, 13'b0};
        end else if (a == 16'hfe00 || a == 16'h7e00) begin
            
          if (b == 16'hFe00 || b == 16'h7e00) begin
                
                invalid = 1'b1;
            c_div1 = {sa ^sb,15'b111111111111111,4'b0}; 
            end else begin
               
                c_div1 = {sa ^ sb, 6'b111111, 13'b0}; 
            end
        end else if (b == 16'hfe00 || b == 16'h7e00) begin
           
            c_div1 = {sa ^ sb, 19'b0};
        end else if (a == 16'b0 || a == 16'b1000000000000000) begin
            
          
            c_div1 = {sa ^ sb, 19'b0};
        end else begin
            
          e_temp = 31-(eb-ea);
          m_temp = ma / mb; 
          if (m_temp[10]) begin
            mant = m_temp; 
                exp = e_temp;
            end else begin
              mant = m_temp<<1; 
                exp = e_temp -1'b1;
            end
            s = sa ^ sb;

            
          if (m_temp[3:0] != 4'b0) begin
                inexact = 1'b1;
            end

            // Check for underflow/overflow
            if (exp < 0) begin
                underflow = 1'b1;
                c_div1 = 20'b0; 
            end else if (exp > 63) begin
                overflow = 1'b1;
                c_div1 = s ? 20'hFDFE0 : 20'h7DFE0; 
            end else begin
                c_div1 = {s, exp, mant};
            end
        end
        end
    end
endmodule


// Code your design here
module dlfloat16_decoder(
  input wire [31:0] instr,
  output reg [3:0] ena,
  output reg [2:0] rm,
  output reg [2:0] sel2,// for cmpr
  output reg op,
  output reg [1:0] sel1);// for sign inj
  
  wire [4:0] fun5;
  wire [6:0] opcode;
  
  assign opcode = instr[6:0];
  assign fun5 = instr[31:27];
  always@(*)
    
    begin
      rm = instr[14:12];
      ena = 4'b0000;
      op = 1'b0;
      sel1 = 2'b00;
      sel2 = 3'b000;
      if (opcode == 7'b1011011)
        begin
          case({fun5,rm})
            8'b00000000: begin op = 1'b0; //add
              ena = 4'b0001; end
            8'b00001000:begin op = 1'b1; //sub
              ena = 4'b0001; end
            8'b00010000:begin ena = 4'b0010; //mul
            end
            8'b00011000:begin ena = 4'b0011; //div
            end
            8'b01011000:begin ena = 4'b0100; //sqrt
            end
            8'b00100000:begin ena = 4'b0101; //sign inject
              sel1 = 2'b01;
            end
            8'b00100001: begin ena = 4'b0101; // sign inject neg
              sel1 = 2'b10; end
            8'b00100010:begin ena = 4'b0101; //sign inject xor
              sel1 = 2'b11; end
            8'b00101000: begin ena = 4'b0110; 
              sel2 = 3'b001;//min
            end
            8'b00101001: begin ena = 4'b0110;
              sel2 = 3'b010;//max
            end
            8'b01000000:begin ena = 4'b0111; //int to float
            end
            8'b01001000:begin ena = 4'b1000;end//float to int
            8'b10100010: begin ena = 4'b0110;//eq
              sel2 = 3'b011; end
            8'b10100001: begin ena = 4'b0110;// less than
            sel2 = 3'b100;end
            8'b10100000: begin ena = 4'b0110;//less than eq
              sel2 = 3'b101; end
          endcase
        end
      else if (opcode ==7'b0011011)//fma
        begin
          ena = 4'b1001;
          op = 1'b0;
        end
      else if (opcode == 7'b0111011)//fms
        begin 
          ena = 4'b1001;
          op = 1'b1;
        end
    end
endmodule
       
            
          
          
// Code your design here
module dlfloat16_comp (
  input [15:0] a1,
  input [15:0] b1,
  input [2:0] sel,
  input clk,
  input rst_n,
	input [3:0] ena,
  output reg [4:0] exceptions,
	output reg [31:0] c_out
);
  reg s1, s2;
  reg [5:0] exp1, exp2;
  reg [8:0] mant1, mant2;
  reg lt, gt, eq;
  reg [15:0] c_1;
   reg invalid, inexact, overflow, underflow, div_zero;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_out <= 32'b0;
            exceptions <= 5'b0;
        end else begin
		c_out <= {16'b0,c_1};
		exceptions <= {invalid, inexact, overflow, underflow, div_zero};
        end
    end
  always @(*) begin
     invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
	  if(ena != 4'b0110)
		  c_1 =16'b0;
	  else begin
    // Extract fields
    s1 = a1[15];
    s2 = b1[15];
    exp1 = a1[14:9];
    exp2 = b1[14:9];
    mant1 = a1[8:0];
    mant2 = b1[8:0];
    lt = 0;
    gt = 0;
    eq = 0;
    c_1 = 16'h0000;
  
    
    // Compare logic
    if (s1 != s2) begin
      if (s1) begin
        lt = 1;
      end else begin
        gt = 1;
      end
    end else begin
      if (exp1 > exp2) begin
        gt = !s1;
        lt = s1;
      end else if (exp1 < exp2) begin
        lt = !s1;
        gt = s1;
      end else begin
        if (mant1 > mant2) begin
          gt = !s1;
          lt = s1;
        end else if (mant1 < mant2) begin
          lt = !s1;
          gt = s1;
        end else begin
          eq = 1;
        end
      end
    end
  
    // Generate output based on opcode
    case (sel)
      3'b001: c_1 = (lt ==1'b1)?a1:b1;//min
      3'b010: c_1 = (gt ==1'b1)?a1:b1;//max
      3'b011: c_1 = {16{eq}};//set eq
      3'b100: c_1 = {16{lt}};//set less than
      3'b101: c_1 = (lt ==1'b1 || eq ==1'b1)?16'hffff:16'h0000;//set less than equal
      default: c_1 = 16'b0;
    endcase
    if (c_1 == 16'h0000)
      underflow =1'b1;
    if(c_1 == 16'hffff)
      overflow = 1'b1;
  end
  end


endmodule


module dlfloat16_add_sub(input [15:0] a, input [15:0] b,input op,input [3:0] ena, output reg [31:0] c_out, input clk,input rst_n, output reg [4:0] exceptions);
   
  reg [19:0] c_add;
    reg    [5:0] Num_shift_80; 
    reg    [5:0]  Larger_exp_80,Final_expo_80;
    reg    [9:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80;
  reg    [12:0] Final_mant_80;
    reg    [10:0] Add_mant_80,Add1_mant_80;
    reg    [5:0]  e1_80,e2_80;
    reg    [8:0] m1_80,m2_80;
    reg          s1_80,s2_80,Final_sign_80;
    reg    [8:0]  renorm_shift_80;
    reg signed [5:0] renorm_exp_80;
    reg signed [5:0] larger_expo_neg;
  reg invalid, inexact, overflow, underflow, div_zero;

 // wire [3:0] check = c_add[19:15];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_out <= 32'b0;
            exceptions <= 5'b0;
        end else begin
		c_out <= {12'b0,c_add};
		exceptions <= {invalid, inexact, overflow, underflow, div_zero};
        end
    end
    always@(*) begin
	    invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
        //stage 1
     	     e1_80 = a[14:9];
    	     e2_80 = b[14:9];
             m1_80 = a[8:0];
     	     m2_80 = b[8:0];
             s1_80 = a[15];
	    if(ena != 4'b0001)
		    c_add = 20'b0;
	    else begin
           if(op) begin
             s2_80 = ~b[15]; //for subtraction op will be 1
           end
           else begin
              s2_80 = b[15];
            end
        
	       Num_shift_80=6'b0;
	  
           if (e1_80  > e2_80) begin
              Num_shift_80           = e1_80 - e2_80;
              Larger_exp_80          = e1_80;                     
              Small_exp_mantissa_80  = {1'b1,m2_80};
              Large_mantissa_80      = {1'b1,m1_80};
           end
        
           else begin
             Num_shift_80           = e2_80 - e1_80;
             Larger_exp_80          = e2_80;
             Small_exp_mantissa_80  = {1'b1,m1_80};
             Large_mantissa_80      = {1'b1,m2_80};
           end
        
	    if (e1_80 == 0 | e2_80 ==0) begin
	        Num_shift_80 = 0;
	       Small_exp_mantissa_80 = 10'd512; //to avoid subnormal mantissa to be greater than normal mantissa pushing it to all zeros and leading 1      
	    end
	    else begin
	        Num_shift_80 = Num_shift_80;
	    end
            
            
           //stage 2 
           //shift and append smaller mantissa
	    Small_exp_mantissa_80  = (Small_exp_mantissa_80 >> Num_shift_80);
              
           //stage 3
           //add the mantissas
                                                    
            if (Small_exp_mantissa_80  < Large_mantissa_80) begin
		   S_mantissa_80 = Small_exp_mantissa_80;
	    	   L_mantissa_80 = Large_mantissa_80;
            end
            else begin
			
		   S_mantissa_80 = Large_mantissa_80;
		   L_mantissa_80 = Small_exp_mantissa_80;
            end       
                       
            Add_mant_80=11'b0;
	
	    if (e1_80!=0 & e2_80!=0) begin
		   if (s1_80 == s2_80) begin
        		Add_mant_80 = S_mantissa_80 + L_mantissa_80;
		    end else begin
			   Add_mant_80 = L_mantissa_80 - S_mantissa_80;
		    end
	    end	
 	    else begin
		    Add_mant_80 ={1'b0, L_mantissa_80};
	    end
      
	   //renormalization for mantissa and exponent
           //stage 4
	   //to avoid latch inference
	   renorm_exp_80=6'd0;
	   renorm_shift_80=9'd0;
	   Add1_mant_80=Add1_mant_80;
	   
           if (Add_mant_80[10] ) begin
		   Add1_mant_80= Add_mant_80 >> 1;
		   renorm_exp_80 = 6'd1;
	   end
           else begin 
              if (Add_mant_80[9])begin
	   	     renorm_shift_80 = 0;
	   	     renorm_exp_80 = 0;		
	      end
              else if (Add_mant_80[8])begin
	   	     renorm_shift_80 = 9'd1; 
	   	     renorm_exp_80 = -1;
	      end 
              else if (Add_mant_80[7])begin
	      	      renorm_shift_80 = 9'd2; 
	      	      renorm_exp_80 = -2;		
	      end  
              else if (Add_mant_80[6])begin
	    	      renorm_shift_80 = 9'd3; 
	    	      renorm_exp_80 = -3;		
	      end
              else if (Add_mant_80[5])begin
	    	      renorm_shift_80 = 9'd4; 
	   	      renorm_exp_80 = -4;		
	      end
              else if (Add_mant_80[4])begin
	    	      renorm_shift_80 = 9'd5; 
	    	      renorm_exp_80 = -5;		
	      end
              else if (Add_mant_80[3])begin
	   	      renorm_shift_80 = 9'd6; 
	   	      renorm_exp_80 = -6;		
	      end
              else if (Add_mant_80[2])begin
	   	      renorm_shift_80 = 9'd7; 
	   	      renorm_exp_80 = -7;		
	       end
              else if (Add_mant_80[1])begin
	   	      renorm_shift_80 = 9'd8; 
	    	      renorm_exp_80 = -8;		
	      end
              else if (Add_mant_80[0])begin
	    	      renorm_shift_80 = 9'd9; 
	    	      renorm_exp_80 = -9;		
	      end
	      else begin
		      renorm_exp_80=6'd0;
	              renorm_shift_80=9'd0;
	              Add1_mant_80=Add1_mant_80;
	      end
	  	   
              Add1_mant_80 = Add_mant_80 << renorm_shift_80;
            
          end

          Final_expo_80 = 6'd0;//to avoid latch inference
	      Final_mant_80 = 9'd0;//to avoid latch inference  
	      Final_sign_80=0;//to avoid latch inference 
          larger_expo_neg = -Larger_exp_80;
      
        //calculating final sign	   
	       if (s1_80 == s2_80) begin
		     Final_sign_80 = s1_80;
	       end 
	       else begin   //if sign is different
	          if (e1_80 > e2_80) begin
	       	     Final_sign_80 = s1_80;	
	          end 
	          else if (e2_80 > e1_80) begin
		     Final_sign_80 = s2_80;
	          end
	       
	          else begin
                     if (m1_80 > m2_80) begin
			            Final_sign_80 = s1_80;		
		             end
		            else if (m1_80 < m2_80) begin
			           Final_sign_80 = s2_80;
		            end
		           else begin
		              Final_sign_80 = 0;
		           end	  
                 end
	       end
      
         
           //checking for overflow/underflow
           if(  Larger_exp_80 == 63 & renorm_exp_80 == 1) begin //overflow
		   overflow = 1'b1;
             if (  Final_sign_80 ) begin
                c_add=16'hFDFE;//largest -ve value
		     
             end
             else begin
               c_add=16'h7DFE;//largest +ve value
             end
  
           end
           else if ((Larger_exp_80 >= 1) & (Larger_exp_80 <= 8) & (renorm_exp_80 <  larger_expo_neg)) begin //underflow
		   underflow = 1'b1;
             if (  Final_sign_80 ) begin
               c_add=16'h8201;//smallest -ve value
               end
             else begin
               c_add=16'd513;//smallest +ve value
             end
            end 
           else begin
      	   
               Final_expo_80 =  Larger_exp_80 + renorm_exp_80;
      
      	       if(Final_expo_80 == 6'b0) begin
		       underflow =1'b1;
                     c_add=16'b0;
               end
               else if( Final_expo_80 == 63) begin
                     c_add=16'hFFFF;
               end      
	      
             Final_mant_80 = {Add1_mant_80,2'b00}; 
	       
               //checking for special cases
               if( a==16'hFFFF | b==16'hFFFF) begin  
                 c_add = 16'hFFFF;
               end
               else begin
                 c_add = (a==0 & b==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
               end 
           end//for overflow/underflow 
	    if (c_add[19:15] != 4'b0000)
		    inexact = 1'b1;
	    end
  end //for always block 
endmodule


module dl_exception(
  input wire [4:0] exceptions,
  output reg invalid, inexact, overflow, underflow, div_zero);
  always@(*)
  begin
    div_zero = exceptions[0];
    underflow =  exceptions[1];
    overflow =  exceptions[2];
    inexact =  exceptions[3]; 
    invalid =  exceptions[4];
  end
endmodule
