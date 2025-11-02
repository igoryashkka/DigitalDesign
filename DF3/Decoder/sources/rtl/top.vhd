library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;
use work.driver_pkg.all;

entity top_alu is
  generic (
    CLK_FREQ_HZ       : integer  := 125_000_000;
    BTN_DEB_N_SAMPLES : natural  := 20_000;
    N_BITS            : positive := 8;
    N_PWM_BITS        : positive := 16;
    STEP              : positive := 1
  );
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;

    btn_raw : in  std_logic_vector(5 downto 0); 
    
    led_zero_o  : out std_logic;
    led_carry_o : out std_logic;
    led_over_o  : out std_logic;
    led_neg_o   : out std_logic;

    pwm_r_o     : out std_logic;
    pwm_g_o     : out std_logic;
    pwm_b_o     : out std_logic;
    dsp_used_o  : out std_logic;

    sda_in     : in  std_logic;
    sda_out_en : out std_logic;
    sda_out    : out std_logic;
    scl        : out   std_logic;
    
    dsp_use_i     : in std_logic;
    dsp_result_i  : in  std_logic_vector(N_PWM_BITS - 1 downto 0);
    dsp_a_val     : out std_logic_vector(N_BITS - 1 downto 0);
    dsp_b_val     : out std_logic_vector(N_BITS - 1 downto 0)
  );
end entity;

architecture rtl of top_alu is

  signal btn_lvl    : std_logic_vector(5 downto 0);
  signal btn_pulse  : std_logic_vector(5 downto 0);

  signal btn_a_q    : std_logic_vector(N_BITS-1 downto 0);
  signal btn_b_q    : std_logic_vector(N_BITS-1 downto 0);
  signal reg_a_u    : unsigned(N_BITS-1 downto 0) := (others => '0');
  signal reg_b_u    : unsigned(N_BITS-1 downto 0) := (others => '0');

  signal result          : std_logic_vector(N_PWM_BITS-1 downto 0);
  signal result_alu          : std_logic_vector(N_PWM_BITS-1 downto 0);
  
  signal carry, overflow, negative, zero : std_logic;
  signal op_sel     : op_t := OP_ADD;
  signal duty_r, duty_g, duty_b : std_logic_vector(N_BITS-1 downto 0);
begin

  gen_deb : for i in 0 to 5 generate
    db_i : entity work.debounce_onepulse
      generic map (
        N_SAMPLES => BTN_DEB_N_SAMPLES
      )
      port map (
        clk      => clk,
        rst_n    => rst_n,
        din      => btn_raw(i),
        q_lvl    => btn_lvl(i),
        q_pulse  => btn_pulse(i)
      );
  end generate;

  u_reg_a_btn : entity work.updown_byte
    generic map (
      N_BITS => N_BITS,
      STEP   => STEP
    )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      inc_lvl => btn_lvl(0),
      dec_lvl => btn_lvl(1),
      reg_val => btn_a_q
    );

  u_reg_b_btn : entity work.updown_byte
    generic map (
      N_BITS => N_BITS,
      STEP   => STEP
    )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      inc_lvl => btn_lvl(2),
      dec_lvl => btn_lvl(3),
      reg_val => btn_b_q
    );

  dsp_a_val <= btn_a_q;
  dsp_b_val <= btn_b_q;
  reg_a_u <= unsigned(btn_a_q);
  reg_b_u <= unsigned(btn_b_q);

  u_op_ctrl : entity work.op_select
    port map (
      clk       => clk,
      rst_n     => rst_n,
      step_puls => btn_pulse(4),
      op_sel    => op_sel
    );

  u_alu : entity work.alu
    generic map (
      N_BITS     => N_BITS,
      N_PWM_BITS => N_PWM_BITS
    )
    port map (
      a      => reg_a_u,
      b      => reg_b_u,
      op_sel => op_sel,
      Y      => result_alu,
      C      => carry,
      V      => overflow,
      N      => negative,
      Z      => zero
    );

  led_zero_o  <= zero;
  led_carry_o <= carry;
  led_over_o  <= overflow;
  led_neg_o   <= negative;

  duty_r(7 downto 2) <= result(15 downto 10);  
  duty_g(7 downto 3) <= result(9  downto 5); 
  duty_b(7 downto 3) <= result(4  downto 0);   

  u_pwm_r : entity work.pwm8
    port map (
      clk   => clk,
      rst_n => rst_n,
      duty  => duty_r,
      pwm   => pwm_r_o
    );

  u_pwm_g : entity work.pwm8
    port map (
      clk   => clk,
      rst_n => rst_n,
      duty  => duty_g,
      pwm   => pwm_g_o
    );

  u_pwm_b : entity work.pwm8
    port map (
      clk   => clk,
      rst_n => rst_n,
      duty  => duty_b,
      pwm   => pwm_b_o
    );
    
   result <= dsp_result_i when (dsp_use_i = '1') else result_alu;
   dsp_used_o <= '1' when (dsp_use_i = '1') else '0';

  u_display : entity work.display
    generic map (
      N_BITS     => N_BITS,
      N_PWM_BITS => N_PWM_BITS,
      CLK_DIV    => 1024
    )
    port map (
      clk       => clk,
      rst_n     => rst_n,
      reg_a     => reg_a_u,
      reg_b     => reg_b_u,
      Y         => result,
      mode_step => btn_pulse(5),  
      sda_out       => sda_out,
      sda_out_en       => sda_out_en,
      sda_in       => sda_in,
      scl       => scl
    );

end architecture;
