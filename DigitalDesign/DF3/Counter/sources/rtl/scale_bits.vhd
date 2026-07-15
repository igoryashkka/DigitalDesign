library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scale_bits is
  generic(
    N_IN  : positive := 16;  -- input width (Regs A/B)
    N_OUT : positive := 8    -- output width (PWM)
  );
  port(
    x : in  std_logic_vector(N_IN-1 downto 0);
    y : out std_logic_vector(N_OUT-1 downto 0)
  );
end entity;

architecture rtl of scale_bits is
  constant IN_MAX    : natural := (2**N_IN)  - 1;
  constant OUT_MAX   : natural := (2**N_OUT) - 1;

  constant OUT_MAX_U : unsigned(N_OUT-1 downto 0)
                     := to_unsigned(OUT_MAX, N_OUT);

  constant W_FULL    : natural := N_IN + N_OUT;

  signal x_u      : unsigned(N_IN-1 downto 0);
  signal mul_full : unsigned(W_FULL-1 downto 0);
  signal sum_full : unsigned(W_FULL-1 downto 0);
  signal div_full : unsigned(W_FULL-1 downto 0);
begin
  x_u <= unsigned(x);

  --  mapping by y_out = (x * (2^N_OUT - 1) + (2^N_IN - 1)/2) / (2^N_IN - 1) )

  mul_full <= x_u * OUT_MAX_U;
  sum_full <= mul_full + to_unsigned(IN_MAX/2, W_FULL);
  div_full <= sum_full / IN_MAX;

  y <= std_logic_vector(resize(div_full, N_OUT));
end architecture;
