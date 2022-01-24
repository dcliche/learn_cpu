module memory(
    input  wire logic        clk,
    input  wire logic [15:0] i_addr_i,     // instruction port
    output      logic [15:0] i_data_out_o,
    input  wire logic [15:0] d_addr_i,     // data port
    input  wire logic        d_we_i,
    input  wire logic [15:0] d_data_in_i,
    output      logic [15:0] d_data_out_o
    );

    logic [15:0] mem_array[1023:0];

    initial begin
        $readmemh("program.hex", mem_array);
    end

    always_ff @(posedge clk) begin
        if (d_we_i) begin
            mem_array[d_addr_i[9:0]] <= d_data_in_i;
        end
    end

    always_comb begin
        d_data_out_o = mem_array[d_addr_i[9:0]];
        i_data_out_o = mem_array[i_addr_i[9:0]];
    end

endmodule