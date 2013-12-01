module wb16_intercon (
                      wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.slave wb_s1,
                      wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.slave wb_s2,
                      wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.master wb_m                      );

   logic tour;

   always_ff @(posedge wb_m.clk)
     begin
        if(wb_m.rst)
          tour <= 0;
        else
          begin
             if(wb_s2.cyc == 1)
               if(!(tour == 0 && wb_s1.cyc == 1))
                  tour <= 1;
             else if(wb_s1.cyc == 1)
               if(!(tour == 1 && wb_s2.cyc == 1))
                 tour <= 0;
          end
     end

   always_comb
     begin
        wb_s1.ack = 0;
        wb_s1.dat_sm = '0;
        wb_s2.ack = 0;
        wb_s2.dat_sm = '0;

        if(tour == 0) // s1
          begin
             wb_m.cyc = wb_s1.cyc;
             wb_m.sel = wb_s1.sel;
             wb_m.cti = wb_s1.cti;
             wb_m.bte = wb_s1.bte;
             wb_m.adr = wb_s1.adr;
             wb_m.dat_ms = wb_s1.dat_ms;
             wb_m.stb = wb_s1.stb;
             wb_m.we = wb_s1.we;

             wb_s1.ack = wb_m.ack;
             wb_s1.dat_sm = wb_m.dat_sm;
          end
        else // s2
          begin
             wb_m.cyc = wb_s2.cyc;
             wb_m.sel = wb_s2.sel;
             wb_m.cti = wb_s2.cti;
             wb_m.bte = wb_s2.bte;
             wb_m.adr = wb_s2.adr;
             wb_m.dat_ms = wb_s2.dat_ms;
             wb_m.stb = wb_s2.stb;
             wb_m.we = wb_s2.we;

             wb_s2.ack = wb_m.ack;
             wb_s2.dat_sm = wb_m.dat_sm;
          end
     end

endmodule