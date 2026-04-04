library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_interconnect_write is
  generic (
    S_COUNT    : positive := 2;
    M_COUNT    : positive := 2;
    ADDR_WIDTH : positive := 32;
    DATA_WIDTH : positive := 32;
    GRANTED_INDEX_INVALID : integer := -1;
    BRESP_BITS_PER_PORT : positive := 2;
    PROT_BITS_PER_PORT  : positive := 3;
    BYTE_WIDTH_BITS     : positive := 8;
    M_BASE_ADDR : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"40001000" & x"40000000";
    M_ADDR_MASK : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"FFFFF000" & x"FFFFF000"
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    s_axi_awaddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_awprot  : in  std_logic_vector(S_COUNT*PROT_BITS_PER_PORT-1 downto 0);
    s_axi_awvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_awready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_wdata   : in  std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector(S_COUNT*(DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto 0);
    s_axi_wvalid  : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_wready  : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_bresp   : out std_logic_vector(S_COUNT*BRESP_BITS_PER_PORT-1 downto 0);
    s_axi_bvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_bready  : in  std_logic_vector(S_COUNT-1 downto 0);

    m_axi_awaddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_awprot  : out std_logic_vector(M_COUNT*PROT_BITS_PER_PORT-1 downto 0);
    m_axi_awvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_awready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_wdata   : out std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_wstrb   : out std_logic_vector(M_COUNT*(DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto 0);
    m_axi_wvalid  : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_wready  : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_bresp   : in  std_logic_vector(M_COUNT*BRESP_BITS_PER_PORT-1 downto 0);
    m_axi_bvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_bready  : out std_logic_vector(M_COUNT-1 downto 0);

    wr_arb_req           : out std_logic_vector(S_COUNT-1 downto 0);
    wr_arb_start_ptr     : out integer range 0 to S_COUNT-1;
    wr_arb_granted_index : in  integer range GRANTED_INDEX_INVALID to S_COUNT-1;
    wr_arb_grant_valid   : in  std_logic
  );
end entity;

architecture rtl of axi_interconnect_write is
  constant AXI_RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant AXI_RESP_DECERR : std_logic_vector(1 downto 0) := "11";

  type t_write_state is (WR_IDLE, WR_ARB, WR_CAPTURE, WR_DECODE, WR_WRITE, WR_WAIT_B, WR_RESP);

  signal write_state      : t_write_state := WR_IDLE;
  signal write_state_next : t_write_state := WR_IDLE;

  signal wr_granted_ind      : integer range GRANTED_INDEX_INVALID to S_COUNT-1 := GRANTED_INDEX_INVALID;
  signal wr_granted_ind_next : integer range GRANTED_INDEX_INVALID to S_COUNT-1 := GRANTED_INDEX_INVALID;
  signal wr_target_idx       : integer range GRANTED_INDEX_INVALID to M_COUNT-1 := GRANTED_INDEX_INVALID;
  signal wr_target_idx_next  : integer range GRANTED_INDEX_INVALID to M_COUNT-1 := GRANTED_INDEX_INVALID;

  signal wr_round_robin_start_ptr      : integer range 0 to S_COUNT-1 := 0;
  signal wr_round_robin_start_ptr_next : integer range 0 to S_COUNT-1 := 0;

  signal wr_awaddr_reg      : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wr_awaddr_reg_next : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wr_awprot_reg      : std_logic_vector(PROT_BITS_PER_PORT-1 downto 0) := (others => '0');
  signal wr_awprot_reg_next : std_logic_vector(PROT_BITS_PER_PORT-1 downto 0) := (others => '0');
  signal wr_wdata_reg       : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal wr_wdata_reg_next  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal wr_wstrb_reg       : std_logic_vector((DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto 0) := (others => '0');
  signal wr_wstrb_reg_next  : std_logic_vector((DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto 0) := (others => '0');
  signal wr_aw_seen         : std_logic := '0';
  signal wr_aw_seen_next    : std_logic := '0';
  signal wr_w_seen          : std_logic := '0';
  signal wr_w_seen_next     : std_logic := '0';

  signal wr_bresp_reg      : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;
  signal wr_bresp_reg_next : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;

  function decode_slave_idx(
    addr      : std_logic_vector;
    base_addr : std_logic_vector;
    addr_mask : std_logic_vector;
    m_count   : integer;
    addr_width: integer
  ) return integer is
    variable idx    : integer := GRANTED_INDEX_INVALID;
    variable addr_u : std_logic_vector(addr_width-1 downto 0);
    variable base_u : std_logic_vector(addr_width-1 downto 0);
    variable mask_u : std_logic_vector(addr_width-1 downto 0);
  begin
    addr_u := addr(addr_width-1 downto 0);
    for i in 0 to m_count-1 loop
      base_u := base_addr((i+1)*addr_width-1 downto i*addr_width);
      mask_u := addr_mask((i+1)*addr_width-1 downto i*addr_width);
      if (addr_u and mask_u) = (base_u and mask_u) then
        idx := i;
        exit;
      end if;
    end loop;
    return idx;
  end function;

begin
    
  gen_wr_req : for i in 0 to S_COUNT-1 generate
  begin
    wr_arb_req(i) <= s_axi_awvalid(i) or s_axi_wvalid(i);
  end generate;

  wr_arb_start_ptr <= wr_round_robin_start_ptr;

  write_fsm_seq : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        write_state                <= WR_IDLE;
        wr_granted_ind             <= GRANTED_INDEX_INVALID;
        wr_target_idx              <= GRANTED_INDEX_INVALID;
        wr_round_robin_start_ptr   <= 0;
        wr_awaddr_reg              <= (others => '0');
        wr_awprot_reg              <= (others => '0');
        wr_wdata_reg               <= (others => '0');
        wr_wstrb_reg               <= (others => '0');
        wr_aw_seen                 <= '0';
        wr_w_seen                  <= '0';
        wr_bresp_reg               <= AXI_RESP_OKAY;
      else
        write_state                <= write_state_next;
        wr_granted_ind             <= wr_granted_ind_next;
        wr_target_idx              <= wr_target_idx_next;
        wr_round_robin_start_ptr   <= wr_round_robin_start_ptr_next;
        wr_awaddr_reg              <= wr_awaddr_reg_next;
        wr_awprot_reg              <= wr_awprot_reg_next;
        wr_wdata_reg               <= wr_wdata_reg_next;
        wr_wstrb_reg               <= wr_wstrb_reg_next;
        wr_aw_seen                 <= wr_aw_seen_next;
        wr_w_seen                  <= wr_w_seen_next;
        wr_bresp_reg               <= wr_bresp_reg_next;
      end if;
    end if;
  end process;

  write_fsm_comb : process(all)
    variable decoded_slave_idx : integer;
    variable aw_seen_after     : std_logic;
    variable w_seen_after      : std_logic;
  begin
    write_state_next              <= write_state;
    wr_granted_ind_next           <= wr_granted_ind;
    wr_target_idx_next            <= wr_target_idx;
    wr_round_robin_start_ptr_next <= wr_round_robin_start_ptr;
    wr_awaddr_reg_next            <= wr_awaddr_reg;
    wr_awprot_reg_next            <= wr_awprot_reg;
    wr_wdata_reg_next             <= wr_wdata_reg;
    wr_wstrb_reg_next             <= wr_wstrb_reg;
    wr_aw_seen_next               <= wr_aw_seen;
    wr_w_seen_next                <= wr_w_seen;
    wr_bresp_reg_next             <= wr_bresp_reg;

    case write_state is
      when WR_IDLE =>
        wr_aw_seen_next     <= '0';
        wr_w_seen_next      <= '0';
        wr_granted_ind_next <= GRANTED_INDEX_INVALID;
        wr_target_idx_next  <= GRANTED_INDEX_INVALID;
        wr_bresp_reg_next   <= AXI_RESP_OKAY;
        write_state_next    <= WR_ARB;

      when WR_ARB =>
        if wr_arb_grant_valid = '1' then
          wr_granted_ind_next           <= wr_arb_granted_index;
          wr_round_robin_start_ptr_next <= (wr_arb_granted_index + 1) mod S_COUNT;
          write_state_next              <= WR_CAPTURE;
        end if;

      when WR_CAPTURE =>
        if wr_granted_ind /= GRANTED_INDEX_INVALID then
          aw_seen_after := wr_aw_seen;
          w_seen_after  := wr_w_seen;

          if s_axi_awvalid(wr_granted_ind) = '1' and wr_aw_seen = '0' then
            wr_awaddr_reg_next <= s_axi_awaddr((wr_granted_ind+1)*ADDR_WIDTH-1 downto wr_granted_ind*ADDR_WIDTH);
            wr_awprot_reg_next <= s_axi_awprot((wr_granted_ind+1)*PROT_BITS_PER_PORT-1 downto wr_granted_ind*PROT_BITS_PER_PORT);
            wr_aw_seen_next    <= '1';
            aw_seen_after      := '1';
          end if;

          if s_axi_wvalid(wr_granted_ind) = '1' and wr_w_seen = '0' then
            wr_wdata_reg_next <= s_axi_wdata((wr_granted_ind+1)*DATA_WIDTH-1 downto wr_granted_ind*DATA_WIDTH);
            wr_wstrb_reg_next <= s_axi_wstrb((wr_granted_ind+1)*(DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto wr_granted_ind*(DATA_WIDTH/BYTE_WIDTH_BITS));
            wr_w_seen_next    <= '1';
            w_seen_after      := '1';
          end if;

          if aw_seen_after = '1' and w_seen_after = '1' then
            write_state_next <= WR_DECODE;
          end if;
        else
          write_state_next <= WR_IDLE;
        end if;

      when WR_DECODE =>
        decoded_slave_idx := decode_slave_idx(
          wr_awaddr_reg,
          M_BASE_ADDR,
          M_ADDR_MASK,
          M_COUNT,
          ADDR_WIDTH
        );

        wr_target_idx_next <= decoded_slave_idx;

        if decoded_slave_idx = GRANTED_INDEX_INVALID then
          wr_bresp_reg_next <= AXI_RESP_DECERR;
          write_state_next  <= WR_RESP;
        else
          write_state_next <= WR_WRITE;
        end if;

      when WR_WRITE =>
        if m_axi_awready(wr_target_idx) = '1' and m_axi_wready(wr_target_idx) = '1' then
          write_state_next <= WR_WAIT_B;
        end if;

      when WR_WAIT_B =>
          if m_axi_bvalid(wr_target_idx) = '1' then
            wr_bresp_reg_next <= m_axi_bresp((wr_target_idx+1)*BRESP_BITS_PER_PORT-1 downto wr_target_idx*BRESP_BITS_PER_PORT);
            write_state_next  <= WR_RESP;
          end if;

      when WR_RESP =>
          if s_axi_bready(wr_granted_ind) = '1' then
            write_state_next <= WR_IDLE;
          end if;

    end case;
  end process;

  write_outputs_comb : process(all)
  begin
    s_axi_awready <= (others => '0');
    s_axi_wready  <= (others => '0');
    s_axi_bvalid  <= (others => '0');
    s_axi_bresp   <= (others => '0');

    m_axi_awaddr  <= (others => '0');
    m_axi_awprot  <= (others => '0');
    m_axi_awvalid <= (others => '0');
    m_axi_wdata   <= (others => '0');
    m_axi_wstrb   <= (others => '0');
    m_axi_wvalid  <= (others => '0');
    m_axi_bready  <= (others => '0');

    if write_state = WR_CAPTURE and wr_granted_ind /= GRANTED_INDEX_INVALID then
      if wr_aw_seen = '0' then
        s_axi_awready(wr_granted_ind) <= '1';
      end if;
      if wr_w_seen = '0' then
        s_axi_wready(wr_granted_ind) <= '1';
      end if;
    end if;

    if write_state = WR_WRITE then
      m_axi_awaddr((wr_target_idx+1)*ADDR_WIDTH-1 downto wr_target_idx*ADDR_WIDTH) <= wr_awaddr_reg;
      m_axi_awprot((wr_target_idx+1)*PROT_BITS_PER_PORT-1 downto wr_target_idx*PROT_BITS_PER_PORT) <= wr_awprot_reg;
      m_axi_awvalid(wr_target_idx) <= '1';

      m_axi_wdata((wr_target_idx+1)*DATA_WIDTH-1 downto wr_target_idx*DATA_WIDTH) <= wr_wdata_reg;
      m_axi_wstrb((wr_target_idx+1)*(DATA_WIDTH/BYTE_WIDTH_BITS)-1 downto wr_target_idx*(DATA_WIDTH/BYTE_WIDTH_BITS)) <= wr_wstrb_reg;
      m_axi_wvalid(wr_target_idx) <= '1';
    end if;

    if write_state = WR_WAIT_B then
      m_axi_bready(wr_target_idx) <= '1';
    end if;

    if write_state = WR_RESP then
      s_axi_bvalid(wr_granted_ind) <= '1';
      s_axi_bresp((wr_granted_ind+1)*BRESP_BITS_PER_PORT-1 downto wr_granted_ind*BRESP_BITS_PER_PORT) <= wr_bresp_reg;
    end if;
  end process;

end architecture;
