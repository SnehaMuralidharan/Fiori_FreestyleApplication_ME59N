  METHOD if_sadl_gw_query_control~set_query_options.

    DATA: lt_search_scope TYPE if_sadl_public_types=>tt_search_scope,
          ls_search_scope LIKE LINE OF lt_search_scope.
    CLEAR: lt_search_scope, ls_search_scope.
    CASE iv_entity_set.

      WHEN gc_plants.
        "Set basic search scope for plant
        ls_search_scope = gc_plantno.
        APPEND ls_search_scope TO lt_search_scope.

        "Set basic search scope for description
        ls_search_scope = gc_plantdesc.
        APPEND ls_search_scope TO lt_search_scope.

        io_query_options->set_text_search_scope( lt_search_scope ).
      WHEN gc_vendors.
        "Set basic search scope for vendor
        ls_search_scope = gc_vendorno.
        APPEND ls_search_scope TO lt_search_scope.

        "Set basic search scope for vendor description
        ls_search_scope = gc_vendordesc.
        APPEND ls_search_scope TO lt_search_scope.

        io_query_options->set_text_search_scope( lt_search_scope ).
      WHEN gc_materials.
        "Set basic search scope for material
        ls_search_scope = gc_materialno.
        APPEND ls_search_scope TO lt_search_scope.

        "Set basic search scope for material description
        ls_search_scope = gc_materialdesc.
        APPEND ls_search_scope TO lt_search_scope.

        io_query_options->set_text_search_scope( lt_search_scope ).
      WHEN gc_purchgroups.
        "Set basic search scope for purchase group
        ls_search_scope = gc_purchgroupno.
        APPEND ls_search_scope TO lt_search_scope.

        "Set basic search scope for purchase group description
        ls_search_scope = gc_purchgroupdesc.
        APPEND ls_search_scope TO lt_search_scope.

        io_query_options->set_text_search_scope( lt_search_scope ).
    ENDCASE.
  ENDMETHOD.
