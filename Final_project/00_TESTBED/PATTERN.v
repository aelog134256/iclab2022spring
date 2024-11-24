//============================================================================
//  
//  Date   : 2022/6/5
//  Author : EECS Lab
//  
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  
//  Debuggging mode : Generating file
//  Debugging file  : Midterm_Golden.txt
//                    Midterm_Your.txt
//  Path            : In-place
//  
//============================================================================

`ifdef RTL
    `define CYCLE_TIME 20
`endif
`ifdef GATE
    `define CYCLE_TIME 20
`endif

`include "../00_TESTBED/pseudo_DRAM.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
    // CHIP IO 
    clk,
    rst_n,
    in_valid,
    start,
    stop,
    inputtype,
    frame_id,
    busy,

    // AXI4 IO
    awid_s_inf,
    awaddr_s_inf,
    awsize_s_inf,
    awburst_s_inf,
    awlen_s_inf,
    awvalid_s_inf,
    awready_s_inf,

    wdata_s_inf,
    wlast_s_inf,
    wvalid_s_inf,
    wready_s_inf,

    bid_s_inf,
    bresp_s_inf,
    bvalid_s_inf,
    bready_s_inf,

    arid_s_inf,
    araddr_s_inf,
    arlen_s_inf,
    arsize_s_inf,
    arburst_s_inf,
    arvalid_s_inf,

    arready_s_inf,
    rid_s_inf,
    rdata_s_inf,
    rresp_s_inf,
    rlast_s_inf,
    rvalid_s_inf,
    rready_s_inf
);

// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
output reg              clk, rst_n;
output reg              in_valid;
output reg              start;
output reg [15:0]       stop;     
output reg [1:0]        inputtype; 
output reg [4:0]        frame_id;
input                   busy;       

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1)     axi write address channel 
//         src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
//         src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)    axi write data channel 
//         src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
//         src slave
output wire                  wready_s_inf;

// (3)    axi write response channel 
//         src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
//         src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)    axi read address channel 
//         src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
//         src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)    axi read data channel 
//         src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
//         src master
input wire                   rready_s_inf;


// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(
    .clk(clk),
    .rst_n(rst_n),

    .   awid_s_inf(   awid_s_inf),
    . awaddr_s_inf( awaddr_s_inf),
    . awsize_s_inf( awsize_s_inf),
    .awburst_s_inf(awburst_s_inf),
    .  awlen_s_inf(  awlen_s_inf),
    .awvalid_s_inf(awvalid_s_inf),
    .awready_s_inf(awready_s_inf),

    .  wdata_s_inf(  wdata_s_inf),
    .  wlast_s_inf(  wlast_s_inf),
    . wvalid_s_inf( wvalid_s_inf),
    . wready_s_inf( wready_s_inf),

    .    bid_s_inf(    bid_s_inf),
    .  bresp_s_inf(  bresp_s_inf),
    . bvalid_s_inf( bvalid_s_inf),
    . bready_s_inf( bready_s_inf),

    .   arid_s_inf(   arid_s_inf),
    . araddr_s_inf( araddr_s_inf),
    .  arlen_s_inf(  arlen_s_inf),
    . arsize_s_inf( arsize_s_inf),
    .arburst_s_inf(arburst_s_inf),
    .arvalid_s_inf(arvalid_s_inf),
    .arready_s_inf(arready_s_inf), 

    .    rid_s_inf(    rid_s_inf),
    .  rdata_s_inf(  rdata_s_inf),
    .  rresp_s_inf(  rresp_s_inf),
    .  rlast_s_inf(  rlast_s_inf),
    . rvalid_s_inf( rvalid_s_inf),
    . rready_s_inf( rready_s_inf) 
);

//================================
//      PARAMETERS & VARIABLES
//================================
//----------------------------------------------------
// You can modify parameter here

// Check mode
// 0 ---> check the accuracy every frame
// 1 ---> check the accuracy when type 0 or type 1 is finished
parameter CHECK_MODE       = 1;

// How many pattern for each type
parameter PATNUM       = 10;

// How many inputtype
// 2 ---> 0, 1
// 4 ---> 0, 1, 2, 3
parameter TYPE_NUM_SEL = 4;

// Random Seed
integer   SEED         = 122;

// Display control
// You can decide how many rows will be display in Midter_Debug.txt
parameter pixelperRow  = 30; 
//----------------------------------------------------

//pragma protect
//pragma protect begin

parameter CYCLE        = `CYCLE_TIME;
parameter DELAY        = 1000000;


//==============================
// 32 Frame
// 1 Frame has 16 histogram
// 1 histogram has 255 bins
// (Frame x histogram x bins)
// (32 x 16 x 255)
//==============================
parameter BIN_NUM      = 255; // Number of bins
parameter HIST_SIDE    = 4;
parameter HIST_NUM     = 16;
parameter FRAME_NUM    = 32;
parameter FRAME_OFFSET = 'h10000;
parameter FRAME_SHIFT  = 'h01000;
parameter HIST_SHIFT   = 'h00100;

// Type basic control
parameter DIST_RANGE_0_1 = 251;
parameter DIST_RANGE_2_3 = 236;

// NUMER / DENOM
parameter DENOM_STOP  = 10;
parameter BACK_NUMER  = 3;
parameter PULSE_SIZE  = 5;
integer   PULSE_NUMER[0:TYPE_NUM_SEL-1][0:PULSE_SIZE-1];

parameter TYPE_0_MAX = 15;
parameter TYPE_1_MAX = 4;
parameter TYPE_2_MAX = 7;
parameter TYPE_3_MAX = 7;

parameter DISTANCE   = 5;

integer         i;
integer         j;
integer         m;
integer         n;
integer         k;
integer idx_pulse;
integer   idx_pat;
integer   exe_lat;
integer   out_lat;
integer   tot_lat;

integer file_in;
integer file_out;

//---------------------------
// Frame Data and Operation
//---------------------------
//====================
//  Data Input
//====================
integer type_in;
integer fram_id_in;

integer start_num;

//====================
//  Frame Pixel
//====================
reg[7:0] gold_hist      [0:HIST_NUM-1][0:BIN_NUM-1];
reg[7:0] gold_dist      [0:HIST_NUM-1];
reg[7:0] gold_dist_type0[0:FRAME_NUM-1][0:HIST_NUM-1];

reg[7:0] your_hist[0:HIST_NUM-1][0:BIN_NUM-1];
reg[7:0] your_dist[0:HIST_NUM-1];

reg[7:0] mark_hist[0:HIST_NUM-1][0:BIN_NUM-1];
reg[7:0] mark_dist[0:HIST_NUM-1];
integer mark_flag;

// Convex & Concave 
integer x_center, y_center;
integer dist_center;
// 0 : convex
// 1 : concave
integer type_3_shape;

// Accuracy
integer corr_cnt;
integer total_corr_cnt;
real    diff_accuracy;
real    total_accuracy;

//---------------------------

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
    condition_task;
    reset_task;
    for (type_in=0 ; type_in<TYPE_NUM_SEL ; type_in=type_in+1) begin
        if(type_in == 0) begin
            for (idx_pat=0 ; idx_pat<FRAME_NUM ; idx_pat=idx_pat+1) begin
                input_task;
                wait_task;
                check_task;
                // Print Pass Info and accumulate the total latency
                $display("\033[0;34mPASS : TYPE %1d, PATTERN NO.%4d, FRAME %2d,\033[m \033[0;32m ACCURACY %6f, Cycles: %3d\033[m", type_in, idx_pat, fram_id_in, diff_accuracy, exe_lat);
                tot_lat = tot_lat + exe_lat;
            end
            $display("\033[0;32mTYPE %1d, TOTAL FRAME %5d, TOTAL CORRECT HIST %5d, TOTAL ACCURACY %6f\033[m\n", type_in, PATNUM, total_corr_cnt, total_accuracy);
        end
        else begin
            for (idx_pat=0 ; idx_pat<PATNUM ; idx_pat=idx_pat+1) begin
                input_task;
                wait_task;
                check_task;
                // Print Pass Info and accumulate the total latency
                $display("\033[0;34mPASS : TYPE %1d, PATTERN NO.%4d, FRAME %2d,\033[m \033[0;32m ACCURACY %6f, Cycles: %3d\033[m", type_in, idx_pat, fram_id_in, diff_accuracy, exe_lat);
                tot_lat = tot_lat + exe_lat;
            end
            $display("\033[0;32mTYPE %1d, TOTAL FRAME %5d, TOTAL CORRECT HIST %5d, TOTAL ACCURACY %6f\033[m\n", type_in, PATNUM, total_corr_cnt, total_accuracy);
        end
    end
    pass_task;
end endtask

task condition_task; begin
    if(TYPE_NUM_SEL !== 2 && TYPE_NUM_SEL !== 3 && TYPE_NUM_SEL !== 4) begin
        $display("===========================================");
        $display("Please select the correct TYPE_NUM_SEL : %-d", TYPE_NUM_SEL);
        $display("===========================================");
        $finish;
    end
end endtask

task reset_task; begin
    force clk = 0;
    rst_n     = 1;
    in_valid  = 0;
    start     = 'dx;
    stop      = 'dx;
    inputtype = 'dx;
    frame_id  = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (busy !== 0) begin
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

    // After reseting, the pattern will send type 0 firstly
    // Thus, we load the distance of type 0
    loadDistType0_task;

    // Initial the pulse function
    initPulse_task;
end endtask

task input_task; begin
    repeat( ({$random(SEED)} % 8 + 3) ) @(negedge clk);

    if(type_in == 0) begin
        // Initial the golden frame
        // type 0     ---> DRAM
        fram_id_in = idx_pat;
        initFrame_task(type_in, fram_id_in); // golden historgram
        initDist_task(type_in, fram_id_in);  // golden distance

        in_valid  = 1;
        inputtype = type_in;
        frame_id  = fram_id_in;
        @(negedge clk);

        in_valid  = 0;
        inputtype = 'dx;
        frame_id  = 'dx;
    end
    else begin
        // Initial the golden frame
        // type 1,2,3 ---> 0
        fram_id_in = {$random(SEED)}%FRAME_NUM;
        initFrame_task(type_in, fram_id_in);     // golden historgram
        initDist_task(type_in, fram_id_in);      // golden distance

        in_valid  = 1;
        inputtype = type_in;
        frame_id  = fram_id_in;

        start    = 0;
        stop     = 0;

        @(negedge clk);

        inputtype = 'dx;
        frame_id  = 'dx;

        if(type_in == 1)      start_num = TYPE_1_MAX;
        else if(type_in == 2) start_num = TYPE_2_MAX;
        else if(type_in == 3) start_num = TYPE_3_MAX;

        for(i=0 ; i<start_num ; i=i+1) begin
            if ( busy === 1 ) begin
                $display("                                                                 ``...`                                ");
                $display("     busy can't overlap in_valid!!!                           `.-:::///:-::`                           ");
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

            repeat( ({$random(SEED)} % 8 + 3) ) @(negedge clk);

            // Repeat how many of bins
            for(j=0 ; j<BIN_NUM ; j=j+1) begin
                // Start
                start = 1;

                // Decide how many histogram to be set one in each frame
                for(k=0 ; k<HIST_NUM ; k=k+1) begin
                    // Probability : NUMER_STOP / DENOM_STOP
                    // Distance with pulse function
                    if($signed(j+1-gold_dist[k]) < 5 && $signed(j+1-gold_dist[k]) >= 0) begin
                        // $display("%d %d || %d %d %d %d",j, k, gold_dist[k], PULSE_NUMER[type_in][j+1-gold_dist[k]], start_num, $signed(j+1-gold_dist[k]));
                        if(({$random(SEED)} % DENOM_STOP) < PULSE_NUMER[type_in][j+1-gold_dist[k]]) begin
                            if(gold_hist[k][j] < start_num) begin
                                stop[k] = 1;
                            end
                            else begin
                                stop[k] = 0;
                            end
                        end
                        else begin
                            stop[k] = 0;
                        end
                    end
                    // Background
                    else begin
                        if(({$random(SEED)} % DENOM_STOP) < BACK_NUMER) begin
                            if(gold_hist[k][j] < start_num) begin
                                stop[k] = 1;
                            end
                            else begin
                                stop[k] = 0;
                            end
                        end
                        else begin
                            stop[k] = 0;
                        end
                    end
                end
                // Set the stop into frame
                setStopFrame_task(j, stop);

                @(negedge clk);
            end
            start    = 0;
            stop     = 0;
        end

        in_valid = 0;
        start    = 'dx;
        stop     = 'dx;
    end
end endtask

// Busy should be 0 after input
//             become 1 when the design is calculating
//             become 0 after process is finished

task wait_task; begin
    // Wait for the busy becomes 1
    exe_lat = -1;
    while (busy !== 1) begin
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %5d   cycles    `:::--:/++:----------::/:.                ", DELAY);
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
    // Wait for the busy becomes 0
    while (busy !== 0) begin
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %5d   cycles    `:::--:/++:----------::/:.                ", DELAY);
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

    // After busy becomes 0
    // Check the DRAM Data

    // Clear the mark histogram and mark distance
    mark_flag = 0;
    for(i=0 ; i<HIST_NUM ; i=i+1) begin
        mark_dist[i] = 0;
        for(j=0 ; j<BIN_NUM ; j=j+1) begin
            mark_hist[i][j] = 0;
        end
    end

    // Load the fram from DRAM
    loadyourFrame_task(fram_id_in);

    // Compare the frame of DRAM with the golden frame
    // Distance
    calAccuracy_task(diff_accuracy);

    // Frame
    for(i=0 ; i<HIST_NUM ; i=i+1) begin
        for(j=0 ; j<BIN_NUM ; j=j+1) begin
            if(your_hist[i][j] !== gold_hist[i][j]) begin
                mark_hist[i][j] = 1;
                mark_flag       = 1;
            end
        end
    end
    // Dump Debug Info
    dumpGoldenFrame_task;
    dumpYourFrame_task;

    // Accumalate the total accuracy
    if(idx_pat == 0) begin
        total_corr_cnt = corr_cnt;
        total_accuracy = diff_accuracy;
    end
    else begin
        total_corr_cnt = total_corr_cnt + corr_cnt;
        total_accuracy = total_accuracy + diff_accuracy;
    end
    // Re-calculate
    if(type_in == 0 && idx_pat == FRAME_NUM - 1) total_accuracy = total_accuracy/FRAME_NUM;
    else if(type_in != 0 && idx_pat == PATNUM - 1) total_accuracy = total_accuracy/PATNUM;

    if(type_in == 0 || type_in == 1) begin
        if( CHECK_MODE == 0 && mark_flag === 1) begin
            $display("                                                                                ");
            $display("    Check mode 0 => Check every frame accuracy     ./+oo+/.                     ");
            $display("    Your Output is not correct                    /s:-----+s`     at %-12d ps   ", $time*1000);
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
        else if(CHECK_MODE == 1 && type_in == 0 && idx_pat == FRAME_NUM-1 && total_accuracy<=0.5 ) begin
            $display("                                                                                ");
            $display("    Check mode 1 => Check total accuracy           ./+oo+/.                     ");
            $display("    Your Output is not correct                    /s:-----+s`     at %-12d ps   ", $time*1000);
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
            $display("Total frame        : %10d", FRAME_NUM);
            $display("Total correct hist : %10d", total_corr_cnt);
            $display("Total accuracy     : %10f", total_accuracy);
            repeat(5) @(negedge clk);
            $finish;
        end
        else if(CHECK_MODE == 1 && type_in == 1 && idx_pat == PATNUM-1 && total_accuracy<=0.5 ) begin
            $display("                                                                                ");
            $display("    Check mode 1 => Check total accuracy           ./+oo+/.                     ");
            $display("    Your Output is not correct                    /s:-----+s`     at %-12d ps   ", $time*1000);
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
            $display("Total frame        : %10d", PATNUM);
            $display("Total correct hist : %10d", total_corr_cnt);
            $display("Total accuracy     : %10f", total_accuracy);
            repeat(5) @(negedge clk);
            $finish;
        end
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

//==============================
integer i_T, j_T, k_T;
integer windowSize;
integer windowSum;
// integer maxSum[0:HIST_NUM-1];

// Load frame from DRAM
task loadyourFrame_task;
    input integer id_T;
begin
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        your_dist[i_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + BIN_NUM];
        for(j_T=0 ; j_T<BIN_NUM+1 ; j_T=j_T+1) begin
            your_hist[i_T][j_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + j_T];
        end
    end
end endtask

task initPulse_task; begin
    for(i_T=0 ; i_T<TYPE_NUM_SEL ; i_T=i_T+1) begin
        if(i_T == 0 || i_T == 1) begin
            PULSE_NUMER[i_T][0] = 6;
            PULSE_NUMER[i_T][1] = 3;
            PULSE_NUMER[i_T][2] = 6;
            PULSE_NUMER[i_T][3] = 3;
            PULSE_NUMER[i_T][4] = 6;
        end
        else begin
            PULSE_NUMER[i_T][0] = 4;
            PULSE_NUMER[i_T][1] = 7;
            PULSE_NUMER[i_T][2] = 6;
            PULSE_NUMER[i_T][3] = 5;
            PULSE_NUMER[i_T][4] = 4;
        end
    end
end endtask

task initFrame_task;
    input integer type_T;
    input integer id_T;
begin
    // Read the histogram from DRAM
    if(type_T == 0) begin
        //$display("%h", id_T*FRAME_SHIFT+FRAME_OFFSET);
        //$display("%h", (id_T+1)*FRAME_SHIFT+FRAME_OFFSET);
        //$display("%h", (HIST_NUM-1)*HIST_SHIFT);
        //$display("%h", BIN_NUM-1);
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
            for(j_T=0 ; j_T<BIN_NUM ; j_T=j_T+1) begin
                gold_hist[i_T][j_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + j_T];
            end
        end
    end
    // Use stop to set the histogram
    else begin
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
            for(j_T=0 ; j_T<BIN_NUM ; j_T=j_T+1) begin
                gold_hist[i_T][j_T] = 0;
            end
        end
    end
end endtask

integer x_temp, y_temp;
integer x_dist, y_dist;
task initDist_task;
    input integer type_T;
    input integer id_T;
begin
    if(type_T == 0) begin
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1)
            gold_dist[i_T] = gold_dist_type0[id_T][i_T];
    end
    else if(type_T == 1) begin
        gold_dist[0]  = {$random(SEED)}%DIST_RANGE_0_1 + 1;
        gold_dist[1]  = gold_dist[0];
        gold_dist[4]  = gold_dist[0];
        gold_dist[5]  = gold_dist[0];

        gold_dist[2]  = {$random(SEED)}%DIST_RANGE_0_1 + 1;
        gold_dist[3]  = gold_dist[2];
        gold_dist[6]  = gold_dist[2];
        gold_dist[7]  = gold_dist[2];

        gold_dist[8]  = {$random(SEED)}%DIST_RANGE_0_1 + 1;
        gold_dist[9]  = gold_dist[8];
        gold_dist[12] = gold_dist[8];
        gold_dist[13] = gold_dist[8];

        gold_dist[10] = {$random(SEED)}%DIST_RANGE_0_1 + 1;
        gold_dist[11] = gold_dist[10];
        gold_dist[14] = gold_dist[10];
        gold_dist[15] = gold_dist[10];
    end
    else if(type_T == 2) begin
        // Convex
        x_center    = {$random(SEED)}%HIST_SIDE;
        y_center    = {$random(SEED)}%HIST_SIDE;
        dist_center = {$random(SEED)}%DIST_RANGE_2_3 + 1;
        gold_dist[x_center + y_center*HIST_SIDE] = dist_center;
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
            x_temp = i_T%HIST_SIDE;
            y_temp = i_T/HIST_SIDE;
            x_dist = (x_temp - x_center) > 0 ? (x_temp - x_center) : (x_center - x_temp);
            y_dist = (y_temp - y_center) > 0 ? (y_temp - y_center) : (y_center - y_temp);
            if(x_dist == 3 || y_dist == 3)      gold_dist[i_T] = dist_center + DISTANCE*3;
            else if(x_dist == 2 || y_dist == 2) gold_dist[i_T] = dist_center + DISTANCE*2;
            else if(x_dist == 1 || y_dist == 1) gold_dist[i_T] = dist_center + DISTANCE;
        end
    end
    else if(type_T == 3) begin
        // Decide the shape of type 3
        type_3_shape = {$random(SEED)}%2;
        if(type_3_shape == 0) begin
            // Convex
            x_center    = {$random(SEED)}%HIST_SIDE;
            y_center    = {$random(SEED)}%HIST_SIDE;
            dist_center = {$random(SEED)}%DIST_RANGE_2_3 + 1;
            gold_dist[x_center + y_center*HIST_SIDE] = dist_center;
            for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
                x_temp = i_T%HIST_SIDE;
                y_temp = i_T/HIST_SIDE;
                x_dist = (x_temp - x_center) > 0 ? (x_temp - x_center) : (x_center - x_temp);
                y_dist = (y_temp - y_center) > 0 ? (y_temp - y_center) : (y_center - y_temp);
                if(x_dist == 3 || y_dist == 3)      gold_dist[i_T] = dist_center + DISTANCE*3;
                else if(x_dist == 2 || y_dist == 2) gold_dist[i_T] = dist_center + DISTANCE*2;
                else if(x_dist == 1 || y_dist == 1) gold_dist[i_T] = dist_center + DISTANCE;
            end
        end
        else begin
            // Concave
            x_center    = {$random(SEED)}%HIST_SIDE;
            y_center    = {$random(SEED)}%HIST_SIDE;
            dist_center = {$random(SEED)}%(DIST_RANGE_2_3-DISTANCE*3) + DISTANCE*3 + 1;
            gold_dist[x_center + y_center*HIST_SIDE] = dist_center;
            for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
                x_temp = i_T%HIST_SIDE;
                y_temp = i_T/HIST_SIDE;
                x_dist = (x_temp - x_center) > 0 ? (x_temp - x_center) : (x_center - x_temp);
                y_dist = (y_temp - y_center) > 0 ? (y_temp - y_center) : (y_center - y_temp);
                if(x_dist == 3 || y_dist == 3)      gold_dist[i_T] = dist_center - DISTANCE*3;
                else if(x_dist == 2 || y_dist == 2) gold_dist[i_T] = dist_center - DISTANCE*2;
                else if(x_dist == 1 || y_dist == 1) gold_dist[i_T] = dist_center - DISTANCE;
            end
        end
    end
end endtask

// Set frame with the stop
task setStopFrame_task;
    input integer bin_T;
    input[HIST_NUM-1:0] stop_T;
begin
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        gold_hist[i_T][bin_T] = gold_hist[i_T][bin_T] + stop_T[i_T];
    end
end endtask

// Load golden distance from file  : type0
integer dummy1, dummy2;
task loadDistType0_task; begin
    file_in = $fopen("../00_TESTBED/dist.dat", "r");
    for(i_T=0 ; i_T<FRAME_NUM ; i_T=i_T+1) begin
        for(j_T=0 ; j_T<HIST_NUM ; j_T=j_T+1) begin
            $fscanf(file_in, "frame : %d hist : %d dist : %d\n", dummy1, dummy2, gold_dist_type0[i_T][j_T]);
            // $display("%d %d %d", dummy1, dummy2, gold_dist_type0[i_T][j_T]);
        end
    end
    $fclose(file_in);
end endtask

integer diff_dist;
task calAccuracy_task;
    output real accuracy_out;
begin
    corr_cnt = 0;
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        diff_dist = your_dist[i_T] - gold_dist[i_T];
        if(diff_dist < 0) diff_dist = -diff_dist;
        // $display("%d %d %d %d", your_dist[i_T], gold_dist[i_T], $signed(your_dist[i_T] - gold_dist[i_T]), diff_dist);
        if(diff_dist <= 'd3) begin
            corr_cnt = corr_cnt + 1;
        end
        else begin
            mark_dist[i_T] = 1;
        end
    end
    if(corr_cnt < 8) begin
        mark_flag    = 1;
    end
    accuracy_out = 1.0 * corr_cnt / HIST_NUM;
end endtask





// Dumper
task dumpGoldenFrame_task; begin
    file_out = $fopen("Midterm_Golden.txt", "w");

    $fwrite(file_out, "Start to debug for final project!!!\n\n");
    $fwrite(file_out, "Golden Frame!!!\n\n");

    //---------------
    // Input info
    //---------------
    $fwrite(file_out, "---------------------------------\n");
    $fwrite(file_out, "[INFO] Type             : %-2d\n", type_in);
    if(type_in == 3 && type_3_shape == 0)      $fwrite(file_out, "[INFO] Shape            : Convex\n");
    else if(type_in == 3 && type_3_shape == 1) $fwrite(file_out, "[INFO] Shape            : Concave\n");
    $fwrite(file_out, "[INFO] Frame id         : %-2d\n\n", fram_id_in);
    
    $fwrite(file_out, "[INFO] DRAM Start       : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET);
    $fwrite(file_out, "[INFO] DRAM End         : 0x%h\n\n", (fram_id_in+1)*FRAME_SHIFT+FRAME_OFFSET-1);
    
    $fwrite(file_out, "[INFO] Hist 0           : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET+0*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Hist %-2d          : 0x%h\n", (HIST_NUM-1), fram_id_in*FRAME_SHIFT+FRAME_OFFSET+(HIST_NUM-1)*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Correct Distance : %-2d\n", corr_cnt);
    $fwrite(file_out, "[INFO] Accuracy         : %-1.4f\n", diff_accuracy);
    $fwrite(file_out, "---------------------------------\n");

    //---------------
    // Distance Matrix
    //---------------
    $fwrite(file_out, "[INFO] Distance Matrix:\n");
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        $fwrite(file_out, "%d ", gold_dist[i_T]);
        if(i_T%HIST_SIDE == 3) $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "---------------------------------\n\n\n\n");

    //-------------------
    // Histogram info
    //-------------------
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        $fwrite(file_out, "    Histogram #%-2d\n", i_T);
        $fwrite(file_out, "    Distance  #%-1d\n\n", gold_dist[i_T]);
        // $fwrite(file_out, "    Max Sum    %-d\n", maxSum[i_T]);
        for(j_T=0 ; j_T<BIN_NUM ; j_T=j_T+1) begin
            // Display index
            if((j_T%pixelperRow) == 0) begin
                for(k_T=j_T ;k_T<j_T+pixelperRow ; k_T=k_T+1) begin
                    if(k_T < BIN_NUM) $fwrite(file_out, "#%-3d  ", k_T+1);
                end
                $fwrite(file_out, "\n");
            end

            // Display bins
            $fwrite(file_out, "%3d   ", gold_hist[i_T][j_T]);
            if(((j_T+1)%pixelperRow) == 0) begin
                $fwrite(file_out, "\n");
            end
        end
        $fwrite(file_out, "\n\n");
    end

    $fclose(file_out);
end endtask

task dumpYourFrame_task; begin
    file_out = $fopen("Midterm_Your.txt", "w");

    $fwrite(file_out, "Start to debug for final project!!!\n\n");
    $fwrite(file_out, "Your Frame!!!\n\n");

    //---------------
    // Input info
    //---------------
    $fwrite(file_out, "---------------------------------\n");
    $fwrite(file_out, "[INFO] Type             : %-2d\n", type_in);
    if(type_in == 3 && type_3_shape == 0)      $fwrite(file_out, "[INFO] Shape            : Convex\n");
    else if(type_in == 3 && type_3_shape == 1) $fwrite(file_out, "[INFO] Shape            : Concave\n");
    $fwrite(file_out, "[INFO] Frame id         : %-2d\n\n", fram_id_in);
    
    $fwrite(file_out, "[INFO] DRAM Start       : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET);
    $fwrite(file_out, "[INFO] DRAM End         : 0x%h\n\n", (fram_id_in+1)*FRAME_SHIFT+FRAME_OFFSET-1);
    
    $fwrite(file_out, "[INFO] Hist 0           : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET+0*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Hist %-2d          : 0x%h\n", (HIST_NUM-1), fram_id_in*FRAME_SHIFT+FRAME_OFFSET+(HIST_NUM-1)*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Correct Distance : %-2d\n", corr_cnt);
    $fwrite(file_out, "[INFO] Accuracy         : %-1.4f\n", diff_accuracy);
    $fwrite(file_out, "---------------------------------\n");

    //---------------
    // Distance Matrix
    //---------------
    $fwrite(file_out, "[INFO] Distance Matrix:\n");
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        $fwrite(file_out, "%d ", gold_dist[i_T]);
        if(i_T%HIST_SIDE == 3) $fwrite(file_out, "\n");
    end
    $fwrite(file_out, "---------------------------------\n\n");

    //-------------------
    // Histogram info
    //-------------------
    $fwrite(file_out, "The wrong bin is marked with \"X\"\n\n");
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        $fwrite(file_out, "    Histogram #%-2d\n", i_T);
        if(mark_dist[i_T] == 1) $fwrite(file_out, "    Distance  #%-1d X\n", your_dist[i_T]);
        else                    $fwrite(file_out, "    Distance  #%-1d\n", your_dist[i_T]);
        $fwrite(file_out, "\n");
        for(j_T=0 ; j_T<BIN_NUM ; j_T=j_T+1) begin
            // Display index
            if((j_T%pixelperRow) == 0) begin
                for(k_T=j_T ;k_T<j_T+pixelperRow ; k_T=k_T+1) begin
                    if(k_T < BIN_NUM) begin
                        if(mark_hist[i_T][k_T] == 1) $fwrite(file_out, "X%-3d  ", k_T+1);
                        else                         $fwrite(file_out, "#%-3d  ", k_T+1);
                    end
                end
                $fwrite(file_out, "\n");
            end

            // Display bins
            $fwrite(file_out, "%3d   ", your_hist[i_T][j_T]);
            if(((j_T+1)%pixelperRow) == 0) begin
                $fwrite(file_out, "\n");
            end
        end
        $fwrite(file_out, "\n\n");
    end

    $fclose(file_out);
end endtask

endmodule

//pragma protect end
