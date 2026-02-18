module Pattern();

    parameter DATA_W  = 32;
    parameter ADDR_W  = 32;
    parameter BRAM_DEPTH = 1024;
    parameter BRAM_ADDR_W = $clog2(BRAM_DEPTH);

    // Clock and Reset
    reg                     ACLK;
    reg                     ARESETn;

    // CPU Fetch Interface
    reg                     CPU_REQ;
    reg     [ADDR_W-1:0]    CPU_REQ_ADDR;
    wire                    CPU_REQ_VALID;
    wire    [DATA_W-1:0]    CPU_REQ_DATA;

    // CPU Write Interface
    reg                     CPU_WR_EN;
    reg     [DATA_W-1:0]    CPU_WR_DATA;
    reg     [DATA_W/8-1:0]  CPU_WR_STRB;

    // Cache Control
    wire                    BUSY;

    integer i;

    reg [DATA_W-1:0] DATA_TEMP [0:BRAM_DEPTH-1];

    Tested #(
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .BRAM_DEPTH(BRAM_DEPTH),
        .BRAM_ADDR_W(BRAM_ADDR_W)
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .CPU_REQ(CPU_REQ),
        .CPU_REQ_ADDR(CPU_REQ_ADDR),
        .CPU_REQ_VALID(CPU_REQ_VALID),
        .CPU_REQ_DATA(CPU_REQ_DATA),
        .CPU_WR_EN(CPU_WR_EN),
        .CPU_WR_DATA(CPU_WR_DATA),
        .CPU_WR_STRB(CPU_WR_STRB),
        .BUSY(BUSY));

    always #5 ACLK = ~ACLK; // 100MHz clock

    initial begin
        ACLK = 0;
        ARESETn = 1;
        CPU_REQ_ADDR = 0;
        RESET_ALL();
        #120; 
        @(negedge ACLK) ARESETn = 0;
        @(negedge ACLK) ARESETn = 1;

        // Tese Case 1 : 
        for(i=0; i<BRAM_DEPTH; i=i+1) begin
            DATA_TEMP[i] = $random;
            WRITE_DATA(CPU_REQ_ADDR, DATA_TEMP[i], 4'b1111);
            CPU_REQ_ADDR = CPU_REQ_ADDR + 4;
        end
        CPU_REQ_ADDR = 0;
        for(i=0; i<BRAM_DEPTH; i=i+1) begin
            READ_DATA(CPU_REQ_ADDR, DATA_TEMP[i]);
            CPU_REQ_ADDR = CPU_REQ_ADDR + 4;
        end

        CPU_REQ_ADDR = 0;
        // Test Case 2 : 
        for(i=0; i<BRAM_DEPTH; i=i+1) begin
            DATA_TEMP[i] = $random;
            WRITE_DATA(CPU_REQ_ADDR, DATA_TEMP[i], 4'b1111);
            READ_DATA(CPU_REQ_ADDR, DATA_TEMP[i]);
            CPU_REQ_ADDR = CPU_REQ_ADDR + 4;
        end       
        
        // Test Case 3 :
        for(i=0; i<BRAM_DEPTH; i=i+1) begin
            DATA_TEMP[i] = $random;
            CPU_REQ_ADDR = $random % BRAM_DEPTH * 4;
            WRITE_DATA(CPU_REQ_ADDR, DATA_TEMP[i], 4'b1111);
            READ_DATA(CPU_REQ_ADDR, DATA_TEMP[i]);
        end

        #20 begin 
            $display("All test cases passed ! ! !");
            #10 $finish;
        end
    end

    task WRITE_DATA;
        input [ADDR_W-1:0] addr;
        input [DATA_W-1:0] data;
        input [DATA_W/8-1:0] strb;
    begin
        CPU_WR_EN = 1;
        CPU_WR_DATA = data;
        CPU_WR_STRB = strb;
        CPU_REQ_ADDR = addr;
        @(negedge BUSY);
        RESET_ALL();
    end
    endtask

    task READ_DATA;
        input [ADDR_W-1:0] addr;
        input [DATA_W-1:0] expected;
        begin
            @(negedge ACLK);
            CPU_REQ = 1;
            CPU_REQ_ADDR = addr;
            wait(CPU_REQ_VALID);
            $display("Read from address %h, Get data = %h, Expected = %h", addr, CPU_REQ_DATA, expected);
            if(CPU_REQ_DATA != expected) begin
                $display("Error: Expected data %h, Got data %h", expected, CPU_REQ_DATA);
                #10 $finish;
            end
            RESET_ALL();
        end
    endtask



    task RESET_ALL;
        begin
            @(negedge ACLK);
            CPU_REQ = 0;
            CPU_WR_EN = 0;
            CPU_WR_DATA = 0;
            CPU_WR_STRB = 0;
        end
    endtask


endmodule