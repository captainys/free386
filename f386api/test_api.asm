;******************************************************************************
;Free386 API�T���v��
;				'ABK project' all left reserved. This is 'PDS'
;******************************************************************************
;
;�@�@2001/03/05�@����J�n
;
;[TAB=8]

%include	"nasm_abk.h"	;NASM�p�w�b�_
%include	"macro.asm"	;�}�N��

code	segment para public 'CODE' use32
;******************************************************************************
;���R�[�h
;******************************************************************************
..start:
	mov	ebx,'F386'	;Free386 funciton?
	mov	 ah,30h		;�o�[�W�������擾
	int	21h

	cmp	edx,' ABK'	;Free386 ?
	jne	no_free386

	mov	ah,10h		;API �̏������ƃ��[�h
	int	9ch		;Free386 Funciton
	jc	fail

	;API �R�[��
	mov	ah,08h		;function �ԍ�
	int	9dh		;API�R�[��

	mov	ah,09h		;function �ԍ�
	int	9dh		;API�R�[��

	mov	ah,4ch
	int	21h


	align	4
no_free386:
	PRINT	no_free386_mes
	mov	ah,4ch
	int	21h


	align	4
fail:
	PRINT	fail_mes
	mov	ah,4ch
	int	21h

	align	4
no_free386_mes:
	db 	'Free386 �ł͂���܂���',13,10,'$'

	align	4
fail_mes:
	db 	'API�̃��[�h�Ɏ��s���܂���',13,10,'$'

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	end
