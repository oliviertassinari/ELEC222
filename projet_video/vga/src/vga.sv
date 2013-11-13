/*
 * Création du module vga
 *
 * Paramètre 	        Commentaire  	         Valeur    Unité
 * Fpix 	            fréquence pixel 	     25,2 	   Mhz
 * Fdisp 	            fréquence image 	     60 	   images/sec
 * HDISP 	            Largeur de l'image 	     640 	   pixels
 * VDISP 	            Hauteur de l'image 	     480 	   lignes
 * HFP 	                Horizontal Front Porch   16 	   pixels
 * HPULSE 	            Largeur de la sync ligne 96 	   pixels
 * HBP 	                Horizontal Back Porch 	 48 	   pixels
 * VFP 	                Vertical Front Porch 	 11 	   lignes
 * VPULSE 	            Largeur de la sync image 2 	       lignes
 * VBP 	                Vertical Back Porch 	 31 	   lignes
 *
 */
`default_nettype none

module vga #(parameter HDISP = 640, VDISP = 480)(input wire CLK, RST,
                                                 output logic VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC,
                                                 output logic [9:0] VGA_R, VGA_G, VGA_B,
                                                 wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.master wb_m);

   // Paramêtres locaux
   localparam logic [$clog2(HDISP<<1)-1:0] HFP = 16;
   localparam logic [$clog2(HDISP<<1)-1:0] HPULSE = 96;
   localparam logic [$clog2(HDISP<<1)-1:0] HBP = 48;

   localparam logic [$clog2(VDISP<<1)-1:0] VFP = 11;
   localparam logic [$clog2(VDISP<<1)-1:0] VPULSE = 2;
   localparam logic [$clog2(VDISP<<1)-1:0] VBP = 31;

   logic [$clog2(HDISP<<1)-1:0] ctH;
   logic [$clog2(VDISP<<1)-1:0] ctV;

   VGA_PLL vga_pll_i(CLK, VGA_CLK);

   always_comb
     begin
        VGA_SYNC = 0;

        if(ctH < HDISP + HFP || ctH >= HDISP + HFP + HPULSE)
          VGA_HS = 1;
        else
          VGA_HS = 0;

        if(ctV < VDISP + VFP || ctV >= VDISP + VFP + VPULSE)
          VGA_VS = 1;
        else
          VGA_VS = 0;

        if(ctV < VDISP && ctH < HDISP)
          VGA_BLANK = 1;
        else
          VGA_BLANK = 0;
     end

   always_ff @(posedge VGA_CLK)
     begin
        if(RST)
          begin
             ctH <= 0;
             ctV <= 0;
          end
        else
          begin
             ctH <= ctH + 1'b1;

             if(ctH == HDISP + HFP + HPULSE + HBP - 1'b1)
               begin
                 ctH <= 0;
                 ctV <= ctV + 1'b1;
               end

             if(ctV == VDISP + VFP + VPULSE + VBP - 1'b1)
               begin
                 ctH <= 0;
                 ctV <= 0;
               end
          end
     end

   always_ff @(posedge VGA_CLK)
     begin
        if(RST)
          begin
             VGA_R <= '0;
             VGA_G <= '0;
             VGA_B <= '0;
          end
        else
          begin
             if(ctH[3:0] == 4'b1111 || ctV[3:0] == 4'b0)
               begin
                  VGA_R <= '1;
                  VGA_G <= '1;
                  VGA_B <= '1;
               end
             else
               begin
                  VGA_R <= '0;
                  VGA_G <= '0;
                  VGA_B <= '0;
               end
          end
     end


   /* Maitre wishbone "bidon" */
   always_comb
     begin
        wb_m.dat_ms = 16'hBABE;
        wb_m.adr = '0;
        wb_m.cyc = 1'b1;
        wb_m.sel = 2'b11;
        wb_m.stb = 1'b1;
        wb_m.we = 1'b1;
        wb_m.cti = '0;
        wb_m.bte = '0;
     end

endmodule