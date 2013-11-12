/*
 * Création du module reset
 *
 * Nom 	        Type 	Nombre de bits 	Utilisation
 * CLK       	entrée 	1 	            Horloge
 * NRST 	    entrée 	1 	            commande 0/1
 *
 * Fonction : Destiné à définri un positif reset stable
 *
 */

module reset #(parameter is_nrst = 1'b1)(input   CLK, RST,
              output logic rst_async);

   logic            registre;
   logic            reset;

   always_comb
     reset = RST^is_nrst;

   /* Création d'un RESET asynchrone stable */
   always_ff @(posedge CLK or posedge reset)
     if(reset)
       {rst_async, registre} <= {1'b1, 1'b0};
     else
       {rst_async, registre} <= {registre, 1'b0};
   // Fin RESET aysnchrone stable

endmodule // reset
