library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.alu_pkg.all;
use work.driver_pkg.all;

entity top_alu is
  generic (
    CLK_FREQ_HZ : integer := 125_000_000;
    BTN_DEB_N_SAMPLES : natural := 20_000;
    N_BITS     : positive := 8;   
    N_PWM_BITS : positive := 16;
    STEP       : positive := 1 
  );
  port(
    clk    : in  std_logic;
    rst_n  : in  std_logic;

    btn_raw : in  std_logic_vector(5 downto 0);

    -- sts
    led_zero_o  : out std_logic;
    led_carry_o : out std_logic;
    led_over_o  : out std_logic;
    led_neg_o   : out std_logic;

    -- PWM RGB
    pwm_r_o     : out std_logic;
    pwm_g_o     : out std_logic;
    pwm_b_o     : out std_logic;

    -- SDA 
    sda         : inout std_logic;
    scl         : in    std_logic
  );
end entity;

architecture rtl of top_alu is

  signal btn_lvl   : std_logic_vector(5 downto 0);
  signal btn_pulse : std_logic_vector(5 downto 0);


  signal reg_a, reg_b : unsigned(N_BITS - 1 downto 0) := (others=>'0');
  signal btn_a_q, btn_b_q : std_logic_vector(N_BITS - 1 downto 0);

  signal op_sel : op_t := OP_ADD;
  signal op_idx : unsigned(2 downto 0) := (others=>'0');


  signal y_add,y_sub,y_mul,y_shl,y_shr,y_sar : std_logic_vector(N_PWM_BITS - 1 downto 0);
  signal c_add,v_add,n_add,z_add : std_logic;
  signal c_sub,v_sub,n_sub,z_sub : std_logic;
  signal c_mul,v_mul,n_mul,z_mul : std_logic;
  signal c_shl,v_shl,n_shl,z_shl : std_logic;
  signal c_shr,v_shr,n_shr,z_shr : std_logic;
  signal c_sar,v_sar,n_sar,z_sar : std_logic;

  signal Y       : std_logic_vector(N_PWM_BITS - 1 downto 0);
  signal C,V,N,Z : std_logic;

  signal duty_r, duty_g, duty_b : std_logic_vector(N_BITS - 1 downto 0);

  signal disp_digits  : std_logic_vector(31 downto 0);
  signal disp_strobe  : std_logic := '0';
  signal disp_busy    : std_logic;
  signal i2c_sda_out  : std_logic;
  signal i2c_sda_oe   : std_logic;
  signal i2c_scl      : std_logic;
  signal i2c_sda_in   : std_logic;

  type display_t is (DIS_A, DIS_B, DIS_RES);
  signal display_sel   : display_t := DIS_RES;
  signal disp_idx      : unsigned(1 downto 0) := (others=>'0'); 


  signal dig0, dig1, dig2, dig3 : std_logic_vector(7 downto 0);

  constant SEG_BLANK : std_logic_vector(7 downto 0) := (others => '0');

  function nibble_to_seg(n : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    case n is
      when "0000" => return SEG_0;
      when "0001" => return SEG_1;
      when "0010" => return SEG_2;
      when "0011" => return SEG_3;
      when "0100" => return SEG_4;
      when "0101" => return SEG_5;
      when "0110" => return SEG_6;
      when "0111" => return SEG_7;
      when "1000" => return SEG_8;
      when "1001" => return SEG_9;
      when "1010" => return SEG_A;
      when "1011" => return SEG_B;
      when "1100" => return SEG_C;
      when "1101" => return SEG_D;
      when "1110" => return SEG_E;
      when others => return SEG_F;
    end case;
  end function;

begin
  gen_deb: for i in 0 to 5 generate
    db_i : entity work.debounce_onepulse
      generic map (N_SAMPLES => BTN_DEB_N_SAMPLES)
      port map (
        clk     => clk,
        rst_n   => rst_n,
        din     => btn_raw(i),
        q_lvl   => btn_lvl(i),
        q_pulse => btn_pulse(i)
      );
  end generate;

  regA_btn: entity work.updown_byte
    generic map(N_BITS => N_BITS, STEP => STEP)
    port map(
      clk       => clk,
      rst_n     => rst_n,
      inc_lvl   => btn_lvl(0),
      dec_lvl   => btn_lvl(1),
      q         => btn_a_q
    );

  regB_btn: entity work.updown_byte
    generic map(N_BITS => N_BITS, STEP => STEP)
    port map(
      clk       => clk,
      rst_n     => rst_n,
      inc_lvl   => btn_lvl(2),
      dec_lvl   => btn_lvl(3),
      q         => btn_b_q
    );


  process(clk, rst_n)
  begin
    if rst_n = '0' then
      reg_a  <= (others => '0');
      reg_b  <= (others => '0');
      op_sel <= OP_ADD;
      op_idx <= (others => '0');
    elsif rising_edge(clk) then
      reg_a <= unsigned(btn_a_q);
      reg_b <= unsigned(btn_b_q);

      if btn_pulse(4) = '1' then
        if op_idx = "110" then
          op_idx <= (others => '0');
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

  process(clk, rst_n)
  begin
    if rst_n = '0' then
      disp_idx    <= (others => '0');  -- 0
      display_sel <= DIS_RES;
    elsif rising_edge(clk) then
      if btn_pulse(5) = '1' then
        if disp_idx = "10" then       -- 2
          disp_idx <= (others => '0');
        else
          disp_idx <= disp_idx + 1;
        end if;
      end if;

      case disp_idx is
        when "00" => display_sel <= DIS_A;
        when "01" => display_sel <= DIS_B;
        when others => display_sel <= DIS_RES;
      end case;
    end if;
  end process;

  u_add: entity work.op_add port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_add,c_add,v_add,n_add,z_add);
  u_sub: entity work.op_sub port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_sub,c_sub,v_sub,n_sub,z_sub);
  u_mul: entity work.op_mul port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_mul,c_mul,v_mul,n_mul,z_mul);
  u_shl: entity work.op_shl port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shl,c_shl,v_shl,n_shl,z_shl);
  u_shr: entity work.op_shr port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shr,c_shr,v_shr,n_shr,z_shr);
  u_sar: entity work.op_sar port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_sar,c_sar,v_sar,n_sar,z_sar);

  u_mux: entity work.alu_mux
    generic map (N_PWM_BITS => N_PWM_BITS)
    port map(
      sel=>op_sel,
      y_add=>y_add, c_add=>c_add, v_add=>v_add, n_add=>n_add, z_add=>z_add,
      y_sub=>y_sub, c_sub=>c_sub, v_sub=>v_sub, n_sub=>n_sub, z_sub=>z_sub,
      y_mul=>y_mul, c_mul=>c_mul, v_mul=>v_mul, n_mul=>n_mul, z_mul=>z_mul,
      y_shl=>y_shl, c_shl=>c_shl, v_shl=>v_shl, n_shl=>n_shl, z_shl=>z_shl,
      y_shr=>y_shr, c_shr=>c_shr, v_shr=>v_shr, n_shr=>z_shr, z_shr=>z_shr,
      y_sar=>y_sar, c_sar=>c_sar, v_sar=>v_sar, n_sar=>n_sar, z_sar=>z_sar,
      y=>Y, carry=>C, overflow=>V, negative=>N, zero=>Z
    );


  led_zero_o  <= Z;
  led_carry_o <= C;
  led_over_o  <= V;
  led_neg_o   <= N;

  duty_r <= std_logic_vector( resize(unsigned(Y(15 downto 10)), 8) sll 2 );
  duty_g <= std_logic_vector( resize(unsigned(Y(9  downto  5)), 8) sll 3 );
  duty_b <= std_logic_vector( resize(unsigned(Y(4  downto  0)), 8) sll 3 );

  u_pwm_r: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_r, pwm=>pwm_r_o);
  u_pwm_g: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_g, pwm=>pwm_g_o);
  u_pwm_b: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty=>duty_b, pwm=>pwm_b_o);

  process(all)
    variable a7_0  : std_logic_vector(7 downto 0);
    variable b7_0  : std_logic_vector(7 downto 0);
    variable y15_0 : std_logic_vector(15 downto 0);
  begin
    a7_0  := std_logic_vector(reg_a(7 downto 0));
    b7_0  := std_logic_vector(reg_b(7 downto 0));
    y15_0 := Y(15 downto 0);

    case display_sel is
      when DIS_A =>
        dig3 <= SEG_BLANK;
        dig2 <= SEG_BLANK;
        dig1 <= nibble_to_seg(a7_0(7 downto 4));
        dig0 <= nibble_to_seg(a7_0(3 downto 0));

      when DIS_B =>
        dig3 <= SEG_BLANK;
        dig2 <= SEG_BLANK;
        dig1 <= nibble_to_seg(b7_0(7 downto 4));
        dig0 <= nibble_to_seg(b7_0(3 downto 0));

      when others =>  -- DIS_RES
        dig3 <= nibble_to_seg(y15_0(15 downto 12));
        dig2 <= nibble_to_seg(y15_0(11 downto 8));
        dig1 <= nibble_to_seg(y15_0(7  downto 4));
        dig0 <= nibble_to_seg(y15_0(3  downto 0));
    end case;
  end process;

  disp_digits <= dig3 & dig2 & dig1 & dig0;

  u_disp : entity work.driver_wrap
    generic map (CLK_DIV => 1024)
    port map (
      clk         => clk,
      rst_n       => rst_n,
      sync_reset  => '0',
      digits_flat => disp_digits,
      disp_strobe => disp_strobe,
      busy        => disp_busy,
      sda_out     => i2c_sda_out,
      sda_in      => i2c_sda_in,
      sda_out_en  => i2c_sda_oe,
      scl         => i2c_scl
    );

  i2c_sda_in <= sda;
  i2c_scl    <= scl;
  sda <= 'Z' when (i2c_sda_oe = '0' or i2c_sda_out = '1') else '0';

  process(clk, rst_n)
    variable strobe_ff : std_logic := '0';
  begin
    if rst_n = '0' then
      strobe_ff := '0';
      disp_strobe <= '0';
    elsif rising_edge(clk) then
      if disp_busy = '0' and strobe_ff = '0' then
        disp_strobe <= '1';
        strobe_ff := '1';
      else
        disp_strobe <= '0';
        if disp_busy = '1' then
          strobe_ff := '0';
        end if;
      end if;
    end if;
  end process;

end architecture;
