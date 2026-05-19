verialtor:
	verilator \
	--binary \
	--coverage \
	-Wno-PINMISSING \
	-sv \
    ~/work/soc_verif/hw/apb_uart/rtl/io_generic_fifo.sv \
    ~/work/soc_verif/build/engine_0/trace0_tb.v\
    --top-module testbench
	
	