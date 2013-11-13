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
//
//----------------------------------------------------------------------------
`timescale 1ns/10ps

module wb_bridge_s32_m16 
      (
	input   logic              clk,
	input   logic              reset,
	// Wishbone 32 bits slave interface
	input   logic              wb_s_stb_i,
	input   logic              wb_s_cyc_i,
	input   logic              wb_s_we_i,
	input   logic              [31:0] wb_s_adr_i,
	input   logic              [3:0]  wb_s_sel_i,
	input   logic              [31:0] wb_s_dat_i,
	output  logic              wb_s_ack_o,
        output  logic              wb_s_rty_o,
        output  logic              wb_s_err_o,
	output  logic              [31:0] wb_s_dat_o,
	// Wishbone 16 bits master interface
	output   logic             wb_m_stb_o,
	output   logic             wb_m_cyc_o,
	output   logic             wb_m_we_o,
	output   logic             [31:0] wb_m_adr_o,
	output   logic             [1:0]  wb_m_sel_o,
	output   logic             [15:0] wb_m_dat_o,
	input    logic             [15:0] wb_m_dat_i,
	input    logic             wb_m_ack_i,
        input    logic             wb_m_rty_i,
        input    logic             wb_m_err_i
);

logic [15:0] wb_m_dat_i_reg ;
logic step2 ;
wire wb_s_req = wb_s_cyc_i && wb_s_stb_i ;
wire need_upper_word = wb_s_req && (wb_s_sel_i[3:2] != 2'b00) ;
wire need_lower_word = wb_s_req && (wb_s_sel_i[1:0] != 2'b00) ;

always_comb 
begin
  // The slave doesnt generate retry
  wb_s_rty_o <= 1'b0 ;
  // The slave transmit all errors
  wb_s_err_o <= wb_m_err_i ;
  
  // Creates command for master interface
  wb_m_stb_o <= wb_s_req || step2 ;
  wb_m_cyc_o <= wb_s_req || step2 ;
  wb_m_we_o  <= wb_s_we_i ;
  wb_s_dat_o <= (!need_upper_word) ? {wb_m_dat_i , wb_m_dat_i} : { wb_m_dat_i , wb_m_dat_i_reg } ;
  wb_s_ack_o <= (!need_lower_word || !need_upper_word || step2) && wb_m_ack_i ;
end

always_comb
  if(step2 || ~need_lower_word) 
  begin
   wb_m_adr_o <=  {wb_s_adr_i[31:2], 2'b10} ;
   wb_m_sel_o <=  wb_s_sel_i[3:2] ;
   wb_m_dat_o <=  wb_s_dat_i[31:16] ;
  end
  else
  begin
   wb_m_adr_o <= {wb_s_adr_i[31:2],2'b00} ;
   wb_m_sel_o <= wb_s_sel_i[1:0] ;
   wb_m_dat_o <= wb_s_dat_i[15:0] ;
  end

always @(posedge clk)
if(~step2 && ~wb_s_we_i && wb_m_ack_i)
  wb_m_dat_i_reg <= wb_m_dat_i ;
 

always @(posedge clk) 
if(reset)
  step2 <= 1'b0 ;
else
begin
 if (wb_m_ack_i && ~step2 && need_upper_word && need_lower_word)   step2 <= 1'b1 ;
 if (wb_m_ack_i && step2) step2 <= 1'b0 ;
end


endmodule
