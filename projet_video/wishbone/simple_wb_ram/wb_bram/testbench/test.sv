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

`timescale 1ns/1ns

import PACKET::*;
import WSHB_M::*;

program test #(type virtual_master_t);
  initial begin
    //
    packet dataIn,  expData, dataOut;
    sel_packet selIn ;
    int addr;
    int trErrors, trExpErrors;
    int itrNum;
    int chkResult ;
    time t0,t1,t2,t3 ;
    //
    WSHB_m_env #(virtual_master_t) wshb_m;
    automatic Packet pkt  = new();
    automatic Checker chk = new();
    itrNum = 10000;
    // Create WSHB master
    wshb_m    = new(testbench_top.wshb_if_0);
    // Start master and slave vips
    wshb_m.startEnv();
    //
    wshb_m.setRndDelay(0, 100, 0, 10);
    wshb_m.setTimeOut(100, 3);
    trExpErrors = 0;
    // Wait several clocks to be sure that DUT is ready
    repeat (10) @(posedge testbench_top.clk);
    // Master read/write in classic mode
    t0 = $time ;
    repeat (itrNum) begin
      addr = pkt.genRndNum(0, 100000);
      pkt.genRndPkt(pkt.genRndNum(1, 32), random_selection, dataIn, selIn);
      $display("address == %h", addr);
      $display("Length  == %d", dataIn.size());
      wshb_m.writeData(addr,dataIn,selIn,without_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      wshb_m.readData(addr,dataOut,selIn,dataIn.size(),without_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      chkResult = chk.CheckPkt(dataOut, dataIn,selIn);
      if(chkResult < 0) $fatal ;  
    end
    t1 = $time ;
    $display("-Total time for wishbone classic mode sequences              : %d",t1-t0) ;
    // Master read/write in burst mode mode
    t2 = $time ;
    repeat (itrNum) begin
      addr = pkt.genRndNum(0, 100000,4); // Force aligned words
      pkt.genRndPkt(pkt.genRndNum(1, 32,4), random_burst_selection, dataIn, selIn); // Force multiple of words
      $display("address == %h", addr);
      $display("Length  == %d", dataIn.size());
      wshb_m.writeData(addr,dataIn,selIn,with_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      wshb_m.readData(addr,dataOut,selIn,dataIn.size(),with_burst_tags);
      wshb_m.busIdle(pkt.genRndNum(0, 2));
      chkResult = chk.CheckPkt(dataOut, dataIn,selIn);
      if(chkResult < 0)  $fatal ;
    end
    t3 = $time ;
    $display("-Total time for wishbone registered feedback mode sequences  : %d",t3-t2) ;
    //
    repeat (5) @testbench_top.wshb_if_0.tbm.cbm;
    //
    trErrors = wshb_m.printStatus();
    $display("-----------------------Test Done------------------------");
    $display("------------------Printing Test Status------------------");
    if (trErrors == trExpErrors) begin
      $display("-Transactions have 0 unexpected TimeOut or Slave Errors-");
    end else begin
      $display("--Transactions have unexpected TimeOut or Slave Errors--");
      $display("Expected  error amount is %d", trExpErrors);
      $display("Generated error amount is %d", trErrors);
    end
    $display("--------------------------------------------------------");
    chk.printFullStatus();
    $display("--------------------------------------------------------");
    //
  end
endprogram
