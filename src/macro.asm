;******************************************************************************
;�@Free386 macro
;******************************************************************************
;
;
%imacro	PRINT86	1
	mov	dx,%1
	mov	ah,09h
	int	21h
%endmacro

%imacro	PRINT	1
	mov	edx,%1
	mov	ah,09h
	int	21h
%endmacro

%imacro	PRINT_	1
	push	eax
	push	edx
	mov	edx,%1
	mov	ah,09h
	int	21h
	pop	edx
	pop	eax
%endmacro

%imacro	PRINT_crlf	0
	mov	ah,02h
	mov	dl,13
	int	21h
	mov	dl,10
	int	21h
%endmacro

%imacro	Program_end	1	;***** �v���Z�X�I�� *****
	mov	ah,4ch
	mov	al,%1
	int	21h	;�I��
%endmacro

%imacro getvecter	0	;�x�N�^�A�h���X�擾 > ES:BX
	mov	ah,35h
	mov	al,Interrupt_No	;��`�� Int �ԍ�
	int	21h
%endmacro

%imacro	setvecter	0	;�x�N�^�A�h���X�ݒ� < DS:DX
	mov	ah,25h
	mov	al,Interrupt_No	;��`�� Int �ԍ�
	int	21h
%endmacro

;******************************************************************************
;��F386 ��p�}�N��
;******************************************************************************
;------------------------------------------------------------------------------
;�EXMS Driver �� call ����}�N��
;------------------------------------------------------------------------------
%macro	XMS_function	0
	call	far [XMS_entry]		;XMS far call
%endmacro


;------------------------------------------------------------------------------
;�EF386 �̃v���e�N�g���[�h���I��������
;------------------------------------------------------------------------------
%macro	F386_end	1
	mov	b [f386err],%1		;�G���[�ԍ��L�^
	jmp	END_program
%endmacro

;------------------------------------------------------------------------------
;�E�v���e�N�g���[�h ���� VCPI ���Ăяo���}�N��
;------------------------------------------------------------------------------
%macro	VCPI_function	0
	callf	[VCPI_entry]		;VCPI far call
%endmacro

;------------------------------------------------------------------------------
;�EV86 �� int �𔭌�����}�N��
;------------------------------------------------------------------------------
%macro	V86_INT	1
	pushf
	push	cs
	push	d (offset .ret_label)
	push	d %1*4			;int�ԍ� *4
	jmp	call_V86_int

	align	4
.ret_label
%endmacro

%macro	V86_INT_21h	0
	pushf
	push	cs
	call	call_V86_int21
%endmacro

;------------------------------------------------------------------------------
;�EV86 ����̊��荞�݂𔻕ʂ���}�N���i���g�p / VCPI���p���͕s�v�j
;------------------------------------------------------------------------------
;%macro	check_int_from_V86	0
;	test	b [esp+10],02h		;+08h �ɂ��� EFLAGS �� VM�r�b�g
;	jnz	near int_from_V86	;V86���[�h����̊��荞�ݐ�p���[�`����
;%endmacro

;------------------------------------------------------------------------------
;�E�L�����[�N���A & �L�����[�Z�b�g
;------------------------------------------------------------------------------
%imacro	set_cy	0	;Carry set
	or	b [esp+8], 01h	;Carry �Z�b�g
%endmacro

%imacro	clear_cy 0	;Carry reset
	and	b [esp+8],0feh	;Carry �N���A
%endmacro

save_cy:	;
cy_save:	;��A�h�~�[�u
cy_set:		;
cy_clear:	;

;------------------------------------------------------------------------------
;�E�L�����[�̏�Ԃ��Z�[�u���� iret ����}�N��
;------------------------------------------------------------------------------
%imacro	iret_save_cy	0	;Cy ���Z�[�u�� iretd ����
	jc	.__set_cy
	clear_cy
	iret
.__set_cy:
	set_cy
	iret
%endmacro

;------------------------------------------------------------------------------
;�EINT �Ăяo���̂悤�Ƀ��x���� call ����}�N��
;------------------------------------------------------------------------------
%imacro	calli	1	;Cy ���Z�[�u�� iretd ����
	pushf
	push	cs
	call	%1
%endmacro

;------------------------------------------------------------------------------
;�EF386_ds�����[�h����
;------------------------------------------------------------------------------
%imacro	LOAD_F386_ds	0
	push	d F386_ds
	pop	ds
%endmacro

;------------------------------------------------------------------------------
;�E���W�X�^�_���v
;------------------------------------------------------------------------------
%imacro call_RegisterDump_with_code	1
	mov	d [dump_err_code], %1
	call	register_dump		;safe
%endmacro
;------------------------------------------------------------------------------
;�EINT�p���W�X�^�_���v
;------------------------------------------------------------------------------
%imacro call_RegisterDumpInt	1
%if INT_HOOK
	push	d %1
	call	register_dump_from_int	;safe
	mov	[esp], eax
	pop	eax
%endif
%endmacro

;******************************************************************************
;�f�B�o�O�p�}�N��
;******************************************************************************

%imacro	SPEED_N		0	;�f�B�o�O�p > �݊����[�h�ؑւ�
	push	dx
	push	ax
	mov	dx,5ech
	xor	al,al
	out	dx,al
	pop	ax
	pop	dx
%endmacro

%imacro		OFF_ON	0	;�f�B�o�O�p > �݊����[�h�ؑւ�
	push	eax
	push	edx

	mov	dx,5ech
	xor	al,al
	out	dx,al

	_WAIT	10

	mov	al,1
	out	dx,al

	_WAIT2	10

	pop	edx
	pop	eax
%endmacro


%imacro	_WAIT	1
	push	eax
	push	ecx
	push	edx
	mov	dx,5ech
	mov	al,0
	out	dx,al

	xor	eax,eax
	mov	ecx,%1
	mov	edx,4000
.wa.lp:
	in	ax,26h
	cmp	eax,edx
	ja	.wa.lp
.wa.lp2:
	in	ax,26h
	cmp	eax,edx
	jbe	.wa.lp2
	loop	.wa.lp

	mov	dx,5ech
	mov	al,1
	out	dx,al
	mov	ecx,%1
	mov	edx,4000
.wa.lp3:
	in	ax,26h
	cmp	eax,edx
	ja	.wa.lp3
.wa.lp4:
	in	ax,26h
	cmp	eax,edx
	jbe	.wa.lp4
	loop	.wa.lp3

	pop	edx
	pop	ecx
	pop	eax
%endmacro


%macro	FAULT	0	;�f�B�o�O�p / �������ی�G���[
	mov	[offset -1],eax
%endmacro


