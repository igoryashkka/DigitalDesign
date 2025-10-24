library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.driver_pkg.all; 

entity display is
  generic (
    N_BITS     : positive := 8;
    N_PWM_BITS : positive := 16;
    CLK_DIV    : positive := 1024
  );
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;

    reg_a      : in  unsigned(N_BITS-1 downto 0);
    reg_b      : in  unsigned(N_BITS-1 downto 0);
    Y          : in  std_logic_vector(N_PWM_BITS-1 downto 0);

    mode_step  : in  std_logic;  

    sda        : inout std_logic;
    scl        : out   std_logic

  );
end entity;

architecture rtl of display is
  signal disp_idx : unsigned(1 downto 0) := (others => '0'); 
  signal mode_i   : natural range 0 to 2 := 2;

  signal dig0, dig1, dig2, dig3 : std_logic_vector(7 downto 0);
  signal digits_flat            : std_logic_vector(31 downto 0);

  signal disp_strobe : std_logic := '0';
  signal disp_busy   : std_logic;
  signal i2c_sda_out : std_logic;
  signal i2c_sda_oe  : std_logic;
  signal i2c_scl     : std_logic;
  signal i2c_sda_in  : std_logic;

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

--function bin8_to_bcd3(x : unsigned(7 downto 0)) return std_logic_vector is
--  variable b    : unsigned(7 downto 0) := x;
--  variable bcd  : unsigned(11 downto 0) := (others => '0'); 
--begin
--  for i in 0 to 7 loop

--    if bcd(11 downto 8) > 4 then bcd(11 downto 8) := bcd(11 downto 8) + 3; end if; -- hundreds
--    if bcd(7 downto 4)  > 4 then bcd(7 downto 4)  := bcd(7 downto 4)  + 3; end if; -- tens
--    if bcd(3 downto 0)  > 4 then bcd(3 downto 0)  := bcd(3 downto 0)  + 3; end if; -- ones

--    bcd := bcd(10 downto 0) & b(7);
--    b   := b(6 downto 0) & '0';
--  end loop;
--  return std_logic_vector(bcd); 
--end function;

--function bin16_to_bcd5(x : unsigned(15 downto 0)) return std_logic_vector is
--  variable b    : unsigned(15 downto 0) := x;
--  variable bcd  : unsigned(19 downto 0) := (others => '0'); 
--begin
--  for i in 0 to 15 loop
--    if bcd(19 downto 16) > 4 then bcd(19 downto 16) := bcd(19 downto 16) + 3; end if; -- ten-thousands
--    if bcd(15 downto 12) > 4 then bcd(15 downto 12) := bcd(15 downto 12) + 3; end if; -- thousands
--    if bcd(11 downto 8)  > 4 then bcd(11 downto 8)  := bcd(11 downto 8)  + 3; end if; -- hundreds
--    if bcd(7 downto 4)   > 4 then bcd(7 downto 4)   := bcd(7 downto 4)   + 3; end if; -- tens
--    if bcd(3 downto 0)   > 4 then bcd(3 downto 0)   := bcd(3 downto 0)   + 3; end if; -- ones
--    bcd := bcd(18 downto 0) & b(15);
--    b   := b(14 downto 0) & '0';
--  end loop;
--  return std_logic_vector(bcd);
--end function;


begin
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      disp_idx <= (others => '0');  
      mode_i   <= 2;               
    elsif rising_edge(clk) then
      if mode_step = '1' then
        if disp_idx = "10" then     
          disp_idx <= (others => '0');
        else
          disp_idx <= disp_idx + 1;
        end if;
      end if;

      case disp_idx is
        when "00"   => mode_i <= 0; -- A
        when "01"   => mode_i <= 1; -- B
        when others => mode_i <= 2; -- RESULT
      end case;
    end if;
  end process;

--process(all)
--  variable bcdA : std_logic_vector(11 downto 0);
--  variable bcdB : std_logic_vector(11 downto 0);
--  variable bcdY : std_logic_vector(19 downto 0);
--begin
--  bcdA := bin8_to_bcd3(reg_a);
--  bcdB := bin8_to_bcd3(reg_b);
--  bcdY := bin16_to_bcd5(unsigned(Y(15 downto 0)));

--  case mode_i is
--    when 0 => 
--      dig0 <= SEG_A;
--      dig1 <= nibble_to_seg(bcdA(11 downto 8)); 
--      dig2 <= nibble_to_seg(bcdA(7  downto 4)); 
--      dig3 <= nibble_to_seg(bcdA(3  downto 0)); 
--    when 1 =>  
--      dig0 <= SEG_B; 
--      dig1 <= nibble_to_seg(bcdB(11 downto 8));
--      dig2 <= nibble_to_seg(bcdB(7  downto 4));
--      dig3 <= nibble_to_seg(bcdB(3  downto 0));
--    when others =>  
--      dig0 <= nibble_to_seg(bcdY(15 downto 12)); 
--      dig1 <= nibble_to_seg(bcdY(11 downto 8));  
--      dig2 <= nibble_to_seg(bcdY(7  downto 4));  
--      dig3 <= nibble_to_seg(bcdY(3  downto 0));  
--  end case;
--end process;

   process(all)
     variable a7_0  : std_logic_vector(7 downto 0);
     variable b7_0  : std_logic_vector(7 downto 0);
     variable y15_0 : std_logic_vector(15 downto 0);
   begin
     a7_0  := std_logic_vector(reg_a(7 downto 0));
     b7_0  := std_logic_vector(reg_b(7 downto 0));
     y15_0 := Y(15 downto 0);

     case mode_i is
       when 0 =>  
         dig3 <= nibble_to_seg(a7_0(3 downto 0));
         dig2 <= nibble_to_seg(a7_0(7 downto 4));
         dig1 <= SEG_BLANK;
         dig0 <= SEG_A;

       when 1 =>  
         dig3 <= nibble_to_seg(b7_0(3 downto 0));
         dig2 <= nibble_to_seg(b7_0(7 downto 4));
         dig1 <= SEG_BLANK;
         dig0 <= SEG_B;

       when others =>  
         dig3 <= nibble_to_seg(y15_0(3  downto 0));
         dig2 <= nibble_to_seg(y15_0(7  downto 4));
         dig1 <= nibble_to_seg(y15_0(11 downto 8));
         dig0 <= nibble_to_seg(y15_0(15 downto 12));
     end case;
   end process;

  digits_flat <= dig3 & dig2 & dig1 & dig0;

  u_disp : entity work.driver_wrap
    generic map (
      CLK_DIV => CLK_DIV
    )
    port map (
      clk         => clk,
      rst_n       => rst_n,
      sync_reset  => '0',
      digits_flat => digits_flat,
      disp_strobe => disp_strobe,
      busy        => disp_busy,
      sda_out     => i2c_sda_out,
      sda_in      => i2c_sda_in,
      sda_out_en  => i2c_sda_oe,
      scl         => i2c_scl
    );

  disp_fsm : process(clk, rst_n)
    variable strobe_ff : std_logic := '0';
  begin
    if rst_n = '0' then
      strobe_ff   := '0';
      disp_strobe <= '0';
    elsif rising_edge(clk) then
      if (disp_busy = '0') and (strobe_ff = '0') then
        disp_strobe <= '1';
        strobe_ff   := '1';
      else
        disp_strobe <= '0';
        if disp_busy = '1' then
          strobe_ff := '0';
        end if;
      end if;
    end if;
  end process;

  i2c_sda_in <= sda;
  sda <= 'Z' when (i2c_sda_oe = '0' or i2c_sda_out = '1') else '0';
  scl <= i2c_scl;

end architecture;
