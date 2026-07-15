library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_pkg.all;

entity op_select is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    step_puls : in  std_logic;
    op_sel    : out op_t
  );
end entity;

architecture rtl of op_select is
  signal idx : unsigned(2 downto 0) := (others => '0');
  signal sel : op_t := OP_ADD;
begin
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      idx <= (others => '0');
      sel <= OP_ADD;
    elsif rising_edge(clk) then
      if step_puls = '1' then
        if idx = "110" then
          idx <= (others => '0');
        else
          idx <= idx + 1;
        end if;
      end if;

      case idx is
        when "000" => sel <= OP_ADD;
        when "001" => sel <= OP_SUB;
        when "010" => sel <= OP_MUL;
        when "011" => sel <= OP_SHL;
        when "100" => sel <= OP_SHR;
        when "101" => sel <= OP_SAR;
        when others=> sel <= OP_ADD;
      end case;
    end if;
  end process;

  op_sel <= sel;
end architecture;
