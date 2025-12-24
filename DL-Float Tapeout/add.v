module dlfloat16_add(
   	 input wire [15:0] a,
   	 input wire [15:0] b,
   	 output reg [15:0] c_add_1
   	 );
   	 
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
     	     e1_80 = a[14:9];
    	     e2_80 = b[14:9];
             m1_80 = a[8:0];
     	     m2_80 = b[8:0];
             s1_80 = a[15];
             c_add_1 = 16'b0;
             begin
           s2_80 = b[15];        
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
               if( a==16'hFFFF | b==16'hFFFF) begin  
                 c_add = 16'hFFFF;
               end
               else begin
                 c_add = (a==0 & b==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
               end 
           end
	    end
        c_add_1 = c_add[19:4];
  end 
endmodule
