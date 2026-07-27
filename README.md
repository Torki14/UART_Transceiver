# UART Transceiver (TX + RX)

A Verilog implementation of a UART (Universal Asynchronous Receiver/Transmitter) transceiver — independent transmitter and receiver modules that exchange bytes over a single data line per direction, with no shared clock between the two ends of the link.

## Frame Format

```
Idle(1)  Start  Bit0 Bit1 Bit2 Bit3 Bit4 Bit5 Bit6 Bit7  Stop  Idle(1)
  1        0     ↑    ↑    ↑    ↑    ↑    ↑    ↑    ↑     1
                 sampled at the middle of each bit period
```

- 1 start bit (`0`), 8 data bits (**LSB first**), 1 stop bit (`1`), no parity
- Line idles high
- Bit period = `CLKS_PER_BIT × clk period` → baud rate = `f_clk / CLKS_PER_BIT`

## Architecture

```
  Tx_Byte[7:0] ──►┌──────────────┐                             ┌──────────┐──► Rx_Byte[7:0]
  Tx_DV        ──►│   uart_tx    │────Tx_Serial───►Rx_serial──►│ uart_rx  │
  clk          ──►└──────────────┘                             └──────────┘──► Rx_DV
                     ↓         ↓                                    ↑
                  Tx_Active Tx_Done                                clk
```

`uart_tx` and `uart_rx` are fully independent — they share only the `CLKS_PER_BIT` parameter and communicate exclusively through the serial line. No handshaking signals are shared between them.

## Module Interfaces

### `uart_tx`

| Parameter      | Default | Description                                    |
|----------------|:-------:|---------------------------------------------------|
| `CLKS_PER_BIT` | 87      | Clock cycles per UART bit period (`f_clk / baud`)    |

| Port        | Direction | Width | Description                                                |
|-------------|-----------|:-----:|---------------------------------------------------------------|
| `clk`       | input     | 1     | System clock                                                    |
| `Tx_Byte`   | input     | 8     | Byte to transmit; must be valid when `Tx_DV` is sampled            |
| `Tx_DV`     | input     | 1     | Pulse high for 1 cycle to request transmission of `Tx_Byte`          |
| `Tx_Active` | output    | 1     | High for the entire frame duration (start → stop bit)                  |
| `Tx_Serial` | output    | 1     | Serial data output; idles high                                           |
| `Tx_Done`   | output    | 1     | Pulses high for 1 cycle when the frame (including stop bit) completes      |

### `uart_rx`

| Parameter      | Default | Description                                 |
|----------------|:-------:|-------------------------------------------------|
| `CLKS_PER_BIT` | 87      | Clock cycles per UART bit period (must match TX)  |

| Port        | Direction | Width | Description                                                     |
|-------------|-----------|:-----:|----------------------------------------------------------------------|
| `clk`       | input     | 1     | System clock                                                           |
| `Rx_serial` | input     | 1     | Asynchronous serial input; idles high, start = falling edge               |
| `Rx_Byte`   | output    | 8     | Most recently received byte; valid when `Rx_DV` is high                     |
| `Rx_DV`     | output    | 1     | Pulses high for 1 cycle when a complete byte is available                     |

## FSM Design

Both modules are 5-state Moore machines (`IDLE`, `START_BIT`, `DATA_BITS`, `STOP_BIT`, `CLEANUP`) driven by a free-running `CLK_COUNTER` (measures the bit period) and a 3-bit `BIT_IDX_COUNTER` (selects the current data bit).

**`uart_rx`** additionally:
- Double-flops `Rx_serial` (`Rx_serial_FF1` → `Rx_serial_FF2`) before use, to avoid metastability on the asynchronous input.
- On detecting a falling edge, waits `(CLKS_PER_BIT − 1) / 2` cycles to reach the middle of the start bit and re-checks the line — confirming a real start bit versus a glitch — before locking onto the frame.
- Samples each subsequent data bit once per full bit period, landing near the center of each bit cell.

**`uart_tx`** latches `Tx_Byte` into `Tx_Latched_Byte` on entry to `TX_START_BIT`, so `Tx_Byte` is free to change once transmission has begun. `Tx_DV` pulses that arrive while a frame is already in progress are ignored — user logic should gate new requests on `Tx_Active` being low, or wait for `Tx_Done`.

## Verification

`uart_tb.v` is a self-checking loopback testbench: it ties `Tx_Serial` directly into `Rx_serial` and drives 5 test bytes (`0x55`, `0xAA`, `0x00`, `0xFF`, `0x3C`) through `uart_tx`, waiting for `Rx_DV` on the receive side and comparing the received byte against what was sent. Each byte is reported PASS/FAIL, with a final summary line.

## Running the Simulation

```bash
# ModelSim / QuestaSim
vlog uart_tx.v uart_rx.v uart_tb.v
vsim -c uart_tb -do "run -all"
```

## Tools

Verilog, ModelSim/QuestaSim

## Author

Mohamed Torki Bassuni — [LinkedIn](https://linkedin.com/in/muhammad-torki) · [GitHub](https://github.com/Torki14)
