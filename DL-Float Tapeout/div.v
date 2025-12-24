module dlfloat16_div( 
    input wire [15:0] a, b,
    output reg [15:0] c_div_1
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
        c_div_1=16'b0;

        e_temp = 6'b0;
        m_temp = 16'b0;
        mant = 13'b0;
        exp = 6'b0;
        s = 0;
        c_div = 20'b0; 
        begin
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
        c_div_1 = c_div[19:4];
    end
    
endmodule
