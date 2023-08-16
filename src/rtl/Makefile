# pre defines
# MODULE=add
MODULE=alu
# build targets
default: sim # specify the default Makefile target

.PHONY: build sim clean lint wave

build: $(MODULE).v tb_$(MODULE).cpp
	@echo "### verilating ###"
	verilator --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp
	@echo "### building executable file ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

sim:build
	@echo "### do the simulation ###"
	./obj_dir/V$(MODULE)

wave:sim
	@echo "### show the waveform ###"
	gtkwave waveform.vcd & 

lint: $(MODULE).v
	@echo "### check rtl file errors"
	verilator --lint-only $(MODULE).v

clean:
	@echo "### clean files ###"
	-rm -rf obj_dir
	-rm -rf waveform.vcd
