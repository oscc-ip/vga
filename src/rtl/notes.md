1. demo1, following [this guide](https://itsembedded.com/dhd/verilator_1/)
   ```bash
     # use verilator to convert the rtl code to c++ files and
     # create a makefile to build all the c++ files
     verilator -Wall --trace -cc vga_ctrl.v --exe main.c
     # use the makefile to create executable file
     make -C obj_dir -f Vvga_ctrl.mk Vvga_ctr
     # run the executable file to do the simulation
     ./obj_dir/Vvga_ctrl
   ```
   1. `-Wall` enable all c++ errors
   2. `-cc` convert the rtl codes to c++ codes
   3. `--exe` enable the makefile to create executable files
   4. `--trace` enable waveform option
