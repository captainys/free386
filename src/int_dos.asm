;******************************************************************************
;�@Free386	���荞�ݏ������[�`�� / DOS ����[�`��
;******************************************************************************
;
; 2001/01/18 �t�@�C���𕪗�
;
;
BITS	32
;==============================================================================
;��DOS ���荞��  int 20-2F
;==============================================================================
;------------------------------------------------------------------------------
;�Eint 20h / �v���O�����̏I��
;------------------------------------------------------------------------------
	align	4
PM_int_20h:
	call_RegisterDumpInt	20h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 22h / �I���A�h���X
;------------------------------------------------------------------------------
;�@�v���O�������I������Ƃ����s���ڂ��A�h���X���L�^���Ă���x�N�^�B
;�@����ł́Aint 21h / AH=4ch �Ƀ`�F�C��
;
	align	4
PM_int_22h:
	call_RegisterDumpInt	22h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 23h / CTRL-C �E�o�A�h���X
;------------------------------------------------------------------------------
	align	4
PM_int_23h:
	call_RegisterDumpInt	23h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 24h / �v���I�G���[���f�A�h���X
;------------------------------------------------------------------------------
	align	4
PM_int_24h:
	call_RegisterDumpInt	24h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 25h / �����Z�N�^�ǂݍ���
;------------------------------------------------------------------------------
	align	4
PM_int_25h:
	call_RegisterDumpInt	25h
	iret

;------------------------------------------------------------------------------
;�Eint 26h / �����Z�N�^��������
;------------------------------------------------------------------------------
	align	4
PM_int_26h:
	call_RegisterDumpInt	26h
	iret

;------------------------------------------------------------------------------
;�Eint 27h / �v���O�����̏풓�I��
;------------------------------------------------------------------------------
	align	4
PM_int_27h:
	call_RegisterDumpInt	27h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 28h / �R���\�[�����͎��ɌĂ΂��A�C�h�����[�`��
;------------------------------------------------------------------------------
	align	4
PM_int_28h:
	call_RegisterDumpInt	28h
	iret

;------------------------------------------------------------------------------
;�Eint 29h / �����R���\�[���o��
;------------------------------------------------------------------------------
;	AL = �o�̓R�[�h
	align	4
PM_int_29h:
	call_RegisterDumpInt	29h
	push	d 29h			; �x�N�^�ԍ�
	jmp	call_V86_int		; V86 ���荞�݃��[�`���Ăяo��

;------------------------------------------------------------------------------
;�Eint 2ah / MS-Networks NETBIOS
;�Eint 2bh / DOS reserved
;�Eint 2ch / DOS reserved
;�Eint 2dh / DOS reserved
;------------------------------------------------------------------------------
	align	4
PM_int_2ah:
PM_int_2bh:
PM_int_2ch:
PM_int_2dh:
	iret

;------------------------------------------------------------------------------
;�Eint 2eh / shell(command.com)�����s
;------------------------------------------------------------------------------
	align	4
PM_int_2eh:
	call_RegisterDumpInt	2eh
	iret

;------------------------------------------------------------------------------
;�Eint 2fh / DOS ����Jfunction
;------------------------------------------------------------------------------
	align	4
PM_int_2fh:
	call_RegisterDumpInt	2fh
	push	d 2fh			;�x�N�^�ԍ�
	jmp	call_V86_int		;V86 ���荞�݃��[�`���Ăяo��


;******************************************************************************
;�Eint 21h / DOS function & DOS-Extender function
;******************************************************************************
;------------------------------------------------------------------------------
;�Eint 21h / ��T�|�[�g
;------------------------------------------------------------------------------
	align	4
int_21h_notsupp:
	set_cy		;�G���[�ɐݒ�
	iret

;------------------------------------------------------------------------------
;�Eint 21h / ���m��function
;------------------------------------------------------------------------------
	align	4
int_21h_unknown:
 	jmp	call_V86_int21

;==============================================================================
;�Eint 21h / �e�[�u���W�����v����
;==============================================================================
proc PM_int_21h
	call_RegisterDumpInt	21h

    %if (int_21h_MAXF < 0ffh)
	cmp	ah,int_21h_MAXF		;�e�[�u���ő�l
	ja	int_21h_unknown		;����ȏ�Ȃ� jmp
    %endif
	cld				;�����t���O�N���A
	push	eax			;

	movzx	eax,ah				;�@�\�ԍ�
	mov	eax,[cs:int21h_table + eax*4]	;�W�����v�e�[�u���Q��

	;------------------------------------------
	;int 21h �̂ݖ߂�l���o��
	;------------------------------------------
	%if INT_HOOK && INT_HOOK_RETV
		push	cs			; cs
		push	d offset .call_retern	; EIP
		pushf				; jump address
		xchg	[esp], eax		;eax=eflags, [esp]=jump address
		xchg	[esp+12], eax		;[esp+8]=eflags, eax=original eax
		ret				; �e�[�u���W�����v
	align 4
	.call_retern:
		;save_cy
		jc	.set_cy
		clear_cy
		jmp	short .saved
	.set_cy:
		set_cy
	.saved:
		call_RegisterDumpInt	-2
		iret
	%endif

.normal_call:
	;------------------------------------------
	;�ʏ�Ăяo��
	;------------------------------------------
	xchg	[esp],eax	;eax���� & �W�����v��L�^
	ret			; table jump


;------------------------------------------------------------------------------
;�y�ėp�zDS:EDX�� NULL �ŏI��镶����
;------------------------------------------------------------------------------
	align	4
int_21h_ds_edx:
	push	ds
	push	es
	push	edx

	push	d (F386_ds)		;F386 ds
	pop	es			;es �� load

	push	eax

	call	get_gp_buffer_32
	test	eax, eax
	jz	.error

	;------------------------------------------------------------
	;�����̃R�s�[
	;------------------------------------------------------------
	pushad
	mov	edi, eax
	mov	ecx,(GP_BUFFER_SIZE /4)-1	;�]���ő�T�C�Y /4
	mov	ebp,4				;�A�h���X���Z�l
	mov	b [es:edi + ecx*4], 00h

	align	4
.loop:
	mov	eax,[edx]
	mov	[es:edi],eax
	test	al,al
	jz	short .exit
	test	ah,ah
	jz	short .exit
	shr	eax,16			;��ʁ����ʂ�
	test	al,al
	jz	short .exit
	test	ah,ah
	jz	short .exit
	add	edx,ebp		;+4
	add	edi,ebp		;+4
	loop	.loop
.exit:
	popad

	mov	edx, eax	; edx <- GP buffer address
	xchg	[esp], eax	; recovery eax
	calli	call_V86_int21

	xchg	[esp], eax	; eax <- GP buffer address
	call	free_gp_buffer_32
	pop	eax

	pop	edx
	pop	es
	pop	ds
	iret_save_cy		;�L�����[�Z�[�u & iret

.error:
	pop	eax
	pop	edx
	pop	es
	pop	ds
	clear_cy
	iret

;------------------------------------------------------------------------------
;�E������o��  AH=09h
;------------------------------------------------------------------------------
	align	4
int_21h_09h:
%if PRINT_TO_FILE
	jmp	int_21h_09h_output_file
%else
	cmp	d [cs:call_buf_used], 0		; check call buffer status
	je	.skip
	iret
.skip:
	; PRINT_TSUGARU �͒Ìy�ł͂Ȃ����Ŏ��s���A
	; �ʏ�̕�����o�͂��s���B
	; �Ìy���� jmp �e�[�u����������������B

	push	ds
	push	es
	push	edx

	push	d (F386_ds)
	pop	es

	mov	d [es:call_buf_used], 1	; use call buffer

	; copy string
	pushad
	mov	edi,[es:call_buf_adr32]
	mov	ecx,[es:call_buf_size]
	shr	ecx, 2			; ecx = buffer size /4
	xor	ebx, ebx

	align	4
.loop:
	mov	eax, [edx + ebx]	; copy [ds:edx]
	mov	[es:edi + ebx], eax	;   to [es:edi]
	cmp	al,'$'
	jz	short .exit
	cmp	ah,'$'
	jz	short .exit
	shr	eax,16
	cmp	al,'$'
	jz	short .exit
	cmp	ah,'$'
	jz	short .exit
	add	ebx, b 4
	loop	.loop
.exit:
	mov	b [es:edi + ecx*4 -1], '$'	; safety
	popad

	mov	edx, [es:call_buf_adr32]
	calli	call_V86_int21

	mov	d [es:call_buf_used], 0

	pop	edx
	pop	es
	pop	ds
	iret_save_cy		;�L�����[�Z�[�u & iret
%endif

;------------------------------------------------------------------------------
;�y�f�o�b�O�z������o�͂������I�Ƀt�@�C���o��  AH=09h
;------------------------------------------------------------------------------
%if PRINT_TO_FILE

proc int_21h_09h_output_file
	; �����t�@�C���o��
	pushad
	push	ds
	push	es

	mov	eax, F386_ds
	mov	ds, eax

	; file open
	push	edx
	mov	al, 0001_0010b
	mov	ah, 3dh
	mov	edx, offset .file
	calli	call_V86_int21
	pop	edx
	jc	.exit

	mov	ebx, eax	; bx = handle

	; file seek
	push	edx
	mov	al, 02h
	mov	ah, 42h
	xor	ecx,ecx
	xor	edx,edx
	calli	call_V86_int21
	pop	edx

	; get buffer
	call	get_gp_buffer_32
	mov	ebp, eax
	test	eax, eax
	jz	.exit

	mov	es,[esp+4]	; original ds
	mov	esi, edx
	mov	edi, ebp
	mov	edx, edi
	xor	ecx, ecx
.loop:
	mov	al, [es:esi]
	mov	[edi], al
	cmp	al, '$'
	jz	short .loop_end
	inc	esi
	inc	edi
	inc	ecx
	cmp	ecx, GP_BUFFER_SIZE
	jnz	short .loop
.loop_end:
	; write
	mov	ah, 40h
	calli	call_V86_int21

	; close
	mov	ah, 3eh
	calli	call_V86_int21

	; free buffer
	mov	eax, ebp
	call	free_gp_buffer_32

.exit:
	pop	es
	pop	ds
	popad
	iret

.file	db	DUMP_FILE,0
%endif

;------------------------------------------------------------------------------
; [Debug] Output to Tsugaru console  AH=09h
;------------------------------------------------------------------------------
%if PRINT_TSUGARU

proc int_21h_09h_output_tsugaru
	pushad
	push	ds
	push	es

	mov	eax, F386_ds
	mov	ds, eax
	mov	es,[esp+4]	; original ds

	; get buffer
	call	get_gp_buffer_32
	mov	ebx, eax
	test	eax, eax
	jz	.exit

	mov	esi, edx
	mov	edi, ebx
	xor	ecx, ecx
.loop:
	mov	al, [es:esi]
	mov	[edi], al
	cmp	al, '$'
	jz	short .loop_end
	inc	esi
	inc	edi
	inc	ecx
	cmp	ecx, GP_BUFFER_SIZE-1
	jb	short .loop
.loop_end:
	mov	[edi], byte 0
	cmp	w [edi-2], 0a0dh
	mov	b [edi-1], 0

	; output for Tsugaru API
	mov	dx, 2f18h
	mov	al, 09h
	out	dx, al

	; free buffer
	mov	eax, ebx
	call	free_gp_buffer_32

.exit:
	pop	es
	pop	ds
	popad
	iret

%endif

;------------------------------------------------------------------------------
;�E�o�b�t�@�t���W��1�s����  AH=0ah
;------------------------------------------------------------------------------
;	ds:edx	input buffer(special format)
;
	align	4
int_21h_0ah:
	pushad
	push	es
	push	ds

	mov	esi,F386_ds
	mov	 es,esi

	push	eax
	call	get_gp_buffer_32
	mov	ebp, eax		; save gp buffer address
	test	eax, eax
	pop	eax
	jz	.exit

	mov	esi, edx		; esi <- caller buffer
	mov	edi, ebp		; edi <- gp buffer
	movzx	ecx, b [edi]		; ecx = maximum characters
	add	ecx, b 2
	rep	movsb			; copy [ds:esi] -> [es:edi]

	push	edx
	mov	edx, ebp		; ds:edx is gp buffer
	calli	call_V86_int21
	pop	edx

	; edx = caller buffer
	; ebp = gp buffer
	push	ds			; exchange ds<>es
	mov	eax,  es
	mov	 ds, eax		; ds = F386 ds
	pop	es			; es = caller selector

	mov	esi, ebp		; [ds:esi] gp buffer
	mov	edi, edx		; [es:edi] caller buffer
	movzx	ecx,b [esi]		; ecx = maximum characters
	add	ecx,b 2			; ecx is buffer size
	rep	movsb			; copy [ds:esi] -> [es:edi]

	mov	eax, ebp
	call	free_gp_buffer_32

.exit:
	pop	ds
	pop	es
	popad
	iret



;------------------------------------------------------------------------------
;�E�J�����g�^�C�� �h���C�u�̃h���C�u�f�[�^�擾  AH=1bh/1ch
;------------------------------------------------------------------------------
	align	4
int_21h_1bh:
int_21h_1ch:
	push	esi

	xor	ebx,ebx			;ebx ���16bit �N���A
	calli	call_V86_int21		;DS:BX = FAT-ID �A�h���X

	mov	esi,[cs:call_V86_ds]	;real ds
	shl	esi, 4			;�Z�O�����g��16�{ (para -> byte)
	add	ebx,esi			;ebx = FAT:ID �x�[�X�A�h���X
	push	d (DOSMEM_sel)		;DOS�������A�N�Z�X�Z���N�^
	pop	ds			;ds �ɐݒ�

	pop	esi
	iret


;------------------------------------------------------------------------------
;�E�f�B�X�N�]���A�h���X�ݒ�  AH=1ah
;------------------------------------------------------------------------------
	align	4
int_21h_1ah:
	push	es
	push	d (F386_ds)
	pop	es

	mov	[es:DTA_off],edx	;offset
	mov	[es:DTA_seg],ds		;segment

	;*** �t�@���N�V�����R�[����]���@�\�t���ɍ����ւ� ***
	mov	d [es:int21h_table+4eh*4],offset int_21h_4eh
	mov	d [es:int21h_table+4fh*4],offset int_21h_4fh

	pop	es
	iret

;------------------------------------------------------------------------------
;�E�f�B�X�N�]���A�h���X�擾  AH=2fh
;------------------------------------------------------------------------------
	align	4
int_21h_2fh:
	mov	ebx, [cs:DTA_off]
	mov	es , [cs:DTA_seg]	;DTA �̌��ݒl
	iret

;------------------------------------------------------------------------------
;�E�풓�I��  AH=31h
;------------------------------------------------------------------------------
	align	4
int_21h_31h:			;���Ή��̋@�\
	jmp	int_21h_4ch

;------------------------------------------------------------------------------
;�E���ʏ��̎擾�^�ݒ�  AH=38h
;------------------------------------------------------------------------------
	align	4
int_21h_38h:
	cmp	dx,-1
	je	near call_V86_int21	; �ݒ�Ȃ� jmp

	;------------------------------------------------------------
	; read 
	;------------------------------------------------------------
	push	edx
	push	edi
	push	esi

	push	eax
	call	get_gp_buffer_32
	mov	esi, eax		;esi = GP buffer
	pop	eax

	test	esi, esi
	jz	short .error

	mov	edi, edx		;edi = �v���O�������o�b�t�@
	mov	edx, esi		;�o�b�t�@�A�h���X
	calli	call_V86_int21		;int 21h ���荞�ݏ������[�`���Ăяo��
	jc	short .error2

	;------------------------------------------------------------
	; copy es:[edx] to ds:[edi]
	;------------------------------------------------------------
	push	ecx
	push	es
	mov	ecx, F386_ds
	mov	 es, ecx

	mov	cl, 32			;32 byte
	align	4
.loop:	mov	ch,[es:edx]		;1 byte
	mov	[edi],ch		;  copy
	inc	edx			;
	inc	edi			;
	dec	cl
	jnz	short .loop

	pop	es
	pop	ecx

	mov	eax, esi
	call	free_gp_buffer_32

	pop	esi
	pop	edi
	pop	edx
	clear_cy
	iret

.error2:
	mov	eax, esi
	call	free_gp_buffer_32

.error:	pop	esi
	pop	edi
	pop	edx
	set_cy
	iret

;------------------------------------------------------------------------------
;�E�t�@�C���̓ǂݍ���  AH=3fh
;------------------------------------------------------------------------------
	align	4
int_21h_3fh:
	cmp	d [cs:call_buf_used], 0	; check call buffer status
	je	.skip
	xor	eax, eax
	set_cy
	iret
.skip:

	push	edx
	push	esi
	push	edi
	push	ebp
	push	es
	push	ds
	push	ecx	;�X�^�b�N�Q�ƒ���

	mov	esi,F386_ds		;DS
	mov	ds,esi			;DS ���[�h
 	mov	es,[esp+4]		;�ǂݍ��ݐ�

	mov	d [call_buf_used], 1	; save call buffer flag

	mov	edi,edx			;�f�[�^��  es:edi �֓ǂݍ���
	mov	edx,ecx			;edx = �c��]���o�C�g��
	mov	ebp,[call_buf_size]	;ebp = �o�b�t�@�T�C�Y

	cmp	edx,ebp			;�c��Ƃ��r
	jbe	.last			;�ȉ��Ȃ�W�����v

	align	4	;-------------------------
.loop:
	xor	eax,eax
	mov	ah,3fh			;File Read (dos function)

	push	edx		;�ޔ�
	mov	edx,[call_buf_adr32]	;�ǂݏo���o�b�t�@
	mov	ecx,ebp			;�o�b�t�@�T�C�Y
	calli	call_V86_int21		;�t�@�C���ǂݍ���  / DOS call
	pop	edx
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �ǂݍ��񂾃o�C�g��
	mov	esi,[call_buf_adr32]	;�o�b�t�@�A�h���X���[�h
	sub	edx,ecx			;edx = �c��]���o�C�g��
	rep	movsb			;�ꊇ�]�� ds:esi -> es:edi

	cmp	eax,ebp			;�]���T�C�Y�Ǝ��ۂ̓]���ʔ�r
	jne	.end			;�Ⴆ�Γ]���I���i�ǂݏI�����j

	cmp	edx,ebp			;�c��ƃo�b�t�@�T�C�Y���r
	ja	short .loop		;�傫����� (edx > BUF_size) ���[�v

	align	4 ;--------------------------------
.last:
	mov	ah,3fh			;File Read (dos function)

	mov	ecx,edx			;ecx = �c��T�C�Y
	push	edx		;�ޔ�
	mov	edx,[call_buf_adr32]	;�ǂݏo���o�b�t�@
	calli	call_V86_int21		;�t�@�C���ǂݍ���  / DOS call
	pop	edx		;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �ǂݍ��񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��
	mov	esi,[call_buf_adr32]	;�o�b�t�@�A�h���X���[�h
	rep	movsb			;�ꊇ�]��

.end:
	mov	eax,[esp]		;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	mov	d [call_buf_used], 0	; clear call buffer flag

	pop	ecx
	pop	ds
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	clear_cy
	iret


	align	4
.error_exit:
	mov	d [call_buf_used], 0	; clear call buffer flag

	pop	ecx
	pop	ds
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	set_cy
	iret


;------------------------------------------------------------------------------
;�E�t�@�C���̏�������  AH=40h
;------------------------------------------------------------------------------
	align	4
int_21h_40h:
	cmp	d [cs:call_buf_used], 0	; check call buffer status
	je	.skip
	xor	eax, eax
	set_cy
	iret
.skip:
	push	edx
	push	esi
	push	edi
	push	ebp
	push	es
	push	ecx	;�X�^�b�N�Q�ƒ���

	mov	edi,F386_ds		;DS
	mov	es ,edi			;  es:edi �]����i�o�b�t�@�p�j
	mov	esi,edx			;  ds:esi �������݃f�[�^

	mov	d [es:call_buf_used], 1	; save call buffer flag

	mov	edx,ecx			;edx = �c��]���o�C�g��
	mov	ebp,[es:call_buf_size]	;ebp = �o�b�t�@�T�C�Y

	cmp	edx,ebp			;�c��ƃo�b�t�@�T�C�Y���r
	jbe	.last			;�ȉ��Ȃ�W�����v

	align	4	;-------------------------
.loop:
	mov	ah,40h			;File Read (dos function)

	mov	edi,[es:call_buf_adr32]	;�o�b�t�@�A�h���X���[�h
	mov	ecx,ebp			;ecx = �������񂾃o�C�g��
	rep	movsb			;�ꊇ�]��

	push	edx		;�ޔ�
	mov	edx,[es:call_buf_adr32]	;�������݃o�b�t�@
	mov	ecx,ebp			;�o�b�t�@�T�C�Y
	calli	call_V86_int21		;�t�@�C����������  / DOS call
	pop	edx		;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	eax,ax			;eax = �������񂾃o�C�g��
	sub	edx,eax			;�c��]���T�C�Y�������

	cmp	eax,ebp			;�]���T�C�Y�Ǝ��ۂ̓]���ʔ�r
	jne	.end			;�Ⴆ�Γ]���I���i�������ݏI�����j

	cmp	edx,ebp			;�c��ƃo�b�t�@�T�C�Y���r
	ja	.loop			;�o�b�t�@�T�C�Y���傫�������烋�[�v

	;----------------------------------------
.last:
	mov	ah,40h			;File Read (dos function)

	mov	edi,[es:call_buf_adr32]	;�o�b�t�@�A�h���X���[�h
	mov	ecx,edx			;ecx = �c��T�C�Y
	rep	movsb			;�ꊇ�]��

	mov	ecx,edx			;ecx = �c��T�C�Y
	push	edx		;�ޔ�
	mov	edx,[es:call_buf_adr32]	;�������݃o�b�t�@
	calli	call_V86_int21		;�t�@�C����������  / DOS call
	pop	edx		;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �������񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��

.end:
	mov	eax,[esp]		;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	mov	d [es:call_buf_used], 0	; clear call buffer flag

	pop	ecx
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	clear_cy
	iret

	align	4
.error_exit:
	mov	d [es:call_buf_used], 0	; clear call buffer flag

	pop	ecx
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	set_cy
	iret


;------------------------------------------------------------------------------
;�EIOCTRL  AH=44h
;------------------------------------------------------------------------------
	align	4
int_21h_44h:			;���Ή��̋@�\
	nop	;�u����Áv�Ƃ̑������H�@�������j��H
	jmp	call_V86_int21
	;
	;�떂����
	;
	;����ł� AL=02h-05h �ɑΉ��ł��Ȃ�
	;
	iret


;------------------------------------------------------------------------------
;�E�J�����g�f�B���N�g���̎擾  AH=47h
;------------------------------------------------------------------------------
; in	ds:esi	64 byte buffer
;	    dl	drive number
;
proc int_21h_47h
	push	ecx
	push	edx
	push	edi
	push	esi

	push	eax
	call	get_gp_buffer_32
	mov	esi, eax
	mov	edi, eax
	pop	eax
	test	esi, esi
	jz	.error

	calli	call_V86_int21	;save to ds:si
	jc	.error_free_gp

	mov	esi, [esp]	;copy cs:edi to ds:esi
	xor	ecx, ecx
.loop:
	mov	edx,[cs:edi+ecx]
	mov	[esi+ecx],edx
	add	cl, 4
	cmp	cl, 64
	jb	.loop

	push	eax
	mov	eax, edi
	call	free_gp_buffer_32
	pop	eax

	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	clear_cy
	iret

.error_free_gp:
	push	eax
	mov	eax, edi
	call	free_gp_buffer_32
	pop	eax

.error:
	pop	esi
	pop	edi
	pop	edx
	pop	ecx
	set_cy
	iret

;------------------------------------------------------------------------------
;�E�q�v���O�����̎��s  AH=4bh
;------------------------------------------------------------------------------
	align	4
int_21h_4bh:
	set_cy
	iret


;------------------------------------------------------------------------------
;�E�ŏ��Ɉ�v����t�@�C���̌���  AH=4eh
;------------------------------------------------------------------------------
	align	4
int_21h_4eh:
	calli	int_21h_ds_edx		;DOS call

	pushfd			;FLAGS save
	push	ds
	push	es
	push	esi
	push	edi
	push	ecx

	mov	esi,F386_ds
	mov	ecx,28h /4	;�f�[�^�̈�T�C�Y /4
	mov	ds ,si		;DS �� F386 �̃��m��
	mov	es ,[DTA_seg]
	mov	esi,80h
	mov	edi,[DTA_off]
	rep	movsd		;�ꊇ�f�[�^�]��

	mov	cl,3		;�c�� 3byte �]��
	rep	movsb		;�o�C�g�]��

	pop	ecx
	pop	edi
	pop	esi
	pop	es
	pop	ds

	popfd
	iret_save_cy		;Carry save & return


;------------------------------------------------------------------------------
;�E���Ɉ�v����t�@�C���̌���  AH=4fh
;------------------------------------------------------------------------------
	align	4
int_21h_4fh:
	calli	call_V86_int21		;DOS call

	pushfd			;FLAGS save
	push	ds
	push	es
	push	esi
	push	edi
	push	ecx

	mov	esi,F386_ds
	mov	ecx,28h /4	;�f�[�^�̈�T�C�Y /4
	mov	ds ,si		;DS �� F386 �̃��m��
	mov	es ,[DTA_seg]
	mov	esi,80h
	mov	edi,[DTA_off]
	rep	movsd		;�ꊇ�f�[�^�]��

	mov	cl,3		;�c�� 3byte �]��
	rep	movsb		;�o�C�g�]��

	pop	ecx
	pop	edi
	pop	esi
	pop	es
	pop	ds

	popfd
	iret_save_cy		;Carry save & return


;------------------------------------------------------------------------------
;�y�ėp�zES:BX�ł̂݁A�߂�l���Ԃ�B AH=34h(InDOS flag), AH=52h(MCB/Undoc)
;------------------------------------------------------------------------------
	align	4
int_21h_ret_esbx:
	xor	ebx, ebx
	calli	call_V86_int21		;int 21h ���荞�ݏ������[�`���Ăяo��

	push	eax

	mov	eax,DOSMEM_sel
	mov	es, eax

	mov	eax, [cs:call_V86_es]
	shl	eax, 4			;to Liner
	add	ebx, eax

	pop	eax
	iret

;------------------------------------------------------------------------------
;�E�t�@�C���̈ړ��i���l�[���j  AH=56h
;------------------------------------------------------------------------------
;	ds:edx	move from
;	es:edi	move to
;
	align	4
int_21h_56h:
	push	edi

	push	eax
	push	ebx
	push	ecx
	push	ds

	mov	eax,F386_ds
	mov	 ds,eax

	call	get_gp_buffer_32
	test	eax, eax
	jz	short .error

	mov	ebx, eax
	xor	ecx, ecx
.loop:
	mov	al,[es:edi+ecx]		; copy from [es:edi]
	mov	[ebx+ecx],al		; copy to   [ds:ebx]
	test	al,al
	jz	.skip

	inc	ecx
	cmp	ecx, GP_BUFFER_SIZE
	jb	.loop
	mov	b [ebx], 0		; force fail

.skip:
	mov	edi, ebx		; buffer address

	pop	ds
	pop	ecx
	pop	ebx
	pop	eax
	calli	int_21h_ds_edx		;call DOS

	pushf
	push	eax
	mov	eax, edi
	call	free_gp_buffer_32
	pop	eax
	popf

	pop	edi
	iret_save_cy

.error:
	pop	ds
	pop	ecx
	pop	ebx
	pop	eax
	pop	edi
	set_cy
	iret


;------------------------------------------------------------------------------
;�EPSP�𓾂�  AH=62h
;------------------------------------------------------------------------------
	align	4
int_21h_62h:
	mov	bx,PSP_sel1
	iret

