;******************************************************************************
;�@�e�������R�W�U�@���v���O�����擪��
;******************************************************************************
;[TAB=8]
;
%include	"f386def.inc"		;�萔���̑}��

extern	start

global	show_TITLE, verbose
global	search_PATH386, search_PATH
global	reset_CRTC, check_MACHINE
global	pool_for_paging
global	callbuf_sizeKB
global	real_mem_pages
global	maximum_heap

;----------------------------------------------------------------------------
segment	text align=16 class=CODE use16
;-----------------------------------------------------------------------------
	times	100h	db 0		;ORG 100h �̑���
..start:
	jmp	start

	;==================================================
	;�����`�ϐ� (�p�b�`�p)
	;==================================================
	align	4

	;[+04 byte]
show_TITLE	db	_show_TITLE	;Free386 �^�C�g���\��
verbose		db	_Verbose	;�璷�ȕ\�����[�h
search_PATH386	db	_search_PATH386	;���ϐ� PATH386 �̌���
search_PATH	db	_search_PATH	;���ϐ� PATH �̌���

	;[+08 byte]
reset_CRTC	db	_reset_CRTC	;CRTC �̃��Z�b�g�ݒ�
check_MACHINE	db	_check_MACHINE	;�ȈՋ@�픻��
		db	0
		db	0
	;[+12 byte]
pool_for_paging	db	_POOL_for_paging;�y�[�W���O�p�̗\�񃁃���
callbuf_sizeKB	db	_CALLBUF_sizeKB	;CALL buffer size (KB)
real_mem_pages	db	_REAL_mem_pages	;�v���O�������s�p���A��������
maximum_heap	db	0		;�w�b�_�𖳎����čő�q�[�v�����������蓖��

	;--------------------------------------------------

	align	16
	;==================================================
	;�f�B�o�O�̂��߂̗̈�
	;==================================================
	;resb	2000h - 17a0h		;for DEBUG


;-----------------------------------------------------------------------------
