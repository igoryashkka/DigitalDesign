library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity traffic_fsm is
    Port ( clk       : in  STD_LOGIC;   
           reset     : in  STD_LOGIC;   
           Ta        : in  STD_LOGIC;   -- Sensor for first street
           Tb        : in  STD_LOGIC;   -- Sensor for second street
           La1       : out STD_LOGIC;   -- Traffic light output for first street (Red/Yellow/Green)
           La0       : out STD_LOGIC;   -- Traffic light output for first street (Red/Yellow/Green)
           Lb1       : out STD_LOGIC;   -- Traffic light output for second street (Red/Yellow/Green)
           Lb0       : out STD_LOGIC    -- Traffic light output for second street (Red/Yellow/Green)
           );
end traffic_fsm;

architecture Behavioral of traffic_fsm is

    
    type state_type is (S0, S1, S2, S3);  
    signal state, next_state : state_type;

begin

    
    process (clk, reset)
    begin
        if reset = '1' then
            state <= S0; 
        elsif rising_edge(clk) then
            state <= next_state;  
        end if;
    end process;

    
    process (state, Ta, Tb)
    begin
        case state is
            when S0 =>
                if Ta = '1' then
                    next_state <= S0; 
                else
                    next_state <= S1; 
                end if;

            when S1 =>
                next_state <= S2; 

            when S2 =>
					 if Tb = '1' then
                    next_state <= S2; 
                else
                    next_state <= S3; 
                end if;

            when S3 =>
                next_state <= S0; 

            when others =>
                next_state <= S0;
        end case;
    end process;

    process (state)
    begin
        case state is
            when S0 =>
                La1 <= '0'; 
                La0 <= '0'; 
            when S1 =>
                La1 <= '0'; 
                La0 <= '1'; 
            when S2 =>
                La1 <= '1'; 
                La0 <= '0'; 
            when S3 =>
                La1 <= '1'; 
                La0 <= '1'; 
            when others =>
                La1 <= '0'; 
                La0 <= '0'; 
        end case;

        
        case state is
            when S0 =>
                Lb1 <= '1';
                Lb0 <= '0';
            when S1 =>
                Lb1 <= '1';
                Lb0 <= '0';
            when S2 =>
                Lb1 <= '0';
                Lb0 <= '0';
            when S3 =>
                Lb1 <= '0';
                Lb0 <= '1';
            when others =>
                Lb1 <= '1';
                Lb0 <= '0'; 
        end case;
    end process;

end Behavioral;
