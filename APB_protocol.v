module apbAdderMaster #(parameter N=32)( pclk, preset_n, add_i, psel_o, penable_o, paddr_o, pwrite_o, pwdata_o, prdata_i, pready_i);

input pclk;
input preset_n; // Active low reset
input [1:0] add_i; // 2'b00 = NO OP , 2'b01 = READ, 2'b10 = NO OP, 2'b11 = WRITE
input [N-1:0] prdata_i;
input pready_i;

output psel_o;
output penable_o;
output [N-1:0] paddr_o;
output pwrite_o;
output [N-1:0] pwdata_o;

wire apb_state_setup, apb_state_access;
reg pwrite_q, nxt_pwrite;
reg [N-1:0] nxt_rdata, rdata_q;


//parameter [1:0] state;
localparam ST_IDLE = 2'b00, ST_SETUP = 2'b01, ST_ACCESS = 2'b11 ;

reg [1:0] cur_state_q, nxt_state;

always @(posedge pclk  or negedge preset_n)
	if(!preset_n)
		cur_state_q <= ST_IDLE;
	else
		cur_state_q <= nxt_state;


always @(*) begin
	nxt_pwrite = pwrite_q;
    nxt_rdata = rdata_q;
	case (cur_state_q)
	ST_IDLE : if(add_i[0]) begin
			nxt_state = ST_SETUP; 
			nxt_pwrite = add_i[1] ; end
		  else begin
			nxt_state = ST_IDLE; end
	ST_SETUP : nxt_state = ST_ACCESS; // assuming that Penable is always asserted 1 cycle after Psel
	ST_ACCESS : if(pready_i) begin
                if(!pwrite_q)
                    nxt_rdata = prdata_i;
			nxt_state = ST_IDLE; end
		    else begin 
			nxt_state = ST_ACCESS; end
	default : nxt_state = ST_IDLE;
    endcase
end

assign apb_state_access = (cur_state_q == ST_ACCESS);
assign apb_state_setup = (cur_state_q == ST_SETUP);


assign psel_o = apb_state_setup | apb_state_access ;
assign penable_o = apb_state_access;

// APB Address
assign paddr_o = {32{apb_state_access}} & 32'hA000;

// APB PWRITE control signal 
always @(posedge pclk or negedge preset_n) begin
	if(!preset_n)
		pwrite_q <= 1'b0;
	else 
		pwrite_q <= nxt_pwrite;
end
assign pwrite_o = pwrite_q;
// APB PWDATA data signal
// ADDER 
// Read a value from the slave at address 0xA000
// Increment that value
// Send that value back during the write operation to the slave

// tap the read values 
assign pwdata_o = {32{apb_state_access}} & (rdata_q + 32'h1);
always @(posedge pclk or negedge preset_n)
    if(!preset_n)
        rdata_q <= 0;
    else
        rdata_q <= nxt_rdata;

endmodule


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
