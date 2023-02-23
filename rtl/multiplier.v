/*
 *  kianv harris multicycle RISC-V rv32im
 *
 *  copyright (c) 2022 hirosh dabui <hirosh@dabui.de>
 *
 *  permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  the software is provided "as is" and the author disclaims all warranties
 *  with regard to this software including all implied warranties of
 *  merchantability and fitness. in no event shall the author be liable for
 *  any special, direct, indirect, or consequential damages or any damages
 *  whatsoever resulting from loss of use, data or profits, whether in an
 *  action of contract, negligence or other tortious action, arising out of
 *  or in connection with the use or performance of this software.
 *
 */

module multiplier
    (
        input wire clk,
        input wire reset,
        input  wire  [31               : 0]  factor1,
        input  wire  [31               : 0]  factor2,
        input  wire  [1                : 0]  MULop,
        output wire  [31               : 0]  product,
        input  wire                          valid,
        output reg                           ready
    );

    wire is_mulh  = MULop == 2'b01;
    wire is_mulsu = MULop == 2'b10;
    wire is_mulu  = MULop == 2'b11;

    wire factor1_is_signed = is_mulh | is_mulsu;
    wire factor2_is_signed = is_mulh;

    // multiplication
    reg [63: 0] rslt;
    reg [31: 0] factor1_abs;
    reg [31: 0] factor2_abs;

    localparam IDLE_BIT              = 0;
    localparam CALC_BIT              = 1;
    localparam READY_BIT             = 2;

    localparam IDLE                  = 1<<IDLE_BIT;
    localparam CALC                  = 1<<CALC_BIT;
    localparam READY                 = 1<<READY_BIT;

    localparam NR_STATES             = 3;

    (* onehot *)
    reg [NR_STATES-1:0] state;

    wire [31:0] rslt_upper_low = (is_mulh | is_mulu | is_mulsu) ? rslt[63:32] : rslt[31:0];
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            ready <= 1'b0;
        end else begin

            (* parallel_case, full_case *)
            case (1'b1)

                state[IDLE_BIT]: begin
                    ready <= 1'b0;
                    if (!ready && valid) begin
                        factor1_abs <= (factor1_is_signed & factor1[31]) ? ~factor1 + 1 : factor1;
                        factor2_abs <= (factor2_is_signed & factor2[31]) ? ~factor2 + 1 : factor2;
                        rslt <= 0;
                        state <= CALC;
                    end
                end

                state[CALC_BIT]: begin
                    rslt <= factor1_abs * factor2_abs;
                    state <= READY;
                end

                state[READY_BIT]: begin
                    /* verilator lint_off WIDTH */
                    rslt <= ((factor1[31] & factor1_is_signed ^ factor2[31] & factor2_is_signed)) ? ~rslt + 1 : rslt;
                    /* verilator lint_on WIDTH */

                    ready <= 1'b1;
                    state <= IDLE;
                end

            endcase

        end

    end

    assign product = rslt_upper_low;

endmodule
