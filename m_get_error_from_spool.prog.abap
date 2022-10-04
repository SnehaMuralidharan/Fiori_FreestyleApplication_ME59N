  METHOD m_get_error_from_spool.

*-- The method is used only for sending values to the F4 help of entity set PR number
    " and PR line item
    TYPES: BEGIN OF lty_spool_list,
             txtline(255) TYPE c,
           END OF lty_spool_list,
           lty_bsart TYPE RANGE OF bsart,
           lty_ekorg TYPE RANGE OF ekorg,
           lty_ekgrp TYPE RANGE OF ekgrp.

    DATA: lt_buffer   TYPE TABLE OF lty_spool_list,
          lv_field1   TYPE char50 ##NEEDED,
          lv_field2   TYPE char50 ##NEEDED,
          lv_field3   TYPE char50 ##NEEDED,
          lv_field4   TYPE char50 ##NEEDED,
          lv_field5   TYPE char50 ##NEEDED,
          lv_field6   TYPE char50 ##NEEDED,
          lv_field7   TYPE char50 ##NEEDED,
          lv_banfn    TYPE banfn ##NEEDED,
          lv_bnfpo    TYPE bnfpo ##NEEDED,
          lv_msgty    TYPE char1 ##NEEDED,
          lv_message  TYPE char120 ##NEEDED,
          lv_field8   TYPE char50 ##NEEDED,
          lv_field9   TYPE char50 ##NEEDED,
          lt_message  TYPE  tt_eban,
          lt_hmessage TYPE  tt_eban,
          lr_ekorg    TYPE lty_ekorg,
          lr_bsart    TYPE lty_bsart,
          lv_flag     TYPE char1,
          lr_ekgrp    TYPE lty_ekgrp.
    CLEAR et_eban.
*-- Fetch the latest job created for ME59N transaction code
    SELECT CAST( listident AS INT4 )
           FROM tbtcp
           INTO @DATA(lv_listident)
           UP TO 1 ROWS
           WHERE progname = @gc_jobname
           AND listident NE @abap_false
           ORDER BY sdldate DESCENDING,
           sdltime DESCENDING.
    ENDSELECT.

*-- Fetch the purchase group based on the username
    SELECT t024~ekgrp
           FROM usr02 AS usr02
           INNER JOIN t024 AS t024
           ON t024~tel_extens = usr02~accnt
           BYPASSING BUFFER
           INTO TABLE @DATA(lt_ekgrp)
           WHERE bname = @sy-uname.
    lr_ekgrp = VALUE #( BASE lr_ekgrp FOR ls_ekgrp IN lt_ekgrp
                       ( sign = zif_global_constant=>gc_char_cap_i
                       option = zif_global_constant=>gc_char_cap_eq
                       low = ls_ekgrp-ekgrp ) ).

*-- Retrieve the spool report from based on the spool number and store in the buffer table

    CALL FUNCTION 'RSPO_RETURN_ABAP_SPOOLJOB'
      EXPORTING
        rqident              = lv_listident
      TABLES
        buffer               = lt_buffer
      EXCEPTIONS
        no_such_job          = 1
        not_abap_list        = 2
        job_contains_no_data = 3
        selection_empty      = 4
        no_permission        = 5
        can_not_access       = 6
        read_error           = 7
        OTHERS               = 8.
    IF sy-subrc = 0.
*-- Capture the PR Document type, purchase org
*-- details from the control table for Validation
      zget_hcode zif_global_constant=>gc_2ces
                 zif_pur_global_constants_03=>gc_reqid_e5284
                 zif_pur_global_constants_03=>gc_uom_e5729:
                 zif_pur_global_constants_03=>gc_pur_org_e5729 0 abap_true lr_ekorg,
                 zif_pur_global_constants_03=>gc_pr_doc_typ_e5729 0 abap_true lr_bsart.
* Implement suitable error handling here
      LOOP AT lt_buffer ASSIGNING FIELD-SYMBOL(<lfs_buffer>).
        CLEAR: lv_field1, lv_field2, lv_field3, lv_field4,
        lv_field5, lv_field6, lv_field7, lv_field8, lv_field9,
        lv_msgty, lv_message, lv_banfn.
*-- Split the list report to get the PR number and line item details
        SPLIT <lfs_buffer>-txtline  AT gc_split INTO lv_field1 lv_field2
        lv_field3 lv_field4 lv_field5 lv_field6 lv_field7
        lv_banfn lv_bnfpo lv_field9 lv_msgty lv_message lv_field8.

*-- Validate the purchase org, purchase group and PR document type
*lv_field3 is PR doc type , lv_field4 is purchase org and lv_field 5 is purchase group
        IF lv_field3 IS NOT INITIAL AND lv_field4 IS NOT INITIAL
          AND lv_field5 IS NOT INITIAL.
*-- Validating the fields as during each spool page break in the spool
          " Check if the field lv_field3 PR doc type contain the actual value or the header description
          IF lv_field3 NP gc_prtype.
*-- Check if the PR doc type, purchase group and Purchase org is available in the maintained controls table
            IF ( lv_field3 IN lr_bsart AND lr_bsart IS NOT INITIAL ) AND ( lv_field4 IN lr_ekorg AND lr_ekorg IS NOT INITIAL )
              AND ( lv_field5 IN lr_ekgrp ).
*-- If maintained set the purchase check flag to 'X'.
              DATA(lv_pur_check) = zif_global_constant=>gc_char_cap_x.
            ELSE.
*-- Else clear the flag
              CLEAR lv_pur_check.
            ENDIF.
          ENDIF.
        ENDIF.
*-- If the PR number has errors those details are captured in the internal table
*-- Check if the Purchase check is set to 'X'
        IF lv_pur_check = zif_global_constant=>gc_char_cap_x.
*-- If the PR number is initial then only capture those error messages
          IF  lv_banfn IS INITIAL.
*-- Check the business object lv_field9 has value DocHeader*
            " get header error message
            IF lv_field9 CP gc_doc_head AND ( lv_msgty = zif_pur_global_constants_03=>gc_error
              OR lv_msgty = zif_pur_global_constants_03=>zif_global_constant~gc_char_cap_w ).
              lt_hmessage = VALUE #( BASE lt_message ( msgtyp = lv_msgty message = lv_message ) ).
            ENDIF.
*-- Check of the business Object lv_field9 has value Item*, if the lv_field9 has item* then
            " lv_flag is set 'X'
            IF lv_field9 CP gc_item.
              lv_flag = zif_global_constant=>gc_char_cap_x.
            ENDIF.
*-- If the lv_flag is set as 'X'
            IF lv_flag = zif_global_constant=>gc_char_cap_x AND ( lv_msgty = zif_pur_global_constants_03=>gc_error
              OR lv_msgty = zif_pur_global_constants_03=>zif_global_constant~gc_char_cap_w ).
*-- To avoid Header data error to be included in the message during page break of the spool
*-- Lv_field9 - Business Object and lv_field2 is PO header details
              IF lv_field9 NP gc_doc_head AND lv_field9 NP gc_pr AND lv_field2 IS INITIAL.
*-- if the lv_field9 does not contain DocHeader or Purchase and the PO number is initial is empty
*-- then the message will be captured
                lt_message = VALUE #( BASE lt_message ( msgtyp = lv_msgty message = lv_message ) ).
              ENDIF.
            ENDIF.
          ENDIF.
*-- If the PR number, PR line item is filled then those data is captured in the table GT_EBAN
          IF lv_banfn IS NOT INITIAL AND lv_msgty = zif_pur_global_constants_03=>gc_error.
*-- If the lt_hmessage is filled then fill the table with PR number but not the line item
            IF lt_hmessage IS NOT INITIAL.
              gt_eban = VALUE #( BASE gt_eban FOR ls_hmessage IN lt_hmessage
              ( banfn = |{ lv_banfn ALPHA = IN }|  msgtyp = ls_hmessage-msgtyp message = ls_hmessage-message ) ).
              CLEAR: lt_hmessage.
            ENDIF.
*-- If the lt_message table is empty but the PR number filled is with error then capture the error that is
            " available in the PR line item.
            IF lt_message IS INITIAL.
*              gt_eban = VALUE #( BASE gt_eban
*                     ( banfn = |{ lv_banfn ALPHA = IN }|  bnfpo = |{ lv_bnfpo ALPHA = IN }| msgtyp = lv_msgty
*                     message = lv_message ) ).
            ELSE.
*-- If the lt_message is not initial then capture those messages along with PR number and PR line item
              DELETE ADJACENT DUPLICATES FROM lt_message COMPARING message.
              gt_eban = VALUE #( BASE gt_eban FOR ls_message IN lt_message
              ( banfn = |{ lv_banfn ALPHA = IN }|  bnfpo = |{ lv_bnfpo ALPHA = IN }| msgtyp = ls_message-msgtyp
              message = ls_message-message ) ).
              CLEAR: lt_message, lv_flag.
            ENDIF.
          ELSEIF lv_banfn IS NOT INITIAL AND lv_msgty = zif_pur_global_constants_03=>zif_global_constant~gc_char_cap_s.
            CLEAR: lt_message, lt_hmessage, lv_flag.
          ENDIF.
        ENDIF.
        CLEAR <lfs_buffer>.
      ENDLOOP.
    ENDIF.
    et_eban = gt_eban.
    CLEAR: lv_listident, lt_buffer.
  ENDMETHOD.
