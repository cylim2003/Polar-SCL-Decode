`timescale 1ns / 1ps


module PartialSumV2
#(
    parameter N = 8,
    parameter STAGES = 3,
    localparam S_WRITE = 2'd1,
    localparam S_READ = 2'd2
)
(
    input wire sysclk,
    input wire sysres,
    input wire [10:0] i,
    input wire [4:0] s,
    input wire U_0, //input U for writing
    input wire readEn,
    input wire writeEn,
    input wire COMPLETED,
    output reg isUpdating,
    output reg readComplete,
    output reg U
    );

reg [N-1:0] stageU [STAGES:0];
integer x;
integer l;
reg [STAGES:0] count;
reg [4:0] current_s;
wire [STAGES:0] BASE;
reg [STAGES:0] temp_count;
reg [10:0] i_count;
assign BASE = (i>>(s+1)<<(s+1));
always @(posedge sysclk or negedge sysres) begin
    if(sysres == 1'b0) begin
        U <= 1'b0;
        for (x = 0; x<=STAGES;x= x+1'b1) begin
            stageU[x] <= 8'd0;
        end
        count <= 1'b0;
        temp_count <= 1'b0;
        isUpdating <= 1'b0;
        current_s <= 1'b0;
        i_count <= 10'b0;
        readComplete <= 1'b0;
    end
    else if(writeEn== 1'b1) begin
        stageU[0][i] <= U_0;
        isUpdating <= 1'b1;
        current_s <= 0;
    end
    else if (isUpdating == 1'b1 && writeEn == 1'b0) begin
        if (i[current_s] == 1'b1) begin
            updateBlock(current_s,i);
            if (current_s < STAGES -1) begin
                current_s <= current_s + 1'b1;
            end
            else begin
                isUpdating <= 1'b0;
            end
        end
        else begin
            U <= 1'b0;
            isUpdating <= 1'b0;
        end
    end

    else if(readEn == 1'b1) begin
        if (count <= ((1<<s)-1)) begin
            $display("Reading Layer:%d Address:%d Value:%b", s, BASE+count, stageU[s][BASE+count]);
            U <= stageU[s][BASE + count ];
            count <= count + 1'b1;
            // count <= temp_count;
            // temp_count <= temp_count + 1'b1;
            // U <= stageU[2][2];
        end
        else begin
            count <= count;
            temp_count<= 1'b0;
            U <= 1'b0;
        end
    end
    else if (COMPLETED == 1'b1) begin
        if (i_count < N) begin
            U <= stageU[0][i_count];
            i_count <= i_count + 1'b1;
        end
        else begin
            i_count <= i_count;
            readComplete <= 1'b1;
        end
    end
    else begin
        temp_count<= 1'b0;
        count <= 1'b0;
    end

end
       
task updateBlock (input [4:0] l, input[STAGES:0] y);
    integer j;
    reg [STAGES-1:0] base;
    begin 
        base = (y>>(l+1)<<(l+1));
        // for (j=0; j<(1<<l); j = j+1'b1) begin
        case (l) 
            0: begin
                stageU[1][base] <= stageU[0][base] ^stageU[0][base + 1];
                stageU[1][base+1] <= stageU[0][base+1];
            end
            1,2,3,4,5,6,7,8,9: begin
                for (j=0; j<(N/2); j = j+1'b1) begin
                    if (j < (1 << l)) begin
                        stageU[l+1][base + j] <= stageU[l][base+j] ^ stageU[l][base+j + (1<<l)];
                        stageU[l+1][base + j +(1<<l)] <= stageU[l][base+j+(1<<l)];
                    end
                end
            end
        endcase
        // for (j=0; j<(N/2<<l); j = j+1'b1) begin
        //     stageU[l+1][base + j] <= stageU[l][base+j] ^ stageU[l][base+j + (1<<l)];
        //     stageU[l+1][base + j +(1<<l)] <= stageU[l][base+j+(1<<l)];
        // end
    end
endtask


endmodule
