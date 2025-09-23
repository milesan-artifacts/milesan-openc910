import "DPI-C" function string getenv(input string env_name);
`timescale 100ns/100ns
module tb_top();

    localparam time CLK_PERIOD          = 200ns;
    localparam time APPL_DELAY          = 10ns;
    localparam time ACQ_DELAY           = 30ns;
    localparam unsigned RST_CLK_CYCLES  = 10;
    // localparam unsigned TOT_STIMS       = 10000;
    // localparam unsigned TIMEOUT_LIM     = 1000;

    localparam int unsigned SRAM_ADDR_WIDTH = 21;
    localparam int unsigned SRAM_DATA_WIDTH = 128;

    localparam type addr_t = logic [SRAM_ADDR_WIDTH-1:0];
    localparam type data_t = logic [SRAM_DATA_WIDTH-1:0];
    localparam type strb_t = logic [SRAM_DATA_WIDTH-1:0];

    localparam [63:0] ADDR_STOP_SIG = 64'h0;
    localparam [63:0] ADDR_IREG_DUMP_SIG = 64'h10 >> 4;
    localparam [63:0] ADDR_REGSTREAM_DUMP_SIG = 64'h20 >> 4;


    logic clk;
    logic rst_n;


    logic  mem_req;
    addr_t mem_addr;
    data_t mem_wdata;
    strb_t mem_strb;
    logic  mem_we;
    data_t mem_rdata;

    logic  mem_req_t0;
    addr_t mem_addr_t0;
    data_t mem_wdata_t0;
    strb_t mem_strb_t0;
    logic  mem_we_t0;
    data_t mem_rdata_t0;


    clk_rst_gen #(
        .CLK_PERIOD     (CLK_PERIOD),
        .RST_CLK_CYCLES (RST_CLK_CYCLES)
    ) i_clk_rst_gen (
        .clk_o  (clk),
        .rst_no (rst_n)
    );

    openc910_tiny_soc i_dut (
        .i_pad_clk(clk),
        .i_pad_rst_b(rst_n),

        .i_pad_jtg_tclk(1'b0),
        .i_pad_jtg_tdi(1'b0),
        .i_pad_jtg_tms(1'b0),
        .i_pad_jtg_trst_b(1'b0),
        .i_pad_uart0_sin(1'b0),

        .o_pad_jtg_tdo(),
        .o_pad_uart0_sout(),
        .b_pad_gpio_porta(),

        .mem_req_o(mem_req),
        .mem_addr_o(mem_addr),
        .mem_wdata_o(mem_wdata),
        .mem_strb_o(mem_strb),
        .mem_we_o(mem_we),
        .mem_rdata_o(mem_rdata),

        .mem_req_o_t0(mem_req_t0),
        .mem_addr_o_t0(mem_addr_t0),
        .mem_wdata_o_t0(mem_wdata_t0),
        .mem_strb_o_t0(mem_strb_t0),
        .mem_we_o_t0(mem_we_t0),
        .mem_rdata_o_t0(mem_rdata_t0)

    );

    initial begin: application_block
        wait (rst_n);

        @(posedge clk);
        #(APPL_DELAY);
    end

    initial begin: acquisition_block
        bit got_stop_req;
        int remaining_before_stop;
        int step_id;
        int simlen;
        string regdump_path;
        string regstream_path;
        int regdump_fp;
        int regstream_fp;

        int int_req_dump_id = 1;
        int stream_req_dump_id = 0;
        int float_req_dump_id = 0;

        wait (rst_n);

        got_stop_req = 0;
        step_id = 0;
        remaining_before_stop = 50;
        simlen = getenv("SIMLEN").atoi();

        regdump_path = getenv("REGDUMP_PATH");
        regstream_path = getenv("REGSTREAM_PATH");

        regdump_fp = $fopen(regdump_path,"a");
        regstream_fp = $fopen(regstream_path,"a");

        $fwrite(regdump_fp,"[\n");
        $fwrite(regstream_fp,"[\n");
        forever begin
            @(posedge clk);
            #(ACQ_DELAY);

            // Check whether got a stop request
            if (!got_stop_req &&
                    mem_req &&
                    mem_we &&
                    // mem_wdata == 0 &&
                    mem_addr == ADDR_STOP_SIG) begin
                $display("Found a stop request after ", step_id, " ticks. Stopping the benchmark after ", remaining_before_stop, " more ticks.");
                got_stop_req = 1;
            end

            // Register dumps
            if (!got_stop_req &&
                    mem_req &&
                    mem_we &&
                    // mem_wdata == 0 &&
                    mem_addr == ADDR_IREG_DUMP_SIG) begin
                if ($isunknown(mem_wdata)) begin
                    $display("Dump of reg x%02d: 0x%16h, 0x%16h", int_req_dump_id, 64'hbadcab1ebadcab1e, 64'hbadcab1ebadcab1e);
                    if (int_req_dump_id == 1)
                        $fwrite(regdump_fp,"\t{\"id\": \"i%02d\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",int_req_dump_id,64'hbadcab1ebadcab1e,64'hbadcab1ebadcab1e);
                    else
                        $fwrite(regdump_fp,",\n\t{\"id\": \"i%02d\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",int_req_dump_id,64'hbadcab1ebadcab1e,64'hbadcab1ebadcab1e);
                end else begin
                    $display("Dump of reg x%02d: 0x%16h, 0x%16h", int_req_dump_id, mem_wdata&64'hFFFF_FFFF_FFFF_FFFF, mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                    if (int_req_dump_id == 1)
                        $fwrite(regdump_fp,"\t{\"id\": \"i%02d\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",int_req_dump_id, mem_wdata&64'hFFFF_FFFF_FFFF_FFFF, mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                    else
                        $fwrite(regdump_fp,",\n\t{\"id\": \"i%02d\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",int_req_dump_id, mem_wdata&64'hFFFF_FFFF_FFFF_FFFF ,mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                end
                int_req_dump_id += 1;
            end

            if (!got_stop_req &&
                    mem_req &&
                    mem_we &&
                    // mem_wdata == 0 &&
                    mem_addr == ADDR_REGSTREAM_DUMP_SIG) begin
                if ($isunknown(mem_wdata)) begin
                    $display("Dump at idx %02d: 0x%16h", stream_req_dump_id, 64'hbadcab1ebadcab1e);
                    if (stream_req_dump_id == 0)
                        $fwrite(regstream_fp,"\t{\"id\": \"0x%h\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",stream_req_dump_id,64'hbadcab1ebadcab1e,64'hbadcab1ebadcab1e);
                    else
                        $fwrite(regstream_fp,",\n\t{\"id\": \"0x%h\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",stream_req_dump_id,64'hbadcab1ebadcab1e,64'hbadcab1ebadcab1e);
                end else begin
                    $display("Dump at idx %02d: 0x%16h, 0x%16h", stream_req_dump_id, mem_wdata&64'hFFFF_FFFF_FFFF_FFFF, mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                    if (stream_req_dump_id == 0)
                        $fwrite(regstream_fp,"\t{\"id\": \"0x%h\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",stream_req_dump_id,mem_wdata&64'hFFFF_FFFF_FFFF_FFFF,mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                    else
                        $fwrite(regstream_fp,",\n\t{\"id\": \"0x%h\", \"value\": \"0x%16h\", \"value_t0\": \"0x%16h\"}",stream_req_dump_id,mem_wdata&64'hFFFF_FFFF_FFFF_FFFF,mem_wdata_t0&64'hFFFF_FFFF_FFFF_FFFF);
                end
                stream_req_dump_id += 1;
            end

            // Decrement if got a stop request.
            if (got_stop_req) begin
                if (remaining_before_stop-- == 0)
                    break;
            end
            // "Natural" stop since SIMLEN has been reached
            if (step_id == simlen-1) begin
                $display("Reached SIMLEN (%d cycles). Stopping.", simlen);
                break;
            end

            step_id++;
        end
        
        $fwrite(regdump_fp,"\n]");
        $fwrite(regstream_fp,"\n]");
        $stop();
    end

endmodule
