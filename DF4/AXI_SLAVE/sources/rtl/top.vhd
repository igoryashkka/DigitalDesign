library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;


entity top is
  generic (
    CLK_FREQ_HZ       : integer  := 125_000_000;
    BTN_DEB_N_SAMPLES : natural  := 20_000;
    N_BITS            : positive := 8;
    N_PWM_BITS        : positive := 16;
    STEP              : positive := 1
  );
  port (
    --      sys_clk_p : in std_logic;
   --     sys_clk_n : in std_logic;
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    duty_r      : in std_logic_vector(N_BITS-1 downto 0);
    led_1       : out std_logic;
    pwm_r_o     : out std_logic

  );
end entity;

architecture rtl of top is

begin 

    -- clk_buffer : IBUFDS
    --     generic map (
    --         DIFF_TERM    => false,
    --         IBUF_LOW_PWR => true ,
    --         IOSTANDARD   => "DEFAULT"
    --     )
    --     port map (
    --         O  => clk,
    --         I  => sys_clk_p,
    --         IB => sys_clk_n
    --     );

   u_pwm_r : entity work.pwm8
    port map (
      clk   => clk,
      rst_n => rst_n ,
      duty  => duty_r,
      pwm   => pwm_r_o
    );
end architecture;
