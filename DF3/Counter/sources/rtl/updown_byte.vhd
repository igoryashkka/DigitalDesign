library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity updown_byte is
  generic(
    N_BITS     : positive := 8;
    STEP       : natural  := 1;
    CLK_HZ     : natural  := 125_000_000; 
    HOLD_MS    : natural  := 1000;
    REPEAT_MS  : natural  := 30
  );
  port(
    clk, rst_n : in  std_logic;
    inc_lvl    : in  std_logic;
    dec_lvl    : in  std_logic;  
    q          : out std_logic_vector(N_BITS-1 downto 0)
  );
end entity;

architecture rtl of updown_byte is
  constant MAX_U        : unsigned(N_BITS-1 downto 0) := (others=>'1');
  constant HOLD_TICKS   : natural := (CLK_HZ / 1000) * HOLD_MS;
  constant REPEAT_TICKS : natural := (CLK_HZ / 1000) * REPEAT_MS;

  signal reg_value    : unsigned(N_BITS-1 downto 0) := (others=>'0');
  signal hold_time    : unsigned(31 downto 0) := (others=>'0');
  signal rep_time     : unsigned(31 downto 0) := (others=>'0');
  signal is_hold      : std_logic := '0';
  signal dir_up       : std_logic := '0';      


  signal inc_q, dec_q : std_logic := '0';
  signal inc_rise     : std_logic;
  signal dec_rise     : std_logic;


  function sat_add(u: unsigned; step: natural) return unsigned is
  begin
    if u <= (MAX_U - to_unsigned(step, u'length)) then
      return u + to_unsigned(step, u'length);
    else
      return MAX_U;
    end if;
  end function;

  function sat_sub(u: unsigned; step: natural) return unsigned is
  begin
    if u >= to_unsigned(step, u'length) then
      return u - to_unsigned(step, u'length);
    else
      return (others=>'0');
    end if;
  end function;

begin
  process(clk, rst_n)
  begin
    if rst_n='0' then
      reg_value <= (others=>'0');
      hold_time <= (others=>'0');
      rep_time  <= (others=>'0');
      is_hold   <= '0';
      dir_up    <= '0';
      inc_q     <= '0';
      dec_q     <= '0';

    elsif rising_edge(clk) then

      inc_rise <= '1' when (inc_lvl='1' and inc_q='0') else '0';
      dec_rise <= '1' when (dec_lvl='1' and dec_q='0') else '0';
      inc_q    <= inc_lvl;
      dec_q    <= dec_lvl;


      if inc_rise='1' and dec_lvl='0' then
        dir_up <= '1';
      elsif dec_rise='1' and inc_lvl='0' then
        dir_up <= '0';
      end if;

      if (inc_lvl='1' or dec_lvl='1') then

        if inc_rise='1' and dec_lvl='0' then
          reg_value <= sat_add(reg_value, STEP);
        elsif dec_rise='1' and inc_lvl='0' then
          reg_value <= sat_sub(reg_value, STEP);
        end if;


        if hold_time < to_unsigned(HOLD_TICKS, hold_time'length) then
          hold_time <= hold_time + 1;
          is_hold   <= '0';
          rep_time  <= (others=>'0');
        else
          is_hold <= '1';

          if rep_time < to_unsigned(REPEAT_TICKS, rep_time'length) then
            rep_time <= rep_time + 1;
          else
            rep_time <= (others=>'0');
            if dir_up='1' and inc_lvl='1' and dec_lvl='0' then
              reg_value <= sat_add(reg_value, STEP);
            elsif dir_up='0' and dec_lvl='1' and inc_lvl='0' then
              reg_value <= sat_sub(reg_value, STEP);
            end if;
          end if;
        end if;

      else
        hold_time <= (others=>'0');
        rep_time  <= (others=>'0');
        is_hold   <= '0';
      end if;

    end if;
  end process;

  q <= std_logic_vector(reg_value);
end architecture;
