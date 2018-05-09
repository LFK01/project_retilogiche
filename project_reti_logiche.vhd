library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
entity project_reti_logiche is
    Port ( 
            i_clk         : in  std_logic;
            i_start       : in  std_logic;
            i_rst         : in  std_logic;
            i_data        : in  std_logic_vector(7 downto 0); --automaticamente va a vedere o_address e tira fuori il valore alla posizione o_address
            o_address     : out std_logic_vector(15 downto 0);
            o_done        : out std_logic;
            o_en          : out std_logic;
            o_we          : out std_logic;
            o_data        : out std_logic_vector (7 downto 0) 
         );
end project_reti_logiche;
architecture Behavioral of project_reti_logiche is
signal count_c: std_logic_vector(7 downto 0):= "00000001";
signal count_r: std_logic_vector(7 downto 0):= "00000001";
signal col, rig, soglia: std_logic_vector(7 downto 0);
signal state: std_logic_vector(3 downto 0):= "0000"; 
signal my_address: std_logic_vector(15 downto 0):= (others => '0');
signal doArea: std_logic := '0';
signal max_c, max_r: std_logic_vector(7 downto 0):= "00000000";
signal min_c, min_r: std_logic_vector(7 downto 0):= "11111111";
signal latoA,latoB: std_logic_vector(7 downto 0):= "00000000";
signal risultato: std_logic_vector(15 downto 0):= "0000000000000000";

begin
o_address <= my_address;
o_we <= '1' when state = "1000" or state = "1001" 
    else '0';
process(i_clk, i_rst)
begin
o_en <= '1';
if i_rst = '1' then
     state <= "0000";
elsif i_clk'event and i_clk = '1' then                 --rising_edge(i_clk)
    if state = "0000" and i_start = '1' then
        state <= "0001";
        my_address <= my_address + "0000000000000010";      --richiesta indirizzo di memoria numero 2
    elsif state = "0001" then
        state <= "0010";
        my_address <= my_address + "0000000000000001";
    elsif state = "0010" then                  --lettura colonne e richiesta indirizzo memoria 3
        col <= i_data; 
        state <= "0011";
        my_address <= my_address + "0000000000000001";
    elsif state = "0011" then                        --lettura righe e richiesta indirizzo memoria 4
        rig <= i_data; 
        state <= "0100";
        my_address <= my_address + "0000000000000001";
    elsif state ="0100" then                        --lettura soglia e richiesta indirizzo memoria 5
        soglia <= i_data; 
        my_address <= my_address + "0000000000000001";
        state <= "0101";
    elsif state = "0101" then
        if i_data >= soglia then -- lettura pixel valido
            doArea <= '1'; -- gestione estremi aggiornati, area da calcolare
            if count_c < min_c  then  --posizione min_c da aggiornare
                min_c <= count_c;
            end if;
            if count_c > max_c then  --posizione max_c da aggiornare
                max_c <= count_c;
            end if;
            if count_r < min_r then  --posizione min_r da aggiornare
                min_r <= count_r;
            end if;
            if count_r > max_r then  --posizione max_r da aggiornare
                max_r <= count_r;
            end if;
        end if;
        if count_c > col-1 then
            count_c <= "00000001";
            count_r <= count_r + "00000001";
            if count_r > rig-1 then
                state <= "1010";
            else my_address <= my_address + "0000000000000001";
            end if;
        end if;
        if count_r <= rig and count_c < col then
            my_address <= my_address + "0000000000000001";
            count_c <= count_c + "00000001";
        end if;
    elsif state = "1010" then
        latoA <= max_c-min_c+1;
        latoB <= max_r-min_r+1;
        state <= "0110";
    elsif state = "0110" then
        risultato <= latoA*latoB;
        if doArea = '0' then
            risultato <= "0000000000000000";
        end if;
        state <= "0111";
    elsif state = "0111" then
        my_address <= "0000000000000001";
        o_data <=  risultato(15 downto 8);
        state <= "1000";
    elsif state = "1000" then
        my_address <= "0000000000000000";
        o_data <=  risultato(7 downto 0);
        state <= "1001";
    elsif state = "1001" then
        o_done <= '1';
        state <= "1111";
    elsif state = "1111" then
        o_done <= '0';
    end if;
end if;    
 
end process;
end Behavioral;