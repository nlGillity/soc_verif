import uvm_pkg::*;
`include "uvm_macros.svh"
`include "config_macros.svh"

virtual class base_driver extends uvm_driver #(fifo_packet);

    fifo_packet pkt;
    virtual uart_fifo_if vif;

    `uvm_component_utils(base_driver)

    //==================================================================================================
    // Pure tasks
    //==================================================================================================

    pure virtual task drive();
    pure virtual task wait_response();
    pure virtual task delay();
    pure virtual task reset();

    //==================================================================================================
    // UVM tasks/functions
    //==================================================================================================

    function new(string name = `BASE_DRIVER_NAME, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if ( !uvm_config_db#(virtual uart_fifo_if)::get(this, "", `UART_FIFO_INTERFACE_NAME, vif) ) 
            `uvm_fatal("NOVIF", {
                "virtual interface must be set for: ", get_full_name(), ".vif"
            })
        `uvm_info(get_full_name(), "Build stage complete.", UVM_LOW);
    endfunction

    //--------------------------------------------------------------------------------------------------

    virtual task run_phase(uvm_phase phase);
        process job;
        forever begin
            wait(vif.rstn);
            fork
                forever begin
                    job = process.self();
                    drive_routine();
                end
            join_none
            wait(!vif.rstn);
            job.kill();
            reset();
        end
    endtask

    //==================================================================================================
    // Tasks
    //==================================================================================================
    
    virtual task drive_routine();
        seq_item_port.get_next_item(pkt);
        drive();
        wait_response();
        reset();
        seq_item_port.item_done(pkt);
        delay();
    endtask

endclass



class master_driver extends base_driver #(fifo_packet);

    `uvm_component_utils(master_driver)

    function new(string name = `MASTER_DRIVER_NAME, uvm_component parent);
        super.new(name, parent);
    endfunction

    //==================================================================================================
    // Implementations
    //==================================================================================================

    virtual task drive();
        vif.valid_i <= pkt.valid;
        vif.data_i  <= pkt.data;
    endtask

    virtual task wait_response();
        do @(posedge vif.clk_i);
        while (!vif.ready_o);
    endtask

    virtual task reset();
        vif.valid_i <= 1'b0;
        vif.data_i  <= '0;
    endtask

    virtual task delay();
        repeat (pkt.delay) @(posedge vif.clk_i);
    endtask

endclass



class slave_driver extends base_driver #(fifo_packet);

    `uvm_component_utils(slave_driver)

    function new(string name = `SLAVE_DRIVER_NAME, uvm_component parent);
        super.new(name, parent);
    endfunction

    //==================================================================================================
    // Implementations
    //==================================================================================================

    virtual task drive();
        vif.ready_i <= pkt.ready;
    endtask

    virtual task wait_response(); endtask

    virtual task reset();
        vif.ready_i <= 1'b0;
    endtask

    virtual task delay();
        repeat (pkt.delay) @(posedge vif.clk_i);
    endtask

endclass
