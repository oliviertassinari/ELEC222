module vga (CLK, RST, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC)

   input CLK, RST;
   output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC;

   always_comb
     begin
        VGA_SYNC = 0;
        VGA_CLK = CLK;
     end

endmodule