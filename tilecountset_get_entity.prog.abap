  METHOD tilecountset_get_entity.

* Description   : The method used for displaying the error cound in the dynamic tile

    DATA : lt_eban  TYPE zcl_zpur_prerr_disp_mpc=>tt_purchaserequisition,
           lv_count TYPE c LENGTH 40,
           lv_color TYPE char10.

    CLEAR: er_entity, lt_eban.

*-- Get the PR error details from the background job and pass those details lt_eban table
    me->m_get_pr_error_data_cnt( IMPORTING et_eban = lt_eban ).

    lv_count = lines( lt_eban ).

*-- Add Color to the count
    IF lv_count EQ 0.
      lv_color = TEXT-001.
    ELSE.
      lv_color = TEXT-002.
    ENDIF.


    er_entity = VALUE #(

                          number = lv_count
                          infostate = TEXT-003
                          numberdigits = TEXT-006
                          numberstate = lv_color
                          subtitle = TEXT-005
                          title =  TEXT-004             ).


  ENDMETHOD.
