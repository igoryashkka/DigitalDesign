library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_slave_gpio is
	generic (
		ADDR_WIDTH : positive := 6;
		DATA_WIDTH : positive := 32;
		N_GPIO     : positive := 8
	);
	port (
		s_axi_aclk    : in  std_logic;
		s_axi_aresetn : in  std_logic;

		s_axi_awaddr  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
		s_axi_awvalid : in  std_logic;
		s_axi_awready : out std_logic;

		s_axi_wdata   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		s_axi_wstrb   : in  std_logic_vector((DATA_WIDTH / 8) - 1 downto 0);
		s_axi_wvalid  : in  std_logic;
		s_axi_wready  : out std_logic;

		s_axi_bresp   : out std_logic_vector(1 downto 0);
		s_axi_bvalid  : out std_logic;
		s_axi_bready  : in  std_logic;

		s_axi_araddr  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
		s_axi_arvalid : in  std_logic;
		s_axi_arready : out std_logic;

		s_axi_rdata   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
		s_axi_rresp   : out std_logic_vector(1 downto 0);
		s_axi_rvalid  : out std_logic;
		s_axi_rready  : in  std_logic;

		gpio_read_data : in  std_logic_vector(N_GPIO - 1 downto 0);
		gpio_out_reg   : out std_logic_vector(N_GPIO - 1 downto 0);
		gpio_dir_reg   : out std_logic_vector(N_GPIO - 1 downto 0)
	);
end entity;

architecture rtl of axi_slave_gpio is
	constant BYTE_LANES : integer := DATA_WIDTH / 8;

	signal awaddr_reg  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal araddr_reg  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal wdata_reg   : std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal wstrb_reg   : std_logic_vector(BYTE_LANES - 1 downto 0);

	signal aw_stored   : std_logic;
	signal w_stored    : std_logic;

	signal rdata_reg   : std_logic_vector(DATA_WIDTH - 1 downto 0);

	signal gpio_data_reg : std_logic_vector(N_GPIO - 1 downto 0);
	signal gpio_dir_reg_i : std_logic_vector(N_GPIO - 1 downto 0);

	-- function apply_wstrb(
	-- 	old_d : std_logic_vector(DATA_WIDTH - 1 downto 0);
	-- 	new_d : std_logic_vector(DATA_WIDTH - 1 downto 0);
	-- 	wstrb : std_logic_vector(BYTE_LANES - 1 downto 0)
	-- ) return std_logic_vector is
	-- 	variable res : std_logic_vector(DATA_WIDTH - 1 downto 0) := old_d;
	-- begin
	-- 	for b in 0 to BYTE_LANES - 1 loop
	-- 		if wstrb(b) = '1' then
	-- 			res(8 * b + 7 downto 8 * b) := new_d(8 * b + 7 downto 8 * b);
	-- 		end if;
	-- 	end loop;
	-- 	return res;
	-- end function;
begin
	-- s_axi_awready <= '1' when (aw_stored = '0' and s_axi_bvalid = '0') else '0';
	-- s_axi_wready  <= '1' when (w_stored = '0' and s_axi_bvalid = '0') else '0';
	-- s_axi_arready <= '1' when (s_axi_rvalid = '0') else '0';

	-- s_axi_bresp  <= "00";
	-- s_axi_rresp  <= "00";
	-- s_axi_rdata  <= rdata_reg;

	-- gpio_out_reg <= gpio_data_reg;
	-- gpio_dir_reg <= gpio_dir_reg_i;

	process (s_axi_aclk)
		variable old_word : std_logic_vector(DATA_WIDTH - 1 downto 0);
		variable new_word : std_logic_vector(DATA_WIDTH - 1 downto 0);
		variable rd_word  : std_logic_vector(DATA_WIDTH - 1 downto 0);
	begin
		if rising_edge(s_axi_aclk) then
			if s_axi_aresetn = '0' then
				awaddr_reg     <= (others => '0');
				araddr_reg     <= (others => '0');
				wdata_reg      <= (others => '0');
				wstrb_reg      <= (others => '0');
				aw_stored      <= '0';
				w_stored       <= '0';
				s_axi_bvalid   <= '0';
				s_axi_rvalid   <= '0';
				rdata_reg      <= (others => '0');
				gpio_data_reg  <= (others => '0');
				gpio_dir_reg_i <= (others => '1');
			else
				if (s_axi_awvalid = '1' and s_axi_awready = '1') then
					awaddr_reg <= s_axi_awaddr;
					aw_stored  <= '1';
				end if;

				if (s_axi_wvalid = '1' and s_axi_wready = '1') then
					wdata_reg <= s_axi_wdata;
					wstrb_reg <= s_axi_wstrb;
					w_stored  <= '1';
				end if;

				if (aw_stored = '1' and w_stored = '1' and s_axi_bvalid = '0') then
					old_word := (others => '0');
					new_word := wdata_reg;

					case awaddr_reg(3 downto 2) is
						when "00" =>
							old_word(N_GPIO - 1 downto 0) := gpio_data_reg;
							new_word := apply_wstrb(old_word, wdata_reg, wstrb_reg);
							gpio_data_reg <= new_word(N_GPIO - 1 downto 0);
						when "01" =>
							old_word(N_GPIO - 1 downto 0) := gpio_dir_reg_i;
							new_word := apply_wstrb(old_word, wdata_reg, wstrb_reg);
							gpio_dir_reg_i <= new_word(N_GPIO - 1 downto 0);
						when others =>
							null;
					end case;

					s_axi_bvalid <= '1';
					aw_stored <= '0';
					w_stored  <= '0';
				end if;

				if (s_axi_bvalid = '1' and s_axi_bready = '1') then
					s_axi_bvalid <= '0';
				end if;

				if (s_axi_arvalid = '1' and s_axi_arready = '1') then
					araddr_reg <= s_axi_araddr;
					rd_word := (others => '0');

					case s_axi_araddr(3 downto 2) is
						when "00" =>
							rd_word(N_GPIO - 1 downto 0) := gpio_read_data;
						when "01" =>
							rd_word(N_GPIO - 1 downto 0) := gpio_dir_reg_i;
						when others =>
							rd_word := (others => '0');
					end case;

					rdata_reg    <= rd_word;
					s_axi_rvalid <= '1';
				end if;

				if (s_axi_rvalid = '1' and s_axi_rready = '1') then
					s_axi_rvalid <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture;
