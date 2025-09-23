library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity updown_byte is
  port(
    clk, rst_n : in  std_logic;
    inc_pulse  : in  std_logic;       
    dec_pulse  : in  std_logic;
    q          : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of updown_byte is
  signal r : unsigned(7 downto 0) := (others=>'0');
begin
  process(clk, rst_n) begin
    if rst_n='0' then
      r <= (others=>'0');
    elsif rising_edge(clk) then
      if inc_pulse='1' and r /= x"FF" then
        r <= r + 1;
      elsif dec_pulse='1' and r /= x"00" then
        r <= r - 1;
      end if;
    end if;
  end process;
  q <= std_logic_vector(r);
end architecture;
