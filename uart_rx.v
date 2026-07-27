module uart_rx 
    #(parameter CLKS_PER_BIT = 87) 
    (
    input            clk,
    input            Rx_serial,
    output [7:0]     Rx_Byte,
    output reg       Rx_DV
);
    localparam IDLE = 0;
    localparam RX_START_BIT = 1;
    localparam RX_DATA_BITS = 2;
    localparam RX_STOP_BIT = 3;
    localparam CLEANUP = 4;

    reg [2:0]  STATE_REG = IDLE;

    reg [2:0]  BIT_IDX_COUNTER = 0;
    reg [15:0] CLK_COUNTER = 0;

    reg        Rx_serial_FF1 = 1;
    reg        Rx_serial_FF2 = 1;
    reg [7:0]  Rx_Acc_Byte   = 0;
    always@(posedge clk) begin
        Rx_serial_FF1 <= Rx_serial;
        Rx_serial_FF2 <= Rx_serial_FF1;
    end    

    always @(posedge clk) begin
        case(STATE_REG)
            IDLE: begin
                Rx_DV <= 0;
                CLK_COUNTER <= 0;
                BIT_IDX_COUNTER <= 0;

                if(Rx_serial_FF2 == 0) 
                    STATE_REG <= RX_START_BIT;
                 else 
                    STATE_REG <= IDLE;   
            end

            RX_START_BIT: begin
                if (CLK_COUNTER ==  (CLKS_PER_BIT - 1) / 2) begin
                    if(Rx_serial_FF2 == 0) begin
                        CLK_COUNTER <= 0;
                        STATE_REG <= RX_DATA_BITS;  
                    end
                    else 
                        STATE_REG <= IDLE;  
                end
                else begin
                    CLK_COUNTER <= CLK_COUNTER + 1;
                    STATE_REG <= RX_START_BIT;
                end
            end

            RX_DATA_BITS: begin
                if(CLK_COUNTER < (CLKS_PER_BIT - 1)) begin
                    CLK_COUNTER <= CLK_COUNTER +1 ;
                    STATE_REG <= RX_DATA_BITS;
                end
                else begin
                    CLK_COUNTER <= 0;
                    Rx_Acc_Byte[BIT_IDX_COUNTER] <= Rx_serial_FF2; 

                    if(BIT_IDX_COUNTER < 7) begin
                        BIT_IDX_COUNTER <= BIT_IDX_COUNTER +1;
                        STATE_REG <= RX_DATA_BITS;
                    end
                    else begin
                        BIT_IDX_COUNTER <= 0;
                        STATE_REG <= RX_STOP_BIT;
                    end
                end
            end

            RX_STOP_BIT: begin
                if(CLK_COUNTER < (CLKS_PER_BIT - 1)) begin
                    CLK_COUNTER <= CLK_COUNTER +1;
                    STATE_REG <= RX_STOP_BIT;
                end
                else begin
                    CLK_COUNTER <= 0;
                    Rx_DV <= 1;
                    STATE_REG <= CLEANUP;
                end
            end

            CLEANUP: begin
                STATE_REG <= IDLE;
                Rx_DV <= 0;
            end

            default: STATE_REG <= IDLE;
        endcase
    end
    assign Rx_Byte = Rx_Acc_Byte;
endmodule