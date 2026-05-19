class coverage_sub;

    bit transaction;
    mailbox #(bit) loopback;
    
    covergroup cg;
        coverpoint transaction {
            bins ;
        }
    endgroup

    function new();
        cg = new;
    endfunction

    virtual task run();
    endtask

endclass