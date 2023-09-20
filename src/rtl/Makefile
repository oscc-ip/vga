# pre defines
# MODULE=add
MODULE=vga_ctrl
# MODULE=alu
# build targets
default: sim # specify the default Makefile target

.PHONY: build sim clean lint wave

verilating: $(MODULE).v tb_$(MODULE).cpp
	@echo "### verilating ###"
	verilator --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp

build: verilating
	@echo "### building executable file ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

sim:build
	@echo "### do the simulation ###"
	./obj_dir/V$(MODULE)

wave:sim
	@echo "### show the waveform ###"
	gtkwave waveform.vcd & 

copy_wave: sim
	scp ./waveform.vcd fujie@10.20.63.34:~/Developer/git_repos/temp/

lint: $(MODULE).v
	@echo "### check rtl file errors"
	verilator --lint-only $(MODULE).v

clean:
	@echo "### clean files ###"
	-rm -rf obj_dir
	-rm -rf waveform.vcd
