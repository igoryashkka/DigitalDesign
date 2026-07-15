# DF4 / AXI Interconnect Task

## Що треба зробити
Зібрати AXI4-Lite interconnect, який розводить транзакції між кількома slave- та master-портами, окремо для читання й запису.

## Піни / порти
- `axi_lite_interconnect.vhd`
  - `clk`, `rst_n` - синхронізація та скидання
  - `s_axi_*` - масиви входів/виходів для slave-сторони: `awaddr`, `awprot`, `awvalid`, `awready`, `wdata`, `wstrb`, `wvalid`, `wready`, `bresp`, `bvalid`, `bready`, `araddr`, `arprot`, `arvalid`, `arready`, `rdata`, `rresp`, `rvalid`, `rready`
  - `m_axi_*` - масиви для master-сторони з тими ж каналами

## Що перевірити
- Коректний арбітраж між кількома master/slave запитами.
- Відокремлення read-path і write-path.
- Мапінг адрес через `M_BASE_ADDR` і `M_ADDR_MASK`.
