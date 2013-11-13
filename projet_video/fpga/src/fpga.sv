/*
 * Création du module fpga
 *
 * Nom 	        Type 	Nombre de bits 	Utilisation
 * CLK       	entrée 	1 	            Horloge
 * LED_VERTE 	sortie 	1 	            Affichage
 * LED_ROUGE 	sortie 	1 	            Affichage
 * SW 	        entrée 	1 	            commande 0/1
 * NRST 	    entrée 	1 	            commande 0/1
 *
 * Fonction : Destiné à contenir le code global du fpga
 *
 */

`default_nettype none

module fpga #(parameter HDISP = 640, VDISP = 480)(input wire CLK, CLK_AUX, SW, NRST,
                                                  output logic        LED_VERTE, LED_ROUGE,
                                                                      VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, TD_RESET,
                                                                      dram_clk, dram_cke, dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n,
                                                  output logic [1:0]  dram_ba,
                                                  output logic [11:0] dram_addr,
                                                  inout  wire  [15:0] dram_dq,
                                                  output logic [1:0]  dram_dqm,
                                                  output wire  [9:0]  VGA_R, VGA_G, VGA_B);

   logic                                                             rst_async;
   wire                                                               wshb_clk;
   wire                                                               wshb_rst;
   logic                                                              VGA_INT;

   /* Reset */
   reset #(.is_nrst(1'b1)) reset_i(CLK, NRST, rst_async);
   reset #(.is_nrst(1'b1)) reset_i_wshb(wshb_clk, NRST),

   /* VGA */
   vga #(.HDISP(HDISP), .VDISP(VDISP)) vga_i(CLK_AUX, rst_async, VGA_INT, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_R, VGA_G, VGA_B, wb16.master);
   assign VGA_CLK = ~VGA_INT;

   /* Interface Wishbone */
   wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32 wb16(wshb_clk, wshb_rst);
   wshb_pll wshb_pll_i(CLK, wshb_clk, dram_clk);

   /* Fifo */
   fifo_async #(.DATA_WIDTH('d16), .DEPTH_WIDTH('d256)) fifo_async_i1(.rst(RST),
                                                                     .rclk(dram_clk),
                                                                     .read(),
                                                                     .rdata(),
                                                                     .rempty(),
                                                                     .wclk(wshb_clk),
                                                                     .wdata(),
                                                                     .write(),
                                                                     .wfull());

   /* Controleur de SDRAM */
   wb16_sdram16 wb_sdram16_i
     (
      // Wishbone 16 bits interface esclave
      .wb_s(wb16.slave),
      // SDRAM
      .cke(dram_cke),                      // clock-enable to SDRAM
      .cs_n(dram_cs_n),                    // chip-select to SDRAM
      .ras_n(dram_ras_n),                  // SDRAM row address strobe
      .cas_n(dram_cas_n),                  // SDRAM column address strobe
      .we_n(dram_we_n),                    // SDRAM write enable
      .ba(dram_ba),                        // SDRAM bank address
      .sAddr(dram_addr),                   // SDRAM row/column address
      .sDQ(dram_dq),                       // data from and to SDRAM
      .dqm(dram_dqm)                       // enable bytes of SDRAM databus
      );


   /* Zone de test de fonctionnement de la plaquette */
   logic [25:0]     cmpt;

   assign LED_ROUGE = SW;
   assign LED_VERTE = cmpt[25];
   assign TD_RESET = '1;

   always_ff @(posedge CLK or posedge rst_async)
     if (rst_async) cmpt <= '0;
     else cmpt <= cmpt + 1'd1;
   // Fin zone de test plaquette



endmodule

