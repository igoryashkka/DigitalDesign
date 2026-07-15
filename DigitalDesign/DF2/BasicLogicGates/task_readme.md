# DF2 / BasicLogicGates Task

## Що треба зробити
Реалізувати та перевірити найпростіші логічні й арифметичні блоки: AND, OR, 2:1 та 4:1 mux, а також 1-бітний і 4-бітний full adder.

## Піни / порти
- `andGate.vhd`
  - `in1`, `in2` - входи
  - `result` - вихід
- `orGate.vhd`
  - `in1`, `in2` - входи
  - `result` - вихід
- `mux2to1.vhd`
  - `a`, `b`, `sel` - входи
  - `y` - вихід
- `mux4to1.vhd`
  - `sel(1 downto 0)` - вибір
  - `result` - вихід
- `FullAdder4Bit.vhd`
  - `A(3 downto 0)`, `B(3 downto 0)`, `Cin` - входи
  - `Sum(3 downto 0)`, `Cout` - виходи

## Що перевірити
- Таблиці істинності для `AND`, `OR` і `mux`.
- Для `FullAdder4Bit` перевірити коректне складання з переносом між бітами.
- Додати або оновити testbench-и під `simulation/`, якщо потрібно покрити всі варіанти `sel`.
