# DF2 / IntermediateBlocks Task

## Що треба зробити
Зібрати середні за складністю блоки: регістр, лічильник, арифметику додавання/віднімання та множення.

## Піни / порти
- `AddSub.vhd`
  - `A_i(N-1 downto 0)`, `B_i(N-1 downto 0)`, `Sub_i` - входи
  - `Diff_o(N-1 downto 0)`, `Borrow_o` - виходи
- `Reg.vhd`
  - `clk_i`, `reset_i`, `enable_i` - входи
  - `D_i(3 downto 0)` - вхід даних
  - `Q_o(3 downto 0)` - вихід
- `counter.vhd`
  - `clk_i`, `reset_i`, `enable_i` - входи
  - `count_o(2 downto 0)` - вихід
- `mult.vhd`
  - `A_i(3 downto 0)`, `B_i(3 downto 0)` - входи
  - `P_o(7 downto 0)` - вихід

## Що перевірити
- Перехід `AddSub` між режимами суми та різниці.
- `Reg` має оновлюватися лише при `enable_i = '1'`.
- `counter` має рахувати тільки при дозволі, а `mult` - давати повний 8-бітний добуток.
