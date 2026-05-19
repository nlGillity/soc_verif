import uvm_pkg::*;
`include "uvm_macros.svh"
`include "config_macros.svh"

virtual class fifo_packet #(
    parameter int unsigned DATA_WIDTH = 8
) extends uvm_sequence_item;

    // Data part
    //----------------------------------------------------------------------------------------

    typedef enum bit[1:0] { ZERO, POS, NEG          } data_kind_e;
    typedef enum bit[1:0] { SMALL, MEDIUM, BIG, MAX } value_kind_e;

    rand data_kind;
    rand value_kind;

    rand bit [DATA_WIDTH - 1:0] data;
    rand bit                    valid;
    rand bit                    ready;

    constraint data_kind_con {
        (data_kind == ZERO  ) -> data == 0;
        (data_kind == POS   ) -> data  > 0;
        (data_kind == NEG   ) -> data  < 0;
    }

    constraint value_kind_con {
        (value_kind == SMALL  ) -> data inside { [`MIN_SMALL_VALUE  : `MAX_SMALL_VALUE  ] };
        (value_kind == MEDIUM ) -> data inside { [`MIN_MEDIUM_VALUE : `MAX_MEDIUM_VALUE ] };
        (value_kind == BIG    ) -> data inside { [`MIN_BIG_VALUE    : `MAX_BIG_VALUE    ] };
        (value_kind == MAX    ) -> data == {DATA_WIDTH{1'b1}};
    }

    // Delay part
    //----------------------------------------------------------------------------------------

    typedef enum bit[1:0] { NONE, SHORT, MEDIUM, LARGE } delay_kind_e;

    rand delay_kind_e delay_kind;
    rand int unsigned delay;

    constraint delay_kind_con {
        (delay_kind == NONE  ) -> delay == 0;
        (delay_kind == SHORT ) -> delay inside { [`SHORT_MIN_DELAY  : `SHORT_MAX_DELAY ] };
        (delay_kind == MEDIUM) -> delay inside { [`MEDIUM_MIN_DELAY : `MEDIUM_MAX_DELAY] };
        (delay_kind == LARGE ) -> delay inside { [`LARGE_MIN_DELAY  : `LARGE_MAX_DELAY ] };
    }

    //==================================================================================================
    // UVM tasks/functions
    //==================================================================================================

    `uvm_object_param_utils_begin(fifo_packet#(DATA_WIDTH))
        `uvm_field_int(delay_kind, UVM_DEFAULT)
        `uvm_field_int(delay,      UVM_DEFAULT)
        `uvm_field_int(data_kind,  UVM_DEFAULT)
        `uvm_field_int(data,       UVM_DEFAULT)
        `uvm_field_int(valid,      UVM_DEFAULT)
        `uvm_field_int(ready,      UVM_DEFAULT)
    `uvm_object_param_utils_end

    function new(string name = `FIFO_PACKET_NAME);
        super.new(name);
    endfunction

endclass