;******************************************************************************
;�@Free386	���荞�ݏ������[�`�� / DOS ����[�`��
;******************************************************************************
;
; 2001/01/18 �t�@�C���𕪗�
;
;
;==============================================================================
;��DOS ���荞��  int 20-2F
;==============================================================================
;------------------------------------------------------------------------------
;�Eint 20h / �v���O�����̏I��
;------------------------------------------------------------------------------
proc4 PM_int_20h
	call_RegisterDumpInt	20h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 22h / �I���A�h���X
;------------------------------------------------------------------------------
;�@�v���O�������I������Ƃ����s���ڂ��A�h���X���L�^���Ă���x�N�^�B
;�@����ł́Aint 21h / AH=4ch �Ƀ`�F�C��
;
proc4 PM_int_22h
	call_RegisterDumpInt	22h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 23h / CTRL-C �E�o�A�h���X
;------------------------------------------------------------------------------
proc4 PM_int_23h
	call_RegisterDumpInt	23h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 24h / �v���I�G���[���f�A�h���X
;------------------------------------------------------------------------------
proc4 PM_int_24h
	call_RegisterDumpInt	24h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 25h / �����Z�N�^�ǂݍ���
;------------------------------------------------------------------------------
proc4 PM_int_25h
	call_RegisterDumpInt	25h
	iret

;------------------------------------------------------------------------------
;�Eint 26h / �����Z�N�^��������
;------------------------------------------------------------------------------
proc4 PM_int_26h
	call_RegisterDumpInt	26h
	iret

;------------------------------------------------------------------------------
;�Eint 27h / �v���O�����̏풓�I��
;------------------------------------------------------------------------------
proc4 PM_int_27h
	call_RegisterDumpInt	27h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h

;------------------------------------------------------------------------------
;�Eint 28h / �R���\�[�����͎��ɌĂ΂��A�C�h�����[�`��
;------------------------------------------------------------------------------
proc4 PM_int_28h
	call_RegisterDumpInt	28h
	iret

;------------------------------------------------------------------------------
;�Eint 29h / �����R���\�[���o��
;------------------------------------------------------------------------------
;	AL = �o�̓R�[�h
;
proc4 PM_int_29h
	call_RegisterDumpInt	29h
	push	29h
	jmp	call_V86_int_iret

;------------------------------------------------------------------------------
;�Eint 2ah / MS-Networks NETBIOS
;�Eint 2bh / DOS reserved
;�Eint 2ch / DOS reserved
;�Eint 2dh / DOS reserved
;------------------------------------------------------------------------------
proc1 PM_int_2ah
proc1 PM_int_2bh
proc1 PM_int_2ch
proc1 PM_int_2dh
	iret

;------------------------------------------------------------------------------
;�Eint 2eh / shell(command.com)�����s
;------------------------------------------------------------------------------
proc4 PM_int_2eh
	call_RegisterDumpInt	2eh
	iret

;------------------------------------------------------------------------------
;�Eint 2fh / DOS ����Jfunction
;------------------------------------------------------------------------------
proc4 PM_int_2fh
	call_RegisterDumpInt	2fh
	push	2fh			; interrupt number
	jmp	call_V86_int_iret


;******************************************************************************
;�Eint 21h / DOS function & DOS-Extender function
;******************************************************************************
;------------------------------------------------------------------------------
;�Eint 21h / ��T�|�[�g
;------------------------------------------------------------------------------
proc4 int_21h_notsupp
	set_cy		;�G���[�ɐݒ�
	iret

;------------------------------------------------------------------------------
;�Eint 21h / ���m��function
;------------------------------------------------------------------------------
proc4 int_21h_unknown
 	jmp	call_V86_int21_iret

;==============================================================================
;�Eint 21h / �e�[�u���W�����v����
;==============================================================================
proc4 PM_int_21h
	call_RegisterDumpInt	21h

    %if (int_21h_fn_MAX < 0ffh)
	cmp	ah,int_21h_fn_MAX		;�e�[�u���ő�l
	ja	int_21h_unknown			;����ȏ�Ȃ� jmp
    %endif
	push	eax
	movzx	eax,ah				;eax = AH
	mov	eax,[cs:int21h_table + eax*4]	;function table

	xchg	[esp],eax			;recovery eax
	ret					; table jump


;------------------------------------------------------------------------------
;�y�ėp�zDS:EDX�� NULL �ŏI��镶����
;------------------------------------------------------------------------------
proc4 int_21h_ds_edx
	push	ds
	push	es
	push	edx

	push	F386_ds		;F386 ds
	pop	es		;es �� load

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
	V86_INT	21h

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
proc4 int_21h_09h
%if PRINT_TO_FILE
	jmp	int_21h_09h_output_file
%else
	cmp	b [cs:call_buf_used], 0		; check call buffer status
	je	.skip
	iret
.skip:
	; PRINT_TSUGARU �͒Ìy�ł͂Ȃ����Ŏ��s���A
	; �ʏ�̕�����o�͂��s���B
	; �Ìy���� jmp �e�[�u����������������B

	push	ds
	push	es
	push	edx

	push	F386_ds
	pop	es

	mov	b [es:call_buf_used], 1	; use call buffer

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
	V86_INT	21h

	mov	b [es:call_buf_used], 0

	pop	edx
	pop	es
	pop	ds
	iret_save_cy		;�L�����[�Z�[�u & iret
%endif

;------------------------------------------------------------------------------
;�y�f�o�b�O�z������o�͂������I�Ƀt�@�C���o��  AH=09h
;------------------------------------------------------------------------------
%if PRINT_TO_FILE

proc4 int_21h_09h_output_file
	; �����t�@�C���o��
	pushad
	push	ds
	push	es

	push	F386_ds
	pop	ds

	; file open
	push	edx
	mov	al, 0001_0010b
	mov	ah, 3dh
	mov	edx, offset .file
	V86_INT	21h
	pop	edx
	jc	.exit

	mov	ebx, eax	; bx = handle

	; file seek
	push	edx
	mov	al, 02h
	mov	ah, 42h
	xor	ecx,ecx
	xor	edx,edx
	V86_INT	21h
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
	V86_INT	21h

	; close
	mov	ah, 3eh
	V86_INT	21h

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

proc4 int_21h_09h_output_tsugaru
	pushad
	push	ds
	push	es

	push	F386_ds
	pop	ds
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
proc4 int_21h_0ah
	pushad
	push	es
	push	ds
	cld

	push	F386_ds
	pop	ds

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
	V86_INT	21h
	pop	edx

	; edx = caller buffer
	; ebp = gp buffer
	push	ds			; exchange ds<>es
	mov	eax,  es
	mov	  ds,ax		; ds = F386 ds
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
proc4 int_21h_1bh
proc4 int_21h_1ch
	push	esi

	xor	ebx,ebx			;ebx ���16bit �N���A
	V86_INT	21h			;DS:BX = FAT-ID �A�h���X

	mov	esi,cs:[cv86_ds]	;real ds
	shl	esi, 4			;�Z�O�����g��16�{ (para -> byte)
	add	ebx,esi			;ebx = FAT:ID �x�[�X�A�h���X
	push	DOSMEM_sel		;DOS�������A�N�Z�X�Z���N�^
	pop	ds			;ds �ɐݒ�

	pop	esi
	iret


;------------------------------------------------------------------------------
;�E�f�B�X�N�]���A�h���X�ݒ�  AH=1ah
;------------------------------------------------------------------------------
proc4 int_21h_1ah
	push	es
	push	F386_ds
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
proc4 int_21h_2fh
	mov	ebx, [cs:DTA_off]
	mov	es , [cs:DTA_seg]	;DTA �̌��ݒl
	iret

;------------------------------------------------------------------------------
;�E�풓�I��  AH=31h
;------------------------------------------------------------------------------
proc4 int_21h_31h			;���Ή��̋@�\
	jmp	int_21h_4ch

;------------------------------------------------------------------------------
;�E���ʏ��̎擾�^�ݒ�  AH=38h
;------------------------------------------------------------------------------
proc4 int_21h_38h
	cmp	dx,-1
	je	call_V86_int21_iret	; setting is jmp

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
	V86_INT	21h			;int 21h ���荞�ݏ������[�`���Ăяo��
	jc	short .error2

	;------------------------------------------------------------
	; copy es:[edx] to ds:[edi]
	;------------------------------------------------------------
	push	ecx
	push	es
	push	F386_ds
	pop	es

	xor	ecx, ecx
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
proc4 int_21h_3fh
	cmp	b [cs:call_buf_used], 0	; check call buffer status
	je	.skip
	xor	eax, eax
	set_cy
	iret
.skip:
	cld
	push	edx
	push	esi
	push	edi
	push	ebp
	push	es
	push	ds
	push	ecx	;�X�^�b�N�Q�ƒ���

	push	F386_ds
	pop	ds
	mov	es,[esp+4]		;�ǂݍ��ݐ�

	mov	b [call_buf_used], 1	; save call buffer flag

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
	V86_INT	21h			;�t�@�C���ǂݍ���  / DOS call
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
	V86_INT	21h			;�t�@�C���ǂݍ���  / DOS call
	pop	edx		;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �ǂݍ��񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��
	mov	esi,[call_buf_adr32]	;�o�b�t�@�A�h���X���[�h
	rep	movsb			;�ꊇ�]��

.end:
	mov	eax,[esp]		;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	mov	b [call_buf_used], 0	; clear call buffer flag

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
	mov	b [call_buf_used], 0	; clear call buffer flag

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
proc4 int_21h_40h
	cmp	b [cs:call_buf_used], 0	; check call buffer status
	je	.skip
	xor	eax, eax
	set_cy
	iret
.skip:
	cld
	push	edx
	push	esi
	push	edi
	push	ebp
	push	es
	push	ecx	;�X�^�b�N�Q�ƒ���

	push	F386_ds
	pop	es			;  es:edi �]����i�o�b�t�@�p�j
	mov	esi,edx			;  ds:esi �������݃f�[�^

	mov	b [es:call_buf_used], 1	; save call buffer flag

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
	V86_INT	21h			;�t�@�C����������  / DOS call
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
	V86_INT	21h			;�t�@�C����������  / DOS call
	pop	edx		;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �������񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��

.end:
	mov	eax,[esp]		;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	mov	b [es:call_buf_used], 0	; clear call buffer flag

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
	mov	b [es:call_buf_used], 0	; clear call buffer flag

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
proc4 int_21h_44h
	jmp	call_V86_int21_iret
	;
	; not support AL=02h-05h
	;


;------------------------------------------------------------------------------
;�E�J�����g�f�B���N�g���̎擾  AH=47h
;------------------------------------------------------------------------------
; in	ds:esi	64 byte buffer
;	    dl	drive number
;
proc4 int_21h_47h
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

	V86_INT	21h		;save to ds:si
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
;�E�ŏ��Ɉ�v����t�@�C���̌���  AH=4eh
;------------------------------------------------------------------------------
proc4 int_21h_4eh
	callint	int_21h_ds_edx		;DOS call

	pushfd			;FLAGS save
	push	ds
	push	es
	push	esi
	push	edi
	push	ecx
	cld

	push	F386_ds
	pop	ds

	mov	ecx,28h /4	;�f�[�^�̈�T�C�Y /4
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
proc4 int_21h_4fh
	V86_INT	21h		;DOS call

	pushfd			;FLAGS save
	push	ds
	push	es
	push	esi
	push	edi
	push	ecx
	cld

	push	F386_ds
	pop	ds

	mov	ecx,28h /4	;�f�[�^�̈�T�C�Y /4
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
proc4 int_21h_ret_esbx
	xor	ebx, ebx
	V86_INT	21h		;int 21h ���荞�ݏ������[�`���Ăяo��

	push	eax

	mov	eax,DOSMEM_sel
	mov	 es,ax

	mov	eax, cs:[cv86_es]
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
proc4 int_21h_56h
	push	edi

	push	eax
	push	ebx
	push	ecx
	push	ds

	push	F386_ds
	pop	ds

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
	callint	int_21h_ds_edx		;call DOS

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
proc4 int_21h_62h
	mov	bx,PSP_sel1
	iret

