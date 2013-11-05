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

module tb_fpga;

   logic CLK, SW, NRST;

   /* Horloge 50Mhz */
   always #10ns CLK = ~CLK;

   /* Instanciation d'un module fpga */
   fpga i_fpga(CLK, SW, NRST, LED_ROUGE, LED_VERTE);

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
        @(negedge CLK);
        @(negedge CLK);
        NRST = 1'b1;

        repeat(1000)
        begin
           @(posedge CLK);
           SW = $random;
        end

        $display("done");
        $finish;
     end

endmodule