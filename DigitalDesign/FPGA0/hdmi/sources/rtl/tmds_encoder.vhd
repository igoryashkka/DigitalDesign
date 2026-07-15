library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_encoder is
  port(
    clk  : in  std_logic;
    rst  : in  std_logic;
    de   : in  std_logic;
    c0   : in  std_logic; -- HSYNC (when de=0)
    c1   : in  std_logic; -- VSYNC (when de=0)
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(9 downto 0)
  );
end entity;

architecture rtl of tmds_encoder is
  function ones(v: std_logic_vector) return integer is
    variable n: integer := 0;
  begin
    for i in v'range loop
      if v(i)='1' then n := n + 1; end if;
    end loop;
    return n;
  end function;

  signal disparity : integer range -1024 to 1024 := 0;
  signal flag_sync : std_logic_vector(1 downto 0);
begin

   flag_sync <= c1 & c0;

  process(clk)
    variable n1       : integer;
    variable q_m      : std_logic_vector(8 downto 0);
    variable q_out    : std_logic_vector(9 downto 0);
    variable use_xnor : boolean;
    variable bal      : integer;
    variable n_qm     : integer;
  begin
    if rising_edge(clk) then
      if rst='1' then
        dout <= (others=>'0');
        disparity <= 0;

      elsif de='0' then
        -- TMDS control codes
        case (flag_sync) is
          when "00"   => dout <= "1101010100";
          when "01"   => dout <= "0010101011";
          when "10"   => dout <= "0101010100";
          when others => dout <= "1010101011";
        end case;
        disparity <= 0;

      else
        n1 := ones(din);
        use_xnor := (n1 > 4) or ((n1 = 4) and (din(0) = '0'));

        -- stage 1
        q_m(0) := din(0);
        for i in 1 to 7 loop
          if use_xnor then
            q_m(i) := not (q_m(i-1) xor din(i));
          else
            q_m(i) := (q_m(i-1) xor din(i));
          end if;
        end loop;
        q_m(8) := '0' when use_xnor else '1';

        n_qm := ones(q_m(7 downto 0));
        bal  := (2*n_qm) - 8; -- ones - zeros

        -- stage 2 (running disparity)
        if (disparity = 0) or (bal = 0) then
          q_out(9) := not q_m(8);
          q_out(8) := q_m(8);
          if q_m(8)='1' then
            q_out(7 downto 0) := q_m(7 downto 0);
            disparity <= disparity + bal;
          else
            q_out(7 downto 0) := not q_m(7 downto 0);
            disparity <= disparity - bal;
          end if;

        elsif ((disparity > 0) and (bal > 0)) or ((disparity < 0) and (bal < 0)) then
          q_out(9) := '1';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := not q_m(7 downto 0);
          if q_m(8)='1' then
            disparity <= disparity - bal + 2;
          else
            disparity <= disparity - bal - 2;
          end if;

        else
          q_out(9) := '0';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := q_m(7 downto 0);
          if q_m(8)='1' then
            disparity <= disparity + bal - 2;
          else
            disparity <= disparity + bal + 2;
          end if;
        end if;

        dout <= q_out;
      end if;
    end if;
  end process;
end architecture;
