  METHOD M_GET_PR_ERROR_DATA_CNT.

    TYPES: BEGIN OF lty_eban,
             banfn TYPE banfn,
             bnfpo TYPE bnfpo,
             frgdt TYPE frgdt,
             matnr TYPE matnr,
             werks TYPE werks,
             flief TYPE flief,
             menge TYPE eban-menge,
             meins TYPE eban-meins,
             ekgrp TYPE ekgrp,
             dispo TYPE dispo,
             maktx TYPE maktx,
             name1 TYPE lfa1-name1,
             dsnam TYPE t024d-dsnam,
           END OF lty_eban.
    DATA: lt_matnr    TYPE /iwbep/t_cod_select_options,
          lt_prnumber TYPE /iwbep/t_cod_select_options,
          lt_pritem   TYPE /iwbep/t_cod_select_options,
          lt_plant    TYPE /iwbep/t_cod_select_options,
          lt_vendor   TYPE /iwbep/t_cod_select_options,
          lt_purchorg TYPE /iwbep/t_cod_select_options,
          lt_error    TYPE /iwbep/t_cod_select_options,
          lt_eban     TYPE SORTED TABLE OF lty_eban WITH NON-UNIQUE KEY banfn bnfpo.
*-- Get the PR item details from the method m_get_eban_data
    me->m_get_error_from_spool_cnt( IMPORTING et_eban = gt_eban ).
    IF gt_eban IS NOT INITIAL.
*-- Retrieve the Filter selection details from the UI application
      IF  it_filter_select_options IS NOT INITIAL.
        lt_matnr = VALUE #( it_filter_select_options[ property = gc_material ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_error = VALUE #( it_filter_select_options[ property = gc_error ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_vendor = VALUE #( it_filter_select_options[ property = gc_vendor ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_plant = VALUE #( it_filter_select_options[ property = gc_plant ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_purchorg = VALUE #( it_filter_select_options[ property = gc_purchgroup ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_prnumber = VALUE #( it_filter_select_options[ property = gc_prnumber ]-select_options OPTIONAL ). "#EC CI_STDSEQ
        lt_pritem = VALUE #( it_filter_select_options[ property = gc_pritem ]-select_options OPTIONAL ). "#EC CI_STDSEQ
*-- Delete the filter details from EBAN table
        DELETE gt_eban WHERE banfn NOT IN lt_prnumber OR bnfpo NOT IN lt_pritem OR message NOT IN lt_error. "#EC CI_SORTSEQ
      ENDIF.
      DATA(lt_pr) = gt_eban.
      DELETE ADJACENT DUPLICATES FROM lt_pr COMPARING banfn bnfpo.
*-- Based on the PR number and Item other details are captured
      IF lt_pr IS NOT INITIAL.
        SELECT eban~banfn,
               eban~bnfpo,
               eban~frgdt,
               eban~matnr,
               eban~werks,
               eban~flief,
               eban~menge,
               eban~meins,
               eban~ekgrp,
               eban~dispo,
               makt~maktx,
               lfa1~name1,
               t024d~dsnam
               FROM eban AS eban
               LEFT JOIN makt AS makt
               ON makt~matnr = eban~matnr
               AND makt~spras = @sy-langu
               LEFT JOIN lfa1 AS lfa1
               ON lfa1~lifnr = eban~flief
               LEFT JOIN t024d AS t024d
               ON t024d~werks = eban~werks
               AND t024d~dispo = eban~dispo
               INTO TABLE @lt_eban
               BYPASSING BUFFER
               FOR ALL ENTRIES IN @lt_pr
               WHERE eban~banfn = @lt_pr-banfn
               AND eban~bnfpo = @lt_pr-bnfpo
               AND eban~matnr IN @lt_matnr
               AND eban~werks IN @lt_plant
               AND eban~flief IN @lt_vendor
               AND eban~ekgrp IN @lt_purchorg.

        IF sy-subrc = 0.
          DELETE ADJACENT DUPLICATES FROM lt_eban COMPARING banfn bnfpo.
*-- Pass the final details to the exporting table
          et_eban = VALUE #(
                             FOR gs_eban IN gt_eban
                                     ( banfn = gs_eban-banfn
                                       bnfpo = gs_eban-bnfpo
                                       frgdt = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-frgdt OPTIONAL )
                                       matnr = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-matnr OPTIONAL )
                                       werks = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-werks OPTIONAL )
                                       flief = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-flief OPTIONAL )
                                       menge = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-menge OPTIONAL )
                                       meins = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-meins OPTIONAL )
                                       ekgrp = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-ekgrp OPTIONAL )
                                       dispo = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-dispo OPTIONAL )
                                       maktx = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-maktx OPTIONAL )
                                       name = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-name1 OPTIONAL )
                                       dsnam = VALUE #( lt_eban[ banfn = |{ gs_eban-banfn ALPHA = IN }|
                                                                 bnfpo = |{ gs_eban-bnfpo ALPHA = IN }| ]-dsnam OPTIONAL )
                                       message   = gs_eban-message
           ) ) ##WARN_OK.

        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR: lt_matnr, lt_prnumber, lt_pritem,lt_plant, lt_vendor,
    lt_purchorg, lt_error.
  ENDMETHOD.
