# APB_Protocol

Some notes for my reference
- APB Protocol is very simple non-pipelined protocol
- We write certain set of statements, which actually used to initiate a transaction from master to slave
- Single cycle transaction, Once starts NEEDS TO COMPLETE
- Still used in many SoCs, very used for reading/ writing data
Used for the Debug code - during debug we need to read/write to provide stimulus
TIMER, I2C, GPIO (need to be programmed and output some data)

That's makes it fairly important that we understand this!!

All the signals are some import points we should know :
- Pclk, Preset
- pSel[1:0] - select signal (which particular slave the transaction is happening)
- Penable is asserted one cycle after the select signal, reason : SoCs implement clk gating so 
if the device at most times in active low power mode, so protocol sends a select and enable, so slave will get to know that it is receiving a transaction.
- Pwrite (1= writing 0 = reading)
- Pwdata written to the slave
- Prdata read from the slave
- Pready w.r.t slave 
- PslaveErrortransaction could not be processed by the slave,(raises error signal) reintiate your transcation security issues between master and slave
- pAddress signal - where we should right data to or read data from
- In access mode Psel and Penb are held high
- Once the transaction starts Penb and Pdata has to remain stable


*Control path - Pwrite, Pclk, Preset, Psel, Pready, pSlaveError, pEnable* </br>
*Data path - Prdata, Pwdata, pAddress*

__Three states protocol can be__:</br>
ST_IDLE - Remain idle Psel, Penable = 0</br>
ST_SETUP - if you want to initiate any transaction - Psel = 1, Penable = 0</br>
ST_ACCESS - Psel = 1, Penable = 1 </br>
Will remain in access state until we get Pready , so in Access state Pready = 0</br>
meanwhile Pwrite, PwData, Paddr will remain stable - if we change these we will run into protocol violation
</br>
What happens if we get Pready = 1</br>
we can go to either idle (no transaction) or setup (new transaction)</br>

Whole system is synchoronous so no metastability</br>

</br>
ADDER using APB Protocol</br>
RTL -> APB Master</br>
TB -> APB Slave</br>


