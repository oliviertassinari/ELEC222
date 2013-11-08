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

module fpga #(parameter HDISP = 640, VDISP = 480)(input   CLK, CLK_AUX, SW, NRST,
             output  LED_VERTE, LED_ROUGE,
                     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANCK, VGA_SYNC,
             output wire [9:0] VGA_R, VGA_G, VGA_B);

   /* Zone de test de fonctionnement de la plaquette */
   logic [25:0]     cmpt;
   logic            rst_async;

   reset #(.is_nrst('b1)) reset_i(.CLK(CLK), .RST(NRST), .rst_async(rst_async));

   assign LED_ROUGE = SW;
   assign LED_VERTE = cmpt[25];

   always_ff @(posedge CLK or posedge rst_async)
     if (rst_async) cmpt <= '0;
     else cmpt <= cmpt + 1'd1;
   // Fin zone de test plaquette

   /* Module vga */
   vga #(.HDISP(HDISP), .VDISP(VDISP)) vga_i(.CLK(CLK_AUX),.RST(rst_async),.VGA_CLK(VGA_CLK), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK(VGA_BLANCK), .VGA_SYNC(VGA_SYNC), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B));


endmodule // fpga

