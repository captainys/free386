;******************************************************************************
;�@V86 ���� Protect �჌�x���A�g���[�`�� / Free386
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"

%include	"free386.inc"
%include	"memory.inc"

;******************************************************************************
;���O���[�o���V���{���錾
;******************************************************************************

global	setup_cv86
global	clear_mode_data

global	call_V86_int
global	call_V86_int21
global	call_V86_HARD_int

global	call_V86
global	call_V86_ds
global	call_V86_es

global	callf32_from_V86	; use by int 21h ax=250dh and towns.asm

global	rint_labels_adr

;******************************************************************************
segment	text class=CODE align=4 use16
;******************************************************************************
;���������R�[�h
;******************************************************************************
;==============================================================================
;��V86����Protect�A�g���[�`���̃Z�b�g�A�b�v
;==============================================================================
proc32 setup_cv86
	;//////////////////////////////////////////////////
	;�����A���[�h���荞�݃t�b�N���[�`�������p�������擾
	;//////////////////////////////////////////////////
	mov	ax,IntVectors *4	;�t�b�N���[�`�������p������
	call	heap_malloc		;��ʃ��������蓖��
	mov	[rint_labels_adr],di	;save
	mov	dx,di			;dx ��
	add	dx,byte 3		;hook ���x���� ret���x�� �̂�������Z
	mov	[rint_labels_top],dx	;

	;�t�b�N���[�`���̐���
	mov	bl,0e8h			;call����
	mov	bh, 90h			;NOP ����
	mov	cx,IntVectors		;int �̐�
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

	ret

BITS	32
;------------------------------------------------------------------------------
;��V86����Protect ���[�h�؂芷���f�[�^�̏�����
;------------------------------------------------------------------------------
	align	4
clear_mode_data:
	ret


;******************************************************************************
;��V86 ���[�h�̊��荞�݃��[�`���Ăяo�� (from Protect mode)
;******************************************************************************
;	����	+00h d Interrupt number
;
	align	4
call_V86_int21:
	push	d 21h			;�x�N�^�ԍ�
call_V86_int:
	sub	esp, 10h		;es --> gs
	push	eax

	push	ds
	push	es

	push	d F386_ds
	pop	ds

	cli
	mov	eax,DOSMEM_sel		;DOS�������ǂݏ����p�Z���N�^
	mov	  es,ax			;es �Ƀ��[�h
	mov	eax,[esp + 4*7]		;�����i�x�N�^�ԍ�*4�j���擾
	mov	eax,[es:eax*4]		;V86 ���荞�݃x�N�^���[�h
	mov	[call_V86_adr],eax	;�Ăяo���A�h���X�Z�[�u

	pop	es
	pop	ds

	mov	eax, [cs:V86_cs]
	mov	[esp+04h], eax		;V86 ds
	mov	[esp+08h], eax		;V86 es
	mov	[esp+0ch], eax		;V86 fs
	mov	[esp+10h], eax		;V86 gs

	mov	eax, [cs:call_V86_adr]
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
;	����	+00h d Interrupt number
;
	align	4
call_V86_HARD_int:
	xchg	[esp], esi		;esi = int�ԍ�
	push	eax
	push	es

	mov	eax,[cs:V86_cs]
	push	eax			;gs
	push	eax			;fs
	push	eax			;es
	push	eax			;ds

	mov	eax,DOSMEM_sel		;DOS�������ǂݏ����p�Z���N�^
	mov	  es,ax
	push	d [es:esi*4]		;V86���荞�݃x�N�^

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
	mov	[call_V86_adr],eax	;�Ăяo���A�h���X�Z�[�u

	push	ss			;���݂̃X�^�b�N
	pop	gs			;gs �ɐݒ�

	lss	esp,[VCPI_stack_adr]	;��p�X�^�b�N���[�h
	push	d [gs:esi+12]		;** V86 gs
	push	d [gs:esi+ 8]		;** V86 fs
	push	d [gs:esi   ]		;** V86 ds
	push	d [gs:esi+ 4]		;** V86 es
	push	d [V86_cs]		;** V86 ss

	call	alloc_sw_stack_32
	push	eax			;** V86 sp
	pushf				;eflags
	push	d [V86_cs]		;** V86 CS ���L�^
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
	call	far [cs:call_V86_adr]	;�ړI���[�`���̃R�[��

	cli
	mov	[cs:call_V86_ds],ds	;ds �Z�[�u
	mov	ds,[cs:V86_cs]		;V86�� ds
	mov	[call_V86_es],es	;es �Z�[�u
	mov	[call_V86_fs],fs	;fs �Z�[�u
	mov	[call_V86_gs],gs	;gs �Z�[�u

	mov	[save_eax],eax		;eax �Z�[�u
	mov	[save_esi],esi		;esi �Z�[�u
	pushf
	pop	w [call_V86_flags]	;flags �Z�[�u

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
	mov	  ds,ax			;gs �Ƀ��[�h

	lss	esp,[save_esp]		;�X�^�b�N����
	call	free_sw_stack_32

	;����	+08h	V86 ds
	;	+0ch	V86 es
	;	+10h	V86 fs
	;	+14h	V86 gs
	mov	eax,[call_V86_ds]	;V86 ds �߂�l
	mov	esi,[call_V86_es]	;V86 es
	mov	[esp + 4*4 + 08h],eax	;�X�^�b�N�ɃZ�[�u
	mov	[esp + 4*4 + 0ch],esi	;
	mov	eax,[call_V86_fs]	;V86 fs
	mov	esi,[call_V86_gs]	;V86 gs
	mov	[esp + 4*4 + 10h],eax	;�X�^�b�N�ɃZ�[�u
	mov	[esp + 4*4 + 14h],esi	;

	pop	gs			;
	pop	fs			;�Z���N�^����
	pop	es			;
	pop	ds			;

	mov	eax,[cs:save_eax]	;eax ����
	mov	esi,[cs:save_esi]	;esi ����

	bt	d [cs:call_V86_flags],0	;V86�� Carry�t���O�ݒ�
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
	mov	  ds,ax			;ds ���[�h
	mov	  es,ax			;
	mov	  fs,ax			;
	mov	  gs,ax			;

	lss	esp,[PM_stack_adr]	;��p�X�^�b�N���[�h
	;call	alloc_sw_stack_32	;�X�^�b�N�̈�m��

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

	;call	free_sw_stack_32	;�X�^�b�N�J��

	mov	eax,[V86_cs]		;V86�� cs,ds
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
callf32_from_V86:
	; retf address	;     = 4
	push	ds	; 2*4 = 8
	push	es
	push	fs
	push	gs
	push	eax	; 4*2 = 8
	push	esi

	push	cs
	pop	ds

	cli
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

	mov   d [to_PM_EIP],offset .32	; jmp to
	mov	esi, [to_PM_data_ladr]
	mov	ax,0de0ch
	int	67h			; VCPI call


	align 4
BITS	32
.32:
	mov	eax,F386_ds		;
	mov	  ds,ax			;ds ���[�h
	mov	  es,ax			;
	mov	  fs,ax			;
	mov	  gs,ax			;
	lss	esp, [cf32_esp32]	;ss:esp ��ݒ�

	pop	esi
	pop	eax
	call	far [cf32_target_eip]
	push	eax
	push	esi
	mov	esi, esp

	mov	eax,[V86_cs]		;V86�� cs,ds
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



BITS	32
;******************************************************************************
;���f�[�^
;******************************************************************************
segment	data class=DATA align=4
;------------------------------------------------------------------------------
save_eax	dd	0		;temporary
save_esi	dd	0		;
save_esp	dd	0		;
save_ss		dd	0		;

call_V86_ds	dw	0,0		;
call_V86_es	dw	0,0		;V86 �̃��[�`���R�[�����
call_V86_fs	dw	0,0		; �e���W�X�^�̒l
call_V86_gs	dw	0,0		;
call_V86_flags	dw	0,0		;

call_V86_adr	dd	0		;V86 / �Ăяo�� CS:IP

	; Real mode interrupt hook routines, for call to 32bit from V86.
rint_labels_adr	dd	0
rint_labels_top	dd	0		; rint_labels_adr +3


cf32_ss16	dd	0		;
cf32_esp32	dd	0		;in 32bit linear address
		dd	DOSMEM_sel	;for lss
cf32_target_eip	dd	0		;call target entry
cf32_target_cs	dd	0		;

;******************************************************************************
;******************************************************************************
