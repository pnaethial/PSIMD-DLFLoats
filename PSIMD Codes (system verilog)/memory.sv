module memory(
    input logic [31:0] address,
    input logic [63:0] data_out_to_mem,
    input logic mem_read,mem_write,
    output logic [63:0] data_in_from_mem
    );
    
    logic [63:0] mem [255:0];
    
    always@(*) begin
        mem[0] = 64'h0000000000000000;
        mem[8] = 64'h3e003e003e003e00;
        mem[16] = 64'h4000400040004000;
        mem[24] = 64'h4100410041004100;
        mem[32] = 64'h4200420042004200;
        mem[40] = 64'h4280428042804280;
        mem[48] = 64'h4300430043004300;
        mem[56] = 64'h4380438043804380;
        mem[64] = 64'h4400440044004400;
        mem[72] = 64'h4440444044404440;
        mem[80] = 64'h4480448044804480;
        mem[88] = 64'h0000000000000000;
        mem[96] = 64'h3e003e003e003e00;
        mem[104] = 64'h4000400040004000;
        mem[112] = 64'h4100410041004100;
        mem[120] = 64'h4200420042004200;
        mem[128] = 64'h4280428042804280;
        mem[136] = 64'h4300430043004300;
        mem[144] = 64'h4380438043804380;
        mem[152] = 64'h4400440044004400;
        mem[180] = 64'h4440444044404440;
        mem[188] = 64'h4480448044804480;
       
        if(mem_read == 1'b1 ) begin
            data_in_from_mem = mem[address];
        end 
        else begin 
            data_in_from_mem = 64'h0000000000000000;
        end
        
        if(mem_write == 1'b1) begin
            mem[address] = data_out_to_mem;
        end
    
    end
    
endmodule
