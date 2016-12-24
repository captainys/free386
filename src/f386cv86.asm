;******************************************************************************
;�@V86 ���� Protect �჌�x���A�g���[�`�� / Free386
;******************************************************************************
;[TAB=8]
;
; 2001/02/15�@Free386.asm ���番��
;
;
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

public	call_V86		;�ėp�I�ȂȌĂяo�����[�`�� (call ���Ďg�p)
public	rint_labels_adr		;���A�����[�h���荞�݃t�b�N���[�`���擪�A�h���X

public	call_v86_ds
public	call_v86_es
public	ISTK_nest

segment	text align=4 class=CODE use16
;******************************************************************************
;���������R�[�h
;******************************************************************************
;==============================================================================
;��V86����Protect�A�g���[�`���̃Z�b�g�A�b�v
;==============================================================================
;ISTK_v86_size	equ	200h	;���[�h�؂芷�����AV86 ���X�^�b�N�ۏ؃T�C�Y
;ISTK_prot_size	equ	200h	;���[�h�؂芷�����AProtect ���X�^�b�N�ۏ؃T�C�Y
;INT_nests	equ	4	;���荞�݃l�X�g�� (��Prot / V86 ���ꂼ��ɂ�)
;
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
	sub	esp, 0ch		;es --> gs
	push	eax

	push	ds
	push	es
	LOAD_F386_ds			;�f�[�^�Z�O�����g

	cli
	mov	eax,DOSMEM_sel		;DOS�������ǂݏ����p�Z���N�^
	mov	 es,eax			;gs �Ƀ��[�h
	mov	eax,[esp + 4*6]		;�����i�x�N�^�ԍ�*4�j���擾
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

	; �t���O�ݒ�
	pushfd
	push	eax
	mov	eax, [esp+4]
	mov	[esp+24h], eax

	pop	eax
	add	esp, 18h		;�X�^�b�N����
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
	VCPI_function			;VCPI far call


;--------------------------------------------------------------------
;�EV86��
;--------------------------------------------------------------------
BITS	16
	align	4
.in86:
	push	d [cs:save_ss]		;�Ăяo������ ss/esp
	push	d [cs:save_esp]		;

	mov	eax,[cs:save_eax]	;eax �̒l����
	mov	esi,[cs:save_esi]	;eax �̒l����

	push	w (-1)			;mark / iret,retf���Ή��̂���
	pushf				;flag save for INT
	call	far [cs:call_v86_adr]	;�ړI���[�`���̃R�[��

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

	mov	w [to_PM_EIP],offset .retPM	;�߂胉�x��

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

	pushfd		;flags

	mov	eax,[cs:call_v86_flags]	;V86 ���t���O
	and	eax,    00cffh		;IF/IOPL �ȊO���o��
	and	w [esp],0f300h		;IF/IOPL �Ȃǎ��o��
	or	  [esp],ax		;���ʂ̃t���O��������

	mov	eax,[cs:save_eax]	;eax ����
	mov	esi,[cs:save_esi]	;esi ����

	popfd
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

	mov   w [to_PM_EIP],offset .32	;�Ăяo�����x��

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
	cli
	mov	eax,F386_ds		;
	mov	 ds,eax			;ds ���[�h
	mov	 es,eax			;
	mov	 fs,eax			;
	mov	 gs,eax			;

	lss	esp, [ISTK_adr]		;ss:esp ��ݒ�
	call	alloc_ISTK_32		;DS������

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
	lss	esp,[VCPI_stack_adr]	;��p�X�^�b�N���[�h
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
	VCPI_function			;VCPI far call


;******************************************************************************
;��ISTK�T�u���[�`�� 32bit
;******************************************************************************
;==============================================================================
;��ISTK����X�^�b�N���������m��
;==============================================================================
	align	4
alloc_ISTK_32:
	pushf
	cli
	mov	eax, [ISTK_nest]
	cmp	eax, ISTK_nest_max
	jae	short .error_exit

	mov	eax, [ISTK_adr]
	inc	d [ISTK_nest]
	sub	d [ISTK_adr], ISTK_size

	push	eax
	mov	eax, [ISTK_nest]
	shl	eax, INT_BUF_sizebits
	add	eax, [int_buf_adr_org]
	mov	[int_buf_adr],eax
	pop	eax

	popf
	ret

.error_exit:
	call	clear_mode_data
	F386_end	26h		; ISTK Overflow

;==============================================================================
;��ISTK���������J��
;==============================================================================
	align	4
free_ISTK_32:
	pushf
	push	eax
	cli

	mov	eax, [ISTK_nest]
	test	eax, eax
	jz	short .error_exit

	dec	d [ISTK_nest]
	add	d [ISTK_adr], ISTK_size

	mov	eax, [ISTK_nest]
	shl	eax, INT_BUF_sizebits
	add	eax, [int_buf_adr_org]
	mov	[int_buf_adr],eax

	pop	eax
	popf
	ret

.error_exit:
	call	clear_mode_data
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

;******************************************************************************
;******************************************************************************
