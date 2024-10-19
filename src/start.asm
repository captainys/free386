;******************************************************************************
; Free386 start
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"

extern	start

global	show_title
global	verbose
global	search_PATH386
global	search_PATH

global	reset_CRTC
global	check_MACHINE
global	desc_memory_map

global	pool_for_paging
global	call_buf_sizeKB
global	resv_real_memKB

global	user_cbuf_pages

;==============================================================================
seg16	text class=CODE align=16
;==============================================================================
	times	100h	db 0		;= ORG 100h
..start:
	jmp	near start

	;==================================================
	;Behavior definition variables (for patches)
	;==================================================
	align	4

	;[+04h byte]
show_title	db	_show_title		;show Free386's title
verbose		db	_verbose		;Performs verbose
search_PATH386	db	_search_PATH386		;find from PATH386 ENV
search_PATH	db	_search_PATH		;find from PATH    ENV

	;[+08h byte]
reset_CRTC	db	_reset_CRTC		;CRTC/VRAM clear setting
check_MACHINE	db	_check_MACHINE		;Auto detect machines type
desc_memory_map	db	_desc_memory_map	;Descending ext memory mapping
		db	0

	;[+0Ch byte]
pool_for_paging	db	_pool_for_paging	;Reserved for paging [page]
call_buf_sizeKB	db	_call_buf_sizeKB	;CALL buffer size [KB]
resv_real_memKB	dw	_resv_real_memKB	;Reserved DOS memory [KB]

	;[+10h byte]
user_cbuf_pages	db	_user_cbuf_pages	;call buffer for client EXP
		db	0
		db	0
		db	0

;==============================================================================
