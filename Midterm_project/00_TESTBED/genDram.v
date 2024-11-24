module GEN_DRAM ();

//================================
//      PARAMETERS & VARIABLES
//================================
//----------------------------------------------------
// You can modify parameter here
// Mode Control
// Default mode
// Uniform distribution
parameter MODE         = 1; // two mode 0, 1
// Mode 0
parameter NUMER_STOP   = 1;
parameter DENOM_STOP   = 10;
// Mode 1
parameter MAX_MODE1    = 256;
parameter MIN_MODE1    = 1;

// Random Seed
integer   SEED         = 5200122;
//----------------------------------------------------

parameter BIN_SIZE     = 8;
parameter BIN_NUM      = 255;
parameter HIST_NUM     = 16;
parameter FRAME_NUM    = 32;
parameter FRAME_OFFSET = 'h10000;
parameter FRAME_SHIFT  = 'h01000;
parameter HIST_SHIFT   = 'h00100;

reg[7:0]       data;
integer  slopeMode1;
integer    valMode1;

integer   idx_frame;
integer    idx_hist;
integer     idx_bin;
integer           i;
integer        file;

initial begin

    // File open
    file = $fopen("../00_TESTBED/dram.dat","w");

    $display("======================================");
    $display("[INFO] Start to randomize the dram.dat");
    $display("[INFO] Your mode is : %-d", MODE);
    $display("======================================");

    for(idx_frame=0 ; idx_frame<FRAME_NUM ; idx_frame=idx_frame+1) begin
        for(idx_hist=0 ; idx_hist<HIST_NUM ; idx_hist=idx_hist+1) begin
            for(idx_bin=0 ; idx_bin<BIN_NUM ; idx_bin=idx_bin+1) begin

                // Write address
                if(idx_bin%4 == 0) $fwrite(file, "@%5h\n", FRAME_OFFSET+FRAME_SHIFT*idx_frame+HIST_SHIFT*idx_hist+idx_bin);

                // Write data
                data = 'dx;
                if(MODE == 1) begin
                    if(idx_bin < (BIN_NUM)/2) begin
                        slopeMode1 = 2*(MAX_MODE1-MIN_MODE1)/(BIN_NUM);
                        valMode1 = MIN_MODE1 + idx_bin * slopeMode1;
                    end
                    else begin
                        slopeMode1 = -2*(MAX_MODE1-MIN_MODE1)/(BIN_NUM);
                        valMode1 = MAX_MODE1 + (idx_bin-(BIN_NUM)/2) * slopeMode1;
                    end
                    data = {$random(SEED)} % valMode1;
                end
                else begin
                    for(i=0 ; i<BIN_SIZE ; i=i+1) begin
                        if(({$random(SEED)} % DENOM_STOP) < NUMER_STOP) data[i] = 1;
                        else                                            data[i] = 0;
                    end
                end

                $fwrite(file, "%h", data);
                if(idx_bin%4 == 3) $fwrite(file, "\n");
                else               $fwrite(file, " ");
            end

            // Write zero distance
            $fwrite(file, "00\n");
        end
    end
    $fclose(file);
end

endmodule

