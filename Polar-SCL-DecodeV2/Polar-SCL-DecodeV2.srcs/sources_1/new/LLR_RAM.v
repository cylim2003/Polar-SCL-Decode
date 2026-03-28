`timescale 1ns / 1ps

module LLR_RAM #(   
    localparam S_IDLE = 2'd0,
    localparam S_WRITE = 2'd1,
    localparam S_READ = 2'd2,
    parameter STAGE = 1
)(
    input wire sysclk,
    input wire sysres,
    input wire [1:0] CONTROL, // 0 = IDLE, 01 = WRITE, 10 = READ
    input wire [7:0] din,
    output wire [7:0] douta,
    output wire [7:0] doutb,
    output reg DONE
    );

reg wea;
reg web;
reg [STAGE+1:0] addra;
reg [STAGE+1:0] addrb;
reg [STAGE+1:0] nexta;
reg [STAGE+1:0] nextb;
reg leftright;
reg [10:0] COUNT;
always @(posedge sysclk or negedge sysres) begin
    if(sysres == 1'b0) begin
        wea <= 1'b0;
        web <= 1'b0;
        addra <= 4'b0;
        nexta <= 4'b0;
        addrb <= 1<<STAGE;
        nextb <= (1<<STAGE);
        leftright <= 1'b0;
        // COUNT <= (1<<STAGE)-1'b1;
        COUNT <= 1'b0;
        DONE <= 1'b0;
    end
    else begin  
        case (CONTROL)
            S_IDLE: begin
                wea <= 1'b0;
                web <= 1'b0;
                addra <= 4'b0;
                addrb <= 1<<STAGE;
                nexta <= 4'b0;
                nextb <= (1<<STAGE);
                leftright <= 1'b0;
                COUNT <= 1'b0;
                DONE <= 1'b0;
                // COUNT <= (1<<STAGE)-1'b1;
                end
            S_READ: begin
                if (COUNT < (1<<STAGE)) begin
                    wea <= 1'b0;
                    web <= 1'b0;
                    addra <= addra + 1'b1;
                    addrb <= addrb + 1'b1;
                    COUNT <= COUNT + 1'b1;
                end
                else begin
                    DONE <= 1'b1;
                end
            end
            S_WRITE: begin
                if (COUNT < 2*(1<<STAGE)) begin
                //     DONE <= 1'b1;
                // end
                // if (DONE == 1'b0) begin
                    if(COUNT < (1<<STAGE)) begin
                        wea <= 1'b1;
                        web <= 1'b0;
                        addra <= nexta;
                        nexta <= nexta +1'b1;
                    end
                    else begin
                        wea <= 1'b0;
                        web <= 1'b1;
                        addrb <= nextb;
                        nextb <= nextb +1'b1;
                        
                    end
                    COUNT <= COUNT +1'b1;
                end
                else begin
                    DONE <= 1'b1;
                    wea <= 1'b0;
                    web <= 1'b0;
                end

                // if (COUNT[10] == 1'b0) begin
                //     wea <= 1'b1;
                //     web <= 1'b0;
                //     addra <= nexta;
                //     nexta <= nexta +1'b1;
                // end
                // else begin
                //     wea <= 1'b0;
                //     web <= 1'b1;
                //     addrb <= nextb;
                //     nextb <= nextb +1'b1;
                // end
                // COUNT <= COUNT -1;
            end
            default: begin
                wea <= 1'b0;
                web <= 1'b0;
                addra <= 4'b0;
                addrb <= 4'd8;
                leftright <= 1'b0;
                DONE <= 1'b0;
                COUNT <= 1'b0;
            end
        endcase
    end
end
        

// RamStage0 RamStage0_inst (
//   .clka(sysclk),    // input wire clka
//   .wea(wea),      // input wire [0 : 0] wea
//   .addra(addra),  // input wire [3 : 0] addra
//   .dina(din),    // input wire [7 : 0] dina
//   .douta(douta),  // output wire [7 : 0] douta
//   .clkb(sysclk),    // input wire clkb
//   .web(web),      // input wire [0 : 0] web
//   .addrb(addrb),  // input wire [3 : 0] addrb
//   .dinb(din),    // input wire [7 : 0] dinb
//   .doutb(doutb)  // output wire [7 : 0] doutb
// );
Block_Ram # (
    .ADDR_WIDTH(STAGE+1),
    .DATA_WIDTH(8)
) RamStage0_inst(
    .clk(sysclk),
    .wea(wea),                     // 写使能
    .addra(addra),  // 地址
    .dina(din),   // 数据输入
    .douta(douta),   // 数据输出
    .web(web),                     // 写使能
    .addrb(addrb),  // 地址
    .dinb(din),   // 数据输入
    .doutb(doutb)  // 数据输出
);
endmodule
