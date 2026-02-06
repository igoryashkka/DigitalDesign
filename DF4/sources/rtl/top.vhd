library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
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

    btn_raw : in  std_logic_vector(1 downto 0); 
    
    led_1  : out std_logic;
    pwm_r_o     : out std_logic

  );
end entity;

architecture rtl of top is

  signal btn_lvl    : std_logic_vector(1 downto 0);
  signal btn_pulse  : std_logic_vector(1 downto 0);

  signal btn_a_q    : std_logic_vector(N_BITS-1 downto 0);
  signal duty_r     : std_logic_vector(N_BITS-1 downto 0);
  signal reg_a_u    : unsigned(N_BITS-1 downto 0) := (others => '0');
begin

  gen_deb : for i in 0 to 1 generate
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

    duty_r <= btn_a_q;

   u_pwm_r : entity work.pwm8
    port map (
      clk   => clk,
      rst_n => rst_n,
        duty  => duty_r,
      pwm   => pwm_r_o
    );

end architecture;
