////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: SPI (Verilog)                                            ////
////                                                                        ////
//// Module Name: spi_slave                                                ////
////                                                                        ////
////                                                                        ////
////  This file is part of the Ethernet IP core project                     ////
////  http://opencores.com/project,spi_verilog_master_slave                 ////
////                                                                        ////
////  Author(s):                                                            ////
////      Santhosh G (santhg@opencores.org)                                 ////
////                                                                        ////
////  Refer to Readme.txt for more information                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Copyright (C) 2014, 2015 Authors                                       ////
////                                                                        ////
//// This source file may be used and distributed without                   ////
//// restriction provided that this copyright statement is not              ////
//// removed from the file and that any derivative work contains            ////
//// the original copyright notice and the associated disclaimer.           ////
////                                                                        ////
//// This source file is free software; you can redistribute it             ////
//// and/or modify it under the terms of the GNU Lesser General             ////
//// Public License as published by the Free Software Foundation;           ////
//// either version 2.1 of the License, or (at your option) any             ////
//// later version.                                                         ////
////                                                                        ////
//// This source is distributed in the hope that it will be                 ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied             ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR                ////
//// PURPOSE.  See the GNU Lesser General Public License for more           ////
//// details.                                                               ////
////                                                                        ////
//// You should have received a copy of the GNU Lesser General              ////
//// Public License along with this source; if not, download it             ////
//// from http://www.opencores.org/lgpl.shtml                               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
/* SPI MODE 3
		CHANGE DATA (miso) @ NEGEDGE SCK
		read data (mosi) @posedge SCK
*/		

module spi_slave
(
    input            reset,

    input            ss,
    input            sclk,
    input            mosi,
    output           miso,

    input            msb_first,
    input            txen,
    input      [7:0] txdata,
    output reg [7:0] rxdata,
    output reg       done
);

    reg [7:0] treg, rreg;
    reg [3:0] nb;
    wire sout;
  
    assign sout = msb_first ? treg[7] : treg[0];
    assign miso = (!ss && txen) ? sout : 1'bz;


    //read from  miso
    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            rreg   = 8'h00;
            rxdata = 8'h00;
            done   = 0;
            nb     = 0;
        end
        else if (!ss) begin 
            if(msb_first) begin
                rreg = {rreg[6:0], mosi};
            end
            else begin
                rreg = {mosi, rreg[7:1]};
            end  

            //increment bit count
            nb = nb + 1;
            if (nb != 8) begin
                done = 0;
            end
            else begin
                rxdata = rreg;
                done   = 1;
                nb     = 0;
            end
        end
    end

    //send to  miso
    always @(negedge sclk or posedge reset) begin
        if (reset) begin
            treg <= 8'hFF;
        end
        else if (!ss) begin			
            if (nb == 0) begin
                treg <= txdata;
            end
            else if (msb_first) begin
                treg <= {treg[6:0], 1'b1};
            end
            else begin
                treg <= {1'b1, treg[7:1]};
            end
        end
    end

endmodule
