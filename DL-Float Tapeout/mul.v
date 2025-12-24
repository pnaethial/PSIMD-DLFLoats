module dlfloat16_mul(a,b,c_mul);
  input  [15:0]a,b;
  output  reg[15:0]c_mul;
    
    reg [9:0]ma,mb; //1 extra because 1.smthng
    reg [8:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
    reg [15:0] c_mul1;
	
  always@(*) begin
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
 	c_mul= c_mul1;
    end 
	wire _unused = &{m_temp[8:0], 9'b0};
endmodule 
