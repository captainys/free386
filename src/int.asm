;******************************************************************************
;�@Free386	���荞�ݏ������[�`��
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"

%include	"start.inc"
%include	"free386.inc"

%include	"sub32.inc"
%include	"memory.inc"
%include	"selector.inc"
%include	"call_v86.inc"

;//////////////////////////////////////////////////////////////////////////////
;���O���[�o���V���{���錾
;//////////////////////////////////////////////////////////////////////////////

global		PM_int_00h
global		PM_int_dummy
global		DOS_int_list
global		int21h_table

global		HW_INT_TABLE_M
global		HW_INT_TABLE_S

;******************************************************************************
segment	text32 class=CODE align=4 use32
;******************************************************************************
;//////////////////////////////////////////////////////////////////////////////
;�����荞�ݏ������[�`��
;//////////////////////////////////////////////////////////////////////////////
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

	xchg	[esp], ebx		;ebx����
%if INT_HOOK
	call	register_dump_from_int
%endif
	; stack top is int number
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
		int	3
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
	push	ds
	push	eax	; for register_dump_fault
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
	call	register_dump_fault	;�_���v�\��

	;�X�^�b�N�|�C���^���[�h
	lss	esp,[cs:PM_stack_adr]

	mov	al,CPU_Fault		;�v���O���� �G���[�R�[�h�L�^
	jmp	exit_32			;�v���O�����I��


;------------------------------------------------------------------------------
;���n�[�h�E�F�A���荞�� (INTR)
;------------------------------------------------------------------------------
	align	4
HW_INT_TABLE_M:	push	byte 0
		jmp	short INTR_intM
		push	byte 1
		jmp	short INTR_intM
		push	byte 2
		jmp	short INTR_intM
		push	byte 3
		jmp	short INTR_intM
		push	byte 4
		jmp	short INTR_intM
		push	byte 5
		jmp	short INTR_intM
		push	byte 6
		jmp	short INTR_intM
		push	byte 7
		; jmp	short INTR_intM

	;///////////////////////////////////////////////
	;�n�[�h�E�F�A���荞�݁i�}�X�^���j
	;///////////////////////////////////////////////
INTR_intM:
%ifdef USE_VCPI_8259A_API
	push	eax
	mov	al, [cs:vcpi_8259m]
	add	[esp+4], al
	pop	eax
	jmp	call_V86_HARD_int

%elif (HW_INT_MASTER > 1fh)
	add	b [esp], HW_INT_MASTER
	jmp	call_V86_HARD_int

%else	;*** CPU ���荞�݂Ɣ���Ă��� ******************
	push	edx
	push	eax

	mov	edx,[esp+8]		; load IRQ number

	mov	al,0bh			; read ISR
	out	I8259A_ISR_M, al	;
	in	al, I8259A_ISR_M	; read DATA
	bt	eax,edx			; �n�[�h�E�F�G���荞�݁H
	jnc	.CPU_int		; bit �� 0 �Ȃ� CPU���荞��

	add	edx, HW_INT_MASTER		; edx = INT�ԍ�
	mov	eax,[cs:intr_table + edx*8 +4]	; edx = �Ăяo����selector
	test	eax,eax				;0?
	jz	.dos_chain			;if 0 jmp

	;/// �o�^���Ă��銄�荞�݂��Ăяo�� ///
	mov	edx,[cs:intr_table + edx*8]	;offset

	mov	[esp+8],eax		;�Z���N�^
	xchg	[esp+4],edx		;eax ���� �� �I�t�Z�b�g�L�^
	pop	eax
	retf				;���荞�݃��[�`���Ăяo��


	align	4
.dos_chain:
	mov	[esp+8],edx		;�Ăяo��INT�ԍ��Ƃ��ċL�^
	pop	eax
	pop	edx
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��


	align	4
.CPU_int:
	lea	eax,[PM_int_00h + HW_INT_MASTER*8 + edx*8]	;CPU��O�̃A�h���X
	mov	[esp+8],eax					;�Z�[�u

	pop	eax
	pop	edx
	ret				;CPU ��O�Ăяo��
%endif

	;///////////////////////////////////////////////
	;�n�[�h�E�F�A���荞�݁i�X���[�u���j
	;///////////////////////////////////////////////
	align	4
HW_INT_TABLE_S:	push	byte 0
		jmp	short INTR_intS
		push	byte 1
		jmp	short INTR_intS
		push	byte 2
		jmp	short INTR_intS
		push	byte 3
		jmp	short INTR_intS
		push	byte 4
		jmp	short INTR_intS
		push	byte 5
		jmp	short INTR_intS
		push	byte 6
		jmp	short INTR_intS
		push	byte 7
		; jmp	short INTR_intS

INTR_intS:
%ifdef USE_VCPI_8259A_API
	push	eax
	mov	al, [cs:vcpi_8259s]
	add	[esp+4], al
	pop	eax
	jmp	call_V86_HARD_int

%elif (HW_INT_SLAVE > 1fh)
	add	b [esp], HW_INT_SLAVE
	jmp	call_V86_HARD_int

%else	;*** CPU ���荞�݂Ɣ���Ă��� ******************
	push	edx
	push	eax

	mov	edx,[esp+8]		;edx = IRQ�ԍ� - 8

	mov	al,0bh			;ISR �ǂݏo���R�}���h
	out	I8259A_ISR_S, al	;8259A �ɏ�������
	in	al, I8259A_ISR_S	;�T�[�r�X���W�X�^�ǂݏo��
	bt	eax,edx			;�n�[�h�E�F�G���荞�݁H
	jnc	.CPU_int		;bit �� 0 �Ȃ� CPU���荞��

	add	edx, HW_INT_SLAVE		; edx = INT�ԍ�
	mov	eax,[cs:intr_table + edx*8 +4]	; edx = �Ăяo����selector
	test	eax,eax				;0?
	jz	.dos_chain			;if 0 jmp

	;/// �o�^���Ă��銄�荞�݂��Ăяo�� ///
	mov	edx,[cs:intr_table + edx*8]	;offset

	mov	[esp+8],eax		;�Z���N�^
	xchg	[esp+4],edx		;eax ���� �� �I�t�Z�b�g�L�^
	pop	eax
	retf				;���荞�݃��[�`���Ăяo��


	align	4
.dos_chain:
	mov	[esp+8],edx		;�Ăяo��INT�ԍ��Ƃ��ċL�^
	pop	eax
	pop	edx
	jmp	call_V86_HARD_int	;V86 ���[�`���R�[��


	align	4
.CPU_int:
	lea	eax,[PM_int_00h + HW_INT_SLAVE*8 + edx*8]	;CPU��O�̃A�h���X
	mov	[esp+8],eax					;�Z�[�u

	pop	eax
	pop	edx
	ret				;CPU ��O�Ăяo��
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
segment	data class=DATA align=4

%include	"int_data.asm"		;���荞�݃e�[�u���Ȃ�

;//////////////////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////////////////
