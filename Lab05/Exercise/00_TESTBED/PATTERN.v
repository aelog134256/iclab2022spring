//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright NYCU SI2 Lab      
//            All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2022 ICLAB SPRING Course
//   Lab05      : SRAM, Template Matching with Image Processing
//   Author     : Yu-Wei Lu
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v2.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//============================================================================
//  
//  Date   : 2022/3/25
//  Author : EECS Lab
//  
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  
//  Debuggging mode : Generating file
//  Debugging file  : Ouput_Result.txt
//  Path            : In-place
//  
//============================================================================

`ifdef RTL
    `timescale 1ns/10ps
    `include "TMIP.v"
    `define CYCLE_TIME 12.0
`endif
`ifdef GATE
    `timescale 1ns/10ps
    `include "TMIP_SYN.v"
    `define CYCLE_TIME 12.0
`endif

module PATTERN(
    // output signals
    clk,
    rst_n,
    in_valid,
    in_valid_2,
    image,
    img_size,
    template, 
    action,

    // input signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);
//======================================
//          I/O PORTS
//======================================
output reg                      clk;
output reg                    rst_n;
output reg                 in_valid;
output reg               in_valid_2;

output reg signed [15:0]      image; // in_valid
output reg signed [15:0]   template; // in_valid
output reg [4:0]           img_size; // in_valid
output reg [2:0]             action; // in_valid2 

input                     out_valid;
input [3:0]                   out_x; // Max Value
input [3:0]                   out_y; // Max Value
input [7:0]             out_img_pos;
input signed[39:0]        out_value;


//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter PATNUM = 5;              // Total number of pattern
parameter SIMPLE = 100;            //Represent the number of simple pattern
parameter CYCLE  = `CYCLE_TIME;
parameter DELAY  = 10000;
integer   SEED   = 5200122;

integer       i;
integer       j;
integer       m;
integer       n;
integer       k;
integer     pat;
integer exe_lat;
integer out_lat;
integer tot_lat;

integer file_out;


//pragma protect
//pragma protect begin

//====================
//  Image Pattern
//====================
// Print flag
reg signed[39:0] flag;
reg signed[39:0] un_flag = 'dx;

// Image size
integer sel;
integer size;

//pragma protect end

// Action info
integer act_num;
integer act_list[0:15];

// Cross Correlation 
reg signed[39:0]  gold_imag[0:15][0:15];
reg signed[39:0]  gold_temp[0:2][0:2];
reg signed[39:0]  gold_padd[0:17][0:17];


//pragma protect
//pragma protect begin


// Max Pooling
reg signed[39:0] max_temp;

// Four type Flipping Adjustment
reg signed[39:0] swap_temp;

// Zoom In
reg signed[39:0]  zoom_temp[0:15][0:15];

// Brightness Adjustment
reg signed[39:0]  brigh_temp[0:15][0:15];

// Golden output
integer gold_x;
integer gold_y;
integer gold_pos_x[0:8];
integer gold_pos_y[0:8];
integer gold_pos_num;
integer gold_pos[0:8];



//======================================
//              Clock
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        dump_task;
        wait_task;
        //check_task;

        // Print Pass Info and accumulate the total latency
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
        tot_lat = tot_lat + exe_lat;
    end
    pass_task;
end endtask

task reset_task; begin

    tot_lat = 0;

    force clk  = 0;
    rst_n      = 1;
    in_valid   = 0;
    in_valid_2 = 0;
    image      = 'dx;
    template   = 'dx;
    img_size   = 'dx;
    action     = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if ( out_valid !== 0 || out_x !== 0 || out_y !== 0 || out_img_pos !== 0 || out_value !== 0 ) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

task input_task; begin
    repeat( ({$random(SEED)} % 4 + 2) ) @(negedge clk);

    //===========================
    //      Preprocess
    //===========================
    // Decide the size of image
    sel = {$random(SEED)}%3;
    if(sel==0)      size = 4;
    else if(sel==1) size = 8;
    else            size = 16;

    // Decide the number of action
    act_num = {$random(SEED)}%16 + 1;

    //===========================
    //      Give Input
    //===========================
    // Invalid 1
    m = 0;
    for(i=0 ; i<size ; i=i+1) begin
        for(j=0 ; j<size ; j=j+1) begin

            // Overlap check
            if ( out_valid === 1 ) begin
                $display("                                                                 ``...`                                ");
                $display("     Out_valid can't overlap in_valid!!!                      `.-:::///:-::`                           "); 
                $display("                                                            .::-----------/s.                          "); 
                $display("                                                          `/+-----------.--+s.`                        "); 
                $display("                                                         .+y---------------/m///:-.                    "); 
                $display("                         ``.--------.-..``            `:+/mo----------:/+::ys----/++-`                 "); 
                $display("                     `.:::-:----------:::://-``     `/+:--yy----/:/oyo+/:+o/-------:+o:-:/++//::.`     "); 
                $display("                  `-//::-------------------:/++:.` .+/----/ho:--:/+/:--//:-----------:sd/------://:`   "); 
                $display("                .:+/----------------------:+ooshdyss:-------::-------------------------od:--------::   ");
                $display("              ./+:--------------------:+ssosssyyymh-------------------------------------+h/---------   ");
                $display("             :s/-------------------:osso+osyssssdd:--------------------------------------+myoos+/:--   ");
                $display("           `++-------------------:oso+++os++osshm:----------------------------------------ss--/:---/   ");
                $display("          .s/-------------------sho+++++++ohyyodo-----------------------------------------:ds+//+/:.   "); 
                $display("         .y/------------------/ys+++++++++sdsdym:------------------------------------------/y---.`     "); 
                $display("        .d/------------------oy+++++++++++omyhNd--------------------------------------------+:         "); 
                $display("       `yy------------------+h++++++++++++ydhohy---------------------------------------------+.        "); 
                $display("       -m/-----------------:ho++++++++++++odyhoho--------------------/++:---------------------:        "); 
                $display("       +y------------------ss+++++++++++ossyoshod+-----------------+ss++y:--------------------+`       "); 
                $display("       y+-//::------------:ho++++++++++osyhddyyoom/---------------::------------------/syh+--+/        "); 
                $display("      `hy:::::////:-/:----+d+++++++++++++++++oshhhd--------------------------------------/m+++`        "); 
                $display("      `hs--------/oo//+---/d++++++++++++++++++++sdN+-------------------------------:------:so`         "); 
                $display("       :s----------:+y++:-/d++++++++++++++++++++++sh+--------------:+-----+--------s--::---os          "); 
                $display("       .h------------:ssy-:mo++++++++++++++++++++++om+---------------+s++ys----::-:s/+so---/+/.        "); 
                $display("    `:::yy-------------/do-hy+++++o+++++++++++++++++oyyo--------------::::--:///++++o+/:------y.       "); 
                $display("  `:/:---ho-------------:yoom+++++hsh++++++++++++ossyyhNs---------------------+hmNmdys:-------h.       "); 
                $display(" `/:-----:y+------------.-sshy++++ohNy++++++++sso+/:---sy--------------------/NMMMMMNhs-----+s/        "); 
                $display(" +:-------:ho-------------:homo+++++hmo+++++oho:--------ss///////:------------yNMMMNdoy//+shd/`        "); 
                $display(" y---------:hs/------------+yod++++++hdo+++odo------------::::://+oo+o/--------/oso+oo::/sy+:o/        "); 
                $display(" y----/+:---::so:----------/m-sdo+oyo+ydo+ody------------------------/oo/------:/+oo/-----::--h.       "); 
                $display(" oo---/ss+:----:/----------+y--+hyooysoydshh----------------------------ohosshhs++:----------:y`       "); 
                $display(" `/oo++oosyo/:------------:yy++//sdysyhhydNdo:---------------------------shdNN+-------------+y-        "); 
                $display("    ``...``.-:/+////::-::/:.`.-::---::+oosyhdhs+/:-----------------------/s//oy:---------:os+.         "); 
                $display("               `.-:://---.                 ````.:+o/::-----------------:/o`  `-://::://:---`           "); 
                $display("                                                  `.-//+o////::/::///++:.`           ``                "); 
                $display("                                                        ``..-----....`                                 ");
                repeat(5) @(negedge clk);
                $finish;
            end

            // Patnum < SIMPLE =====> simple testing data
            // Image
            in_valid = 1;
            if(pat < SIMPLE) image = {$random(SEED)}%201 - 150;
            else             image = $random(SEED);
            gold_imag[i][j] = $signed(image);

            // Template
            if(m<9) begin
                if( pat<SIMPLE ) template = $random(SEED)%5;
                else             template = $random(SEED);
                gold_temp[m/3][m%3] = $signed(template);
            end
            else                 template = 'dx;
            m = m + 1;

            // Image size
            if(j==0 && i==0) img_size = size;
            else             img_size = 'dx;

            @(negedge clk);
        end
    end

    in_valid = 0;
    image    = 'dx;
    template = 'dx;
    img_size = 'dx;

    // Invalid 2
    @(negedge clk);
    for(i=0 ; i<act_num ; i=i+1) begin

        // Overlap check
            if ( out_valid === 1 ) begin
                $display("                                                                 ``...`                                ");
                $display("     Out_valid can't overlap in_valid!!!                      `.-:::///:-::`                           "); 
                $display("                                                            .::-----------/s.                          "); 
                $display("                                                          `/+-----------.--+s.`                        "); 
                $display("                                                         .+y---------------/m///:-.                    "); 
                $display("                         ``.--------.-..``            `:+/mo----------:/+::ys----/++-`                 "); 
                $display("                     `.:::-:----------:::://-``     `/+:--yy----/:/oyo+/:+o/-------:+o:-:/++//::.`     "); 
                $display("                  `-//::-------------------:/++:.` .+/----/ho:--:/+/:--//:-----------:sd/------://:`   "); 
                $display("                .:+/----------------------:+ooshdyss:-------::-------------------------od:--------::   ");
                $display("              ./+:--------------------:+ssosssyyymh-------------------------------------+h/---------   ");
                $display("             :s/-------------------:osso+osyssssdd:--------------------------------------+myoos+/:--   ");
                $display("           `++-------------------:oso+++os++osshm:----------------------------------------ss--/:---/   ");
                $display("          .s/-------------------sho+++++++ohyyodo-----------------------------------------:ds+//+/:.   "); 
                $display("         .y/------------------/ys+++++++++sdsdym:------------------------------------------/y---.`     "); 
                $display("        .d/------------------oy+++++++++++omyhNd--------------------------------------------+:         "); 
                $display("       `yy------------------+h++++++++++++ydhohy---------------------------------------------+.        "); 
                $display("       -m/-----------------:ho++++++++++++odyhoho--------------------/++:---------------------:        "); 
                $display("       +y------------------ss+++++++++++ossyoshod+-----------------+ss++y:--------------------+`       "); 
                $display("       y+-//::------------:ho++++++++++osyhddyyoom/---------------::------------------/syh+--+/        "); 
                $display("      `hy:::::////:-/:----+d+++++++++++++++++oshhhd--------------------------------------/m+++`        "); 
                $display("      `hs--------/oo//+---/d++++++++++++++++++++sdN+-------------------------------:------:so`         "); 
                $display("       :s----------:+y++:-/d++++++++++++++++++++++sh+--------------:+-----+--------s--::---os          "); 
                $display("       .h------------:ssy-:mo++++++++++++++++++++++om+---------------+s++ys----::-:s/+so---/+/.        "); 
                $display("    `:::yy-------------/do-hy+++++o+++++++++++++++++oyyo--------------::::--:///++++o+/:------y.       "); 
                $display("  `:/:---ho-------------:yoom+++++hsh++++++++++++ossyyhNs---------------------+hmNmdys:-------h.       "); 
                $display(" `/:-----:y+------------.-sshy++++ohNy++++++++sso+/:---sy--------------------/NMMMMMNhs-----+s/        "); 
                $display(" +:-------:ho-------------:homo+++++hmo+++++oho:--------ss///////:------------yNMMMNdoy//+shd/`        "); 
                $display(" y---------:hs/------------+yod++++++hdo+++odo------------::::://+oo+o/--------/oso+oo::/sy+:o/        "); 
                $display(" y----/+:---::so:----------/m-sdo+oyo+ydo+ody------------------------/oo/------:/+oo/-----::--h.       "); 
                $display(" oo---/ss+:----:/----------+y--+hyooysoydshh----------------------------ohosshhs++:----------:y`       "); 
                $display(" `/oo++oosyo/:------------:yy++//sdysyhhydNdo:---------------------------shdNN+-------------+y-        "); 
                $display("    ``...``.-:/+////::-::/:.`.-::---::+oosyhdhs+/:-----------------------/s//oy:---------:os+.         "); 
                $display("               `.-:://---.                 ````.:+o/::-----------------:/o`  `-://::://:---`           "); 
                $display("                                                  `.-//+o////::/::///++:.`           ``                "); 
                $display("                                                        ``..-----....`                                 ");
                repeat(5) @(negedge clk);
                $finish;
            end

        in_valid_2 = 1;
        if(i==act_num-1) action = 0;
        else             action = {$random(SEED)}%7 + 1; // 1~7
        act_list[i] = action;

        @(negedge clk);
    end

    in_valid_2 = 0;
    action     = 'dx;
end endtask

task wait_task; begin
    exe_lat = -1;
    while ( out_valid!==1 ) begin
        if ( out_x !== 0 || out_y !== 0 || out_img_pos !== 0 || out_value !== 0 ) begin
            $display("                                           `:::::`                                                       ");
            $display("                                          .+-----++                                                      ");
            $display("                .--.`                    o:------/o                                                      ");
            $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
            $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
            $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
            $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
            $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
            $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
            $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
            $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
            $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
            $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
            $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
            $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
            $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
            $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
            $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
            $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
            $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
            $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
            $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
            $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
            $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
            $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
            $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
            $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) @(negedge clk);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %6d  cycles    `:::--:/++:----------::/:.                ", DELAY);
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

task check_task; begin
    out_lat = 0;
    i = 0;
    j = 0;
    m = 0;
    while (out_valid === 1) begin
        if (out_lat == size*size) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than %-3d                  /s:-----+s`     at %-12d ps   ", size*size, $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
        end

        if ( i<size && j<size ) begin

            //====================
            // Check
            //====================
            // Out_x and Out_y
            if(out_x !== gold_x || out_y !== gold_y) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    The Out_x and Out_y is not correct!!!         /s:-----+s`     at %-12d ps   ", $time*1000);
                $display("                                                  y/-------:y                   ");
                $display("                                             `.-:/od+/------y`                  ");
                $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
                $display("                              -m+:::::::---------------------::o+.              ");
                $display("                             `hod-------------------------------:o+             ");
                $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
                $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
                $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
                $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
                $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
                $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
                $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
                $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
                $display("                 s:----------------/s+///------------------------------o`       ");
                $display("           ``..../s------------------::--------------------------------o        ");
                $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
                $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
                $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
                $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
                $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
                $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
                $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
                $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
                $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
                $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
                $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
                $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
                $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
                $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
                $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
                $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
                $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
                $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
                $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
                $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
                $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
                $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
                $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
                repeat(5) @(negedge clk);
                $finish;
            end

            // Out_value
            if(out_value !== gold_imag[i][j]) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    The Out_value is not correct!!!               /s:-----+s`     at %-12d ps   ", $time*1000);
                $display("                                                  y/-------:y                   ");
                $display("                                             `.-:/od+/------y`                  ");
                $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
                $display("                              -m+:::::::---------------------::o+.              ");
                $display("                             `hod-------------------------------:o+             ");
                $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
                $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
                $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
                $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
                $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
                $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
                $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
                $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
                $display("                 s:----------------/s+///------------------------------o`       ");
                $display("           ``..../s------------------::--------------------------------o        ");
                $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
                $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
                $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
                $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
                $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
                $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
                $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
                $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
                $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
                $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
                $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
                $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
                $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
                $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
                $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
                $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
                $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
                $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
                $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
                $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
                $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
                $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
                $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
                repeat(5) @(negedge clk);
                $finish;
            end

            // Matching template position
            if(m < gold_pos_num && out_img_pos !== gold_pos[m]) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    The Out_img_pos is not correct!!!             /s:-----+s`     at %-12d ps   ", $time*1000);
                $display("                                                  y/-------:y                   ");
                $display("                                             `.-:/od+/------y`                  ");
                $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
                $display("                              -m+:::::::---------------------::o+.              ");
                $display("                             `hod-------------------------------:o+             ");
                $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
                $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
                $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
                $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
                $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
                $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
                $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
                $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
                $display("                 s:----------------/s+///------------------------------o`       ");
                $display("           ``..../s------------------::--------------------------------o        ");
                $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
                $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
                $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
                $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
                $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
                $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
                $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
                $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
                $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
                $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
                $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
                $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
                $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
                $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
                $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
                $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
                $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
                $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
                $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
                $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
                $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
                $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
                $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
                repeat(5) @(negedge clk);
                $finish;
            end
            else if(m>= gold_pos_num && out_img_pos !== 0) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    The Out_img_pos should be zero!!!             /s:-----+s`     at %-12d ps   ", $time*1000);
                $display("                                                  y/-------:y                   ");
                $display("                                             `.-:/od+/------y`                  ");
                $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
                $display("                              -m+:::::::---------------------::o+.              ");
                $display("                             `hod-------------------------------:o+             ");
                $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
                $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
                $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
                $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
                $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
                $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
                $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
                $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
                $display("                 s:----------------/s+///------------------------------o`       ");
                $display("           ``..../s------------------::--------------------------------o        ");
                $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
                $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
                $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
                $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
                $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
                $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
                $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
                $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
                $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
                $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
                $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
                $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
                $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
                $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
                $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
                $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
                $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
                $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
                $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
                $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
                $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
                $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
                $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
                repeat(5) @(negedge clk);
                $finish;
            end

            // Update index
            if ( i<size )  j=j+1;
            if ( j==size ) begin
                i=i+1;
                j=0;
            end
            m = m+1;
        end

        out_lat = out_lat + 1;
        @(negedge clk);
    end
    
    if (out_lat<size*size) begin     
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than %-2d                  /s:-----+s`     at %-12d ps   ", size*size, $time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   "); 
        repeat(5) @(negedge clk);
        $finish;
    end
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask

//===========================================================================

//======================================
//  Image Operation
//======================================

task cross_task; begin
    // Zero Padding
    for ( i=0 ; i<size+2 ; i=i+1 ) begin
        for ( j=0 ; j<size+2 ; j=j+1 ) begin
            if ( i==0 || i==size+1 ) begin
                gold_padd[i][j] = 0;
            end
            else if ( j==0 || j==size+1 ) begin
                gold_padd[i][j] = 0;
            end
            else begin
                gold_padd[i][j] = gold_imag[i-1][j-1];
            end
        end
    end

    // Output
    for ( i=0 ; i<size ; i=i+1 ) begin
        for ( j=0 ; j<size ; j=j+1 ) begin
            gold_imag[i][j] = 0;
            for ( m=0 ; m<3 ; m=m+1 ) begin
                for ( n=0 ; n<3 ; n=n+1 ) begin
                    gold_imag[i][j] = gold_imag[i][j] + gold_temp[m][n] * gold_padd[i+m][j+n];
                end
            end
        end
    end

    // Find the max value coordinate
    max_temp = gold_imag[0][0];
    gold_x = 0;
    gold_y = 0;
    for (i=0 ; i<size ; i=i+1) begin
        for (j=0 ; j<size ; j=j+1) begin
            if(gold_imag[i][j] > max_temp) begin
                max_temp = gold_imag[i][j];
                gold_x = i;
                gold_y = j;
            end
        end
    end

    // Find the matching template position coordinate
    m = 0;
    for (i=gold_x-1 ; i<gold_x+2 ; i=i+1) begin
        for(j= gold_y-1 ; j<gold_y+2 ; j=j+1) begin
            gold_pos_x[m] = i;
            gold_pos_y[m] = j;
            m = m+1;
        end
    end

    // Find the true template position
    // Clear 
    gold_pos_num = 0;
    for (i=0 ; i<9 ; i=i+1) gold_pos[i] = 'dx;
    // Get 
    for (i=0 ; i<9 ; i=i+1) begin
        if(gold_pos_x[i] !== -1 && gold_pos_y[i] !== -1 && gold_pos_x[i] !== size && gold_pos_y[i] !== size) begin
            gold_pos[gold_pos_num] = gold_pos_x[i]*size + gold_pos_y[i];
            gold_pos_num = gold_pos_num + 1;
        end
    end

end endtask

task maxpool_task; begin
    // If the image size is 4, the output of max pooling will be the same
    if(size != 4) begin
        // Max pooling
        for (i=0 ; i<size ; i=i+2) begin
            for (j=0 ; j<size ; j=j+2) begin
                max_temp = gold_imag[i][j];
                for ( m=0 ; m<2 ; m=m+1 ) begin
                    for ( n=0 ; n<2 ; n=n+1 ) begin
                        if (gold_imag[i+m][j+n] > max_temp)
                            max_temp = gold_imag[i+m][j+n]; 
                    end
                end
                gold_imag[i/2][j/2] = max_temp;
            end
        end

        // Modify size
        // 8  ===> 4
        // 16 ===> 8
        size = size/2;

        // Clear the out-of-bound value
        for ( i=0 ; i<16 ; i=i+1 ) begin
            for ( j=0 ; j<16 ; j=j+1 ) begin
                if ( i>=size || j>=size )
                    gold_imag[i][j] = 'dx;
            end
        end
    end
end endtask

task h_flip_task; begin
    for(i=0 ; i<size ; i=i+1) begin
        for(j=0 ; j<size/2 ; j=j+1) begin
            swap_temp              = gold_imag[i][j];
            gold_imag[i][j]        = gold_imag[i][size-j-1];
            gold_imag[i][size-j-1] = swap_temp;
        end
    end
end endtask

task v_flip_task; begin
    for(i=0 ; i<size/2 ; i=i+1) begin
        for(j=0 ; j<size ; j=j+1) begin
            swap_temp              = gold_imag[i][j];
            gold_imag[i][j]        = gold_imag[size-i-1][j];
            gold_imag[size-i-1][j] = swap_temp;
        end
    end
end endtask

task left_diag_task; begin
    for(i=0 ; i<size ; i=i+1) begin
        for(j=0 ; j<size-i ; j=j+1) begin
            if((i+j) !== (size-1)) begin
                swap_temp                     = gold_imag[i][j];
                gold_imag[i][j]               = gold_imag[size-j-1][size-i-1];
                gold_imag[size-j-1][size-i-1] = swap_temp;
            end
        end
    end
end endtask

task right_diag_task; begin
    for(i=0 ; i<size ; i=i+1) begin
        for(j=i ; j<size ; j=j+1) begin
            swap_temp       = gold_imag[i][j];
            gold_imag[i][j] = gold_imag[j][i];
            gold_imag[j][i] = swap_temp;
        end
    end
end endtask

task zoom_in_task; begin
    if(size !== 16) begin
        // Store temp image
        for(i=0 ; i<size ; i=i+1) begin
            for(j=0 ; j<size ; j=j+1) begin
                zoom_temp[i][j] = gold_imag[i][j];
            end
        end

        // Zoom-in
        for ( i=0 ; i<size ; i=i+1 ) begin
            for ( j=0 ; j<size ; j=j+1 ) begin
                gold_imag[i*2  ][j*2  ] = zoom_temp[i][j];
                gold_imag[i*2+1][j*2  ] = $floor(zoom_temp[i][j]*2/3 + 20);
                gold_imag[i*2  ][j*2+1] = $floor(zoom_temp[i][j]/3);
                gold_imag[i*2+1][j*2+1] = $floor(zoom_temp[i][j]*0.5);
            end
        end

        // Modify size
        size = size*2;

        // Clear the out-of-bound value
        for ( i=0 ; i<16 ; i=i+1 ) begin
            for ( j=0 ; j<16 ; j=j+1 ) begin
                if ( i>=size || j>=size )
                    gold_imag[i][j] = 'dx;
            end
        end
    end
end endtask

task short_bright_task; begin
    // First step : brightness adjustment
    for(i=0 ; i<size ; i=i+1) begin
        for(j=0 ; j<size ; j=j+1) begin
            brigh_temp[i][j] = $floor(gold_imag[i][j]*0.5 + 50);
        end
    end

    // Second step : shortcut
    if(size !== 4) begin
        // Shortcut image
        for ( i=0 ; i<size/2 ; i=i+1 ) begin
            for ( j=0 ; j<size/2 ; j=j+1 ) begin
                gold_imag[i][j] = brigh_temp[i+size/4][j+size/4];
            end
        end

        // Modify size
        size = size/2;

        // Clear the out-of-bound value
        for ( i=0 ; i<16 ; i=i+1 ) begin
            for ( j=0 ; j<16 ; j=j+1 ) begin
                if ( i>=size || j>=size )
                    gold_imag[i][j] = 'dx;
            end
        end
    end
    else begin
        for(i=0 ; i<size ; i=i+1) begin
            for(j=0 ; j<size ; j=j+1) begin
                gold_imag[i][j] = brigh_temp[i][j];
            end
        end
    end
end endtask


task dump_task; begin
    file_out = $fopen("Ouput_Result.txt", "w");


    //-------------------------
    // Action Info
    //-------------------------
    $fwrite(file_out, "--------------------------------------------------------------------------------------------------------------------------\n");
    $fwrite(file_out, "Number of action : %-2d\n", act_num);
    $fwrite(file_out, "Action list : ");
    for(k=0 ; k<act_num ; k=k+1) $fwrite(file_out, "%-1d ", act_list[k]);
    $fwrite(file_out, "\n--------------------------------------------------------------------------------------------------------------------------\n");

    //-------------------------
    // Original Image
    //-------------------------
    $fwrite(file_out, "     Original Image\n");

    // Print row index
    $fwrite(file_out, "%d ", un_flag);
    for(i=0 ; i<size ; i=i+1) begin
        flag = i;
        $fwrite(file_out, "%d ",flag);
    end
    $fwrite(file_out, "\n");

    for(i=0 ; i<size ; i=i+1) begin
        // Print column index
        flag = i;
        $fwrite(file_out, "%d ",flag);

        // Print value
        for(j=0 ; j<size ; j=j+1) begin
            $fwrite(file_out, "%d ",gold_imag[i][j]);
        end
        $fwrite(file_out, "\n");
    end

    for(k=0 ; k<act_num ; k=k+1) begin
        $fwrite(file_out, "==========================================================================================================================\n");
        case(act_list[k])
            0:$fwrite(file_out, "     Cross correlation\n");
            1:$fwrite(file_out, "     Max Pooling\n");
            2:$fwrite(file_out, "     Horizontal Flip\n");
            3:$fwrite(file_out, "     Vertical   Flip\n");
            4:$fwrite(file_out, "     Left-diagonal Flip\n");
            5:$fwrite(file_out, "     Right-diagonal Flip\n");
            6:$fwrite(file_out, "     Zoom in\n");
            7:$fwrite(file_out, "     Shortcut Brightness Adjustment\n");
        endcase

        case(act_list[k])
            0 : cross_task;
            1 : maxpool_task;
            2 : h_flip_task;
            3 : v_flip_task;
            4 : left_diag_task;
            5 : right_diag_task;
            6 : zoom_in_task;
            7 : short_bright_task;
        endcase
        
        $fwrite(file_out, "==========================================================================================================================\n");
        if(act_list[k] == 0) begin

            //-------------------------
            // Template Image
            //-------------------------
            $fwrite(file_out, "     Template Image\n");

            // Print row index
            $fwrite(file_out, "%d ", un_flag);
            for(i=0 ; i<3 ; i=i+1) begin
                flag = i;
                $fwrite(file_out, "%d ",flag);
            end
            $fwrite(file_out, "\n");

            for(i=0 ; i<3 ; i=i+1) begin

                // Print column index
                flag = i;
                $fwrite(file_out, "%d ",flag);

                // Print value
                for(j=0 ; j<3 ; j=j+1) begin
                    $fwrite(file_out, "%d ",gold_temp[i][j]);
                end
                $fwrite(file_out, "\n");
            end


            //-------------------------
            // Position of Image
            //-------------------------
            $fwrite(file_out, "--------------------------------------------------------------------------------------------------------------------------\n");
            $fwrite(file_out, "     Position\n");

            // Print row index
            $fwrite(file_out, "%d ", un_flag);
            for(i=0 ; i<size ; i=i+1) begin
                flag = i;
                $fwrite(file_out, "%d ",flag);
            end
            $fwrite(file_out, "\n");

            for(i=0 ; i<size ; i=i+1) begin

                // Print column index
                flag = i;
                $fwrite(file_out, "%d ",flag);

                // Print value
                for(j=0 ; j<size ; j=j+1) begin
                    flag = i*size+j;
                    $fwrite(file_out, "%d ", flag);
                end
                $fwrite(file_out, "\n");
            end


            $fwrite(file_out, "--------------------------------------------------------------------------------------------------------------------------\n");
            $fwrite(file_out, "     Final Image\n");
        end
        else if(act_list[k] == 7) begin
            //-------------------------
            // Brightness of Image
            //-------------------------
            $fwrite(file_out, "     After Brightness\n");


            if(brigh_temp[size+1][size+1] !== 'dx) begin
                // Print row index
                $fwrite(file_out, "%d ", un_flag);
                for(i=0 ; i<size*2 ; i=i+1) begin
                    flag = i;
                    $fwrite(file_out, "%d ",flag);
                end
                $fwrite(file_out, "\n");

                for(i=0 ; i<size*2 ; i=i+1) begin
                    // Print column index
                    flag = i;
                    $fwrite(file_out, "%d ",flag);

                    // Print value
                    for(j=0 ; j<size*2 ; j=j+1) begin
                        $fwrite(file_out, "%d ",brigh_temp[i][j]);
                    end
                    $fwrite(file_out, "\n");
                end
            end
            else begin
                // Print row index
                $fwrite(file_out, "%d ", un_flag);
                for(i=0 ; i<size ; i=i+1) begin
                    flag = i;
                    $fwrite(file_out, "%d ",flag);
                end
                $fwrite(file_out, "\n");

                for(i=0 ; i<size ; i=i+1) begin
                    // Print column index
                    flag = i;
                    $fwrite(file_out, "%d ",flag);

                    // Print value
                    for(j=0 ; j<size ; j=j+1) begin
                        $fwrite(file_out, "%d ",brigh_temp[i][j]);
                    end
                    $fwrite(file_out, "\n");
                end
            end


            $fwrite(file_out, "--------------------------------------------------------------------------------------------------------------------------\n");
            $fwrite(file_out, "     After Shortcut\n");
        end


        //-------------------------
        // Golden Image
        //-------------------------
        // Print row index
        $fwrite(file_out, "%d ", un_flag);
        for(i=0 ; i<size ; i=i+1) begin
            flag = i;
            $fwrite(file_out, "%d ",flag);
        end
        $fwrite(file_out, "\n");

        for(i=0 ; i<size ; i=i+1) begin
            // Print column index
            flag = i;
            $fwrite(file_out, "%d ",flag);

            // Print value
            for(j=0 ; j<size ; j=j+1) begin
                $fwrite(file_out, "%d ",gold_imag[i][j]);
            end
            $fwrite(file_out, "\n");
        end
    end
    $fwrite(file_out, "==========================================================================================================================\n");
    $fwrite(file_out, "Max Value             : (%-2d, %-2d)\n", gold_x, gold_y);
    $fwrite(file_out, "==========================================================================================================================\n");
    $fwrite(file_out, "The matching position : ");
    for(i=0 ; i<gold_pos_num ; i=i+1)
        $fwrite(file_out, "%-2d ", gold_pos[i]);
    $fwrite(file_out, "\n==========================================================================================================================\n");

    $fclose(file_out);

end endtask

endmodule

//pragma protect end
