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

// YM/TPT adaptation: test of a  bram controller connected to a 32 bit wishbone interface

`timescale 1ns/10ps

module testbench_top;
  // Clock generator
  bit clk;
  bit rst ;
  initial begin
    forever #5 clk = ~clk;
  end
  initial
  begin
     rst = 1 ;
     #20 ;
     rst = 0 ;
  end

  // Wishbone 32 bits interface with a master testbench
  wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32 
    #(.TB_MASTER(1))  
    wshb_if_0(
             .clk(clk),
             .rst(rst)
             );
  
  // Device under test
  wb_bram u_ctrl
  (
    // Wishbone 32 bits slave interface
   .wb_s(wshb_if_0.slave)
  );

  // Testbench
  // Virtual tb_master modport  for the testbench
  typedef virtual wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32 #(.TB_MASTER(1)).tb_master  virtual_master_t ;

  test #(virtual_master_t) u_test();


endmodule
