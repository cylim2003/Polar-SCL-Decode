`timescale 1ns / 1ps

module Block_Ram# (
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 1
)(
    input  wire clk,
    input  wire wea,                     
    input  wire [ADDR_WIDTH-1:0] addra,  
    input  wire [DATA_WIDTH-1:0] dina,   
    output reg  [DATA_WIDTH-1:0] douta,  
    input  wire web,                     
    input  wire [ADDR_WIDTH-1:0] addrb,  
    input  wire [DATA_WIDTH-1:0] dinb,   
    output reg  [DATA_WIDTH-1:0] doutb   
);

reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
integer i;

initial begin
    for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1)
        mem[i] = 0;
end

always @(posedge clk) begin
    if (wea) begin
        mem[addra] <= dina;
    end
    douta <= mem[addra]; 
end

always @(posedge clk) begin
    if (web) begin
        mem[addrb] <= dinb;
    end
    doutb <= mem[addrb]; 
end
endmodule
