/*
 * Création du module reset
 *
 * Nom 	        Type 	Nombre de bits 	Utilisation
 * CLK       	entrée 	1 	            Horloge
 * NRST 	    entrée 	1 	            commande 0/1
 *
 * Fonction : Destiné à définri un reset stable
 *
 */

module reset #(parameter rst_activity = 1)(input   CLK, NRST,
              output  resync_rst);

   logic              r0;

   /* Création d'un RESET asynchrone stable */
   always_ff @(posedge CLK or negedge NRST)
     begin
        if(~NRST) {resync_rst,r0} <= {rst_activity, rst_activity};
        else  {resync_rst,r0} <= {r0,~rst_activity};
     end
   // Fin RESET aysnchrone stable
endmodule // reset
