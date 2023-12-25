;******************************************************************************
; subroutine for Free386
;******************************************************************************
;[TAB=8]
;
;------------------------------------------------------------------------------

%include "macro.inc"
%include "f386def.inc"

%include "start.inc"
%include "sub.inc"
%include "free386.inc"
%include "memory.inc"
%include "selector.inc"
;------------------------------------------------------------------------------
global	dump_orig_eax
global	dump_orig_ds
global	dump_orig_esp
global	dump_orig_ss
;------------------------------------------------------------------------------

seg32	text32 class=CODE align=4 use32
;##############################################################################
;register dump
;##############################################################################
;------------------------------------------------------------------------------
proc32 register_dump_iret
;------------------------------------------------------------------------------
	;	+08h eflags
	;	+04h cs
	; stack	+00h eip
	push	eax				; error code       is dummy
	push	eax				; interrupt number is dummy
	push	offset set_dump_head_is_reg	; callback function
	push	ds
	push	eax

	push	F386_ds
	pop	ds

	mov	eax, esp
	add	eax, 4 * 8
	mov	[dump_orig_esp], eax
	push	ss
	pop	dword [dump_orig_ss]

	; stack
	;	+1ch	eflags
	;	+18h	cs
	;	+14h	eip
	;	+10h	error code
	;	+0ch	interrupt number
	;	+08h	header handler address
	;	+04h	ds
	;	+00h	eax
	call	register_dump

	pop	eax
	pop	ds
	add	esp, 4 * 3
	iret


;------------------------------------------------------------------------------
proc32 set_dump_head_is_reg
;------------------------------------------------------------------------------
	; edi = ebp = buffer address
	mov	esi, offset regdump_hr
	call	copy_esi_to_edi
	mov	esi, offset dump_head_reg
	call	copy_esi_to_edi
	ret

;------------------------------------------------------------------------------
proc32 set_dump_head_is_fault
;------------------------------------------------------------------------------
	; ebx = int number
	; edx = error code
	; edi = ebp = buffer address
	;
	mov	esi, offset regdump_hr
	call	copy_esi_to_edi

	mov	esi, offset dump_head_fault
	call	copy_esi_to_edi

	push	edi
	mov	edi, ebp
	mov	eax, ebx
	call	rewrite_next_hash_to_hex	; int number

	add	edi, byte 4
	;
	; copy exception name
	;
	cmp	ebx, byte 11h
	ja	.unknown

	mov	esi, offset cpu_fault_name_table
.loop:
	test	ebx, ebx
	jz	short .copy_name
.zero_loop:
	lodsb
	test	al,al
	jnz	.zero_loop	; find 0
	dec	ebx
	jmp	short .loop
.unknown:
	mov	esi, offset cpu_fault_unknown
.copy_name:
	call	copy_esi_to_edi

	mov	eax, edx
	call	rewrite_next_hash_to_hex	; error code
	pop	edi
	ret

;------------------------------------------------------------------------------
proc32 copy_esi_to_edi
;------------------------------------------------------------------------------
.loop:
	lodsb
	test	al,al
	jz	.ret
	stosb
	jmp	short .loop
.ret:
	ret

;##############################################################################
; register dump main
;	original code by kattyo@ABK  2000/07/24
;##############################################################################
; in	 ds = F386_ds
; out	eax = destroy
;
proc32 register_dump
	call	get_gp_buffer_32
	test	eax, eax
	jnz	.step		; success
	ret			; alloc error
	;stack
	;	+20h	eflags
	;	+1ch	cs
	;	+18h	eip
	;	+14h	error code
	;	+10h	interrupt number
	;	+0ch	header handler address
	;	+08h	ds
	;	+04h	eax
	;memory
	;	[dump_orig_esp]
	;	[dump_orig_ss]
.step:
	cld
	pusha					; 20h bytes
	push	es
	%assign buf_adr		-4		; buffer address (eax)
	%assign	sdiff		 24h

	mov	eax, cr3
	push	eax
	mov	eax, cr2
	push	eax
	mov	eax, cr0
	push	eax				; 0ch bytes

	%assign	sdiff	sdiff + 0ch

	push	dword [esp + sdiff + 20h]	; eflags
	push	ebp
	push	edi
	push	esi				; esi

	push	edx
	push	ecx
	push	ebx

	%assign	sdiff	sdiff + 1ch

	push	dword [esp + sdiff + 04h]	; eax
	push	gs
	push	fs
	push	es

	%assign	sdiff	sdiff + 10h

	push	dword [esp + sdiff + 08h]	; ds
	push	dword [dump_orig_esp]
	push	dword [dump_orig_ss]

	%assign	sdiff	sdiff + 0ch

	push	dword [esp + sdiff + 18h]	; eip
	%assign	sdiff	sdiff + 04h
	push	dword [esp + sdiff + 1ch]	; cs
	%assign	sdiff	sdiff + 04h

	push	ds
	pop	es				; set es

	;------------------------------------------------------------
	; set flags
	;------------------------------------------------------------
	mov	eax, [esp + sdiff + 20h]	; eflags
	mov	edx, offset regdump_flags +1
	mov	 cl, '0'

	test	al, 01h		; Carry
	setnz	bl
	or	bl, cl
	mov	[edx + 3*0],bl

	test	al, 04h		; Parity
	setnz	bl
	or	bl, cl
	mov	[edx + 3*1],bl

	test	al, 40h		; Zero
	setnz	bl
	or	bl, cl
	mov	[edx + 3*2],bl

	test	al, 80h		; Sign
	setnz	bl
	or	bl, cl
	mov	[edx + 3*3],bl

	test	ah, 08h		; Overflow
	setnz	bl
	or	bl, cl
	mov	[edx + 3*4],bl

	test	ah, 04h		; Direction / DF
	setnz	bl
	or	bl, cl
	mov	[edx + 3*5],bl

	test	ah, 02h		; Interrupt Enable / IF
	setnz	bl
	or	bl, cl
	mov	[edx + 3*6],bl

	;------------------------------------------------------------
	; make message data
	;------------------------------------------------------------
	mov	ebp, [esp + sdiff + buf_adr]	; save buffer pointer
	mov	edi, ebp

	mov	ebx, [esp + sdiff + 10h]	; interrupt number
	mov	ecx, [esp + sdiff + 14h]	; error code

	call	near [esp + sdiff + 0ch]	; header set handler

	push	edi
	mov	esi, offset regdump_msg
	call	copy_esi_to_edi			; regdump message
	mov	byte [edi], '$'			; end mark for PRINT
	pop	edi

	;------------------------------------------------------------
	; rewrite register value
	;------------------------------------------------------------
	mov	ecx, 19
.loop_regs:
	pop	eax
	call	rewrite_next_hash_to_hex
	loop	.loop_regs

	PRINT32	ebp

	; free buffer
	mov	eax, ebp
	call	free_gp_buffer_32

	pop	es
	popa
	ret


;##############################################################################
; register dump for interrupt hook
;##############################################################################
%if INT_HOOK
;------------------------------------------------------------------------------
proc32 set_dump_head_is_int
;------------------------------------------------------------------------------
	; ecx = error code
	; edi = ebp = buffer address
	mov	esi, offset regdump_hr
	call	copy_esi_to_edi

	mov	esi, offset dump_head_int
	call	copy_esi_to_edi

	push	edi
	mov	edi, ebp
	mov	eax, ecx
	call	rewrite_next_hash_to_hex	; rewrite int number
	pop	edi
	ret

%if INT_HOOK_RETV
;------------------------------------------------------------------------------
proc32 set_dump_head_is_return
;------------------------------------------------------------------------------
	; ecx = error code
	; edi = ebp = buffer address
	mov	esi, offset dump_head_ret
	call	copy_esi_to_edi
	ret
%endif

;------------------------------------------------------------------------------
proc32 register_dump_from_int
;------------------------------------------------------------------------------
	push	set_dump_head_is_int
	push	ds
	push	eax
	;
	;stack
	;	+1ch	eflags
	;	+18h	cs
	;	+14h	eip
	;	+10h	int number
	;	+0ch	caller
	;	+08h	set header handler
	;	+04h	ds
	;	+00h	eax
	;
	%assign	cs_diff		18h
	%assign	intnum_diff 	10h
	%assign	ah_diff 	01h

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
		cmp	w [esp + cs_diff], INT_HOOK_CS
		jne	short .no_dump
	%endif
	;
	; exclude CS
	;
	%if INT_HOOK_EX_CS
		cmp	w [esp + cs_diff], INT_HOOK_EX_CS
		je	short .no_dump
	%endif
	;
	; Free386 internal call ignore
	;
	%if !INT_HOOK_F386
		cmp	w [esp + cs_diff], F386_cs
		je	short .no_dump
	%endif
	;
	; int 21h, ah=09h is ignore
	;
	cmp	b [esp + intnum_diff], 21h
	jnz	short .do_dump
	cmp	ah, 09h
	jz	short .no_dump
.do_dump:
	; stack
	;	+1ch	eflags
	;	+18h	cs
	;	+14h	eip
	;	+10h	int number
	;	+0ch	caller
	;	+08h	set header handler
	;	+04h	ds
	;	+00h	eax
	mov	eax, esp
	add	eax, 20h
	mov	[dump_orig_esp], eax
	push	ss
	pop	dword [dump_orig_ss]

	call	register_dump

	%if INT_HOOK_RETV
		cmp	b [esp + ah_diff],    4ch	; ah!=4ch
		jne	.do_dump_ret
		cmp	b [esp + intnum_diff],21h	; int 21h
		je	.no_dump
	.do_dump_ret:
		cmp	b [.in_dump], 0
		jnz	.no_dump
		mov	b [.in_dump], 1

		mov	eax, [esp + 14h]
		mov	[.orig_eip], eax
		mov	eax, [esp + 18h]
		mov	[.orig_cs],  eax
		mov	d [esp+14h], offset .int_retern
		mov	  [esp+18h], cs
	%endif

.no_dump:
	pop	eax
	pop	ds
	add	esp, byte 4		; <-- push set_dump_head_is_int
	ret

%if INT_HOOK_RETV
	align 4
.int_retern:
	pushf
	push	d [cs:.orig_cs]
	push	d [cs:.orig_eip]
	push	eax			; int number is dummy
	push	eax			; error code is dummy
	push	set_dump_head_is_return	; dump header handler
	push	ds
	push	eax

	push	d F386_ds
	pop	ds
	mov	b [.in_dump], 0

	mov	eax, esp
	add	eax, 20h
	mov	[dump_orig_esp], eax
	push	ss
	pop	dword [dump_orig_ss]

	call	register_dump

	pop	eax
	pop	ds
	add	esp, 0ch
	iret

	align	4
.in_dump	dd	0
.orig_eip	dd	0
.orig_cs	dd	0
%endif
%endif

;##############################################################################
; search PATH/ENV
;##############################################################################
;/////////////////////////////////////////////////////////////////////////////
; get ENV pointer by ENV name
;/////////////////////////////////////////////////////////////////////////////
; in	[ebx]	env name
;
; ret	cy=0	fs:[edx] target env value
;	cy=1	fs:[edx] env end after "00h 00h" or zero
;
proc32 search_env
	push	eax
	push	ebx
	push	ecx
	push	esi
	push	ebp

	mov	eax, DOSENV_sel
	mov	 fs, ax
	lsl	ebp, eax		; ebp = env selector limit

	xor	esi, esi
	jmp	short .compare		; find start

.next_env:
	add	esi, ecx
.next_env_loop:
	cmp	byte fs:[esi-1], 0
	je	.compare
	inc	esi
	dec	ebp
	jz	.not_found
	jmp	short .next_env_loop

.compare:
	xor	ecx, ecx		; need before "found_env_end"
	cmp	byte fs:[esi], 0	; ENV first byte is 0
	je	.found_env_end		; 
.compare_loop:
	mov	al, fs:[esi + ecx]	; ENV memory
	mov	dl,    [ebx + ecx]	; ENV name
	inc	ecx
	dec	ebp
	jz	.not_found

	test	al, al			; found 0 in ENV
	jz	.next_env

	test	dl, dl			; dl==0
	jnz	.skip
	cmp	al, '='
	je	.match
.skip:
	cmp	al, dl
	jne	.next_env
	jmp	.compare_loop


.match:
	mov	edx, esi
	add	edx, ecx	; edx = found address
	clc			; success
.ret:
	pop	ebp
	pop	esi
	pop	ecx
	pop	ebx
	pop	eax
	ret

.not_found:
	xor	edx, edx
	stc
	jmp	short .ret

.found_env_end:
	mov	edx, esi
	inc	edx
	stc
	jmp	short .ret



;/////////////////////////////////////////////////////////////////////////////
; search PATH, find file from PATH
;/////////////////////////////////////////////////////////////////////////////
; in	[esi]	find file name
;	[ebx]	env name
;	 edi	work address (size:100h)
;
; ret	fs	destroy
;	cy=0	found: store [edi] found file name
;	cy=1	not found
;
proc32 search_path_env
	pusha

	call	search_env	; fs:[edx] = ENV string
	jc	.fail
	cmp	byte fs:[edx],'0'
	je	.fail

	mov	ebp, edi	; ebp = save edi
.copy_path_start:
	mov	ecx, 0ffh -1	; ebp = file name limit, -1 for '\' mark

.copy_path:
	mov	al, fs:[edx]
	mov	[edi], al
	inc	edx
	inc	edi

	test	al, al
	jz	.copy_fname
	cmp	al, ';'
	je	.copy_fname

	loop	.copy_path
	jmp	short .fail	; buffer over flow

.copy_fname:			; copy file name
	mov	byte [edi-1], '\'

	xor	ebx, ebx
.copy_fname_loop:
	mov	al, [esi + ebx]
	mov	[edi + ebx], al
	test	al, al
	jz	.copy_finish

	inc	ebx
	loop	.copy_fname_loop
	jmp	short .fail	; buffer over flow

.copy_finish:
	;
	; edx = PATH + "\" + filename
	;
%if 0
	push	edx			; print path name for test
	mov	edx, ebp
	call	print_string_32
	pop	edx
%endif

	mov	edi, ebp
	call	check_readable_file
	jnc	.success

	cmp	byte fs:[edx-1], 0
	jne	.copy_path_start

.fail:
	stc
	popa
	ret

.success:
	;clc
	popa	; success
	ret


;/////////////////////////////////////////////////////////////////////////////
; check readable file
;/////////////////////////////////////////////////////////////////////////////
; in	[edi]	file name
; ret	cy=0	success
;	cy=1	fail
;
proc32 check_readable_file
	push	eax
	push	ebx
	push	edx

	mov	ah, 3dh		; file open
	mov	al, 100_000b	; 100=share, 000=read mode
	mov	edx, edi
	int	21h
	jc	.ret

	mov	ebx, eax	; ebx = file handle
	mov	ah, 3eh		; file close
	int	21h

	clc
.ret:
	pop	edx
	pop	ebx
	pop	eax
	ret

;##############################################################################
; load EXP file
;##############################################################################

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
proc32 load_exp
	push	ds			;�Ō�ɐςނ���
	mov	es,[esp]		;es �ɐݒ�

	;/// �t�@�C���I�[�v�� ///
	;mov	edx,[�t�@�C����]	;�t�@�C���� ASCIIz
	mov	ax,3d00h		;file open(read only)
	int	21h			;dos call
	jc	.file_open_error	;Cy=1 �Ȃ�I�[�v���G���[

	mov	ebx,eax			;bx <- file handl�ԍ�
	mov	[file_handle],eax	;�������������ɂ��L�^

	;
	;�w�b�_�����[�h
	;
	mov	edx,esi			;���[�N�A�h���X
	mov	ecx,200h		;�ǂݍ��ރo�C�g��
	mov	ah,3fh			;file read ->ds:edx
	int	21h			;dos call
	jc	.file_read_error	;Cy=1 �Ȃ烊�[�h�G���[

	;
	;�w�b�_�����
	;
	mov	eax,[esi]
	cmp	eax,00013350H		;P3 �`��['P3']�E�t���b�g���f��[w (0001)]
	jne	.load_MZ_exp		;P3 �łȂ���� MZ�w�b�_���m�F (jmp)

	;
	;�K�v�ȃ������Z�o
	;
	mov	ecx,[esi+74h]		;ecx = program image size
	mov	eax,[esi+56h]		;eax = mindata
	call	.calc_4Kmem_eax_ecx
	mov	[5ch],eax		;save to PSP

	mov	eax,[esi+5ah]		;eax = maxdata
	call	.calc_4Kmem_eax_ecx
	shr	eax,12			;4KB pages

	push	esi
	mov	ecx,eax			;ecx = allocation pages (max)
	mov	esi,[esi+5eh]		;esi = base memory address
	call	make_cs_ds		;
	pop	esi
	jc	.not_enough_memory	;error

	;
	;�������ʃ`�F�b�N
	;
	mov	ebx,[60h]		;���ۂɊ��蓖�Ă������� [byte]
	mov	eax,[5ch]		;PSP �ɋL�^ / �Œ���K�v�ȃ����� [byte]
	cmp	ebx,eax			;�l��r
	jb	.not_enough_memory	;�����Ȃ烁�����s��

	sub	ebx,[esi+74h]		;���[�h�C���[�W�̑傫��������
	mov	[64h],ebx		;�q�[�v���������ʂ� PSP�ɋL�^

	;
	;���[�h�v���O�����̃X�^�b�N�Ǝ��s�J�n�A�h���X���L�^
	;
	mov	eax,[esi + 62h]	;�X�^�b�N�|�C���^
	mov	ebx,[esi + 68h]	;���s�J�n�A�h���X
	mov	[tmp03],eax	;esp
	mov	[tmp04],ebx	;eip

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
	jnz	exp_un_pack_fread	;PACK �������Ȃ���t�@�C���ǂݍ���
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
	mov	ebp,[tmp03]		;esp
	mov	edx,[tmp04]		;eip
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


proc32 .calc_4Kmem_eax_ecx
	; in eax + ecx
	add	eax, ecx
	jc	.over
.step:	add	eax,      0fffh		; round up 4KB
	jc	.over
	and	eax, 0fffff000h	
	ret

.over	mov	eax, 0fffff000h
	ret


;----------------------------------------------------------------------
;��MZ �w�b�_������ EXP �t�@�C���̃��[�h
;----------------------------------------------------------------------
;	mov	eax,[esi]
;	cmp	eax,00013350H	;P3 �`��['P3']�E�t���b�g���f��[w (0001)]
;	jne	check_MZ	;P3 �łȂ���� MZ�w�b�_���m�F (jmp)
;
proc32 .load_MZ_exp

	;////////////////////////////////////////////////////
	;MZ(MP) �w�b�_�ɑΉ����Ȃ��ꍇ
	;////////////////////////////////////////////////////
%if USE_MZ_EXP = 0
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
	;+04h  (file size + 511) >> 9   // Thanks to Mamiya (san)
	;
	mov	ebp,eax		;ebp = eax
	shr	ebp,16		;+02 w "�t�@�C���T�C�Y / 512" �̗]��
	movzx	eax,w [esi+04h]	;+04 w "512 byte �P�ʂ̃u���b�N��"
	movzx	edx,w [esi+08h]	;+08 w "�w�b�_  �T�C�Y / 16"

	test	ebp,ebp		;ebp = 0 ?
	jz	.step2		;0 �Ȃ� jmp
	dec	eax		;�[������?
.step2:
	shl	eax,9		;512�{
	shl	edx,4 		; 16�{

	; *** edx, ebp �����̕��܂ŕۑ����邱��

	or	eax, ebp	;eax = (512 byte�u���b�N��)*512 + 511�ȉ��̒[��
	sub	eax, edx	;eax = �w�b�_�T�C�Y������
	mov	ebp, eax	;edi = load image size
	add	eax, 000000fffh	;
	and	eax, 0fffff000h	;eax = load image size (4KB unit)

	movzx	ebx,w [esi+0ah]	;+0A w "mindata / 4KB"
	shl	ebx,12
	add	ebx, eax	;minimum memory size (byte)
	mov	[5ch], ebx

	movzx	ecx,w [esi+0ch]	;+0C w "maxdata / 4KB"
	shr	eax,12		;eax = load image pages

	push	esi
	add	ecx,eax			;ecx = allocate max pages
	xor	esi,esi			;esi = base offset address
	call	make_cs_ds
	pop	esi
	jc	.not_enough_memory	;�G���[�Ȃ烁�����s��

	;
	;�������ʃ`�F�b�N
	;
	mov	eax, [60h]		;���ۂɊ��蓖�Ă������� [byte]
	cmp	eax, ebx		;�l��r
	jb	.not_enough_memory	;�����Ȃ烁�����s��

	sub	eax, ebp		;���[�h�C���[�W�̑傫��������
	mov	[64h], eax		;PSP�ɋL�^ / �q�[�v���������� [byte]

	;
	;�X�^�b�N�� exp �̂��̂ɕύX
	;
	mov	eax,[esi + 0eh]	;�X�^�b�N�|�C���^
	mov	ebx,[esi + 14h]	;���s�J�n�A�h���X
	mov	[tmp03],eax	;esp
	mov	[tmp04],ebx	;eip

	;
	;�ȉ��AP3 �̃R�s�[
	;
	mov	ebx,[file_handle]	;ebx <- �t�@�C���n���h���ԍ����[�h
	xor	ecx,ecx			;ecx = 0
	;mov	edx,---		;�����	;edx = �v���O�����C���[�W�܂ł� offset
	mov	ax,4200h		;�t�@�C���擪����|�C���^�ړ�
	int	21h			;DOS call�ifile pointer = cx:dx�j
	jc	.file_read_error	;Cy=1 �Ȃ� �G���[

	mov	ecx, ebp		;�ǂލ��ރT�C�Y�i�v���O�����T�C�Y�j
	xor	edx, edx		;�ǂݍ��ސ擪������(ds:edx)

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
	mov	  ds,ax
	mov	  es,cx
	mov	[tmp01],eax	;���̃v���O����
	mov	[tmp02],ecx	;�ǂݍ��ݐ�

	;
	;���ɂ�� ds �����̃Z�O�����g�������悤�ɂȂ���
	;
	mov	edi,edx			;edi <- �t�@�C���ǂݍ��ݐ�
	mov	edx,esi			;edx <- ���[�N������
	mov	[tmp00],esi		;�ėp�ϐ��Ɉꎞ�I�ɋL��


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

	mov	 ds, [tmp02]		;ds = �t�@�C�����[�h�̈�

	;
	;ds:edx = �v���O�������[�h�̈�
	;
	mov	ah,3fh			;file read
	int	21h			;DOS �R�[��
	jc	short exp_up_fread_err	;�L�����[������΃��[�h�G���[

	mov	 ds, [cs:tmp01]		;���̃v���O������ ds
	mov	edx, [tmp00]		;���[�N�G���A�I�t�Z�b�g��߂�
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
	mov	 es,[tmp01]	;���̃v���O����
	mov	 ds,[tmp02]	;���[�h�̈�

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
	push	ebx
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
	jb	.no_memory		;�}�C�i�X�Ȃ�G���[
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
	call	make_selector_4k	;�������Z���N�^�쐬 edi=�\���� eax=sel

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
	pop	ebx
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
;
proc32 run_exp
	mov	eax,gs			;DS
	mov	 ss,ax			;
	mov	esp,ebp			;�X�^�b�N�؂�ւ�

	push	fs			;cs
	push	edx			;EIP

	mov	ds,ax			;
	mov	es,ax			;�Z���N�^�����ݒ�
	mov	fs,ax			;
	mov	gs,ax			;

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
; DATA
;******************************************************************************
segdata	data class=DATA align=4
		   ;                         12345678901234567890123456789012345678901
dump_head_fault	db "CPU Expection: INT ##h -                                          ",13,10,
		db "Err = ####_####  ",0
dump_head_int	db "Int = ###h       ",0
dump_head_ret	db "Return:          ",0
dump_head_reg	db "Register dump:   ",0
regdump_msg	db                   "CS:EIP = ####:####_####  SS:ESP = ####:####_####",13,10,
		db " DS = ####  ES = ####  FS = ####  GS = ####   "
regdump_flags	db "C  P  Z  S  O  D  I ",13,10,
		db "EAX = ####_####  EBX = ####_####  ECX = ####_####  EDX = ####_####",13,10,
		db "ESI = ####_####  EDI = ####_####  EBP = ####_####  FLG = ####_####",13,10,
		db "CR0 = ####_####  CR2 = ####_####  CR3 = ####_####",13,10
regdump_hr	db "------------------------------------------------------------------",13,10,0

cpu_fault_name_table:
			;12345678901234567890123456789012345678901 : max 41 byte
.err_00		db	'Zero Divide Error',0
.err_01		db	'Debug Exceptions',0
.err_02		db	'NMI',0
.err_03		db	'Breakpoint',0
.err_04		db	'INTO Overflow',0
.err_05		db	'Bounds Check Fault',0
.err_06		db	'Invalid Opcode Fault',0
.err_07		db	'Coprocessor Not Available',0
.err_08		db	'Double Fault',0
.err_09		db	'Coprocessor Segment Overrun',0
.err_0a		db	'Invalid TSS',0
.err_0b		db	'Segment Not Present Fault',0
.err_0c		db	'Stack Exception Fault',0
.err_0d		db	'General Protection Exception',0
.err_0e		db	'Page Fault',0
.err_0f		db	'(CPU RESERVED)',0
.err_10		db	'Coprocessor Error',0
.err_11		db	'Alignment Fault',0
cpu_fault_unknown:
		db	'Unknown',0

	align	4
dump_orig_esp	dd	0
dump_orig_ss	dd	0

;------------------------------------------------------------------------------
; for load exp
;------------------------------------------------------------------------------
	align	4
tmp00		dd	0	; temporary
tmp01		dd	0	;
tmp02		dd	0	;
tmp03		dd	0	;
tmp04		dd	0	;

file_handle	dd	0
Load_cs		dd	0
Load_ds		dd	0

;##############################################################################
;##############################################################################
