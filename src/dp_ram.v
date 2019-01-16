//-----------------------------------------------------
// Design Name : ram_dp_sr_sw
// File Name   : ram_dp_sr_sw.v
// Function    : Synchronous read write RAM
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module dp_ram (
    clk    ,
    wr     ,
    wr_addr,
    wr_data,
    rd     ,
    rd_addr,
    rd_data
); 

parameter DATA_WIDTH = 8 ;
parameter ADDR_WIDTH = 8 ;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

//--------------Input Ports----------------------- 
//
input clk;
input wr;
input [ADDR_WIDTH-1:0] wr_addr;
input [DATA_WIDTH-1:0] wr_data;
input rd;
input [ADDR_WIDTH-1:0] rd_addr;
output [DATA_WIDTH-1:0] rd_data;


//--------------Internal variables---------------- 
reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];


//--------------Code Starts Here------------------ 
// Memory Write Block 
always @ (posedge clk) begin
    if (wr) begin
        mem[wr_addr] <= wr_data;
    end
end

// Memory Read Block 
assign rd_data = mem[rd_addr]; 

endmodule
