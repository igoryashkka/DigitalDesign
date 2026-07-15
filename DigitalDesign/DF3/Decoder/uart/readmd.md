PS \DF3\Decoder> python alu_uart_cli.py -p COM5 --selftest --rounds 10  
Opened COM5 @ 115200 8N1, timeout=0.5
Note: this script expects the FPGA to echo bytes (RX->TX loopback in your top_alu).
Running selftest: 10 random commands...
[00] TX=b'alu:0:32;130\n' RX=b'alu:0:32;130\n'  OK
[01] TX=b'alu:0:253;230\n' RX=b'alu:0:253;230\n'  OK
[02] TX=b'alu:1:194;107\n' RX=b'alu:1:194;107\n'  OK
[03] TX=b'alu:0:249;14\n' RX=b'alu:0:249;14\n'  OK
[04] TX=b'alu:1:221;1\n' RX=b'alu:1:221;1\n'  OK
[05] TX=b'alu:2:228;136\n' RX=b'alu:2:228;136\n'  OK
[06] TX=b'alu:2:117;52\n' RX=b'alu:2:117;52\n'  OK
[07] TX=b'alu:1:15;11\n' RX=b'alu:1:15;11\n'  OK
[08] TX=b'alu:0:4;195\n' RX=b'alu:0:4;195\n'  OK
[09] TX=b'alu:2:110;216\n' RX=b'alu:2:110;216\n'  OK
Selftest done. OK=10, MISMATCH=0