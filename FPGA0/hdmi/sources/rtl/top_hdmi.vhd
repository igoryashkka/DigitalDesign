library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- Minimal DVI/HDMI (video only) transmitter:
-- video_timing -> test_pattern -> 3x TMDS encoder -> 3x OSERDES -> 3x OBUFDS
-- TMDS clock is forwarded from pix_clk via OBUFDS (simple option).
entity top_hdmi is
  port(
    rst       : in  std_logic;  -- active-high reset

    clk_200   : in  std_logic;  -- 200 MHz board clock

    -- TMDS differential outputs
    tmds_clk_p : out std_logic;
    tmds_clk_n : out std_logic;

    tmds_d0_p  : out std_logic;
    tmds_d0_n  : out std_logic;

    tmds_d1_p  : out std_logic;
    tmds_d1_n  : out std_logic;

    tmds_d2_p  : out std_logic;
    tmds_d2_n  : out std_logic
  );
end entity;

architecture rtl of top_hdmi is

  signal pix_clk  : std_logic;
  signal ser_clk  : std_logic;
  signal resetn   : std_logic;
  signal clk_lock : std_logic;

  -- timing signals
  signal hsync, vsync, de : std_logic;
  signal x, y             : unsigned(9 downto 0);

  -- RGB from test pattern
  signal r, g, b : std_logic_vector(7 downto 0);

  -- TMDS 10-bit words
  signal tmds_r, tmds_g, tmds_b : std_logic_vector(9 downto 0);

  -- serialized TMDS bits
  signal tmds_r_s, tmds_g_s, tmds_b_s : std_logic;

begin

  resetn <= not rst;

  u_clk_wiz : entity work.clk_wiz_0
    port map(
      clk_in1  => clk_200,
      resetn   => resetn,
      clk_out1 => pix_clk,
      clk_out2 => ser_clk,
      locked   => clk_lock
    );

  -- (640x480)
  u_timing : entity work.video_timing
    port map(
      clk   => pix_clk,
      rst   => rst,
      hsync => hsync,
      vsync => vsync,
      de    => de,
      x     => x,
      y     => y
    );

  u_pat : entity work.test_pattern
    port map(
      clk => pix_clk,
      rst => rst,
      de  => de,
      x   => x,
      y   => y,
      r   => r,
      g   => g,
      b   => b
    );

  -- DVI/HDMI baseline: when DE=0, HS/VS are encoded as control codes on BLUE channel
  u_enc_b : entity work.tmds_encoder
    port map(
      clk  => pix_clk,
      rst  => rst,
      de   => de,
      c0   => hsync,  
      c1   => vsync,   
      din  => b,
      dout => tmds_b
    );

  u_enc_g : entity work.tmds_encoder
    port map(
      clk  => pix_clk,
      rst  => rst,
      de   => de,
      c0   => '0',
      c1   => '0',
      din  => g,
      dout => tmds_g
    );

  u_enc_r : entity work.tmds_encoder
    port map(
      clk  => pix_clk,
      rst  => rst,
      de   => de,
      c0   => '0',
      c1   => '0',
      din  => r,
      dout => tmds_r
    );

  -- (10:1, DDR)
  u_ser_b : entity work.tmds_oserdes_10b
    port map(
      rst     => rst,
      pix_clk => pix_clk,
      ser_clk => ser_clk,
      din10   => tmds_b,
      dout    => tmds_b_s
    );

  u_ser_g : entity work.tmds_oserdes_10b
    port map(
      rst     => rst,
      pix_clk => pix_clk,
      ser_clk => ser_clk,
      din10   => tmds_g,
      dout    => tmds_g_s
    );

  u_ser_r : entity work.tmds_oserdes_10b
    port map(
      rst     => rst,
      pix_clk => pix_clk,
      ser_clk => ser_clk,
      din10   => tmds_r,
      dout    => tmds_r_s
    );

  -- Differential output buffers
  -- Conventional mapping: D0=Blue, D1=Green, D2=Red
  u_obuf_d0 : OBUFDS port map(I => tmds_b_s, O => tmds_d0_p, OB => tmds_d0_n);
  u_obuf_d1 : OBUFDS port map(I => tmds_g_s, O => tmds_d1_p, OB => tmds_d1_n);
  u_obuf_d2 : OBUFDS port map(I => tmds_r_s, O => tmds_d2_p, OB => tmds_d2_n);

  -- TMDS clock: simplest = forward pix_clk as differential clock
  u_obuf_clk : OBUFDS port map(I => pix_clk, O => tmds_clk_p, OB => tmds_clk_n);

end architecture;

  