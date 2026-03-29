`timescale 1ns / 1ps

module Partial_SumV3#(
    parameter N = 1024,
    parameter STAGES = 10
)
(
    input wire sysclk,
    input wire sysres,
    input wire [10:0] i,
    input wire [4:0] s,
    input wire U_input, //input U for writing
    input wire readEn,
    input wire writeEn,
    input wire COMPLETED,
    input wire [31:0] pathInputdouta,
    input wire [31:0] pathInputdoutb,
    output wire [31:0] pathOutputdouta,
    output wire [31:0] pathOutputdoutb,
    output reg isUpdating,
    output reg readComplete,
    output reg U_feedback
    );

genvar z;
generate
    for (z = 0; z < STAGES; z = z + 1) begin : Partial_Sum_RAM
            Block_Ram# (
                .ADDR_WIDTH(5),
                .DATA_WIDTH(32)
            )Partial_Sum_RAM_inst(
                .clk(sysclk),
                .wea(wea[z]),              // 写使能
                .addra(stageAddrA[z]),  // 地址
                .dina(dina[z]),             // 数据输入
                .douta(douta[z]),       // 数据输出
                .web(web[z]),              // 写使能
                .addrb(stageAddrB[z]),  // 地址
                .dinb(dinb[z]),             // 数据输入
                .doutb(doutb[z])        // 数据输出
            );
    end
endgenerate
// wire [31:0] debug_dina_to_ram = dina;
// reg [63:0] cur_dout;
reg [4:0] stageAddrA [STAGES-1:0]; //stage 9 -> 0 
reg [4:0] stageAddrB [STAGES-1:0];
reg [31:0] dina [STAGES-1:0];
reg [31:0] dinb [STAGES-1:0];
// reg [6:0] stageAddrA;
// reg [6:0] stageAddrB;
reg [STAGES-1:0] wea;
reg [STAGES-1:0] web;
// reg [31:0] dina;
// reg [31:0] dinb;
reg [31:0] tempU;
reg [STAGES:0] count;
reg [4:0] current_s;
reg [10:0] i_count;
reg [31:0] temp_douta; 
reg [31:0] temp_doutb; 
reg [31:0] temp_doutUp;
reg [31:0] ramPageCount;
reg [31:0] ramPageCountLow;
reg [31:0] ramPageCountHigh;
reg updateDelay;
reg DELAY1;
reg DELAY2;
reg DELAY3;

wire [STAGES:0] BASE;
wire [STAGES:0] readBASE;
wire[5:0] ramPage; // 32 ramPage total;
wire[5:0] readramPage;
wire [4:0] offset; // 0-31

wire [STAGES:0] updateBase; 
wire[5:0] updateRamPage;
wire [4:0] updateOffset; //0-31 
wire [5:0] updateRamPageOffset; //1-16 rampage total

wire [31:0] douta [STAGES-1:0];
wire [31:0] doutb [STAGES-1:0];

integer x;
integer l;
integer j;
assign BASE = (i>>(s+1)<<(s+1));
assign readBASE = (count>>(1)<<(1));
assign ramPage = BASE[STAGES:5];
assign readramPage = readBASE[STAGES:5];
assign offset = BASE[4:0]; // 0-16


assign updateBase = (i>>(current_s+1)<<(current_s+1));
assign updateOffset = updateBase[4:0];
assign updateRamPage = updateBase[STAGES:5];
assign updateRamPageOffset = (current_s >= 5) ? (1 << (current_s-5)) : 1;


always@(posedge sysclk or negedge sysres) begin
    if(sysres == 1'b0) begin
        count <= 1'b0;
        for(x=0;x< STAGES;x=x+1) begin
            stageAddrA[x] <= 6'b0;
            stageAddrB[x] <= 6'b0;
            dina[x] <= 1'b0;
            dinb[x] <= 1'b0;
        end
        // dina<= 31'd0;
        // dinb<= 31'd0;
        wea <= 1'b0;
        web <=1'b0;
        U_feedback <= 1'b0;
        temp_douta <= 1'b0;
        temp_doutb <= 1'b0;
        ramPageCount <= 1'b0;
        ramPageCountLow <= 1'b0;
        ramPageCountHigh <= 1'b0;
        temp_doutUp <= 1'b0;
        i_count <= 1'b0;
        isUpdating <= 1'b0;
        updateDelay <= 1'b0;
        DELAY1 <= 1'b0;
        tempU <= 1'b0;
        readComplete <= 1'b0;
    end

    
    else if (readEn == 1'b1) begin
        wea<= 1'b0;
        web<= 1'b0;
        DELAY3 <= DELAY2;
        DELAY2 <= DELAY1;
        DELAY1 <= 1'b1;
        if (count < ((1<<s))) begin
            stageAddrA[s] <= ramPage+ramPageCount;
            temp_douta <= douta[s];
            if (count[4:0] == 5'd28) begin
                ramPageCount <= ramPageCount + 1'b1;
            end
            if(DELAY3 == 1'b1) begin
                count <= count + 1'b1;
            end
            if(DELAY2 == 1'b1) begin
                U_feedback <= temp_douta[offset+count[4:0]];
            end
        end
        else begin
            ramPageCount<= 1'b0;
            count <= count;
            U_feedback<=1'b0;
            DELAY1 <= 1'b0;
        end
    end


    else if (writeEn == 1'b1) begin 
        count <= 1'b0;
        stageAddrA[0] <= ramPage;
        tempU[i[4:0]] <= U_input;
        wea <= 1'b0;
        web <= 1'b0;
        isUpdating <= 1'b1;
        updateDelay <= 1'b0;
        current_s <=  1'b0;
        ramPageCountLow <= 1'b0;
        ramPageCountHigh <= 1'b0;
        DELAY1 <= 1'b0;
        DELAY2 <= 1'b0;
        DELAY3 <= 1'b0;
    end
    else if (isUpdating == 1'b1 && writeEn == 1'b0) begin
        if (updateDelay == 1'b0) begin
            wea<= 1'b1;
            dina[0] <= tempU;
            DELAY1 <= 1'b1;
            if (DELAY1 == 1'b1) begin
                updateDelay <= 1'b1;
                DELAY1 <= 1'b0;
            end
        end
        else if (updateDelay == 1'b1 && i[current_s] == 1'b1) begin
            if (count < ((1<<current_s))) begin
                stageAddrA[current_s] <= updateRamPage +ramPageCountLow; //LowerRam Read
                stageAddrB[current_s] <= updateRamPage +updateRamPageOffset+ramPageCountLow;
                stageAddrA[current_s+1] <= updateRamPage +ramPageCountHigh;
                stageAddrB[current_s+1] <= updateRamPage +updateRamPageOffset+ramPageCountHigh;
                if (current_s >4) begin
                    ramPageCountLow <= ramPageCountLow + 1'b1; 
                end
                DELAY3 <= DELAY2;
                DELAY2 <= DELAY1;
                DELAY1 <= 1'b1;
                // if(DELAY1 == 1'b1 && DELAY2 == 1'b0) begin
                //     ramPageCountLow <= ramPageCountLow + 1'b1; 
                // end
                if(DELAY2 == 1'b1) begin
                    temp_douta <= douta[current_s];
                    temp_doutb <= doutb[current_s];
                    if(current_s<5) begin
                        dina[current_s+1] <= douta[current_s+1]; 
                    end
                    // ramPageCountLow <= ramPageCountLow + 1'b1; 
                end
                if(DELAY3 == 1'b1) begin    
                    if(current_s < 5) begin
                        wea <= (1'b1<<(current_s+1)); // check if 
                        web <= 1'b0;
                        for (j=0; j<16; j = j+1'b1) begin
                            if (j < (1 << current_s)) begin
                                dina[current_s+1][updateOffset + j] <= temp_douta[updateOffset+j] ^ temp_douta[updateOffset + j + (1<<current_s)];
                                dina[current_s+1][updateOffset + j + (1<<current_s)] <= temp_douta[updateOffset + j + (1<<current_s)];
                            end
                        end
                    end
                    else begin
                        wea<= (1'b1<<(current_s+1));
                        web<= (1'b1<<(current_s+1));
                        dina[current_s +1] <= temp_douta ^temp_doutb;
                        dinb[current_s +1] <= temp_doutb;
                        ramPageCountHigh <= ramPageCountHigh + 1'b1;
                    end
                    count <= count + 10'd32;
                end
            end
            else begin
                current_s <= current_s + 1'b1;
                count <= 1'b0;
                wea <= 1'b0;
                web <= 1'b0;
                DELAY1 <= 1'b0;
                DELAY2 <= 1'b0;
                DELAY3 <= 1'b0;
                ramPageCountLow<= 1'b0;
                ramPageCountHigh <= 1'b0;
                for(x=0;x< STAGES;x=x+1) begin
                    stageAddrA[x] <= 6'b0;
                    stageAddrB[x] <= 6'b0;
                    dina[x] <= 1'b0;
                    dinb[x] <= 1'b0;
                end
            end
        end
        else begin
            if(i[4:0] == 5'd31) begin
                tempU <= 5'd0;
            end
            current_s<= 1'b0;
            isUpdating <= 1'b0;
            wea <=1'b0;
            web <=1'b0;
            DELAY1 <= 1'b0;
            DELAY2 <= 1'b0;
            DELAY3 <= 1'b0;
            // updateDelay <= 1'b0;
        end
    end

    else if (COMPLETED == 1'b1) begin
        if (count < N) begin
            wea <= 1'b0;
            web <= 1'b0;
            stageAddrA[0] <= ramPageCount;
            temp_douta <= douta[0];
            DELAY1 <= 1'b1;
            if (count[4:0] == 5'd28) begin
                ramPageCount <= ramPageCount + 1'b1;
            end
            if(DELAY1 == 1'b1) begin
                U_feedback <= temp_douta[count[4:0]];
                count <= count + 1'b1;
            end
        end
        else begin
            count <= count;
            readComplete <= 1'b1;
        end
    end
    else begin
        count<= 1'b0;
        wea <=1'b0;
        web <=1'b0;
        DELAY1 <= 1'b0;
        DELAY2 <= 1'b0;
        DELAY3 <= 1'b0;
        U_feedback <= 1'b0;
    end
end





endmodule
