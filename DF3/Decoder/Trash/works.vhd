-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity top is
--   port (
--      clk   : in  std_logic;                      -- Clock input (e.g. sys_clk_125)
--      rst_n : in  std_logic;                      -- Active-low reset (can connect to sw[0])

--      btn   : in  std_logic_vector(3 downto 0);   -- 4 push buttons
--      led   : out std_logic_vector(3 downto 0)    -- 4 LEDs
--     -- led5_r : out std_logic
--   );
-- end entity;

-- architecture rtl of top is
--   -- Internal signals
--    signal inc_pulse, dec_pulse : std_logic;

--    signal count                : std_logic_vector(7 downto 0);
-- begin
    

--   db_inc: entity work.debounce_onepulse
--     generic map(N_SAMPLES => 20000)
--     port map(
--       clk    => clk,
--       rst_n  => rst_n,
--       din    => btn(0),
--       pulse  => inc_pulse
--     );

--   db_dec: entity work.debounce_onepulse
--     generic map(N_SAMPLES => 20000)
--     port map(
--       clk    => clk,
--       rst_n  => rst_n,
--       din    => btn(1),
--       pulse  => dec_pulse
--     );

-- ----  -- Up/Down counter logic
--   counter: entity work.updown_byte
--     port map(
--       clk       => clk,
--       rst_n     => rst_n,
--       inc_pulse => inc_pulse,
--       dec_pulse => dec_pulse,
--       q         => count
--     );
  
--     led <= count(3 downto 0);   

-- end architecture;


