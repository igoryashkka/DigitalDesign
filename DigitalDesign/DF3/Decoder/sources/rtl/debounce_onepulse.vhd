library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity debounce_onepulse is
  generic(
    N_SAMPLES : natural := 16
  );
  port(
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    din     : in  std_logic;
    q_lvl   : out std_logic;
    q_pulse : out std_logic
  );
end entity;

architecture rtl of debounce_onepulse is
  signal sync  : std_logic_vector(1 downto 0);
  signal filt  : unsigned(15 downto 0) := (others=>'0');
  signal stable, prev_stable : std_logic := '0';
begin
  process(clk) begin
    if rising_edge(clk) then
      sync(0) <= din;
      sync(1) <= sync(0);
    end if;
  end process;

  process(clk, rst_n) begin
    if rst_n='0' then
      filt        <= (others=>'0');
      stable      <= '0';
      prev_stable <= '0';
    elsif rising_edge(clk) then
      if sync(1) = stable then
        filt <= (others=>'0');
      else
        filt <= filt + 1;
        if filt = to_unsigned(N_SAMPLES-1, filt'length) then
          stable <= sync(1);
          filt   <= (others=>'0');
        end if;
      end if;
      prev_stable <= stable;
    end if;
  end process;

  q_lvl     <= stable;                                
  q_pulse <= '1' when (prev_stable='0' and stable='1') else '0';
end architecture;
