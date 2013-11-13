// YM/TPT
// Wishbone bus modelized via an "interface"
// 4 modports are defined:
// master : master interface (for hardware synthesis)
// slave  : slave  interface (for hardware synthesis)
// tb_master : master inteface for testbenches
// tb_slave  : slave  inteface for testbenches
//  Interface definition defines 4 parameters :
//    DATA_BYTES    : width of data interface
//    ADDRESS_WIDTH : width of the address bus
//    TB_MASTER : the master modport is for a VM model
//    TB_SLAVE  : the slave  modport is for a VM model

// The code use a mix of PREPROCESSING and parameters
// This solution tries to give a solution to the following problems:

// 1/ Synthesis of individual modules using interfaces as ports expects interfaces
// bus size to be allready defined. Therefore generic interfaces cannot be used. Furthermore
// the standard doesn't allow to change parameter values to an interface used as a port
// of a module : we choose to use compiler directives in order to forge fixed interfaces
// whose parameters (DATA_BYTES, ADDRESS_WIDTH) are given in the name.

// 2/ The 4 modports (master, slave, tb_master, tb_slave) cannot be defined alltogether. Even
// if only a couple of them (master, tb_slave) or (master, slave) , or (tb_master, slave)...
// are used during simulation. During elaboration phase, Modelsim complains about conflicts 
// beetween "continuous assignments" (in the modules) and "procedural" (testbench). 
// We use parameters, in order to restrict the interface to the following cases :
//  (master, slave)
//  (master, slave,tb_master)
//  (master, slave,tb_slave)
//  Is there a better way ?
// 
// The following code generates two kind of interfaces:
// wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32
// wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32

`timescale 1ns/10ps

`define WSHB_IF_START(DATA_BYTES,ADDRESS_WIDTH) \
                                                                      \
interface wshb_if_DATA_BYTES_``DATA_BYTES``_ADDRESS_WIDTH_``ADDRESS_WIDTH #(parameter TB_MASTER=0,TB_SLAVE=0) (input logic clk, input logic rst) ;                \
                                                                      \
  // WISHBONE  signals                                                \
  logic  [8*DATA_BYTES-1:0]  dat_sm, dat_ms ;                         \
  logic  [ADDRESS_WIDTH-1:0] adr ;                                    \
  logic                      cyc;                                     \
  logic  [DATA_BYTES-1:0]    sel;                                     \
  logic                      stb;                                     \
  logic                      we;                                      \
  logic                      ack;                                     \
  logic                      err;                                     \
  logic                      rty;                                     \
  logic [2:0]                cti;                                     \
  logic [1:0]                bte;
                                                                      
`define WSHB_IF_RTL \
  //////////////// RTL Masters and slaves modports ///////////////////\
                                                                      \
  // Modport for master rtl                                           \
  modport master (                                                    \
    output dat_ms,                                                    \
    output adr ,                                                      \
    output cyc ,                                                      \
    output sel ,                                                      \
    output stb ,                                                      \
    output we  ,                                                      \
    output cti ,                                                      \
    output bte ,                                                      \
    input  ack ,                                                      \
    input  err ,                                                      \
    input  rty ,                                                      \
    input  dat_sm,                                                    \
    input  clk,                                                       \
    input  rst                                                        \
  ) ;                                                                 \
                                                                      \
  // Modport for slave rtl                                            \
  modport slave (                                                     \
    output dat_sm,                                                    \
    output ack ,                                                      \
    output err ,                                                      \
    output rty ,                                                      \
    input  adr ,                                                      \
    input  sel ,                                                      \
    input  stb ,                                                      \
    input  we,                                                        \
    input  cyc ,                                                      \
    input  dat_ms,                                                    \
    input  cti,                                                       \
    input  bte,                                                       \
    input  clk,                                                       \
    input  rst                                                        \
  ) ;                                                                 \
  

`define WSHB_IF_TB \
  //////////////// TESTBENCH Masters and slaves modports /////////////\
  if(TB_MASTER) begin:tbm                                             \
   // Modport for master testbench                                    \
     modport tb_master(                                               \
       clocking cbm,                                                  \
       task clockAlign()                                              \
     );                                                               \
                                                                      \
    // Clocking block for master testbench                            \
    clocking cbm @(posedge clk);                                      \
      // WISHBONE Master signals                                      \
      output dat_ms ;                                                 \
      output adr ;                                                    \
      output cyc ;                                                    \
      output sel ;                                                    \
      output stb ;                                                    \
      output we ;                                                     \
      output cti;                                                     \
      output bte;                                                     \
      input  ack;                                                     \
      input  err;                                                     \
      input  rty;                                                     \
      input  dat_sm;                                                  \
    endclocking                                                       \
  end                                                                 \
                                                                      \
                                                                      \
   if(TB_SLAVE) begin:tbs                                             \
    // Modport for slave testbench                                    \
    modport tb_slave(                                                 \
      clocking cbs,                                                   \
      clocking cbs_n,                                                 \
      task clockAlign()                                               \
    );                                                                \
                                                                      \
    // Clocking block 0 positive edge                                 \
    clocking cbs @(posedge clk);                                      \
      // WISHBONE Slave signals                                       \
      output dat_sm;                                                  \
      output ack;                                                     \
      output err;                                                     \
      output rty;                                                     \
      input  adr;                                                     \
      input  sel;                                                     \
      input  stb;                                                     \
      input  we;                                                      \
      input  cyc;                                                     \
      input  dat_ms;                                                  \
      input  cti   ;                                                  \
      input  bte   ;                                                  \
    endclocking                                                       \
                                                                      \
    // Clocking block 1 negative edge                                 \
    clocking cbs_n @(negedge clk);                                    \
      // WISHBONE Slave signals                                       \
      output dat_sm;                                                  \
      output ack ;                                                    \
      output err ;                                                    \
      output rty ;                                                    \
      input  adr;                                                     \
      input  sel;                                                     \
      input  stb;                                                     \
      input  we ;                                                     \
      input  cyc;                                                     \
      input  dat_ms;                                                  \
      input  cti   ;                                                  \
      input  bte   ;                                                  \
    endclocking                                                       \
  end                                                                 \
    // Clock edge alignment                                           \
    task clockAlign();                                                \
       wait(sync_posedge.triggered);                                  \
    endtask                                                           \
                                                                      \
    sequence sync_posedge;                                            \
      @(posedge clk) 1;                                               \
    endsequence                                                       
                                                                      

`define WSHB_IF_END \
endinterface                                                          

// Standard interfaces definitions

// 4 bytes data / 32 bits addresses
`WSHB_IF_START(4,32) 
`WSHB_IF_RTL
// synthesis translate_off                                          
`WSHB_IF_TB
// synthesis translate_on                                         
`WSHB_IF_END


// 2 bytes data / 32 bits addresses
`WSHB_IF_START(2,32) 
`WSHB_IF_RTL
// synthesis translate_off                                          
`WSHB_IF_TB
// synthesis translate_on                                         
`WSHB_IF_END
