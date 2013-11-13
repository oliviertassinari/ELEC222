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

`timescale 1ns/10ps

interface wshb_s_if #(DATA_BYTES , ADDRESS_WIDTH) (input bit clk);
  // WISHBONE Slave signals
  logic  [8*DATA_BYTES-1:0] dat_ms;
  logic  [8*DATA_BYTES-1:0] dat_sm;
  logic  [ADDRESS_WIDTH-1:0] adr;
  logic         cyc;
  logic  [DATA_BYTES-1:0]  sel;
  logic         stb;
  logic         we;
  logic         ack;
  logic         err;
  logic         rty;

  // Modport for slave testbench
  modport tb_slave(
    clocking cbs,
    clocking cbs_n,
    task clockAlign()  
  );


  // Clocking block 0 positive edge
  clocking cbs @(posedge clk);
    // WISHBONE Slave signals
    output dat_sm;
    output ack;
    output err;
    output rty;
    input  adr;
    input  sel;
    input  stb;
    input  we;
    input  cyc;
    input  dat_ms;
  endclocking
  // Clocking block 1 negative edge
  clocking cbs_n @(negedge clk);
    // WISHBONE Slave signals
    output dat_sm;
    output ack;
    output err;
    output rty;
    input  adr;
    input  sel;
    input  stb;
    input  we;
    input  cyc;
    input  dat_ms;
  endclocking
  // Clock edge alignment
  sequence sync_posedge;
     @(posedge clk) 1;
  endsequence
  // Clock edge alignment
  task clockAlign();
    wait(sync_posedge.triggered);
  endtask
  //
endinterface
