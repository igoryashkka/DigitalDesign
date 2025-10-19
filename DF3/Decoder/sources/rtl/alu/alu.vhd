library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;

entity alu is
  generic (
    N_BITS     : positive := 8;
    N_PWM_BITS : positive := 16
  );
  port (
    a      : in  unsigned(N_BITS-1 downto 0);
    b      : in  unsigned(N_BITS-1 downto 0);
    op_sel : in  op_t;


    Y      : out std_logic_vector(N_PWM_BITS-1 downto 0);
    C      : out std_logic;
    V      : out std_logic;
    N      : out std_logic;
    Z      : out std_logic
  );
end entity;

architecture rtl of alu is

  signal y_add, y_sub, y_mul, y_shl, y_shr, y_sar : std_logic_vector(N_PWM_BITS-1 downto 0);
  signal c_add, v_add, n_add, z_add               : std_logic;
  signal c_sub, v_sub, n_sub, z_sub               : std_logic;
  signal c_mul, v_mul, n_mul, z_mul               : std_logic;
  signal c_shl, v_shl, n_shl, z_shl               : std_logic;
  signal c_shr, v_shr, n_shr, z_shr               : std_logic;
  signal c_sar, v_sar, n_sar, z_sar               : std_logic;

  signal shift_amt : std_logic_vector(2 downto 0);
begin

  shift_amt <= std_logic_vector(b(2 downto 0));


  u_add : entity work.op_add
    port map (
      a => std_logic_vector(a),
      b => std_logic_vector(b),
      y => y_add, carry => c_add, overflow => v_add, negative => n_add, zero => z_add
    );

  u_sub : entity work.op_sub
    port map (
      a => std_logic_vector(a),
      b => std_logic_vector(b),
      y => y_sub, carry => c_sub, overflow => v_sub, negative => n_sub, zero => z_sub
    );

  u_mul : entity work.op_mul
    port map (
      a => std_logic_vector(a),
      b => std_logic_vector(b),
      y => y_mul, carry => c_mul, overflow => v_mul, negative => n_mul, zero => z_mul
    );

  u_shl : entity work.op_shl
    port map (
      a => std_logic_vector(a),
      b => shift_amt,
      y => y_shl, carry => c_shl, overflow => v_shl, negative => n_shl, zero => z_shl
    );

  u_shr : entity work.op_shr
    port map (
      a => std_logic_vector(a),
      b => shift_amt,
      y => y_shr, carry => c_shr, overflow => v_shr, negative => n_shr, zero => z_shr
    );

  u_sar : entity work.op_sar
    port map (
      a => std_logic_vector(a),
      b => shift_amt,
      y => y_sar, carry => c_sar, overflow => v_sar, negative => n_sar, zero => z_sar
    );


  with op_sel select
    Y <= y_add when OP_ADD,
         y_sub when OP_SUB,
         y_mul when OP_MUL,
         y_shl when OP_SHL,
         y_shr when OP_SHR,
         y_sar when OP_SAR,
         y_add when others; 

  with op_sel select
    C <= c_add when OP_ADD,
         c_sub when OP_SUB,
         c_mul when OP_MUL,
         c_shl when OP_SHL,
         c_shr when OP_SHR,
         c_sar when OP_SAR,
         c_add when others;

  with op_sel select
    V <= v_add when OP_ADD,
         v_sub when OP_SUB,
         v_mul when OP_MUL,
         v_shl when OP_SHL,
         v_shr when OP_SHR,
         v_sar when OP_SAR,
         v_add when others;

  with op_sel select
    N <= n_add when OP_ADD,
         n_sub when OP_SUB,
         n_mul when OP_MUL,
         n_shl when OP_SHL,
         n_shr when OP_SHR,
         n_sar when OP_SAR,
         n_add when others;

  with op_sel select
    Z <= z_add when OP_ADD,
         z_sub when OP_SUB,
         z_mul when OP_MUL,
         z_shl when OP_SHL,
         z_shr when OP_SHR,
         z_sar when OP_SAR,
         z_add when others;
end architecture;
