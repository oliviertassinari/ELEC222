//-----------------------------------------------------------------
// Wishbone BlockRAM
// Guénolé LALLEMENT
//
// Input slave 
//     input  adr ,  
//     input  sel ,  
//     input  stb ,  
//     input  we,    
//     input  cyc ,  
//     input  dat_ms,
//     input  cti,   // non utilisé
//     input  bte,   // non utilisé
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
   logic 	    state ;
     	
   /* Signaux non utilisés */
   assign wb_s.err = 0; 
   assign wb_s.rty = 0;
   assign wb_s.ack = state ;
      
   always_ff @(posedge wb_s.clk)
     begin
	if(~wb_s.rst)
	  begin
	     state <= 0;
	     
	     wb_s.dat_sm <= mem[wb_s.adr[adr_width-1:0]];  // lecture (ici, sel n'est pas utile tant que dat_sm contient les bonnes données
	     
	     if (wb_s.stb & wb_s.cyc)
	       begin
		  state <= !state;
		  if(wb_s.we) // écriture
		    for (int i = 0; i < 4; i++) // prise en compte du masque
		      if (wb_s.sel[i] == 'b1)
			mem[wb_s.adr[adr_width-1:0]][i] <= wb_s.dat_ms[8*i+:8];
	       end
	  end
     end
endmodule

