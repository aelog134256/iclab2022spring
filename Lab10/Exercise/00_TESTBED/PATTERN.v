`define CYCLE_TIME 12

module PATTERN(
    // Output signals
    clk,
    rst_n,
    in_valid,
    in_data,
    op,
    // Output signals
    out_valid,
    out_data
);
//======================================
//          I/O PORTS
//======================================
output reg                   clk;
output reg                 rst_n;
output reg              in_valid;
output reg signed [6:0]  in_data;
output reg [3:0]              op;

input                  out_valid;
input signed [6:0]      out_data;

//======================================
//      PARAMETERS & VARIABLES
//======================================
parameter PATNUM = 5;
parameter CYCLE  = `CYCLE_TIME;
parameter DELAY  = 1000;
integer   SEED   = 5200122;

parameter IN_IMAGE_LEN  = 8;
parameter OP_NUM        = 15;
parameter WINDOW_LEN    = 2;
parameter OUT_IMAGE_LEN = 4;

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

//====================
//  Image
//====================
integer data_imag[0:IN_IMAGE_LEN-1][0:IN_IMAGE_LEN-1];
integer op_list  [0:OP_NUM-1];
integer gold_imag[0:OUT_IMAGE_LEN-1][0:OUT_IMAGE_LEN-1];

integer op_x, op_y;

integer op_idx;
integer done_flag;
integer zoom_flag;
// 0 is zoom in
// 1 is zoom out

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
        cal_task;
        wait_task;
        check_task;

        // Print Pass Info and accumulate the total latency
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
        tot_lat = tot_lat + exe_lat;
    end
    $finish;
    //pass_task;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task reset_task; begin

    tot_lat = 0;

    force clk  = 0;
    rst_n      = 1;
    in_valid   = 0;
    in_data    = 'dx;
    op         = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if (out_valid !== 0 || out_data !== 0) begin
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
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task input_task; begin
    repeat( ({$random(SEED)} % 4 + 2) ) @(negedge clk);
    //===========================
    //      Give Input
    //===========================
    // Invalid
    for(i=0 ; i<IN_IMAGE_LEN ; i=i+1) begin
        for(j=0 ; j<IN_IMAGE_LEN ; j=j+1) begin
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

            in_valid = 1;
            // op
            if((i*IN_IMAGE_LEN + j) < OP_NUM) op = {$random(SEED)} % 9;
            else                              op ='dx;
            // in_data
            in_data = $random(SEED) % 64;

            op_list[i*IN_IMAGE_LEN + j] = op;
            data_imag[i][j] = in_data;

            @(negedge clk);
        end
    end

    in_valid = 0;
    in_data  = 'dx;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task wait_task; begin
    exe_lat = -1;
    while (out_valid !== 1) begin
        if (out_data !== 0) begin
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
            $display("    is over %6d  cycles    `:::--:/++:----------::/:.                   ", DELAY);
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
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task check_task; begin
    out_lat = 0;
    i = 0;
    while (out_valid === 1) begin
        // Check output cycle
        if (out_lat == OUT_IMAGE_LEN*OUT_IMAGE_LEN) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than %-3d                  /s:-----+s`     at %-12d ps   ", OUT_IMAGE_LEN*OUT_IMAGE_LEN, $time*1000);
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
        // Check output
        if (i < OUT_IMAGE_LEN*OUT_IMAGE_LEN) begin
            if(out_data !== gold_imag[i/OUT_IMAGE_LEN][i%OUT_IMAGE_LEN]) begin
                $display("                                                                                ");
                $display("                                                   ./+oo+/.                     ");
                $display("    The out_data is not correct!!!                /s:-----+s`     at %-12d ps   ", $time*1000);
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
            
        end
        i=i+1;
        out_lat = out_lat + 1;
        @(negedge clk);
    end
    
    if (out_lat<OUT_IMAGE_LEN*OUT_IMAGE_LEN) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than %-2d                  /s:-----+s`     at %-12d ps   ", OUT_IMAGE_LEN*OUT_IMAGE_LEN, $time*1000);
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
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task cal_task; begin
    // Operation point reset (3, 3)
    op_x = 3;
    op_y = 3;
    // Do the operation
    done_flag = 0;
    for(op_idx=0 ; op_idx<OP_NUM ; op_idx=op_idx+1) begin
        if     (op_list[op_idx] == 0) mid_subtask;
        else if(op_list[op_idx] == 1) avg_subtask;
        else if(op_list[op_idx] == 2) count_clk_rot_subtask;
        else if(op_list[op_idx] == 3) clk_rot_subtask;
        else if(op_list[op_idx] == 4) flip_subtask;
        else if(op_list[op_idx] == 5) shift_up_subtask;
        else if(op_list[op_idx] == 6) shift_left_subtask;
        else if(op_list[op_idx] == 7) shift_down_subtask;
        else if(op_list[op_idx] == 8) shift_right_subtask;
        dump_subtask;
    end
    done_flag = 1;
    if(op_x < 4 && op_y < 4) begin
        zoom_in_subtask;
        zoom_flag = 0;
    end
    else begin 
        zoom_out_subtask;
        zoom_flag = 1;
    end
    dump_subtask;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task mid_subtask;
    integer pixel_list[0:WINDOW_LEN*WINDOW_LEN-1];
    integer swapped;
    integer temp;
begin
    // Sort the window of image pixel
    for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
        for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
            pixel_list[i*WINDOW_LEN+j] = data_imag[op_y+i][op_x+j];
        end
    end
    // for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
    //     for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
    //         $write("%d ", pixel_list[i*WINDOW_LEN+j]);
    //     end
    // end
    // $display("\n");
    for (i=0 ; i<WINDOW_LEN*WINDOW_LEN-1 ; i=i+1) begin
        swapped = 0;
        for (j = 0; j<(WINDOW_LEN*WINDOW_LEN-1-i); j=j+1) begin
            if (pixel_list[j] > pixel_list[j+1]) begin
                temp = pixel_list[j];
                pixel_list[j] = pixel_list[j+1];
                pixel_list[j+1] = temp;
                swapped = 1;
            end
        end
    end
    // for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
    //     for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
    //         $write("%d ", pixel_list[i*WINDOW_LEN+j]);
    //     end
    // end
    // $display("\n");
    // Give the midpoint to the image
    for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
        for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
            data_imag[op_y+i][op_x+j] = $floor((pixel_list[1]+pixel_list[2]) / 2);
        end
    end
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task avg_subtask;
    integer avg_sum;
begin
    // Calculate the average
    avg_sum = 0;
    for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
        for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
            avg_sum = avg_sum + data_imag[op_y+i][op_x+j];
        end
    end
    // Give the average to the image
    for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
        for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
            data_imag[op_y+i][op_x+j] = $floor((avg_sum) / (WINDOW_LEN*WINDOW_LEN));
        end
    end
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task count_clk_rot_subtask;
    integer temp;
begin
    temp                      = data_imag[op_y  ][op_x  ];
    data_imag[op_y  ][op_x  ] = data_imag[op_y  ][op_x+1];
    data_imag[op_y  ][op_x+1] = data_imag[op_y+1][op_x+1];
    data_imag[op_y+1][op_x+1] = data_imag[op_y+1][op_x  ];
    data_imag[op_y+1][op_x  ] = temp;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task clk_rot_subtask;
    integer temp;
begin
    temp                      = data_imag[op_y  ][op_x  ];
    data_imag[op_y  ][op_x  ] = data_imag[op_y+1][op_x  ];
    data_imag[op_y+1][op_x  ] = data_imag[op_y+1][op_x+1];
    data_imag[op_y+1][op_x+1] = data_imag[op_y  ][op_x+1];
    data_imag[op_y  ][op_x+1] = temp;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task flip_subtask; begin
    for(i=0 ; i<WINDOW_LEN ; i=i+1) begin
        for(j=0 ; j<WINDOW_LEN ; j=j+1) begin
            data_imag[op_y+i][op_x+j] = -data_imag[op_y+i][op_x+j];
        end
    end
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task shift_up_subtask; begin
    if(op_y > 0) op_y = op_y - 1;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task shift_left_subtask; begin
    if(op_x > 0) op_x = op_x - 1;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task shift_down_subtask; begin
    if(op_y < 6) op_y = op_y + 1;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task shift_right_subtask; begin
    if(op_x < 6) op_x = op_x + 1;
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task zoom_in_subtask; begin
    for(i=0 ; i<OUT_IMAGE_LEN ; i=i+1) begin
        for(j=0 ; j<OUT_IMAGE_LEN ; j=j+1) begin
            gold_imag[i][j] = data_imag[op_y+i+1][op_x+j+1];
        end
    end
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task zoom_out_subtask; begin
    for(i=0 ; i<OUT_IMAGE_LEN ; i=i+1) begin
        for(j=0 ; j<OUT_IMAGE_LEN ; j=j+1) begin
            gold_imag[i][j] = data_imag[i*2][j*2];
        end
    end
end endtask
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
task dump_subtask; begin
    if(op_idx == 0) begin
        file_out = $fopen("Lab10_debug.txt", "w");
        //-------------------------
        // OP Info
        //-------------------------
        $fwrite(file_out, "================================================================================================================\n");
        $fwrite(file_out, "OP idx  : ");
        for(i=0 ; i<OP_NUM ; i=i+1) $fwrite(file_out, "%-2d ", i);
        $fwrite(file_out, "\nOP list : ");
        for(i=0 ; i<OP_NUM ; i=i+1) $fwrite(file_out, "%-2d ", op_list[i]);
        // //-------------------------
        // // OP point
        // //-------------------------
        // $fwrite(file_out, "\n");
        // $fwrite(file_out, "OP X-coord  : %-2d \n", op_x);
        // $fwrite(file_out, "OP Y-coord  : %-2d \n", op_y);
        // $fwrite(file_out, "Window indx : ");
        //  for(i=0 ; i<WINDOW_LEN ; i=i+1)
        //     for(j=0 ; j<WINDOW_LEN ; j=j+1)
        //         $fwrite(file_out, "(%2d, %2d) ", op_x+j, op_y+i);
        // $fwrite(file_out, "\n");
        $fwrite(file_out, "\n================================================================================================================\n");
        $fclose(file_out);
    end
    if(done_flag == 0) begin
        //-------------------------
        // OP List
        //-------------------------
        file_out = $fopen("Lab10_debug.txt", "a");
        if     (op_list[op_idx] == 0) $fwrite(file_out, "OP #%-2d     : Midpoint\n", op_idx);
        else if(op_list[op_idx] == 1) $fwrite(file_out, "OP #%-2d     : Average\n", op_idx);
        else if(op_list[op_idx] == 2) $fwrite(file_out, "OP #%-2d     : Counterclockwise Rotation\n", op_idx);
        else if(op_list[op_idx] == 3) $fwrite(file_out, "OP #%-2d     : Clockwise Rotation\n", op_idx);
        else if(op_list[op_idx] == 4) $fwrite(file_out, "OP #%-2d     : Flip\n", op_idx);
        else if(op_list[op_idx] == 5) $fwrite(file_out, "OP #%-2d     : Shift Up\n", op_idx);
        else if(op_list[op_idx] == 6) $fwrite(file_out, "OP #%-2d     : Shift Left\n", op_idx);
        else if(op_list[op_idx] == 7) $fwrite(file_out, "OP #%-2d     : Shift Down\n", op_idx);
        else if(op_list[op_idx] == 8) $fwrite(file_out, "OP #%-2d     : Shift Right\n", op_idx);
        //-------------------------
        // OP point
        //-------------------------
        $fwrite(file_out, "OP X-coord : %-2d \n", op_x);
        $fwrite(file_out, "OP Y-coord : %-2d \n", op_y);
        $fwrite(file_out, "Window idx : ");
         for(i=0 ; i<WINDOW_LEN ; i=i+1)
            for(j=0 ; j<WINDOW_LEN ; j=j+1)
                $fwrite(file_out, "(%2d, %2d) ", op_x+j, op_y+i);
        $fwrite(file_out, "\n\n");
        //-------------------------
        // Data Image
        //-------------------------
        // Print row index
        $fwrite(file_out, "[%5d]",'dx);
        for(i=0 ; i<IN_IMAGE_LEN ; i=i+1)
            $fwrite(file_out, "[%5d]",i);
        $fwrite(file_out, "\n");

        for(i=0 ; i<IN_IMAGE_LEN ; i=i+1) begin
            // Print column index
            $fwrite(file_out, "[%5d]",i);
            // Print value
            for(j=0 ; j<IN_IMAGE_LEN ; j=j+1)
                $fwrite(file_out, " %5d ", data_imag[i][j]);
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n================================================================================================================\n");
        $fclose(file_out);
    end
    else begin
        //-------------------------
        // Zoom
        //-------------------------
        file_out = $fopen("Lab10_debug.txt", "a");
        if     (zoom_flag == 0) $fwrite(file_out, "Zoom-in\n");
        else if(zoom_flag == 1) $fwrite(file_out, "Zoom-out\n");
        $fwrite(file_out, "\n");
        //-------------------------
        // Golden Image
        //-------------------------
        // Print row index
        $fwrite(file_out, "[%5d]",'dx);
        for(i=0 ; i<OUT_IMAGE_LEN ; i=i+1)
            $fwrite(file_out, "[%5d]",i);
        $fwrite(file_out, "\n");

        for(i=0 ; i<OUT_IMAGE_LEN ; i=i+1) begin
            // Print column index
            $fwrite(file_out, "[%5d]",i);
            // Print value
            for(j=0 ; j<OUT_IMAGE_LEN ; j=j+1)
                $fwrite(file_out, " %5d ", gold_imag[i][j]);
            $fwrite(file_out, "\n");
        end
        $fwrite(file_out, "\n================================================================================================================\n");
        $fclose(file_out);
    end
end endtask
endmodule
