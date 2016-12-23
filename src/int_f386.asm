;******************************************************************************
;�@Free386	Free386 �I���W�i���T�[�r�X���[�`��
;******************************************************************************
;[TAB=8]
;
; 2001/02/27	�쐬�J�n
;
BITS	32

	public	setup_F386_int

;******************************************************************************
;�EFree386 �I���W�i���t�@���N�V�����̃Z�b�g�A�b�v
;******************************************************************************
	align	4
setup_F386_int:
	mov	cl,F386_INT			;���荞�ݔԍ�
	mov	edx,offset Free386_function	;���荞�݃t�@���N�V����

	push	ds
	push	cs
	pop	ds				;ds:edx = �G���g���|�C���g
	mov	ax,2504h			;���荞�݂̐ݒ�
	int	21h				;DOS-Extender call

	mov	cl,INT_REGDUMP			;���荞�ݔԍ�
	mov	edx,offset regdump_function	;���W�X�^dump�T�[�r�X
	mov	ax,2504h			;���荞�݂̐ݒ�
	int	21h				;DOS-Extender call

	pop	ds				;ds ����
	ret


;******************************************************************************
;��Free386 �I���W�i���t�@���N�V����
;******************************************************************************
	align	4
Free386_function:
	push	eax			;

	cmp	ah,F386_MAX_func	;�e�[�u���ő�l
	jae	.no_func		;����ȏ�Ȃ� jmp

	movzx	eax,ah				;�@�\�ԍ�
	mov	eax,[cs:F386fn_table + eax*4]	;�W�����v�e�[�u���Q��

	xchg	[esp],eax		;eax���� & �W�����v��L�^
	ret				;�e�[�u���W�����v

;------------------------------------------------------------------------------
;�E���m�̃t�@���N�V����
;------------------------------------------------------------------------------
	align	4
.no_func:		;���m�̃t�@���N�V����
F386fn_unknown:
	set_cy		;Cy =1
	iret


;------------------------------------------------------------------------------
;�E���Ή��t�@���N�V�������X�g
;------------------------------------------------------------------------------
	align	4
F386fn_02h:
F386fn_03h:
F386fn_04h:
F386fn_05h:
F386fn_06h:
F386fn_07h:

F386fn_08h:
F386fn_09h:
F386fn_0ah:
F386fn_0bh:
F386fn_0ch:
F386fn_0dh:
F386fn_0eh:
F386fn_0fh:

F386fn_12h:
F386fn_13h:
F386fn_14h:
F386fn_15h:
F386fn_16h:
F386fn_17h:
	set_cy		;Cy =1
	iret


;//////////////////////////////////////////////////////////////////////////////
;�����擾�t�@���N�V����
;//////////////////////////////////////////////////////////////////////////////
;------------------------------------------------------------------------------
;�EFree386 �o�[�W�������̎擾 ah=00h
;------------------------------------------------------------------------------
	align	4
F386fn_00h:
	mov	al,Major_ver	;Free386 ���W���o�[�W����
	mov	ah,Minor_ver	;Free386 �}�C�i�[�o�[�W����
	mov	ebx,F386_Date	;���t
	mov	ecx,0		;reserved
	mov	edx,' ABK'	;for Free386 check
	iret

;------------------------------------------------------------------------------
;�E�@��R�[�h�擾 ah=01h
;------------------------------------------------------------------------------
	align	4
F386fn_01h:
	mov	eax,MACHINE_CODE	;�@��R�[�h
	iret




;//////////////////////////////////////////////////////////////////////////////
;���g��API�t�@���N�V����
;//////////////////////////////////////////////////////////////////////////////
;------------------------------------------------------------------------------
;���W��API �̃��[�h ah=10h
;------------------------------------------------------------------------------
	align	4
F386fn_10h:
	pusha
	push	ds
	push	es

	push	d (DOSENV_sel)
	push	d (F386_ds)
	pop	ds
	pop	es
	xor	esi,esi
	mov	edi,[work_adr]	;���[�N�A�h���X

	align	4
.search:mov	al,[es:esi]	;���[�h
	inc	esi		;�|�C���^�X�V
	test	al,al		;�l�`�F�b�N
	jnz	.search
	mov	al,[es:esi]	;���[�h
	inc	esi		;�|�C���^�X�V
	test	al,al		;�l�`�F�b�N
	jnz	.search
	
	;es:esi ���̈�̏I���
	add	esi,byte 2	;�t�@�C����

	align	4
.cpy:	mov	al,[es:esi]	;�N���t�@�C���̐��PATH�R�s�[
	mov	[edi],al	;
	inc	esi
	inc	edi
	test	al,al
	jnz	.cpy

	;�p�X�����̂ݎ��o��
.srch2:	dec	edi
	cmp	b [edi],'\'
	jne	.srch2
	inc	edi

	;�t�@�C������A������
	mov	esi,offset default_API	;�W��API�̃t�@�C����
.cpy2:	mov	al,[esi]
	mov	[edi],al
	inc	esi
	inc	edi
	test	al,al
	jnz	.cpy2

	mov	edx,[work_adr]	;�t�@�C���� (ASCIIz)
	mov	esi,edx		;�o�b�t�@�A�h���X
	call	load_exp
	jc	.error

	push	ds
	mov	[_esp],esp	;ss:esp �̐ݒ�
	mov	[_ss] ,ss	;
	jmp	run_exp		;API �����ݒ胋�[�`���̎��s

	align	4
.error:	pop	es
	pop	ds
	popa
	set_cy
	iret


;------------------------------------------------------------------------------
;�����[�h����API����̕��A ah=11h
;------------------------------------------------------------------------------
	align	4
F386fn_11h:
	cmp	d [cs:_ss],0		;�Z�[�u���Ă���X�^�b�N�̒l�m�F
	je	.error

	lss	esp,[cs:stack_pointer]	;�X�^�b�N���A
	pop	ds

	mov	d [_ss],0		;ss ���N���A
	pop	es
	pop	ds
	popa
	clear_cy
	iret


	align	4
.error:	set_cy				;�v���O�������[�h���łȂ�
	iret

;******************************************************************************
;�����W�X�^�_���v�T�[�r�X (int 0ffh)
;******************************************************************************
	align	4
regdump_function:
	call	register_dump		;safe
	iret

