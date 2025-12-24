`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.08.2025 12:54:58
// Design Name: 
// Module Name: Cfu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Cfu_1(
  input               cmd_valid,
  output              cmd_ready,
  input      [9:0]    cmd_payload_function_id,
  input      [31:0]   cmd_payload_inputs_0,
  input      [31:0]   cmd_payload_inputs_1,
  output reg          rsp_valid,
  input               rsp_ready,
  output reg [31:0]   rsp_payload_outputs_0,
  input               reset,
  input               clk
    );
   
   
   wire [15:0] src1, src2;
   wire [31:0] op1,op2;
   wire[2:0] rm;
   wire [3:0] ena;
   wire [2:0] sel2;
   wire [1:0] sel1;
   wire op;
    wire [31:0] result;
   assign op1 = cmd_payload_inputs_0;
   assign op2 = cmd_payload_inputs_1;
   assign cmd_ready = ~rsp_valid;
   

   wire [19:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt, out_sign, out_i2f, out_comp;
   wire [31:0] out_f2i;
   wire [19:0] out_muxed_wire;
   wire [31:0] out_1_wire,result_ieee;
   wire [15:0] result_wire; 
   reg [31:0] result_ieee_1;
   
       always @(posedge clk) begin
        if (reset) begin
            rsp_payload_outputs_0 <= 32'b0;
            rsp_valid <= 1'b0;
        end else if (rsp_valid) begin
            // Waiting to hand off response to CPU.
            rsp_valid <= ~rsp_ready;
        end else if (cmd_valid) begin
            rsp_valid <= 1'b1;
            // Accumulate step:
            rsp_payload_outputs_0 <= result_ieee_1;
        end
    end
    
    always@(*) begin
        if(ena == 4'b1000) begin
            result_ieee_1 = out_1_wire;
        end else begin
            result_ieee_1 = result_ieee;
        end 
    
    end

   
   control_unit control_unit(
   .funct10(cmd_payload_function_id),
   .rm(rm),
   .op(op),
   .ena(ena),
   .sel1(sel1),
   .sel2(sel2)
   );
   
   
   ieee32_to_ieee16 ieee32_to_ieee16_0(
   .ieee32_in(op1),
   .ieee16_out(src1)
   );
   
   ieee32_to_ieee16 ieee32_to_ieee16_1(
   .ieee32_in(op2),
   .ieee16_out(src2)
   );
   
   
   ieee16_to_ieee32 ieee16_to_ieee32(
   .ieee16(result_wire),
   .ieee32(result_ieee)
   );
   
    
   ieee16_add_sub add_sub(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .op(op), 
   .c_add_1(out_add_sub)
   );
   
   ieee16_mul mul(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .c_mul_1(out_mul)
   );
   
   ieee16_div div(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .c_div_1(out_div)
   );
   
   ieee16_sqrt sqrt(
   .dl_in(src1), 
   .ena(ena), 
   .dl_out_fin_1(out_sqrt)
   );
   
   ieee16_mac mac(
   .clk(clk),
   .reset(reset),
   .a(src1), 
   .b(src2), 
   .c_add(out_mac), 
   .ena(ena), 
   .op(op)
   );
   
   ieee16_sign_inv sign_inv(
   .in1(src1), 
   .in2(src2), 
   .ena(ena), 
   .sel(sel1), 
   .out_1(out_sign)
   );
   
   int32_to_ieee16 i2f(
   .in_int(op1), 
   .ena(ena), 
   .float_out_1(out_i2f)
   );
   
   ieee16_to_int32 f2i(
   .float_in(src1), 
   .ena(ena), 
   .int_out_fin_1(out_f2i)
   );
   
   ieee16_comp comp(
   .a1(src1), 
   .b1(src2), 
   .ena(ena), 
   .sel(sel2), 
   .c_out_1(out_comp)
   );


   out_mux outmux(
      .ena(ena),
      .out_add_sub(out_add_sub), 
      .out_mul(out_mul), 
      .out_div(out_div),
      .out_mac(out_mac),      
      .out_sqrt(out_sqrt), 
      .out_sign(out_sign),
      .out_i2f(out_i2f), 
      .out_comp(out_comp), 
      .out_f2i(out_f2i),
      .out_muxed(out_muxed_wire), 
      .out_1(out_1_wire)
   );

   ieee16_round round(
      .rm(rm), 
      .ena(ena), 
      .in(out_muxed_wire), 
      .out_1(result_wire)
   );
   
   
   
endmodule

module control_unit(
    input wire [9:0] funct10,
    output reg [2:0] rm,
    output reg op,
    output reg [3:0] ena,
    output reg [1:0] sel1,
    output reg [2:0] sel2
);

    reg [1:0] funct2;
    reg [4:0] funct5;
    always@(*) begin
        rm = funct10[2:0];
        funct2 = funct10[4:3];
        funct5 = funct10[9:5];
        ena = 4'b0000;
        op = 1'b0;
        sel1 = 2'b00;
        sel2 = 3'b000;
        if (funct2 == 2'b00) begin
          case(funct5)
            5'b00000: begin op = 1'b0; //add
              ena = 4'b0001; end
            5'b00001:begin op = 1'b1; //sub
              ena = 4'b0001; end
            5'b00010:begin ena = 4'b0010; //mul
            end
            5'b00011:begin ena = 4'b0011; //div
            end
           5'b01011:begin ena = 4'b0100; //sqrt
            end
            5'b00100:begin 
                if (rm == 3'b000 ) begin 
                    ena = 4'b0101; //sign inject
                    sel1 = 2'b01;
                end 
                else if (rm == 3'b001 )begin 
                    ena = 4'b0101; // sign inject neg
                    sel1 = 2'b10;
                end
                else if (rm == 3'b010) begin
                    ena = 4'b0101; //sign inject xor
                    sel1 = 2'b11; 
                end
              end
            5'b00101: begin 
                if(rm == 3'b000) begin 
                    ena = 4'b0110; 
                    sel2 = 3'b001;//min
                end
                else if(rm == 3'b001) begin 
                    ena = 4'b0110;
                    sel2 = 3'b010;//max
                end
            end
            5'b01001:begin ena = 4'b0111; //int to float
            end
            5'b01000:begin 
                ena = 4'b1000;  // float to int
            end
            5'b10100: begin 
                if(rm == 3'b010) begin 
                    ena = 4'b0110;//eq
                    sel2 = 3'b011; 
                end
                else if(rm == 3'b001)begin 
                    ena = 4'b0110;// less than
                    sel2 = 3'b100;
                end
                else if(rm == 3'b000 ) begin 
                    ena = 4'b0110;//less than eq
                    sel2 = 3'b101; 
                end
            end
            
            default : begin ena = 4'b0000;
                sel2 = 3'b000;
                sel1 = 2'b00;
            end
          endcase
        end else if (funct2 == 2'b01)begin
                ena = 4'b1001;
                op = 1'b0;
        end else if (funct2 == 2'b10) begin
                ena = 4'b1001;
                op = 1'b1;
        end 
    end

endmodule


module out_mux(
     input wire [3:0] ena, 
     input wire [19:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt,out_sign, out_i2f, out_comp,
     input wire [31:0] out_f2i, 
     output reg [19:0] out_muxed, 
     output reg [31:0] out_1);

    
  always @(*)
    begin
    out_1 = 32'b0;
    out_muxed = 20'b0;
      if(ena == 4'b1000)
        out_1 = out_f2i;
      else begin
      case(ena)
        4'b0001: out_muxed = out_add_sub;
        4'b0010: out_muxed = out_mul;
        4'b0011: out_muxed = out_div;
        4'b0100: out_muxed = out_sqrt;
        4'b0101: out_muxed = out_sign;
        4'b0110: out_muxed = out_comp;
        4'b1001: out_muxed = out_mac;
        4'b0111: out_muxed = out_i2f;
        default: out_muxed = 20'b0;
      endcase
      end
    end
endmodule


module int32_to_ieee16(
   input wire signed [31:0] in_int,
   input wire[3:0] ena,
   output reg [19:0] float_out_1  
);
    reg [4:0] exponent;   
    reg [9:0] mantissa;    
    reg sign;             
    reg [31:0] abs_input;
    reg [15:0] float_out;
    integer i;

          

       
    always @(*) begin
        float_out_1 = 20'b0;
        
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
        if ( exponent <= 10) begin
          mantissa = abs_input << (10 - exponent);  // Left shift for +ve exp
           end else begin
             mantissa = abs_input >> (exponent - 10);// Right shift for -ve exp
           end

        
        //Bias the exponent 
        exponent = exponent + 15;
      
      float_out = {sign,exponent,mantissa};
      end 
      float_out_1 = {float_out,4'b0000};
    end
    
endmodule


module ieee16_to_int32(
   input wire [3:0] ena,
   input wire[15:0] float_in,
   output reg signed [31:0] int_out_fin_1
);
  reg sign;
  reg [4:0] exponent;
  reg [10:0] mantissa; 
  reg signed [4:0] actual_exponent;
  reg signed [31:0] result;
  reg signed [31:0] int_out_fin;

  always @(*) begin
    int_out_fin_1 = 32'b0;
	  if(ena != 4'b1000)
		  int_out_fin = 32'b0;
	  else begin
    // Extract fields
    sign = float_in[15];
    exponent = float_in[14:10];
    mantissa = {1'b1, float_in[9:0]}; 
    
    // Handle special cases
    if (exponent == 5'b00000) begin
      int_out_fin = 0;
    end  
    else if (exponent == 5'b11111) begin
      // Infinity or NaN: saturate to max 32-bit signed integer
      int_out_fin = sign ? -32'h80000000 : 32'h7FFFFFFF;
    end else begin
  
      actual_exponent = exponent - 15; // Unbias the exponent
      
      if (actual_exponent <= 10) begin
        result = {23'b0, mantissa >> ( 10 - actual_exponent)};
        end else begin
        result = mantissa << (actual_exponent - 10);
      end 
      int_out_fin = sign ? -result : result;
      // Clamp to 32-bit signed range
      if (int_out_fin > 32'h7FFFFFFF)begin 
        int_out_fin = 32'h7FFFFFFF;
      end
      if (int_out_fin > 32'h80000000)begin
         int_out_fin = 32'h80000000;
      end 
    end
  end
  int_out_fin_1 = int_out_fin;
  end
endmodule


module ieee16_sqrt (
	input wire [3:0] ena,
    input  wire [15:0] dl_in,              
	output reg [19:0] dl_out_fin_1
);
    reg sign;
    reg [4:0] exp_in;
    reg [9:0] mant_in;
    reg done;
    // Internal variables
    reg [13:0] x, x_next;
    reg [13:0] diff, mant_sqrt, remainder;
    reg [10:0] mant_norm;
    reg [4:0] exp_out, ier;

    // Output and exception flags
    reg [19:0] dl_out;

    // Control
    integer i;

	 
    always@(*)  begin
        // Decode input
        sign = dl_in[15];
        exp_in = dl_in[14:10];
        mant_in = dl_in[9:0];
        mant_norm = 11'b0;
        dl_out_fin_1 = 20'b0;
        // Reset outputs
        x = 14'b0;
        x_next = 14'b0;
        diff = 14'b0;
        remainder = 14'b0;
        mant_sqrt = 14'b0;
        exp_out = 5'b0;
        ier = 5'b0;
        done = 1'b0;

        dl_out = 20'b0;

        if (ena != 4'b0100) begin
            dl_out = 20'b0;
        end else begin
            // Special cases
            if (dl_in == 16'h0000) begin
                dl_out = 20'h00000;  // Zero
            end else if (sign == 1'b1) begin
                dl_out = 20'hFFFFF;  // NaN for negative input
            end else begin
                mant_norm = (exp_in == 0) ? {1'b0, mant_in} : {1'b1, mant_in};

                if (exp_in == 5'b0) begin
                    exp_out = 5'b0;
                end else begin
                    if (exp_in[0]) begin
                        ier = exp_in + 1;
                        mant_norm = mant_norm >> 1;
                    end else begin
                        ier = exp_in;
                    end
                    exp_out = (ier + 5'd15) >> 1; // Apply bias
                end

                // Newton-Raphson iteration (8 cycles max)
                x = mant_norm;
                for (i = 0; i < 9 && !done; i = i + 1) begin
                    if (x == 0) begin
                        x_next = 0;
                    end else begin
                        x_next = (x + (mant_norm / x)) >> 1;
                    end
                    diff = (x > x_next) ? (x - x_next) : (x_next - x);
                    x = x_next;
                    if (diff <= 1) begin
                        done = 1;
                    end
                end

                mant_sqrt = x << 10;
                remainder = mant_norm - (x * x);

                if (remainder >= (2 * x)) begin
                    mant_sqrt = mant_sqrt + 1;
                end



                if (exp_out > 5'b11110) begin
                    dl_out = 20'h7DFE0;
                end else if (exp_out == 5'b0 && mant_sqrt == 14'b0) begin
                    dl_out = 20'h00000;
                end else begin
                    dl_out = {1'b0, exp_out, mant_sqrt[13:4]}; // Use top 9 bits
                end
            end
        end
        dl_out_fin_1 = dl_out;
    end


endmodule




module ieee16_sign_inv(
   input wire [15:0] in1, 
   input wire [15:0] in2,  
   input wire[1:0] sel,
   output reg [19:0] out_1,
   input wire [3:0] ena
);
 reg [19:0] out_comb;
 wire [14:0] not_used;
 reg [19:0] out;
 
 
  assign not_used = in1[14:0];
   (* keep = "true" *) wire dummy_use = ^not_used;
		
  always @(*) begin
    out_1 = 20'b0;  
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
  out = {out_comb,4'b0000};
  out_1 = out;
  end


endmodule


module ieee16_round( 
      input [19:0] in, 
      input [3:0] ena,
      input [2:0] rm,
      output reg [15:0] out_1
);
  
  reg G_bit,R_bit, S1_bit , S2_bit, S_bit;
  reg sign;
  reg [4:0] exp,exp_tmp;
  reg [10:0] mant1, mant1_tmp;
  reg [9:0] mant;
  reg [15:0] rounded_val;
  reg [15:0] out;

always @(*) begin
        // Extract and decode input fields
        sign   = in[19];
        exp    = in[18:14];
        mant1  = {1'b0, in[13:4]}; // 10 bits with leading 0
        G_bit  = in[3];
        R_bit  = in[2];
        S1_bit = in[1];
        S2_bit = in[0];
        S_bit  = S1_bit | S2_bit;

        // Initialize to avoid latches
        mant1_tmp    = mant1;
        exp_tmp      = exp;
        mant         = mant1[9:0];
        rounded_val  = {sign, exp_tmp, mant};
        out_1 = 16'b0;

        // Rounding modes
        case (rm)
            // Round to nearest, ties to even
            3'b000: begin
                if (!G_bit) begin
                    mant = mant1[9:0];
                end else if (R_bit | S_bit) begin
                    if (in[4]) begin // tie: LSB = 1
                        mant1_tmp = mant1 + 1;
                        mant = mant1_tmp[9:0];
                        if (mant1_tmp[10])
                            exp_tmp = exp + 1;
                    end else begin
                        mant = mant1[9:0]; // tie: LSB = 0
                    end
                end else begin
                    // G=1, R=0, S=0 → midpoint → round up
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[9:0];
                    if (mant1_tmp[10])
                        exp_tmp = exp + 1;
                end
            end

            // Round toward zero
            3'b001: begin
                mant = mant1[9:0];
            end

            // Round up (toward +∞)
            3'b010: begin
                if ((G_bit | R_bit | S_bit) && !sign) begin
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[9:0];
                    if (mant1_tmp[10])
                        exp_tmp = exp + 1;
                end else begin
                    mant = mant1[9:0];
                end
            end

            // Round down (toward -∞)
            3'b011: begin
                if ((G_bit | R_bit | S_bit) && sign) begin
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[9:0];
                    if (mant1_tmp[10])
                        exp_tmp = exp + 1;
                end else begin
                    mant = mant1[9:0];
                end
            end

            // Default: truncate
            default: begin
                mant = mant1[0:0];
                exp_tmp = exp;
            end
        endcase

        // Compose the final 16-bit rounded result
        rounded_val = {sign, exp_tmp, mant};

        // Apply enable logic
        if (ena != 4'b1000)
            out = rounded_val;
        else begin
            out = in[19:4]; // Bypass
        end
            out_1 = out;

    end

endmodule
      
    
module ieee16_mul(a, b,ena, c_mul_1);
    input [15:0] a, b;
    input wire [3:0] ena;
    output reg [19:0] c_mul_1;
    
    reg [10:0] ma, mb;     // Changed from 9:0 to 10:0
    reg [9:0] mant;        // Changed from 8:0 to 9:0
    reg [21:0] m_temp;     // Changed from 19:0 to 21:0
    reg [4:0] ea, eb, e_temp, exp; // Changed from 5:0 to 4:0
    reg sa, sb, s;
    reg [15:0] c_mul1;
	
  	
    always@(*) begin
        // Extract IEEE 16-bit components
        ma = {1'b1, a[9:0]};  // Changed from a[8:0] to a[9:0]
        mb = {1'b1, b[9:0]};  // Changed from b[8:0] to b[9:0]
        sa = a[15];
        sb = b[15];
        ea = a[14:10];        // Changed from a[14:9] to a[14:10]
        eb = b[14:10];        // Changed from b[14:9] to b[14:10]
  	
        // Initialize to avoid latch inference
        e_temp = 5'b0;
        m_temp = 22'b0;
        mant = 10'b0;
        exp = 5'b0;
        s = 0;
        c_mul1= 16'b0;
  	
        
        // Check for underflow/overflow (adjusted for IEEE 16-bit bias of 15)
        if(ena != 4'b0010)
        if ((ea + eb) <= 15) begin
            c_mul1 = 16'b0; // Underflow
        end else if ((ea + eb) > 45) begin // 30 + 15 = 45
            if((sa ^ sb)) begin
                c_mul1 = 16'hFC00; // -infinity
            end else begin
                c_mul1 = 16'h7C00; // +infinity
            end
        end else if ((ea + eb) == 46) begin // All exponent bits set
            c_mul1 = 16'hFFFF; // NaN
        end else begin	
            e_temp = ea + eb - 15; // IEEE 16-bit bias
            m_temp = ma * mb;
		
            if (m_temp[21]) begin
                mant = m_temp[20:11];
                exp = e_temp + 1'b1;
            end else begin
                mant = m_temp[19:10];
                exp = e_temp;
            end
            s = sa ^ sb;
		
            // Check for special cases	
            if(a == 16'hFFFF | b == 16'hFFFF) begin
                c_mul1 = 16'hFFFF;
            end else begin
                c_mul1 = (a == 0 | b == 0) ? 16'b0 : {s, exp, mant};
            end 
        end 
        c_mul_1 = {4'b0,c_mul1};
    end 
    
    wire _unused = &{m_temp[9:0], 11'b0};
endmodule


// Code your design here
module ieee16_mac(a,b,c_add,ena,op,clk,reset);
	input wire op; 
	input wire [3:0] ena;
    input wire [15:0]a,b;
	output reg [19:0] c_add;
	input wire clk,reset;
	wire [19:0] c_add_wire;
    wire [15:0] c_mul1,b1;
    reg [19:0] c_macc_add_1;
    wire [4:0] excep;
    wire oper = op;
 
 	ieee16_mul_mac mul(.a(a),.b(b),.c_mul_1(c_mul1),.ena(ena));
	ieee16_add_mac add(.a(c_mul1),.b(b1),.c_add_1(c_add_wire),.op(oper));
    mac_reg macreg(.a(c_add_wire[19:4]),.clk(clk),.reset(reset),.b(b1));
    
    always @(*) begin
        c_add = c_add_wire;
    end

endmodule
  
module mac_reg(
    input wire [15:0] a,
    input wire clk,reset,
    output reg [15:0] b
);

    always @(posedge clk) begin
        if(reset) begin
            b <= 16'b0;
        end else begin
            b <= a;
        end
    end
endmodule
  
module ieee16_mul_mac(a, b,ena, c_mul_1);
    input [15:0] a, b;
    input wire [3:0] ena;
    output reg [15:0] c_mul_1;
    
    reg [10:0] ma, mb;     // Changed from 9:0 to 10:0
    reg [9:0] mant;        // Changed from 8:0 to 9:0
    reg [21:0] m_temp;     // Changed from 19:0 to 21:0
    reg [4:0] ea, eb, e_temp, exp; // Changed from 5:0 to 4:0
    reg sa, sb, s;
    reg [15:0] c_mul1;
	
  	
    always@(*) begin
        // Extract IEEE 16-bit components
        ma = {1'b1, a[9:0]};  // Changed from a[8:0] to a[9:0]
        mb = {1'b1, b[9:0]};  // Changed from b[8:0] to b[9:0]
        sa = a[15];
        sb = b[15];
        ea = a[14:10];        // Changed from a[14:9] to a[14:10]
        eb = b[14:10];        // Changed from b[14:9] to b[14:10]
  	
        // Initialize to avoid latch inference
        e_temp = 5'b0;
        m_temp = 22'b0;
        mant = 10'b0;
        exp = 5'b0;
        s = 0;
        c_mul_1 = 16'b0;
        c_mul1= 16'b0;
  	
        
        // Check for underflow/overflow (adjusted for IEEE 16-bit bias of 15)
        if(ena != 4'b1001)
        if ((ea + eb) <= 15) begin
            c_mul1 = 16'b0; // Underflow
        end else if ((ea + eb) > 45) begin // 30 + 15 = 45
            if((sa ^ sb)) begin
                c_mul1 = 16'hFC00; // -infinity
            end else begin
                c_mul1 = 16'h7C00; // +infinity
            end
        end else if ((ea + eb) == 46) begin // All exponent bits set
            c_mul1 = 16'hFFFF; // NaN
        end else begin	
            e_temp = ea + eb - 15; // IEEE 16-bit bias
            m_temp = ma * mb;
		
            if (m_temp[21]) begin
                mant = m_temp[20:11];
                exp = e_temp + 1'b1;
            end else begin
                mant = m_temp[19:10];
                exp = e_temp;
            end
            s = sa ^ sb;
		
            // Check for special cases	
            if(a == 16'hFFFF | b == 16'hFFFF) begin
                c_mul1 = 16'hFFFF;
            end else begin
                c_mul1 = (a == 0 | b == 0) ? 16'b0 : {s, exp, mant};
            end 
        end 
        c_mul_1 = c_mul1;
    end 
    
    wire _unused = &{m_temp[9:0], 11'b0};
endmodule
 
module ieee16_add_mac(
    input [15:0] a,
    input [15:0] b,
    input wire [3:0] ena,
    input wire op,
    output reg [19:0] c_add_1
);
   
    reg [19:0] c_add;
    reg [4:0] Num_shift_80;
    reg [4:0] Larger_exp_80, Final_expo_80;
    reg [10:0] Small_exp_mantissa_80, Large_mantissa_80;
    reg [11:0] Add_mant_80, Add1_mant_80;
    reg [4:0] e1_80, e2_80;
    reg [9:0] m1_80, m2_80;
    reg s1_80, s2_80, Final_sign_80;
    reg signed [5:0] renorm_exp_80;

    always@(*) begin
        // Extract IEEE 16-bit components
        e1_80 = a[14:10];
        e2_80 = b[14:10];
        m1_80 = a[9:0];
        m2_80 = b[9:0];
        s1_80 = a[15];
        s2_80 = b[15];
        c_add_1 = 20'b0;
        
        if(ena != 4'b0001)
            c_add = 20'b0;
        else begin
            if(op) begin
                s2_80 = ~b[15];
            end
            else begin
                s2_80 = b[15];
            end
        
        // Handle zero operands first
        if (a == 16'b0) begin
            // 0 + b = b, pack into 20-bit format
            c_add = {b[15], b[14:10], b[9:0], 4'b0000};
        end else if (b == 16'b0) begin
            // a + 0 = a, pack into 20-bit format  
            c_add = {a[15], a[14:10], a[9:0], 4'b0000};
        end else begin
            // Both operands are non-zero
            // Determine larger exponent and align mantissas
            if (e1_80 > e2_80) begin
                Num_shift_80 = e1_80 - e2_80;
                Larger_exp_80 = e1_80;
                Small_exp_mantissa_80 = {1'b1, m2_80};
                Large_mantissa_80 = {1'b1, m1_80};
            end else if (e2_80 > e1_80) begin
                Num_shift_80 = e2_80 - e1_80;
                Larger_exp_80 = e2_80;
                Small_exp_mantissa_80 = {1'b1, m1_80};
                Large_mantissa_80 = {1'b1, m2_80};
            end else begin
                // Same exponents
                Num_shift_80 = 0;
                Larger_exp_80 = e1_80;
                Small_exp_mantissa_80 = {1'b1, m1_80};
                Large_mantissa_80 = {1'b1, m2_80};
            end
            
            // Shift smaller mantissa
            if (Num_shift_80 > 0 && Num_shift_80 < 12) begin
                Small_exp_mantissa_80 = Small_exp_mantissa_80 >> Num_shift_80;
            end else if (Num_shift_80 >= 12) begin
                Small_exp_mantissa_80 = 0; // Complete underflow
            end
            
            // Perform addition or subtraction
            if (s1_80 == s2_80) begin
                // Same signs - addition
                Add_mant_80 = Small_exp_mantissa_80 + Large_mantissa_80;
                Final_sign_80 = s1_80;
            end else begin
                // Different signs - subtraction
                if (e1_80 > e2_80 || (e1_80 == e2_80 && m1_80 >= m2_80)) begin
                    Add_mant_80 = Large_mantissa_80 - Small_exp_mantissa_80;
                    Final_sign_80 = (e1_80 >= e2_80) ? s1_80 : s2_80;
                end else begin
                    Add_mant_80 = Small_exp_mantissa_80 - Large_mantissa_80;
                    Final_sign_80 = (e2_80 > e1_80) ? s2_80 : s1_80;
                end
            end
            
            // Normalize result
            renorm_exp_80 = 0;
            Add1_mant_80 = Add_mant_80;
            Final_expo_80 = Larger_exp_80;
            
            if (Add_mant_80 == 0) begin
                c_add = 20'b0;
            end else if (Add_mant_80[11]) begin
                // Overflow - shift right
                Add1_mant_80 = Add_mant_80 >> 1;
                Final_expo_80 = Larger_exp_80 + 1;
                
                if (Final_expo_80 >= 31) begin
                    // Overflow to infinity
                    c_add = {Final_sign_80, 5'b11111, 14'b0};
                end else begin
                    // Pack normalized result
                    c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
                end
            end else if (Add_mant_80[10]) begin
                // Already normalized
                c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
            end else begin
                // Need to shift left and adjust exponent
                if (Add_mant_80[9]) begin
                    renorm_exp_80 = -1;
                    Add1_mant_80 = Add_mant_80 << 1;
                end else if (Add_mant_80[8]) begin
                    renorm_exp_80 = -2;
                    Add1_mant_80 = Add_mant_80 << 2;
                end else if (Add_mant_80[7]) begin
                    renorm_exp_80 = -3;
                    Add1_mant_80 = Add_mant_80 << 3;
                end else if (Add_mant_80[6]) begin
                    renorm_exp_80 = -4;
                    Add1_mant_80 = Add_mant_80 << 4;
                end else if (Add_mant_80[5]) begin
                    renorm_exp_80 = -5;
                    Add1_mant_80 = Add_mant_80 << 5;
                end else if (Add_mant_80[4]) begin
                    renorm_exp_80 = -6;
                    Add1_mant_80 = Add_mant_80 << 6;
                end else if (Add_mant_80[3]) begin
                    renorm_exp_80 = -7;
                    Add1_mant_80 = Add_mant_80 << 7;
                end else if (Add_mant_80[2]) begin
                    renorm_exp_80 = -8;
                    Add1_mant_80 = Add_mant_80 << 8;
                end else if (Add_mant_80[1]) begin
                    renorm_exp_80 = -9;
                    Add1_mant_80 = Add_mant_80 << 9;
                end else if (Add_mant_80[0]) begin
                    renorm_exp_80 = -10;
                    Add1_mant_80 = Add_mant_80 << 10;
                end else begin
                    c_add = 20'b0; // Result is zero
                end
                
                Final_expo_80 = Larger_exp_80 + renorm_exp_80;
                
                if (Final_expo_80 <= 0) begin
                    // Underflow to zero
                    c_add = {Final_sign_80, 19'b0};
                end else begin
                    // Pack normalized result  
                    c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
                end
            end
        end
          
        c_add_1 = c_add;
        end
    end
endmodule


module ieee16_div(
    input wire [3:0] ena,
    input wire [15:0] a, b,
    output reg [19:0] c_div_1
);
    reg [10:0] ma, mb;
    reg [21:0] m_temp;
    reg [4:0] ea, eb, exp;
    reg signed [6:0] e_temp;
    reg sa, sb, s;
    reg [19:0] c_div;

always @(*) begin
    // Extract IEEE 16-bit components
    sa = a[15];
    sb = b[15];
    ea = a[14:10];
    eb = b[14:10];
    
    // Initialize
    c_div = 20'b0;
    c_div_1 = 20'b0;
    if(ena != 4'b0011)
            c_div = 20'b0;
        else begin
    
    // Handle special cases
    if (a == 16'b0) begin
        c_div = {sa ^ sb, 19'b0}; // 0/x = 0
    end else if (b == 16'b0) begin
        c_div = {sa ^ sb, 5'b11111, 14'b0}; // x/0 = inf
    end else if (ea == 5'b11111 || eb == 5'b11111) begin
        c_div = {sa ^ sb, 5'b11111, 14'b11111111111111}; // NaN for inf cases
    end else begin
        // Normal case - both are finite, non-zero numbers
        
        // Add implicit leading 1 for normalized mantissas
        ma = {1'b1, a[9:0]};  // 1.mantissa format
        mb = {1'b1, b[9:0]};  // 1.mantissa format
        
        // Calculate result sign
        s = sa ^ sb;
        
        // Calculate result exponent: exp_a - exp_b + bias
        e_temp = ea - eb + 15;
        
        // Perform integer division with sufficient precision
        // We need to get a result in 1.xxxxxxxxxx format
        // Shift ma by 10 bits to get enough precision
        m_temp = (ma << 10) / mb;
        
        // Now m_temp should contain the result mantissa
        // We expect it to be in range [1.0, 2.0) which means bit 10 should be set
        
        if (m_temp[10] == 1'b0) begin
            // Result is less than 1.0, need to normalize
            m_temp = m_temp << 1;
            e_temp = e_temp - 1;
        end
        // If m_temp[11] is set, result >= 2.0, need to shift right
        else if (m_temp[11] == 1'b1) begin
            m_temp = m_temp >> 1;
            e_temp = e_temp + 1;
        end
        
        // Final exponent
        exp = e_temp;
        
        // Check for overflow/underflow
        if (exp >= 31) begin
            c_div = {s, 5'b11111, 14'b0}; // Infinity
        end else if (exp <= 0) begin
            c_div = {s, 19'b0}; // Zero (underflow)
        end else begin
            // Pack the result: {sign, exponent, mantissa_frac, padding}
            // m_temp[10] is the implicit 1, m_temp[9:0] is the fractional part
            c_div = {s, exp[4:0], m_temp[9:0], 4'b0000};
        end
    end
end
    c_div_1 = c_div;
end
endmodule




module ieee16_comp(
   input wire [15:0] a1,
   input wire [15:0] b1,
   input wire [2:0] sel,
   input wire [3:0] ena,
   output reg [19:0] c_out_1
);
  reg s1, s2;
  reg [4:0] exp1, exp2;
  reg [9:0] mant1, mant2;
  reg lt, gt, eq;
  reg [19:0] c_1;

 always @(*) begin
       c_out_1 = 20'b0;
	  if(ena != 4'b0110)
		  c_1 =20'b0;
	  else begin
    // Extract fields
    s1 = a1[15];
    s2 = b1[15];
    exp1 = a1[14:10];
    exp2 = b1[14:10];
    mant1 = a1[9:0];
    mant2 = b1[9:0];
    lt = 0;
    gt = 0;
    eq = 0;
    c_1 = 20'h00000;
  
    
    // Compare logic
    if (s1 != s2) begin
      if (s1) begin
        lt = 1;
      end else begin
        gt = 1;
      end
    end 
    else begin
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
      3'b001: c_1[19:4] = (lt ==1'b1)?a1:b1;//min
      3'b010: c_1[19:4]  = (gt ==1'b1)?a1:b1;//max
      3'b011: c_1[19:4]  = {16{eq}};//set eq
      3'b100: c_1[19:4]  = {16{lt}};//set less than
      3'b101: c_1[19:4]  = (lt ==1'b1 || eq ==1'b1)?20'hffff0:20'h00000;//set less than equal
      default: c_1 = 20'b0;

    endcase

  end
      c_out_1 = c_1;
  end


endmodule


module ieee16_add_sub(
    input [15:0] a,
    input [15:0] b,
    input wire [3:0] ena,
    input wire op,
    output reg [19:0] c_add_1
);
   
    reg [19:0] c_add;
    reg [4:0] Num_shift_80;
    reg [4:0] Larger_exp_80, Final_expo_80;
    reg [10:0] Small_exp_mantissa_80, Large_mantissa_80;
    reg [11:0] Add_mant_80, Add1_mant_80;
    reg [4:0] e1_80, e2_80;
    reg [9:0] m1_80, m2_80;
    reg s1_80, s2_80, Final_sign_80;
    reg signed [5:0] renorm_exp_80;

    always@(*) begin
        // Extract IEEE 16-bit components
        e1_80 = a[14:10];
        e2_80 = b[14:10];
        m1_80 = a[9:0];
        m2_80 = b[9:0];
        s1_80 = a[15];
        s2_80 = b[15];
        c_add_1 =20'b0;
        
        if(ena != 4'b0001)
            c_add = 20'b0;
        else begin
            if(op) begin
                s2_80 = ~b[15];
            end
            else begin
                s2_80 = b[15];
            end
        
        // Handle zero operands first
        if (a == 16'b0) begin
            // 0 + b = b, pack into 20-bit format
            c_add = {b[15], b[14:10], b[9:0], 4'b0000};
        end else if (b == 16'b0) begin
            // a + 0 = a, pack into 20-bit format  
            c_add = {a[15], a[14:10], a[9:0], 4'b0000};
        end else begin
            // Both operands are non-zero
            // Determine larger exponent and align mantissas
            if (e1_80 > e2_80) begin
                Num_shift_80 = e1_80 - e2_80;
                Larger_exp_80 = e1_80;
                Small_exp_mantissa_80 = {1'b1, m2_80};
                Large_mantissa_80 = {1'b1, m1_80};
            end else if (e2_80 > e1_80) begin
                Num_shift_80 = e2_80 - e1_80;
                Larger_exp_80 = e2_80;
                Small_exp_mantissa_80 = {1'b1, m1_80};
                Large_mantissa_80 = {1'b1, m2_80};
            end else begin
                // Same exponents
                Num_shift_80 = 0;
                Larger_exp_80 = e1_80;
                Small_exp_mantissa_80 = {1'b1, m1_80};
                Large_mantissa_80 = {1'b1, m2_80};
            end
            
            // Shift smaller mantissa
            if (Num_shift_80 > 0 && Num_shift_80 < 12) begin
                Small_exp_mantissa_80 = Small_exp_mantissa_80 >> Num_shift_80;
            end else if (Num_shift_80 >= 12) begin
                Small_exp_mantissa_80 = 0; // Complete underflow
            end
            
            // Perform addition or subtraction
            if (s1_80 == s2_80) begin
                // Same signs - addition
                Add_mant_80 = Small_exp_mantissa_80 + Large_mantissa_80;
                Final_sign_80 = s1_80;
            end else begin
                // Different signs - subtraction
                if (e1_80 > e2_80 || (e1_80 == e2_80 && m1_80 >= m2_80)) begin
                    Add_mant_80 = Large_mantissa_80 - Small_exp_mantissa_80;
                    Final_sign_80 = (e1_80 >= e2_80) ? s1_80 : s2_80;
                end else begin
                    Add_mant_80 = Small_exp_mantissa_80 - Large_mantissa_80;
                    Final_sign_80 = (e2_80 > e1_80) ? s2_80 : s1_80;
                end
            end
            
            // Normalize result
            renorm_exp_80 = 0;
            Add1_mant_80 = Add_mant_80;
            Final_expo_80 = Larger_exp_80;
            
            if (Add_mant_80 == 0) begin
                c_add = 20'b0;
            end else if (Add_mant_80[11]) begin
                // Overflow - shift right
                Add1_mant_80 = Add_mant_80 >> 1;
                Final_expo_80 = Larger_exp_80 + 1;
                
                if (Final_expo_80 >= 31) begin
                    // Overflow to infinity
                    c_add = {Final_sign_80, 5'b11111, 14'b0};
                end else begin
                    // Pack normalized result
                    c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
                end
            end else if (Add_mant_80[10]) begin
                // Already normalized
                c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
            end else begin
                // Need to shift left and adjust exponent
                if (Add_mant_80[9]) begin
                    renorm_exp_80 = -1;
                    Add1_mant_80 = Add_mant_80 << 1;
                end else if (Add_mant_80[8]) begin
                    renorm_exp_80 = -2;
                    Add1_mant_80 = Add_mant_80 << 2;
                end else if (Add_mant_80[7]) begin
                    renorm_exp_80 = -3;
                    Add1_mant_80 = Add_mant_80 << 3;
                end else if (Add_mant_80[6]) begin
                    renorm_exp_80 = -4;
                    Add1_mant_80 = Add_mant_80 << 4;
                end else if (Add_mant_80[5]) begin
                    renorm_exp_80 = -5;
                    Add1_mant_80 = Add_mant_80 << 5;
                end else if (Add_mant_80[4]) begin
                    renorm_exp_80 = -6;
                    Add1_mant_80 = Add_mant_80 << 6;
                end else if (Add_mant_80[3]) begin
                    renorm_exp_80 = -7;
                    Add1_mant_80 = Add_mant_80 << 7;
                end else if (Add_mant_80[2]) begin
                    renorm_exp_80 = -8;
                    Add1_mant_80 = Add_mant_80 << 8;
                end else if (Add_mant_80[1]) begin
                    renorm_exp_80 = -9;
                    Add1_mant_80 = Add_mant_80 << 9;
                end else if (Add_mant_80[0]) begin
                    renorm_exp_80 = -10;
                    Add1_mant_80 = Add_mant_80 << 10;
                end else begin
                    c_add = 20'b0; // Result is zero
                end
                
                Final_expo_80 = Larger_exp_80 + renorm_exp_80;
                
                if (Final_expo_80 <= 0) begin
                    // Underflow to zero
                    c_add = {Final_sign_80, 19'b0};
                end else begin
                    // Pack normalized result  
                    c_add = {Final_sign_80, Final_expo_80, Add1_mant_80[9:0], 4'b0000};
                end
            end
        end
          
        c_add_1 = c_add;
        end
    end
endmodule


module ieee32_to_ieee16 (
    input  wire [31:0] ieee32_in,
    output wire [15:0] ieee16_out
);
    wire        sign       = ieee32_in[31];
    wire [7:0]  exp32      = ieee32_in[30:23];
    wire [22:0] frac32     = ieee32_in[22:0];
    wire is_nan32 = (exp32 == 8'hFF) && (frac32 != 0);
    wire is_inf32 = (exp32 == 8'hFF) && (frac32 == 0);
    wire is_zero32 = (exp32 == 8'h00) && (frac32 == 0);
    wire [23:0] sig24 = (exp32 == 8'h00) ? {1'b0, frac32} : {1'b1, frac32};
    wire signed [9:0] e_single  = (exp32 == 8'h00) ? -10'sd126 : ( $signed({1'b0,exp32}) - 10'sd127 );
    wire signed [9:0] e_half    = e_single + 10'sd15;
    wire [9:0] mant_main_norm = sig24[22:13]; 
    wire       g_norm         = sig24[12];
    wire       r_norm         = sig24[11];
    wire       s_norm         = |sig24[10:0];
    wire       round_up_norm  = g_norm && (r_norm | s_norm | mant_main_norm[0]);
    reg  [4:0]  exp16,exp16_1;
    reg  [9:0]  mant16;
    reg  [10:0] mant_ext;
    integer shift_amt;
    reg [26:0] aligned;
    reg [26:0] shifted;
    reg [9:0]  mant_main_sub;
    reg        g_sub, r_sub, s_sub;
    reg        round_up_sub;
    reg [10:0] mant_sub_ext;

    always @* begin
        exp16  = 5'd0;
        mant16 = 10'd0;

        if (is_nan32) begin
            exp16  = 5'h1F;
            mant16 = 10'h200 | (frac32[22] ? 10'h001 : 10'h000);
        end
        else if (is_inf32) begin
            exp16  = 5'h1F;
            mant16 = 10'h000;
        end
        else if (is_zero32) begin
            exp16  = 5'd0;
            mant16 = 10'd0;
        end
        else if (e_half >= 10'sd31) begin
            exp16  = 5'h1F;
            mant16 = 10'h000;
        end
        else if (e_half <= 10'sd0) begin
            shift_amt = (1 - e_half);
            if (shift_amt > 26) begin
                exp16  = 5'd0;
                mant16 = 10'd0;
            end else begin
                aligned = {sig24, 3'b000};
                shifted = aligned >> shift_amt;
                mant_main_sub = shifted[26:17];
                g_sub         = shifted[16];
                r_sub         = shifted[15];
                s_sub         = |shifted[14:0];
                round_up_sub  = g_sub && (r_sub | s_sub | mant_main_sub[0]);
                mant_sub_ext  = {1'b0, mant_main_sub} + (round_up_sub ? 11'd1 : 11'd0);
                if (mant_sub_ext[10]) begin
                    exp16  = 5'd1;
                    mant16 = 10'd0;
                end else begin
                    exp16  = 5'd0;
                    mant16 = mant_sub_ext[9:0];
                end
            end
        end
        else begin
            mant_ext = {1'b0, mant_main_norm} + (round_up_norm ? 11'd1 : 11'd0);
            if (mant_ext[10]) begin
                if (e_half + 10'sd1 >= 10'sd31) begin
                    exp16  = 5'h1F;   // overflow to Inf after rounding
                    mant16 = 10'd0;
                end else begin
                    exp16_1  = (e_half + 10'sd1);
                    exp16 = exp16_1;
                    mant16 = mant_ext[10:1]; // drop carry bit
                end
            end else begin
                exp16  = e_half[4:0];
                mant16 = mant_ext[9:0];
            end
        end
    end

    assign ieee16_out = {sign, exp16, mant16};
endmodule


module ieee16_to_ieee32 (
    input  wire [15:0] ieee16,     // Half precision input
    output wire [31:0] ieee32      // Single precision output
);

    // Extract IEEE-754 half precision fields
    wire sign;
    wire [4:0] exp16;
    wire [9:0] frac16;

    assign sign  = ieee16[15];
    assign exp16 = ieee16[14:10];
    assign frac16 = ieee16[9:0];

    // Special cases
    wire is_zero   = (exp16 == 5'd0)  && (frac16 == 10'd0);
    wire is_inf    = (exp16 == 5'd31) && (frac16 == 10'd0);
    wire is_nan    = (exp16 == 5'd31) && (frac16 != 10'd0);

    // Exponent conversion: bias difference = 127 - 15 = 112
    wire signed [9:0] exp_unbiased = exp16 - 15;
    wire signed [9:0] exp32_temp   = exp_unbiased + 127;

    wire [7:0] exp32 = is_zero ? 8'd0 :
                       is_inf  ? 8'hFF :
                       is_nan  ? 8'hFF :
                       exp32_temp[7:0];

    // Fraction conversion: pad 13 zeros to match 23 bits
    wire [22:0] frac32 = is_zero ? 23'd0 :
                         is_inf  ? 23'd0 :
                         is_nan  ? {1'b1, 22'd0} :
                         {frac16, 13'b0};

    // Construct IEEE-754 single precision
    assign ieee32 = {sign, exp32, frac32};

endmodule
