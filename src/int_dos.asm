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
	jmp	PM_int_21h		;�`�F�C��

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
	jmp	PM_int_21h		;�`�F�C��

;------------------------------------------------------------------------------
;�Eint 23h / CTRL-C �E�o�A�h���X
;------------------------------------------------------------------------------
	align	4
PM_int_23h:
	call_RegisterDumpInt	23h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h		;�`�F�C��

;------------------------------------------------------------------------------
;�Eint 24h / �v���I�G���[���f�A�h���X
;------------------------------------------------------------------------------
	align	4
PM_int_24h:
	call_RegisterDumpInt	24h
	mov	ax,4c00h		;�v���O�����I�� (ret=00)
	jmp	PM_int_21h		;�`�F�C��

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
	jmp	PM_int_21h		;�`�F�C��

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
	sub	esp,byte 4		;���[�U�̈�i���g�p�j
	push	d (29h * 4)		;�x�N�^�ԍ�*4 �� push
	jmp	call_V86_int		;V86 ���荞�݃��[�`���Ăяo��

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
	sub	esp,byte 4		;���[�U�̈�i���g�p�j
	push	d (2fh * 4)		;�x�N�^�ԍ�*4 �� push
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
	align	4
PM_int_21h:
	call_RegisterDumpInt	21h

%if (int_21h_MAXF < 0ffh)
	cmp	ah,int_21h_MAXF		;�e�[�u���ő�l
	jae	int_21h_unknown		;����ȏ�Ȃ� jmp
%endif
	cld				;�����t���O�N���A
	push	eax			;

	movzx	eax,ah				;�@�\�ԍ�
	mov	eax,[cs:int21h_table + eax*4]	;�W�����v�e�[�u���Q��

	;------------------------------------------
	;int 21h �̂ݖ߂�l���o��
	;------------------------------------------
%if INT_HOOK
	;
	; ���̎��_�� original eax ���ς܂�Ă���
	;
	cmp	b [esp + 01h], 09h	;�Ăяo���� AH
	jz	short .normal_call
	cmp	d [esp + 08h], F386_cs	;�Ăяo���� CS
	jz	short .normal_call

	; ���̎��_�� original eax ���ς܂�Ă���
	push	cs			; cs
	push	d offset .call_retern	; EIP
	pushf				; jump address
	xchg	[esp], eax		;eax=eflags, [esp]=jump address
	xchg	[esp+12], eax		;[esp+8]=eflags, eax=original eax
	ret				; �e�[�u���W�����v
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
	push	fs
	push	gs
	push	edx

	push	d (F386_ds)		;F386 ds
	pop	es			;es �� load

	;�����̃R�s�[
	pushad
	mov	edi,[es:int_buf_adr]	;�]���� es:edi
	mov	ecx,(INT_BUF_size /4)-1	;�]���ő�T�C�Y /4
	mov	ebp,4			;�A�h���X���Z�l
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

	mov	edx, [cs:int_buf_adr]
	calli	call_V86_int21

	pop	edx
	pop	gs
	pop	fs
	pop	es
	pop	ds
	iret_save_cy		;�L�����[�Z�[�u & iret

;------------------------------------------------------------------------------
;�E������o��  AH=09h
;------------------------------------------------------------------------------
	align	4
int_21h_09h:
%if PRINT_TO_FILE
	jmp	int_21h_09h_output_file
%else
	push	ds
	push	es
	push	fs
	push	gs
	push	edx

	push	d (F386_ds)		;F386 ds
	pop	es			;es �� load

	;�����̃R�s�[
	pushad
	mov	edi,[es:int_buf_adr]	;�]���� es:edi
	mov	ecx,(INT_BUF_size /4)-1	;�]���ő�T�C�Y /4
	mov	ebp,4			;�A�h���X���Z�l
	mov	b [es:edi + ecx*4], '$'

	align	4
.loop:
	mov	eax,[edx]
	mov	[es:edi],eax
	cmp	al,'$'
	jz	short .exit
	cmp	ah,'$'
	jz	short .exit
	shr	eax,16			;��ʁ����ʂ�
	cmp	al,'$'
	jz	short .exit
	cmp	ah,'$'
	jz	short .exit
	add	edx,ebp		;+4
	add	edi,ebp		;+4
	loop	.loop
.exit:
	popad

	mov	edx, [cs:int_buf_adr]
	calli	call_V86_int21

	pop	edx
	pop	gs
	pop	fs
	pop	es
	pop	ds
	iret_save_cy		;�L�����[�Z�[�u & iret
%endif

;------------------------------------------------------------------------------
;�y�f�o�b�O�z������o�͂������I�Ƀt�@�C���o��  AH=09h
;------------------------------------------------------------------------------
%if PRINT_TO_FILE
int_21h_09h_output_file:
	; �����t�@�C���o��
	pushad
	push	es
	push	ds

	mov	eax, F386_ds
	mov	ds, eax

	; file open
	push	edx
	mov	al, 01000010b
	mov	ah, 3dh
	mov	edx, .file
	calli	call_V86_int21
	pop	edx
	jc	.exit

	mov	ebx, eax	; bx = handle

	; file seek
	mov	al, 02h
	mov	ah, 42h
	xor	ecx,ecx
	xor	edx,edx
	calli	call_V86_int21

	mov	es,[esp]
	mov	esi, edx
	mov	edi, [int_buf_adr]
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
	cmp	ecx,INT_BUF_size
	jnz	short .loop
.loop_end:
	; write
	mov	ah, 40h
	calli	call_V86_int21

	; close
	mov	ah, 3eh
	calli	call_V86_int21

.exit:
	pop	ds
	pop	es
	popad
	iret

.file	db	"dump.txt",0
%endif


;------------------------------------------------------------------------------
;�E�o�b�t�@�t���W��1�s����  AH=0ah
;------------------------------------------------------------------------------
	align	4
int_21h_0ah:
	push	ecx
	push	edx
	push	esi
	push	edi
	push	es
	push	ds

	mov	esi,F386_ds		;DS
 	mov	 es,[esp]		;�o�b�t�@�A�h���X
	mov	 ds,esi			;DS ���[�h
	mov	edi,edx			;  es:edi �� ���[�h

	mov	cl,[es:edi]		;�ő���̓o�C�g��
	mov	edx,[int_buf_adr]	;�o�b�t�@�A�h���X���[�h
	mov	esi,edx			;esi �ɂ��o�b�t�@�A�h���X��
	mov	[edx],cl		;�ő���̓o�C�g�����[�h

	mov	eax,[v86_cs]		;V86�� cs,ds
	push	eax			;*** call_V86 ***
	push	eax			;����	+04h	call adress / cs:ip
	push	eax			;	+08h	V86 ds
	push	eax			;	+0ch	V86 es
	push	d [DOS_int21h_adr]	;	+10h	V86 fs
	call	call_V86		;	+14h	V86 gs
	add	esp,byte 14h		;�X�^�b�N����

	movzx	ecx,b [esi+1]		;���ۂɓ��͂��ꂽ������
	mov	[es:edi+1],cl		;�Ăяo�����ɋL�^
	inc	ecx			;CR ���܂ޕ�������
	add	esi,byte 2		;�A�h���X�����炷
	add	edi,byte 2		;
	rep	movsb			;�ꊇ�]��  ds:esi -> es:edi

	pop	ds
	pop	es
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
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

	mov	esi,[cs:call_v86_ds]	;real ds
	shl	esi, 4			;�Z�O�����g��16�{ (para -> byte)
	add	ebx,esi			;ebx = FAT:ID �x�[�X�A�h���X
	push	d (DOSMEM_Lsel)		;DOS�������A�N�Z�X�Z���N�^
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
	cmp	edx,-1		;�ݒ�?
	jne	short .read	;�ǂݏo���Ȃ� jmp
	jmp	call_V86_int21

.read:	push	edx
	push	edi
	mov	edi,edx			;edi = �v���O�������o�b�t�@
	mov	edx,[cs:int_buf_adr]	;�o�b�t�@�A�h���X
	calli	call_V86_int21		;int 21h ���荞�ݏ������[�`���Ăяo��
	jc	short .error

	push	ecx
	push	es
	mov	ecx, F386_ds
	mov	es, ecx

	mov	cl,34			;34 byte
	align	4
.loop:	mov	ch,[es:edx]		;1 byte
	mov	[edi],ch		;   -copy
	inc	edx			;�A�h���X�X�V
	inc	edi			;
	dec	cl
	jnz	short .loop

	pop	es
	pop	ecx
	pop	edi
	pop	edx
	clear_cy
	iret

.error:	pop	edi
	pop	edx
	set_cy
	iret

;------------------------------------------------------------------------------
;�E�t�@�C���̓ǂݍ���  AH=3fh
;------------------------------------------------------------------------------
	align	4
int_21h_3fh:
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ebp
	push	es
	push	ds

	mov	esi,F386_ds		;DS
 	mov	es,[esp]		;�ǂݍ��ݐ��
	mov	ds,esi			;DS ���[�h

	sub	esp,byte 0ch		;*** call_V86 ***
	push	d [v86_cs]		;����	+04h	call adress / cs:ip
	push	d [DOS_int21h_adr]	;	+08h�`+14h	ds,es,fs,gs

	mov	edi,edx			;�f�[�^��  es:edi �֓ǂݍ���
	mov	edx,ecx			;edx = �c��]���o�C�g��
	mov	ebp,ecx			;ebp = �]���o�C�g��

	cmp	edx,INT_BUF_size	;�c��ƃo�b�t�@�T�C�Y���r
	jbe	.last			;�ȉ��Ȃ�W�����v

	align	4	;-------------------------
.loop:
	mov	ah,3fh			;File Read (dos function)

	mov	[Idata0],edx	;�ޔ�
	mov	edx,[int_buf_adr]	;�ǂݏo���o�b�t�@
	mov	ecx,INT_BUF_size	;�o�b�t�@�T�C�Y
	call	call_V86		;�t�@�C���ǂݍ���  / DOS call
	mov	edx,[Idata0]	;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �ǂݍ��񂾃o�C�g��
	mov	esi,[int_buf_adr]	;�o�b�t�@�A�h���X���[�h
	sub	edx,ecx			;edx = �c��]���o�C�g��
	rep	movsb			;�ꊇ�]�� ds:esi -> es:edi

	cmp	ax,INT_BUF_size		;�]���T�C�Y�Ǝ��ۂ̓]���ʔ�r
	jne	.end			;�Ⴆ�Γ]���I���i�ǂݏI�����j

	cmp	edx,INT_BUF_size	;�c��ƃo�b�t�@�T�C�Y���r
	ja	short .loop		;�傫����� (edx > BUF_size) ���[�v

	align	4 ;--------------------------------
.last:
	mov	ah,3fh			;File Read (dos function)

	mov	ecx,edx			;ecx = �c��T�C�Y
	mov	[Idata0],edx	;�ޔ�
	mov	edx,[int_buf_adr]	;�ǂݏo���o�b�t�@
	call	call_V86		;�t�@�C���ǂݍ���  / DOS call
	mov	edx,[Idata0]	;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �ǂݍ��񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��
	mov	esi,[int_buf_adr]	;�o�b�t�@�A�h���X���[�h
	rep	movsb			;�ꊇ�]��

.end:
	mov	eax,ebp			;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	add	esp,byte 14h		;�X�^�b�N����
 	pop	ds
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	clear_cy
	iret


	align	4
.error_exit:
	add	esp,byte 14h		;�X�^�b�N����
	pop	ds
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	set_cy
	iret


;------------------------------------------------------------------------------
;�E�t�@�C���̏�������  AH=40h
;------------------------------------------------------------------------------
	align	4
int_21h_40h:
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ebp
	push	es

	mov	edi,F386_ds		;DS
	mov	es ,edi			;  es:edi �]����i�o�b�t�@�p�j
	mov	esi,edx			;  ds:esi �������݃f�[�^

	sub	esp,byte 0ch		;*** call_V86 ***
	push	d [es:v86_cs]		;����	+04h	call adress / cs:ip
	push	d [es:DOS_int21h_adr]	;	+08h�`+14h	ds,es,fs,gs

	mov	edx,ecx			;edx = �c��]���o�C�g��
	mov	ebp,ecx			;ebp = �]���o�C�g��

	cmp	edx,INT_BUF_size	;�c��ƃo�b�t�@�T�C�Y���r
	jbe	.last			;�ȉ��Ȃ�W�����v

	align	4	;-------------------------
.loop:
	mov	ah,40h			;File Read (dos function)

	mov	edi,[es:int_buf_adr]	;�o�b�t�@�A�h���X���[�h
	mov	ecx,INT_BUF_size	;ecx = �������񂾃o�C�g��
	rep	movsb			;�ꊇ�]��

	mov	[es:Idata0],edx	;�ޔ�
	mov	edx,[es:int_buf_adr]	;�������݃o�b�t�@
	mov	ecx,INT_BUF_size	;�o�b�t�@�T�C�Y
	call	call_V86		;�t�@�C����������  / DOS call
	mov	edx,[es:Idata0]	;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	eax,ax			;eax = �������񂾃o�C�g��
	sub	edx,eax			;�c��]���T�C�Y�������

	cmp	eax,INT_BUF_size	;�]���T�C�Y�Ǝ��ۂ̓]���ʔ�r
	jne	.end			;�Ⴆ�Γ]���I���i�������ݏI�����j

	cmp	edx,INT_BUF_size	;�c��ƃo�b�t�@�T�C�Y���r
	ja	.loop			;�o�b�t�@�T�C�Y���傫�������烋�[�v

	;----------------------------------------
.last:
	mov	ah,40h			;File Read (dos function)

	mov	edi,[es:int_buf_adr]	;�o�b�t�@�A�h���X���[�h
	mov	ecx,edx			;ecx = �c��T�C�Y
	rep	movsb			;�ꊇ�]��

	mov	ecx,edx			;ecx = �c��T�C�Y
	mov	[es:Idata0],edx	;�ޔ�
	mov	edx,[es:int_buf_adr]	;�������݃o�b�t�@
	call	call_V86		;�t�@�C����������  / DOS call
	mov	edx,[es:Idata0]	;����
	jc	.error_exit		;Cy=1 => �G���[�Ȃ�W�����v

	movzx	ecx,ax			;ecx = �������񂾃o�C�g��
	sub	edx,ecx			;edx = �c��]���o�C�g��

.end:
	mov	eax,ebp			;�w��]���T�C�Y
	sub	eax,edx			;�c��]���ʂ����� -> ���ۂ̓]����

	add	esp,byte 14h		;�X�^�b�N����
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	clear_cy
	iret

	align	4
.error_exit:
	add	esp,byte 14h		;�X�^�b�N����
	pop	es
	pop	ebp
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
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
	align	4
int_21h_47h:
	push	edi
	push	esi
	push	ecx
	push	edx

	push	esi
	mov	esi,[cs:int_buf_adr]	;�o�b�t�@�A�h���X
	mov	edi,esi			;edi �ɂ�

	calli	call_V86_int21		;DOS call

	pop	esi
	pushfd			;�t���O�ۑ�
	mov	ecx,64/4
.loop:
	mov	edx,[cs:edi]
	mov	[esi],edx
	add	edi,byte 4
	add	esi,byte 4
	loop	.loop

	popfd			;�t���O����
	pop	edx
	pop	ecx
	pop	esi
	pop	edi
	iret_save_cy		;�L�����[�Z�[�u & iret

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

	mov	eax,DOSMEM_Lsel
	mov	es, eax

	mov	eax, [cs:call_v86_es]
	shl	eax, 4			;to Liner
	add	ebx, eax

	pop	eax
	iret

;------------------------------------------------------------------------------
;�E�t�@�C���̈ړ��i���l�[���j  AH=56h
;------------------------------------------------------------------------------
	align	4
int_21h_56h:
	push	edi

	push	eax
	push	ebx
	push	ecx
	push	ds

	mov	eax,F386_ds	;
	mov	ds,ax		;�Z�O�����g���W�X�^���[�h

	mov	ebx,[int_buf_adr]	;����o�b�t�@�̃A�h���X
	mov	ecx,100h		;�ő� 100h (256) ����
	add	ebx,ecx			;+100h �̈ʒu�̃o�b�t�@
.loop:
	mov	al,[es:edi]	;es:edi �ύX�t�@�C����
	mov	[ebx],al	;�o�b�t�@�փR�s�[
	inc	edi		;
	inc	ebx		;�|�C���^�X�V

	test	al,al		;�lcheck
	jz	.exit		;0 �Ȃ�E�o (0 �܂ŃR�s�[����)
	loop	.loop
.exit:
	mov	edi,[int_buf_adr]	;����o�b�t�@�̃A�h���X
	add	edi,100h		;+100h

	pop	ds
	pop	ecx
	pop	ebx
	pop	eax

	calli	int_21h_ds_edx		;DOS �Ăяo��

	pop	edi
	iret_save_cy


;------------------------------------------------------------------------------
;�EPSP�𓾂�  AH=62h
;------------------------------------------------------------------------------
	align	4
int_21h_62h:
	mov	bx,PSP_sel1
	iret

