library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SequenceDetector is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        in_bit   : in  STD_LOGIC;
        detected : out STD_LOGIC
    );
end SequenceDetector;

architecture Behavioral of SequenceDetector is
    
    type state_type is (S0, S1, S2, S3, S4);
    signal state, next_state : state_type;
    
begin
    
    process(clk, reset)
    begin
        if reset = '1' then
            state <= S0;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
    
    process(state, in_bit)
    begin
        case state is
            when S0 => 
                if in_bit = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
                
            when S1 =>  
                if in_bit = '0' then
                    next_state <= S2;
                else
                    next_state <= S0;
                end if;
                
            when S2 =>  
                if in_bit = '1' then
                    next_state <= S3;
                else
                    next_state <= S0;
                end if;
                
            when S3 =>  
                if in_bit = '1' then
                    next_state <= S4;
                else
                    next_state <= S0;
                end if;
                
            when S4 =>  
                next_state <= S0;  
                
            when others =>
                next_state <= S0;
        end case;
    end process;
    
    detected <= '1' when state = S4 else '0';
    
end Behavioral;
