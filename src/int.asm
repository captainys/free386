;******************************************************************************
;�@Free386	���荞�ݏ������[�`��
;******************************************************************************
;[TAB=8]
;
; 2001/01/18	�t�@�C���𕪗�
; 2001/02/26	�I�u�W�F�N�g�t�@�C���𕪗�
;
%include	"nasm_abk.h"		;NASM �p�w�b�_�t�@�C��
%include	"macro.asm"		;�}�N�����̑}��
%include	"f386def.inc"		;�萔���̑}��

%include	"start.inc"		;����I�v�V����
%include	"f386sub.inc"		;Free386 �p�T�u���[�`��
%include	"f386seg.inc"		;�Z���N�^/�y�[�W���O���[�`��
%include	"f386cv86.inc"		;V86 ���� Protect �჌�x���A�g���[�`��
%include	"free386.inc"		;Free386 �{�̕ϐ�

;//////////////////////////////////////////////////////////////////////////////
;���O���[�o���V���{���錾
;//////////////////////////////////////////////////////////////////////////////

public		PM_int_00h
public		PM_int_dummy
public		DOS_int_list
public		intr_M0
public		intr_S0


;//////////////////////////////////////////////////////////////////////////////
;�����荞�ݏ������[�`��
;//////////////////////////////////////////////////////////////////////////////
segment	text align=4 class=CODE use16
BITS	32
;------------------------------------------------------------------------------
;���_�~�[�̊��荞�݃n���h��
;------------------------------------------------------------------------------
;	DOS �̃n���h���� chain ����
;
	align	4
PM_int_dummy:
	push	ebx
	push	ds

	mov	ds ,[esp+0ch]		;CS
	mov	ebx,[esp+08h]		;EIP ���[�h
	movzx	ebx,b [ebx-1]		;int �ԍ������[�h
	pop	ds

%if INT_HOOK
	xchg	[esp], ebx		;ebx����
	call	register_dump_from_int	;safe
	xchg	[esp], ebx		;ebx=int�ԍ�
%endif
	shl	ebx,2			;4 �{����

	xchg	[esp],ebx		;ebx���� �� �Ăяo���x�N�^�ݒ�
	jmp	call_V86_int


;------------------------------------------------------------------------------
;���C���e���\��b�o�t��O�iint 00 - 1f�j
;------------------------------------------------------------------------------
	align	4
PM_int_00h:	clc
		push	eax
		call	cpu_int
PM_int_top:	nop

PM_int_01h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_02h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_03h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_04h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_05h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_06h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_07h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_08h:	clc
		nop
		jmp	NEAR double_fault
		nop

PM_int_09h:	clc
		nop
		call	cpu_int
		nop

PM_int_0ah:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_0bh:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_0ch:	clc
		nop
		jmp	NEAR stack_fault	;�X�^�b�N��O
		nop

PM_int_0dh:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_0eh:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_0fh:	clc
		push	eax
		call	cpu_int
		nop

PM_int_10h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_11h:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_12h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_13h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_14h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_15h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_16h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_17h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_18h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_19h:	clc
		push	eax
		call	cpu_int
		nop

PM_int_1ah:	clc
		push	eax
		call	cpu_int
		nop

PM_int_1bh:	clc
		push	eax
		call	cpu_int
		nop

PM_int_1ch:	clc
		push	eax
		call	cpu_int
		nop

PM_int_1dh:	clc
		push	eax
		call	cpu_int
		nop

PM_int_1eh:	stc
		nop
		call	cpu_int_with_error_code
		nop

PM_int_1fh:	clc
		push	eax
		call	cpu_int

	;	+0ch	eflags
	;	+08h	cs
	;	+04h	eip
	;stack	+00h	error code

	align	4
double_fault:
stack_fault:
	lss	esp,[cs:PM_stack_adr]		;�X�^�b�N�|�C���^���[�h
	push	d -1				; eflags
	push	d -1				; eip
	push	d -1				; cs
	push	d 0				; error code
	push	d (offset PM_int_0ch +7)	;call ���̑���
	push	ds
	push	eax
	jmp	short view_int

	align	4
cpu_int:
cpu_int_with_error_code:
	cld
	push	ds
	push	eax	; for register_dump_fault	;safe
	pushf

	mov	eax, F386_ds
	mov	ds, eax

	mov	eax, esp
	sub	eax, 1ch
	mov	[dump_orig_esp],esp
	mov	eax, ss
	mov	[dump_orig_ss] ,eax

	; �X�^�b�N�̈��S���`�F�b�N
	verw	ax
	jnz	short .load_stack	; ss �ɏ������݂ł��Ȃ�
	test	eax, eax
	jz	short .load_stack	; ss=0
	lsl	eax, eax		; eax = �Z���N�^���
	cmp	esp, eax 		; esp ���Z���N�^����𒴂��ĂȂ�
	jbe	short .safe
.load_stack:
	lss	esp,[cs:PM_stack_adr]	;���S�ȃX�^�b�N�|�C���^���[�h
	xor	eax, eax
	dec	eax
	push	eax				; eflags
	push	eax				; eip
	push	eax				; cs
	push	eax				; error code
	push	d (offset PM_int_1fh +7)	; call ���̑���
	push	ds
	push	eax
	clc
	pushf
.safe:
	popf

view_int:
	mov	eax, F386_ds
	mov	ds, eax

	jc	short .step		; �G���[�R�[�h��������
	mov	d [esp+0ch], -1		; ����G���[�R�[�h
.step:
	;���� int �ԍ��Z�o
	mov	eax,[esp+8]		;call���A�h���X
	sub	eax,offset PM_int_top	;int 00h �Ƃ̍�
	shr	eax,3			;1/8 ����� eax = Int �ԍ�
	mov	[esp+8],eax		;int �ԍ��ۑ�
	call	register_dump_fault	;�_���v�\��	;safe

	;�X�^�b�N�|�C���^���[�h
	lss	esp,[cs:PM_stack_adr]

	mov	al,CPU_Fault		;�v���O���� �G���[�R�[�h�L�^
	jmp	END_program		;�v���O�����I��


;------------------------------------------------------------------------------
;���n�[�h�E�F�A���荞�� (INTR)
;------------------------------------------------------------------------------
%if (enable_INTR)

	align	4
intr_M0:	call	INTR_intM		;�}�X�^��
intr_Mtop:	db	90h,90h,90h
intr_M1:	call	INTR_intM
		db	90h,90h,90h
intr_M2:	call	INTR_intM
		db	90h,90h,90h
intr_M3:	call	INTR_intM
		db	90h,90h,90h
intr_M4:	call	INTR_intM
		db	90h,90h,90h
intr_M5:	call	INTR_intM
		db	90h,90h,90h
intr_M6:	call	INTR_intM
		db	90h,90h,90h
intr_M7:	call	INTR_intM
		db	90h,90h,90h

intr_S0:	call	INTR_intS		;�X���[�u��
intr_Stop:	db	90h,90h,90h
intr_S1:	call	INTR_intS
		db	90h,90h,90h
intr_S2:	call	INTR_intS
		db	90h,90h,90h
intr_S3:	call	INTR_intS
		db	90h,90h,90h
intr_S4:	call	INTR_intS
		db	90h,90h,90h
intr_S5:	call	INTR_intS
		db	90h,90h,90h
intr_S6:	call	INTR_intS
		db	90h,90h,90h
intr_S7:	call	INTR_intS
		db	90h,90h,90h

	;///////////////////////////////////////////////
	;�n�[�h�E�F�A���荞�݁i�}�X�^���j
	;///////////////////////////////////////////////
INTR_intM:
%if (INTR_MASTER > 1fh)
	push	eax
	mov	eax,[esp+4]				;�Ăь��A�h���X
	sub	eax,(offset intr_Mtop) - INTR_MASTER*8	;�擪�Ƃ̍�
							;   + INTR_number*8
	shr	eax,1					;eax = int�ԍ�*4
	mov	[esp+4],eax				;int�ԍ�*4 �L�^

	pop	eax			;eax ����
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��

%else	;*** CPU ���荞�݂Ɣ���Ă��� ******************
	push	eax
	push	edx

	mov	edx,[esp+8]
	sub	edx,offset intr_Mtop
	shr	edx,3			;edx = IRQ�ԍ�

	mov	al,0bh			;ISR �ǂݏo���R�}���h
	out	I8259A_ISR_M, al	;8259A �ɏ�������
	in	al, I8259A_ISR_M	;�T�[�r�X���W�X�^�ǂݏo��
	bt	eax,edx			;�n�[�h�E�F�G���荞�݁H
	jnc	.CPU_int		;bit �� 0 �Ȃ� CPU���荞��

	lea	eax,[edx*4 + INTR_MASTER*4]	;eax = INT�ԍ� *4
	mov	edx,[cs:intr_table + eax*2 +4]	;edx = �Ăяo��selector
	test	edx,edx				;0?
	jz	.dos_chain			;if 0 jmp

	;/// �o�^���Ă��銄�荞�݂��Ăяo�� ///
	mov	eax,[cs:intr_table + eax*2]	;offset

	mov	[esp+8],edx		;�Z���N�^
	xchg	[esp+4],eax		;eax ���� �� �I�t�Z�b�g�L�^
	pop	edx
	retf				;���荞�݃��[�`���Ăяo��


	align	4
.dos_chain:
	mov	[esp+8],eax		;�Ăяo��INT�ԍ��Ƃ��ċL�^
	pop	edx
	pop	eax
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��


	align	4
.CPU_int:
	lea	eax,[PM_int_00h +INTR_MASTER*8 + edx*8]	;CPU��O Address
	mov	[esp+8],eax				;�Z�[�u

	pop	edx
	pop	eax
	ret				;CPU ��O�Ăяo��
%endif

	;///////////////////////////////////////////////
	;�n�[�h�E�F�A���荞�݁i�X���[�u���j
	;///////////////////////////////////////////////
	align	4
INTR_intS:
%if (INTR_SLAVE > 1fh)
	push	eax
	mov	eax,[esp+4]				;�Ăь��A�h���X
	sub	eax,(offset intr_Stop) - INTR_SLAVE*8	;�A�h���X�� + INT�ԍ�
	shr	eax,1					;eax = int�ԍ�*4

	mov	[esp+4],eax		;int�ԍ�*4 �L�^
	pop	eax			;eax ����
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��

%else	;*** CPU ���荞�݂Ɣ���Ă��� ******************
	push	eax
	push	edx

	mov	edx,[esp+8]
	sub	edx,offset intr_Stop
	shr	edx,3			;edx = IRQ�ԍ� - 8

	mov	al,0bh			;ISR �ǂݏo���R�}���h
	out	I8259A_ISR_S, al	;8259A �ɏ�������
	in	al, I8259A_ISR_S	;�T�[�r�X���W�X�^�ǂݏo��
	bt	eax,edx			;�n�[�h�E�F�G���荞�݁H
	jnc	.CPU_int		;bit �� 0 �Ȃ� CPU���荞��

	lea	eax,[edx*4 + INTR_SLAVE*4]	;eax = INT�ԍ� *4
	mov	edx,[cs:intr_table + eax*2 +4]	;edx = �Ăяo��selector
	test	edx,edx				;0?
	jz	.dos_chain			;if 0 jmp

	;/// �o�^���Ă��銄�荞�݂��Ăяo�� ///
	mov	eax,[cs:intr_table + eax*2]	;offset

	mov	[esp+8],edx		;�Z���N�^
	xchg	[esp+4],eax		;eax ���� �� �I�t�Z�b�g�L�^
	pop	edx
	retf				;���荞�݃��[�`���Ăяo��


	align	4
.dos_chain:
	mov	[esp+8],eax		;�Ăяo��INT�ԍ��Ƃ��ċL�^
	pop	edx
	pop	eax
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��


	align	4
.CPU_int:
	lea	eax,[PM_int_00h + INTR_SLAVE*8 + edx*8]	;CPU��O Address
	mov	[esp+8],eax

	pop	edx
	pop	eax
	ret			;CPU ��O�Ăяo��
%endif
%endif

;//////////////////////////////////////////////////////////////////////////////
;�����荞�݃T�[�r�X
;//////////////////////////////////////////////////////////////////////////////

%include	"int_dos.asm"		;DOS ���荞�ݏ���
%include	"int_dosx.asm"		;DOS-Extender ���荞�ݏ���
%include	"int_f386.asm"		;Free386 �I���W�i�� API

;//////////////////////////////////////////////////////////////////////////////
;�����荞�݃f�[�^��
;//////////////////////////////////////////////////////////////////////////////

%include	"int_data.asm"		;���荞�݃e�[�u���Ȃ�

;//////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////////////////
