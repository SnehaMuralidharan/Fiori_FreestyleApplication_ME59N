  METHOD errormessages_get_entityset.

    DATA lt_eban TYPE tt_eban.
    CLEAR: et_entityset, lt_eban.
*-- Get the PR item details from the method m_get_eban_data
    me->m_get_error_from_spool( IMPORTING et_eban = lt_eban ).
    et_entityset = CORRESPONDING #( lt_eban ).

*-- Delete the duplicates in the PR message
    SORT et_entityset BY message.
    DELETE ADJACENT DUPLICATES FROM et_entityset COMPARING message.

*-- If filter value is set in the search of the F4 help then other values will be deleted
    IF iv_search_string IS NOT INITIAL.
      DELETE et_entityset WHERE message <> iv_search_string. "#EC CI_STDSEQ
    ENDIF.
  ENDMETHOD.
