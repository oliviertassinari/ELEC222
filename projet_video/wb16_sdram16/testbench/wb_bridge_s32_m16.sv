//----------------------------------------------------------------------------
// Wishbone bridge
// Act as 32 bit slave and a 16 bits master
// YM/TPT
// - The slave interface doesnt generate rty
// - The slave interfac transmit all errors from the master
// - Access to the 16b master interface are optimized according to the
// selected bytes
// - Interface signals are combinational: the interface doesnt insert any cycle latency
//   but the combinational paths between the external master and slaves are longer...
// - tag be/cti supported only for "Classic Bus Cycle" "Incrementing Burst Cycle" and "End of Burst"
//
//----------------------------------------------------------------------------

module wb_bridge_s32_m16
      (
   wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32.slave wb_s,
   wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.master wb_m 
);

logic [15:0] wb_m_data_sm_reg ;
logic step2 ;
wire wb_s_req = wb_s.cyc && wb_s.stb ;
wire need_upper_word = wb_s_req && (wb_s.sel[3:2] != 2'b00) ;
wire need_lower_word = wb_s_req && (wb_s.sel[1:0] != 2'b00) ;

// Tag Generation
assign wb_m.bte  = wb_s.bte  ;
logic [2:0] lastTag ;
always_ff @(posedge wb_m.clk) 
  if(wb_s_req && (wb_s.cti != 3'b111)) 
    lastTag <= wb_s.cti ;
assign wb_m.cti  = (wb_s.cti == 3'b111) ? (step2 ? 3'b111 : lastTag) : wb_s.cti ;

// The slave doesnt generate retry
assign wb_s.rty = 1'b0 ;
// The slave transmit all errors
assign wb_s.err = wb_m.err ;

// Creates command for master interface
assign wb_m.stb = wb_s_req || step2 ;
assign wb_m.cyc = wb_s_req || step2 ;
assign wb_m.we  = wb_s.we ;
assign wb_s.dat_sm = (!need_upper_word)  ? { wb_m.dat_sm , wb_m.dat_sm} 
                                         : { wb_m.dat_sm , wb_m_data_sm_reg } ;
assign wb_s.ack = (!need_lower_word || !need_upper_word || step2) && wb_m.ack ;

assign {wb_m.adr,wb_m.sel,wb_m.dat_ms} = (step2 || ~need_lower_word) ?
                    {{wb_s.adr[31:2],2'b10}, wb_s.sel[3:2], wb_s.dat_ms[31:16]}: 
                    {{wb_s.adr[31:2],2'b00}, wb_s.sel[1:0], wb_s.dat_ms[15:0]} ;

always @(posedge wb_m.clk)
if(~step2 && ~wb_s.we && wb_m.ack)
  wb_m_data_sm_reg <= wb_m.dat_sm ;


always @(posedge wb_m.clk)
if(wb_m.rst)
  step2 <= 1'b0 ;
else
begin
 if (wb_m.ack && ~step2 && need_upper_word && need_lower_word)   step2 <= 1'b1 ;
 if (wb_m.ack && step2) step2 <= 1'b0 ;
end


endmodule
