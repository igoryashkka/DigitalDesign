library ieee;
use ieee.std_logic_1164.all;

entity clk_wiz_0 is
  port(
    clk_in1  : in  std_logic;
    resetn   : in  std_logic;
    clk_out1 : out std_logic;
    clk_out2 : out std_logic
  );
end entity;

architecture sim of clk_wiz_0 is
  signal div2 : std_logic := '0';
begin
  process(clk_in1)
  begin
    if rising_edge(clk_in1) then
      if resetn = '0' then
        div2 <= '0';
      else
        div2 <= not div2;
      end if;
    end if;
  end process;

  clk_out1 <= div2;
  clk_out2 <= clk_in1;
end architecture;
