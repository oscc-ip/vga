CPPFLAGS= -g
LDFLAGS= -g
# pre defines
# MODULE=add
# MODULE=vga_ctrl
MODULE=ping_pong_register
gtkwave=/Applications/gtkwave.app/Contents/Resources/bin/gtkwave  # mac config
# MODULE=alu
# build targets
default: sim # specify the default Makefile target

.PHONY: build sim clean lint wave gdb

verilating: $(MODULE).v tb_$(MODULE).cpp
	@echo "### verilating ###"
	verilator --top-module ${MODULE} --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp

build: verilating
	@echo "### building executable file ###"
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)

sim:build
	@echo "### do the simulation ###"
	./obj_dir/V$(MODULE)

wave:sim
	@echo "### show the waveform ###"
	${gtkwave} waveform.vcd & 

gdb: $(MODULE).v tb_$(MODULE).cpp
	@echo "### debug project ###"
	verilator -CFLAGS -g --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp
	make -C obj_dir -f V$(MODULE).mk V$(MODULE)
	gdb ./obj_dir/V${MODULE} -silent

copy_wave: sim
	scp ./waveform.vcd fujie@10.20.63.34:~/Developer/git_repos/temp/

lint: $(MODULE).v
	@echo "### check rtl file errors"
	verilator --lint-only $(MODULE).v

clean:
	@echo "### clean files ###"
	-rm -rf obj_dir
	-rm -rf waveform.vcd
