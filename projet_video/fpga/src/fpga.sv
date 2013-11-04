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

   /* Création d'un compteur */
   logic [25:0]     cmpt;

   assign LED_ROUGE = SW;
   assign LED_VERTE = cmpt[25];

   always_ff @(posedge CLK or negedge NRST)
     if (~NRST) cmpt <= '0;
     else cmpt <= cmpt + 1'd1;

endmodule // fpga

