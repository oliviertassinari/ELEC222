/**
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
 **/
`default_nettype none

  module vga #(parameter HDISP = 640, VDISP = 480)(input wire
                                                   CLK,
                                                   RST,
                                                 output logic
                                                   VGA_CLK,
                                                   VGA_HS,
                                                   VGA_VS,
                                                   VGA_BLANK,
                                                   VGA_SYNC,
                                                 output logic [9:0]
                                                   VGA_R,
                                                   VGA_G,
                                                   VGA_B,
                                                   wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.master wb_m);

   /* Paramêtres locaux */
   localparam logic [$clog2(HDISP<<1)-1:0] HFP = 16;
   localparam logic [$clog2(HDISP<<1)-1:0] HPULSE = 96;
   localparam logic [$clog2(HDISP<<1)-1:0] HBP = 48;

   localparam logic [$clog2(VDISP<<1)-1:0] VFP = 11;
   localparam logic [$clog2(VDISP<<1)-1:0] VPULSE = 2;
   localparam logic [$clog2(VDISP<<1)-1:0] VBP = 31;

   logic [$clog2(HDISP<<1)-1:0]            ctH;
   logic [$clog2(VDISP<<1)-1:0]            ctV;

   logic [$clog2(HDISP)-1:0]            ctMireH;
   logic [$clog2(VDISP)-1:0]            ctMireV;

   logic                                   vga_enable, mire_loaded;
   logic [15:0]                            fifo_sm_dat;
   logic                                   fifo_sm_read, fifo_sm_rempty, fifo_sm_write, fifo_sm_wfull;

   /* Instanciation des modules complémentaires */
   VGA_PLL vga_pll_i(CLK, VGA_CLK);

   /* Fifo */
   fifo_async #(16, 256)  fifo_async_i_sm(RST, VGA_CLK, fifo_sm_read, fifo_sm_dat, fifo_sm_rempty, wb_m.clk, wb_m.dat_sm, fifo_sm_write, fifo_sm_wfull);

   /* MAE pour protocole VGA */
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

   // Compteurs
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

                  if(ctV == VDISP + VFP + VPULSE + VBP - 1'b1)
                    ctV <= 0;
                  else
                    ctV <= ctV + 1'b1;
               end
          end
     end

   /* Affichage */
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
             if(vga_enable)
               begin
                  VGA_R <= ctH;
                  VGA_G <= ctH;
                  VGA_B <= ctV;
               end
             else
               begin
                  VGA_R <= '0;
                  VGA_G <= '0;
                  VGA_B <= '0;
               end
          end
     end

   // Chargement de la mire
   always_ff @(posedge wb_m.clk)
     begin
        if(RST)
          begin
             mire_loaded <= 0;
             ctMireH <= 0;
             ctMireV <= 0;
          end
        else
          if(!mire_loaded)
            begin
               ctMireH <= ctMireH + 1'b1;

               if(ctMireH == HDISP - 1'b1)
                 begin
                    ctMireH <= 0;

                    if(ctMireV == VDISP - 1'b1)
                      begin
                         ctMireV <= 0;
                         mire_loaded <= 1;
                      end
                    else
                      ctMireV <= ctMireV + 1'b1;
                 end
            end
     end

   // Contrôleur
   always_ff @(posedge VGA_CLK)
     begin
        if(RST)
          begin
             wb_m.adr <= '0;
             wb_m.cyc <= '0;
             wb_m.sel <= '0;
             wb_m.stb <= '0;
             wb_m.we <= '0;
             wb_m.cti <= '0;
             wb_m.bte <= '0;
             fifo_sm_read <= 0;
             fifo_sm_write <= 0;
          end
     end

endmodule