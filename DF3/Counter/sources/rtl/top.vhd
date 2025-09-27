library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
generic (
  CLK_FREQ_HZ : integer  := 125_000_000;
  BAUD        : integer  := 115200;
  N_BITS      : positive := 8
);
  port(
    clk            : in  std_logic;
    rst_n          : in  std_logic;
   
    sw_op          : in  std_logic;
    btn_a_up       : in  std_logic;
    btn_a_down     : in  std_logic;
    btn_b_up       : in  std_logic;
    btn_b_down     : in  std_logic;

    -- PWM RGB
    pwm_muxed_o    : out std_logic;
    led            : out std_logic_vector(3 downto 0)

  );
end entity;

architecture rtl of top is 
--  ----------------------------------------------------------------------------
  -- Debounced pulses
  signal a_up_p, a_dn_p, b_up_p, b_dn_p : std_logic;

  -- A/B regs 
  signal reg_a, reg_b : unsigned(7 downto 0) := (others=>'0');

  --  A/B btns
  signal btn_a_q, btn_b_q : std_logic_vector(7 downto 0);



  signal Y_sel           : std_logic_vector(7 downto 0);

  signal duty_r, duty_g, duty_b : std_logic_vector(7 downto 0);
    
 begin


--   ----------------------------------------------------------------------------
--   -- Buttons → pulses
  db_aup : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_a_up ,a_up_p);
  db_adn : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_a_down,a_dn_p);
  db_bup : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_b_up ,b_up_p);
  db_bdn : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_b_down,b_dn_p);

  regA_btn: entity work.updown_byte port map(clk,rst_n,a_up_p,a_dn_p,btn_a_q);
  regB_btn: entity work.updown_byte port map(clk,rst_n,b_up_p,b_dn_p,btn_b_q);


  -- Mux : counter -> pwm channel 
  u_mux : entity work.mux2
    generic map (N_BITS => N_BITS)
    port map (
      sel => sw_op,
      a   => btn_a_q,
      b   => btn_b_q,
      y   => Y_sel
    );

  -- LED 

    led(3 downto 0) <= btn_b_q(3 downto 0) when sw_op = '1'
                   else btn_a_q(3 downto 0);
  -- PWM 
  u_pwm: entity work.pwm8 port map(clk  => clk,rst_n=> rst_n,duty => Y_sel ,pwm  => pwm_muxed_o);

end architecture;
