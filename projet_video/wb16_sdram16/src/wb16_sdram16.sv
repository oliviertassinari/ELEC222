//-----------------------------------------------------------------------------
// Wishbone SDRAM controller for 32 bit whishbone bus and 16b SDRAM width
// YM/TPT
//-----------------------------------------------------------------------------
// PREDICTION_WIDTH :
// Burst prediction width (length of burst is 2**PREDICTION_WIDTH)

module wb16_sdram16 #(
        parameter       PREDICTION_WIDTH = 4,
        parameter       OP_FREQ_KHZ =  100_000
) (
   // Whishbone connection
   wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.slave wb_s,
   // SDRAM connection
   //   output logic  sdram_clk                 , // clock for SDRAM
   output logic  cke                       , // clock-enable to SDRAM
   output logic  cs_n                      , // chip-select to SDRAM
   output logic  ras_n                     , // SDRAM row address strobe
   output logic  cas_n                     , // SDRAM column address strobe
   output logic  we_n                      , // SDRAM write enable
   output logic  [1:0]  ba                 , // SDRAM bank address
   output logic  [11:0] sAddr              , // SDRAM row/column address
   inout  wire   [15:0] sDQ                , // data from and to SDRAM
   output logic  [1:0]  dqm                  // enable bytes of SDRAM databus
);



//----------------------------------------------------------------------------
// Instantiate a WB16 to Xess cntl adapter
//----------------------------------------------------------------------------

logic   cntl_rd;
logic   cntl_wr;
logic   cntl_opBegun;
logic   cntl_earlyOpBegun;
logic   cntl_rdPending;
logic   cntl_done;
logic   cntl_rdDone;
logic   [21:0] cntl_hAddr;
logic   [15:0] cntl_hDIn ;
logic   [15:0] cntl_hDOut;
logic   [1:0]  cntl_hSel;
logic   [3:0] cntl_status ;

wb_bridge_xess #(.PREDICTION_WIDTH(PREDICTION_WIDTH), // Burst prediction width (length of burst is 2**PREDICTION_WIDTH)
                 .DATA_BYTES(2) ,                     // DATA width
            .HADDR_WIDTH(22)                     // Full address size for Xess controller
) wb_bridge_xess0 (
   // Wishbone interface
   .wb_s(wb_s),
   // Xess Controller connection
   .cntl_rd(cntl_rd),
   .cntl_wr(cntl_wr),
   .cntl_opBegun(cntl_opBegun),
   .cntl_earlyOpBegun(cntl_earlyOpBegun),
   .cntl_rdPending(cntl_rdPending),
   .cntl_done(cntl_done),
   .cntl_rdDone(cntl_rdDone),
   .cntl_hAddr(cntl_hAddr),
   .cntl_hDIn(cntl_hDIn),
   .cntl_hDOut(cntl_hDOut),
   .cntl_hSel(cntl_hSel),
   .cntl_status(cntl_status)
);

//----------------------------------------------------------------------------
// Instantiate the Xess SDRAM controller
//----------------------------------------------------------------------------

logic cntl_lock ;
logic [15:0] cntl_sD                ; // data from SDRAM
logic [15:0] cntl_sQ                ; // data to SDRAM

xess_sdramcntl #(
    .FREQ(OP_FREQ_KHZ)           , // operating frequency in KHz
    .IN_PHASE(1'b0)              , // SDRAM and controller work on same or opposite clock edge
    .PIPE_EN(1'b1)               , // if true, enable pipelined read operations
    .MAX_NOP(10000)              , // number of NOPs before entering self-refresh
    .MULTIPLE_ACTIVE_ROWS(1'b1)  , // if true, allow an active row in each bank
    .DATA_BYTES(2)               , // host & SDRAM data width
    .BA_WIDTH(2)                 , // Bank address width
    .CAS_CYCLES(2)               , // Cas LATENCY  --> TODO: check why doesnt work with cas==3
    .NROWS(2**12)                , // number of rows in SDRAM array
    .NCOLS(2**8)                 , // number of columns in SDRAM array
    .HADDR_WIDTH(2+12+8)         , // host-side address width
    .SADDR_WIDTH(12)               // SDRAM-side address width
    )

    xess_sdram_cntl0 (
    .clk(wb_s.clk),
    .lock(cntl_lock),
    .rst(wb_s.rst),
    // cntl interface
    .rd(cntl_rd),
    .wr(cntl_wr),
    .earlyOpBegun(cntl_earlyOpBegun),
    .opBegun(cntl_opBegun),
    .rdPending(cntl_rdPending),
    .done(cntl_done),
    .rdDone(cntl_rdDone),
    .hAddr(cntl_hAddr),
    .hDIn(cntl_hDIn),
    .hSel(cntl_hSel),
    .hDOut(cntl_hDOut),
    .status(cntl_status),
    // sdram interface
    .cke(cke),
    .cs_n(cs_n),
    .ras_n(ras_n),
    .cas_n(cas_n),
    .we_n(we_n),
    .ba(ba),
    .sAddr(sAddr),
    .sD(cntl_sD),
    .sQ(cntl_sQ),
    .dqm(dqm)
) ;

//----------------------------------------------------------------------------
// Generate global signals for the SDRAM
//----------------------------------------------------------------------------

// Choose to let the SDRAM operate on opposite clock edges
// Should be coeherent with the sdramcntl parameters
//assign sdram_clk = ~wb_s.clk ;

// The sdramcntl wait for PLL to be locked via the "lock" signal"
// here we simply consider that the PLL is always locked....
// should be updated in real life...
assign cntl_lock = ~wb_s.rst ;

// Generate the DATA bus signals
assign cntl_sD = sDQ ;
assign sDQ = (!we_n && !cs_n) ? cntl_sQ : 'Z ;


endmodule
