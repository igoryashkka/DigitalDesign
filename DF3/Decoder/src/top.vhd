library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;

entity top_alu is
  generic (
    CLK_FREQ_HZ : integer := 125_000_000;
    BAUD        : integer := 115200;
    BTN_DEB_N_SAMPLES : natural := 20_000  
  );
  port(
    clk    : in  std_logic;
    rst_n  : in  std_logic;

    btn_raw : in  std_logic_vector(4 downto 0);

    -- sts
    led_zero_o  : out std_logic;
    led_carry_o : out std_logic;
    led_over_o  : out std_logic;
    led_neg_o   : out std_logic;

    -- PWM RGB
    pwm_r_o     : out std_logic;
    pwm_g_o     : out std_logic;
    pwm_b_o     : out std_logic
  );
end entity;

architecture rtl of top_alu is

  signal btn_pulse : std_logic_vector(4 downto 0);

  -- A/B regs
  signal reg_a, reg_b : unsigned(7 downto 0) := (others=>'0');
  signal btn_a_q, btn_b_q : std_logic_vector(7 downto 0);

  -- Op select
  signal op_sel   : op_t := OP_ADD;
  signal op_idx   : unsigned(2 downto 0) := (others=>'0');

  -- ALU signals
  signal y_add,y_sub,y_mul,y_shl,y_shr,y_sar : std_logic_vector(15 downto 0);
  signal c_add,v_add,n_add,z_add : std_logic;
  signal c_sub,v_sub,n_sub,z_sub : std_logic;
  signal c_mul,v_mul,n_mul,z_mul : std_logic;
  signal c_shl,v_shl,n_shl,z_shl : std_logic;
  signal c_shr,v_shr,n_shr,z_shr : std_logic;
  signal c_sar,v_sar,n_sar,z_sar : std_logic;

  signal Y          : std_logic_vector(15 downto 0);
  signal C,V,N,Z    : std_logic;

  signal duty_r, duty_g, duty_b : std_logic_vector(7 downto 0);
begin
  ------------------------------------------------------------------------------
  gen_deb: for i in 0 to 4 generate
    db_i : entity work.debounce_onepulse
      generic map(
        N_SAMPLES => BTN_DEB_N_SAMPLES
      )
      port map(
        clk   => clk,
        rst_n => rst_n,
        din   => btn_raw(i),
        q => btn_pulse(i)
      );
  end generate;

  ------------------------------------------------------------------------------
  -- Up/Down regs
  regA_btn: entity work.updown_byte
    port map(
      clk       => clk,
      rst_n     => rst_n,
      inc_pulse => btn_pulse(0),  
      dec_pulse => btn_pulse(1),  
      q         => btn_a_q
    );

  regB_btn: entity work.updown_byte
    port map(
      clk       => clk,
      rst_n     => rst_n,
      inc_pulse => btn_pulse(2), 
      dec_pulse => btn_pulse(3),  
      q         => btn_b_q
    );

  ------------------------------------------------------------------------------
  process(clk, rst_n) begin
    if rst_n='0' then
      reg_a  <= (others=>'0');
      reg_b  <= (others=>'0');
      op_sel <= OP_ADD;
      op_idx <= (others=>'0');
    elsif rising_edge(clk) then
      reg_a <= unsigned(btn_a_q);
      reg_b <= unsigned(btn_b_q);

      if btn_pulse(4)='1' then
        if op_idx = "110" then
          op_idx <= (others=>'0');
        else
          op_idx <= op_idx + 1;
        end if;
      end if;

      case op_idx is
        when "000" => op_sel <= OP_ADD;
        when "001" => op_sel <= OP_SUB;
        when "010" => op_sel <= OP_MUL;
        when "011" => op_sel <= OP_SHL;
        when "100" => op_sel <= OP_SHR;
        when "101" => op_sel <= OP_SAR;
        when others => op_sel <= OP_ADD;
      end case;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- ALU operators
  u_add: entity work.op_add port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_add,c_add,v_add,n_add,z_add);
  u_sub: entity work.op_sub port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_sub,c_sub,v_sub,n_sub,z_sub);
  u_mul: entity work.op_mul port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_mul,c_mul,v_mul,n_mul,z_mul);
  u_shl: entity work.op_shl port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shl,c_shl,v_shl,n_shl,z_shl);
  u_shr: entity work.op_shr port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shr,c_shr,v_shr,n_shr,z_shr);
  u_sar: entity work.op_sar port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_sar,c_sar,v_sar,n_sar,z_sar);

  -- ALU mux
  u_mux: entity work.alu_mux
    port map(
      sel=>op_sel,
      y_add=>y_add, c_add=>c_add, v_add=>v_add, n_add=>n_add, z_add=>z_add,
      y_sub=>y_sub, c_sub=>c_sub, v_sub=>v_sub, n_sub=>n_sub, z_sub=>z_sub,
      y_mul=>y_mul, c_mul=>c_mul, v_mul=>v_mul, n_mul=>n_mul, z_mul=>z_mul,
      y_shl=>y_shl, c_shl=>c_shl, v_shl=>v_shl, n_shl=>n_shl, z_shl=>z_shl,
      y_shr=>y_shr, c_shr=>c_shr, v_shr=>v_shr, n_shr=>n_shr, z_shr=>z_shr,
      y_sar=>y_sar, c_sar=>c_sar, v_sar=>v_sar, n_sar=>n_sar, z_sar=>z_sar,
      y=>Y, carry=>C, overflow=>V, negative=>N, zero=>Z
    );

  -- Status LEDs
  led_zero_o  <= Z;
  led_carry_o <= C;
  led_over_o  <= V;
  led_neg_o   <= N;
  
  -- PWM
  duty_r <= std_logic_vector( resize(unsigned(Y(15 downto 10)), 8) sll 2 );
  duty_g <= std_logic_vector( resize(unsigned(Y(9  downto  5)), 8) sll 3 );
  duty_b <= std_logic_vector( resize(unsigned(Y(4  downto  0)), 8) sll 3 );

  u_pwm_r: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_r, pwm=>pwm_r_o);
  u_pwm_g: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_g, pwm=>pwm_g_o);
  u_pwm_b: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_b, pwm=>pwm_b_o);
end architecture;
