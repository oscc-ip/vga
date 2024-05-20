// Copyright (c) 2020 ETH Zurich and University of Bologna
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Andreas Kurth <akurth@iis.ee.ethz.ch>
// - Samuel Riedel <sriedel@iis.ee.ethz.ch>
// - Michael Rogenmoser <michaero@iis.ee.ethz.ch>
// - Thomas Benz <tbenz@iis.ee.ethz.ch>
//
// -- Adaptable modifications are redistributed under compatible License --
//
// Copyright (c) 2023 Beijing Institute of Open Source Chip
// vga is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.
///
/// Infinite (Simulation-Only) Memory with AXI Slave Port
///
/// The memory array is named `mem`, and it is *not* initialized or reset.  This makes it possible to
/// load the memory of this module in simulation with an external `$readmem*` command, e.g.,
/// ```sv
/// axi4_mem_model #( ... ) i_sim_mem ( ... );
/// initial begin
///   $readmemh("file_with_memory_addrs_and_data.mem", i_sim_mem.mem);
///   $readmemh("file_with_memory_addrs_and_read_errors.mem", i_sim_mem.rerr);
///   $readmemh("file_with_memory_addrs_and_write_errors.mem", i_sim_mem.werr);
/// end
/// ```
/// `mem` is addressed (or indexed) byte-wise with `AddrWidth`-wide addresses.
///
/// This module does not support atomic operations (ATOPs).

`include "axi4_if.sv"

`define AXI4_SIM_BASE_ADDR 32'h8000_0000

module axi4_mem_model #(
    parameter int  BUFFER_DEPTH        = 1024,
    /// Warn on accesses to uninitialized bytes
    parameter bit  WARN_UNINITIALIZED  = 1'b0,
    /// Default value for uninitialized memory (undefined, zeros, ones, random)
    parameter      UNINITIALIZED_DATA  = "undefined",
    /// Clear error on access
    parameter bit  CLEAR_ERR_ON_ACCESS = 1'b1,
    /// Application delay (measured after rising clock edge)
    parameter time APP_DELAY           = 0ps,
    /// Acquisition delay (measured after rising clock edge)
    parameter time ACQ_DELAY           = 0ps
) (
    axi4_if.slave axi4
);

  typedef struct packed {
    logic [`AXI4_ID_WIDTH-1:0]   id;
    logic [`AXI4_ADDR_WIDTH-1:0] addr;
    logic [7:0]                  len;
    logic [2:0]                  size;
    logic [1:0]                  burst;
  } axi4_sim_arreq_t;

  typedef struct packed {
    logic [`AXI4_ID_WIDTH-1:0]   id;
    logic [`AXI4_DATA_WIDTH-1:0] data;
    logic [1:0]                  resp;
    logic                        last;
  } axi4_sim_rreq_t;

  // only inc burst mode support
  function logic [`AXI4_ADDR_WIDTH-1:0] axi4_sim_beat_addr(
      input logic [`AXI4_ADDR_WIDTH-1:0] addr_i, input logic [7:0] alen_i,
      input logic [2:0] asize_i, input logic [1:0] aburst_i, input int beat_i);

    logic [`AXI4_ADDR_WIDTH-1:0] res = addr_i;
    if (aburst_i == `AXI4_BURST_TYPE_INCR) begin
      res = addr_i + beat_i * (1 << asize_i);
    end
    $display("addr_i: %h beat_i: %d asize_i: %d res: %h", addr_i, beat_i, asize_i, res);
    return res;
  endfunction

  logic [7:0] mem[logic [`AXI4_ADDR_WIDTH-1:0]];
  initial begin
    automatic int              r_cnt = 0;
    automatic axi4_sim_arreq_t ar_queue  [$];

    axi4.awready = '0;
    axi4.wready  = '0;
    axi4.bid     = '0;
    axi4.bresp   = `AXI4_RESP_OKAY;
    axi4.buser   = '0;
    axi4.bvalid  = '0;

    axi4.arready = '0;
    axi4.rid     = '0;
    axi4.rdata   = '0;
    axi4.rresp   = `AXI4_RESP_OKAY;
    axi4.rlast   = '0;
    axi4.ruser   = '0;
    axi4.rvalid  = '0;
    wait (axi4.aresetn);
    fork
      // AR
      forever begin
        @(posedge axi4.aclk);
        #(APP_DELAY);
        axi4.arready = 1'b1;
        #(ACQ_DELAY - APP_DELAY);
        if (axi4.arvalid) begin
          automatic
          axi4_sim_arreq_t
          ar = {
            axi4.arid, axi4.araddr, axi4.arlen, axi4.arsize, axi4.arburst
          };
          ar_queue.push_back(ar);
        end
      end
      // R
      forever begin
        @(posedge axi4.aclk);
        #(APP_DELAY);
        axi4.rvalid = 1'b0;
        if (ar_queue.size() != 0) begin
          automatic logic [1:0] burst = ar_queue[0].burst;
          automatic logic [7:0] len = ar_queue[0].len;
          automatic logic [2:0] size = ar_queue[0].size;
          automatic
          logic [`AXI4_ADDR_WIDTH-1:0]
          addr = axi4_sim_beat_addr(
              ar_queue[0].addr, len, size, burst, r_cnt
          );

          automatic axi4_sim_rreq_t r_beat = '0;
          automatic logic [`AXI4_DATA_WIDTH-1:0] r_data = 'x;  // compatibility reasons
          $display("mem: %h", mem[addr]);
          r_beat.data = 'x;
          r_beat.id   = ar_queue[0].id;
          r_beat.resp = `AXI4_RESP_OKAY;
          for (int i = 0; i < `AXI4_WSTRB_WIDTH; i++) begin
            automatic logic [`AXI4_ADDR_WIDTH-1:0] byte_addr = addr + i;
            if (!mem.exists(byte_addr)) begin
              if (WARN_UNINITIALIZED) begin
                $warning("Access to non-initialized byte at address 0x%016x by ID 0x%x.",
                         byte_addr, r_beat.id);
              end
              case (UNINITIALIZED_DATA)
                "random": r_data[i*8+:8] = $urandom;
                "ones":   r_data[i*8+:8] = '1;
                "zeros":  r_data[i*8+:8] = '0;
                default:  r_data[i*8+:8] = 'x;
              endcase
            end else begin
              r_data[i*8+:8] = mem[byte_addr];
            end
            r_beat.resp = `AXI4_RESP_OKAY;
            if (CLEAR_ERR_ON_ACCESS & axi4.rready) begin
              // rerr[byte_addr] = `AXI4_RESP_OKAY;
            end
          end
          r_beat.data = r_data;
          if (r_cnt == ar_queue[0].len) begin
            r_beat.last = 1'b1;
          end
          axi4.rid    = r_beat.id;
          axi4.rdata  = r_beat.data;
          axi4.rresp  = r_beat.resp;
          axi4.rlast  = r_beat.last;
          axi4.rvalid = 1'b1;
          #(ACQ_DELAY - APP_DELAY);
          while (!axi4.rready) begin
            @(posedge axi4.aclk);
            #(ACQ_DELAY);
          end
          if (r_beat.last) begin
            r_cnt = 0;
            void'(ar_queue.pop_front());
          end else begin
            r_cnt++;
          end
        end
      end
    join
  end
endmodule
