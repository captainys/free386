;------------------------------------------------------------------------------
;COM ̧�ٍ쐬�ׂ̈̃T�u���[�`���Q
;
;	This is PDS.
;	made by nabe@abk  1998/03/31
;------------------------------------------------------------------------------
;NASM �p�ɈڐA�B
;
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"
%include	"f386sub.inc"

segment	text align=16 class=CODE use16
;##############################################################################
;���T�u���[�`�� (16 bit)
;##############################################################################
;------------------------------------------------------------------------------
;���p�����[�^�[���
;------------------------------------------------------------------------------
;
	global	get_parameter

max_paras	equ	20h	;�ő�p�����[�^�[��

	align	2
get_parameter:
	push	ax
	push	bx
	push	dx
	push	si


	mov	bx,081h	-1	;�R�}���h���C���p�����^��A�h���X -1
	mov 	dl,0		;�����񒆂��̃t���O�Ɏg�p�@�ŏ��� off ��
				;  1:������  0:�����񒆂łȂ�
	mov	si,offset paras_p	;�e�p�����^�ւ̃|�C���^�L�^�p�z�񃍁[�h

	align	2
.loop:
	inc	bx		;bx �X�e�b�v
	mov	al,[bx]		;�p�����^���[�h

	cmp	al,' '  	;SPACE
	jz	.kugiri		;��؂蔭��
	cmp	al,'	'	;TAB
	jz	.kugiri		;��؂蔭��

	cmp	al,0dh		;�p�����[�^�[�I���R�[�h
	jz	.exit		;�p�����[�^�[�̏I���(���[�v�E�o)

	;
	;������
	;
	cmp	dl,0			;�����񒆃t���O���[�h
	jne	.loop			; 0�łȂ���Ε����񒆂Ȃ̂ł��̂܂�ٰ��

	;
	;�V�K�����񔭌�
	;
	mov	[si],bx			;�p�����^������̃|�C���^�L�^
	mov	dl,01			;������ flag-on
	add	si,2			;�z����A�h���X�X�e�b�v
	inc	b [paras]		;���݂̃p�����[�^�� +1
	cmp	b [paras],max_paras	;���݂̃p�����[�^�[�� �� ��͍ő�l��r
	je	.exit			;��̓��[�v�E�o

	jmp	.loop			;���[�v


	align	2
.kugiri:
	mov	byte [bx],0		;null ��
	mov 	dl,0			;�����񒆂��̃t���O�� off ��
	jmp	short .loop		;���[�v



	align	2
	;�p�����[�^�[�P������̓��[�v�E�o
.exit:
	mov	byte [bx],00h		;0 �ɏ�����
	mov	[paras_last],bx		;�����Ƃ��ċL�^

	pop	si
	pop	dx
	pop	bx
	pop	ax
	ret

;------------------------------------------------------------------------------
;���g���������i���ւ̕ϊ�
;------------------------------------------------------------------------------
;
;	in	ds:di	�c��͂��镶����inull �ŏI���j
;	ret	ax	�c���ʂ̐��l
;		Cy=1	�c�G���[
;
;
	global	hex_to_bin

	align	2
hex_to_bin:
	push	bx
	push	si
	push	di

	xor	ax,ax
	xor	bx,bx
	mov	si,offset h2b	;���l�ϊ��e�[�u�����[�h

	align	2
hex_to_bin_loop:
	mov	bl,[di]
	inc	di

	cmp	bl,0		;null �Ɣ�r
	je	h2b_end		;���[�`���I��

	;
	;�wh�x�͖�������
	;
	cmp	bl,'H'
	je	hex_to_bin_loop
	cmp	bl,'h'
	je	hex_to_bin_loop

	cmp	bl,'0'		;�R�[�h30h �Ɣ�r
	jb	h2b_error	;�����菬������΃G���[(=jmp)
	cmp	bl,'f'		;�R�[�h66h �Ɣ�r
	ja	h2b_error	;������傫����΃G���[(=jmp)

	;
	;�e�[�u������
	;
	sub	bl,30h		;30h �������i�e�[�u�������p�j
	mov	bl,[bx+si]	;�e�[�u���̒l�����[�h
	cmp	bl,0ffh		;-1 �Ɣ�r
	je	h2b_error	;�������ƃG���[

	;
	;���l���Z
	;
	shl	ax,4		;����ڼ޽� 4 �ޯļ�āi�~4�j
	add	ax,bx		;�e�[�u���̒l�𑫂�

	jmp	hex_to_bin_loop	;���[�v


	align	2
h2b_error:
	pop	di
	pop	si
	pop	bx
	stc		;�L�����[�Z�b�g(�G���[)
	ret


	align	2
h2b_end:
	pop	di
	pop	si
	pop	bx
	clc		;�L�����[�N���A(����I��)
	ret



	align	2
;------------------------------------------------------------------------------
;�����l���g�����ϊ��i�S�P�^�Œ�j
;------------------------------------------------------------------------------
;
;	dx ��16�i���ŁA[si] �ɋL�^����
;	si �� ret �� +4�����B
;
	global	HEX_conv4
HEX_conv4:
	push	ax
	push	bx
	push	dx
	push	di
	mov	di,offset hex_str	;16�i��������
	xor	bx,bx

	;�P�����ڋL�^
	mov	bl,dh
	and	bl,0f0h
	shr	bx,4
	mov	al,[di+bx]
	mov	[si],al
	inc	si

	;�Q�����ڋL�^
	mov	bl,dh
	and	bl,0fh
	mov	al,[di+bx]
	mov	[si],al
	inc	si

	;�R�����ڋL�^
bin2Hex_2:			;�Q�����̂ݕϊ����Ɏg�p�i�΁j
	mov	bl,dl
	and	bl,0f0h
	shr	bx,4
	mov	al,[di+bx]
	mov	[si],al
	inc	si

	;�S�����ڋL�^
	mov	bl,dl
	and	bl,0fh
	mov	al,[di+bx]
	mov	[si],al
	inc	si

	pop	di
	pop	dx
	pop	bx
	pop	ax
	ret



	align	2
;------------------------------------------------------------------------------
;�����l���g�����ϊ��i�Q�P�^�Œ�j
;------------------------------------------------------------------------------
;
;	dl ��16�i���ŁA[si] �ɋL�^����
;	si �� ret �� +4�����B
;
	global	HEX_conv2
HEX_conv2:
	push	ax
	push	bx
	push	dx
	push	di
	mov	di,offset hex_str	;16�i��������
	xor	bx,bx

	jmp	short	bin2Hex_2	;���񂾂�����


;##############################################################################
;���T�u���[�`�� (32 bit)
;##############################################################################
BITS	32
	align	4
;------------------------------------------------------------------------------
;��NULL �ŏI��镶����̕\��
;------------------------------------------------------------------------------
;	ds:[edx]  strings (Null determinant)
;
	global	string_print
string_print:
	push	eax
	push	ebx
	push	edx

	mov	ebx,edx		;ebx ������擪
	dec	ebx		;-1 ����

	align	4
.loop:
	inc	ebx		;�|�C���^�X�V
	cmp	byte [ebx],0	;NULL �����Ɣ�r
	jne	short .loop

	mov	byte [ebx],'$'	;������I�[���ꎞ�I�ɒu��������
	mov	ah,09h		;display string
	int	21h		;DOS call
	mov	byte [ebx],0	;NULL �ɕ���

	mov	ah,09h
	mov	edx,offset cr_lf	;���s
	int	21h			;�\��

	pop	edx
	pop	ebx
	pop	eax
	ret


	align	4
;------------------------------------------------------------------------------
;�����l���P�O�i���ϊ��i���P�^�j
;------------------------------------------------------------------------------
;
;	eax �� 10�i�� �ŁA[edi] �ɋL�^����B
;	�ϊ�����P�^���� ecx ���i2�`10�� �^ ����I�I�j
;
;ret	edi = �Ō�̕����̎��� byte
;
	global	bin2deg_32
bin2deg_32:
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	ebp

	mov	ebx,offset deg_table	;10^n ���l�e�[�u��
	mov	esi,offset deg_str	;10�i ������ϊ��e�[�u��

	dec	ecx			;���� -1
	mov	ebp,15			;�댯�h�~�̂��߂̃}�X�N�l
	mov	b [esi],' '		;0 �̕����� �X�y�[�X������
	and	ecx,ebp			;�댯�h�~�̂��߂̃}�X�N

	align	4
.loop:
	;----------------loop---
	xor	edx,edx			;edx = 0
	div	dword [ebx + ecx*4]	;�ŏ�ʂ̃P�^���犄���Ă���
					;edx.eax / 10^ecx = eax (�]��=edx)
	and	eax,ebp			;�댯�h�~�̂��߁ifor �ŏ�ʌ��j

	test	eax,eax			;�l�`�F�b�N
	jz	short .skip		;0 �������� jmp
	mov	byte [esi],'0'		;0 �̈ʒu�� '0' ������
.skip:

	mov	al,[esi + eax]		;�Y�������R�[�h (0�`9)
	mov	[edi],al		;�L�^
	mov	eax,edx			;eax = �]��
	inc	edi			;���̕����i�[�ʒu�w

	loop	.loop			;ecx = 0 �ɂȂ�܂ŌJ��Ԃ�
	;--------------------loop end---

	mov	b [esi],'0'		;0 �̈ʒu�� '0' ������
	mov	al,[esi + eax]		;�Ō�̌��̕����R�[�h (0�`9)
	mov	[edi],al
	inc	edi

	pop	ebp
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret


	align	4
;------------------------------------------------------------------------------
;�����l���P�U�i���ϊ��i���P�^�j
;------------------------------------------------------------------------------
;
;	eax = value
;	ecx = number of digits
;
;ret	edi = �Ō�̕����̎��� byte
;
	global	bin2hex_32
bin2hex_32:
	push	eax
	push	ebx
	push	ecx
	push	edx

	push	ecx
	mov	edx,ecx
	shl	edx,2		; *4
	mov	cl, 32
	sub	cl, dl
	shl	eax,cl
	pop	ecx

.loop:
	rol	eax, 4
	movzx	ebx, al
	and	bl, 0fh
	mov	dl, [.hex + ebx]

	cmp	b [edi], '_'
	jne	.skip
	inc	edi
.skip:
	mov	[edi], dl
	inc	edi
	loop	.loop

	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

	align	4
.hex	db	"0123456789abcdef"

;------------------------------------------------------------------------------
;������ # ������������
;------------------------------------------------------------------------------
;	eax	value
;	edi	target
;
	align	4
	global	rewrite_next_hash_to_hex
rewrite_next_hash_to_hex:
	push	ecx
.loop:
	inc	edi
	cmp	b [edi], '#'
	jne	.loop
	call	count_num_of_hash
	call	bin2hex_32
	pop	ecx
	ret


	align	4
	global	rewrite_next_hash_to_deg
rewrite_next_hash_to_deg:
	push	ecx
.loop:
	inc	edi
	cmp	b [edi], '#'
	jne	.loop
	call	count_num_of_hash
	call	bin2deg_32
	pop	ecx
	ret

	align	4
count_num_of_hash:
	push	edi
	xor	ecx, ecx
	jmp	.loop
.skip:
	inc	edi
.loop:
	cmp	b [edi+ecx], '_'
	je	.skip
	cmp	b [edi+ecx], '#'
	jne	.exit
	inc	ecx
	jmp	.loop
.exit:
	pop	edi
	ret

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------


	align	4
;//////////////////////////////////////////////////////////////////////////////
;���f�[�^�̈�
;//////////////////////////////////////////////////////////////////////////////
segment	data align=16 class=CODE use16
group	comgroup text data
;------------------------------------------------------------------------------
	global	paras,paras_last,paras_p

paras		dw	0,0		;���������p�����[�^�[�̐�
paras_last	dw	0,0		;0dh �̈ʒu
paras_p		resw	max_paras	;�|�C���^�z��

	align	4
deg_table:
deg_00	dd	1
deg_01	dd	10
deg_02	dd	100
deg_03	dd	1000
deg_04	dd	10000
deg_05	dd	100000
deg_06	dd	1000000
deg_07	dd	10000000
deg_08	dd	100000000
deg_09	dd	1000000000

deg_str:
hex_str	db	'0123456789ABCDEF'

;*** 16 �i�� ���l�ϊ��p�e�[�u�� ***
h2b	db	 0, 1, 2, 3, 4, 5, 6, 7,  8, 9,-1,-1,-1,-1,-1,-1
	db	-1,10,11,12,13,14,15,-1, -1,-1,-1,-1,-1,-1,-1,-1
	db	-1,-1,-1,-1,-1,-1,-1,-1, -1,-1,-1,-1,-1,-1,-1,-1
	db	-1,10,11,12,13,14,15,-1



cr_lf	db	13,10,'$'


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
