//----------------------------------------------------------------------------
// Wishbone slave to Xess bridge
// YM/TPT Wrapper around the Xess Corporation SDRAM controller protocol
//
// Parameters usage:
//
// PREDICTION_WIDTH:
// The controller performs burst read by anticipation. The size is 2**PREDICTION_WIDTH
// --  If all read access are bursts of the same size as the predicted burst performance is optimal.
// --  If read access are burst of smaller size, (or even non burst accessees) performances are degraded because
//     of the added latency due to the unusable accesses.
// --  If read access are bursts of bigger size, performance degradation comes from the splitting of the big bursts into
//     normalized bursts : for example if read burst is 10 words and predicted burst is 8 words, two bursts of 8 will be perf//     executed
// DATA_BYTES:
// -- the bus data size (and the associated wishbone bus) is a multible au DATA_BYTES
// -- allowed values are  1,2, 4 or 8
// HADDR_WIDTH:
// -- full address size of the DRAM. The total number of words of the DRAM is 2**HADDR_WIDTH ;
//
//----------------------------------------------------------------------------

module wb_bridge_xess #(
        parameter                  PREDICTION_WIDTH = 4, // Burst prediction width (length of burst is 2**PREDICTION_WIDTH)
        parameter                  DATA_BYTES  = 4 ,     // DATA width
   parameter           HADDR_WIDTH =  21     // Full address size for Xess controller
) (
   // Wishbone interface
   interface wb_s,
   // Xess Controller connection
   output  logic               cntl_rd,
   output  logic               cntl_wr,
   input   logic               cntl_opBegun,
   input   logic               cntl_earlyOpBegun,
   input   logic               cntl_rdPending,
   input   logic               cntl_done,
   input   logic               cntl_rdDone,
   output  logic               [HADDR_WIDTH-1:0] cntl_hAddr,
   output  logic               [8*DATA_BYTES-1:0] cntl_hDIn,
   input   logic               [8*DATA_BYTES-1:0] cntl_hDOut,
   output  logic               [DATA_BYTES-1:0]  cntl_hSel,
   input   logic               [3:0] cntl_status
);

logic wishbone_read_request  ;
logic match_read_addresses ;
enum logic [1:0] { INIT_RD, BURST_RD, WAIT_END_RD } state_rd, next_state_rd ;
enum logic  { INIT_OUT, RBURST_OUT } state_out, next_state_out ;
logic [PREDICTION_WIDTH-1:0] rd_cmpt ;   // read counter for sdram controller requests
logic [PREDICTION_WIDTH-1:0] out_cmpt;   // data counter for sdram controller answers
logic [HADDR_WIDTH-1:0] local_Addr,      // exact word address computed from WishBone address
                        rAddr ,          // computed address for the SDRAM  read requests
                        outAddr ;        // computed address for the SDRAM  read requests

 //---------------------------------------------------------------------------
// Wishbone unused output signals
assign wb_s.rty = 1'b0 ;
assign wb_s.err = 1'b0 ;
//---------------------------------------------------------------------------


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

localparam PREDICTION_SIZE = 2**PREDICTION_WIDTH  ;
localparam HADDR_DEC = clogb2(DATA_BYTES) ;

// Direct connections
assign cntl_hDIn =  wb_s.dat_ms ;
assign wb_s.dat_sm  =  cntl_hDOut ;
assign cntl_hSel = wb_s.sel ;

// Write acces are directly handled by the sdramcntl
assign  cntl_wr =  wb_s.stb & wb_s.cyc & wb_s.we & (state_out == INIT_OUT) ;

// Compute exact word address in memory
assign local_Addr =  wb_s.adr[HADDR_WIDTH+HADDR_DEC-1:HADDR_DEC] ;

//  Read access
assign  wishbone_read_request =  wb_s.stb & wb_s.cyc & ~wb_s.we ;

// State machine for automatic burst read
always_comb
begin
 next_state_rd <= state_rd ;
 case (state_rd)
 INIT_RD:
   if (wishbone_read_request)
    begin
      next_state_rd <= BURST_RD ;
    end
 BURST_RD:
    begin
      if (cntl_earlyOpBegun)
      begin
        if ((rd_cmpt == (PREDICTION_SIZE-1)) || ~wishbone_read_request)
          next_state_rd <= WAIT_END_RD ;
      end
    end
  WAIT_END_RD:
    begin
      if ((out_cmpt == rd_cmpt) && cntl_rdDone) // Si on a recu toutes les données demandées
      begin
        next_state_rd <= INIT_RD ;
      end
    end
  default:
      next_state_rd <= INIT_RD ;
  endcase
end


// State machine for automatic burst out from sdram cntl
always_comb
begin
 next_state_out <= state_out ;
 case (state_out)
  INIT_OUT:
    begin
      if (cntl_rdDone)
      begin
        next_state_out <= RBURST_OUT ;
      end
    end
  RBURST_OUT:
    begin
    if (cntl_rdDone)
      if ((out_cmpt == rd_cmpt) && (state_rd == WAIT_END_RD)) // Si on a recu toutes les données demandées
      begin
        next_state_out <= INIT_OUT ;
      end
    end
 endcase
end

// State machine update
always @( posedge wb_s.clk, posedge wb_s.rst)
if (wb_s.rst)
begin
  state_out <= INIT_OUT ;
  state_rd <= INIT_RD ;
end
else
begin
 state_rd <= next_state_rd ;
 state_out <= next_state_out ;
end

// rd request counters
always @( posedge wb_s.clk, posedge wb_s.rst)
// Counters are reset at the burst transaction completion
if (wb_s.rst)
begin
  rd_cmpt <= '0 ;
  rAddr <= '0 ;
end
else
begin
  if (cntl_rdDone && (state_rd == WAIT_END_RD) && (rd_cmpt == out_cmpt))
  begin
    rd_cmpt <= '0 ;
    rAddr <= '0 ;
  end
  else 
  begin
    if ((rd_cmpt != (PREDICTION_SIZE-1)) && wishbone_read_request && cntl_earlyOpBegun)
    begin
      rd_cmpt <= rd_cmpt + 1'b1 ;
      rAddr <= rAddr + 1'b1 ;
    end
    if ((state_rd == INIT_RD) && wishbone_read_request)
     rAddr <= local_Addr ;
  end
end

// out read counters
always @( posedge wb_s.clk, posedge wb_s.rst)
if (wb_s.rst)
begin
  outAddr <=  '0 ;
  out_cmpt <= '0 ;
end
else
begin
  if (cntl_rdDone && (state_rd == WAIT_END_RD) && (rd_cmpt == out_cmpt))
  begin
    outAddr <= local_Addr ;
    out_cmpt <= '0 ;
  end
  else
  begin
    if (cntl_rdDone)
    begin
     outAddr <=  outAddr + 1'b1 ;
     out_cmpt <= out_cmpt + 1'b1 ;
    end
    if ((state_out == INIT_OUT) && ~cntl_rdDone)
     outAddr <= local_Addr ;
  end
end


// Compute if address of anticipated read match asked address
assign match_read_addresses = cntl_rdDone && (outAddr == local_Addr) ;

assign cntl_rd = (state_rd == BURST_RD)  ;

assign wb_s.ack =  (cntl_wr && cntl_earlyOpBegun) || // A write transaction
                   (cntl_rdDone && match_read_addresses && wishbone_read_request) ; // Incoming data from the sdram controller

assign cntl_hAddr = (state_rd == INIT_RD) ? local_Addr : rAddr ;

endmodule
