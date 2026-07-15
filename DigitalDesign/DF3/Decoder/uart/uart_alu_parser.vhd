-- uart_alu_parser.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_alu_parser is
  port(
    clk, rst_n  : in  std_logic;
    rx_data     : in  std_logic_vector(7 downto 0);
    rx_valid    : in  std_logic;
    rx_ready    : out std_logic;

    op_out      : out unsigned(2 downto 0);   -- 0..5 (clamped)
    a_out       : out unsigned(7 downto 0);   -- 0..255 (clamped)
    b_out       : out unsigned(7 downto 0);
    cmd_stb     : out std_logic               -- 1 clk pulse when full command parsed
  );
end entity;

architecture rtl of uart_alu_parser is
  type st_t is (S_SYNC_A, S_SYNC_L, S_SYNC_U, S_SYNC_COL1,
                S_OP, S_A, S_SEMI, S_B, S_DONE);
  signal st : st_t := S_SYNC_A;

  -- accumulators (decimal)
  signal acc_op : unsigned(2 downto 0) := (others=>'0');  -- 0..7, we clamp to 0..5 at DONE
  signal acc_a  : unsigned(9 downto 0) := (others=>'0');  -- allow up to 1023, clamp to 255
  signal acc_b  : unsigned(9 downto 0) := (others=>'0');

  signal stb_q  : std_logic := '0';

  -- helpers
  function is_digit(c: std_logic_vector(7 downto 0)) return boolean is
    variable u : unsigned(7 downto 0);
  begin
    u := unsigned(c);
    return (u >= to_unsigned(48,8)) and (u <= to_unsigned(57,8)); -- '0'..'9'
  end function;

  function to_digit(c: std_logic_vector(7 downto 0)) return unsigned is
    variable u : unsigned(7 downto 0);
  begin
    u := unsigned(c) - to_unsigned(48,8); -- '0'
    return resize(u, 4); -- 0..9 in 4 bits
  end function;

  -- Width-safe decimal accumulation:
  -- compute in integer, then cast back to unsigned with exact target width.
  function add_dec(prev : unsigned; d : unsigned) return unsigned is
    variable i : natural;
  begin
    i := to_integer(prev) * 10 + to_integer(resize(d, prev'length));
    return to_unsigned(i, prev'length);
  end function;

begin
  rx_ready <= '1';
  cmd_stb  <= stb_q;

  process(clk, rst_n)
    variable ch : std_logic_vector(7 downto 0);
  begin
    if rst_n = '0' then
      st      <= S_SYNC_A;
      acc_op  <= (others=>'0');
      acc_a   <= (others=>'0');
      acc_b   <= (others=>'0');
      stb_q   <= '0';
      op_out  <= (others=>'0');
      a_out   <= (others=>'0');
      b_out   <= (others=>'0');
    elsif rising_edge(clk) then
      stb_q <= '0';

      if rx_valid = '1' then
        ch := rx_data;

        case st is
          -- expect "alu:"
          when S_SYNC_A    => if ch = x"61" then st <= S_SYNC_L;    else st <= S_SYNC_A; end if; -- 'a'
          when S_SYNC_L    => if ch = x"6C" then st <= S_SYNC_U;    else st <= S_SYNC_A; end if; -- 'l'
          when S_SYNC_U    => if ch = x"75" then st <= S_SYNC_COL1; else st <= S_SYNC_A; end if; -- 'u'
          when S_SYNC_COL1 => if ch = x"3A" then st <= S_OP;        else st <= S_SYNC_A; end if; -- ':'

          -- op (decimal), then ':'
          when S_OP =>
            if is_digit(ch) then
              acc_op <= add_dec(acc_op, to_digit(ch));
            elsif ch = x"3A" then -- ':'
              st <= S_A;
            else
              st <= S_SYNC_A; acc_op <= (others=>'0');
            end if;

          -- A (decimal), then ';'
          when S_A =>
            if is_digit(ch) then
              acc_a <= add_dec(acc_a, to_digit(ch));
            elsif ch = x"3B" then -- ';'
              st <= S_SEMI;
            else
              st <= S_SYNC_A; acc_a <= (others=>'0');
            end if;

          -- separator before B
          when S_SEMI =>
            if is_digit(ch) then
              acc_b <= resize(to_digit(ch), acc_b'length);
              st    <= S_B;
            else
              st <= S_SYNC_A; acc_b <= (others=>'0');
            end if;

          -- B (decimal), ends with '\n' or ';'
          when S_B =>
            if is_digit(ch) then
              acc_b <= add_dec(acc_b, to_digit(ch));
            elsif (ch = x"0A") or (ch = x"3B") then  -- '\n' or ';'
              st <= S_DONE;
            else
              st <= S_SYNC_A; acc_b <= (others=>'0');
            end if;

          when S_DONE =>
            -- clamp op to 0..5
            if acc_op > to_unsigned(5, acc_op'length) then
              op_out <= to_unsigned(5, op_out'length);
            else
              op_out <= acc_op;
            end if;

            -- clamp A/B to 0..255
            if acc_a > to_unsigned(255, acc_a'length) then
              a_out <= to_unsigned(255, a_out'length);
            else
              a_out <= resize(acc_a, a_out'length);
            end if;

            if acc_b > to_unsigned(255, acc_b'length) then
              b_out <= to_unsigned(255, b_out'length);
            else
              b_out <= resize(acc_b, b_out'length);
            end if;

            stb_q  <= '1';

            -- reset for next command
            st      <= S_SYNC_A;
            acc_op  <= (others=>'0');
            acc_a   <= (others=>'0');
            acc_b   <= (others=>'0');

          when others =>
            st <= S_SYNC_A;
        end case;
      end if;
    end if;
  end process;
end architecture;
