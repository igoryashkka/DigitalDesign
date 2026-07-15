# DV3 Task

## Що треба зробити
Доопрацювати UVM-стенд для DXI-фільтра: сценарії random, boundary та file-driven, scoreboard і запуск через Vivado / wrapper-скрипти.

## Піни / порти
- `dxi_if.sv`
  - `clk` - такт
  - `rstn` - reset
  - `valid`, `ready` - handshake
  - `data(71 downto 0)` - DXI payload
- `config_if.sv`
  - `clk` - такт
  - `config_select(1 downto 0)` - вибір режиму фільтра

## Що перевірити
- `random_uvm_test` має проганятися за замовчуванням.
- `boundary_uvm_test` повинен покривати крайні значення пікселів і режимів.
- `file_uvm_test` має читати тестові дані з файлу та порівнювати результат зі scoreboard.
