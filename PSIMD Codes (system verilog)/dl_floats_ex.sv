module dl_floats_ex(
   input logic [3:0] ena,
   input logic [2:0] rm,
   input logic [2:0] sel2, // for cmpr
   input logic op,
   input logic [1:0] sel1,
   input logic [15:0] op1, op2, op3,
   input logic [31:0] in_int,
   output logic invalid, inexact, overflow, underflow, div_by_zero,
   output logic [15:0] result,
   output logic [31:0] out_1
);

   logic [15:0] src1, src2, src3;
   assign src1 = op1;
   assign src2 = op2;
   assign src3 = op3;

   logic [19:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt, out_sign, out_i2f, out_comp;
   logic [31:0] out_f2i;
   logic [19:0] out_muxed_logic;
   logic [31:0] out_1_logic;
   logic [15:0] result_logic;

   // Exception logics
   logic [4:0] exceptions1, exceptions2, exceptions3, exceptions4, exceptions5;
   logic [4:0] exceptions6, exceptions7, exceptions8, exceptions9, out_excep;
   logic invalid_logic, inexact_logic, overflow_logic, underflow_logic, div_by_zero_logic;

   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_add_sub add_sub(.a(src1), .b(src2), .ena(ena), .op(op), .exceptions2(exceptions2), .c_add(out_add_sub));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_mul mul(.a(src1), .b(src2), .ena(ena), .c_mul(out_mul), .exceptions1(exceptions1));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_div div(.a(src1), .b(src2), .ena(ena), .c_div(out_div), .exceptions3(exceptions3));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_sqrt sqrt(.dl_in(src1), .ena(ena), .dl_out_fin(out_sqrt), .exceptions4(exceptions4));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_mac mac(.a(src1), .b(src2), .d(src3), .c_add(out_mac), .ena(ena), .op(op), .exceptions7(exceptions7));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_sign_inv sign_inv(.in1(src1), .in2(src2), .ena(ena), .sel(sel1), .out(out_sign), .exceptions5(exceptions5));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)int32_to_dlfloat16 i2f(.in_int(in_int), .ena(ena), .float_out1(out_i2f), .exceptions8(exceptions8));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_to_int32 f2i(.float_in(src1), .ena(ena), .int_out_fin(out_f2i), .exceptions9(exceptions9));
   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_comp comp(.a1(src1), .b1(src2), .ena(ena), .sel(sel2), .c_out(out_comp), .exceptions6(exceptions6));

   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)excep_mux e_mux(
      .ena(ena),
      .exceptions1(exceptions1), .exceptions2(exceptions2), .exceptions3(exceptions3),
      .exceptions4(exceptions4), .exceptions5(exceptions5), .exceptions6(exceptions6),
      .exceptions7(exceptions7), .exceptions8(exceptions8), .exceptions9(exceptions9),
      .out_excep(out_excep)
   );

   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)out_mux outmux(
      .ena(ena),
      .out_add_sub(out_add_sub), .out_mul(out_mul), .out_div(out_div),
      .out_mac(out_mac), .out_sqrt(out_sqrt), .out_sign(out_sign),
      .out_i2f(out_i2f), .out_comp(out_comp), .out_f2i(out_f2i),
      .out_muxed(out_muxed_logic), .out_1(out_1_logic)
   );

   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dl_exception excep(
      .out_excep(out_excep),
      .invalid(invalid_logic), .inexact(inexact_logic),
      .overflow(overflow_logic), .underflow(underflow_logic), .div_zero(div_by_zero_logic)
   );

   (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)dlfloat16_round round(
      .rm(rm), .ena(ena), .in(out_muxed_logic), .out(result_logic)
   );

   always @(*) begin
      result = result_logic;
      out_1 = out_1_logic;
      invalid = invalid_logic;
      inexact = inexact_logic;
      overflow = overflow_logic;
      underflow = underflow_logic;
      div_by_zero = div_by_zero_logic;
   end

endmodule



module out_mux(
     input logic [3:0] ena, 
     input logic [19:0] out_add_sub, out_mul, out_div, out_mac, out_sqrt,out_sign, out_i2f, out_comp,
     input logic [31:0] out_f2i, 
     output logic [19:0] out_muxed, 
     output logic [31:0] out_1);

  always@(*)
    begin
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


module excep_mux(
     input logic [3:0] ena, 
     input logic [4:0] exceptions1,exceptions2, exceptions3,exceptions4 ,exceptions5,exceptions6,exceptions7,exceptions8,exceptions9, 
     output logic [4:0] out_excep);

  always@(*)
    begin
      case(ena)
        4'b0001: out_excep = exceptions2;
        4'b0010: out_excep = exceptions1;
        4'b0011: out_excep = exceptions3;
        4'b0100: out_excep = exceptions4;
        4'b0101: out_excep = exceptions5;
        4'b0110: out_excep = exceptions6;
        4'b1001: out_excep = exceptions7;
        4'b0111: out_excep = exceptions8;
        4'b1000: out_excep = exceptions9;
        default: out_excep = 5'b0;
      endcase
      end
   
endmodule

module int32_to_dlfloat16(
   input logic signed [31:0] in_int,
   input logic[3:0] ena,
   output logic [4:0] exceptions8,
   output logic [19:0] float_out1  
);
    logic [5:0] exponent;   
    logic [8:0] mantissa;    
    logic sign;             
    logic [31:0] abs_input;
    logic [15:0] float_out;
    integer i;

          

       
    always @(*) begin
        if(in_int>512) begin
            exceptions8 = 5'b01000;
        end else begin
            exceptions8 =5'b00000;
        end
        
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
      float_out1 = {float_out,4'b0000};
    end
    
endmodule

module dlfloat16_to_int32(
   input logic [3:0] ena,
   output logic [4:0] exceptions9,
   input logic[15:0] float_in,
   output logic signed [31:0] int_out_fin
);
  logic sign;
  logic [5:0] exponent;
  logic [9:0] mantissa; 
  logic signed [5:0] actual_exponent;
  logic signed [31:0] result;

  always @(*) begin
    exceptions9 = 5'b0;
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
  end
endmodule

module dlfloat16_sqrt (
	input logic [3:0] ena,
    input  logic [15:0] dl_in,              
	output logic [19:0] dl_out_fin,         
    output logic [4:0] exceptions4  
);
    logic sign = dl_in[15];                
    logic [5:0] exp_in = dl_in[14:9] ;     
    logic [8:0] mant_in = dl_in[8:0];      

  
    logic [12:0] x, x_next=0;  // Current and next estimates for the square root of mantissa
    logic [12:0] diff;      
    logic done;              //convergence flag
    logic [12:0] remainder; 
   
    logic [9:0] mant_norm;
   
    logic [5:0] exp_out;      
    logic [12:0] mant_sqrt;    
    integer i;
    logic [5:0] ier;
	logic [19:0] dl_out;
    logic invalid, overflow, underflow, inexact;
    logic div_by_zero = 1'b0;

	 
    always @(*) begin
        mant_norm = (exp_in == 0) ? {1'b0, mant_in} : {1'b1, mant_in};
        invalid = 0;
        overflow = 0;
        underflow = 0;
        inexact = 0;
		ier = 6'b0;
        mant_sqrt = 13'b0;
        done = 0;  
        
	    if (ena!=4'b0100) 
		    dl_out = 20'b0; 
	    else begin
	    
        //special cases
        if (dl_in == 16'h0000) begin
            // Zero input
            dl_out = 20'h00000;  // Output is zero
        end
        else if (sign == 1'b1) begin
            // Negative input
            dl_out = 20'hFFFFF;  // NaN representation
            invalid = 1'b1;
        end
        else begin

          if (exp_in == 6'b0) begin//Denormalized input
                exp_out = 6'b0;  
            end
             else begin
              if(exp_in[0] ==1'b1)
                begin
                  ier = (exp_in+1);
                  mant_norm = mant_norm >>1;
                 
                end
              else
                ier = exp_in;
            end
			exp_out = (ier +31)>>1; // Add bias
            x = mant_norm;
            
          if (mant_norm == 0) begin
        mant_sqrt = 0;
          end else if (mant_norm == 1) begin
        mant_sqrt = 1;end
        else begin
         for (i = 0; i < 8 && !done; i = i + 1) begin
           x_next = (x + ((mant_norm) / x)) >> 1; // New estimate= average of x and num/x
            diff = (x > x_next) ? (x - x_next) : (x_next - x); 

            if (diff <= 1) begin
                done = 1; 
            end
        
            x = x_next; 
        end
        

           mant_sqrt = x<<9;
          
            remainder = mant_norm - (x * x); //remainder calculated for better approximation
            
            if (remainder >= (2 * x )) begin // round up if remainder is large
            mant_sqrt = mant_sqrt + 1;
        end
            
            // Check for inexact result
            if (mant_sqrt * mant_sqrt != (mant_norm << 3)) begin
                inexact = 1'b1;
            end

            // Check for overflow and underflow
            if (exp_out > 6'b111110) begin
                overflow = 1'b1;
                dl_out = 20'h7DFE0;  
            end else if (exp_out == 6'b0 && mant_sqrt == 13'b0) begin
                underflow = 1'b1;
                dl_out = 20'h00000;  
            end else begin
            
               dl_out = {1'b0, exp_out, mant_sqrt};
           
            end
            dl_out_fin = dl_out;
		exceptions4 = {invalid, inexact, overflow, underflow, div_by_zero};
        end
	end
	end
	end
endmodule


module dlfloat16_sign_inv (
   input logic [15:0] in1, 
   input logic [15:0] in2,  
   input logic[1:0] sel,
   output logic [19:0] out,
   output logic [4:0] exceptions5,
   input logic [3:0] ena
);
 logic [19:0] out_comb;
 logic [14:0] not_used;
 
  assign not_used = in1[14:0];
		
  always @(*) begin
    
	exceptions5 = 5'b0;    
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
  end


endmodule


module dlfloat16_round ( 
      input [19:0] in, 
      input [3:0] ena,
      input [2:0] rm,
      output logic [15:0] out);
  
  logic G_bit,R_bit, S1_bit , S2_bit, S_bit;
  logic [15:0]out1;
  logic sign;
  logic [5:0] exp;
  logic [9:0] mant1;
  logic [8:0] mant;
  logic [2:0] rm1;
  logic [19:0] in1;

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
        3'b000: begin
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
        3'b001: begin 
          mant = mant1[8:0];//truncate GRS bits and leave it 
        end  
        
       //ROUND UP  
        3'b010: begin
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
        3'b011: begin
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
      if(ena !=4'b1000) begin
      out = out1; 
      end
      else begin
        out = in;
      end 
    end
  
endmodule  
      
    
// Code your design here
module dlfloat16_mul(a,b,ena,c_mul,exceptions1);
  input logic [15:0]a,b;
  input logic [3:0] ena;
  output  logic [19:0] c_mul;
  output logic [4:0] exceptions1;
    
    logic [9:0]ma,mb; //1 extra because 1.smthng
    logic [12:0] mant;
    logic [19:0]m_temp; //after multiplication
    logic [5:0] ea,eb,e_temp,exp;
    logic sa,sb,s;
	logic invalid, inexact, overflow, underflow, div_zero;


		 	
  always@(*) begin
  //  exceptions = {invalid, inexact, overflow, underflow, div_zero}; 
    invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
	    exceptions1=5'b00000;
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
		  c_mul =20'b0;
	  else begin

		  
  	//checking for underflow/overflow
    if (  (ea + eb) <= 31 ) begin
      underflow = 1'b1;
  		c_mul=16'b0;//pushing to zero on underflow
  	end
    else if ( (ea + eb) > 94) begin
      overflow = 1'b1;
      if( (sa ^ sb) ) begin
          c_mul=16'hFDFE;//pushing to largest -ve number on overflow
        end
      else begin
          c_mul=16'h7DFE;//pushing to largest +ve number on overflow
      end
    end
        
  	else if ( (ea + eb) == 94 ) begin
      invalid = 1'b1;
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
	  if(c_mul[19:15] != 4'b0000)
      inexact = 1'b1;
    end 
    exceptions1 = {invalid, inexact, overflow, underflow, div_zero}; 
//    $display("exceptions in mul =%b",exceptions1);
  end
	logic _unused = &{m_temp[8:0], 9'b0};
	
endmodule 


// Code your design here
module dlfloat16_mac(a,b,d,c_add,ena,op,exceptions7);
	input logic op; 
	input logic [3:0] ena;
    input logic [15:0]a,b,d;
	output logic [19:0] c_add;
	logic [19:0] c_add_logic;
    output logic [4:0] exceptions7;
    logic [4:0] exceptions7_logic;
    logic [15:0] c_mul1;
    logic [19:0] c_mac;
    logic [4:0] excep;
    logic oper =op;
 
 	fpmac_mult mul(.a(a),.b(b),.c_mul1(c_mul1),.ena(ena));
	fpmac_adder add(.a1(c_mul1),.b1(d),.c_add(c_add_logic),.oper(oper),.exceptions7(exceptions7_logic));

    always @(*) begin
        c_add = c_add_logic;
        exceptions7 = exceptions7_logic;
    end

endmodule
  
module fpmac_mult(a,b,c_mul1,ena);
    input logic [15:0]a,b;
    output  logic [15:0] c_mul1;
	input logic [3:0] ena;  
    logic [9:0]ma,mb; //1 extra because 1.smthng
    logic [8:0] mant;
    logic [19:0]m_temp; //after multiplication
    logic [5:0] ea,eb,e_temp,exp;
    logic sa,sb,s;
  	
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
    end 
	logic _unused = &{m_temp[8:0], 9'b0};
endmodule 
 
module fpmac_adder(a1,b1,c_add,oper,exceptions7);
   
   	 input logic [15:0] a1;
   	 input logic [15:0] b1;
   	 output logic [19:0] c_add;
   	 input logic oper;
   	output logic [4:0] exceptions7;
    logic    [5:0] Num_shift_80; 
    logic    [5:0]  Larger_exp_80,Final_expo_80;
    logic    [9:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80;
    logic    [12:0] Final_mant_80;
    logic    [10:0] Add_mant_80,Add1_mant_80;
    logic    [5:0]  e1_80,e2_80;
    logic    [8:0] m1_80,m2_80;
    logic          s1_80,s2_80,Final_sign_80;
    logic    [8:0]  renorm_shift_80;
    logic signed [5:0] renorm_exp_80;
    logic signed [5:0] larger_expo_neg;
    logic invalid, inexact, overflow, underflow, div_zero;
    
    always@(*) begin

	    invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
        //stage 1
     	     e1_80 = a1[14:9];
    	     e2_80 = b1[14:9];
             m1_80 = a1[8:0];
     	     m2_80 = b1[8:0];
             s1_80 = a1[15];
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
	        Final_mant_80=Final_mant_80<<2;
               //checking for special cases
               if( a1==16'hFFFF | b1==16'hFFFF) begin  
                 c_add = 16'hFFFF;
               end
               else begin
                 c_add = (a1==0 & b1==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
               end 
           end//for overflow/underflow 
	    if (c_add[19:15] != 4'b0000)
		    inexact = 1'b1;
	    end
	    exceptions7= {invalid, inexact, overflow, underflow, div_zero};

  end //for always block 
endmodule



module dlfloat16_div(
    input logic [3:0] ena,
    input logic [15:0] a, b,
    output logic [19:0] c_div,         // 1-bit sign, 6-bit exponent, 13-bit mantissa
    output logic [4:0] exceptions3
);
    logic [9:0] ma, mb;       
    logic [12:0] mant;        
    logic [23:0] m_temp;     
    logic [5:0] ea, eb, e_temp, exp;
    logic sa, sb, s;     
    logic div_by_zero, underflow, overflow, inexact, invalid;

            

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
        div_by_zero = 1'b0;
        underflow = 1'b0;
        overflow = 1'b0;
        inexact = 1'b0;
        invalid = 1'b0;
        if(ena != 4'b0011)
            c_div = 20'b0;
        else begin
        // Special Cases
      if(( b == 16'b0 || b==16'b1000000000000000) &&(a==16'b0 || a==16'b1000000000000000))
            begin
              c_div = {sa ^sb,15'b111111111111111,4'b0};
              invalid = 1'b1;
            end
      
       else if (b == 16'b0 || b == 16'b1000000000000000) begin
            
            div_by_zero = 1'b1;
            c_div = {sa ^ sb, 6'b111111, 13'b0};
        end else if (a == 16'hfe00 || a == 16'h7e00) begin
            
          if (b == 16'hFe00 || b == 16'h7e00) begin
                
                invalid = 1'b1;
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
                inexact = 1'b1;
            end

            // Check for underflow/overflow
            if (exp < 0) begin
                underflow = 1'b1;
                c_div = 20'b0; 
            end else if (exp > 63) begin
                overflow = 1'b1;
                c_div = s ? 20'hFDFE0 : 20'h7DFE0; 
            end else begin
                c_div = {s, exp, mant};
            end
            end
        exceptions3 = {invalid, inexact, overflow, underflow, div_by_zero};
        
        end
    end
endmodule


       
          

module dlfloat16_comp (
   input logic [15:0] a1,
   input logic [15:0] b1,
   input logic [2:0] sel,
   input logic [3:0] ena,
   output logic [4:0] exceptions6,
   output logic [19:0] c_out
);
  logic s1, s2;
  logic [5:0] exp1, exp2;
  logic [8:0] mant1, mant2;
  logic lt, gt, eq;
  logic [19:0] c_1;
  logic invalid, inexact, overflow, underflow, div_zero;

  always @(*) begin

     invalid =1'b0;
	    inexact = 1'b0;
	    overflow = 1'b0;
	    underflow = 1'b0;
	    div_zero = 1'b0;
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

    if (c_1 == 20'h00000)
      underflow =1'b1;
    if(c_1 == 20'hffff0)
      overflow = 1'b1;
  end
      c_out = {c_1};
	exceptions6 = {invalid, inexact, overflow, underflow, div_zero};
  end


endmodule


module dlfloat16_add_sub(
     input logic [15:0] a,
     input logic [15:0] b,
     input logic op,
     input logic [3:0] ena, 
     output logic [19:0] c_add, 
     output logic [4:0] exceptions2
    );

    logic    [5:0] Num_shift_80; 
    logic    [5:0]  Larger_exp_80,Final_expo_80;
    logic    [9:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80;
    logic    [12:0] Final_mant_80;
    logic    [10:0] Add_mant_80,Add1_mant_80;
    logic    [5:0]  e1_80,e2_80;
    logic    [8:0] m1_80,m2_80;
    logic          s1_80,s2_80,Final_sign_80;
    logic    [8:0]  renorm_shift_80;
    logic signed [5:0] renorm_exp_80;
    logic signed [5:0] larger_expo_neg;
    logic invalid, inexact, overflow, underflow, div_zero;


		

    always@(*) begin
		exceptions2 = {invalid, inexact, overflow, underflow, div_zero};
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
	        Final_mant_80=Final_mant_80<<2;
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
   input logic [4:0] out_excep,
   output logic invalid, inexact, overflow, underflow, div_zero);
  
  always@(*)
  begin
    div_zero = out_excep[0];
    underflow =  out_excep[1];
    overflow =  out_excep[2];
    inexact =  out_excep[3]; 
    invalid =  out_excep[4];
  end
endmodule