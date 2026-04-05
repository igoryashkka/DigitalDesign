library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_interconnect_read is
  generic (
    S_COUNT    : positive := 2;
    M_COUNT    : positive := 2;
    ADDR_WIDTH : positive := 32;
    DATA_WIDTH : positive := 32;
    GRANTED_INDEX_INVALID : integer := -1;
    BRESP_BITS_PER_PORT : positive := 2;
    PROT_BITS_PER_PORT  : positive := 3;
    M_BASE_ADDR : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"40001000" & x"40000000";
    M_ADDR_MASK : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"FFFFF000" & x"FFFFF000"
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    s_axi_araddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_arprot  : in  std_logic_vector(S_COUNT*PROT_BITS_PER_PORT-1 downto 0);
    s_axi_arvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_arready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_rdata   : out std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(S_COUNT*BRESP_BITS_PER_PORT-1 downto 0);
    s_axi_rvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_rready  : in  std_logic_vector(S_COUNT-1 downto 0);

    m_axi_araddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_arprot  : out std_logic_vector(M_COUNT*PROT_BITS_PER_PORT-1 downto 0);
    m_axi_arvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_arready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_rdata   : in  std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_rresp   : in  std_logic_vector(M_COUNT*BRESP_BITS_PER_PORT-1 downto 0);
    m_axi_rvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_rready  : out std_logic_vector(M_COUNT-1 downto 0);

    rd_arb_req           : out std_logic_vector(S_COUNT-1 downto 0);
    rd_arb_start_ptr     : out integer range 0 to S_COUNT-1;
    rd_arb_granted_index : in  integer range GRANTED_INDEX_INVALID to S_COUNT-1;
    rd_arb_grant_valid   : in  std_logic
  );
end entity;

architecture rtl of axi_interconnect_read is
  constant AXI_RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant AXI_RESP_DECERR : std_logic_vector(1 downto 0) := "11";

  type t_read_state is (RD_IDLE, RD_ARB, RD_CAPTURE, RD_DECODE, RD_READ, RD_RESP);

  signal read_state      : t_read_state := RD_IDLE;
  signal read_state_next : t_read_state := RD_IDLE;

  signal rd_granted_ind      : integer range GRANTED_INDEX_INVALID to S_COUNT-1 := GRANTED_INDEX_INVALID;
  signal rd_granted_ind_next : integer range GRANTED_INDEX_INVALID to S_COUNT-1 := GRANTED_INDEX_INVALID;
  signal rd_target_idx       : integer range GRANTED_INDEX_INVALID to M_COUNT-1 := GRANTED_INDEX_INVALID;
  signal rd_target_idx_next  : integer range GRANTED_INDEX_INVALID to M_COUNT-1 := GRANTED_INDEX_INVALID;

  signal rd_round_robin_start_ptr      : integer range 0 to S_COUNT-1 := 0;
  signal rd_round_robin_start_ptr_next : integer range 0 to S_COUNT-1 := 0;

  signal rd_araddr_reg      : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_araddr_reg_next : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rd_arprot_reg      : std_logic_vector(PROT_BITS_PER_PORT-1 downto 0) := (others => '0');
  signal rd_arprot_reg_next : std_logic_vector(PROT_BITS_PER_PORT-1 downto 0) := (others => '0');
  signal rd_ar_seen         : std_logic := '0';
  signal rd_ar_seen_next    : std_logic := '0';

  signal rd_rdata_reg      : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal rd_rdata_reg_next : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal rd_rresp_reg      : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;
  signal rd_rresp_reg_next : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;

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
  rd_arb_req <= s_axi_arvalid;
  rd_arb_start_ptr <= rd_round_robin_start_ptr;

  read_fsm_seq : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        read_state                <= RD_IDLE;
        rd_granted_ind            <= GRANTED_INDEX_INVALID;
        rd_target_idx             <= GRANTED_INDEX_INVALID;
        rd_round_robin_start_ptr  <= 0;
        rd_araddr_reg             <= (others => '0');
        rd_arprot_reg             <= (others => '0');
        rd_ar_seen                <= '0';
        rd_rdata_reg              <= (others => '0');
        rd_rresp_reg              <= AXI_RESP_OKAY;
      else
        read_state                <= read_state_next;
        rd_granted_ind            <= rd_granted_ind_next;
        rd_target_idx             <= rd_target_idx_next;
        rd_round_robin_start_ptr  <= rd_round_robin_start_ptr_next;
        rd_araddr_reg             <= rd_araddr_reg_next;
        rd_arprot_reg             <= rd_arprot_reg_next;
        rd_ar_seen                <= rd_ar_seen_next;
        rd_rdata_reg              <= rd_rdata_reg_next;
        rd_rresp_reg              <= rd_rresp_reg_next;
      end if;
    end if;
  end process;

  read_fsm_comb : process(all)
    variable decoded_slave_idx : integer;
  begin
    read_state_next              <= read_state;
    rd_granted_ind_next          <= rd_granted_ind;
    rd_target_idx_next           <= rd_target_idx;
    rd_round_robin_start_ptr_next <= rd_round_robin_start_ptr;
    rd_araddr_reg_next           <= rd_araddr_reg;
    rd_arprot_reg_next           <= rd_arprot_reg;
    rd_ar_seen_next              <= rd_ar_seen;
    rd_rdata_reg_next            <= rd_rdata_reg;
    rd_rresp_reg_next            <= rd_rresp_reg;

    case read_state is
      when RD_IDLE =>
        rd_ar_seen_next      <= '0';
        rd_granted_ind_next  <= GRANTED_INDEX_INVALID;
        rd_target_idx_next   <= GRANTED_INDEX_INVALID;
        rd_rresp_reg_next    <= AXI_RESP_OKAY;
        read_state_next      <= RD_ARB;

      when RD_ARB =>
        if rd_arb_grant_valid = '1' then
          rd_granted_ind_next            <= rd_arb_granted_index;
          rd_round_robin_start_ptr_next  <= (rd_arb_granted_index + 1) mod S_COUNT;
          read_state_next                <= RD_CAPTURE;
        end if;

      when RD_CAPTURE =>
        if rd_granted_ind /= GRANTED_INDEX_INVALID then
          if s_axi_arvalid(rd_granted_ind) = '1' and rd_ar_seen = '0' then
            rd_araddr_reg_next <= s_axi_araddr((rd_granted_ind+1)*ADDR_WIDTH-1 downto rd_granted_ind*ADDR_WIDTH);
            rd_arprot_reg_next <= s_axi_arprot((rd_granted_ind+1)*PROT_BITS_PER_PORT-1 downto rd_granted_ind*PROT_BITS_PER_PORT);
            rd_ar_seen_next    <= '1';
            read_state_next    <= RD_DECODE;
          end if;
        else
          read_state_next <= RD_IDLE;
        end if;

      when RD_DECODE =>
        decoded_slave_idx := decode_slave_idx(
          rd_araddr_reg,
          M_BASE_ADDR,
          M_ADDR_MASK,
          M_COUNT,
          ADDR_WIDTH
        );

        rd_target_idx_next <= decoded_slave_idx;

        if decoded_slave_idx = GRANTED_INDEX_INVALID then
          rd_rdata_reg_next <= (others => '0');
          rd_rresp_reg_next <= AXI_RESP_DECERR;
          read_state_next   <= RD_RESP;
        else
          read_state_next <= RD_READ;
        end if;

      when RD_READ =>
        if m_axi_rvalid(rd_target_idx) = '1' then
          rd_rdata_reg_next <= m_axi_rdata((rd_target_idx+1)*DATA_WIDTH-1 downto rd_target_idx*DATA_WIDTH);
          rd_rresp_reg_next <= m_axi_rresp((rd_target_idx+1)*BRESP_BITS_PER_PORT-1 downto rd_target_idx*BRESP_BITS_PER_PORT);
          read_state_next   <= RD_RESP;
        end if;

      when RD_RESP =>
        if s_axi_rready(rd_granted_ind) = '1' then
          read_state_next <= RD_IDLE;
        end if;
    end case;
  end process;

  read_outputs_comb : process(all)
  begin
    s_axi_arready <= (others => '0');
    s_axi_rdata   <= (others => '0');
    s_axi_rresp   <= (others => '0');
    s_axi_rvalid  <= (others => '0');

    m_axi_araddr  <= (others => '0');
    m_axi_arprot  <= (others => '0');
    m_axi_arvalid <= (others => '0');
    m_axi_rready  <= (others => '0');

    if read_state = RD_CAPTURE and rd_granted_ind /= GRANTED_INDEX_INVALID and rd_ar_seen = '0' then
      s_axi_arready(rd_granted_ind) <= '1';
    end if;

    if read_state = RD_READ then
      m_axi_araddr((rd_target_idx+1)*ADDR_WIDTH-1 downto rd_target_idx*ADDR_WIDTH) <= rd_araddr_reg;
      m_axi_arprot((rd_target_idx+1)*PROT_BITS_PER_PORT-1 downto rd_target_idx*PROT_BITS_PER_PORT) <= rd_arprot_reg;
      m_axi_arvalid(rd_target_idx) <= '1';
      m_axi_rready(rd_target_idx) <= '1';
    end if;

    if read_state = RD_RESP then
      s_axi_rvalid(rd_granted_ind) <= '1';
      s_axi_rdata((rd_granted_ind+1)*DATA_WIDTH-1 downto rd_granted_ind*DATA_WIDTH) <= rd_rdata_reg;
      s_axi_rresp((rd_granted_ind+1)*BRESP_BITS_PER_PORT-1 downto rd_granted_ind*BRESP_BITS_PER_PORT) <= rd_rresp_reg;
    end if;
  end process;

end architecture;
