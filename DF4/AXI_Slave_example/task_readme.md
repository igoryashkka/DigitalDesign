# DF4 / AXI Slave Example Task

## Що треба зробити
Дописати AXI4-Lite slave з GPIO-регістрами: коректний handshake, підтримка `wstrb`, читання/запис і передача подій у register-file.

## Піни / порти
- `axi_gpio.vhd`
  - `s_axi_aclk`, `s_axi_aresetn` - такт і reset
  - write address channel: `s_axi_awaddr`, `s_axi_awvalid`, `s_axi_awready`
  - write data channel: `s_axi_wdata`, `s_axi_wstrb`, `s_axi_wvalid`, `s_axi_wready`
  - write response channel: `s_axi_bresp`, `s_axi_bvalid`, `s_axi_bready`
  - read address channel: `s_axi_araddr`, `s_axi_arvalid`, `s_axi_arready`
  - read data channel: `s_axi_rdata`, `s_axi_rresp`, `s_axi_rvalid`, `s_axi_rready`
  - register-file side: `axi_write_fire`, `wr_addr`, `wr_data`, `wr_strb`, `axi_read_fire`, `rd_addr`, `rd_data`

## Що перевірити
- Запис має завершуватися тільки після прийому і адреси, і даних.
- Читання має повертати дані з `rd_data` з коректним `rvalid`/`rready` handshake.
- Варто окремо перевірити частковий запис через `wstrb`.
