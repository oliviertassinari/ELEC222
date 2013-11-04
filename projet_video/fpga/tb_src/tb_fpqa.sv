module tb_fpga;

   logic CLK, SW, NRST;

   // Horloge 50Mhz
   always #10ns CLK = ~CLK;

   fpga i_fpga(CLK, SW, NRST, LED_ROUGE, LED_VERTE);

   initial
     begin: entree
        CLK = 1'b0;
        NRST = 1'b0;
        SW = 1'b0;

        repeat(1000)
        begin
           @(posedge CLK);
           SW = $random;
        end

        $display("done");
        $finish;
     end

endmodule