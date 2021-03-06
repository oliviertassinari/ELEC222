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

// VERSION YM /Telecom-Paristech 2012
// - unique interface for master and slaves using modport
// - parameterized virtual interface via type parameter
// - blockSize parameter automatically extracted from data sizes
// - added simple registred block transferts using CTI/BTE signaling:
//    Burst Type Extension is always "00" (Linear burst)
//    Cycle Type Identifier may be : "000" (classic cycle) 
//                                   "010" Incrementing burst cycle
//                                   "111" End of Burst
// - added a flag to select registered transfer mode or not
// - corected the timeOut detection for correct handling of X or Z acknowledge signals

`timescale 1ns/10ps

package WSHB_M;
import PACKET::*;

typedef bit [31:0]   bit32;
typedef bit [63:0]   bit64;
typedef bit8         bit8_8[8];
typedef class WSHB_m_busTrans;

`ifdef VCS
typedef mailbox TransMBox;
`else
typedef mailbox #(WSHB_m_busTrans) TransMBox;
`endif
///////////////////////////////////////////////////////////////////////////////
// Class WSHB_m_busTrans:
///////////////////////////////////////////////////////////////////////////////
class WSHB_m_busTrans;
  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  int                                 TrNum;
  enum {WRITE, READ, IDLE, WAIT,
        CFG_DELAY, CFG_TIMEOUT}       TrType;
  bit32                               address;
  bit [2:0]                           cti ;
  bit8_8                              dataBlock;
  bit8                                sel;
  int                                 lastBlock;
  int                                 idleCycles;
  string                              failedTr;
  // Configuration variables
  int minBurst, maxBurst, minWait, maxWait;
  int ackTimeOut, rtyTimeOut;
  /////////////////////////////////////////////////////////////////////////////
  //************************* Class Methods *********************************//
  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////
  /*- unpack2pack():*/
  /////////////////////////////////////////////////////////////////////////////
  function bit64 unpack2pack(bit8_8 dataBlock);
    unpack2pack = {dataBlock[7], dataBlock[6], dataBlock[5], dataBlock[4],
                   dataBlock[3], dataBlock[2], dataBlock[1], dataBlock[0]};
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- pack2unpack():*/
  /////////////////////////////////////////////////////////////////////////////
  function bit8_8 pack2unpack(bit64 dataBlock );
    {pack2unpack[7], pack2unpack[6], pack2unpack[5], pack2unpack[4],
     pack2unpack[3], pack2unpack[2], pack2unpack[1], pack2unpack[0]
    } = dataBlock;
  endfunction
  //
endclass // WSHB_m_busTrans
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Class WSHB_m_busBFM:
///////////////////////////////////////////////////////////////////////////////
class WSHB_m_busBFM #(type virtual_wshb_master_type);
  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  // Configuration variables
  int       blockSize;
  int       maxRetry    = 0;
  int       ackTimeOut  = 0;
  int       burstDelayEn= 0;
  rand int  maxBurstLen = 0;
  rand int  waitCycles  = 0;
  local int maxBurst, minBurst;
  local int maxWait, minWait;
  // Constraints for random timing
  constraint c_timing {
    this.maxBurstLen          inside {[minBurst:maxBurst]};
    this.waitCycles           inside {[minWait:maxWait]};
  }
  /////////////////////////////////////////////////////////////////////////////
  virtual_wshb_master_type ifc;
  TransMBox trInBox, trOutBox, statusBox;
  local WSHB_m_busTrans tr;
  int burstCnt;
  /////////////////////////////////////////////////////////////////////////////
  //************************* Class Methods *********************************//
  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////
  /*- startBFM(): Start main loop.*/
  /////////////////////////////////////////////////////////////////////////////
  task startBFM();
    fork
      this.run_loop();
    join_none
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- run_loop(): Main loop.*/
  /////////////////////////////////////////////////////////////////////////////
  local task run_loop();
    // Init
    this.ifc.tbm.cbm.dat_ms    <= 'd0;
    this.ifc.tbm.cbm.adr     <= 'd0;
    this.ifc.tbm.cbm.cyc     <= 1'b0;
    this.ifc.tbm.cbm.sel     <= 'd0;
    this.ifc.tbm.cbm.stb     <= 1'b0;
    this.ifc.tbm.cbm.we      <= 1'b0;
    this.ifc.tbm.cbm.cti     <= 3'b000 ;
    this.ifc.tbm.cbm.bte     <= 2'b00 ;
    this.burstCnt          = 0;
    // Start main loop
    forever begin
      this.trInBox.get(this.tr);
      // Clock alignment
      this.ifc.clockAlign();
      // Transaction decoder
      if(this.tr.TrType == WSHB_m_busTrans::IDLE) begin
        repeat(this.tr.idleCycles) @this.ifc.tbm.cbm;
      end else if(this.tr.TrType == WSHB_m_busTrans::WAIT)begin
        this.trOutBox.put(this.tr);
      end else if(this.tr.TrType == WSHB_m_busTrans::CFG_DELAY) begin
        // Set configuration. Random delays.
        this.maxBurst     = this.tr.maxBurst;
        this.minBurst     = this.tr.minBurst;
        this.minWait      = this.tr.minWait;
        this.maxWait      = this.tr.maxWait;
        this.burstCnt     = 0;
        this.burstDelayEn = this.tr.maxBurst;
        assert (this.randomize())
        else $fatal(0, "Wishbone Master: Init Randomize failed");
      end else if(this.tr.TrType == WSHB_m_busTrans::CFG_TIMEOUT) begin
        // Set configuration. Time outs.
        this.maxRetry   = this.tr.rtyTimeOut;
        this.ackTimeOut = this.tr.ackTimeOut;
      end else begin
        // Read/Write transaction.
        this.blockWrRd();
        if(this.tr.TrType == WSHB_m_busTrans::READ) begin
          this.trOutBox.put(this.tr);
        end
      end
    end
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- blockWrRd(): Generate Read or Write transaction.*/
  /////////////////////////////////////////////////////////////////////////////
  local task blockWrRd();
    WSHB_m_busTrans trErr;
    string tempStr;
    int retryCnt = 0;
    int ackCnt   = 0;
    this.ifc.tbm.cbm.cyc      <= 1'b1;
    this.ifc.tbm.cbm.stb      <= 1'b1;
    this.ifc.tbm.cbm.adr      <= this.tr.address;
    this.ifc.tbm.cbm.sel      <= this.tr.sel;
    this.ifc.tbm.cbm.dat_ms   <= this.tr.unpack2pack(this.tr.dataBlock);
    this.ifc.tbm.cbm.cti      <= this.tr.cti ;
    if(this.tr.TrType == WSHB_m_busTrans::WRITE) begin
      this.ifc.tbm.cbm.we       <= 1'b1;
    end else begin
      this.ifc.tbm.cbm.we      <= 1'b0;
    end
    // Wait for slave response.
    do begin
      // Wait for slave acknowledge.
      do begin
        @this.ifc.tbm.cbm;
        ackCnt++;
      end while(((this.ifc.tbm.cbm.ack !== 1'b1)&&(this.ifc.tbm.cbm.err !== 1'b1)&&
                (this.ifc.tbm.cbm.rty !== 1'b1))&&(ackCnt != this.ackTimeOut));
      // Check error signal.
      if(this.ifc.tbm.cbm.err == 1'b1) begin
        trErr = new();
        $display("Transaction Error Detected at sim time %0d", $time());
        tempStr.itoa($time);
        trErr.failedTr = "Transaction Error Detected at sim time ";
        trErr.failedTr     = {trErr.failedTr, tempStr, "ns"};
        this.statusBox.put(trErr);
        trErr = null;
        break;
      end
      // Check acknowledge timeout
      // if((this.ifc.tbm.cbm.ack == 1'b0) && (this.ifc.tbm.cbm.rty == 1'b0)) begin 
      // cor YM for correct X handling
      if((this.ifc.tbm.cbm.ack !== 1'b1) && (this.ifc.tbm.cbm.rty !== 1'b1)) begin
        trErr = new();
        $display("Transaction TimeOut Detected at sim time %0d", $time());
        tempStr.itoa($time);
        trErr.failedTr = "Transaction TimeOut Detected at sim time ";
        trErr.failedTr     = {trErr.failedTr, tempStr, "ns"};
        this.statusBox.put(trErr);
        trErr = null;
        break;
      end
      retryCnt++;
    end while((this.ifc.tbm.cbm.rty == 1'b1)&&((retryCnt-1) != this.maxRetry));
    // Check retry signal
    if(this.ifc.tbm.cbm.rty == 1'b1) begin
      trErr = new();
      $display("Unexpected Transaction Retry Detected at sim time %0d", $time());
      tempStr.itoa($time);
      trErr.failedTr = "Unexpected Transaction Retry Detected at sim time ";
      trErr.failedTr     = {trErr.failedTr, tempStr, "ns"};
      this.statusBox.put(trErr);
      trErr = null;
    end
    // Get data.
    this.tr.dataBlock         = this.tr.pack2unpack(this.ifc.tbm.cbm.dat_sm);
    if(this.tr.lastBlock == 1) begin
      this.ifc.tbm.cbm.cyc       <= 1'b0;
    end
    this.ifc.tbm.cbm.stb         <= 1'b0;
    // Random timing control.
    if((this.burstDelayEn != 0) && (this.maxBurstLen != 0))begin
      this.burstCnt            = this.burstCnt + 1;
    end
    if((this.burstCnt == this.maxBurstLen) && (this.burstDelayEn != 0)) begin
      if(this.maxBurstLen != 0) repeat(waitCycles) @this.ifc.tbm.cbm;
      assert (this.randomize())
      else $fatal(0, "Wishbone Master: Randomize failed");
      this.burstCnt           = 0;
    end
    //
  endtask
  //
endclass // WSHB_m_busBFM
///////////////////////////////////////////////////////////////////////////////
// Class WSHB_m_env:
///////////////////////////////////////////////////////////////////////////////
class WSHB_m_env #(type virtual_wshb_master_type) extends WSHB_m_busBFM #(virtual_wshb_master_type);
  /////////////////////////////////////////////////////////////////////////////
  //************************ Class Variables ********************************//
  /////////////////////////////////////////////////////////////////////////////
  local WSHB_m_busTrans tr;
  // "TrNum": Is storing transactions count during all simulation time.
  local int TrNum           = 0;
  local int envStarted      = 0;
  /////////////////////////////////////////////////////////////////////////////
  //************************* Class Methods *********************************//
  /////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////
  /*- new(): Takes physical interface as an input value and connects it to
  // virtual interface. Creates transaction mailboxes.*/
  /////////////////////////////////////////////////////////////////////////////
  function new(virtual_wshb_master_type ifc) ;
    super.ifc              = ifc;
    super.trInBox          = new();
    super.trOutBox         = new();
    super.statusBox        = new();
    super.blockSize        = $size(ifc.tbm.cbm.dat_sm) >> 3 ;
  endfunction
  /////////////////////////////////////////////////////////////////////////////
  /*- startEnv(): Start BFM. Only after this task transactions will appear on
  //  the bus.*/
  /////////////////////////////////////////////////////////////////////////////
  task startEnv();
    if(envStarted == 0) begin
      super.startBFM();
      this.envStarted = 1;
    end
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- setRndDelay(): Set/Disable bus random delays. To disable delays set all
  //  arguments zero.*/
  /////////////////////////////////////////////////////////////////////////////
  task setRndDelay(int minBurst=0, maxBurst=0, minWait=0, maxWait=0);
    this.tr              = new();
    this.tr.TrType       = WSHB_m_busTrans::CFG_DELAY;
    this.tr.minBurst     = minBurst;
    this.tr.maxBurst     = maxBurst;
    this.tr.minWait = minWait;
    this.tr.maxWait = maxWait;
    super.trInBox.put(this.tr);
    this.tr              = null;
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- setTimeOut(): Set acknowledge timeout and max retry cycles.*/
  /////////////////////////////////////////////////////////////////////////////
  task setTimeOut(int ackTimeOut=0, rtyTimeOut=0);
    this.tr              = new();
    this.tr.TrType       = WSHB_m_busTrans::CFG_TIMEOUT;
    this.tr.ackTimeOut   = ackTimeOut;
    this.tr.rtyTimeOut   = rtyTimeOut;
    super.trInBox.put(this.tr);
    this.tr              = null;
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- busIdle(): Hold bus in idle for the specified clock cycles.*/
  /////////////////////////////////////////////////////////////////////////////
  task busIdle(int idleCycles);
    this.tr             = new();
    this.tr.TrType      = WSHB_m_busTrans::IDLE;
    this.tr.idleCycles  = idleCycles;
    super.trInBox.put(this.tr);
    this.tr             = null;
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- writeData(): Send data buffer. Start address will be incremented after
  // each transaction.*/
  /////////////////////////////////////////////////////////////////////////////
  task writeData(bit32 addr, bit8 inBuff[$], bit selBuff[$], burst_tags burstMode);
    int byteSel = 0;
    bit firstBlock = 1;
    bit8 selBlock ;
    for(int i = 0; 0 == super.blockSize[i]; i++) begin
      byteSel[i]         = 1'b1;
    end
    //
    while(inBuff.size() != 0) begin
      this.tr = new();
      this.TrNum++;
      this.tr.sel     = 8'h00;
      this.tr.cti     = 3'b000 ;
      this.tr.address = addr & (~byteSel);
      for(int j = addr&byteSel; j < super.blockSize; j++) begin
        this.tr.dataBlock[j] = inBuff.pop_front();
        if(firstBlock || (burstMode == without_burst_tags))
           selBlock[j] = selBuff.pop_front();
        this.tr.lastBlock = 0;
        addr++;
        if(inBuff.size() == 0) begin
          this.tr.lastBlock = 1;
          break;
        end
      end
      this.tr.sel = selBlock;
      // compute tags for burst transaction
      if(burstMode == with_burst_tags) begin
        if(this.tr.lastBlock)
           this.tr.cti = 3'b111 ;
        else
           this.tr.cti  = 3'b010 ;
      end
      //
      this.tr.TrType    = WSHB_m_busTrans::WRITE;
      super.trInBox.put(this.tr);
      this.tr = null;
      firstBlock = 0 ;
    end
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- readData(): Read data buffer.Start address will be incremented after
  //  each transaction.*/
  // refBuff is used to give the value of the selection bits
  /////////////////////////////////////////////////////////////////////////////
  task readData(bit32 addr, output bit8 outBuff[$], input bit selBuff[$], input bit32 dataLength, burst_tags burstMode);
    int byteSel = 0;
    bit32 last_addr ;
    bit firstBlock = 1;
    bit8 selBlock ;
    outBuff.delete();
    for(int i = 0; 0 == super.blockSize[i]; i++) begin
      byteSel[i]         = 1'b1;
    end
    //
    while(dataLength != 0) begin
      this.tr = new();
      this.TrNum++;
      this.tr.sel     = 8'h00;
      this.tr.address = addr & (~byteSel);
      this.tr.cti     = 3'b000 ;
      last_addr = addr ;
      for(int j = addr&byteSel; j < super.blockSize; j++) begin
        if(firstBlock || (burstMode == without_burst_tags))
           selBlock[j] = selBuff.pop_front();
        addr++;
        dataLength--;
        this.tr.lastBlock   = 0;
        if(dataLength == 0) begin
          this.tr.lastBlock = 1;
          break;
        end
      end
      this.tr.sel = selBlock;
      //
      // compute tags for burst transaction
      if(burstMode==with_burst_tags) begin
        if(this.tr.lastBlock)
           this.tr.cti = 3'b111 ;
        else
           this.tr.cti  = 3'b010 ;
      end
      this.tr.TrType    = WSHB_m_busTrans::READ;
      super.trInBox.put(this.tr);
      super.trOutBox.get(this.tr);
      for(int j = last_addr&byteSel; j < blockSize; j++) begin
          outBuff = {outBuff, this.tr.dataBlock[j]};
      end
      this.tr = null;
      firstBlock = 0 ;
    end
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- pollData(): Poll specified address until read data buffer is equal to
  // pollData buffer. If poll counter is reached to "pollTimeOut" value
  // stop polling and generate error message. Poll counter is incremented after
  // each clock.*/
  /////////////////////////////////////////////////////////////////////////////
task pollData(input bit32 address, bit8 pollData[$], bit32 pollTimeOut = 1000000);
    bit8 dataBuff[$];
    int status;
    string tempStr;
    bit selBuff[$] = {} ;
    $display("Polling address 0x%h: @sim time %0d", address, $time);
    // Create a selection mask
    selBuff = {} ;
    for (int i = 0; i < pollData.size(); i++) selBuff.push_back(1'b1) ; 

    fork: poll
      begin
        repeat(pollTimeOut) @super.ifc.tbm.cbm;
        this.tr = new();
        $display("Poll Time Out Detected at sim time %0d", $time());
        tempStr.itoa($time);
        this.tr.failedTr     = "Poll TimeOut detected. At simulation time ";
        this.tr.failedTr     = {this.tr.failedTr, tempStr, "ns"};
        super.statusBox.put(this.tr);
        this.tr = null;
      end
      begin
        do begin
          this.readData(address, dataBuff, selBuff, pollData.size(), without_burst_tags);
          status = 0;
          for(int i = 0; i < pollData.size(); i++) begin
            if((dataBuff[i] != pollData[i]) ) begin
              status = 1;
              break;
            end
          end
        end while(status == 1);
        $display("Poll Done!");
      end
    join_any
    disable poll;
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- waitCommandDone(): Wait until all instructions in the input mailbox are
  //  finished.*/
  /////////////////////////////////////////////////////////////////////////////
  task waitCommandDone();
    this.tr         = new();
    this.tr.TrType  = WSHB_m_busTrans::WAIT;
    this.trInBox.put(this.tr);
    this.trOutBox.get(this.tr);
    this.tr = null;
  endtask
  /////////////////////////////////////////////////////////////////////////////
  /*- printStatus(): Print all errors if there are any and
  // return errors count. Otherwise return 0.*/
  /////////////////////////////////////////////////////////////////////////////
  function int printStatus();
    this.tr = new();
    printStatus = this.statusBox.num();
    while(this.statusBox.num() != 0)begin
      void'(this.statusBox.try_get(this.tr));
      $display(this.tr.failedTr);
    end
    this.tr = null;
  endfunction
  //
endclass // WSHB_m_env
//
endpackage
