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

   localparam logic [$clog2(HDISP*VDISP)-1:0] NBPIX = HDISP*VDISP;

   logic [$clog2(HDISP<<1)-1:0]            ctH;
   logic [$clog2(VDISP<<1)-1:0]            ctV;

   logic [$clog2(NBPIX)-1:0]               ctMire;
   logic [$clog2(NBPIX)-1:0]               ctFifo;

   logic                                   vga_enable, mire_loaded, wait_ack, fifo_start;
   logic [15:0]                            fifo_sm_dat;
   logic                                   fifo_sm_read, fifo_sm_rempty, fifo_sm_write, fifo_sm_wfull;

   /* Instanciation des modules complémentaires */
   VGA_PLL vga_pll_i(CLK, VGA_CLK);

   /* Fifo */
   fifo_async #(16, 8)  fifo_async_i_sm(.rst(RST),
                                        .rclk(VGA_CLK),
                                        .read(fifo_sm_read),
                                        .rdata(fifo_sm_dat),
                                        .rempty(fifo_sm_rempty),
                                        .wclk(wb_m.clk),
                                        .wdata(wb_m.dat_sm),
                                        .write(fifo_sm_write),
                                        .wfull(fifo_sm_wfull));

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

   // Compteurs de synchronisation
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
                  VGA_R <= { fifo_sm_dat[4:0], 5'b0 };
                  VGA_G <= { fifo_sm_dat[10:5], 4'b0 };
                  VGA_B <= { fifo_sm_dat[15:11], 5'b0 };
               end
             else
               begin
                  VGA_R <= '0;
                  VGA_G <= '0;
                  VGA_B <= '0;
               end
          end
     end

   // Compteurs de la mire
   always_ff @(posedge wb_m.clk)
     begin
        if(RST)
          begin
             mire_loaded <= 0;
             ctMire <= 0;
          end
        else
          if(!mire_loaded)
            begin
               if(!wait_ack)
                 begin
                    ctMire <= ctMire + 1'b1;
                    wait_ack <= 1;

                    if(ctMire == NBPIX-1)
                      begin
                         mire_loaded <= 1;
                      end
                 end
            end
     end

   // Controleur wishbone et FIFO
   always_ff @(posedge wb_m.clk)
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
             vga_enable <= 0;
             fifo_start <= 0;
             ctFifo <= '0;
             wait_ack <= 1;
          end
        else
          begin
             wb_m.cyc <= 1;
             wb_m.sel <= 2'b11;
             wb_m.cti <= '0;
             wb_m.bte <= '0;

             if(!mire_loaded)
               begin
                  wb_m.adr <= 2*ctMire;
                  wb_m.dat_ms <= { 10'b0, ctMire[5:0]};
                  wb_m.stb <= 1;
                  wb_m.we <= 1;
               end
             else
               begin
                  wb_m.adr <= 2*ctFifo;
                  wb_m.we <= 0;

                  if(!fifo_sm_wfull)
                    begin
                       if(ctFifo == NBPIX-1)
                         ctFifo <= 0;
                       else
                         ctFifo <= ctFifo + 1'b1;

                       wb_m.stb <= 1;
                    end
                  else
                    begin
                       wb_m.stb <= 0;

                       if(!vga_enable && ctV == VDISP + VFP + VPULSE + VBP - 1'b1 && ctH == HDISP + HFP + HPULSE + HBP - 1'b1)
                         vga_enable <= 1;
                    end
               end
          end
     end

   // Controle FIFO
   always_comb
     begin
        if(wb_m.stb && wb_m.we == 0)
          fifo_sm_write = 1;
        else
          fifo_sm_write = 0;

        if(vga_enable && VGA_BLANK)
          fifo_sm_read = 1;
        else
          fifo_sm_read = 0;
     end

endmodule