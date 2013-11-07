module vga (CLK, RST, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC)

   localparam HDISP = 640;
   localparam VDISP = 480;
   localparam HFP = 16;
   localparam HPULSE = 96;
   localparam HBP = 48;
   localparam VFP = 11;
   localparam VPULSE = 2;
   localparam VBP = 31;

   input CLK, RST;
   output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC;

   always_comb
     begin
        VGA_SYNC = 0;
        VGA_CLK = CLK;
     end

endmodule