`timescale 1ns / 1ps

module Cfu(
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
   reg [31:0] op1,op2;
   wire [31:0] ieee_float;
   wire[2:0] rm;
   wire [3:0] ena;
   wire [2:0] sel2;
   wire [1:0] sel1;
   wire op;
    wire [31:0] result;
   
   always@(posedge clk) begin
    op1 <= cmd_payload_inputs_0;
    op2 <= cmd_payload_inputs_1;
    //cmd_ready <= ~rsp_valid;
    
   end
   
   
   //assign op1 = cmd_payload_inputs_0;
//   assign op2 = cmd_payload_inputs_1;
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

   
   (* dont_touch = "true" *) control_unit control_unit(
   .funct10(cmd_payload_function_id),
   .rm(rm),
   .op(op),
   .ena(ena),
   .sel1(sel1),
   .sel2(sel2)
   );
   
   
   (* dont_touch = "true" *) ieee32_to_dlfp16 ieee_to_dl0(
   .ieee32_in(op1),
   .dlfp16_out(src1)
   );
   
   (* dont_touch = "true" *) ieee32_to_dlfp16 ieee_to_dl1(
   .ieee32_in(op2),
   .dlfp16_out(src2)
   );
   
   
   (* dont_touch = "true" *) dlfp16_to_ieee32 dl_to_ieee(
   .dlfp16(result_wire),
   .ieee32(result_ieee)
   );
   
    
   (* dont_touch = "true" *) dlfloat16_add_sub add_sub(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .op(op), 
   .c_add_1(out_add_sub)
   );
   
   (* dont_touch = "true" *) dlfloat16_mul mul(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .c_mul_1(out_mul)
   );
   
   (* dont_touch = "true" *) dlfloat16_div div(
   .a(src1), 
   .b(src2), 
   .ena(ena), 
   .c_div_1(out_div)
   );
   
   
   (* dont_touch = "true" *) sqrt_pipeline sqrt(
   .clk(clk),
   .rst_n(reset),
   .ena(ena),
   .dl_in(src1),
   .dl_out20(out_sqrt)
   );
   //(* dont_touch = "true" *) dlfloat16_sqrt sqrt(
//   .dl_in(src1), 
//   .ena(ena), 
//   .dl_out_fin_1(out_sqrt)
//   );
   
   (* dont_touch = "true" *) dlfloat16_mac mac(
   .clk(clk),
   .reset(reset),
   .a(src1), 
   .b(src2), 
   .c_add(out_mac), 
   .ena(ena), 
   .op(op)
   );
   
   (* dont_touch = "true" *) dlfloat16_sign_inv sign_inv(
   .in1(src1), 
   .in2(src2), 
   .ena(ena), 
   .sel(sel1), 
   .out_1(out_sign)
   );
   
   
   (* dont_touch = "true" *) int32_to_dlfloat16_pipeline i2f(
   .clk(clk),
   .rst_n(reset),
   .in_int(op1), 
   .ena(ena), 
   .float_out_1(out_i2f)
   );


   //i(* dont_touch = "true" *) nt32_to_dlfloat16 i2f(
//   .in_int(op1), 
//   .ena(ena), 
//   .float_out_1(out_i2f)
//   );
   
   (* dont_touch = "true" *) dlfloat16_to_int32 f2i(
   .float_in(src1), 
   .ena(ena), 
   .int_out_fin_1(out_f2i)
   );
   
   (* dont_touch = "true" *) dlfloat16_comp comp(
   .a1(src1), 
   .b1(src2), 
   .ena(ena), 
   .sel(sel2), 
   .c_out_1(out_comp)
   );


   (* dont_touch = "true" *) out_mux outmux(
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

   (* dont_touch = "true" *) dlfloat16_round round(
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


//module int32_to_dlfloat16(
//   input wire signed [31:0] in_int,
//   input wire[3:0] ena,
//   output reg [19:0] float_out_1  
//);
//    reg [5:0] exponent;   
//    reg [8:0] mantissa;    
//    reg sign;             
//    reg [31:0] abs_input;
//    reg [15:0] float_out;
//    integer i;

          

       
//    always @(*) begin
//        float_out_1 = 20'b0;
        
//      if(ena != 4'b0111)
//        float_out = 16'b0;
//      else begin
//      if (in_int == 32'b0) begin
//        float_out = 16'b0;
//      end
      
//      sign = (in_int < 0) ? 1 : 0;
        
//      //determine absolute value
//      abs_input = (in_int < 0) ? -in_int : in_int;
        
//        // Normalize the number 
//        exponent = 0;
//        mantissa = 0;
//        //NOTE: might get synth warnings for else block path but when i tried to add else block to exit from the loop threw synth errros
//      // Find the exponent (shift the number to be in the form 1.xxxx)
//       for (i = 0; i < 32 ; i = i + 1) begin
//        if (abs_input >= (1 << (exponent + 1))) begin
//            exponent = exponent + 1; 
//        end
//       end        
//        // Shift the number to form the normalized mantissa
//        if ( exponent <= 9) begin
//          mantissa = abs_input << (9 - exponent);  // Left shift for +ve exp
//           end else begin
//             mantissa = abs_input >> (exponent - 9);// Right shift for -ve exp
//           end

        
//        //Bias the exponent 
//        exponent = exponent + 31;
      
//      float_out = {sign,exponent,mantissa};
//      end 
//      float_out_1 = {float_out,4'b0000};
//    end
    
//endmodule

module dlfloat16_to_int32(
   input wire [3:0] ena,
   input wire[15:0] float_in,
   output reg signed [31:0] int_out_fin_1
);
  reg sign;
  reg [5:0] exponent;
  reg [9:0] mantissa; 
  reg signed [5:0] actual_exponent;
  reg signed [31:0] result;
  reg signed [31:0] int_out_fin;

  always @(*) begin
    int_out_fin_1 = 32'b0;
	  if(ena != 4'b1000)
		  int_out_fin = 32'b0;
	  else begin
    // Extract fields
    sign = float_in[15];
    exponent = float_in[14:9];
    mantissa = {1'b1, float_in[8:0]}; 
    
    // Handle special cases
    if (exponent == 6'b000000) begin
      int_out_fin = 0;
    end  
    else if (exponent == 6'b111111) begin
      // Infinity or NaN: saturate to max 32-bit signed integer
      int_out_fin = sign ? -32'h80000000 : 32'h7FFFFFFF;
    end else begin
  
      actual_exponent = exponent - 31; // Unbias the exponent
      
      if (actual_exponent <= 9) begin
        result = {23'b0, mantissa >> ( 9 - actual_exponent)};
        end else begin
        result = mantissa << (actual_exponent - 9);
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




module dlfloat16_sign_inv (
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


module dlfloat16_round ( 
      input [19:0] in, 
      input [3:0] ena,
      input [2:0] rm,
      output reg [15:0] out_1
);
  
  reg G_bit,R_bit, S1_bit , S2_bit, S_bit;
  reg sign;
  reg [5:0] exp,exp_tmp;
  reg [9:0] mant1, mant1_tmp;
  reg [8:0] mant;
  reg [15:0] rounded_val;
  reg [15:0] out;

always @(*) begin
        // Extract and decode input fields
        sign   = in[19];
        exp    = in[18:13];
        mant1  = {1'b0, in[12:4]}; // 10 bits with leading 0
        G_bit  = in[3];
        R_bit  = in[2];
        S1_bit = in[1];
        S2_bit = in[0];
        S_bit  = S1_bit | S2_bit;

        // Initialize to avoid latches
        mant1_tmp    = mant1;
        exp_tmp      = exp;
        mant         = mant1[8:0];
        rounded_val  = {sign, exp_tmp, mant};
        out_1 = 16'b0;

        // Rounding modes
        case (rm)
            // Round to nearest, ties to even
            3'b000: begin
                if (!G_bit) begin
                    mant = mant1[8:0];
                end else if (R_bit | S_bit) begin
                    if (in[4]) begin // tie: LSB = 1
                        mant1_tmp = mant1 + 1;
                        mant = mant1_tmp[8:0];
                        if (mant1_tmp[9])
                            exp_tmp = exp + 1;
                    end else begin
                        mant = mant1[8:0]; // tie: LSB = 0
                    end
                end else begin
                    // G=1, R=0, S=0 → midpoint → round up
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[8:0];
                    if (mant1_tmp[9])
                        exp_tmp = exp + 1;
                end
            end

            // Round toward zero
            3'b001: begin
                mant = mant1[8:0];
            end

            // Round up (toward +∞)
            3'b010: begin
                if ((G_bit | R_bit | S_bit) && !sign) begin
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[8:0];
                    if (mant1_tmp[9])
                        exp_tmp = exp + 1;
                end else begin
                    mant = mant1[8:0];
                end
            end

            // Round down (toward -∞)
            3'b011: begin
                if ((G_bit | R_bit | S_bit) && sign) begin
                    mant1_tmp = mant1 + 1;
                    mant = mant1_tmp[8:0];
                    if (mant1_tmp[9])
                        exp_tmp = exp + 1;
                end else begin
                    mant = mant1[8:0];
                end
            end

            // Default: truncate
            default: begin
                mant = mant1[8:0];
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
      
    
// Code your design here
module dlfloat16_mul(a,b,ena,c_mul_1);
  input wire [15:0]a,b;
  input wire [3:0] ena;
  output  reg [19:0] c_mul_1;
    
    reg [9:0]ma,mb; //1 extra because 1.smthng
    reg [12:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
	reg [19:0] c_mul;

		 	
  always@(*) begin
        ma ={1'b1,a[8:0]};
        mb= {1'b1,b[8:0]};
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];
        c_mul_1 = 20'b0;
  	    
       //to avoid latch inference
  	e_temp = 6'b0;
  	m_temp = 20'b0;
  	mant=9'b0;
  	exp= 6'b0;
  	s=0;
	  if(ena !=4'b0010)
		  c_mul =20'b0;
	  else begin

		  
  	//checking for underflow/overflow
    if (  (ea + eb) <= 31 ) begin
  		c_mul=16'b0;//pushing to zero on underflow
  	end
    else if ( (ea + eb) > 94) begin
      if( (sa ^ sb) ) begin
          c_mul=16'hFDFE;//pushing to largest -ve number on overflow
        end
      else begin
          c_mul=16'h7DFE;//pushing to largest +ve number on overflow
      end
    end
        
  	else if ( (ea + eb) == 94 ) begin
		c_mul=16'hFFFF;//pushing to inf if exp is all ones
 	end
        else begin	
        e_temp = ea + eb - 31;
        m_temp = ma * mb;
		
          mant = m_temp[19] ? m_temp[18:6] : m_temp[17:5];
        exp = m_temp[19] ? e_temp+1'b1 : e_temp;	
        s=sa ^ sb;
		
 	//checking for special cases	
         if( a==16'hFFFF | b==16'hFFFF ) begin
            c_mul =16'hFFFF;
         end
        else begin
           c_mul = (a==0 | b==0) ? 0 :{s,exp,mant};
         end 
 	end 
    end 
    c_mul_1 = c_mul;
  end
	wire _unused = &{m_temp[8:0], 9'b0};

	
endmodule


// Code your design here
module dlfloat16_mac(a,b,c_add,ena,op,clk,reset);
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
 
 	fpmac_mult mul(.a(a),.b(b),.c_mul(c_mul1),.ena(ena));
	fpmac_adder add(.a1(c_mul1),.b1(b1),.c_add_1(c_add_wire),.oper(oper));
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
  
module fpmac_mult(a,b,c_mul,ena);
    input wire [15:0]a,b;
    output  reg [15:0] c_mul;
	input wire [3:0] ena;  
    reg [9:0]ma,mb; //1 extra because 1.smthng
    reg [8:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
    reg [15:0] c_mul1;
  	
    always@(*) begin
	  if(ena !=4'b1001)
		  c_mul1 = 16'b0;
	  else begin
        ma ={1'b1,a[8:0]};
        mb= {1'b1,b[8:0]};
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];
        c_mul = 16'b0;
       //to avoid latch inference
  	e_temp = 6'b0;
  	m_temp = 20'b0;
  	mant=9'b0;
  	exp= 6'b0;
  	s=0;
  	
  	//checking for underflow/overflow
    if (  (ea + eb) <= 31 ) begin
  		c_mul1=16'b0;//pushing to zero on underflow
  	end
    else if ( (ea + eb) > 94) begin
      if( (sa ^ sb) ) begin
          c_mul1=16'hFDFE;//pushing to largest -ve number on overflow
        end
      else begin
          c_mul1=16'h7DFE;//pushing to largest +ve number on overflow
      end
    end
        
  	else if ( (ea + eb) == 94 ) begin
		c_mul1=16'hFFFF;//pushing to inf if exp is all ones
 	end
        else begin	
        e_temp = ea + eb - 31;
        m_temp = ma * mb;
		
        mant = m_temp[19] ? m_temp[18:10] : m_temp[17:9];
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
	  end
	  c_mul = c_mul1;
    end 
	wire _unused = &{m_temp[8:0], 9'b0};
	
endmodule
 
module fpmac_adder(a1,b1,c_add_1,oper);
   
   	 input wire [15:0] a1;
   	 input wire [15:0] b1;
   	 output reg [19:0] c_add_1;
   	 input wire oper;
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
    reg [19:0] c_add;
    
    always@(*) begin
     	     e1_80 = a1[14:9];
    	     e2_80 = b1[14:9];
             m1_80 = a1[8:0];
     	     m2_80 = b1[8:0];
             s1_80 = a1[15];
             c_add_1 = 20'b0;
           begin
           if(oper) begin
             s2_80 = ~b1[15]; //for subtraction op will be 1
           end
           else begin
              s2_80 = b1[15];
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
		   Add1_mant_80= Add_mant_80 << 1;
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
             if (  Final_sign_80 ) begin
                c_add=16'hFDFE;//largest -ve value
		     
             end
             else begin
               c_add=16'h7DFE;//largest +ve value
             end
  
           end
           else if ((Larger_exp_80 >= 1) & (Larger_exp_80 <= 8) & (renorm_exp_80 <  larger_expo_neg)) begin //underflow
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
                     c_add=16'b0;
               end
               else if( Final_expo_80 == 63) begin
                     c_add=16'hFFFF;
               end      

             Final_mant_80 = {Add1_mant_80,2'b00}; 
	        Final_mant_80=Final_mant_80<<2;
               //checking for special cases
               if( a1==16'hFFFF | b1==16'hFFFF) begin  
                 c_add = 16'hFFFF;
               end
               else begin
                 c_add = (a1==0 & b1==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
               end 
           end//for overflow/underflow 
	    end
        c_add_1 = c_add;
  end 

  
endmodule


module dlfloat16_div(
    input wire [3:0] ena,
    input wire [15:0] a, b,
    output reg [19:0] c_div_1
);
    reg [9:0] ma, mb;       
    reg [12:0] mant;        
    reg [23:0] m_temp;     
    reg [5:0] ea, eb, e_temp, exp;
    reg sa, sb, s;     
    reg [19:0] c_div;

            

always @(*) begin
     
        ma = {1'b1, a[8:0]}; 
        mb = {1'b1, b[8:0]}; 
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];

        e_temp = 6'b0;
        m_temp = 16'b0;
        mant = 13'b0;
        exp = 6'b0;
        s = 0;
        c_div = 20'b0; 
        c_div_1 = 20'b0;
        if(ena != 4'b0011)
            c_div = 20'b0;
        else begin
        // Special Cases
      if(( b == 16'b0 || b==16'b1000000000000000) &&(a==16'b0 || a==16'b1000000000000000))
            begin
              c_div = {sa ^sb,15'b111111111111111,4'b0};
            end
      
       else if (b == 16'b0 || b == 16'b1000000000000000) begin
            c_div = {sa ^ sb, 6'b111111, 13'b0};
        end else if (a == 16'hfe00 || a == 16'h7e00) begin
            
          if (b == 16'hFe00 || b == 16'h7e00) begin
            c_div = {sa ^sb,15'b111111111111111,4'b0}; 
            end else begin
               
                c_div = {sa ^ sb, 6'b111111, 13'b0}; 
            end
        end else if (b == 16'hfe00 || b == 16'h7e00) begin
           
            c_div = {sa ^ sb, 19'b0};
        end else if (a == 16'b0 || a == 16'b1000000000000000) begin
            
          
            c_div = {sa ^ sb, 19'b0};
        end else begin
            
          e_temp = 31-(eb-ea);
          m_temp = (ma<<13) / mb; 
          if (m_temp[13]) begin
            mant = m_temp[12:0]; 
                exp = e_temp;
            end else begin
              mant = m_temp[11:0]<<1; 
              exp = e_temp -1'b1;
            end
            s = sa ^ sb;

         

            // Check for underflow/overflow
            if (exp < 0) begin
                c_div = 20'b0; 
            end else if (exp > 63) begin
                c_div = s ? 20'hFDFE0 : 20'h7DFE0; 
            end else begin
                c_div = {s, exp, mant};
            end
            end
        
        end
        c_div_1 = c_div;
    end

    
endmodule


module dlfloat16_comp (
   input wire [15:0] a1,
   input wire [15:0] b1,
   input wire [2:0] sel,
   input wire [3:0] ena,
   output reg [19:0] c_out_1
);
  reg s1, s2;
  reg [5:0] exp1, exp2;
  reg [8:0] mant1, mant2;
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
    exp1 = a1[14:9];
    exp2 = b1[14:9];
    mant1 = a1[8:0];
    mant2 = b1[8:0];
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


module dlfloat16_add_sub(
     input wire [15:0] a,
     input wire [15:0] b,
     input wire op,
     input wire [3:0] ena, 
     output reg [19:0] c_add_1
    );
    
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


		

    always@(*) begin
        e1_80 = a[14:9];
        e2_80 = b[14:9];
        m1_80 = a[8:0];
        m2_80 = b[8:0];
        s1_80 = a[15];
        
        if(ena != 4'b0001)
            c_add = 20'b0;
        else begin
            if(op) begin
                s2_80 = ~b[15];
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
                Small_exp_mantissa_80 = 10'd512;
            end
            else begin
                Num_shift_80 = Num_shift_80;
            end
            
            Small_exp_mantissa_80  = (Small_exp_mantissa_80 >> Num_shift_80);
              
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
      
            renorm_exp_80=6'd0;
            renorm_shift_80=9'd0;
            Add1_mant_80=Add_mant_80; 
           
            if (Add_mant_80[10] ) begin
                Add1_mant_80= Add_mant_80 >> 1;  
                renorm_exp_80 = 6'd1;
            end
            else begin 
                if (Add_mant_80[9])begin
                    renorm_shift_80 = 0;
                    renorm_exp_80 = 0;		
                    Add1_mant_80 = Add_mant_80;
                end
                else if (Add_mant_80[8])begin
                    renorm_shift_80 = 9'd1; 
                    renorm_exp_80 = -1;
                    Add1_mant_80 = Add_mant_80 << 1;
                end 
                else if (Add_mant_80[7])begin
                    renorm_shift_80 = 9'd2; 
                    renorm_exp_80 = -2;
                    Add1_mant_80 = Add_mant_80 << 2;		
                end  
                else if (Add_mant_80[6])begin
                    renorm_shift_80 = 9'd3; 
                    renorm_exp_80 = -3;
                    Add1_mant_80 = Add_mant_80 << 3;		
                end
                else if (Add_mant_80[5])begin
                    renorm_shift_80 = 9'd4; 
                    renorm_exp_80 = -4;
                    Add1_mant_80 = Add_mant_80 << 4;		
                end
                else if (Add_mant_80[4])begin
                    renorm_shift_80 = 9'd5; 
                    renorm_exp_80 = -5;
                    Add1_mant_80 = Add_mant_80 << 5;		
                end
                else if (Add_mant_80[3])begin
                    renorm_shift_80 = 9'd6; 
                    renorm_exp_80 = -6;
                    Add1_mant_80 = Add_mant_80 << 6;		
                end
                else if (Add_mant_80[2])begin
                    renorm_shift_80 = 9'd7; 
                    renorm_exp_80 = -7;
                    Add1_mant_80 = Add_mant_80 << 7;		
                end
                else if (Add_mant_80[1])begin
                    renorm_shift_80 = 9'd8; 
                    renorm_exp_80 = -8;
                    Add1_mant_80 = Add_mant_80 << 8;		
                end
                else if (Add_mant_80[0])begin
                    renorm_shift_80 = 9'd9; 
                    renorm_exp_80 = -9;
                    Add1_mant_80 = Add_mant_80 << 9;		
                end
                else begin
                    renorm_exp_80=6'd0;
                    renorm_shift_80=9'd0;
                    Add1_mant_80=11'b0;
                end
            end

            Final_expo_80 = 6'd0;
            Final_mant_80 = 13'd0;
            Final_sign_80=0;
            larger_expo_neg = -Larger_exp_80;
      	   
            if (s1_80 == s2_80) begin
                Final_sign_80 = s1_80;
            end 
            else begin 
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
         
            if(  Larger_exp_80 == 63 & renorm_exp_80 == 1) begin
                if (  Final_sign_80 ) begin
                    c_add=20'hFDFE0;
                end
                else begin
                    c_add=20'h7DFE0;
                end
            end
            else if ((Larger_exp_80 >= 1) & (Larger_exp_80 <= 8) & (renorm_exp_80 <  larger_expo_neg)) begin //underflow
                if (  Final_sign_80 ) begin
                    c_add=20'h82010;
                end
                else begin
                    c_add=20'h02010;
                end
            end 
            else begin
                Final_expo_80 =  Larger_exp_80 + renorm_exp_80;
      
                if(Final_expo_80 == 6'b0) begin
                    c_add=20'b0;
                end
                else if( Final_expo_80 == 63) begin
                    c_add=20'hFFFFF;
                end      
                else begin
                    Final_mant_80 = {Add1_mant_80[8:0], 4'b0000}; 
                    
                    if( a==16'hFFFF | b==16'hFFFF) begin  
                        c_add = 20'hFFFFF;
                    end
                    else begin
                        c_add = (a==0 & b==0) ? 20'b0 : {Final_sign_80, Final_expo_80, Final_mant_80};
                    end
                end
            end
        end
        c_add_1 = c_add;
    end 
endmodule


module ieee32_to_dlfp16 (
    input  wire [31:0] ieee32_in,
    output wire [15:0] dlfp16_out
);
    
    wire        sign   = ieee32_in[31];
    wire [7:0]  exp32  = ieee32_in[30:23];
    wire [22:0] frac32 = ieee32_in[22:0];
    wire is_nan32   = (exp32 == 8'hFF) && (frac32 != 0);
    wire is_inf32   = (exp32 == 8'hFF) && (frac32 == 0);
    wire is_zero32  = (exp32 == 8'h00) && (frac32 == 0);
    wire [23:0] sig24 = (exp32 == 8'h00) ? {1'b0, frac32} : {1'b1, frac32};
    wire signed [9:0] e_single = (exp32 == 8'h00) ? -10'sd126 : $signed({1'b0, exp32}) - 10'sd127;
    wire signed [9:0] e_dl = e_single + 10'sd31;
    wire [8:0] mant_main_norm = sig24[22:14]; // 9 bits
    wire       g_norm         = sig24[13];
    wire       r_norm         = sig24[12];
    wire       s_norm         = |sig24[11:0];
    wire       round_up_norm  = g_norm && (r_norm | s_norm | mant_main_norm[0]);
    reg  [5:0]  exp_dl;       // 6-bit exponent
    reg  [8:0]  mant_dl;      // 9-bit mantissa
    reg  [9:0]  mant_ext;     // for rounding carry
    reg  [5:0]  exp_dl_plus1;
    integer     shift_amt;
    reg  [27:0] aligned;      // {sig24, 4'b0} to provide G/R/S during shifts
    reg  [27:0] shifted;
    reg  [8:0]  mant_main_sub;
    reg         g_sub, r_sub, s_sub;
    reg         round_up_sub;
    reg  [9:0]  mant_sub_ext;

    always @* begin
        exp_dl  = 6'd0;
        mant_dl = 9'd0;

        if (is_nan32) begin
            exp_dl  = 6'h3F;                 // all ones
            mant_dl = 9'h100 | (frac32[22] ? 9'h001 : 9'h000);
        end
        else if (is_inf32) begin
            exp_dl  = 6'h3F;                 // +/-Inf
            mant_dl = 9'h000;
        end
        else if (is_zero32) begin
            exp_dl  = 6'd0;                  // signed zero
            mant_dl = 9'd0;
        end
        else if (e_dl >= 10'sd63) begin
            exp_dl  = 6'h3F;                 // Inf
            mant_dl = 9'd0;
        end
        else if (e_dl <= 10'sd0) begin
            shift_amt = (1 - e_dl);          // >= 1
            if (shift_amt > 27) begin
                exp_dl  = 6'd0;
                mant_dl = 9'd0;              // underflow to zero
            end else begin
                aligned = {sig24, 4'b0000};  // width 28
                shifted = aligned >> shift_amt;
                mant_main_sub = shifted[27:19];   // 9-bit candidate
                g_sub         = shifted[18];
                r_sub         = shifted[17];
                s_sub         = |shifted[16:0];
                round_up_sub  = g_sub && (r_sub | s_sub | mant_main_sub[0]);
                mant_sub_ext  = {1'b0, mant_main_sub} + (round_up_sub ? 10'd1 : 10'd0);
                if (mant_sub_ext[9]) begin
                    exp_dl  = 6'd1;
                    mant_dl = 9'd0;
                end else begin
                    exp_dl  = 6'd0;
                    mant_dl = mant_sub_ext[8:0];
                end
            end
        end
        else begin
            mant_ext = {1'b0, mant_main_norm} + (round_up_norm ? 10'd1 : 10'd0);
            if (mant_ext[9]) begin
                if ((e_dl + 10'sd1) >= 10'sd63) begin
                    exp_dl  = 6'h3F;          // becomes Inf
                    mant_dl = 9'd0;
                end else begin
                    exp_dl_plus1 = e_dl[5:0] + 6'd1;
                    exp_dl  = exp_dl_plus1;
                    mant_dl = mant_ext[9:1];  // drop carry bit
                end
            end else begin
                exp_dl  = e_dl[5:0];
                mant_dl = mant_ext[8:0];
            end
        end
    end

    assign dlfp16_out = {sign, exp_dl, mant_dl};
endmodule


module dlfp16_to_ieee32 (
    input  wire [15:0] dlfp16,   // DLFloat-16 input
    output wire [31:0] ieee32    // IEEE-754 single precision output
);

    wire        sign;
    wire [5:0]  exp16;
    wire [8:0]  frac16;

    assign sign   = dlfp16[15];
    assign exp16  = dlfp16[14:9];
    assign frac16 = dlfp16[8:0];


    wire is_zero = (exp16 == 6'd0)  && (frac16 == 9'd0);
    wire is_inf  = (exp16 == 6'd63) && (frac16 == 9'd0);
    wire is_nan  = (exp16 == 6'd63) && (frac16 != 9'd0);

    wire signed [9:0] exp_unbiased = exp16 - 31;  // remove DLFloat bias
    wire signed [9:0] exp32_temp   = exp_unbiased + 127; // apply IEEE bias

    wire [7:0] exp32 = is_zero ? 8'd0 :
                       is_inf  ? 8'hFF :
                       is_nan  ? 8'hFF :
                       exp32_temp[7:0];

    wire [22:0] frac32 = is_zero ? 23'd0 :
                         is_inf  ? 23'd0 :
                         is_nan  ? {1'b1, 22'd0} :   // quiet NaN
                         {frac16, 14'b0};
    assign ieee32 = {sign, exp32, frac32};

endmodule


module sqrt_pipeline(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  ena,
    input  wire [15:0] dl_in,
    output reg  [19:0] dl_out20
);

localparam integer MANT_EXTRACT_SHIFT = 0;
localparam integer GUARD_BIT = 2;
localparam integer CONV_THRESH = 13'd1;

// internal signals (decode + pipeline regs)
reg valid_in;
reg        sign_comb;
reg [5:0]  exp_in_comb,ier;
reg [8:0]  mant_in_comb;
reg [9:0]  mant_norm_comb;   // normalized mantissa (10 bits)
reg [5:0]  exp_half_comb;    // exponent after halving (stage0)

// pipeline registers (including pipeline-tracked input for debug)
reg [15:0] in_reg0, in_reg1, in_reg2, in_reg3, in_reg4, in_reg5, in_reg6, in_reg7, in_reg8;
reg [12:0] x_reg0, x_reg1, x_reg2, x_reg3, x_reg4, x_reg5, x_reg6, x_reg7, x_reg8;
reg [9:0]  mant_norm_reg0, mant_norm_reg1, mant_norm_reg2, mant_norm_reg3,
           mant_norm_reg4, mant_norm_reg5, mant_norm_reg6, mant_norm_reg7, mant_norm_reg8;
reg [5:0]  exp_out_reg0, exp_out_reg1, exp_out_reg2, exp_out_reg3, exp_out_reg4,
           exp_out_reg5, exp_out_reg6, exp_out_reg7, exp_out_reg8;
reg        sign0, sign1, sign2, sign3, sign4, sign5, sign6, sign7, sign8;
reg        valid_reg0, valid_reg1, valid_reg2, valid_reg3, valid_reg4, valid_reg5, valid_reg6, valid_reg7, valid_reg8;

reg        done_reg0, done_reg1, done_reg2, done_reg3, done_reg4, done_reg5, done_reg6, done_reg7, done_reg8;
reg        conv0, conv1, conv2, conv3, conv4, conv5, conv6, conv7;
reg [12:0] x_next_comb0, x_next_comb1, x_next_comb2, x_next_comb3,
           x_next_comb4, x_next_comb5, x_next_comb6, x_next_comb7;
reg [12:0] diff_comb0, diff_comb1, diff_comb2, diff_comb3,
           diff_comb4, diff_comb5, diff_comb6, diff_comb7;

// final packing combinational
reg [12:0] mant_nr;
reg [12:0] mant13;         // 13-bit mantissa field (final)
reg [12:0] mant_full19;        // intermediate full mantissa (19-bit)
reg [12:0]  x_nonpipe;         // unscaled x (approx sqrt of mant_norm)
reg [19:0] dl_out_next;
reg [5:0]  exp_out_final;
reg [12:0] remainder12;       // remainder width (safe for mant_norm - x*x)
reg [19:0] dl_tmp;
            reg [19:0] sq;
            reg [19:0] mantnorm_ext;
// -----------------------------
// Stage 0: decode + normalize
// -----------------------------
always @(*) begin
    mant_norm_comb = 10'd0;
    exp_half_comb  = 6'd0;
    // Use ena[2] as start (same semantics you used earlier)
    sign_comb = 1'b0;
    exp_in_comb = 6'd0;
    mant_in_comb = 9'd0;
    if (ena== 4'b0100) begin
        valid_in = 1;
    end else begin
        valid_in =0;
    end

    if (ena == 4'b0100) begin
        sign_comb    = dl_in[15];
        exp_in_comb  = dl_in[14:9];
        mant_in_comb = dl_in[8:0];

        if (exp_in_comb == 6'd0) begin
            mant_norm_comb = {1'b0, mant_in_comb}; // denorm or zero
            exp_half_comb  = 6'd0;
        end else begin
            mant_norm_comb = {1'b1,mant_in_comb};
        end
            
        
            if (exp_in_comb[0]) begin
                // odd exponent: shift mantissa right and bump exponent before halving
                mant_norm_comb = ({mant_norm_comb} >> 1);
                ier = (exp_in_comb + 1);
            end else begin
                ier = exp_in_comb;
            end
            exp_half_comb = (ier + 31) >> 1;
        end
    end


// Stage0 regs
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg0 <= 13'd0;
        mant_norm_reg0 <= 10'd0;
        exp_out_reg0 <= 6'd0;
        valid_reg0 <= 1'b0;
        done_reg0 <= 1'b0;
        sign0 <= 1'b0;
        in_reg0 <= 16'd0;
    end else begin
        in_reg0 <= dl_in;
        x_reg0 <= {mant_norm_comb}; // left justify (scale by 2^3)
        mant_norm_reg0 <= mant_norm_comb;
        exp_out_reg0 <= exp_half_comb;
        valid_reg0 <= valid_in;
        done_reg0 <= 1'b0;
        sign0 <= sign_comb;
    end
end

// -----------------------------
// NR stages (with forwarding) - numerator scaled to match x_reg (<<3)
// -----------------------------
always @(*) begin
    // Stage1 comb (from reg0)
    x_next_comb0 = x_reg0;
    conv0 = 1'b0;
    diff_comb0 = 13'd0;
    if (valid_reg0 && !done_reg0) begin
        if (x_reg0 == 13'd0) begin
            x_next_comb0 = 13'd0;
        end else begin
            // numerator scaled to match x_reg (mant_norm_reg0)
            x_next_comb0 = (x_reg0 + (mant_norm_reg0 / x_reg0 )) >> 1;
        end
        diff_comb0 = (x_reg0 > x_next_comb0) ? (x_reg0 - x_next_comb0) : (x_next_comb0 - x_reg0);
        if (diff_comb0 <= 1) conv0 = 1'b1;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        x_reg1 <= 13'd0; mant_norm_reg1 <= 10'd0; exp_out_reg1 <= 6'd0; valid_reg1 <= 1'b0; done_reg1 <= 1'b0; sign1 <= 1'b0; in_reg1 <= 16'd0;
    end else begin
        in_reg1 <= in_reg0;
        if (done_reg0) x_reg1 <= x_reg0; else x_reg1 <= x_next_comb0;
        mant_norm_reg1 <= mant_norm_reg0;
        exp_out_reg1 <= exp_out_reg0;
        valid_reg1 <= valid_reg0;
        done_reg1 <= done_reg0 | conv0;
        sign1 <= sign0;
    end
end

// Stage 2
always @(*) begin
    x_next_comb1 = x_reg1;
    conv1 = 1'b0;
    diff_comb1 = 13'd0;
    if (valid_reg1 && !done_reg1) begin
        if (x_reg1 == 13'd0) begin
            x_next_comb1 = 13'd0;
        end else begin
            x_next_comb1 = (x_reg1 + ( (mant_norm_reg1) / x_reg1 )) >> 1;
        end
        diff_comb1 = (x_reg1 > x_next_comb1) ? (x_reg1 - x_next_comb1) : (x_next_comb1 - x_reg1);
        if (diff_comb1 <= CONV_THRESH) conv1 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg2 <= 13'd0; mant_norm_reg2 <= 10'd0; exp_out_reg2 <= 6'd0; valid_reg2 <= 1'b0; done_reg2 <= 1'b0; sign2 <= 1'b0; in_reg2 <= 16'd0;
    end else begin
        in_reg2 <= in_reg1;
        if (done_reg1) x_reg2 <= x_reg1; else x_reg2 <= x_next_comb1;
        mant_norm_reg2 <= mant_norm_reg1;
        exp_out_reg2 <= exp_out_reg1;
        valid_reg2 <= valid_reg1;
        done_reg2 <= done_reg1 | conv1;
        sign2 <= sign1;
    end
end

// Stage 3
always @(*) begin
    x_next_comb2 = x_reg2;
    conv2 = 1'b0;
    diff_comb2 = 13'd0;
    if (valid_reg2 && !done_reg2) begin
        if (x_reg2 == 13'd0) begin
            x_next_comb2 = 13'd0;
        end else begin
            x_next_comb2 = (x_reg2 + ( (mant_norm_reg2) / x_reg2 )) >> 1;
        end
        diff_comb2 = (x_reg2 > x_next_comb2) ? (x_reg2 - x_next_comb2) : (x_next_comb2 - x_reg2);
        if (diff_comb2 <= CONV_THRESH) conv2 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg3 <= 13'd0; mant_norm_reg3 <= 10'd0; exp_out_reg3 <= 6'd0; valid_reg3 <= 1'b0; done_reg3 <= 1'b0; sign3 <= 1'b0; in_reg3 <= 16'd0;
    end else begin
        in_reg3 <= in_reg2;
        if (done_reg2) x_reg3 <= x_reg2; else x_reg3 <= x_next_comb2;
        mant_norm_reg3 <= mant_norm_reg2;
        exp_out_reg3 <= exp_out_reg2;
        valid_reg3 <= valid_reg2;
        done_reg3 <= done_reg2 | conv2;
        sign3 <= sign2;
    end
end

// Stage 4
always @(*) begin
    x_next_comb3 = x_reg3;
    conv3 = 1'b0;
    diff_comb3 = 13'd0;
    if (valid_reg3 && !done_reg3) begin
        if (x_reg3 == 13'd0) begin
            x_next_comb3 = 13'd0;
        end else begin
            x_next_comb3 = (x_reg3 + ( (mant_norm_reg3) / x_reg3 )) >> 1;
        end
        diff_comb3 = (x_reg3 > x_next_comb3) ? (x_reg3 - x_next_comb3) : (x_next_comb3 - x_reg3);
        if (diff_comb3 <= CONV_THRESH) conv3 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg4 <= 13'd0; mant_norm_reg4 <= 10'd0; exp_out_reg4 <= 6'd0; valid_reg4 <= 1'b0; done_reg4 <= 1'b0; sign4 <= 1'b0; in_reg4 <= 16'd0;
    end else begin
        in_reg4 <= in_reg3;
        if (done_reg3) x_reg4 <= x_reg3; else x_reg4 <= x_next_comb3;
        mant_norm_reg4 <= mant_norm_reg3;
        exp_out_reg4 <= exp_out_reg3;
        valid_reg4 <= valid_reg3;
        done_reg4 <= done_reg3 | conv3;
        sign4 <= sign3;
    end
end

// Stage 5
always @(*) begin
    x_next_comb4 = x_reg4;
    conv4 = 1'b0;
    diff_comb4 = 13'd0;
    if (valid_reg4 && !done_reg4) begin
        if (x_reg4 == 13'd0) begin
            x_next_comb4 = 13'd0;
        end else begin
            x_next_comb4 = (x_reg4 + ( (mant_norm_reg4) / x_reg4 )) >> 1;
        end
        diff_comb4 = (x_reg4 > x_next_comb4) ? (x_reg4 - x_next_comb4) : (x_next_comb4 - x_reg4);
        if (diff_comb4 <= CONV_THRESH) conv4 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg5 <= 13'd0; mant_norm_reg5 <= 10'd0; exp_out_reg5 <= 6'd0; valid_reg5 <= 1'b0; done_reg5 <= 1'b0; sign5 <= 1'b0; in_reg5 <= 16'd0;
    end else begin
        in_reg5 <= in_reg4;
        if (done_reg4) x_reg5 <= x_reg4; else x_reg5 <= x_next_comb4;
        mant_norm_reg5 <= mant_norm_reg4;
        exp_out_reg5 <= exp_out_reg4;
        valid_reg5 <= valid_reg4;
        done_reg5 <= done_reg4 | conv4;
        sign5 <= sign4;
    end
end

// Stage 6
always @(*) begin
    x_next_comb5 = x_reg5;
    conv5 = 1'b0;
    diff_comb5 = 13'd0;
    if (valid_reg5 && !done_reg5) begin
        if (x_reg5 == 13'd0) begin
            x_next_comb5 = 13'd0;
        end else begin
            x_next_comb5 = (x_reg5 + ( (mant_norm_reg5) / x_reg5 )) >> 1;
        end
        diff_comb5 = (x_reg5 > x_next_comb5) ? (x_reg5 - x_next_comb5) : (x_next_comb5 - x_reg5);
        if (diff_comb5 <= CONV_THRESH) conv5 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg6 <= 13'd0; mant_norm_reg6 <= 10'd0; exp_out_reg6 <= 6'd0; valid_reg6 <= 1'b0; done_reg6 <= 1'b0; sign6 <= 1'b0; in_reg6 <= 16'd0;
    end else begin
        in_reg6 <= in_reg5;
        if (done_reg5) x_reg6 <= x_reg5; else x_reg6 <= x_next_comb5;
        mant_norm_reg6 <= mant_norm_reg5;
        exp_out_reg6 <= exp_out_reg5;
        valid_reg6 <= valid_reg5;
        done_reg6 <= done_reg5 | conv5;
        sign6 <= sign5;
    end
end

// Stage 7
always @(*) begin
    x_next_comb6 = x_reg6;
    conv6 = 1'b0;
    diff_comb6 = 13'd0;
    if (valid_reg6 && !done_reg6) begin
        if (x_reg6 == 13'd0) begin
            x_next_comb6 = 13'd0;
        end else begin
            x_next_comb6 = (x_reg6 + ( (mant_norm_reg6) / x_reg6 )) >> 1;
        end
        diff_comb6 = (x_reg6 > x_next_comb6) ? (x_reg6 - x_next_comb6) : (x_next_comb6 - x_reg6);
        if (diff_comb6 <= CONV_THRESH) conv6 = 1'b1;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        x_reg7 <= 13'd0; mant_norm_reg7 <= 10'd0; exp_out_reg7 <= 6'd0; valid_reg7 <= 1'b0; done_reg7 <= 1'b0; sign7 <= 1'b0; in_reg7 <= 16'd0;
    end else begin
        in_reg7 <= in_reg6;
        if (done_reg6) x_reg7 <= x_reg6; else x_reg7 <= x_next_comb6;
        mant_norm_reg7 <= mant_norm_reg6;
        exp_out_reg7 <= exp_out_reg6;
        valid_reg7 <= valid_reg6;
        done_reg7 <= done_reg6 | conv6;
        sign7 <= sign6;
    end
end

// Stage 8 comb (final NR)
always @(*) begin
    x_next_comb7 = x_reg7;
    conv7 = 1'b0;
    diff_comb7 = 13'd0;
    if (valid_reg7 && !done_reg7) begin
        if (x_reg7 == 13'd0) begin
            x_next_comb7 = 13'd0;
        end else begin
            x_next_comb7 = (x_reg7 + ( (mant_norm_reg7) / x_reg7 )) >> 1;
        end
        diff_comb7 = (x_reg7 > x_next_comb7) ? (x_reg7 - x_next_comb7) : (x_next_comb7 - x_reg7);
        if (diff_comb7 <= CONV_THRESH) conv7 = 1'b1;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        x_reg8 <= 13'd0; mant_norm_reg8 <= 10'd0; exp_out_reg8 <= 6'd0; valid_reg8 <= 1'b0; done_reg8 <= 1'b0; sign8 <= 1'b0; in_reg8 <= 16'd0;
    end else begin
        in_reg8 <= in_reg7;
        if (done_reg7) x_reg8 <= x_reg7; else x_reg8 <= x_next_comb7;
        mant_norm_reg8 <= mant_norm_reg7;
        exp_out_reg8 <= exp_out_reg7;
        valid_reg8 <= valid_reg7;
        done_reg8 <= done_reg7 | conv7;
        sign8 <= sign7;
    end
end

// ------------------------------------------------------------------
// Final combinational: normalization, remainder-based rounding, pack output (20-bit)
// ------------------------------------------------------------------
always @(*) begin
    // defaults
    dl_out_next = 20'd0;
    mant13 = 13'd0;
    exp_out_final = 6'd0;
    remainder12 = 12'd0;
    mant13 = 13'd0;
    x_nonpipe = 13'd0;

    if (valid_reg8) begin
        // prefer the registered pipeline signals that relate to this result
        exp_out_final = exp_out_reg8;

        // Negative input => invalid (NaN-like)
        if (sign8) begin
            exp_out_final = 6'b111111;
            mant13 = 13'b1000000000000; // top pattern for NaN-like (13-bit)
        end else begin
            x_nonpipe = x_reg8; // keep lower widths
            mant13 = {x_reg8} << 9;
            remainder12[12:0] = (mant_norm_reg8 - x_nonpipe * x_nonpipe);

            // rounding: if remainder >= 2 * x_nonpipe then increment mantissa
//            if (remainder12 >= 2 * (x_nonpipe)) begin
//                mant13 = mant13 + 1'b1;
//            end
            end


            if (exp_out_final > 6'b111110) begin
                dl_tmp = {1'b0, 6'b111110, 13'b1111111111111}; // saturated-like pattern
            end else if ((exp_out_final == 6'd0) && (mant13 == 13'd0)) begin
                dl_tmp = 20'd0;
            end else begin
                // normal packing: sign=0 (sqrt non-negative), exp_out_final, mant13 (13 bits)
                dl_tmp = {1'b0, exp_out_final, mant13};
            end
            dl_out_next = dl_tmp;
            $display("dl_tmp1 = %h", dl_tmp);
end
end
// ------------------------------------------------------------------
// Output registers
// ------------------------------------------------------------------
always @(posedge clk) begin
    if (!rst_n) begin
        dl_out20 <= 20'd0;
    end else begin
        dl_out20 <= dl_out_next;
    end
end

endmodule


module int32_to_dlfloat16_pipeline(
    input  wire        clk,
    input  wire        rst_n,
    input  wire signed [31:0] in_int,
    input  wire [3:0]  ena,
    output reg  [19:0] float_out_1
);

// Pipeline stage registers
reg        valid_reg0, valid_reg1, valid_reg2, valid_reg3;
reg [31:0] abs_input_comb, abs_input_reg1, abs_input_reg2;
reg        sign_reg0, sign_reg1, sign_reg2, sign_reg3;

// Stage 1 registers (normalization)
reg [5:0]  leading_bit_pos_reg1;
reg [5:0]  exponent_reg1, exponent_reg2, exponent_reg3;
reg [8:0]  mantissa_reg2, mantissa_reg3;

// Combinational logic for each stage
reg [31:0] abs_input_comb;
reg [5:0]  leading_bit_pos_comb;
reg [5:0]  exponent_comb;
reg [8:0]  mantissa_comb;
reg [15:0] float_out_comb;

// ------------------------------------------------------------------
// Stage 0: Input Processing (Combinational)
// ------------------------------------------------------------------
always @(*) begin
    // Input validation and absolute value calculation
    abs_input_comb = (in_int < 0) ? -in_int : in_int;
    valid_reg0        = (ena == 4'b0111);
    sign_reg0         = (in_int < 0) ? 1'b1 : 1'b0;
end

// ------------------------------------------------------------------
// Stage 1: Find Leading Bit (Combinational)
// ------------------------------------------------------------------
always @(*) begin
    leading_bit_pos_comb = 6'd0;
    
    // Priority encoder to find leading bit position
    if (valid_reg0 && abs_input_comb != 0) begin
        if      (abs_input_comb[31]) leading_bit_pos_comb = 6'd31;
        else if (abs_input_comb[30]) leading_bit_pos_comb = 6'd30;
        else if (abs_input_comb[29]) leading_bit_pos_comb = 6'd29;
        else if (abs_input_comb[28]) leading_bit_pos_comb = 6'd28;
        else if (abs_input_comb[27]) leading_bit_pos_comb = 6'd27;
        else if (abs_input_comb[26]) leading_bit_pos_comb = 6'd26;
        else if (abs_input_comb[25]) leading_bit_pos_comb = 6'd25;
        else if (abs_input_comb[24]) leading_bit_pos_comb = 6'd24;
        else if (abs_input_comb[23]) leading_bit_pos_comb = 6'd23;
        else if (abs_input_comb[22]) leading_bit_pos_comb = 6'd22;
        else if (abs_input_comb[21]) leading_bit_pos_comb = 6'd21;
        else if (abs_input_comb[20]) leading_bit_pos_comb = 6'd20;
        else if (abs_input_comb[19]) leading_bit_pos_comb = 6'd19;
        else if (abs_input_comb[18]) leading_bit_pos_comb = 6'd18;
        else if (abs_input_comb[17]) leading_bit_pos_comb = 6'd17;
        else if (abs_input_comb[16]) leading_bit_pos_comb = 6'd16;
        else if (abs_input_comb[15]) leading_bit_pos_comb = 6'd15;
        else if (abs_input_comb[14]) leading_bit_pos_comb = 6'd14;
        else if (abs_input_comb[13]) leading_bit_pos_comb = 6'd13;
        else if (abs_input_comb[12]) leading_bit_pos_comb = 6'd12;
        else if (abs_input_comb[11]) leading_bit_pos_comb = 6'd11;
        else if (abs_input_comb[10]) leading_bit_pos_comb = 6'd10;
        else if (abs_input_comb[9])  leading_bit_pos_comb = 6'd9;
        else if (abs_input_comb[8])  leading_bit_pos_comb = 6'd8;
        else if (abs_input_comb[7])  leading_bit_pos_comb = 6'd7;
        else if (abs_input_comb[6])  leading_bit_pos_comb = 6'd6;
        else if (abs_input_comb[5])  leading_bit_pos_comb = 6'd5;
        else if (abs_input_comb[4])  leading_bit_pos_comb = 6'd4;
        else if (abs_input_comb[3])  leading_bit_pos_comb = 6'd3;
        else if (abs_input_comb[2])  leading_bit_pos_comb = 6'd2;
        else if (abs_input_comb[1])  leading_bit_pos_comb = 6'd1;
        else if (abs_input_comb[0])  leading_bit_pos_comb = 6'd0;
    end
end

// ------------------------------------------------------------------
// Stage 1 Register
// ------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_reg1           <= 1'b0;
        abs_input_reg1       <= 32'b0;
        sign_reg1            <= 1'b0;
        leading_bit_pos_reg1 <= 6'b0;
        exponent_reg1        <= 6'b0;
    end else begin
        valid_reg1           <= valid_reg0;
        abs_input_reg1       <= abs_input_comb;
        sign_reg1            <= sign_reg0;
        leading_bit_pos_reg1 <= leading_bit_pos_comb;
        exponent_reg1        <= leading_bit_pos_comb + 6'd31; // Bias the exponent
    end
end

// ------------------------------------------------------------------
// Stage 2: Mantissa Extraction (Combinational)
// ------------------------------------------------------------------
always @(*) begin
    mantissa_comb = 9'b0;
    
    if (valid_reg1 && abs_input_reg1 != 0) begin
        if (leading_bit_pos_reg1 <= 9) begin
            // Left shift for small numbers
            mantissa_comb = abs_input_reg1 << (9 - leading_bit_pos_reg1);
        end else begin
            // Right shift for large numbers
            mantissa_comb = abs_input_reg1 >> (leading_bit_pos_reg1 - 9);
        end
    end
    float_out_comb = 16'b0;
    
    if (valid_reg1) begin
        if (abs_input_reg1 == 32'b0) begin
            float_out_comb = 16'b0;
        end else begin
            float_out_comb = {sign_reg1, exponent_reg1, mantissa_comb};
        end
    end
end


// ------------------------------------------------------------------
// Output Assignment
// ------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        float_out_1   <= 20'b0;
    end else begin
        float_out_1   <= {float_out_comb, 4'b0000};
    end
end
endmodule
