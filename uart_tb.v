module uart_tb;

    localparam CLKS_PER_BIT = 87;   // 10 MHz clk, 115200 baud
    localparam CLK_PERIOD   = 100;  // 100 ns -> 10 MHz

    reg        clk = 0;
    reg        Tx_DV;
    reg  [7:0] Tx_Byte;
    wire       Tx_Serial;
    wire       Tx_Done;

    wire       Rx_DV;
    wire [7:0] Rx_Byte;

    integer errors = 0;

    always #(CLK_PERIOD/2) clk = ~clk;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) DUT_TX (
        .clk       (clk),
        .Tx_DV     (Tx_DV),
        .Tx_Byte   (Tx_Byte),
        .Tx_Active (),
        .Tx_Serial (Tx_Serial),
        .Tx_Done   (Tx_Done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) DUT_RX (
        .clk       (clk),
        .Rx_serial (Tx_Serial),   
        .Rx_DV     (Rx_DV),
        .Rx_Byte   (Rx_Byte)
    );

    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            Tx_Byte <= data;
            Tx_DV   <= 1'b1;
            @(posedge clk);
            Tx_DV   <= 1'b0;

            wait (Rx_DV == 1'b1);
            if (Rx_Byte === data)
                $display("PASS: sent 0x%02h, received 0x%02h", data, Rx_Byte);
            else begin
                $display("FAIL: sent 0x%02h, received 0x%02h", data, Rx_Byte);
                errors = errors + 1;
            end

            wait (Tx_Done == 1'b1);
            @(posedge clk);
        end
    endtask

    initial begin
        Tx_DV   = 0;
        Tx_Byte = 8'h00;

        repeat (5) @(posedge clk);

        send_byte(8'h55);
        send_byte(8'hAA);
        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'h3C);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule