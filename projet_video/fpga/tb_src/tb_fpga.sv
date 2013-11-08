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

module tb_fpga;

   bit CLK, SW, NRST, CLK_AUX;

   logic [9:0] VGA_R, VGA_G, VGA_B;

   // Horloge 50Mhz
   always #10ns CLK = ~CLK;

   // Horloge 27Mhz
   always #18.5ns  CLK_AUX = ~CLK_AUX;

   /* Instanciation d'un module fpga */
   fpga i_fpga(CLK, CLK_AUX, SW, NRST, LED_ROUGE, LED_VERTE, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_R, VGA_G, VGA_B);

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

        repeat(1000)
        begin
           @(posedge CLK);
           SW = $random;
        end

        $display("done");
        $stop;
     end

endmodule