`include "Usertype_PKG.sv"

module GEN_DRAM ();

//===================================
// PARAMETERS & VARIABLES
//===================================
parameter DRAM_OFFSET = 'h10000;
parameter USER_NUM    = 256;
integer   SEED        = 5200122;

integer addr;
integer file;

//===================================
// BAG & PKM INFO
//===================================
// Bag Info
// 4 bit 
Item_num   berry_num;
Item_num   medicine_num;
Item_num   candy_num;
Item_num   bracer_num;
// 2 bit
Stone      stone_type;
// 14 bit
Money      money;

// PKM Info
// 4 bit
Stage      pkm_stage;
PKM_Type   pkm_type;
// 8 bit
HP         pkm_hp;
ATK        pkm_atk;
EXP        pkm_exp;

//================================================================
//      CLASS RANDOM
//================================================================
// Bag Info
// Item
class random_item_numm;
    rand Item_num ran_item_num;
    function new ( int seed );
        this.srandom(seed);
    endfunction 
endclass

// Stone
class random_stone_type;
    rand Stone ran_stone_type;
    function new ( int seed );
        this.srandom(seed);
    endfunction
    constraint range{
        ran_stone_type inside { No_stone, W_stone, F_stone, T_stone };
    }
endclass

// Money
class random_amnt;
    rand Money ran_money;
    function new ( int seed );
        this.srandom(seed);
    endfunction
endclass

// PKM Info
// PKM Type
class random_type;
    rand PKM_Type ran_type;
    function new ( int seed );
        this.srandom(seed);
    endfunction 
    constraint range{
        ran_type inside { No_type, Grass, Fire, Water, Electric, Normal };
    }
endclass

// PKM Stage
class random_stage;
    rand Stage ran_stage;
    function new ( int seed );
        this.srandom(seed);
    endfunction 
    constraint range{
        ran_stage inside { Lowest, Middle, Highest };
    }
endclass

// Bag Info
random_item_numm  rNum   = new(SEED);
random_stone_type rStone = new(SEED);
random_amnt       rAmnt  = new(SEED);

// PKM Info
random_type       rType  = new(SEED);
random_stage      rStage = new(SEED);

initial begin
    file = $fopen("../00_TESTBED/DRAM/dram.dat","w");
    for( addr=DRAM_OFFSET ; addr<((DRAM_OFFSET+USER_NUM*8)-1) ; addr=addr+'h8 )  begin
        $fwrite(file, "@%5h\n", addr);
        // Bag Info
        void'(rNum.randomize());
        berry_num    = rNum.ran_item_num;
        void'(rNum.randomize());
        medicine_num = rNum.ran_item_num;
        void'(rNum.randomize());
        candy_num    = rNum.ran_item_num;
        void'(rNum.randomize());
        bracer_num   = rNum.ran_item_num;

        void'(rStone.randomize());
        stone_type   = rStone.ran_stone_type;

        void'(rAmnt.randomize());
        money        = rAmnt.ran_money;
        $fwrite(file, "%1h%1h %1h%1h %h %h\n", berry_num, medicine_num, candy_num, bracer_num, {stone_type, money[13:8]}, money[7:0]);
        //$display("[Bag Info]]");
        //$display("%1h %1h %1h %1h %s %1h", berry_num, medicine_num, candy_num, bracer_num, stone_type.name(), money);

        // PKM Info
        rType.randomize();
        pkm_type   = rType.ran_type;

        if (pkm_type == No_type) begin
            pkm_stage = No_stage;
            pkm_hp    = 0;
            pkm_atk   = 0;
            pkm_exp   = 0;
        end
        else begin
            rStage.randomize();
            pkm_stage = rStage.ran_stage;

        end

        case(pkm_type)
            Grass    : begin
                if(pkm_stage == Lowest) begin
                    pkm_hp  = {$random(SEED)} % 'd128 + 'd1;
                    pkm_atk = 'd63;
                    pkm_exp = {$random(SEED)} % 'd32;
                end
                else if(pkm_stage == Middle) begin
                    pkm_hp  = {$random(SEED)} % 'd192 + 'd1;
                    pkm_atk = 'd94;
                    pkm_exp = {$random(SEED)} % 'd63;
                end
                else if(pkm_stage == Highest) begin
                    pkm_hp  = {$random(SEED)} % 'd254 + 'd1;
                    pkm_atk = 'd123;
                    pkm_exp = 0;
                end
            end
            Fire     : begin
                if(pkm_stage == Lowest) begin
                    pkm_hp  = {$random(SEED)} % 'd119 + 'd1;
                    pkm_atk = 'd64;
                    pkm_exp = {$random(SEED)} % 'd30;
                end
                else if(pkm_stage == Middle) begin
                    pkm_hp  = {$random(SEED)} % 'd177 + 'd1;
                    pkm_atk = 'd96;
                    pkm_exp = {$random(SEED)} % 'd59;
                end
                else if(pkm_stage == Highest) begin
                    pkm_hp  = {$random(SEED)} % 'd225 + 'd1;
                    pkm_atk = 'd127;
                    pkm_exp = 0;
                end
            end
            Water    : begin
                if(pkm_stage == Lowest) begin
                    pkm_hp  = {$random(SEED)} % 'd125 + 'd1;
                    pkm_atk = 'd60;
                    pkm_exp = {$random(SEED)} % 'd28;
                end
                else if(pkm_stage == Middle) begin
                    pkm_hp  = {$random(SEED)} % 'd187 + 'd1;
                    pkm_atk = 'd89;
                    pkm_exp = {$random(SEED)} % 'd55;
                end
                else if(pkm_stage == Highest) begin
                    pkm_hp  = {$random(SEED)} % 'd245 + 'd1;
                    pkm_atk = 'd113;
                    pkm_exp = 0;
                end
            end
            Electric : begin
                if(pkm_stage == Lowest) begin
                    pkm_hp  = {$random(SEED)} % 'd122 + 'd1;
                    pkm_atk = 'd65;
                    pkm_exp = {$random(SEED)} % 'd26;
                end
                else if(pkm_stage == Middle) begin
                    pkm_hp  = {$random(SEED)} % 'd182 + 'd1;
                    pkm_atk = 'd97;
                    pkm_exp = {$random(SEED)} % 'd51;
                end
                else if(pkm_stage == Highest) begin
                    pkm_hp  = {$random(SEED)} % 'd235 + 'd1;
                    pkm_atk = 'd124;
                    pkm_exp = 0;
                end
            end
            Normal : begin
                pkm_stage = Lowest;
                pkm_hp  = {$random(SEED)} % 'd124 + 'd1;
                pkm_atk = 'd62;
                pkm_exp = {$random(SEED)} % 'd29;
            end
        endcase
        $fwrite(file, "@%5h\n", addr+'h4);
        $fwrite(file, "%1h%1h %h %h %h\n", pkm_stage, pkm_type, pkm_hp, pkm_atk, pkm_exp);
    end
    $fclose(file);
    $display("=================================");
    $display("= Generate DRAM Data Successful =");
    $display("=================================");
end

endmodule
