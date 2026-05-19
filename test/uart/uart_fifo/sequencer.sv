import uvm_pkg::*;
`include "uvm_macros.svh"
`include "config_macros.svh"

class base_sequencer extends uvm_sequencer #(fifo_packet);

    `uvm_sequencer_utils(base_sequencer)

    function new(string name = `BASE_SEQUENCER_NAME, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass