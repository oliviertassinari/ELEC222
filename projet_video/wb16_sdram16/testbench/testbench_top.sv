/*
Copyright (C) 2009 SysWip

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// YM/TPT adaptation: test of a 32b to 16b wishbone bridge
// ATTENTION : busses model and classes doesn(t use parameters for the size
// of the bus (templates problems in SystemVerilog).
// both interfaces and classes should be corrected

`timescale 1ns/10ps

module testbench_top;
  // Clock generator
  bit clk;
  bit reset ;
  initial begin
    forever #5 clk = ~clk;
  end
  initial
  begin
     reset = 1 ;
     #20 ;
     reset = 0 ;
  end
  //

  // Wishbone 32 bits interface with a master testbench
  wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32 #(.TB_MASTER(1))  wshb_if_0(clk,reset);
  // Virtual tb_master modport  for the testbench
  typedef virtual wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32 #(.TB_MASTER(1)).tb_master  virtual_master_t ;


  // Wishbone 16 bits interface
  wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32  wb16(clk,reset);

  // Test
  test #(virtual_master_t) u_test();


// Adaptation des requetes 32 bits en requêtes 16 bits
  


wb_bridge_s32_m16 wb_bridge_0
      (
      .wb_s(wshb_if_0.slave),
      .wb_m(wb16.master)
      );

  // Interface sdram
  logic dram_clk ;
  logic dram_cke ;
  logic dram_cs_n ;
  logic dram_ras_n ;
  logic dram_we_n ;
  logic [1:0] dram_ba ;
  logic [11:0] dram_addr ;
  wire  [15:0] dram_dq ;
  logic [1:0] dram_dqm ;
  
  assign dram_clk = ~clk ;


  wb16_sdram16 u_sdram_ctrl
  (
   // Wishbone 32 bits slave interface
   .wb_s(wb16.slave),
   // SDRAM
   .cke(dram_cke),                      // clock-enable to SDRAM
   .cs_n(dram_cs_n),                    // chip-select to SDRAM
   .ras_n(dram_ras_n),                  // SDRAM row address strobe
   .cas_n(dram_cas_n),                  // SDRAM column address strobe
   .we_n(dram_we_n),                    // SDRAM write enable
   .ba(dram_ba),                        // SDRAM bank address
   .sAddr(dram_addr),                   // SDRAM row/column address
   .sDQ(dram_dq),                       // data from and to SDRAM
   .dqm(dram_dqm)                       // enable bytes of SDRAM databus
  );

// sdram

  km416s4030 SDRAM
  (
                  .BA0    (dram_ba  [0] ),
                  .BA1    (dram_ba  [1] ),
                  .DQML   (dram_dqm [0] ),
                  .DQMU   (dram_dqm [1] ),
                  .DQ0    (dram_dq  [0] ),
                  .DQ1    (dram_dq  [1] ),
                  .DQ2    (dram_dq  [2] ),
                  .DQ3    (dram_dq  [3] ),
                  .DQ4    (dram_dq  [4] ),
                  .DQ5    (dram_dq  [5] ),
                  .DQ6    (dram_dq  [6] ),
                  .DQ7    (dram_dq  [7] ),
                  .DQ8    (dram_dq  [8] ),
                  .DQ9    (dram_dq  [9] ),
                  .DQ10   (dram_dq  [10]),
                  .DQ11   (dram_dq  [11]),
                  .DQ12   (dram_dq  [12]),
                  .DQ13   (dram_dq  [13]),
                  .DQ14   (dram_dq  [14]),
                  .DQ15   (dram_dq  [15]),
                  .CLK    (dram_clk     ),
                  .CKE    (dram_cke     ),
                  .A0     (dram_addr[0] ),
                  .A1     (dram_addr[1] ),
                  .A2     (dram_addr[2] ),
                  .A3     (dram_addr[3] ),
                  .A4     (dram_addr[4] ),
                  .A5     (dram_addr[5] ),
                  .A6     (dram_addr[6] ),
                  .A7     (dram_addr[7] ),
                  .A8     (dram_addr[8] ),
                  .A9     (dram_addr[9] ),
                  .A10    (dram_addr[10]),
                  .A11    (dram_addr[11]),
                  .WENeg  (dram_we_n    ),
                  .RASNeg (dram_ras_n   ),
                  .CSNeg  (dram_cs_n    ),
                  .CASNeg (dram_cas_n   )
 ) ;


endmodule
