;******************************************************************************
;�@V86 ���� Protect �჌�x���A�g���[�`�� / Free386
;******************************************************************************
;[TAB=8]
;
%include	"nasm_abk.h"		;NASM �p�w�b�_�t�@�C��
%include	"macro.asm"		;�}�N�����̑}��
%include	"f386def.inc"		;�萔���̑}��

%include	"free386.inc"		;�O���ϐ�


;******************************************************************************
;���O���[�o���V���{���錾
;******************************************************************************

public	setup_cv86		;call v86 �̏����ݒ�
public	clear_mode_data		;���[�h�ؑւ��f�[�^�̏�����

public	call_V86_int		;int �Ăяo��
public	call_V86_int21		;int 21h �Ăяo��
public	call_V86_HARD_int

public	call_V86		;�ėp�I�ȂȌĂяo�����[�`�� (call ���Ďg�p)
public	rint_labels_adr		;���A�����[�h���荞�݃t�b�N���[�`���擪�A�h���X

public	call_v86_ds
public	call_v86_es
public	ISTK_nest

public	callf32_from_v86	; use by towns.asm, int 21h ax=250dh

segment	text align=4 class=CODE use16
;******************************************************************************
;���������R�[�h
;******************************************************************************
;==============================================================================
;��V86����Protect�A�g���[�`���̃Z�b�g�A�b�v
;==============================================================================
BITS	16
setup_cv86:
	;//////////////////////////////////////////////////
	;�����A���[�h���荞�݃t�b�N���[�`�������p�������擾
	;//////////////////////////////////////////////////
	mov	ax,Real_Vectors *4	;�t�b�N���[�`�������p������
	call	heap_malloc		;��ʃ��������蓖��
	mov	[rint_labels_adr],di	;save
	mov	dx,di			;dx ��
	add	dx,byte 3		;hook ���x���� ret���x�� �̂�������Z
	mov	[rint_labels_top],dx	;

	;�t�b�N���[�`���̐���
	mov	bl,0e8h			;call����
	mov	bh, 90h			;NOP ����
	mov	cx,Real_Vectors		;int �̐�
	mov	si,offset int_V86	;�Ăяo�����x��
	mov	bp,4			;���Z�l
	mov	ax,si			;ax = �Ăяo���A�h���X

	align	4
	;e8 xxxx	call int_buf
	;90		nop
	;�� 256 ���ׂ�iint hook�p�j
.loop:
	mov	[di+3],bh		;NOP
	mov	[di  ],bl		;call
	sub	ax,dx			;���΃A�h���X�Z�o
	mov	[di+1],ax		;<r_adr>
	add	di,bp			;int ���x��
	add	dx,bp			;call �� stack �ɐς܂��A�h���X
	mov	ax,si			;ax = �Ăяo���A�h���X
	loop	.loop

	;//////////////////////////////////////////////////
	;���[�h�؂芷�����p�A�ꎞ�X�^�b�N�������擾
	;//////////////////////////////////////////////////
	mov	ax,ISTK_size * ISTK_nest_max	;V86 <-> Prot stack
	call	stack_malloc			;���ʃ��������蓖��
	mov	[ISTK_adr    ],di		;�L�^
	mov	[ISTK_adr_org],di		;�����l
	ret

BITS	32
;------------------------------------------------------------------------------
;��V86����Protect ���[�h�؂芷���f�[�^�̏�����
;------------------------------------------------------------------------------
	align	4
clear_mode_data:
	pushfd
	cli
	push	eax
	mov	eax,[ISTK_adr_org]		;�����l���[�h
	mov	[ISTK_adr], eax			;�Z�[�u

	mov	eax,[int_buf_adr_org]		;�����l���[�h
	mov	[int_buf_adr],eax		;�Z�[�u

	mov	eax,[int_rwbuf_adr_org]		;�����l���[�h
	mov	[int_rwbuf_adr] ,eax		;�Z�[�u
	mov   d	[int_rwbuf_size],INT_RWBUF_size	;�Z�[�u

	xor	eax, eax
	mov	[ISTK_nest],eax			;nest�J�E���^������
	pop	eax
	popfd
	ret


;******************************************************************************
;��V86 ���[�h�̊��荞�݃��[�`���Ăяo�� (from Protect mode)
;******************************************************************************
;	����	+00h d Int_No * 4
;
	align	4
call_V86_int21:
	push	d (21h * 4)		;ds : �x�N�^�ԍ� �~4
call_V86_int:
	sub	esp, 10h		;es --> gs
	push	eax

	push	ds
	push	es

	push	d F386_ds
	pop	ds

	cli
	mov	eax,DOSMEM_sel		;DOS�������ǂݏ����p�Z���N�^
	mov	 es,eax			;es �Ƀ��[�h
	mov	eax,[esp + 4*7]		;�����i�x�N�^�ԍ�*4�j���擾
	mov	eax,[es:eax]		;V86 ���荞�݃x�N�^���[�h
	mov	[call_v86_adr],eax	;�Ăяo���A�h���X�Z�[�u

	pop	es
	pop	ds

	mov	eax, [cs:v86_cs]
	mov	[esp+04h], eax		;V86 ds
	mov	[esp+08h], eax		;V86 es
	mov	[esp+0ch], eax		;V86 fs
	mov	[esp+10h], eax		;V86 gs

	mov	eax, [cs:call_v86_adr]
	xchg	[esp], eax		;[esp]=�Ăяo����, eax=�I���W�i��
	call	call_V86

	; Carry�t���O�ݒ�
	pushfd
	push	eax

	mov	eax, [esp+4]
	and	b [esp+28h], 0feh
	and	al, 01h
	or	b [esp+28h], al

	pop	eax
	add	esp, 1ch		;�X�^�b�N����
	iret


;******************************************************************************
;��V86���[�h�̊��荞�݃��[�`���Ăяo�� (�n�[�h�E�F�A���荞�ݗp)
;******************************************************************************
;	����	+00h d Int_No * 4

	align	4
call_V86_HARD_int:
	xchg	[esp], esi		;esi = int�ԍ�*4
	push	eax
	push	es

	mov	eax,[cs:v86_cs]
	push	eax			;gs
	push	eax			;fs
	push	eax			;es
	push	eax			;ds

	mov	eax,DOSMEM_sel		;DOS�������ǂݏ����p�Z���N�^
	mov	 es,eax
	push	d [es:esi]		;V86���荞�݃x�N�^

	call	call_V86

	add	esp, 14h		;�X�^�b�N����

	pop	es
	pop	eax
	pop	esi
	iret


;******************************************************************************
;��V86�R�[���ėp�T�u���[�`��
;******************************************************************************
;�E���̃��[�`���́ucall�v���Ďg�p����
;�EV86 �R�[������ �Z�O�����g���W�X�^�̒l��ۑ�����
;�E�C�ӂ̃A�h���X���Ăяo����
;�E�t���O�͊�{�I��V86���ŁAcall�����߂�l���Z�b�g
;
;����	+00h	�߂�A�h���X
;	+04h	call adress / cs:ip
;	+08h	V86 ds
;	+0ch	V86 es
;	+10h	V86 fs
;	+14h	V86 gs
;
	align	4
call_V86:
	push	ds	;1	esp �ɂ��X�^�b�N�Q�Ƃɒ��ӁI
	push	es	;2
	push	fs	;3
	push	gs	;4

	push	d (F386_ds)		;�f�[�^�Z�O�����g
	pop	ds			;ds �Ƀ��[�h

	cli
	mov	[save_eax],eax		;eax�ۑ�
	mov	[save_esi],esi		;esi
	mov	[save_esp],esp
	mov	[save_ss] ,ss

	mov	eax,[esp + 4*4 +4]	;�Ăяo���A�h���X���[�h
	lea	esi,[esp + 4*4 +8]	;V86 call �p�����[�^�u���b�N
	mov	[call_v86_adr],eax	;�Ăяo���A�h���X�Z�[�u

	push	ss			;���݂̃X�^�b�N
	pop	gs			;gs �ɐݒ�

	lss	esp,[VCPI_stack_adr]	;��p�X�^�b�N���[�h
	push	d [gs:esi+12]		;** V86 gs
	push	d [gs:esi+ 8]		;** V86 fs
	push	d [gs:esi   ]		;** V86 ds
	push	d [gs:esi+ 4]		;** V86 es
	push	d [v86_cs]		;** V86 ss

	call	alloc_ISTK_32
	push	eax			;** V86 sp
	pushf				;eflags
	push	d [v86_cs]		;** V86 CS ���L�^
	push	d (offset .in86)	;** V86 IP ���L�^

	mov	ax,0de0ch		;VCPI function 0ch / to V86 mode
	call 	far [VCPI_entry]	;VCPI far call


;--------------------------------------------------------------------
;�EV86��
;--------------------------------------------------------------------
BITS	16
	align	4
.in86:
	push	d [cs:save_ss]		;�Ăяo������ ss/esp
	push	d [cs:save_esp]		;

	mov	eax,[cs:save_eax]	;eax �̒l����
	mov	esi,[cs:save_esi]	;esi �̒l����

	push	w (-1)			;mark / iret,retf���Ή��̂���
	pushf				;flag save for INT
	push	cs			;
	push	w .call_ret		;�߂胉�x��
	push	d [cs:call_v86_adr]	;�ړI���[�`��
	sti
	retf				;far call
.call_ret:
	;;call	far [cs:call_v86_adr]	;�ړI���[�`���̃R�[��

	cli
	mov	[cs:call_v86_ds],ds	;ds �Z�[�u
	mov	ds,[cs:v86_cs]		;V86�� ds
	mov	[call_v86_es],es	;es �Z�[�u
	mov	[call_v86_fs],fs	;fs �Z�[�u
	mov	[call_v86_gs],gs	;gs �Z�[�u

	mov	[save_eax],eax		;eax �Z�[�u
	mov	[save_esi],esi		;esi �Z�[�u
	pushf
	pop	w [call_v86_flags]	;flags �Z�[�u

	pop	ax			;flags����菜����Ă邩�H
	cmp	ax,-1
	jz	.pop_skip		;flags���Ȃ����skip
	pop	ax
.pop_skip:
	pop	d [save_esp]		;Protect mode esp
	pop	d [save_ss]		;Protect mode ss

	mov	d [to_PM_EIP],offset .retPM	;�߂胉�x��

	mov	esi,[to_PM_data_ladr]	;���[�h�ؑւ��p�\���̃A�h���X
	mov	ax,0de0ch		;to �v���e�N�g���[�h
	int	67h			;VCPI call

BITS	32
;--------------------------------------------------------------------
;�E�v���e�N�g���[�h��
;--------------------------------------------------------------------
	align	4
.retPM:
	mov	eax,F386_ds		;ds
	mov	 ds,eax			;gs �Ƀ��[�h

	lss	esp,[save_esp]		;�X�^�b�N����
	call	free_ISTK_32

	;����	+08h	V86 ds
	;	+0ch	V86 es
	;	+10h	V86 fs
	;	+14h	V86 gs
	mov	eax,[call_v86_ds]	;V86 ds �߂�l
	mov	esi,[call_v86_es]	;V86 es
	mov	[esp + 4*4 + 08h],eax	;�X�^�b�N�ɃZ�[�u
	mov	[esp + 4*4 + 0ch],esi	;
	mov	eax,[call_v86_fs]	;V86 fs
	mov	esi,[call_v86_gs]	;V86 gs
	mov	[esp + 4*4 + 10h],eax	;�X�^�b�N�ɃZ�[�u
	mov	[esp + 4*4 + 14h],esi	;

	pop	gs			;
	pop	fs			;�Z���N�^����
	pop	es			;
	pop	ds			;

	mov	eax,[cs:save_eax]	;eax ����
	mov	esi,[cs:save_esi]	;esi ����

	bt	d [cs:call_v86_flags],0	;V86�� Carry�t���O�ݒ�
	ret


;******************************************************************************
;��V86 ����v���e�N�g���[�h���荞�݃��[�`���̌Ăяo��
;******************************************************************************
BITS	16
	align	4
int_V86:
	push	ds	;4
	push	es	;3
	push	fs	;2
	push	gs	;1

	push	cs			;
	pop	ds			;ds �ݒ�
	mov	[save_eax],eax		;eax �Z�[�u
	mov	[save_esi],esi		;esi
	mov	[save_esp],esp
	mov	[save_ss] ,ss

	;-------------------------------
	;int �ԍ��̎Z�o
	;-------------------------------
	mov	ax,ss			;
	mov	fs,ax			;fs:si = ss:sp
	mov	si,sp			;

	mov	ax,[fs:si + 2*4]	;call ���A�h���X
	sub	ax,[rint_labels_top]	;�o�^�ԍ� 0 ���� (CPU Int �����Ɠ���
	shr	ax,2			;4 �Ŋ���         int.asm �Q��)
	mov	[.int_no], al		;�v���e�N�g���̌Ăяo���ԍ��Ƃ��ċL�^

	mov   d [to_PM_EIP],offset .32	;�Ăяo�����x��

	mov	esi,[to_PM_data_ladr]	;���[�h�ؑւ��\����
	mov	ax,0de0ch		;to �v���e�N�g���[�h
	int	67h			;VCPI call


	align	4
	;*** �v���e�N�g���[�h����̕��A���x�� ******
.ret_PM:
	mov	eax,[save_eax]		;eax ����
	mov	esi,[save_esi]		;esi

	pop	gs
	pop	fs
	pop	es
	pop	ds
	add	sp,byte 2		;call �̖߂�X�^�b�N����
	iret



BITS	32
;--------------------------------------------------------------------
;�E�v���e�N�g���[�h
;--------------------------------------------------------------------
	align	4
.32:
	mov	eax,F386_ds		;
	mov	 ds,eax			;ds ���[�h
	mov	 es,eax			;
	mov	 fs,eax			;
	mov	 gs,eax			;

	lss	esp, [ISTK_adr]		;ss:esp ��ݒ�
	call	alloc_ISTK_32		;�X�^�b�N�̈�m��

	push	d [save_ss]		;���A�����[�h�X�^�b�N
	push	d [save_esp]

	mov	eax,[save_eax]		;eax ����
	mov	esi,[save_esi]		;esi

	push	ds
	db	0cdh			;int ����
.int_no	db	 00h
	pop	ds

	cli
	mov	[save_eax], eax		;eax �ۑ�
	mov	[save_esi], esi		;esi

	pop	d [save_esp]		;���A�����[�h�X�^�b�N
	pop	d [save_ss]

	call	free_ISTK_32		;�X�^�b�N�J��

	mov	eax,[v86_cs]		;V86�� cs,ds
	push	eax			;** V86 gs
	push	eax			;** V86 fs
	push	eax			;** V86 ds
	push	eax			;** V86 es
	push	d [save_ss ]		;** V86 ss
	push	d [save_esp]		;** V86 sp
	pushfd				;eflags
	push	eax			;** V86 CS ���L�^
	push	d (offset .ret_PM)	;** V86 IP ���L�^

	mov	ax,0de0ch		;VCPI function 0ch / to V86 mode
	call 	far [VCPI_entry]	;VCPI far call


;******************************************************************************
; far call protect mode routeine from V86
;******************************************************************************
BITS	16
	align	4
callf32_from_v86:
	; retf address	;     = 4
	push	ds	; 2*4 = 8
	push	es
	push	fs
	push	gs
	push	eax	; 4*2 = 8
	push	esi

	push	cs
	pop	ds

	push	bp	; = 2
	mov	bp, sp
	mov	eax, [bp + 16h]
	mov	[cs:cf32_target_eip], eax
	mov	eax, [bp + 1ah]
	mov	[cs:cf32_target_cs],  eax
	pop	bp

	xor	eax, eax
	mov	ax, ss
	mov	[cf32_ss16],  eax	;save SS
	shl	eax, 4
	add	eax, esp
	mov	[cf32_esp32], eax	;linear adddress of ss:esp

	cli
	mov   d [to_PM_EIP],offset .32	;�Ăяo�����x��
	mov	esi, [to_PM_data_ladr]	;���[�h�ؑւ��\����
	mov	ax,0de0ch		;to �v���e�N�g���[�h
	int	67h			;VCPI call


	align 4
BITS	32
.32:
	mov	eax,F386_ds		;
	mov	 ds,eax			;ds ���[�h
	mov	 es,eax			;
	mov	 fs,eax			;
	mov	 gs,eax			;
	lss	esp, [cf32_esp32]	;ss:esp ��ݒ�

	pop	esi
	pop	eax
	call	far [cf32_target_eip]
	push	eax
	push	esi
	mov	esi, esp

	mov	eax,[v86_cs]		;V86�� cs,ds
	push	eax			;** V86 gs
	push	eax			;** V86 fs
	push	eax			;** V86 ds
	push	eax			;** V86 es

	push	d [cf32_ss16]		;** V86 ss
	push	eax			;** V86 sp // dummy
	pushfd				;eflags
	push	eax			;** V86 CS
	push	d (offset .ret_PM)	;** V86 IP

	mov	eax, [cf32_ss16]
	shl	eax, 4
	sub	esi, eax
	mov	[esp + 0ch], esi	; Fix V86 sp

	mov	ax,0de0ch		;VCPI function 0ch / to V86 mode
	call 	far [VCPI_entry]	;VCPI far call


	align	4
BITS	16
.ret_PM:
	pop	esi
	pop	eax

	pop	gs
	pop	fs
	pop	es
	pop	ds
	retf


;******************************************************************************
;��ISTK�T�u���[�`�� 32bit
;******************************************************************************
BITS	32
;==============================================================================
;��ISTK�̈悩��X�^�b�N���������m��
;==============================================================================
	align	4
alloc_ISTK_32:		;eax = �m�ۂ���ISTK�o�b�t�@
	pushfd
	cli

	mov	eax, [ISTK_nest]
	cmp	eax, ISTK_nest_max
	jae	short .error_exit

	;nest counter +1
	inc	eax
	mov	[ISTK_nest], eax

	;int_buf �̃A�h���X�X�V
	shl	eax, INT_BUF_sizebits
	add	eax, [int_buf_adr_org]
	mov	[int_buf_adr]  ,eax
	mov	[int_rwbuf_adr],eax
	mov	d [int_rwbuf_size],INT_BUF_size

	;return ISTK
	mov	eax, [ISTK_adr]
	sub	d [ISTK_adr], ISTK_size

	popfd
	ret

.error_exit:
	call	clear_mode_data
	F386_end	26h		; ISTK Overflow

;==============================================================================
;��ISTK�̈�̃��������J��
;==============================================================================
	align	4
free_ISTK_32:
	pushfd
	cli
	push	eax
	push	ebx

	mov	eax, [ISTK_nest]
	test	eax, eax
	jz	short .error_exit

	;nest counter -1
	dec	eax
	mov	[ISTK_nest], eax

	;int_buf �̃A�h���X�X�V
	mov	ebx, eax
	shl	ebx, INT_BUF_sizebits
	add	ebx, [int_buf_adr_org]
	mov	[int_buf_adr],ebx

	test	eax, eax
	jnz	short .nested

	;�l�X�g�Ȃ��Ȃ�Read/Write buffer�͑傫���̂��g��
	mov	d [int_rwbuf_size],INT_RWBUF_size
	mov	ebx,[int_rwbuf_adr_org]
.nested:
	mov	[int_rwbuf_adr],ebx

	;free ISTK
	add	d [ISTK_adr], ISTK_size

	pop	ebx
	pop	eax
	popfd
	ret

.error_exit:
	call	clear_mode_data
	push	d 0
	push	d 3F0h

	F386_end	27h		; ISTK Underflow


BITS	32
;******************************************************************************
;���f�[�^
;******************************************************************************
segment	data align=16 class=CODE use16
group	comgroup text data
;------------------------------------------------------------------------------
save_eax	dd	0		;���[�h�؂芷�����̃��W�X�^�Z�[�u�p
save_esi	dd	0		;
save_esp	dd	0		;�����܂ňꎞ�̈�
save_ss		dd	0		;

call_v86_ds	dw	0,0		;
call_v86_es	dw	0,0		;V86 �̃��[�`���R�[�����
call_v86_fs	dw	0,0		; �e���W�X�^�̒l
call_v86_gs	dw	0,0		;
call_v86_flags	dw	0,0		;

call_v86_adr	dd	0		;V86 / �Ăяo�� CS:IP

ISTK_adr	dd	0		;V86����Protect���[�h�ؑ֎��p�̃X�^�b�N
		dd	F386_ds		;�Z���N�^
ISTK_adr_org	dd	0
ISTK_nest	dd	0

rint_labels_top	dd	0		;��+3/ �߂�I�t�Z�b�g���� int�ԍ��Z�o�p
rint_labels_adr	dd	0		;���A�����[�h���荞�݃t�b�N���[�`��
					;�@�쐬�̈�ւ̃|�C���^

cf32_ss16	dd	0		;
cf32_esp32	dd	0		;in 32bit linear address
		dd	DOSMEM_sel	;for lss
cf32_target_eip	dd	0		;call target entry
cf32_target_cs	dd	0		;

;******************************************************************************
;******************************************************************************
