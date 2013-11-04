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

module fpga (input   CLK, SW, NRST,
             output  LED_VERTE, LED_ROUGE);

   /* Zone de test de fonctionnement de la plaquette */
   logic [25:0]     cmpt;
   logic            resync_rst;

   reset #(rst_activity = 0) i_reset(.CLK(CLK), .NRST(NRST), .resync_rst(resync_rst));

   assign LED_ROUGE = SW;
   assign LED_VERTE = cmpt[25];

   always_ff @(posedge CLK or negedge resync_rst)
     if (~resync_rst) cmpt <= '0;
     else cmpt <= cmpt + 1'd1;
   // Fin zone de test plaquette

endmodule // fpga

