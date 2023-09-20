class vga_ctrl {

private:
  // resolotion configs
  int hsync_end_i;
  int hpulse_end_i;
  int hdata_begin_i;
  int hdata_end_i;
  int vsync_end_i;
  int vpulse_end_i;
  int vdata_begin_i;
  int vdata_end_i;

public:
  int data_i;
  int red_o, green_o, blue_o;
  int vsync_o, hsync_o, blank_o;

  void set_resolution(int hsync_end_i, int hpulse_end_i, int hdata_begin_i,
                      int hdata_end_i, int vsync_end_i, int vpulse_end_i,
                      int vdata_begin_i, int vdata_end_i);

  void eval(int data_i); // dut step
};
