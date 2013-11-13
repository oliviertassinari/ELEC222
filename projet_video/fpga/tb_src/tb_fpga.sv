/*
 * Création du module testbench de fpga
 *
 * Nom 	        Type 	Nombre de bits 	Utilisation
 * CLK       	entrée 	1 	            Horloge
 * LED_VERTE 	sortie 	1 	            Affichage
 * LED_ROUGE 	sortie 	1 	            Affichage
 * SW 	        entrée 	1 	            commande 0/1
 * NRST 	    entrée 	1 	            commande 0/1
 *
 * Fonction : Destiné à tester fpga.sv
 *
 */

`timescale 1ns/100ps
`default_nettype none

module tb_fpga;

   bit CLK, SW, NRST, CLK_AUX;
   logic [9:0] VGA_R, VGA_G, VGA_B;
   wire        LED_ROUGE, LED_VERTE;
   wire        VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, TD_RESET;

   // Interface sdram
   wire        dram_clk;
   wire        dram_cke;
   wire        dram_cs_n;
   wire        dram_ras_n;
   wire        dram_cas_n;
   wire        dram_we_n;
   wire [1:0]  dram_ba;
   wire [11:0] dram_addr;
   wire [15:0] dram_dq;
   wire [1:0]  dram_dqm;

   // Horloge 50Mhz
   always #10ns CLK = ~CLK;

   // Horloge 27Mhz
   always #18.5ns  CLK_AUX = ~CLK_AUX;

   // Instanciation d'un module fpga
   fpga #(.HDISP('d160), .VDISP('d120)) i_fpga(CLK,
                                               CLK_AUX,
                                               SW,
                                               NRST,
                                               LED_ROUGE,
                                               LED_VERTE,
                                               VGA_CLK,
                                               VGA_HS,
                                               VGA_VS,
                                               VGA_BLANK,
                                               VGA_SYNC,
                                               TD_RESET,
                                               dram_clk,
                                               dram_cke,
                                               dram_cs_n,
                                               dram_ras_n,
                                               dram_cas_n,
                                               dram_we_n,
                                               dram_ba,
                                               dram_addr,
                                               dram_dq,
                                               dram_dqm,
                                               VGA_R,
                                               VGA_G,
                                               VGA_B);

   // sdram
   km416s4030 SDRAM
     (
      .BA0    (dram_ba  [0] ),
      .BA1    (dram_ba  [1] ),
      .DQML   (dram_dqm [0] ),
      .DQMU   (dram_dqm [1] ),
      .DQ0    (dram_dq  [0] ),
      .DQ1    (dram_dq  [1] ),
      .DQ2    (dram_dq  [2] ),
      .DQ3    (dram_dq  [3] ),
      .DQ4    (dram_dq  [4] ),
      .DQ5    (dram_dq  [5] ),
      .DQ6    (dram_dq  [6] ),
      .DQ7    (dram_dq  [7] ),
      .DQ8    (dram_dq  [8] ),
      .DQ9    (dram_dq  [9] ),
      .DQ10   (dram_dq  [10]),
      .DQ11   (dram_dq  [11]),
      .DQ12   (dram_dq  [12]),
      .DQ13   (dram_dq  [13]),
      .DQ14   (dram_dq  [14]),
      .DQ15   (dram_dq  [15]),
      .CLK    (dram_clk     ),
      .CKE    (dram_cke     ),
      .A0     (dram_addr[0] ),
      .A1     (dram_addr[1] ),
      .A2     (dram_addr[2] ),
      .A3     (dram_addr[3] ),
      .A4     (dram_addr[4] ),
      .A5     (dram_addr[5] ),
      .A6     (dram_addr[6] ),
      .A7     (dram_addr[7] ),
      .A8     (dram_addr[8] ),
      .A9     (dram_addr[9] ),
      .A10    (dram_addr[10]),
      .A11    (dram_addr[11]),
      .WENeg  (dram_we_n    ),
      .RASNeg (dram_ras_n   ),
      .CSNeg  (dram_cs_n    ),
      .CASNeg (dram_cas_n   )
      );

   initial
     begin: entree
        CLK = 1'b0;
        NRST = 1'b0;
        SW = 1'b0;
        @(negedge CLK);
        @(negedge CLK);
        NRST = 1'b1;
        @(negedge CLK);
        @(negedge CLK);
        @(negedge CLK);
        NRST = 1'b0;
        repeat(10)
          @(negedge CLK);

        NRST = 1'b1;

        repeat(2000)
        begin
           @(posedge CLK);
           SW = $random;
        end

        $display("done");
        $stop;
     end

endmodule