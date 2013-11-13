//-----------------------------------------------------------------
// Wishbone BlockRAM - Pipelined
// Guénolé LALLEMENT
//
// Input slave 
//     input  adr ,  
//     input  sel ,  
//     input  stb ,  
//     input  we,    
//     input  cyc ,  
//     input  dat_ms,
//     input  cti,   // utilisé : TAG - type de transfert (classique, burst)
//     input  bte,   // utilisé : TAG - type de burst 
//     input  clk,
//     input  rst
//
// Output slave
//     output dat_sm,
//     output ack ,  
//     output err ,  
//     output rty ,  
//
//
//-----------------------------------------------------------------

module wb_bram #(parameter adr_width = 11) (
					    // Wishbone interface
					    wshb_if_DATA_BYTES_4_ADDRESS_WIDTH_32.slave wb_s
					    );

   /* Tableau représentant les données en RAM */
   logic [3:0][7:0] mem [0:2**adr_width-1];
   logic	    state ;
   logic [adr_width-1:0] adr;
   
   /* Signaux non utilisés */
   assign wb_s.err = 0; 
   assign wb_s.rty = 0;
   assign wb_s.ack = (state || (wb_s.cti == 'b010 && wb_s.we));

   always_comb
     begin
	if (state && ~wb_s.we && wb_s.cti[1])
	  adr = wb_s.adr + 'd4;
       	else
	  adr = wb_s.adr;
     end
   
   always_ff @(posedge wb_s.clk)
     begin
	if(~wb_s.rst)
	  begin
	     state <= 'b0;
	     
	     if (wb_s.stb & wb_s.cyc)
	       begin
		  if (wb_s.cti == 'b010) state <= 'b1;
		  else state <= !state;

		  if(wb_s.we) // écriture
		    for (int i = 0; i < 4; i++) // prise en compte du masque
		      if (wb_s.sel[i] == 'b1) 
			mem[adr][i] <= wb_s.dat_ms[8*i+:8];
		  
		  wb_s.dat_sm <= mem[adr];  // lecture
	       end
	  end // if(~wb_s.rst)
     end // always_ff @
endmodule