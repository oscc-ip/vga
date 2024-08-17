# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Nicole Narr <narrn@student.ethz.ch>
# Christopher Reinwardt <creinwar@student.ethz.ch>

# import numpy as np

with open("sim.mem", "w+", encoding='utf-8') as f:
    f.write("@80000000\n")
    fb_len = (int)(640 * 480 / 8 + 10)
    wr_val = 0
    for i in range(fb_len):
        for k in range(8):
            txt = "{:x} "
            f.write(txt.format(wr_val & 0xFF))
            wr_val = wr_val + 1
        f.write("\n")

# with open("color_matrix.mem", "w+") as f:
#     f.write("@80000000\n")
#     color = 0
#     arr = np.empty((640, 480))
#     for v in range(8):
#         for h in range(16):
#             for vi in range(30):
#                 for hi in range(40):
#                     for k in range(8):
#                         arr[h * 40 + hi][v * 30 + vi] = color
#             color += 0x0101
#         color += 0x1010

#     color = 0x1010
#     for v in range(8, 16):
#         for h in range(16):
#             for vi in range(30):
#                 for hi in range(40):
#                     for k in range(8):
#                         arr[h * 40 + hi][v * 30 + vi] = color
#             color += 0x0101
#         color += 0x1010

#     for v in range(480):
#         for h in range(int(640 / 4)):
#             temp = (int(arr[4 * h][v]) & 0xFFFF) | (
#                 (int(arr[4 * h + 1][v]) & 0xFFFF) << 16) | (
#                     (int(arr[4 * h + 2][v]) & 0xFFFF) << 32) | (
#                         (int(arr[4 * h + 3][v]) & 0xFFFF) << 48)
#             for k in range(8):
#                 txt = "{:x} "
#                 f.write(txt.format((temp >> (8 * k)) & 0xFF))

#             f.write("\n")
