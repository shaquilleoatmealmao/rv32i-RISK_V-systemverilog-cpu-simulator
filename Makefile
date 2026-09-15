SIM ?= iverilog
OUT := build/rv32i_tb

.PHONY: test clean lint

test:
	mkdir -p build
	$(SIM) -g2012 -Wall -s tb_rv32i -o $(OUT) rtl/rv32i_core.sv tb/tb_rv32i.sv
	vvp $(OUT)

lint:
	verilator --lint-only -Wall --Wno-fatal --timing rtl/rv32i_core.sv tb/tb_rv32i.sv

clean:
	rm -rf build
