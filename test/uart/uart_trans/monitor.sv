class monitor;

    virtual apb_uart_if vif;
    mailbox#(bit) loopback_mbx;

    virtual task run();
        process job;
        forever begin
            wait(vif.rstn);
            fork
                forever begin
                    job = process.self();
                    run_routine();
                end
            join_none
            wait(!vif.rstn);
            job.kill();
            reset();
        end
    endtask

    virtual task run_routine();
        @(posedge vif.clk);
        loopback_mbx.put(vif.tx_o);
    endtask

    virtual task reset();
        bit tmp;
        while(loopback_mbx.try_get(tmp));
    endtask

endclass