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
    window,
    mode,
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

//======================================
//      I/O PORTS
//======================================

// << CHIP io port with system >>
output reg              clk, rst_n;
output reg              in_valid;
output reg              start;
output reg [15:0]       stop;
output reg [1:0]        window;
output reg              mode;
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


//================================
//      DRAM Connection
//================================

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

    // initialize DRAM: $readmemh("../00_TESTBED/dram.dat", u_DRAM.DRAM_r);
    // direct access DRAM: u_DRAM.DRAM_r[addr][7:0];
    
//================================
//      PARAMETERS & VARIABLES
//================================
//----------------------------------------------------
// You can modify parameter here

// Frequency of one stop : NUMER_STOP / DENOM_STOP
parameter NUMER_STOP   = 1;
parameter DENOM_STOP   = 10;

// For pat < 100
// start : 4 ~ START_SIMPLE
parameter START_SIMPLE = 4;

// Random Seed
integer   SEED         = 5200122;

// Display control
// You can decide how many rows will be display in Midter_Debug.txt
parameter pixelperRow  = 30; 

// How many pattern
parameter PATNUM       = 10;
//----------------------------------------------------

//pragma protect
//pragma protect begin

parameter CYCLE        = `CYCLE_TIME;
parameter DELAY        = 1000000;

// Number of bins
parameter BIN_SIZE     = 255;
parameter HIST_NUM     = 16;
parameter FRAME_OFFSET = 'h10000;
parameter FRAME_SHIFT  = 'h01000;
parameter HIST_SHIFT   = 'h00100;

integer        i;
integer        j;
integer        m;
integer        n;
integer        k;
integer      pat;
integer  exe_lat;
integer  out_lat;
integer  tot_lat;

integer file_out;

//---------------------------
// Frame Data and Operation
//---------------------------
//====================
//  Data Input
//====================
integer window_in;
integer mode_in;
integer fram_id_in;

integer start_num;

//====================
//  Frame Pixel
//====================
reg[7:0] gold_hist[0:HIST_NUM-1][0:BIN_SIZE-1];
reg[7:0] gold_dist[0:HIST_NUM-1];

reg[7:0] your_hist[0:HIST_NUM-1][0:BIN_SIZE-1];
reg[7:0] your_dist[0:HIST_NUM-1];

reg[7:0] mark_hist[0:HIST_NUM-1][0:BIN_SIZE-1];
reg[7:0] mark_dist[0:HIST_NUM-1];
integer mark_flag;

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
    reset_task;
    for (pat=0 ; pat<PATNUM ; pat=pat+1) begin
        input_task;
        wait_task;
        check_task;

        // Print Pass Info and accumulate the total latency
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
        tot_lat = tot_lat + exe_lat;
    end
    pass_task;
end endtask

task reset_task; begin
    force clk = 0;
    rst_n     = 1;
    in_valid  = 0;
    start     = 'dx;
    stop      = 'dx;
    window    = 'dx;
    mode      = 'dx;
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
end endtask

task input_task; begin
    repeat( ({$random(SEED)} % 8 + 3) ) @(negedge clk);
    mode_in    = {$random(SEED)}%2;
    window_in  = {$random(SEED)}%4;
    fram_id_in = {$random(SEED)}%32;

    preprocessFrame_task(mode_in, fram_id_in);

    if(mode_in == 0) begin
        in_valid = 1;
        mode     = mode_in;
        window   = window_in;
        frame_id = fram_id_in;

        start    = 0;
        stop     = 0;

        @(negedge clk);

        mode     = 'dx;
        window   = 'dx;
        frame_id = 'dx;

        if(pat < 100) start_num = {$random(SEED)}%(START_SIMPLE-3) + 4;
        else          start_num = {$random(SEED)}%252 + 4;

        // Repeat how many times of start
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
            for(j=0 ; j<BIN_SIZE ; j=j+1) begin
                // Start
                start = 1;
                // Decide how many histogram to be set one in each frame
                for(k=0 ; k<HIST_NUM ; k=k+1) begin
                    // Probability : NUMER_STOP / DENOM_STOP
                    if(({$random(SEED)} % DENOM_STOP) < NUMER_STOP) begin
                        stop[k] = 1;
                    end
                    else begin
                        stop[k] = 0;
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
    else begin
        in_valid = 1;
        mode     = mode_in;
        window   = window_in;
        frame_id = fram_id_in;
        @(negedge clk);

        in_valid = 0;
        mode     = 'dx;
        window   = 'dx;
        frame_id = 'dx;
    end

    // Calculate the distance
    calDistFrame_task;
    // Dump Debug Info
    dumpGoldenFrame_task;
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
        mark_dist[i]    = 0;
        for(j=0 ; j<BIN_SIZE ; j=j+1) begin
            mark_hist[i][j] = 0;
        end
    end

    // Load the fram from DRAM
    loadyourFrame_task(fram_id_in);

    // Compare the frame of DRAM with the golden frame
    for(i=0 ; i<HIST_NUM ; i=i+1) begin
        if(your_dist[i] !== gold_dist[i]) begin
            mark_dist[i] = 1;
            mark_flag    = 1;
        end
        for(j=0 ; j<BIN_SIZE ; j=j+1) begin
            if(your_hist[i][j] !== gold_hist[i][j]) begin
                mark_hist[i][j] = 1;
                mark_flag       = 1;
            end
        end
    end
    dumpYourFrame_task;

    if(mark_flag === 1) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
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
integer maxSum[0:HIST_NUM-1];

// Load frame from DRAM
task loadyourFrame_task;
    input integer id_T;
begin
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        your_dist[i_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + BIN_SIZE];
        for(j_T=0 ; j_T<BIN_SIZE+1 ; j_T=j_T+1) begin
            your_hist[i_T][j_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + j_T];
        end
    end


end endtask

// 1. Load frame from DRAM
// 2. Calculate the distance
task preprocessFrame_task;
    input integer mode_T;
    input integer id_T;
begin
    // Mode = 0
    // Use stop to set the histogram
    if(mode_T == 0) begin
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
            for(j_T=0 ; j_T<BIN_SIZE ; j_T=j_T+1) begin
                gold_hist[i_T][j_T] = 0;
            end
        end
    end
    // Mode = 1
    // 
    else begin
        //$display("%h", id_T*FRAME_SHIFT+FRAME_OFFSET);
        //$display("%h", (id_T+1)*FRAME_SHIFT+FRAME_OFFSET);
        //$display("%h", (HIST_NUM-1)*HIST_SHIFT);
        //$display("%h", BIN_SIZE-1);
        for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
            for(j_T=0 ; j_T<BIN_SIZE ; j_T=j_T+1) begin
                gold_hist[i_T][j_T] = u_DRAM.DRAM_r[FRAME_OFFSET + id_T*FRAME_SHIFT + i_T*HIST_SHIFT + j_T];
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

task calDistFrame_task; begin

    windowSize = 2**window_in;

    // Each Historgram
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        for(j_T=0 ; j_T<(BIN_SIZE-windowSize+1) ; j_T=j_T+1) begin
            // Reset the distance and max window
            if(j_T == 0) begin
                maxSum[i_T] = 0;
                for(k_T=0 ; k_T<windowSize ; k_T=k_T+1) begin
                    maxSum[i_T] = maxSum[i_T] + gold_hist[i_T][k_T];
                end
                gold_dist[i_T] = 0;
            end

            // Calculate the sum of each window
            windowSum = 0;
            for(k_T=0 ; k_T<windowSize ; k_T=k_T+1) begin
                windowSum = windowSum + gold_hist[i_T][j_T+k_T];
            end

            // Compare each window to get the max window and distance
            if(windowSum > maxSum[i_T]) begin
                gold_dist[i_T] = j_T+1;
                maxSum[i_T] = windowSum;
            end
        end
    end
end endtask

task dumpGoldenFrame_task; begin
    file_out = $fopen("Midterm_Golden.txt", "w");

    $fwrite(file_out, "Start to debug for midterm project!!!\n\n");
    $fwrite(file_out, "Golden Frame!!!\n\n");

    //---------------
    // Input info
    //---------------
    $fwrite(file_out, "---------------------------------\n");
    $fwrite(file_out, "[INFO] Mode       : %-2d\n", mode_in);
    $fwrite(file_out, "[INFO] Window     : %-2d, size : %-1d\n", window_in, windowSize);
    $fwrite(file_out, "[INFO] Frame id   : %-2d\n\n", fram_id_in);
    
    $fwrite(file_out, "[INFO] DRAM Start : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET);
    $fwrite(file_out, "[INFO] DRAM End   : 0x%h\n\n", (fram_id_in+1)*FRAME_SHIFT+FRAME_OFFSET-1);
    
    $fwrite(file_out, "[INFO] Hist 0     : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET+0*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Hist %-2d    : 0x%h\n", (HIST_NUM-1), fram_id_in*FRAME_SHIFT+FRAME_OFFSET+(HIST_NUM-1)*HIST_SHIFT);
    $fwrite(file_out, "---------------------------------\n\n\n\n");

    //-------------------
    // Histogram info
    //-------------------
    for(i_T=0 ; i_T<HIST_NUM ; i_T=i_T+1) begin
        $fwrite(file_out, "    Histogram #%-2d\n", i_T);
        $fwrite(file_out, "    Distance  #%-1d\n", gold_dist[i_T]);
        $fwrite(file_out, "    Max Sum    %-d\n", maxSum[i_T]);
        for(j_T=0 ; j_T<BIN_SIZE ; j_T=j_T+1) begin
            // Display index
            if((j_T%pixelperRow) == 0) begin
                for(k_T=j_T ;k_T<j_T+pixelperRow ; k_T=k_T+1) begin
                    if(k_T < BIN_SIZE) $fwrite(file_out, "#%-3d  ", k_T+1);
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

    $fwrite(file_out, "Start to debug for midterm project!!!\n\n");
    $fwrite(file_out, "Your Frame!!!\n\n");

    //---------------
    // Input info
    //---------------
    $fwrite(file_out, "---------------------------------\n");
    $fwrite(file_out, "[INFO] Mode       : %-2d\n", mode_in);
    $fwrite(file_out, "[INFO] Window     : %-2d, size : %-1d\n", window_in, windowSize);
    $fwrite(file_out, "[INFO] Frame id   : %-2d\n\n", fram_id_in);
    
    $fwrite(file_out, "[INFO] DRAM Start : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET);
    $fwrite(file_out, "[INFO] DRAM End   : 0x%h\n\n", (fram_id_in+1)*FRAME_SHIFT+FRAME_OFFSET-1);
    
    $fwrite(file_out, "[INFO] Hist 0     : 0x%h\n", fram_id_in*FRAME_SHIFT+FRAME_OFFSET+0*HIST_SHIFT);
    $fwrite(file_out, "[INFO] Hist %-2d    : 0x%h\n", (HIST_NUM-1), fram_id_in*FRAME_SHIFT+FRAME_OFFSET+(HIST_NUM-1)*HIST_SHIFT);
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
        for(j_T=0 ; j_T<BIN_SIZE ; j_T=j_T+1) begin
            // Display index
            if((j_T%pixelperRow) == 0) begin
                for(k_T=j_T ;k_T<j_T+pixelperRow ; k_T=k_T+1) begin
                    if(k_T < BIN_SIZE) begin
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
