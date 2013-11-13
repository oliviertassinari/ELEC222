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

  // Wishbone master interface
  wshb_if #(.DATA_BYTES(4),.ADDRESS_WIDTH(32)) wshb_tbm_if_0(clk);
  // Wishbone slave interface
  wshb_if #(.DATA_BYTES(2),.ADDRESS_WIDTH(32)) wshb_tbs_if_0(clk);
  // Test
  test #(
        .MASTER_DATA_BYTES(4),
        .SLAVE_DATA_BYTES(2),
        .ADDRESS_WIDTH(32)
        )
        u_test();

  // Le convertisseur
  wb_bridge_s32_m16 u_bridge
      (
	.clk(clk),
	.reset(reset),
	// Wishbone 32 bits slave interface
	.wb_s_stb_i(wshb_tbm_if_0.stb_o),
	.wb_s_cyc_i(wshb_tbm_if_0.cyc_o),
	.wb_s_we_i(wshb_tbm_if_0.we_o),
	.wb_s_adr_i(wshb_tbm_if_0.adr_o),
	.wb_s_sel_i(wshb_tbm_if_0.sel_o),
	.wb_s_dat_i(wshb_tbm_if_0.dat_mo),
	.wb_s_ack_o(wshb_tbm_if_0.ack),
	.wb_s_dat_o(wshb_tbm_if_0.dat_sm),
        .wb_s_err_o(wshb_tbm_if_0.err),
        .wb_s_rty_o(wshb_tbm_if_0.rty),
	// Wishbone 16 bits master interface
	.wb_m_stb_o(wshb_tbs_if_0.stb),
	.wb_m_cyc_o(wshb_tbs_if_0.cyc),
	.wb_m_we_o(wshb_tbs_if_0.we),
	.wb_m_adr_o(wshb_tbs_if_0.adr),
	.wb_m_sel_o(wshb_tbs_if_0.sel),
	.wb_m_dat_o(wshb_tbs_if_0.dat_ms),
	.wb_m_dat_i(wshb_tbs_if_0.dat_so),
	.wb_m_ack_i(wshb_tbs_if_0.ack_o),
        .wb_m_err_i(wshb_tbs_if_0.err_o),
        .wb_m_rty_i(wshb_tbs_if_0.rty_o)
);



endmodule
