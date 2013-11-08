module vga #(parameter HDISP = 640, VDISP = 480)(input CLK, RST,
                                                 output logic VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC,
                                                 output logic [9:0] VGA_R, VGA_G, VGA_B);

   localparam HFP = 16;
   localparam HPULSE = 96;
   localparam HBP = 48;

   localparam VFP = 11;
   localparam VPULSE = 2;
   localparam VBP = 31;

   enum   logic[2:0] {dispH, fpH, pulseH, bpH} stateH;
   enum   logic[2:0] {dispV, fpV, pulseV, bpV} stateV;

   logic [$clog2(HDISP)-1:0] ctH = 0;
   logic [$clog2(VDISP)-1:0] ctV = 0;

   VGA_PLL i_vga_pll(CLK, VGA_CLK);

   always_comb
     begin
        VGA_SYNC = 0;

        if(stateV == dispV && stateH == dispH)
          VGA_BLANK = 1;
        else
          VGA_BLANK = 0;

        if(stateV == pulseV)
          VGA_VS = 0;
        else
          VGA_VS = 1;

        if(stateH == pulseH)
          VGA_HS = 0;
        else
          VGA_HS = 1;
     end

   always_ff @(posedge VGA_CLK)
     begin
        if(RST)
          begin
             stateH <= dispH;
             ctH <= HDISP;
             stateV <= dispV;
             ctV <= VDISP;
          end
        else
          begin
             ctH <= ctH - 1;

             if(ctH == 0)
               begin
                  if(ctV == 0)
                    begin
                       case(stateV)
                         dispV:
                           begin
                              stateV <= fpV;
                              ctV <= VFP;
                           end
                         fpV:
                           begin
                              stateV <= pulseV;
                              ctV <= VPULSE;
                           end
                         pulseV:
                           begin
                              stateV <= bpV;
                              ctV <= VBP;
                           end
                         bpV:
                           begin
                              stateV <= dispV;
                              ctV <= VDISP;
                           end
                       endcase
                    end

                  case(stateH)
                    dispH:
                      begin
                         stateH <= fpH;
                         ctH <= HFP;
                      end
                    fpH:
                      begin
                         stateH <= pulseH;
                         ctH <= HPULSE;
                      end
                    pulseH:
                      begin
                         stateH <= bpH;
                         ctH <= HBP;
                      end
                    bpH:
                      begin
                         stateH <= dispH;
                         ctH <= HDISP;
                         ctV <= ctV - 1;
                      end
                  endcase
               end
          end
     end

   always_ff @(posedge VGA_CLK)
     begin
        if (RST)
          begin
             VGA_R <= 'b0;
             VGA_G <= 'b0;
             VGA_B <= 'b0;
          end
        else
          begin
             if (~(ctH % 16))
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
             if (~(ctV % 16))
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
          end // else: !if(RST)
     end


endmodule