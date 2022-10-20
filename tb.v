`define CLK @(posedge pclk)
module tb_apbSlave();

reg pclk;
reg preset_n;
reg [1:0] add_i;
reg [31:0] prdata_i;
reg pready_i;

wire psel_o;
wire penable_o;
wire [31:0] paddr_o;
wire pwrite_o;
wire [31:0] pwdata_o;


apbAdderMaster UUT(pclk, preset_n, add_i, psel_o, penable_o, paddr_o, pwrite_o, pwdata_o, prdata_i, pready_i);

initial begin 
    pclk = 0;
    forever begin
        #5 pclk = ~pclk;
    end
end

// Drive Stimulus

initial begin
    preset_n = 1'b0; add_i = 2'b00;
    pready_i = 1'b0;
    repeat (2) `CLK;
    preset_n = 1'b1;
    repeat (2) `CLK;

    //Intiate a read transaction
    add_i = 2'b01;
    `CLK;
    add_i = 2'b00;
    repeat (4) `CLK;

    // Intiate a write transaction
    add_i = 2'b11;
    `CLK;
    add_i = 2'b00;
    repeat (4) `CLK;
    $finish;   
end
    // APB Slave
    always @(posedge pclk or negedge preset_n) begin
        if(!preset_n)
            pready_i = 1'b0;
        else begin
        if (psel_o && penable_o) begin
            pready_i = 1'b1;
            prdata_i = {$random} % 10;
        end
        else begin
            pready_i = 1'b0;
            prdata_i = {$random} % 10;
        end
    end
    end

// vcd dump file 
initial begin
    $dumpfile("apbSlave.vcd");
    $dumpvars(0, tb_apbSlave);
end


endmodule
