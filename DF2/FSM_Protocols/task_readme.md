# DF2 / FSM_Protocols Task

## Що треба зробити
Описати та перевірити FSM-блоки для детектора послідовності, look-ahead логіки та SPI master/slave обміну.

## Піни / порти
- `SequenceDetector.vhd`
  - `clk`, `reset`, `in_bit` - входи
  - `detected` - вихід
- `lookahd.vhd`
  - перевірити локально в файлі, бо реалізація може змінюватися залежно від навчального прикладу
- `spi_master.vhd`
  - `CLK_i`, `Reset_i`, `Start_i`, `MSIO_i`, `InputData_i(N-1 downto 0)` - входи
  - `Mosi_o`, `Done_o`, `SCK_o`, `CS_o` - виходи
- `spi_slave.vhd`
  - використовує SPI-лінії обміну; звірити точний інтерфейс у модулі перед підключенням testbench

## Що перевірити
- Для `SequenceDetector` перевірити збіг потрібної бітової послідовності й коректний `reset`.
- Для SPI перевірити фазу `SCK`, активність `CS` та передачу `MOSI` під час `Start_i`.
- У simulation-папці є готові шаблони testbench-ів, їх варто використовувати як базу.
