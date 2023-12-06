;------------------------------------------------------------------------------
;F386sub.asm	subroutine for Free386
;------------------------------------------------------------------------------
;[TAB=8]
;	Author kattyo@abk / nabe@abk
;
;------------------------------------------------------------------------------

%include	"macro.inc"
%include	"f386def.inc"

%include	"start.inc"
%include	"free386.inc"
%include	"f386mem.inc"
%include	"f386seg.inc"

;------------------------------------------------------------------------------
	global	register_dump		;safe
	global	register_dump_fault	;safe
	global	dump_err_code
	global	dump_orig_esp
	global	dump_orig_ss
%if INT_HOOK
	global	register_dump_from_int	;safe
%endif
	global	eax2hex

	global	searchpath		;�t�@�C���̃p�X�T�[�`
	global	load_exp		;exp �t�@�C���̃��[�h
	global	run_exp			;exp �t�@�C���̎��s

;******************************************************************************
;���R�[�h
;******************************************************************************
;
;##############################################################################
;stack dump
;	This is PDS.
;	made by ����@ABK  2000/07/24
;##############################################################################
;
; 2001/01/18	Free386 �ւ̑g�ݍ���		(by nabe@abk)
; 2001/02/06	�d�l�̊��Ⴂ����� & ����	(by nabe@abk)
;
;
segment	text public align=4 class=CODE use16
BITS	32
;------------------------------------------------------------------------------
;�����W�X�^�_���v�\��
;------------------------------------------------------------------------------
;;	mov		eax, 0dh		; ��O�ԍ�
;;	mov		ebx, offset dmy_tbl	; �n�����e�[�u��
;;
%imacro	to_hex	1
	mov	edx,offset %1
	call	eax2hex
%endmacro

%if INT_HOOK
;------------------------------------------------
proc register_dump_from_int
;------------------------------------------------
	push	ds
	push	eax
	;
	; call���A�h���X��exception number����Ɏg��
	; com�̎d�l��, 100h ��菬�������Ƃ͖���
	;
	;stack
	;	+18h	eflags
	;	+14h	cs
	;	+10h	eip
	;	+0ch	int number
	;	+08h	caller (or exception number)
	;	+04h	ds
	;	+00h	eax
	;
	push	d F386_ds
	pop	ds
	;
	; target AH
	;
	%if INT_HOOK_AH
		cmp	ah, INT_HOOK_AH
		jne	short .no_dump
	%endif
	;
	; target CS
	;
	%if INT_HOOK_CS
		cmp	d [esp+14h], INT_HOOK_CS
		jne	short .no_dump
	%endif
	;
	; exclude CS
	;
	%if INT_HOOK_EX_CS
		cmp	d [esp+14h], INT_HOOK_EX_CS
		je	short .no_dump
	%endif
	;
	; Free386 internal call ignore
	;
	%if !INT_HOOK_F386
		cmp	d [esp+14h], F386_cs
		je	short .no_dump
	%endif
	;
	; int 21h, ah=09h �͖���
	;
	%if INT_HOOK_RETV
		cmp	b [esp+0ch], 21h
		jz	short .is_int21
		cmp	d [esp+0ch], -2
		jnz	short .not_int21h
		.is_int21:
	%else
		cmp	b [esp+0ch], 21h
		jnz	short .not_int21h
	%endif
	cmp	ah, 09h
	jz	short .no_dump

.not_int21h:
	; Int = �ɏ�������
	mov	eax, [blue_int_str]
	mov	[regdump_msg], eax

	call	register_dump_fault	;safe

	; Err = �ɖ߂�
	mov	eax, [blue_err_str]
	mov	[regdump_msg], eax
.no_dump:
	push	d [esp+18h]	; eflags
	popf
	pop	eax
	pop	ds
	ret
%endif

	align	4
;------------------------------------------------
register_dump:		;safe
;------------------------------------------------
	pushf
	push	cs
	push	eax	; EIP dummy
	push	d [cs:dump_err_code]
	push	d 100h	; Exception number
	push	ds
	push	eax
	mov	eax, F386_ds
	mov	 ds, eax
	mov	eax,[esp+1ch]	; caller
	mov	[esp+10h],eax
	mov	d [dump_err_code], -1

	call	register_dump_fault	;safe

	pop	eax
	pop	ds
	add	esp, 10h
	popf
	ret

	;stack
	;	+1ch	eflags
	;	+18h	cs
	;	+14h	eip
	;	+10h	error code
	;	+0ch	exception number
	;	+08h	ds
	;	+04h	eax
	align 4
;------------------------------------------------
;------------------------------------------------
proc register_dump_fault
	; in	stack +04h	eax
	;
	; ���W�X�^�ۑ�, ds�ݒ�ςŌĂяo������
	;
	push	edx
	push	ecx
	push	ebx
	push	eax

	mov	eax, [esp+14h]
	to_hex	blue_eax
	mov	eax, [esp+04h]
	to_hex	blue_ebx
	mov	eax, [esp+08h]
	to_hex	blue_ecx
	mov	eax, [esp+0ch]
	to_hex	blue_edx

	mov	eax, esi
	to_hex	blue_esi
	mov	eax, edi
	to_hex	blue_edi
	mov	eax, ebp
	to_hex	blue_ebp

	mov	eax, [esp+20h]
	to_hex	blue_errorcode
	mov	eax, [esp+24h]
	to_hex	blue_eip
	mov	eax, [esp+28h]
	to_hex	blue_cs

	mov	eax, [esp+18h]
	to_hex	blue_ds
	mov	eax, es
	to_hex	blue_es
	mov	eax, fs
	to_hex	blue_fs
	mov	eax, gs
	to_hex	blue_gs

	mov	eax, [dump_orig_ss]
	mov	d [dump_orig_ss], -1
	cmp	eax, -1
	jz	short .current_ss

	to_hex	blue_ss
	mov	eax,[dump_orig_esp]
	to_hex	blue_esp
	jmp	short .end_ss
.current_ss:
	mov	eax, esp
	add	eax, b 30h
	to_hex	blue_esp
	mov	eax, ss
	to_hex	blue_ss
.end_ss:

	mov	eax, cr0
	to_hex	blue_cr0
	mov	eax, cr2
	to_hex	blue_cr2
	mov	eax, cr3
	to_hex	blue_cr3

	mov	eax, [esp + 2ch]	; eflags
	mov	edx, offset blue_flags +1

	test	ah, 004h	; OF
	setnz	bl
	or	bl, '0'
	mov	[edx],bl

	test	ah, 002h	; DF
	setnz	bl
	or	bl, '0'
	mov	[edx + 3*1],bl

	test	al, 040h	; Zero
	setnz	bl
	or	bl, '0'
	mov	[edx + 3*2],bl

	test	al, 020h	; Zero
	setnz	bl
	or	bl, '0'
	mov	[edx + 3*3],bl

	test	al, 001h	; Carry
	setnz	bl
	or	bl, '0'
	mov	[edx + 3*4],bl

	to_hex	blue_eflags

	;CPU��O�ɂ��Ăяo���H
	mov	ebx, offset regdump_msg
	mov	eax, [esp + 1ch]
	cmp	eax, 0ffh
	ja	.no_exception

	mov	dl, [err_max]
	cmp	al, dl
	jbe	.exp1
	mov	al, dl
.exp1:
	movzx	ecx, b [err_size]
	mul	ecx	; edx broken
	lea	ebx, [err_00 + eax]
	mov	edx, offset blue_intno
.loop:
	mov	al, [ebx]
	mov	[edx], al
	inc	ebx
	inc	edx
	loop	.loop
	mov	ebx, offset blue_screen
	jmp	short .print

.no_exception:
	cmp	d [esp+20h], -2
	jne	.print
	PRINT	string_return
	PRINT	offset regdump_ds
	PRINT	string_crlf
	jmp	short .exit

.print:
	PRINT	ebx
.exit:
	pop	eax
	pop	ebx
	pop	ecx
	pop	edx
	ret

;================================================
;convert to hex
;================================================
; EAX �� [EDX] �ւP�U�i��������Ƃ��Ċi�[
	align 4
eax2hex:
	mov	bl,[edx+4]
	cmp	bl,'_'
	jz	.loop
	shl	eax, 16
.loop:
	mov	ebx, eax
	shr	ebx, 28
	mov	 cl, [hex_str + ebx]
	mov	[edx], cl
	inc	edx
	shl	eax, 4

	mov	bl, [edx]
	cmp	bl, ' '
	jz	.end
	cmp	bl, ':'
	jz	.end
	cmp	bl, 'h'
	jz	.end
	cmp	bl, 13
	jz	.end

	cmp	bl, '_'
	jnz	.loop
	inc	edx
	jmp	short .loop
.end:
	ret

;##############################################################################
;findpath  -  search PATH
;	This is PDS.
;	made by ����@ABK  2000/07/24
;##############################################################################
;
; 2001/01/31	Free386 �ւ̑g�ݍ��� (by nabe@abk)
;
;------------------------------------------------------------------------------
;���{��
;------------------------------------------------------------------------------
;
; searchpath
;
;in:
;	[esi]	�v���O������
;	[ebx]	���ϐ���
;ret:
;	eax	0=��������
;		  [edi]	�������ʃv���O������
;		1=�v���O�����t�@�C�����Ȃ�
;		2=�Y�����閼�O�̊��ϐ����Ȃ�
;
	align	4
searchpath:
		;�ŏ��ɃJ�����g�f�B���N�g����T��
		mov	edx, esi		; �t�@�C����
		call	is_file_exist
		jc	.search_current_add_EXP
		mov	edi, esi
		mov	eax, 0
		ret


	align	4
.search_current_add_EXP:
		push	esi
		mov	ecx, 0
.search_current_add_EXP_strcpy:
		mov	al, [esi]
		mov	[nowpath + ecx], al
		inc	esi
		inc	ecx
		or	al, al
		jnz	.search_current_add_EXP_strcpy
		
		pop	esi
		
		mov	d [nowpath + ecx - 1], '.EXP'
		mov	b [nowpath + ecx + 3], 0
		mov	edx, offset nowpath
		call	is_file_exist
		jc	.search_path
		
		mov	edi, offset nowpath
		mov	eax, 0
		ret
		
.search_path:
		call	___getenv_2
		or	eax, eax
		jz	.ng_env_notfound

.search_next:
		call	getnextpath_
		or	eax, eax
		jz	.no_program

		call	add_progname_
		
		mov	edx, offset nowpath	; �t�@�C����
		call	is_file_exist		; ���݌���
		
		jc	.add_EXP
		
		mov	edi, offset nowpath
		mov	eax, 0
		ret
		
.add_EXP:
		mov	edx, offset nowpath
		mov	eax, [nowpath_len]
		mov	byte [edx + eax], '.'
		
;	push	esi
;	mov	esi, edx
;	call	print_sz
;	pop	esi
		
		call	is_file_exist
		
		jc	.not_found
		
		mov	edi, offset nowpath
		mov	eax, 0
		ret
.not_found:
		jmp	.search_next

.no_program:
		mov	eax, 2
		ret

.ng_env_notfound:
		mov	eax, 1
		ret

; ���ϐ����Ȃ�
.ng_notfound:
		mov	eax, 2
		ret


;�t�@�C�����J���邩����
;
;in:
;	[edx]	�t�@�C����
;ret:
;	Cy	0 �t�@�C��������
;		1 �t�@�C�����Ȃ�
;
is_file_exist:
		push	eax
		push	ebx
		
		mov	ah, 03Dh		; File/Device open
		mov	al, 000b		; �ǂݍ��݂̂�
		int	021h
		jnc	.file_found

		jmp	.ret

.file_found:
		mov	bx, ax		; BX=�n���h��
		mov	ah, 03Eh	; File/Device Close
		int	21h
		jmp	.ret
.ret:
		pop	ebx
		pop	eax
		ret

;
; ���ϐ����擾
;
;in:
;	[ebx]		�擾���ׂ����ϐ���
;ret:
;	eax		���� (0=���s�A����ȊO=����)
;	edi		���ʂ̊��ϐ��l ('='���E��)
;
___getenv_2:
		push	esi
		push	edi
		
		mov	ax, 02Ch
		mov	es, ax		; 02Ch = ���ϐ��ւ̃Z���N�^
		mov	edi, 0		; ���ϐ��Z���N�^�I�t�Z�b�g�[��
		
		;���ϐ������񒷂��擾
		mov	ecx, -1
		mov	esi, ebx
.envlencnt:
		inc	ecx
		cmp	byte [esi + ecx], 00h
		jnz	.envlencnt
		mov	eax, ecx
		

	align	4
.loop:
		mov	ecx, eax		; ECX��EAX(���ϐ�����)
		mov	esi, ebx		; ESI��EBX(���ϐ���)
		
		cmp	byte [es:edi], 00h	; ���ϐ����X�g�I�[�������H
		jz	.ng			; �I�[�����Ȃ�I��
		cld
		
	repz	cmpsb				; �����񌟍�
		
		jecxz	.ok
		
	align	4
.loop2:
		cmp	byte [es:edi], 00h	; ���ϐ���S�Ďg�������Ă���
		pushfd				; ����������Ȃ��̂Ō���(����
		inc	edi			; ���ϐ����܂ŃX�L�b�v������
		popfd				; ���˂Ă���)
		jnz	.loop2			;
		jmp	.loop
.ng:
		mov	eax, 0
		jmp	.ret
.ok:
		cmp	byte [es:edi], '='	; �C�R�[���L�����ǂ��� '='�H
		jnz	.loop2
		
		mov	eax, 1
		inc	edi
		mov	[nowenv], edi
		
		jmp	.ret
.ret:
		pop	edi
		pop	esi
		ret

;
;getnextpath	���� PATH �v�f�𓾂�
;
;��FA:\DOS;A:\TOOL;A:\GAME;A:\TC\BIN'\0'
;          ��      ��      ��        ��
;
;in:
;	���ɂȂ�
;ret:
;	eax	0=���s
;	nowpath	����ꂽ�f�B���N�g����
;
getnextpath_:
		push	esi
		
		mov	ecx, 0
		mov	esi, [nowenv]
		mov	ax, 02Ch
		mov	es, ax
		
		cmp	b [es:esi], 0
		jz	.no_more
		
.cpy_to_buf:
		mov	al, [es:esi]
		mov	b [nowpath + ecx], al
		inc	esi
		inc	ecx
		
		cmp	al, 00h
		jz	.cpy_to_buf_end_zero
		cmp	al, ';'
		jnz	.cpy_to_buf
		jmp	.cpy_to_buf_end
		
.cpy_to_buf_end_zero:
		dec	esi
.cpy_to_buf_end:
		dec	ecx
		mov	b [nowpath + ecx], 00h
		mov	[nowenv], esi
		mov	[nowpath_len], ecx
		
		pop	esi
		mov	eax, 1
		ret
.no_more:
		mov	eax, 0
		pop	esi
		ret

;
;�v���O��������t������
;
;
;
	align	4
add_progname_:
		push	edi
		push	esi
		
		mov	edi, offset nowpath
		add	edi, [nowpath_len]
		
		cmp	d [nowpath_len], 0
		jz	.loop
		cmp	b [edi - 1], '\'
		jz	.loop
		mov	b [edi], '\'
		mov	b [edi + 1], 0
		inc	edi
		
	align	4
.loop:
		mov	al, [esi]
		mov	[edi], al
		inc	esi
		inc	edi
		or	al, al
		jnz	.loop

		mov	d [edi], 'EXP'
		dec	edi
		sub	edi, offset nowpath
		mov	d [nowpath_len], edi

		;�����p�X�̕\��
		;;mov	esi, nowpath
		;;call	print_sz

		pop	esi
		pop	edi
		ret


;##############################################################################
;##############################################################################
; under is presented by nabe@abk.
;/////////////////////////////////////////////////////////////////////////////
;��.EXP �t�@�C���̃��[�h
;/////////////////////////////////////////////////////////////////////////////
;	2001/02/15	F386prot.asm ����ړ�
;
;	IN	[edx]	�t�@�C���� (ASCIIz)
;		[esi]	�o�b�t�@�A�h���X(min 200h)
;
;	Ret	Carry = 0 / ���[�h����
;		fs	���[�h�v���O���� cs
;		gs	���[�h�v���O���� ds
;		edx	���[�h�v���O���� EIP
;		ebp	���[�h�v���O���� ESP
;
;		Carry = 1 / ���[�h���s
;		ah	�G���[�R�[�h (F386�����G���[�R�[�h�Ɠ���)
;
;------------------------------------------------------------------------------
;��EXP �t�@�C���̃��[�h
;------------------------------------------------------------------------------
proc load_exp
	push	ds			;�Ō�ɐςނ���
	mov	es,[esp]		;es �ɐݒ�

	;/// �t�@�C���I�[�v�� ///
	;mov	edx,[�t�@�C����]	;�t�@�C���� ASCIIz
	mov	ax,3d00h		;file open(read only)
	int	21h			;dos call
	jc	NEAR .file_open_error	;Cy=1 �Ȃ�I�[�v���G���[

	mov	ebx,eax			;bx <- file handl�ԍ�
	mov	[file_handle],eax	;�������������ɂ��L�^

	;
	;�w�b�_�����[�h
	;
	mov	edx,esi			;���[�N�A�h���X
	mov	ecx,200h		;�ǂݍ��ރo�C�g��
	mov	ah,3fh			;file read ->ds:edx
	int	21h			;dos call
	jc	NEAR .file_read_error	;Cy=1 �Ȃ烊�[�h�G���[

	;
	;�w�b�_�����
	;
	mov	eax,[esi]
	cmp	eax,00013350H		;P3 �`��['P3']�E�t���b�g���f��[w (0001)]
	jne	NEAR .load_MZ_exp	;P3 �łȂ���� MZ�w�b�_���m�F (jmp)

	;
	;�K�v�ȃ������Z�o
	;
	mov	ecx,[esi+74h]	;���[�h�C���[�W�̑傫���i�v���O�����̃T�C�Y�j

	mov	eax,ecx
	add	eax,[esi+56h]	;�t�@�C���̌��Ɋ��蓖�Ă郁�����̍ŏ���
	add	eax,     0fffh	;4KB �P�ʂŃ������������̂Œ[���J��グ
	and	eax,0fffff000h	;4KB �P�ʂ�
	mov	[5ch],eax	;PSP �ɋL�^ /�Œ���K�v�ȃ������T�C�Y[byte]

	add	ecx,[esi+5ah]	;�t�@�C���̌��Ɋ��蓖�Ă郁�����̍ő��
	jnc	.step		;�l�I�[�o�[���ĂȂ���� jmp
	mov	ecx,0fffff000h	;�ő�l
.step:	add	ecx,     0fffh	;4KB �P�ʂŃ������������̂Œ[���J��グ
	shr	ecx,12		;4KB �P�ʂ�

	push	esi
	mov	esi,[esi+5eh]		;�x�[�X�������A�h���X
	call	make_cs_ds		;cs/ds �쐬�ƃ������m��
	pop	esi
	jc	NEAR .not_enough_memory	;�G���[�Ȃ烁�����s��

	;
	;�������ʃ`�F�b�N
	;
	mov	ebx,[60h]		;���ۂɊ��蓖�Ă������� [byte]
	mov	eax,[5ch]		;PSP �ɋL�^ / �Œ���K�v�ȃ����� [byte]
	cmp	ebx,eax			;�l��r
	jb	NEAR .not_enough_memory	;�����Ȃ烁�����s��

	sub	ebx,[esi+74h]		;���[�h�C���[�W�̑傫��������
	mov	[64h],ebx		;�q�[�v���������ʂ� PSP�ɋL�^

	;
	;���[�h�v���O�����̃X�^�b�N�Ǝ��s�J�n�A�h���X���L�^
	;
	mov	eax,[esi + 62h]	;�X�^�b�N�|�C���^
	mov	ebx,[esi + 68h]	;���s�J�n�A�h���X
	mov	[data3],eax	;esp
	mov	[data4],ebx	;eip

	;
	;�������v���O�������[�h������
	;
	mov	ebx,[file_handle]	;ebx <- �t�@�C���n���h���ԍ����[�h
	mov	 dx,[esi + 26h]		;�v���O�����܂ł̃t�@�C�����I�t�Z�b�g
	mov	 cx,[esi + 28h]		; bit 31-16
	mov	ax,4200h		;�t�@�C���擪����|�C���^�ړ�
	int	21h			;dos call�ifile pointer = cx:dx�j
	jc	.file_read_error	;Cy=1 �Ȃ� �G���[

	mov	ecx,[esi + 2ah]		;�ǂލ��ރT�C�Y�i�v���O�����T�C�Y�j
	mov	edx,[esi + 5eh]		;�ǂݍ��ސ擪������(ds:edx)
					;+5eh �ɂ�"�x�[�X�A�h���X"������
	mov	 ds,[Load_ds]		;���[�h��Z���N�^�l���[�h

	;
	;-PACK �Ń����N���� PACK ����Ă��邩�`�F�b�N
	;
	mov	eax,[es:esi+72h]	;�w�b�_�� �t���O�����l
	test	al,01h			;bit 0 �� check

	push  d offset .sl_un_pack_ret	;call �̖߂胉�x��
	jnz	NEAR exp_un_pack_fread	;PACK �������Ȃ���t�@�C���ǂݍ���
	add	esp,byte (4)		;�X�^�b�N����(�߂胉�x��)


.file_read:		;MZ �w�b�_���[�h����Ă΂��
	;
	;�t�@�C�����[�h
	; ds:edx �� ecx �o�C�g�ǂݍ���
	;
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	.file_read_error	;�L�����[�� 1 �Ȃ� ���[�h�G���[


	align	4
.sl_un_pack_ret:
	mov	ah,3eh			;�t�@�C���N���[�Y
	int	21h			;dos �R�[��

	pop	ds
	mov	ebp,[data3]		;esp
	mov	edx,[data4]		;eip
	mov	 fs,[Load_cs]		;cs
	mov	 gs,[Load_ds]		;ds
	clc				;�L�����[�N���A
	ret

.file_read_error:
	mov	ds, [esp]		;�X�^�b�N�g�b�v���� DS ����
	mov	ebx,[file_handle]	;ebx <- �t�@�C���n���h���ԍ����[�h
	mov	ah,3eh			;�t�@�C���N���[�Y
	int	21h			;dos call
.file_open_error:
	mov	ah,22			;'File read error'
	pop	ds
	stc				;�L�����[�Z�b�g
	ret

.not_enough_memory:
	mov	cl,23			;'Memory is insufficient'
.fclose_end:
	pop	ds

	mov	ebx,[file_handle]	;ebx <- �t�@�C���n���h���ԍ����[�h
	mov	ah,3eh			;�t�@�C���N���[�Y
	int	21h			;dos call

	mov	ah,cl			;ah = �G���[�R�[�h
	stc				;�L�����[�Z�b�g
	ret

.ftype_error:
	mov	cl,24			;'Unknown EXP header'
	jmp	short .fclose_end	;�t�@�C�����N���[�Y���Ă���I��



;----------------------------------------------------------------------
;��MZ �w�b�_������ EXP �t�@�C���̃��[�h
;----------------------------------------------------------------------
;	mov	eax,[esi]
;	cmp	eax,00013350H	;P3 �`��['P3']�E�t���b�g���f��[w (0001)]
;	jne	NEAR check_MZ	;P3 �łȂ���� MZ�w�b�_���m�F (jmp)
;
	align	4
.load_MZ_exp:

	;////////////////////////////////////////////////////
	;MZ(MP) �w�b�_�ɑΉ����Ȃ��ꍇ
	;////////////////////////////////////////////////////
%if (USE_MZ_EXP = 0)
	jmp	short .ftype_error	;MZ �w�b�_�ɑΉ����Ȃ�
%else

	;////////////////////////////////////////////////////
	;MZ(MP) �w�b�_���[�h���[�`��
	;////////////////////////////////////////////////////
	cmp	ax,'MP'			;MZ(MP) �w�b�_?
	jne	.ftype_error		;������� ���Ή��`��

	;
	;�K�v�ȃ������Z�o
	;
	;+02h   file size & 511
	;+04h  (file size + 511) >> 9   / thanks to Mamiya (san)
	;
	mov	ebp,eax		;ebp = eax
	shr	ebp,16		;+02 w "�t�@�C���T�C�Y / 512" �̗]��
	movzx	eax,w [esi+04h]	;+04 w "512 byte �P�ʂ̃u���b�N��"
	movzx	edx,w [esi+08h]	;+08 w "�w�b�_  �T�C�Y / 16"
	movzx	ecx,w [esi+0ah]	;+0A w "�q�[�v�̍ŏ��� / 4KB"
	shl	eax,9		;512�{
	shl	edx,4 		; 16�{
	shl	ecx,12		;4K(4096)�{

	or	eax,ebp		;eax = (512 byte�u���b�N��)*512 + 511�ȉ��̒[��
	test	ebp,ebp		;ebp = 0 ?
	jz	.step2		;0 �Ȃ� jmp
	sub	eax,512		;�[������Ȃ� 512 byte ���� / eax = file size
.step2:
	sub	eax,edx		;eax = �v���O�����C���[�W�T�C�Y
	mov	ebp,eax		;���[�h�C���[�W�T�C�Y��ۑ����Ă���
	xchg	eax,ecx		;eax=�Œ���K�v�ȃ����� ecx=�v���O�����T�C�Y

	;���F�ȉ��A�t�@�C���|�C���^�ړ��܂� edx,ebp ��j�󂵂Ȃ�����

	movzx	ebx,w [esi+0ch]	;+0C w "�q�[�v�̍ő�v���� / 4KB"
	add	ecx,0fffh	;4KB�����؏グ
	shr	ecx,12		;/4KB
	add	ecx,ebx		;ecx = �ő�v����������
	;/// ecx = �ő�v��������
	push	esi
	xor	esi,esi			;�x�[�X�������A�h���X = 0
	call	make_cs_ds		;cs/ds �쐬�ƃ������m��
	pop	esi
	jc	.not_enough_memory	;�G���[�Ȃ烁�����s��

	;
	;�������ʃ`�F�b�N
	;
	mov	ebx,[60h]		;���ۂɊ��蓖�Ă������� [byte]
	mov	[5ch],eax		;PSP �ɋL�^ / �Œ���K�v�ȃ����� [byte]
	cmp	ebx,eax			;�l��r
	jb	.not_enough_memory	;�����Ȃ烁�����s��

	sub	ebx,ebp			;���[�h�C���[�W�̑傫��������
	mov	[64h],ebx		;PSP�ɋL�^ / �q�[�v���������� [byte]

	;
	;�X�^�b�N�� exp �̂��̂ɕύX
	;
	mov	eax,[esi + 0eh]	;�X�^�b�N�|�C���^
	mov	ebx,[esi + 14h]	;���s�J�n�A�h���X
	mov	[data3],eax	;esp
	mov	[data4],ebx	;eip

	;
	;�ȉ��AP3 �̃R�s�[
	;
	mov	ebx,[file_handle]	;ebx <- �t�@�C���n���h���ԍ����[�h
	xor	ecx,ecx			;ecx = 0
	;mov	edx,---		;�����	;edx = �v���O�����C���[�W�܂ł� offset
	mov	ax,4200h		;�t�@�C���擪����|�C���^�ړ�
	int	21h			;DOS call�ifile pointer = cx:dx�j
	jc	NEAR .file_read_error	;Cy=1 �Ȃ� �G���[

	mov	ecx,ebp			;�ǂލ��ރT�C�Y�i�v���O�����T�C�Y�j
	xor	edx,edx			;�ǂݍ��ސ擪������(ds:edx)

	mov	edi,[Load_ds]		;���[�h��Z���N�^�l���[�h
	mov	 ds,edi			;

	jmp	.file_read		;���ۂ̓ǂݍ��ݏ��� (P3 Header �Ƌ���)
%endif


;======================================================================
;��EXP �� PACK ��n���Ȃ���t�@�C�������[�h����T�u���`�[�� (P3�w�b�_)
;======================================================================
;
;	special thanks to PEN@�C�L ���i�����񋟁j
;
;	in	   ebx = �t�@�C���n���h���ԍ�
;		ds:edx = �t�@�C����ǂݍ��ރ������ʒu
;		   ecx = �t�@�C����ǂݍ��ރT�C�Y
;
;		es:esi = ���[�N������(200h byte)
;
	align	4
exp_un_pack_fread:
	push	ebp
	push	edi

	mov	ebp,ecx		;ebp = �ǂݍ��ރo�C�g��

	;
	;�Z�O�����g���W�X�^ ds�es �̌���
	;
	mov	eax,es
	mov	ecx,ds
	mov	 ds,eax
	mov	 es,ecx
	mov	[data1],eax	;���̃v���O����
	mov	[data2],ecx	;�ǂݍ��ݐ�

	;
	;���ɂ�� ds �����̃Z�O�����g�������悤�ɂȂ���
	;
	mov	edi,edx			;edi <- �t�@�C���ǂݍ��ݐ�
	mov	edx,esi			;edx <- ���[�N������
	mov	[data0],esi		;�ėp�ϐ��Ɉꎞ�I�ɋL��


	align	4
exp_up_loop:	;*** ���[�v�X�^�[�g ****************************
	;
	;ds:edx = ���[�N������
	;es:edi = �t�@�C�����[�h�̈�
	;   ebx = �t�@�C���n���h���ԍ�
	;   ebp = �c��ǂݍ��݃o�C�g��

	test	ebp,ebp			;�c�� byte ��
	jz	exp_up_fread_eof	;if 0 jmp �����I��

	;
	; 2 byte ���[�h
	;
	mov	ecx,2			;2 byte
	sub	ebp,ecx			;ebp = �c��T�C�Y
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	short exp_up_fread_err	;�L�����[������΃��[�h�G���[
	test	ax,ax			;ax ���m�F
	jz	short exp_up_fread_eof	;0 �Ȃ� EOF �ł���

	xor	eax,eax			;eax �̏��16bit �N���A
	mov	 ax,[edx]		;eax <- �ǂݍ��񂾃f�[�^
	bt	eax,15			;�r�b�g 15 ���m�F
	jc	short pack_length	;1 �Ȃ�p�b�N����Ă���

	;
	;�p�b�N����Ă��Ȃ�$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	;
	mov	edx,edi			;edx <- �v���O�������[�h�̈�
	mov	ecx,eax			;ecx = �ǂݍ��ރo�C�g��
	sub	ebp,eax			;ebp = �c��T�C�Y
	add	edi,eax			;���[�h�o�C�g�������v���O�������[�h�̈�
					; �̃A�h���X���X�e�b�v����

	mov	 ds, [data2]		;ds = �t�@�C�����[�h�̈�

	;
	;ds:edx = �v���O�������[�h�̈�
	;
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	short exp_up_fread_err	;�L�����[������΃��[�h�G���[

	mov	 ds, [cs:data1]		;���̃v���O������ ds
	mov	edx, [data0]		;���[�N�G���A�I�t�Z�b�g��߂�
	;
	;��ds:edx �����[�N�̈�ɕ���
	;

	jmp	exp_up_loop		;���[�v������***********



	;
	;/// ���[�`���I�� //////////////////////////////////////
	;
	align	4
exp_up_fread_eof:	;�t�@�C�����Ō�܂œǂ�ŁA������������
	;
	;�Z�O�����g���W�X�^ ds�es �����ɖ߂�
	;
	mov	 es,[data1]	;���̃v���O����
	mov	 ds,[data2]	;���[�h�̈�

	pop	edi
	pop	ebp
	ret

	;
	;/// �t�@�C���ǂݍ��ݎ��̃G���[ ////////////////////////
	;
	align	4
exp_up_fread_err:
	pop	edi
	pop	ebp
	add	esp,4				;�߂胉�x������
	jmp	load_exp.file_read_error	;�G���[�ɂ��E�o
	;///////////////////////////////////////////////////////



	align	4
	;
	;PACK ����Ă��� $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	;
pack_length:
	and	eax,7fffh	;�r�b�g15 �� 0 �ɂ���
	mov	esi,eax		;esi �ɒl�L��

	dec	ebp			;ebp = �c��o�C�g��
	mov	ecx,1			;1 byte
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	short exp_up_fread_err	;�L�����[������΃��[�h�G���[

	xor	eax,eax			;eax �N���A
	mov	al,[edx]		;�ǂݍ��񂾒l���m�F
	test	al,al			;��and al,al
	jnz	short str_length	;0 �łȂ���Ε�����̌J��Ԃ����k

	;
	;NULL �R�[�h�̃����O�X���k�ł���
	;
	mov	ecx,esi			;�w��o�C�g����
	rep	stosb			;NULL ��W�J���� ->es:edi

	jmp	exp_up_loop		;���[�v������***********



	align	4
	;
	;������� PACK ����Ă��� $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	;
str_length:
	mov	cl,al			;ecx <- �J��Ԃ�������̒���
	sub	ebp,eax			;ebp = �c��o�C�g��
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	short exp_up_fread_err	;�L�����[������΃��[�h�G���[

	push	ebx			;ebx �ۑ�
	xor	ebx,ebx			;ebx �N���A

	mov	ah,cl			;ah <- ������̒���
	mov	ecx,esi			;�R�s�[�o�C�g��

	align	4
str_length_loop:
	mov	al,[edx + ebx]		;�����񃍁[�h
	inc	bl			;��������I�t�Z	�b�g�X�e�b�v
	cmp	bl,ah			;�������Ɣ�r
	je	short strl_lp_offsetc	; 0 �Ȃ�I�t�Z�b�g�N���A

	mov	[es:edi],al		;1 byte ��������
	inc	edi			;�A�h���X�X�V
	loop	str_length_loop		;ecx ���J�E���^�� 0 �ɂȂ�܂Ń��[�v

	pop	ebx
	jmp	exp_up_loop		;���[�v������***********

	align	4
strl_lp_offsetc:	;ebx �� 0 �Ƀ��[�v������
	xor	bl,bl			;ebx = 0

	mov	[es:edi],al		;1 byte ��������
	inc	edi			;�A�h���X�X�V
	loop	str_length_loop		;ecx ���J�E���^�� 0 �ɂȂ�܂Ń��[�v

	pop	ebx
	jmp	exp_up_loop		;���[�v������***********


;======================================================================
;���v���O���������[�h����Z���N�^���쐬����T�u���`�[��
;======================================================================
;����	ecx	�v���ő��(page)
;	esi	�ǂݍ��ݐ�����炷��(P3�w�b�_ -offset �I�v�V����)
;
;Ret	Cy=0 ����
;		���ۂ̊��蓖�ė�(byte)�� PSP �� [60h] �ɋL�^
;		Load_cs, Load_ds �Ƀ��[�h�p�Z���N�^�� cs/ds �L�^
;	Cy=1 ���s
;
	align	4
	global	make_cs_ds
make_cs_ds:
	push	eax
	push	ecx
	push	edx
	push	esi
	push	ebp

	mov	ebp,[free_RAM_pages]	;�󂫃������Ɣ�r
	add	ebp,[DOS_mem_pages]	;DOS������

	mov	[60h],esi		;save base offset
	mov	edx,esi			;�ǂݍ��݃x�[�X
	shr	edx,12			;page�P�ʂ̂��� / ���܂Ŕj�󂵂Ȃ�����

	mov	eax,ecx			;���蓖�ėv����
	add	eax,edx			;eax = �K�v�A�h���X��
	add	eax,3ffh		;�[���؎̂�
	shr	eax,10			;eax = �y�[�W�e�[�u���p�ɕK�v�ȃ�����
	add	eax,ecx			;�v���ʂ̃��������쐬����ɕK�v�ȃ�����
	cmp	eax,ebp ;=free_pages	;�󂫃������Ɣ�r
	jbe	.do_alloc		;�����΃��������蓖�Ă�jmp

.alloc_all:	;�S�󂫃��������蓖��
	mov	ecx,ebp ;=free_pages	;�󂫃����������[�h
	movzx	eax,b [pool_for_paging]	;�v�[����������
	sub	ecx,eax			;�\�񃁃����y�[�W��������
	ja	.mem_pool		;0 �ȏ�Ȃ� jmp
	add	ecx,eax			;�l�����ɖ߂�(�v�[�����Ȃ�)
.mem_pool:
	mov	eax,ecx			;�S�󂫃y�[�W��
	add	eax,edx			;�A�h���X���ꕪ�̃A�h���X��
	add	eax,3ffh		;�[���؏グ
	shr	eax,10			;eax = �y�[�W�e�[�u���p�ɕK�v�ȃ�����
	sub	ecx,eax			;�󂫃y�[�W���������
	jb	near .no_memory		;�}�C�i�X�Ȃ�G���[
.do_alloc:
	mov	ebp, [free_liner_adr]	;�\��t����A�h���X��ۑ�
	push	esi
	and	esi, 0xfffff000		;���炵��
	add	esi, ebp		;�󂫃��j�A�A�h���X�ɉ��Z
	mov	[free_liner_adr], esi	;���炷
	pop	esi

	push	ecx
	call	alloc_DOS_mem		;DOS��������擪�Ɋ��蓖��
	pop	ecx
	jc	.no_memory		;�G���[jmp

	push	ecx
	sub	ecx, eax		;���蓖�čσy�[�W��������
	call	alloc_RAM		;���������蓖��
	pop	ecx		; ecx�͂܂��g��
	jc	.no_memory		;�G���[jmp

	;�Z���N�^�쐬
	call	search_free_LDTsel	;eax = �󂫃Z���N�^
	jc	.no_selector		;if �G���[ jmp
	mov	[Load_cs],eax		;�Z���N�^�l�L�^

	mov	edi,[work_adr]		;edi ���[�N�A�h���X
	add	ecx,edx			;�I�t�Z�b�g�̂�������Z
	dec	ecx			;page�� -1
	mov	[edi  ],ebp		;�x�[�X
	mov	[edi+4],ecx		;limit
	mov	d [edi+8],0a00h		;R/X �^�C�v / �������x��=0

	mov	esi, [60h]		;load base offset
	inc	ecx			;ecx = �T�C�Y (page)

	shl	ecx, 12			;ecx = �T�C�Y (byte)
	sub	ecx, esi		;�x�[�X�I�t�Z�b�g������
	mov	[60h],ecx		;PSP �̈�ɋL�^
	call	make_mems_4k		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;ds �쐬
	call	search_free_LDTsel	;eax = �󂫃Z���N�^
	jc	.no_selector		;if �G���[ jmp
	mov	[Load_ds],eax		;�Z���N�^�l�L�^

	mov	ebx,[Load_cs]		;�R�s�[��
	mov	ecx,eax			;�R�s�[��
	mov	 ax,0200h		;R/W �^�C�v / �������x��=0
	call	make_alias		;�G�C���A�X�쐬

	clc				;����I��
.exit:
	pop	ebp
	pop	esi
	pop	edx
	pop	ecx
	pop	eax
	ret

.no_memory:
.no_selector:
	stc
	jmp	.exit


;=============================================================================
;�����[�h�����v���O���������s����T�u���[�`��
;=============================================================================
;	IN	fs	���[�h�v���O���� cs
;		gs	���[�h�v���O���� ds
;		edx	���[�h�v���O���� EIP
;		ebp	���[�h�v���O���� ESP
	align	4
run_exp:
	mov	eax,gs			;DS
	mov	 ss,eax			;
	mov	esp,ebp			;�X�^�b�N�؂�ւ�

	push	fs			;cs
	push	edx			;EIP

	mov	ds,eax			;
	mov	es,eax			;�Z���N�^�����ݒ�
	mov	fs,eax			;
	mov	gs,eax	; �ݒ��

	;
	;�S�Ă̔ėp���W�X�^�N���A�i�N�����̏����l�j
	;
	xor	eax,eax
	xor	ebx,ebx
	xor	ecx,ecx
	xor	edx,edx
	xor	edi,edi
	xor	esi,esi
	xor	ebp,ebp

	;
	;�������ړI�v���O�����̎��s������
	;
	retf		;far return

;******************************************************************************
;���f�[�^
;******************************************************************************
segment	data align=4 class=CODE use16
group	comgroup text data

;------------------------------------------------------------------------------
;�E���W�X�^�_���v�\��
;------------------------------------------------------------------------------
; db "Expection Interrupted : INT 00h -                                 ",13,10
; db "ErrorCode = ####_####  CS:EIP = ####:####_####  EFLAGS = ####_####",13,10
; db "DS = ####  ES = ####  SS = ####  FS = ####  GS = ####             ",13,10
; db "CR0 = ####_####  CR1 = ****_****  CR2 = ####_####  CR3 = ####_####",13,10
; db "EAX = ####_####  EBX = ####_####  ECX = ####_####  EDX = ####_####",13,10
; db "ESI = ####_####  EDI = ####_####  EBP = ####_####  ESP = ####_####",13,10
; db "$"

blue_screen:	;;	db 01Bh,"[46m"
		db "----------------------------------------"
		db "--------------------------",13,10
		db "Expection Interrupted : INT "
blue_intno	db "##h -                                 ",13,10,
regdump_msg	db "Err = " ;blue_err_str�ŏ���������̂ŕύX���͒���
blue_errorcode	db "####_####  "
blue_cseip	db "CS:EIP = "
blue_cs		db "####:"
blue_eip	db "####_####   SS:ESP = "
blue_ss		db "####:"
blue_esp	db "####_####",13,10,
regdump_ds	db " DS = "
blue_ds		db "####        ES = "
blue_es		db "####        FS = "
blue_fs		db "####        GS = "
blue_gs		db "####",13,10,"EAX = "
blue_eax	db "####_####  EBX = "
blue_ebx	db "####_####  ECX = "
blue_ecx	db "####_####  EDX = "
blue_edx	db "####_####",13,10,"ESI = "
blue_esi	db "####_####  EDI = "
blue_edi	db "####_####  EBP = "
blue_ebp	db "####_####  FLG = "
blue_eflags	db "####_####",13,10,"CR0 = "
blue_cr0	db "####_####  CR2 = "
;blue_cr1 / CPU �ɑ��݂��Ȃ�
blue_cr2	db "####_####  CR3 = "
blue_cr3	db "####_####  "
blue_flags	db "O  D  S  Z  C  ",13,10
		db "----------------------------------------"
		db "--------------------------",13,10
;;		db 0x1b,"[40;0m"
		db "$"
string_return	db '*Ret:*'
string_crlf	db 13,10,'$'

blue_err_str	db	"Err "
blue_int_str	db	"Int "

extern	hex_str		;Definded in sub.asm
;hex_str 	db	'0123456789ABCDEF'

err_size	db	34
err_max		db	12h
			;1234567890123456789012345678901234
err_00		db	'00h - Zero Divide Error           '
err_01		db	'01h - Debug Exceptions            '
err_02		db	'02h - NMI                         '
err_03		db	'03h - Breakpoint                  '
err_04		db	'04h - INTO Overflow Fault         '
err_05		db	'05h - Bounds Check Fault          '
err_06		db	'06h - Invalid Opcode Fault        '
err_07		db	'07h - Coprocessor Not Available   '
err_08		db	'08h - Double Fault                '
err_09		db	'09h - Coprocessor Segment Overrun '
err_0a		db	'0Ah - Invalid TSS                 '
err_0b		db	'0Bh - Segment Not Present Fault   '
err_0c		db	'0Ch - Stack Exception Fault       '
err_0d		db	'0Dh - General Protection Exception'
err_0e		db	'0Eh - Page Fault                  '
err_0f		db	'0Fh - (CPU RESERVED)              '
err_10		db	'10h - Coprocessor Error           '
err_11		db	'11h - Alignment Fault             '
err_dmy		db	'1xh - Unknown (Stack broken?)     '

	align	4
dump_err_code	dd	-1
dump_orig_esp	dd	-1
dump_orig_ss	dd	-1

;------------------------------------------------------------------------------
;�E�t�@�C���p�X����
;------------------------------------------------------------------------------
	align	4
nowenv		dd	0
nowpath_len	dd	0
;nowpath_pos	dd	0

nowpath		db	"1234567890123456789012345678901234567890"
		db	"1234567890123456789012345678901234567890","1234"
		db	0
		db	'$',0,0,0

;------------------------------------------------------------------------------
;�Eexp �t�@�C���̃��[�h (routin made by nabe@abk)
;------------------------------------------------------------------------------
	align	4
data0		dd	0		;�f�[�^�ꎞ�ޔ�p
data1		dd	0		;
data2		dd	0		;
data3		dd	0		;
data4		dd	0		;

file_handle	dd	0		;�t�@�C���n���h��
Load_cs		dd	0		;���[�h��Z���N�^
Load_ds		dd	0		;



;##############################################################################
;##############################################################################
