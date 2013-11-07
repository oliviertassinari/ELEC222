module vga #(parameter HDISP = 640, VDISP = 480)(CLK, RST, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC)

   localparam HFP = 16;
   localparam HPULSE = 96;
   localparam HBP = 48;

   localparam VFP = 11;
   localparam VPULSE = 2;
   localparam VBP = 31;

   input CLK, RST;
   output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC;

   enum   logic[2:0] {disp, fp, pulse, bp} stateH;
   enum   logic[2:0] {disp, fp, pulse, bp} stateV;

   logic [31:0] ctH = 0;
   logic [31:0] ctV = 0;

   logic rst_async;
   reset #(.is_nrst('b0)) reset_i(.CLK(VGA_CLK), .RST(RST), .rst_async(rst_async));

   always_comb
     begin
        VGA_SYNC = 0;
        VGA_CLK = CLK;

        if(stateV == disp && stateH == disp)
          VGA_BLANK = 1;
        else
          VGA_BLANK = 0;

        if(stateV == pulse)
          VGA_VS = 0;
        else
          VGA_VS = 1;

        if(stateH == pulse)
          VGA_HS = 0;
        else
          VGA_HS = 1;
     end

   always_ff
     begin
        if(rst_async)
          begin
             stateH <= disp;
             ctH <= HDISP;
             stateV <= disp;
             ctV <= VDISP;
          end
        else
          begin
             ctH <= ctH - 1;

             if(ctH == 0)
               begin
                  if(stateH == bp)
                    begin
                       case(stateV)
                         disp:
                           begin
                              stateV <= fp;
                              ctV <= VFP;
                           end
                         fp:
                           begin
                              stateV <= pulse;
                              ctV <= VPULSE;
                           end
                         puls:
                           begin
                              stateV <= bp;
                              ctV <= VBP;
                           end
                         bp:
                           begin
                              stateV <= disp;
                              ctV <= VDISP;
                           end
                       endcase
                    end

                  case(stateH)
                    disp:
                      begin
                         stateH <= fp;
                         ctH <= HFP;
                      end
                    fp:
                      begin
                         stateH <= pulse;
                         ctH <= HPULSE;
                      end
                    puls:
                      begin
                         stateH <= bp;
                         ctH <= HBP;
                      end
                    bp:
                      begin
                         stateH <= disp;
                         ctH <= HDISP;
                         ctV <= ctV - 1;
                      end
                  endcase
               end
          end
     end

endmodule