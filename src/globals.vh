// -----------------------------------------------------------------------------
//    Copyright (C) 2016 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

`define LED_DATA_WIDTH          24
`define LEDS_NUM                12

`define IMG_WIDTH               12
`define IMG_HEIGHT              (`LEDS_NUM)

`define NBUFS                   16
`define BUF_SIZE                1024
`define BUF_ID_LOWER_BIT        (clogb2(`BUF_SIZE))

`define FIRST_BASE_BIT          28

`define BUF_MANAGER_BASE        1
`define MEM_BASE                2
`define SPI_BASE                3

`define BUF_MANAGER_BASE_ADDR   (`BUF_MANAGER_BASE << `FIRST_BASE_BIT)
`define MEM_BASE_ADDR           (`MEM_BASE         << `FIRST_BASE_BIT)
`define SPI_BASE_ADDR           (`SPI_BASE         << `FIRST_BASE_BIT)

`define COLUMN_TIME             200000
`define FRAME_TIME              (2 * `COLUMN_TIME * `IMG_WIDTH)



// ---------------------------------------------------------
function integer addr_base;
    input [31:0] addr;
    begin
        addr_base = addr[31:`FIRST_BASE_BIT];
    end
endfunction


function integer addr_without_base;
    input [31:0] addr;
    begin
        addr_without_base = addr[`FIRST_BASE_BIT-1:0];
    end
endfunction


function integer clogb2;
    input [31:0] value;
    begin
        value = value - 1;
        for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
            value = value >> 1;
        end
    end
endfunction


function integer addr_for_buf_id;
    input [31:0] buf_id;
    begin
        addr_for_buf_id = `MEM_BASE_ADDR | buf_id << `BUF_ID_LOWER_BIT;
    end
endfunction

 

