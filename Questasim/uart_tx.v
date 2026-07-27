module uart_tx 
    #(parameter CLKS_PER_BIT = 87) 
    (
    input       clk,
    input [7:0] Tx_Byte,
    input       Tx_DV,
    output reg  Tx_Active,
    output reg  Tx_Serial,
    output reg  Tx_Done
);
    localparam IDLE = 0;
    localparam TX_START_BIT = 1;
    localparam TX_DATA_BITS = 2;
    localparam TX_STOP_BIT = 3;
    localparam CLEANUP = 4;

    reg [2:0] STATE_REG = IDLE;

    reg [2:0] BIT_IDX_COUNTER = 0;
    reg [15:0] CLK_COUNTER = 0;

    reg [7:0] Tx_Latched_Byte = 0;

    always@(posedge clk) begin
    case(STATE_REG) 
        IDLE: begin
            Tx_Serial <= 1;
            Tx_Active <= 0;
            Tx_Done   <= 0;
            CLK_COUNTER <= 0;
            BIT_IDX_COUNTER <= 0;
            if(Tx_DV) begin
                Tx_Latched_Byte <= Tx_Byte;
                STATE_REG <= TX_START_BIT;
            end
            else 
                STATE_REG <= IDLE;
        end

        TX_START_BIT: begin
            Tx_Active <= 1;
            Tx_Serial <= 0;
            if(CLK_COUNTER < (CLKS_PER_BIT - 1)) begin
                CLK_COUNTER <= CLK_COUNTER + 1;
                STATE_REG <= TX_START_BIT;
            end
            else begin
                STATE_REG <= TX_DATA_BITS;
                CLK_COUNTER <= 0;
            end
        end

        TX_DATA_BITS: begin
            Tx_Serial <= Tx_Latched_Byte[BIT_IDX_COUNTER];
            if(CLK_COUNTER < (CLKS_PER_BIT - 1)) begin
                CLK_COUNTER <= CLK_COUNTER + 1;
                STATE_REG <= TX_DATA_BITS;
            end
            else begin
                CLK_COUNTER <= 0;
                if(BIT_IDX_COUNTER < 7) begin
                    BIT_IDX_COUNTER <= BIT_IDX_COUNTER + 1;
                    STATE_REG <= TX_DATA_BITS;
                end
                else begin
                    BIT_IDX_COUNTER <= 0;
                    STATE_REG <= TX_STOP_BIT;
                end
            end        
        end

        TX_STOP_BIT: begin
            Tx_Serial <= 1;
            if(CLK_COUNTER < (CLKS_PER_BIT - 1)) begin
                    CLK_COUNTER <= CLK_COUNTER + 1;
                    STATE_REG   <= TX_STOP_BIT;
            end
            else begin
                    CLK_COUNTER <= 0;
                    STATE_REG   <= CLEANUP;
                    Tx_Done     <= 1;
            end           
        end

        CLEANUP: begin
            Tx_Done <= 0;
            Tx_Active <= 0;
            STATE_REG <= IDLE;
        end
        default: STATE_REG <= IDLE;
    endcase
    end
endmodule