#ifndef __VGA_CTRL__
#define __VGA_CTRL__
class vc_in_io {
public:
  bool clk, resetn;
  // ConfigUnit input
  int hsync_end_i;
  int hpulse_end_i;
  int hdata_begin_i;
  int hdata_end_i;
  int vsync_end_i;
  int vpulse_end_i;
  int vdata_begin_i;
  int vdata_end_i;
  // PingPongRegister input
  int data_i;
  bool self_test_i;
  // get random input
  void randInIO(unsigned long int sim_time);
};
class vc_out_io {
public:
  int red_o, green_o, blue_o;
  int vsync_o, hsync_o, blank_o;
  bool data_req_o;
};
class vga_ctrl {

private:
  // resolotion configs
  int vcount, hcount;
  int test_cnt;
  int test_color[8];

public:
  vc_in_io *in;
  vc_out_io *out;

  void resetn(); // resetn c_model
  void eval();   // step one cycle
  vga_ctrl() {
    in = new vc_in_io;
    out = new vc_out_io;
    vcount = 0;
    hcount = 0;
  }
};
#endif
