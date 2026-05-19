import uvm_pkg::*;
`include "uvm_macros.svh"
`include "config_macros.svh"

virtual class base_monitor extends uvm_monitor;

    fifo_packet pkt;
    fifo_packet pkt_clone;

    virtual uart_fifo_if vif;

    uvm_analysis_port #(fifo_packet) item_collected_port;

    function new(string name = `BASE_MONITOR_NAME, uvm_component parent)
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
        pkt       = fifo_packet::type_id::creat("pkt");
        pkt_clone = fifo_packet::type_id::creat("pkt_clone");
    endfunction

    virtual task run_phase(uvm_phase phase);
        process job;
        forever begin
            wait(vif.rstn_i);
            fork
                forever begin
                    job = process.self();
                    collect();
                    send_collected();
                    @(posedge vif.clk_i);
                end
            join_none
            wait(!vif.rstn_i);
            job.kill();
        end
    endtask

    virtual task send_collected();
        $cast(pkt_clone, pkt.clone());
        item_collected_port.write(pkt_clone);
    endtask

    pure virtual task collect();

endclass


class master_monitor extends base_monitor;

    virtual task collect();
        wait(vif.valid_i && vif.ready_o);
        pkt.ready = vif.ready_o;
        pkt.valid = vif.valid_i;
        pkt.data  = vif.data_i;
    endtask

endclass