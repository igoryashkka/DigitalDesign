library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm8 is
  port(
    clk, rst_n : in  std_logic;
    duty       : in  std_logic_vector(7 downto 0);
    pwm        : out std_logic
  );
end entity;

architecture rtl of pwm8 is
  signal cnt : unsigned(7 downto 0) := (others=>'0');
begin
  process(clk, rst_n) begin
    if rst_n='0' then
      cnt <= (others=>'0');
    elsif rising_edge(clk) then
      cnt <= cnt + 1;
    end if;
  end process;
  pwm <= '1' when cnt < unsigned(duty) else '0';
end architecture;
