library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_rr_arbiter is
  generic (
    N : positive := 2;
    GRANTED_INDEX_INVALID : integer := -1
  );
  port (
    req       : in  std_logic_vector(N-1 downto 0);
    start_ptr : in  integer range 0 to N-1;
    granted_index : out integer range GRANTED_INDEX_INVALID to N-1;
    grant_valid   : out std_logic
  );
end entity;

architecture rtl of axi_rr_arbiter is
begin
  process(all)
    variable found : boolean;
    variable granted_ind : integer range GRANTED_INDEX_INVALID to N-1;
    variable current_ind : integer range 0 to N-1;
  begin
    found := false;
    granted_ind := GRANTED_INDEX_INVALID;

    for k in 0 to N-1 loop
      current_ind := (start_ptr + k) mod N;
      if req(current_ind) = '1' then
        granted_ind := current_ind;
        found := true;
        exit;
      end if;
    end loop;

    granted_index <= granted_ind;
    if found then
      grant_valid <= '1';
    else
      grant_valid <= '0';
    end if;
  end process;
end architecture;
