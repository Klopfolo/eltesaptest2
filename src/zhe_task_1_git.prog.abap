*&---------------------------------------------------------------------*
*& Report zhe_task_1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zhe_task_1_git.

TABLES erpsls_billdoc.

TYPES: BEGIN OF ty_t_billdoc_extended.
         INCLUDE TYPE erpsls_billdoc.
TYPES:   kalsm      TYPE vbrk-kalsm,
         land1      TYPE vbrk-land1,
         regio      TYPE vbrk-regio,
         butxt      TYPE t001-butxt,
         adrnr      TYPE t001-adrnr,
         city1      TYPE adrc-city1,
         post_code1 TYPE adrc-post_code1,
         street     TYPE adrc-street.
TYPES: END OF ty_t_billdoc_extended.

DATA: lt_ext  TYPE STANDARD TABLE OF ty_t_billdoc_extended,
      lt_out  TYPE STANDARD TABLE OF erpsls_billdoc,
      lo_data TYPE REF TO data,
      lt_vbrk TYPE TABLE OF vbrk,
      lt_t001 TYPE TABLE OF t001,
      lt_adrc TYPE TABLE OF adrc,
      lo_salv TYPE REF TO cl_salv_table.

FIELD-SYMBOLS <fs_out> LIKE lt_out.

SELECT-OPTIONS: so_num   FOR erpsls_billdoc-vbeln,
                so_type  FOR erpsls_billdoc-fkart,
                so_datum FOR erpsls_billdoc-fkdat,
                so_org   FOR erpsls_billdoc-vkorg,
                so_chan  FOR erpsls_billdoc-vtweg.

PARAMETERS: p_open  AS CHECKBOX,
            p_books AS CHECKBOX.

cl_salv_bs_runtime_info=>set( display  = abap_false
                              metadata = abap_false
                              data     = abap_true ).

SUBMIT erpsls_billdoc_view
       WITH svbeln IN so_num
       WITH sfkart IN so_type
       WITH sfkdat IN so_datum
       WITH svkorg IN so_org
       WITH svtweg IN so_chan
       WITH popen    = p_open
       WITH pnotopen = p_books
       AND RETURN.

TRY.
    cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = lo_data ).
    ASSIGN lo_data->* TO <fs_out>.
    cl_salv_bs_runtime_info=>clear_all( ).

  CATCH cx_root.
ENDTRY.

cl_salv_bs_runtime_info=>set( display  = abap_true
                              metadata = abap_false
                              data     = abap_false ).

SELECT *
  FROM vbrk
  INTO TABLE lt_vbrk
  WHERE vbeln IN so_num.

SELECT *
  FROM t001
  INTO TABLE lt_t001
  FOR ALL ENTRIES IN lt_vbrk
  WHERE land1 = lt_vbrk-land1.

SELECT *
  FROM adrc
  INTO TABLE lt_adrc
  FOR ALL ENTRIES IN lt_t001
  WHERE addrnumber = lt_t001-adrnr.

MOVE-CORRESPONDING <fs_out> TO lt_ext.

LOOP AT lt_ext ASSIGNING FIELD-SYMBOL(<fs_ext>).

  LOOP AT lt_vbrk ASSIGNING FIELD-SYMBOL(<fs_vbrk>) WHERE vbeln = <fs_ext>-vbeln.
    <fs_ext>-kalsm = <fs_vbrk>-kalsm.
    <fs_ext>-land1 = <fs_vbrk>-land1.
    <fs_ext>-regio = <fs_vbrk>-regio.
  ENDLOOP.

  LOOP AT lt_t001 ASSIGNING FIELD-SYMBOL(<fs_t001>) WHERE land1 = <fs_ext>-land1.
    <fs_ext>-butxt = <fs_t001>-butxt.
    <fs_ext>-adrnr = <fs_t001>-adrnr.
  ENDLOOP.

  LOOP AT lt_adrc ASSIGNING FIELD-SYMBOL(<fs_adrc>) WHERE addrnumber = <fs_ext>-adrnr.
    <fs_ext>-city1      = <fs_adrc>-city1.
    <fs_ext>-post_code1 = <fs_adrc>-post_code1.
    <fs_ext>-street     = <fs_adrc>-street.
  ENDLOOP.

ENDLOOP.

TRY.
    cl_salv_table=>factory( IMPORTING r_salv_table = lo_salv
                            CHANGING  t_table      = lt_ext ).
  CATCH cx_root.
ENDTRY.

lo_salv->display( ).
