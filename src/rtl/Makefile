# pre defines
# MODULE=add
# MODULE=vga_ctrl
# MODULE=ping_pong_register
MODULE=vga_top
# MODULE=config_unit
# gtkwave=/Applications/gtkwave.app/Contents/Resources/bin/gtkwave  # mac config
# MODULE=alu
# build targets
default: sim # specify the default Makefile target

.PHONY: build sim clean lint wave gdb sdl

# @verilator --top-module ${MODULE} --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp vga_ctrl.cpp ping_pong_register.cpp
#	@verilator --top-module ${MODULE} --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp
verilating: $(MODULE).v tb_$(MODULE).cpp
	@echo "### verilating ###"
	@verilator --top-module ${MODULE} --trace --cc $(MODULE).v --exe tb_$(MODULE).cpp $(MODULE).cpp vga_ctrl.cpp ping_pong_register.cpp config_unit.cpp

build: verilating
	@echo "### building executable file ###"
	@make -C obj_dir -f V$(MODULE).mk V$(MODULE) 2>&1 > /dev/null

sim:build
	@echo "### do the simulation ###"
	@./obj_dir/V$(MODULE)

# @verilator --top-module vga_top --trace --cc vga_top.v --exe sdl_vga_top.cpp vga_top.cpp vga_ctrl.cpp ping_pong_register.cpp config_unit.cpp
sdl:
	@echo "### verilating ###"
	@verilator --top-module ${MODULE} --trace --cc -LDFLAGS -lSDL2 $(MODULE).v --exe sdl_$(MODULE).cpp $(MODULE).cpp vga_ctrl.cpp ping_pong_register.cpp config_unit.cpp 
	@echo "### building executable file ###"
	@make -C obj_dir -f V$(MODULE).mk V$(MODULE) -lSDL2 2>&1 > /dev/null
	@echo "### do the simulation ###"
	@./obj_dir/V$(MODULE)
	@echo "### show VGA using SDL ###"


wave:sim
	@echo "### show the waveform ###"
	gtkwave waveform.vcd & 

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
