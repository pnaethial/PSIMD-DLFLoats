module Cfu (
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

    reg [2:0] rm;
    reg [3:0] ena;
    reg [4:0] funct5;
    reg [1:0] funct2;
    reg [2:0] sel2;
    reg [1:0] sel1;
    reg op,sp;
    wire [31:0] result;
    wire [31:0] rs1,rs2;
    wire [1:0] invalid,inexact,overflow,underflow,div_by_zero;
   
    assign cmd_ready = ~rsp_valid;
    assign rs1 = cmd_payload_inputs_0;
    assign rs2 = cmd_payload_inputs_1;

    always@(*) begin
        rm = cmd_payload_function_id[2:0];
        funct2 = cmd_payload_function_id[4:3];
        funct5 = cmd_payload_function_id[9:5];
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
//            5'b01011:begin ena = 4'b0100; //sqrt
//            end
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
       
        if(funct5 == 5'b01000) begin
            sp = 1'b1;
        end else begin
            sp = 1'b0;
        end    
    end        
       
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
            rsp_payload_outputs_0 <= result;
        end
    end
               
   
   
    Execution_unit ex_unit(
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sp(sp),
    .sel1(sel1),
    .data1(rs1),
    .data2(rs2),
    .datai_0(rs1),
    .dataout(result)
    );
   
endmodule


module Execution_unit #(
    parameter REG_WIDTH = 32)(
     input wire [3:0] ena,
     input wire [2:0] rm,
     input wire [2:0] sel2,// for cmpr
     input wire op,sp,
     input wire [1:0] sel1,
     input wire [REG_WIDTH-1:0] data1,
     input wire [REG_WIDTH-1:0] data2,
     input wire [REG_WIDTH-1:0] datai_0,
     output reg [REG_WIDTH-1:0] dataout
    );
   
    wire [15:0] data_0, data_1;
    wire [15:0] data1_0, data1_1;
    wire [15:0] data2_0, data2_1;
    wire [31:0] in_int_0,outi_0,outi_1;
    wire [31:0] data_out_1,data_in_1;
   
    wire [31:0] dataout_1,dataouti_0,dataout_wire;
    reg [31:0] out_1_wire;
   
   
    always@(*) begin
        dataout = dataout_wire;
        out_1_wire = outi_0 & outi_1;
    end
   
    dl_floats_execution_unit E0 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_0),
    .op2(data2_0),
    .op3(data2_0),
    .in_int(in_int_0),
    .result(data_0),
    .out_1(outi_0)
    );
   
    dl_floats_execution_unit E1 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_1),
    .op2(data2_1),
    .op3(data2_1),
    .in_int(in_int_0),
    .result(data_1),
    .out_1(outi_1)
    );

   
     splitter s1 (
    .data1(data1),
    .data2(data2),
    .datai_0(datai_0),
    .data_0(data_0),
    .data_1(data_1),
    .outi_0(out_1_wire),
    .dataout_1(dataout_1),
    .dataouti_0(dataouti_0),
    .data1_0(data1_0),
    .data1_1(data1_1),
    .data2_0(data2_0),
    .data2_1(data2_1),
    .in_int_0(in_int_0)
    );
   
   
    mux mux (
    .a(dataout_1),
    .b(dataouti_0),
    .s(sp),
    .c(dataout_wire)
    );
   
endmodule



module mux #(
    parameter REG_WIDTH = 32)(
    input wire [REG_WIDTH-1:0] a,
    input wire [REG_WIDTH-1:0] b,
    input wire s,
    output reg [REG_WIDTH-1:0] c
    );
     
    always@(*) begin
        if(s)
            c = b;
        else
            c = a;
    end
endmodule


module dl_floats_execution_unit(
   input wire [3:0] ena,
   input wire [2:0] rm,
   input wire [2:0] sel2, // for cmpr
   input wire op,
   input wire [1:0] sel1,
   input wire [15:0] op1, op2, op3,
   input wire [31:0] in_int,
   output reg [15:0] result,
   output reg [31:0] out_1
);

   wire [15:0] src1, src2, src3;
   assign src1 = op1;
   assign src2 = op2;
   assign src3 = op3;

   wire [19:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt, out_sign, out_i2f, out_comp;
   wire [31:0] out_f2i;
   wire [19:0] out_muxed_wire;
   wire [31:0] out_1_wire;
   wire [15:0] result_wire;

   dlfloat16_add_sub add_sub(
   .a(src1),
   .b(src2),
   .ena(ena),
   .op(op),
   .c_add_1(out_add_sub)
   );
   
   dlfloat16_mul mul(
   .a(src1),
   .b(src2),
   .ena(ena),
   .c_mul_1(out_mul)
   );
   
   dlfloat16_div div(
   .a(src1),
   .b(src2),
   .ena(ena),
   .c_div_1(out_div)
   );
   
//   dlfloat16_sqrt sqrt(
//   .dl_in(src1),
//   .ena(ena),
//   .dl_out_fin_1(out_sqrt)
//   );
   
   dlfloat16_mac mac(
   .a(src1),
   .b(src2),
   .d(src3),
   .c_add(out_mac),
   .ena(ena),
   .op(op)
   );
   
   dlfloat16_sign_inv sign_inv(
   .in1(src1),
   .in2(src2),
   .ena(ena),
   .sel(sel1),
   .out_1(out_sign)
   );
   
   int32_to_dlfloat16 i2f(
   .in_int(in_int),
   .ena(ena),
   .float_out_1(out_i2f)
   );
   
   dlfloat16_to_int32 f2i(
   .float_in(src1),
   .ena(ena),
   .int_out_fin_1(out_f2i)
   );
   
   dlfloat16_comp comp(
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
      //.out_sqrt(out_sqrt),
      .out_sign(out_sign),
      .out_i2f(out_i2f),
      .out_comp(out_comp),
      .out_f2i(out_f2i),
      .out_muxed(out_muxed_wire),
      .out_1(out_1_wire)
   );



   dlfloat16_round round(
      .rm(rm),
      .ena(ena),
      .in(out_muxed_wire),
      .out_1(result_wire)
   );

   always @(*) begin
      result = result_wire;
      out_1 = out_1_wire;
   end

endmodule



module out_mux(
     input wire [3:0] ena,
     input wire [19:0] out_add_sub, out_mul, out_div, out_sign, out_i2f, out_comp,
     input wire [19:0] out_mac,
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
//        4'b0100: out_muxed = out_sqrt;
        4'b0101: out_muxed = out_sign;
        4'b0110: out_muxed = out_comp;
        4'b1001: out_muxed = out_mac;
        4'b0111: out_muxed = out_i2f;
        default: out_muxed = 20'b0;
      endcase
      end
    end
endmodule




module int32_to_dlfloat16(
   input wire signed [31:0] in_int,
   input wire[3:0] ena,
   output reg [19:0] float_out_1  
);
    reg [5:0] exponent;  
    reg [8:0] mantissa;    
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
        if ( exponent <= 9) begin
          mantissa = abs_input << (9 - exponent);  // Left shift for +ve exp
           end else begin
             mantissa = abs_input >> (exponent - 9);// Right shift for -ve exp
           end

       
        //Bias the exponent
        exponent = exponent + 31;
     
      float_out = {sign,exponent,mantissa};
      end
      float_out_1 = {float_out,4'b0000};
    end
   
endmodule

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

module dlfloat16_sqrt (
input wire [3:0] ena,
   input  wire [15:0] dl_in,              
output reg [19:0] dl_out_fin_1
);
   reg sign;
   reg [5:0] exp_in;
   reg [8:0] mant_in;
   reg done;
   // Internal variables
   reg [12:0] x, x_next;
   reg [12:0] diff, mant_sqrt, remainder;
   reg [9:0] mant_norm;
   reg [5:0] exp_out, ier;

   // Output and exception flags
   reg [19:0] dl_out;

   // Control
   integer i;


   always@(*)  begin
       // Decode input
       sign = dl_in[15];
       exp_in = dl_in[14:9];
       mant_in = dl_in[8:0];
       mant_norm = 10'b0;
       dl_out_fin_1 = 20'b0;
       // Reset outputs
       x = 13'b0;
       x_next = 13'b0;
       diff = 13'b0;
       remainder = 13'b0;
       mant_sqrt = 13'b0;
       exp_out = 6'b0;
       ier = 6'b0;
       done = 1'b0;

       dl_out = 20'b0;

       if (ena != 4'b0100) begin
           dl_out = 20'b0;
       end else begin
           // Special cases
           if (dl_in == 16'h0000) begin
               dl_out = 20'h00000;  // Zero
           end else if (sign == 1'b1) begin
               dl_out = 20'hFFFFF;  // NaN for negative input;
           end else begin
               mant_norm = (exp_in == 0) ? {1'b0, mant_in} : {1'b1, mant_in};

               if (exp_in == 6'b0) begin
                   exp_out = 6'b0;
               end else begin
                   if (exp_in[0]) begin
                       ier = exp_in + 1;
                       mant_norm = mant_norm >> 1;
                   end else begin
                       ier = exp_in;
                   end
                   exp_out = (ier + 6'd31) >> 1; // Apply bias
               end

               // Newton-Raphson iteration (8 cycles max)
               x = mant_norm;
               for (i = 0; i < 8 && !done; i = i + 1) begin
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

               mant_sqrt = x << 9;
               remainder = mant_norm - (x * x);

               if (remainder >= (2 * x)) begin
                   mant_sqrt = mant_sqrt + 1;
               end

               

               if (exp_out > 6'b111110) begin
                   dl_out = 20'h7DFE0;
               end else if (exp_out == 6'b0 && mant_sqrt == 13'b0) begin
                   dl_out = 20'h00000;
               end else begin
                   dl_out = {1'b0, exp_out, mant_sqrt[12:4]}; // Use top 9 bits
               end
           end
       end
       dl_out_fin_1 = dl_out;
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
      output reg [15:0] out_1);
 
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



  always@(*) begin;
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
module dlfloat16_mac(a,b,d,c_add,ena,op);
input wire op;
input wire [3:0] ena;
    input wire [15:0]a,b,d;
output reg [19:0] c_add;
wire [19:0] c_add_wire;
    wire [15:0] c_mul1;
    reg [19:0] c_macc_add_1;
    wire [4:0] excep;
    wire oper =op;
 
  fpmac_mult mul(.a(a),.b(b),.c_mul(c_mul1),.ena(ena));
fpmac_adder add(.a1(c_mul1),.b1(d),.c_add_1(c_add_wire),.oper(oper));

    always @(*) begin
        c_add = c_add_wire;
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

        //stage 1
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
           end
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

           
          if (m_temp[3:0] != 4'b0) begin
            end

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
  reg [19:0] c_out;

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
      c_out = {c_1};
      c_out_1 = c_out;
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




module splitter #(
    parameter REG_WIDTH = 32)(
     input wire [REG_WIDTH-1:0] data1,
     input wire [REG_WIDTH-1:0] data2,
     input wire [REG_WIDTH-1:0] datai_0,
     input wire [15:0] data_0,
     input wire [15:0] data_1,
     input wire [31:0] outi_0,
     output reg [REG_WIDTH-1:0] dataout_1,
     output reg [REG_WIDTH-1:0] dataouti_0,
     output reg [15:0] data1_0,
     output reg [15:0] data1_1,
     output reg [15:0] data2_0,
     output reg [15:0] data2_1,
     output reg [31:0] in_int_0
    );
   
    always@(*) begin
            data1_0 = data1[15:0];
            data1_1 = data1[31:16];
            data2_0 = data2[15:0];
            data2_1 = data2[31:16];          
            dataout_1[15:0] = data_0;
            dataout_1[31:16] = data_1;            
            dataouti_0 [31:0] = outi_0;            
            in_int_0 = datai_0[31:0];
    end
endmodule
