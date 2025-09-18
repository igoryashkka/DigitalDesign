library ieee;
use ieee.std_logic_1164.all;

package alu_pkg is
  type op_t is (OP_ADD, OP_SUB, OP_MUL, OP_SHL, OP_SHR, OP_SAR);
end package;

library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;

entity alu_mux is
  port(
    sel      : in  op_t;
    y_add    : in  std_logic_vector(15 downto 0); c_add, v_add, n_add, z_add : in std_logic;
    y_sub    : in  std_logic_vector(15 downto 0); c_sub, v_sub, n_sub, z_sub : in std_logic;
    y_mul    : in  std_logic_vector(15 downto 0); c_mul, v_mul, n_mul, z_mul : in std_logic;
    y_shl    : in  std_logic_vector(15 downto 0); c_shl, v_shl, n_shl, z_shl : in std_logic;
    y_shr    : in  std_logic_vector(15 downto 0); c_shr, v_shr, n_shr, z_shr : in std_logic;
    y_sar    : in  std_logic_vector(15 downto 0); c_sar, v_sar, n_sar, z_sar : in std_logic;
    y        : out std_logic_vector(15 downto 0);
    carry, overflow, negative, zero : out std_logic
  );
end entity;

architecture rtl of alu_mux is
begin
  process(all) begin
    case sel is
      when OP_ADD => y<=y_add; carry<=c_add; overflow<=v_add; negative<=n_add; zero<=z_add;
      when OP_SUB => y<=y_sub; carry<=c_sub; overflow<=v_sub; negative<=n_sub; zero<=z_sub;
      when OP_MUL => y<=y_mul; carry<=c_mul; overflow<=v_mul; negative<=n_mul; zero<=z_mul;
      when OP_SHL => y<=y_shl; carry<=c_shl; overflow<=v_shl; negative<=n_shl; zero<=z_shl;
      when OP_SHR => y<=y_shr; carry<=c_shr; overflow<=v_shr; negative<=n_shr; zero<=z_shr;
      when OP_SAR => y<=y_sar; carry<=c_sar; overflow<=v_sar; negative<=n_sar; zero<=z_sar;
    end case;
  end process;
end architecture;
