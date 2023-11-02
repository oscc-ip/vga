#include <stdio.h>

int main() {

  int hsync_pulse[4] = {128, 96, 41, 2};
  int hback[4] = {88, 40, 41, 66};
  int hleft[4] = {0, 8, 0, 0};
  int hdata[4] = {800, 640, 480, 320};
  int htotal[4] = {1056, 800, 525, 0};

  int vsync_pulse[4] = {4, 2, 10, 0};
  int vback[4] = {23, 25, 2, 0};
  int vtop[4] = {0, 8, 0, 0};
  int vdata[4] = {600, 480, 272, 240};
  int vtotal[4] = {628, 525, 286, 0};

  unsigned __int128 width[8] = {11, 8, 8, 10, 10, 4, 6, 10};
  int wid[8] = {11, 8, 8, 10, 10, 4, 6, 10};
  unsigned __int128 value[4][8];

  for (int i = 0; i < 4; i++) {
    // sync, pulse, data_begin, data_end
    value[i][0] = htotal[i];
    value[i][1] = hsync_pulse[i];
    value[i][2] = hsync_pulse[i] + hback[i] + hleft[i];
    value[i][3] = value[i][2] + hdata[i];

    value[i][4] = vtotal[i];
    value[i][5] = vsync_pulse[i];
    value[i][6] = vsync_pulse[i] + vback[i] + vtop[i];
    value[i][7] = value[i][6] + vdata[i];

    printf("i=%d\n", i);
    for (int j = 0; j < 8; j++) {
      printf("%lld ", (unsigned long long)value[i][j]);
    }
    printf("\n==========\n");
  }

  unsigned __int128 resolution;

  for (int i = 0; i < 4; i++) {
    resolution = value[i][7];
    for (int j = 6; j >= 0; j--) {
      resolution = resolution << width[j];
      resolution += value[i][j];
    }
    printf(">>>>>i=%d\n", i);
    unsigned long long right =
        (unsigned long long)(resolution & 0xffffffffffffffff);
    unsigned long long left =
        (unsigned long long)((resolution >> 64) & 0xffffffffffffffff);

    printf("left=0x%llx\n", left);
    printf("right=0x%016llx\n", right);
    printf("resolution=0x%llx%016llx\n\n", left, right);
  }

  // int start = 0;
  // for (int i = 0; i < 8; i++) {
  //   printf("%02d:%02d\n", start + wid[i] - 1, start);
  //   start += wid[i];
  // }

  // for (int i = 0; i < 8; i++) {
  //   printf("%02d:%d\n", wid[i] - 1, 0);
  // }

  //   int shift=0;
  // for(int i=0;i<8;i++){
  //      printf("shift=%d\n", shift);
  //       shift+=wid[i];
  //   }

  return 0;
}
