module decoder(
  input logic [31:0] instr,
  output logic [3:0] ena,
  output logic [2:0] rm,
  output logic [2:0] sel2,
  output logic op,
  output logic [1:0] sel1,
  output logic [4:0] rs1,
  output logic [4:0] rs2,
  output logic [4:0] rs3,
  output logic [4:0] rd,
  output logic wr_enable,logic_fti_ctrl,
  output logic sp
  );
  
  logic [4:0] fun5;
  logic [6:0] opcode;
  logic [1:0] fmt;
  
  assign opcode = instr[6:0]; 
  assign fun5 = instr[31:27];
  assign fmt = instr[26:25];
  
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
            8'b01001000:begin ena = 4'b0111; //int to float
            end
            8'b01000000:begin ena = 4'b1000;  // float to int
            end
            8'b10100010: begin ena = 4'b0110;//eq
              sel2 = 3'b011; 
            end
            8'b10100001: begin ena = 4'b0110;// less than
            sel2 = 3'b100;
            end
            8'b10100000: begin ena = 4'b0110;//less than eq
              sel2 = 3'b101; 
            end
            default : begin ena = 4'b0000;
                sel2 = 3'b000;
                sel1 = 2'b00;
            end
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
    
    always@(*) begin
         if (opcode == 7'b1011011) begin
            rs1 = instr[19:15];
            rd = instr [11:7];
            if (fun5 != 5'b01011 || 5'b01000 || 5'b01001 ) begin
                rs2 = instr[24:20];
            end
            else  begin
                rs2 = 5'b00000;
            end
        end
        
        
        if (opcode == 7'b0011011) begin
            rs1 = instr[19:15];
            rd = instr [11:7];
            if (fun5 != 5'b01011 || 5'b01000 || 5'b01001 ) begin
                rs2 = instr[24:20];
            end
            else  begin
                rs2 = 5'b000000;
            end
        end
        
        if (opcode == 7'b0111011) begin
            rs1 = instr[19:15];
            rd = instr [11:7];
            if (fun5 != 5'b01011 || 5'b01000 || 5'b01001) begin
                rs2 = instr[24:20];
            end
            else  begin
                rs2 = 5'b00000;
            end
        end

        if (opcode == 7'b0011011 || 7'b0111011 ) begin
            rs3 = instr[31:27];
        end else begin
            rs3 =5'b00000;
        end

         
         if (opcode != 7'b0101011) begin
            wr_enable = 1'b1;
         end
        
        if (opcode == 7'b0101011) begin
            sp = 1'b0;
        end else begin
            sp = 1'b1;
        end
        
        if(fun5 == 5'b01000 ) begin
            logic_fti_ctrl = 1'b0;
        end else begin  
            logic_fti_ctrl = 1'b1;
        end
    end


endmodule