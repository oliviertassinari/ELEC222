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

   logic                                   vga_enable, mire_loaded;
   logic [15:0]                            fifo_ms_dat, fifo_sm_dat;
   logic                                   fifo_ms_read, fifo_ms_rempty, fifo_ms_write, fifo_ms_wfull;
   logic                                   fifo_sm_read, fifo_sm_rempty, fifo_sm_write, fifo_sm_wfull;

   /* Instanciation des modules complémentaires */
   VGA_PLL vga_pll_i(CLK, VGA_CLK);

   /* Fifo */
   fifo_async #(16, 256)  fifo_async_i_sm(RST, VGA_CLK, fifo_sm_read, fifo_sm_dat, fifo_sm_rempty, wb_m.clk, wb_m.dat_sm, fifo_sm_write, fifo_sm_wfull);
   fifo_async #(16, 256)  fifo_async_i_ms(RST, wb_m.clk, fifo_ms_read, wb_m.dat_ms, fifo_ms_rempty, VGA_CLK, fifo_ms_dat, fifo_ms_write, fifo_ms_wfull);

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
             vga_enable <= 0;
             mire_loaded <= 0;
          end
        else
          begin
             if(mire_loaded && fifo_sm_wfull)
               vga_enable <= 1;

             if(!mire_loaded && ctH == HDISP - 1'b1 && ctV == VDISP - 1'b1)
               mire_loaded <= 1;

             if(!mire_loaded)
               begin
                  VGA_R <= ctH;
                  VGA_G <= ctH;
                  VGA_B <= ctV;
               end
             else if(vga_enable && VGA_BLANK)
               begin
                  VGA_R <= {5'b0, fifo_ms_dat[4:0]};
                  VGA_G <= {4'b0, fifo_ms_dat[5:0]};
                  VGA_B <= {5'b0, fifo_ms_dat[4:0]};
               end
             else
               begin
                  VGA_R <= '0;
                  VGA_G <= '0;
                  VGA_B <= '0;
               end
          end
     end

   // Contrôleur
   always_ff @(posedge VGA_CLK)
     begin
        if(RST)
          begin
             wb_m.adr = '0;
             wb_m.cyc = '0;
             wb_m.sel = '0;
             wb_m.stb = '0;
             wb_m.we = '0;
             wb_m.cti = '0;
             wb_m.bte = '0;
             fifo_ms_dat <= '0;
             fifo_ms_write <= 0;
             fifo_ms_read <= 0;
             fifo_sm_read <= 0;
             fifo_sm_write <= 0;
          end
        else
          begin
             fifo_ms_dat <= {VGA_R[4:0], VGA_G[5:0], VGA_B[4:0]};
             fifo_ms_write <= VGA_BLANK; // On ecrit dans la fifo les pixels utiles.
             fifo_ms_read <= 1;

             fifo_sm_read <= vga_enable && VGA_BLANK;
             fifo_sm_write <= wb_m.ack && mire_loaded;

             wb_m.adr <= 2*(ctH+ctV*HDISP);

             wb_m.cyc <= 1'b1;
             wb_m.sel <= 2'b11;
             wb_m.stb <= ~fifo_sm_wfull; // Si la FIFO est pleine, le contrôleur de lecture doit arrêter de faire des requètes
             wb_m.we <= ~mire_loaded;

             // Reset du burst cycle
             if(ctH == HDISP - 1'b1 && ctV == VDISP - 1'b1)
               wb_m.cti <= 3'b0;
             else
               wb_m.cti <= 3'b10;

             wb_m.bte <= '0;
          end
     end

endmodule