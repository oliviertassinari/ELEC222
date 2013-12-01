module mire #(parameter HDISP = 640, VDISP = 480)(
        wshb_if_DATA_BYTES_2_ADDRESS_WIDTH_32.master wb_m
    );

    localparam logic [$clog2(HDISP*VDISP)-1:0] NBPIX = HDISP*VDISP;

    logic [$clog2(NBPIX)-1:0]               ctMire;
    logic                                   mire_loaded, cyc;

    always_ff @(posedge wb_m.clk)
    begin
       if(wb_m.rst)
       begin
            mire_loaded <= 0;
            cyc <= 1;
            ctMire <= '0;
       end
       else
          if(!mire_loaded)
            begin
                if(cyc == 0)
                    cyc <= 1;

               if(wb_m.ack)
                 begin
                    ctMire <= ctMire + 1'b1;
                    cyc <= 0;

                    if(ctMire == NBPIX - 1'b1)
                      begin
                         mire_loaded <= 1;
                      end
                 end
            end
       end
    end

    always_comb
    begin
        wb_m.cyc = 0;
        wb_m.sel = 2'b11;
        wb_m.cti = '0;
        wb_m.bte = '0;
        wb_m.adr = '0;
        wb_m.dat_ms = '0;
        wb_m.stb = 0;
        wb_m.we = 0;

        if(!mire_loaded)
          begin
             wb_m.cyc = cyc;
             wb_m.adr = 2*ctMire;
             wb_m.dat_ms = { 6'b0, ctMire[9:0]};
             wb_m.stb = 1;
             wb_m.we = 1;
          end
    end

endmodule