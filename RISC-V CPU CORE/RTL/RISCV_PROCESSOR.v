`include "SYSTEM_DEF.vh"

module RISCV_PROCESSOR(
    input ACLK,
    input ARESETn);

    localparam DATA_W  = 32;
    localparam ADDR_W  = 32;
    localparam BRAM_DEPTH = 1024;
    localparam BRAM_ADDR_W = $clog2(BRAM_DEPTH);

    wire                   AR_VALID, AR_READY;
    wire [`PC_WIDTH-1:0]   AR_ADDR;
    wire                   R_VALID,  R_READY;
    wire [`DATA_WIDTH-1:0] R_DATA;
    wire [BRAM_ADDR_W-1:0] SLAVE_ADDR;
    wire [`DATA_WIDTH-1:0] SLAVE_DOUT;
    wire [3:0]             SLAVE_WE;
    wire [`DATA_WIDTH-1:0] SLAVE_DIN;

    // BRAM Instance
    blk_mem_gen_0 Instruction_Mem (
        .addra(SLAVE_ADDR),
        .clka(ACLK),
        .douta(SLAVE_DOUT));

    // AXI4-Lite Bus - Protocol Handler
    AXI4_Lite_Bus #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .BRAM_DEPTH(BRAM_DEPTH),
        .BRAM_ADDR_W(BRAM_ADDR_W)
    ) Instruction_AXI4_Lite_Bus (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        // Write channels - TIED OFF (no writes from Cache)
        .AW_VALID(1'b0),
        .AW_READY(), // Leave unconnected
        .AW_ADDR({ADDR_W{1'b0}}),
        .W_VALID(1'b0),
        .W_READY(), // Leave unconnected
        .W_DATA({DATA_W{1'b0}}),
        .W_STRB({(DATA_W/8){1'b0}}),
        .B_VALID(), // Leave unconnected
        .B_READY(1'b0),
        .B_RESP(), // Leave unconnected

        // Read channels - FROM CACHE
        .AR_VALID(AR_VALID),
        .AR_READY(AR_READY),
        .AR_ADDR(AR_ADDR),
        .R_VALID(R_VALID),
        .R_READY(R_READY),
        .R_DATA(R_DATA),
        .R_RESP(),          // Leave unconnected (always OKAY)

        // BRAM interface (unchanged)
        .SLAVE_WE(SLAVE_WE),
        .SLAVE_ADDR(SLAVE_ADDR),
        .SLAVE_DIN(SLAVE_DIN),
        .SLAVE_DOUT(SLAVE_DOUT));

    RISCV_CPU RISC_V_CPU_inst(
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .I_AR_ADDR(AR_ADDR),
        .I_R_DATA(R_DATA),
        .I_AR_VALID(AR_VALID),
        .I_AR_READY(AR_READY),
        .I_R_VALID(R_VALID),
        .I_R_READY(R_READY));

endmodule