vdel -all
vlib work 
vlog uart_tx.v uart_rx.v uart_tb.v +cover -covercells
vsim -voptargs=+acc work.uart_tb -cover
add wave *
run -all