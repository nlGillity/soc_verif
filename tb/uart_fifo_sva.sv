initial assume(
    !rstn_i && 
    !clr_i  &&
    !valid_i
);

//=========================================================================
// Up valid-ready
//=========================================================================

always_ff @(posedge clk_i)
    if (rstn_i && !clr_i)
        if ($past(valid_i && !ready_o && (rstn_i && !clr_i)))
            up_valid_stabillity_a : assume (valid_i);

//=========================================================================
// Down valid-ready
//=========================================================================

always_ff @(posedge clk_i)
    if (rstn_i && !clr_i)
        if ($past(valid_o && !ready_i && (rstn_i && !clr_i)))
            down_valid_stabillity_a : assert final (valid_o);

//=========================================================================
// Reset
//=========================================================================

always_ff @(posedge clk_i)
    if ($fell(rstn_i)) begin
        up_ready_reset_a   : assert final (ready_o);
        elements_reset_a   : assert final (elements_o == 0);  
        down_valid_reset_a : assert final (!valid_o);
    end

//=========================================================================
// FIFO Clear
//=========================================================================

always_ff @(posedge clk_i)
    if ($past(clr_i)) begin
        clear_a            : assert final (elements_o == '0);
        up_ready_clear_a   : assert final (ready_o);
        down_valid_clear_a : assert final (!valid_o);
    end

//=========================================================================
// FIFO elements
//=========================================================================

always_ff @(posedge clk_i)
    fixed_size_a: assert final (elements_o <= BUFFER_DEPTH);

//------------------------------------------------------------------------

always_ff @(posedge clk_i)
    if (rstn_i && !clr_i) begin
        if (elements_o == 0) begin
            empty_down_valid_a : assert final (!valid_o);
            empty_up_ready_a   : assert final (ready_o);
        end

        if (elements_o == BUFFER_DEPTH) begin
            full_down_valid_a : assert final (valid_o);
            full_up_ready_a   : assert final (!ready_o);
        end
    end

//------------------------------------------------------------------------

always_ff @(posedge clk_i)
    if (rstn_i && !clr_i) begin
        if ($past(rstn_i && !clr_i)) begin

            if ($past(!ready_i)) begin

                if ($past(valid_i))
                    if ($past(elements_o == BUFFER_DEPTH))
                        assert final ($stable(elements_o));
                    else if ($past(elements_o < BUFFER_DEPTH))
                        assert final (elements_o == $past(elements_o) + 1);
                else if ($past(!valid_i)) begin
                    assert final ($stable(elements_o));
                end

            end else if ($past(ready_i)) begin

                if ($past(!valid_o)) begin

                    if ($past(valid_i)) begin
                        if ($past(elements_o == BUFFER_DEPTH))
                            assert final ($stable(elements_o));
                        else if ($past(elements_o < BUFFER_DEPTH))
                            assert final (elements_o == $past(elements_o) + 1);
                    end else if ($past(!valid_i)) begin
                        assert final ($stable(elements_o));
                    end

                end else if ($past(valid_o)) begin

                    if ($past(!valid_i)) begin
                        if ($past(elements_o != 0))
                            assert final (elements_o == $past(elements_o) - 1);
                        else if ($past(elements_o > 0)) begin
                            assert final ($stable(elements_o));
                        end
                    end

                end

            end

        end
    end