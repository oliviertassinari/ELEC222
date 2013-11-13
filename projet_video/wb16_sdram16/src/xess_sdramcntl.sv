////////////////////////////////////////////////////////////////////
// Company : XESS Corp.
// Engineer : Dave Vanden Bout
// Creation Date : 05/17/2005
// Copyright : 2005, XESS Corp
// Tool Versions : WebPACK 6.3.03i
//
// Description:
// SDRAM controller
//
// Revision:
// 1.4.0
//
// Additional Comments:
// 1.4.0:
// Added generic parameter to enable/disable independent active rows in each bank.
// 1.3.0:
// Modified to allow independently active rows in each bank.
// 1.2.0:
// Modified to allow pipelining of read/write operations.
// 1.1.0:
// Initial release.
//
// License:
// This code can be freely distributed and modified as long as
// this header is not removed.
////////////////////////////////////////////////////////////////////
// TPT/YM adptation to SystemVerilog 32bit datas
// TPT/YM added latency choice for cas
// TPT/YM support of byte enable for writing
// TPT/YM local clogb2 function for Precision Synthesis support
// TPT/YM introduce "DATA_BYTES" parameter and computes bus widths from this value
//        in order to allow usage of 32bits or 16 bits memories
// TPT/YM fixed :  DQM should be "1" during powerup phase
// TPT/YM : timing adjusted to IS42S16400B-7 or A2V64S40CTP-G7 chips of DE2 BOARDS


module xess_sdramcntl
    #(
    parameter int unsigned FREQ                 =  100_000, // operating frequency in KHz
    parameter bit          IN_PHASE             =  1'b0,    // SDRAM and controller work on same or opposite clock edge
    parameter bit          PIPE_EN              =  1'b1,    // if true, enable pipelined read operations
    parameter int unsigned MAX_NOP              =  10000,   // number of NOPs before entering self-refresh
    parameter bit          MULTIPLE_ACTIVE_ROWS =  1'b1,    // if true, allow an active row in each bank
    parameter int unsigned DATA_BYTES           =  4,       // host & SDRAM data width
    parameter int unsigned NROWS                =  2048,    // number of rows in SDRAM array
    parameter int unsigned NCOLS                =  256,     // number of columns in SDRAM array
    parameter int unsigned HADDR_WIDTH          =  21,      // host-side address width
    parameter int unsigned SADDR_WIDTH          =  11,      // SDRAM-side address width
    parameter int unsigned BA_WIDTH             =  2,        // Bank address width
    parameter int unsigned CAS_CYCLES           =  3        // CAS latency
    )
    (
    // host side
    input  logic                     clk          , // master clock
    input  logic                     lock         , // true if clock is stable
    input  logic                     rst          , // reset
    input  logic                     rd           , // initiate read operation
    input  logic                     wr           , // initiate write operation
    output logic                     earlyOpBegun , // read/write/self-refresh op has begun (async)
    output logic                     opBegun      , // read/write/self-refresh op has begun (clocked)
    output logic                     rdPending    , // true if read operation(s) are still in the pipeline
    output logic                     done         , // read or write operation is done
    output logic                     rdDone       , // read operation is done and data is available
    input  logic [HADDR_WIDTH-1:0]   hAddr        , // address from host to SDRAM
    input  logic [8*DATA_BYTES-1:0]  hDIn         , // data from host to SDRAM
    input  logic [DATA_BYTES-1:0]    hSel         , // Byte enable
    output logic [8*DATA_BYTES-1:0]  hDOut        , // data from SDRAM to host
    output logic [3:0]               status       , // diagnostic status of the FSM

    // SDRAM side
    output logic cke                       , // clock-enable to SDRAM
    output logic cs_n                      , // chip-select to SDRAM
    output logic ras_n                     , // SDRAM row address strobe
    output logic cas_n                     , // SDRAM column address strobe
    output logic we_n                      , // SDRAM write enable
    output logic [BA_WIDTH-1:0] ba         , // SDRAM bank address
    output logic [SADDR_WIDTH-1:0] sAddr   , // SDRAM row/column address
    input  wire [8*DATA_BYTES-1:0]  sD     , // data from SDRAM
    output wire [8*DATA_BYTES-1:0]  sQ     , // data from SDRAM
    output logic [DATA_BYTES-1:0] dqm        // enable bytes of SDRAM databus if true
    ) ;

  localparam int unsigned DATA_WIDTH           =  8*DATA_BYTES ;      // host & SDRAM data width

  localparam bit OUTPUT = 1'b1;   // direction of dataflow w.r.t. this controller
  localparam bit INPUT  = 1'b0;
  localparam bit NOP    = 1'b0;   // no operation
  localparam bit READ   = 1'b1;   // read operation
  localparam bit WRITE  = 1'b1;   // write operation
  localparam bit YES    = 1'b1;
  localparam bit NO     = 1'b0;
  localparam bit HI     = 1'b1;
  localparam bit LO     = 1'b0;
  localparam bit ONE    = 1'b1;
  localparam bit ZERO   = 1'b0;


  // SDRAM timing parameters
  localparam int unsigned Tinit = 200;      // min initialization interval (us)
  localparam int unsigned Tras  = 45;       // min interval between active to precharge commands (ns)
  localparam int unsigned Trcd  = 21;       // min interval between active and R/W commands (ns)
  localparam int unsigned Tref  = 64_000_000;  // maximum refresh interval (ns)
  localparam int unsigned Trfc  = 68;       // duration of refresh operation (ns)
  localparam int unsigned Trp   = 21;       // min precharge command duration (ns)
  localparam int unsigned Twr   = 15;       // write recovery time (ns)
  localparam int unsigned Txsr  = 68;       // exit self-refresh time (ns)

  // SDRAM timing parameters converted into clock cycles (based on FREQ)
  localparam int unsigned NORM         = 1_000_000;  // normalize ns * KHz
  localparam int unsigned INIT_CYCLES  = 1+((Tinit*FREQ)/1000);  // SDRAM power-on initialization interval
  localparam int unsigned RAS_CYCLES   = 1+((Tras*FREQ)/NORM);  // active-to-precharge interval
  localparam int unsigned RCD_CYCLES   = 1+((Trcd*FREQ)/NORM);  // active-to-R/W interval
  localparam int unsigned REF_CYCLES   = 1+(((Tref/NROWS)*FREQ)/NORM);  // interval between row refreshes
  localparam int unsigned RFC_CYCLES   = 1+((Trfc*FREQ)/NORM);  // refresh operation interval
  localparam int unsigned RP_CYCLES    = 1+((Trp*FREQ)/NORM);  // precharge operation interval
  localparam int unsigned WR_CYCLES    = 1+((Twr*FREQ)/NORM);  // write recovery time
  localparam int unsigned XSR_CYCLES   = 1+((Txsr*FREQ)/NORM);  // exit self-refresh time
  localparam int unsigned MODE_CYCLES  = 2;  // mode register setup time
  localparam int unsigned RFSH_OPS     = 8;  // number of refresh operations needed to init SDRAM

// For clogb2 handling by Precision Synthesis
function integer clogb2;
input [31:0]  value;
begin
  int i ;
  if ((value == 0) || (value == 1)) clogb2 = 0 ;
  else
    begin
    value = value-1 ;
    for (i = 0; i < 32; i++)
      if (value[i]) clogb2 = i+1 ;
  end
end
endfunction

  localparam timer_size = clogb2(INIT_CYCLES+1) ;
  localparam rasTimer_size = clogb2(RAS_CYCLES+1) ;
  localparam wrTimer_size = clogb2(WR_CYCLES+1) ;
  localparam refTimer_size = clogb2(REF_CYCLES+1) ;
  localparam rfshCntr_size = clogb2(NROWS+1) ;
  localparam nopCntr_size = clogb2(MAX_NOP+1) ;

  // timer registers that count down times for various SDRAM operations
  logic [timer_size-1:0]  timer_r, timer_x       ;  // current SDRAM op time
  logic [rasTimer_size-1:0]   rasTimer_r, rasTimer_x ;   // active-to-precharge time
  logic [wrTimer_size-1:0]    wrTimer_r, wrTimer_x   ;    // write-to-precharge time
  logic [refTimer_size-1:0]   refTimer_r, refTimer_x ;   // time between row refreshes
  logic [rfshCntr_size-1:0]        rfshCntr_r, rfshCntr_x ;        // counts refreshes that are neede
  logic [nopCntr_size-1:0]      nopCntr_r, nopCntr_x   ;      // counts consecutive NOP operations

  logic doSelfRfsh ;        // active when the NOP counter hits zero and self-refresh can start

  // states of the SDRAM controller state machine
  typedef enum  {
    INITWAIT,                           // initialization - waiting for power-on initialization to complete
    INITPCHG,                           // initialization - initial precharge of SDRAM banks
    INITSETMODE,                        // initialization - set SDRAM mode
    INITRFSH,                           // initialization - do initial refreshes
    RW,                                 // read/write/refresh the SDRAM
    ACTIVATE,                           // open a row of the SDRAM for reading/writing
    REFRESHROW,                         // refresh a row of the SDRAM
    SELFREFRESH                         // keep SDRAM in self-refresh mode with CKE low
    } cntlState ;
  cntlState state_r, state_x ;  // state register and next state

  // commands that are sent to the SDRAM to make it perform certain operations
  // commands use these SDRAM input pins (cs_n,ras_n,cas_n,we_n,dqm)
  typedef logic[4+DATA_BYTES-1:0]  sdramCmd ;
  //localparam sdramCmd NOP_CMD    = {4'b0111,{DATA_BYTES{1'b1}}} ;
  localparam sdramCmd NOP_CMD    = {4'b0111,{DATA_BYTES{1'b1}}} ;
  localparam sdramCmd ACTIVE_CMD = {4'b0011,{DATA_BYTES{1'b0}}} ;
  localparam sdramCmd READ_CMD   = {4'b0101,{DATA_BYTES{1'b0}}} ;
  localparam sdramCmd WRITE_CMD  = {4'b0100,{DATA_BYTES{1'b0}}} ;
  localparam sdramCmd PCHG_CMD   = {4'b0010,{DATA_BYTES{1'b1}}} ;
  localparam sdramCmd MODE_CMD   = {4'b0000,{DATA_BYTES{1'b1}}} ;
  localparam sdramCmd RFSH_CMD   = {4'b0001,{DATA_BYTES{1'b1}}} ;

  // SDRAM mode register
  typedef logic[11:0] sdramMode ;
  // the SDRAM is placed in a non-burst mode (burst length = 1) with a 3-cycle CAS
  //localparam sdramMode MODE = {2'b00, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000};
  //YM the SDRAM is placed in a non-burst mode (burst length = 1) with a 2-cycle CAS
  localparam sdramMode MODE = {2'b00, 1'b0, 2'b00, 3'b010, 1'b0, 3'b000};

  // the host address is decomposed into these sets of SDRAM address components
  localparam int unsigned  ROW_LEN = clogb2(NROWS);  // number of row address bits
  localparam int unsigned  COL_LEN = clogb2(NCOLS);  // number of column address bits
  logic [BA_WIDTH-1:0] bank ;  // bank address bits
  logic [ROW_LEN - 1:0] row ;  // row address within bank
  logic [SADDR_WIDTH-1:0] col;  // column address within row

  // registers that store the currently active row in each bank of the SDRAM
  localparam int  NUM_ACTIVE_ROWS = MULTIPLE_ACTIVE_ROWS ? 2**BA_WIDTH : 1 ;
  typedef logic[ROW_LEN-1:0]  activeRowType  [0:NUM_ACTIVE_ROWS-1]  ;
  activeRowType  activeRow_r, activeRow_x  ;
  logic [0:NUM_ACTIVE_ROWS-1] activeFlag_r, activeFlag_x ;  // indicates that some row in a bank is active
  logic [clogb2(NUM_ACTIVE_ROWS)-1:0] bankIndex;                    // bank address bits
//  logic  [BA_WIDTH-1:0] activeBank_r, activeBank_x;   // indicates the bank with the active row
// YM/TPT one extra bit for initial non active condition
  logic  [BA_WIDTH:0] activeBank_r, activeBank_x;   // indicates the bank with the active row
  logic                               doActivate;                   // indicates when a new row in a bank needs to be activated

  // there is a command bit embedded within the SDRAM column address
  localparam int unsigned CMDBIT_POS  = 10;  // position of command bit
  localparam logic AUTO_PCHG_ON  = 1'b1;  // CMDBIT value to auto-precharge the bank
  localparam logic AUTO_PCHG_OFF = 1'b0;  // CMDBIT value to disable auto-precharge
  localparam logic ONE_BANK      = 1'b0;  // CMDBIT value to select one bank
  localparam logic ALL_BANKS     = 1'b1;  // CMDBIT value to select all banks

  // status signals that indicate when certain operations are in progress
  logic wrInProgress       ;  // write operation in progress
  logic rdInProgress       ;  // read operation in progress
  logic activateInProgress ;  // row activation is in progress

  // these registers track the progress of read and write operations
  logic [CAS_CYCLES+1:0] rdPipeline_r, rdPipeline_x ;  // pipeline of read ops in progress
  logic [0:0]            wrPipeline_r, wrPipeline_x ;  // pipeline of write ops (only need 1 cycle)

  // registered outputs to host
  logic opBegun_r, opBegun_x             ;   // true when SDRAM read or write operation is started
  logic [DATA_WIDTH-1:0] hDOut_r, hDOut_x                 ;   // holds data read from SDRAM and sent to the host
  logic [DATA_WIDTH-1:0] hDOutOppPhase_r, hDOutOppPhase_x ;   // holds data read from SDRAM   on opposite clock edge

  // registered outputs to SDRAM
  logic cke_r, cke_x ;    // clock enable
  sdramCmd cmd_r, cmd_x ;    // SDRAM command bits
  logic [BA_WIDTH-1:0] ba_r, ba_x  ;    // SDRAM bank address bits
  logic [SADDR_WIDTH-1:0] sAddr_r, sAddr_x ;    // SDRAM row/column address
  logic [DATA_WIDTH-1:0]  sData_r, sData_x       ;    // SDRAM out databus
  //logic sDataDir_r, sDataDir_x ;    // SDRAM databus direction control bit

  // SDRAM tristate data bus
  logic [DATA_WIDTH-1:0] sDIn    ;   // data from SDRAM
  logic [DATA_WIDTH-1:0] sDOut   ;    // data to SDRAM


  //////////////////////////////////////////////////////////-
  // attach some internal signals to the I/O ports
  //////////////////////////////////////////////////////////-

  // attach registered SDRAM control signals to SDRAM input pins
  assign {cs_n, ras_n, cas_n, we_n, dqm} = cmd_r;  // SDRAM operation control bits
  assign cke                                    = cke_r;  // SDRAM clock enable
  assign ba                                     = ba_r;  // SDRAM bank address
  assign sAddr                                  = sAddr_r;  // SDRAM address
  assign sDOut                                  = sData_r;  // SDRAM output data bus

  // attach some port signals
  assign hDOut   = hDOut_r;                   // data back to host
  assign opBegun = opBegun_r;                 // true if requested operation has begun
  assign earlyOpBegun = opBegun_x;


  //////////////////////////////////////////////////////////-
  // compute the next state and outputs
  //////////////////////////////////////////////////////////-

  always @( * )
  begin

    //////////////////////////////////////////////////////////-
    // setup default values for signals
    //////////////////////////////////////////////////////////-

    opBegun_x    <= NO;                 // no operations have begun
    cke_x        <= YES;                // enable SDRAM clock
    cmd_x        <= NOP_CMD;            // set SDRAM command to no-operation
    //sDataDir_x   <= INPUT;              // accept data from the SDRAM
    sData_x      <= hDIn[DATA_WIDTH-1:0];  // output data from host to SDRAM
    state_x      <= state_r;            // reload these registers and flags
    activeFlag_x <= activeFlag_r;       //              with their existing values
    activeRow_x  <= activeRow_r;
    activeBank_x <= activeBank_r;
    rfshCntr_x   <= rfshCntr_r;

    //////////////////////////////////////////////////////////-
    // setup default value for the SDRAM address
    //////////////////////////////////////////////////////////-

    // extract bank field from host address
    ba_x                    = hAddr[$size(ba) + ROW_LEN + COL_LEN - 1:ROW_LEN + COL_LEN];
    if (MULTIPLE_ACTIVE_ROWS)
    begin
      bank                  <= '0;
      bankIndex             <= ba_x;
    end
    else
    begin
      bank                  <= ba_x;
      bankIndex             <= '0;
    end
    // extract row, column fields from host address
    row                     = hAddr[ROW_LEN + COL_LEN - 1:COL_LEN];
    // extend column (if needed) until it is as large as the (SDRAM address bus - 1)
    col                     = '0;  // set it to all zeroes
    col[COL_LEN-1:0]        = hAddr[COL_LEN-1:0];
    // by default, set SDRAM address to the column address with interspersed
    // command bit set to disable auto-precharge
    //ORIGINAL sAddr_x  <= { col[SADDR_WIDTH-2:CMDBIT_POS] , AUTO_PCHG_OFF , col[CMDBIT_POS-1:0] };
    // TPT
    sAddr_x  <= { AUTO_PCHG_OFF , col[CMDBIT_POS-1:0] };


    //////////////////////////////////////////////////////////-
    // manage the read and write operation pipelines
    //////////////////////////////////////////////////////////-

    // determine if read operations are in progress by the presence of
    // READ flags in the read pipeline
    rdInProgress <= (rdPipeline_r[$high(rdPipeline_r):1] != 0)  ;
    rdPending      <= rdInProgress;     // tell the host if read operations are in progress

    // enter NOPs into the read and write pipeline shift registers by default
    rdPipeline_x    <= {NOP , rdPipeline_r[$high(rdPipeline_r):1]};
    wrPipeline_x[0] <= NOP;

    // transfer data from SDRAM to the host data register if a read flag has exited the pipeline
    // (the transfer occurs 1 cycle before we tell the host the read operation is done)
    if (rdPipeline_r[1] == READ)
    begin
      hDOutOppPhase_x <= sDIn[DATA_WIDTH-1:0];  // gets value on the SDRAM databus on the opposite phase
      if (IN_PHASE)
        // get the SDRAM data for the host directly from the SDRAM if the controller and SDRAM are in-phase
        hDOut_x       <= sDIn[DATA_WIDTH-1:0];
      else
        // otherwise get the SDRAM data that was gathered on the previous opposite clock edge
        hDOut_x       <= hDOutOppPhase_r[DATA_WIDTH-1:0];
    end
    else
    begin
      // retain contents of host data registers if no data from the SDRAM has arrived yet
      hDOutOppPhase_x <= hDOutOppPhase_r;
      hDOut_x         <= hDOut_r;
    end

    done   <= rdPipeline_r[0] || wrPipeline_r[0];  // a read or write operation is done
    rdDone <= rdPipeline_r[0];          // SDRAM data available when a READ flag exits the pipeline

    //////////////////////////////////////////////////////////-
    // manage row activation
    //////////////////////////////////////////////////////////-

    // request a row activation operation if the row of the current address
    // does not match the currently active row in the bank, or if no row
    // in the bank is currently active
    //doActivate <= (bank != activeBank_r) || (row != activeRow_r[bankIndex]) || (!activeFlag_r[bankIndex]) ;
    // YM/TPT added one bit extension to activeBank_r for initial conditions
    doActivate <= ({1'b0,bank} != activeBank_r) || (row != activeRow_r[bankIndex]) || (!activeFlag_r[bankIndex]) ;

    //////////////////////////////////////////////////////////-
    // manage self-refresh
    //////////////////////////////////////////////////////////-

    // enter self-refresh if neither a read or write is requested for MAX_NOP consecutive cycles.
    if (rd || wr)
    begin
      // any read or write resets NOP counter and exits self-refresh state
      nopCntr_x  <= 0;
      doSelfRfsh <= NO;
    end
    else if (nopCntr_r != MAX_NOP )
    begin
      // increment NOP counter whenever there is no read or write operation
      nopCntr_x  <= nopCntr_r + 1'b1;
      doSelfRfsh <= NO;
    end
    else
    begin
      // start self-refresh when counter hits maximum NOP count and leave counter unchanged
      nopCntr_x  <= nopCntr_r;
      doSelfRfsh <= YES;
    end

    //////////////////////////////////////////////////////////-
    // update the timers
    //////////////////////////////////////////////////////////-

    // row activation timer
    if ( rasTimer_r != 0)
    begin
      // decrement a non-zero timer and set the flag
      // to indicate the row activation is still inprogress
      rasTimer_x         <= rasTimer_r - 1'b1;
      activateInProgress <= YES;
    end
    else
    begin
      // on timeout, keep the timer at zero     and reset the flag
      // to indicate the row activation operation is done
      rasTimer_x         <= rasTimer_r;
      activateInProgress <= NO;
    end

    // write operation timer
    if (wrTimer_r != 0)
    begin
      // decrement a non-zero timer and set the flag
      // to indicate the write operation is still inprogress
      wrTimer_x    <= wrTimer_r - 1'b1;
      wrInProgress <= YES;
    end
    else
    begin
      // on timeout, keep the timer at zero and reset the flag that
      // indicates a write operation is in progress
      wrTimer_x    <= wrTimer_r;
      wrInProgress <= NO;
    end

    // refresh timer
    if (refTimer_r != 0)
      refTimer_x <= refTimer_r - 1'b1;
    else
    begin
      // on timeout, reload the timer with the interval between row refreshes
      // and increment the counter for the number of row refreshes that are needed
      refTimer_x <= (refTimer_size)'(REF_CYCLES);
      rfshCntr_x <= rfshCntr_r + 1'b1;
    end

    // main timer for sequencing SDRAM operations
    if (timer_r != 0)
    begin
      // decrement the timer and do nothing else since the previous operation has not completed yet.
      timer_x <= timer_r - 1'b1;
      status  <= 4'b0000;
    end
    else
    begin
      // the previous operation has completed once the timer hits zero
      timer_x <= timer_r;               // by default, leave the timer at zero

      //////////////////////////////////////////////////////////-
      // compute the next state and outputs
      //////////////////////////////////////////////////////////-
      case (state_r)

        //////////////////////////////////////////////////////////-
        // let clock stabilize and) wait for the SDRAM to initialize
        //////////////////////////////////////////////////////////-
        INITWAIT:
     begin
          if (lock)
       begin
            timer_x <= (timer_size)'(INIT_CYCLES);     // set timer for initialization duration
            state_x <= INITPCHG;
       end
          else
            cke_x   <= NO;
                                        // disable SDRAM clock and return to this state if (the clock is not stable
                                        // this insures the clock is stable before enabling the SDRAM
                                        // it also insures a clean startup if (the SDRAM is currently in self-refresh mode
          status    <= 4'b0001;
          end
          //////////////////////////////////////////////////////////-
          // precharge all SDRAM banks after power-on initialization
          //////////////////////////////////////////////////////////-
        INITPCHG:
     begin
          cmd_x               <= PCHG_CMD;
          sAddr_x[CMDBIT_POS] <= ALL_BANKS;  // precharge all banks
          timer_x             <= (timer_size)'(RP_CYCLES);  // set timer for precharge operation duration
          rfshCntr_x          <= (rfshCntr_size)'(RFSH_OPS);  // set counter for refresh ops needed after precharge
          state_x             <= INITRFSH;
          status              <= 4'b0010;
          end

          //////////////////////////////////////////////////////////-
          // refresh the SDRAM a number of times after initial precharge
          //////////////////////////////////////////////////////////-
        INITRFSH:
     begin
          cmd_x      <= RFSH_CMD;
          timer_x    <= (timer_size)'(RFC_CYCLES);     // set timer to refresh operation duration
          rfshCntr_x <= rfshCntr_r - 1'b1;  // decrement refresh operation counter
          if (rfshCntr_r == 1) state_x  <= INITSETMODE;    // set the SDRAM mode once all refresh ops are done
          status     <= 4'b0011;
          end

          //////////////////////////////////////////////////////////-
          // set the mode register of the SDRAM
          //////////////////////////////////////////////////////////-
        INITSETMODE:
     begin
          cmd_x   <= MODE_CMD;
          sAddr_x <= MODE;              // output mode register bits on the SDRAM address bits
          timer_x <= (timer_size)'(MODE_CYCLES);       // set timer for mode setting operation duration
          state_x <= RW;
          status  <= 4'b0100;
          end

          //////////////////////////////////////////////////////////-
          // process read/write/refresh operations after initialization is done
          //////////////////////////////////////////////////////////-
        RW:
     begin
          //////////////////////////////////////////////////////////-
          // highest priority operation: row refresh
          // do a refresh operation if (the refresh counter is non-zero
          //////////////////////////////////////////////////////////-
          if (rfshCntr_r != 0)
     begin
                                        // wait for any row activations, writes or reads to finish before doing a precharge
            if ((!activateInProgress) && (!wrInProgress) && (!rdInProgress))
       begin
              cmd_x                       <= PCHG_CMD;  // initiate precharge of the SDRAM
              sAddr_x[CMDBIT_POS]         <= ALL_BANKS;  // precharge all banks
              timer_x                     <= (timer_size)'(RP_CYCLES);  // set timer for this operation
              activeFlag_x                <= '0 ;  // all rows are inactive after a precharge operation
              state_x                     <= REFRESHROW;  // refresh the SDRAM after the precharge
            end
            status                        <= 4'b0101;
     end
            //////////////////////////////////////////////////////////-
            // do a host-initiated read operation
            //////////////////////////////////////////////////////////-
          else if (rd)
          begin                 // Wait one clock cycle if (the bank address has just changed and each bank has its own active row.
            // This gives extra time for the row activation circuitry.
            if ((ba_x == ba_r) || (!MULTIPLE_ACTIVE_ROWS))
            begin                          // activate a new row if (the current read is outside the active row or bank
              if (doActivate)
              begin                        // activate new row only if (all previous activations, writes, reads are done
                if ((!activateInProgress) && (!wrInProgress) && (!rdInProgress))
      begin
                  cmd_x                   <= PCHG_CMD;  // initiate precharge of the SDRAM
                  sAddr_x[CMDBIT_POS]     <= ONE_BANK;  // precharge this bank
                  timer_x                 <= (timer_size)'(RP_CYCLES);  // set timer for this operation
                  activeFlag_x[bankIndex] <= NO;  // rows in this bank are inactive after a precharge operation
                  state_x                 <= ACTIVATE;  // activate the new row after the precharge is done
                end ;
              end
                                        // read from the currently active row if (no previous read operation
                                        // is in progress or if (pipeline reads are enabled
                                        // we can always initiate a read even if (a write is already in progress
              else if ((!rdInProgress) || PIPE_EN)
         begin
                cmd_x                     <= READ_CMD;  // initiate a read of the SDRAM
                                        // insert a flag into the pipeline shift register that will exit the end
                                        // of the shift register when the data from the SDRAM is available
                rdPipeline_x              <= { READ , rdPipeline_r[$high(rdPipeline_r):1]};
                opBegun_x                 <= YES;  // tell the host the requested operation has begun
              end
            end
            status                        <= 4'b0110;
     end
            //////////////////////////////////////////////////////////-
            // do a host-initiated write operation
            //////////////////////////////////////////////////////////-
          else if (wr)
     begin
            // Wait one clock cycle if (the bank address has just changed and each bank has its own active row.
            // This gives extra time for the row activation circuitry.
            if ((ba_x == ba_r) || (!MULTIPLE_ACTIVE_ROWS))
            begin                          // activate a new row if (the current write is outside the active row or bank
              if (doActivate)
              begin                        // activate new row only if (all previous activations, writes, reads are done
                if ((!activateInProgress) && (!wrInProgress) && (!rdInProgress))
      begin
                  cmd_x                   <= PCHG_CMD;  // initiate precharge of the SDRAM
                  sAddr_x[CMDBIT_POS]     <= ONE_BANK;  // precharge this bank
                  timer_x                 <= (timer_size)'(RP_CYCLES);  // set timer for this operation
                  activeFlag_x[bankIndex] <= NO;  // rows in this bank are inactive after a precharge operation
                  state_x                 <= ACTIVATE;  // activate the new row after the precharge is done
                end
              end                          // write to the currently active row if (no previous read operations are in progress
              else if (!rdInProgress)
         begin
           // YM/TPT adaptation to byte enable writes
                cmd_x                     <= WRITE_CMD | {4'b0000 , ~hSel};  // initiate the write operation TPT/YM
                //sDataDir_x                <= OUTPUT;  // turn on drivers to send data to SDRAM
                                        // set timer so precharge doesn't occur too soon after write operation
                wrTimer_x                 <= (wrTimer_size)'(WR_CYCLES);
                                        // insert a flag into the 1-bit pipeline shift register that will exit on the
                                        // next cycle.  The write into SDRAM is not actually done by that time, but
                                        // this doesn't matter to the host
                wrPipeline_x[0]           <= WRITE;
                opBegun_x                 <= YES;  // tell the host the requested operation has begun
              end
            end
            status                        <= 4'b0111;
     end
            //////////////////////////////////////////////////////////-
            // do a host-initiated self-refresh operation
            //////////////////////////////////////////////////////////-
          else if (doSelfRfsh)
     begin
            // wait until all previous activations, writes, reads are done
            if ((!activateInProgress) && (!wrInProgress) && (!rdInProgress))
       begin
              cmd_x                       <= PCHG_CMD;  // initiate precharge of the SDRAM
              sAddr_x[CMDBIT_POS]         <= ALL_BANKS;  // precharge all banks
              timer_x                     <= (timer_size)'(RP_CYCLES);  // set timer for this operation
              activeFlag_x                <= '0;  // all rows are inactive after a precharge operation
              state_x                     <= SELFREFRESH;  // self-refresh the SDRAM after the precharge
            end
            status                        <= 4'b1000;
     end
            //////////////////////////////////////////////////////////-
            // no operation
            //////////////////////////////////////////////////////////-
          else
     begin
            state_x                       <= RW;  // continue to look for SDRAM operations to execute
            status                        <= 4'b1001;
          end
          end

          //////////////////////////////////////////////////////////-
          // activate a row of the SDRAM
          //////////////////////////////////////////////////////////-
        ACTIVATE:
     begin
          cmd_x                   <= ACTIVE_CMD;
          sAddr_x                 <= '0;  // output the address for the row to be activated
          sAddr_x[ROW_LEN-1:0]      <= row;
//          activeBank_x            <= bank;
//        YM/TPT one extra bit for initialisation case
          activeBank_x            <= {1'b0, bank};
          activeRow_x[bankIndex]  <= row;  // store the new active SDRAM row address
          activeFlag_x[bankIndex] <= YES;  // the SDRAM is now active
          rasTimer_x              <= (rasTimer_size)'(RAS_CYCLES);  // minimum time before another precharge can occur
          timer_x                 <= (timer_size)'(RCD_CYCLES);  // minimum time before a read/write operation can occur
          state_x                 <= RW;  // return to do read/write operation that initiated this activation
          status                  <= 4'b1010;
          end

          //////////////////////////////////////////////////////////-
          // refresh a row of the SDRAM
          //////////////////////////////////////////////////////////-
        REFRESHROW:
     begin
          cmd_x      <= RFSH_CMD;
          timer_x    <= (timer_size)'(RFC_CYCLES);     // refresh operation interval
          rfshCntr_x <= rfshCntr_r - 1'b1;  // decrement the number of needed row refreshes
          state_x    <= RW;             // process more SDRAM operations after refresh is done
          status     <= 4'b1011;
          end

          //////////////////////////////////////////////////////////-
          // place the SDRAM into self-refresh and keep it there until further notice
          //////////////////////////////////////////////////////////-
        SELFREFRESH:
     begin
          if ((doSelfRfsh) || (!lock))
     begin
                                        // keep the SDRAM in self-refresh mode as long as requested and until there is a stable clock
            cmd_x        <= RFSH_CMD;   // output the refresh command; this is only needed on the first clock cycle
            cke_x        <= NO;         // disable the SDRAM clock
     end
          else
     begin
                                        // else exit self-refresh mode and start processing read and write operations
            cke_x        <= YES;        // restart the SDRAM clock
            rfshCntr_x   <= 0;          // no refreshes are needed immediately after leaving self-refresh
            activeFlag_x <= '0  ;  // self-refresh deactivates all rows
            timer_x      <= (timer_size)'(XSR_CYCLES);  // wait this long until read and write operations can resume
            state_x      <= RW;
          end
          status         <= 4'b1100;
          end

          //////////////////////////////////////////////////////////-
          // unknown state
          //////////////////////////////////////////////////////////-
        default:
     begin
          state_x <= INITWAIT;          // reset state if (in erroneous state
          status  <= 4'b1101;
          end

      endcase
    end
  end


  //////////////////////////////////////////////////////////-
  // update registers on the appropriate clock edge
  //////////////////////////////////////////////////////////-

  always_ff  @(posedge clk or posedge rst)
  begin:reg_proc
    int rowindex;
    if (rst)
    begin
      // asynchronous reset
      state_r      <= INITWAIT;
      activeFlag_r <= '0;
      rfshCntr_r   <= '0;
      timer_r      <= '0;
      refTimer_r   <= (refTimer_size)'(REF_CYCLES);
      rasTimer_r   <= '0;
      wrTimer_r    <= '0;
      nopCntr_r    <= '0;
      opBegun_r    <= NO;
      rdPipeline_r <= '0;
      wrPipeline_r <= '0;
      cke_r        <= NO;
      cmd_r        <= NOP_CMD;
      ba_r         <= '0;
      sAddr_r      <= '0;
      sData_r      <= '0;
      //sDataDir_r   <= INPUT;
      hDOut_r      <= '0;
      activeBank_r <= {1'b1,{BA_WIDTH{1'b0}}} ;
      for(rowindex=0;rowindex < NUM_ACTIVE_ROWS;rowindex++)
        activeRow_r[rowindex]  <= '0; // YM/TPT added for clean synthesis
    end
    else
    begin
      state_r      <= state_x;
      activeBank_r <= activeBank_x;
      activeRow_r  <= activeRow_x;
      activeFlag_r <= activeFlag_x;
      rfshCntr_r   <= rfshCntr_x;
      timer_r      <= timer_x;
      refTimer_r   <= refTimer_x;
      rasTimer_r   <= rasTimer_x;
      wrTimer_r    <= wrTimer_x;
      nopCntr_r    <= nopCntr_x;
      opBegun_r    <= opBegun_x;
      rdPipeline_r <= rdPipeline_x;
      wrPipeline_r <= wrPipeline_x;
      cke_r        <= cke_x;
      cmd_r        <= cmd_x;
      ba_r         <= ba_x;
      sAddr_r      <= sAddr_x;
      sData_r      <= sData_x;
      //sDataDir_r   <= sDataDir_x;
      hDOut_r      <= hDOut_x;
    end
  end

    // the register that gets data from the SDRAM and holds it for the host
    // is clocked on the opposite edge.  We don't use this register if (IN_PHASE=TRUE.
  always_ff  @(negedge clk or posedge rst)
    if (rst)
      hDOutOppPhase_r <= '0;
    else
      hDOutOppPhase_r <= hDOutOppPhase_x;


  //////////////////////////////////////////////////////////-
  // TPT splitted SDRAM bus
  //////////////////////////////////////////////////////////-

  assign sDIn = sD ;
  assign sQ  = sDOut ;

endmodule

