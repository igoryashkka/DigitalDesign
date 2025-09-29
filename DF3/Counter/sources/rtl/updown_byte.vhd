library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity updown_byte is
  generic(
    N_BITS : positive := 8;
    STEP   : natural  := 1    
  );
  port(
    clk, rst_n : in  std_logic;
    inc_pulse  : in  std_logic;
    dec_pulse  : in  std_logic;
    q          : out std_logic_vector(N_BITS-1 downto 0)
  );
end entity;

architecture rtl of updown_byte is
  signal r : unsigned(N_BITS-1 downto 0) := (others=>'0');
  constant max : unsigned(N_BITS-1 downto 0) := (others=>'1');
begin
  process(clk, rst_n) begin
    if rst_n='0' then
      r <= (others=>'0');
    elsif rising_edge(clk) then
      if    inc_pulse='1' and r < max - to_unsigned(STEP-1, N_BITS) then
        r <= r + to_unsigned(STEP, N_BITS);
      elsif dec_pulse='1' and r > to_unsigned(STEP-1, N_BITS) then
        r <= r - to_unsigned(STEP, N_BITS);
      end if;  
    end if;
  end process;
  q <= std_logic_vector(r);
end architecture;
