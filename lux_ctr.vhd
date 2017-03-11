library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all;  
use ieee.std_logic_unsigned.all; 

ENTITY luxcontroller IS
PORT (  clk        : in    std_logic ; -- System Clock
        rst        : in    std_logic ; -- System Rese
        run        : in    std_logic ; -- run lux algo
        
    
     ); 
END luxcontroller;

ARCHITECTURE RTL OF controller IS

component   lux is
    Port ( clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
			  start : in  STD_LOGIC;
			  start_rst : in  STD_LOGIC;
			  done  : out STD_LOGIC;
           Mt    : in  STD_LOGIC_VECTOR (31 downto 0);
			  Cout  : out  STD_LOGIC_VECTOR (31 downto 0)
			  );
end component ;


component ram_dual is 
generic( d_width    : integer := 12; 
         addr_width : integer := 8; 
         mem_depth  : integer := 32
        ); 
port (o1        : out STD_LOGIC_VECTOR(d_width - 1 downto 0); 
      o2        : out STD_LOGIC_VECTOR(d_width - 1 downto 0);
      we1       : in STD_LOGIC;
      we2       : in STD_LOGIC;
      rst       : in STD_LOGIC;
      clk       : in STD_LOGIC; 
      d1        : in STD_LOGIC_VECTOR(d_width - 1 downto 0); 
      addr1     : in unsigned(addr_width - 1 downto 0);
      d2        : in STD_LOGIC_VECTOR(d_width - 1 downto 0); 
      addr2     : in unsigned(addr_width - 1 downto 0)      
      
      ); 
end component; 


-- FSM States
   type state_type is (idle, first_round, wait_R_first,Mt_round, wait_R_Mt,last_Mt, 
                       last_round32,last_round32n,wait_R_32,wait_R_32n,lenght_round0,wait_R_lenght0,
                       lenght_round1,wait_R_lenght1, empty_round,wait_R_empty, c3_round,wait_R_C3);
  -- FSM registers
  signal state_reg : state_type;
  signal state_next: state_type;

  signal count_round_reg, count_round_next : unsigned(32 downto 0);
  
  signal lux_start : STD_LOGIC;
  signal lux_start_rst : STD_LOGIC;
  signal lux_done : STD_LOGIC;
  signal lux_Mt : STD_LOGIC_VECTOR (31 downto 0);
  signal lux_Cout  : STD_LOGIC_VECTOR (31 downto 0);
  
  signal ramMt_o1, ramMt_o2, ramMt_we1 , ramMt_we2 : STD_LOGIC;
  signal ramC3_o1, ramC3_o2, ramC3_we1 , ramC3_we2 : STD_LOGIC;
  signal ramMt_d1,ramMt_d2,ramC3_d1,ramC3_d2 :STD_LOGIC_VECTOR (31 downto 0);
  
  signal ramC3_addr1,ramC3_addr2 : unsigned( 3 downto 0);
  signal ramMt_addr1,ramMt_addr2 : unsigned( 9 downto 0);
  
BEGIN
U_lux: lux PORT MAP ( 
        clk        => clk,
        rst        => rst,
	     start      => lux_start,
        start_rst  => lux_start_rst,
        done       => lux_done,
        Mt         => lux_Mt,
        Cout       =>lux_Cout 
    );
 
 U_ram_Mt: ram_dual 
 generic map (d_width   => 32,
              addr_width => 1024,
              mem_depth  : integer := 10)
 PORT MAP (
      o1   =>ramMt_o1 ,
      o2   =>ramMt_o2 ,
      we1  =>ramMt_we1 ,
      we2  =>ramMt_we2 ,
      rst  =>rst ,
      clk  =>clk ,
      d1   =>ramMt_d1 ,
      addr1=>ramMt_addr1 ,
      d2   =>ramMt_d2 ,
      addr2=>ramMt_addr2 );
  
   U_ram_C3: ram_dual 
 generic map (d_width   => 32,
              addr_width => 8,
              mem_depth  : integer := 4)
 PORT MAP (
      o1   =>ramC3_o1 ,
      o2   =>ramC3_o2 ,
      we1  =>ramC3_we1 ,
      we2  =>ramC3_we2 ,
      rst  =>rst ,
      clk  =>clk ,
      d1   =>ramC3_d1 ,
      addr1=>ramC3_addr1 ,
      d2   =>ramC3_d2 ,
      addr2=>ramC3_addr2 );        
    
cloked_process : process( clk, rst )
  begin
    if( rst='1' ) then
      state_reg <= idle;
      message_lenght_reg <= (others=>'0') ;
      count_round_reg <= (others=>'0') ;
    elsif( clk'event and clk='1' ) then
      state_reg <= state_next;
      count_round_reg <= count_round_next;
      message_lenght_reg <= message_lenght_next;
    end if;
 end process ;
 
 
   combinatory_FSM_next : process(state_reg, run, lux_done, message_lenght_reg, count_round_reg)
  begin
    state_next<= state_reg;
    case state_reg is
    

    when idle =>
      if run = '1' then
        state_next <=first_round;
      end if
        
    when first_round =>
        state_next <=wait_R_first;
        
    when wait_R_first =>
      if lux_done = '1' then
        state_next <=
     end if;  
    when Mt_round =>
        state_next <=wait_R_Mt;
        
    when wait_R_Mt =>
      if lux_done = '1'  and message_lenght_reg = count_round_reg then
        state_next <=last_Mt;
      elsif lux_done = '1' then 
        state_next <= Mt_round;
      end if; 
        
    when last_Mt =>
        if message_lenght_reg(5 downto 0) = "00000" then
          state_next <=last_round32;
        else 
          state_next <=last_round32n;
        end if;
        
    when last_round32 =>
        state_next <= wait_R_32;
        
    when last_round32n =>
        state_next <= wait_R_32n;
        
    when wait_R_32 =>
      if lux_done = '1' then
        state_next <= lenght_round0;
      end if; 
        
    when wait_R_32n =>
      if lux_done = '1' then
        state_next <= lenght_round0;
      end if; 
        
    when lenght_round0 =>
        state_next <= wait_R_lenght0;
        
    when wait_R_lenght0 =>
     if lux_done = '1' then
        state_next <=lenght_round1;
     end if; 
        
    when lenght_round1 =>wait_R_lenght1;
        state_next <=
        
    when wait_R_lenght1 =>
     if lux_done = '1' then
        state_next <=empty_round;
     end if; 
        
    when empty_round =>
        state_next <=wait_R_empty;
        
    when wait_R_empty =>
     if lux_done = '1' and count_round_reg = 15 then
        state_next <= c3_round;
     elsif lux_done = '1' then
        state_next <= empty_round;
     end if; 
        
    when c3_round =>
        state_next <= wait_R_C3;
        
    when wait_R_C3 =>
     if lux_done = '1' and count_round_reg = 7 then
        state_next <= idle;
     elsif lux_done = '1' then
        state_next <= c3_round;
     end if; 
     
    when others =>

    end case;
  end process;
     

combinatory_command : process( )
begin 
    
 lux_start <= '0';
 lux_start_rst <= '0' ;

 -- lux_Mt <= ? (RAM_mt, modif last, 08, 00, lenght0,lenght1)
 -- addr_ram_mt ? (read) 
 -- save C3 addr++ ramC3_addr1 (write)
 
      
    case state_reg is
    

    when idle =>
        
    when first_round =>
        lux_start_rst <= '1';
        --lux_Mt <= RAM_MT
        --addr_ram_mt ++
        
    when wait_R_first =>
        
    when Mt_round =>
         lux_start <= '1';
         --lux_Mt <= RAM_MT
         --addr_ram_mt ++
         
        
    when wait_R_Mt =>

        
    when last_Mt =>
        
    when last_round32 =>
         lux_start <= '1';
         --lux_Mt <= "80"
         
    when last_round32n =>
         lux_start <= '1';
         --lux_Mt <= MMM10000000 (modified last)
    when wait_R_32 =>
        
    when wait_R_32n =>
        
    when lenght_round0 =>
        lux_start <= '1';
         --lux_Mt <= lenght 0 (4byte)
    
    when wait_R_lenght0 =>
        
    when lenght_round1 =>
        lux_start <= '1';
         ----lux_Mt <= lenght 1 (4byte)
    
    when wait_R_lenght1 =>
        
    when empty_round =>
         lux_start <= '1';
         ----lux_Mt <= 0000000000
         
    when wait_R_empty =>

        
    when c3_round =>
          lux_start <= '1';
         ----lux_Mt <= 0000000000
         -- save C3 addr++

    when wait_R_C3 =>
     
    when others =>

    end case;
  end process;
 
 