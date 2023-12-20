;******************************************************************************
;�@Free386 in protect mode
;******************************************************************************
;
BITS	32
;==============================================================================
;���v���e�N�g���[�h �X�^�[�g���x��
;==============================================================================
proc32 start32
	mov	ebx,F386_ds		;ds �Z���N�^
	mov	 ds,bx			;ds ���[�h
	mov	 es,bx			;es
	mov	 fs,bx			;fs
	mov	 gs,bx			;gs
	lss	esp,[PM_stack_adr]	;�X�^�b�N�|�C���^���[�h

;------------------------------------------------------------------------------
;�����荞�ݐݒ�
;------------------------------------------------------------------------------
	;///////////////////////////////
	;hook int 22h/23h
	;///////////////////////////////
	mov	eax,2506h		;��Ƀv���e�N�g���[�h�Ŕ������銄�荞��
	mov	 cl,23h			;CTRL-C ���荞��
	mov	edx,offset abort_32	;hook �惋�[�`��

	push	cs
	pop	ds			;ds:edx = �G�g���[�A�h���X
	int	21h

	mov	 ds,bx			;recovery ds

	;///////////////////////////////
	;Free386 �Ǝ����荞�݂̐ݒ�
	;///////////////////////////////
	call	setup_F386_int		;see int_f386.asm

	sti

;------------------------------------------------------------------------------
; Debug code
;------------------------------------------------------------------------------
Debug_code:
%if PRINT_TO_FILE
	xor	ecx, ecx
	mov	edx, .file
	mov	ah, 3ch
	int	21h	; Debug file create

	jmp	.skip
.file	db	DUMP_FILE,0
.skip:
%endif

%if PRINT_TSUGARU
	; https://nabe.adiary.jp/0619
	mov	dx, 2f10h
	mov	al, 5dh
	mov	ah, al
	out	dx, al
	in	al, dx
	not	al
	cmp	al, ah
	je	.enable_tsugaru_api	; is Tsugaru

	PRINT	.not_Tsugaru
	jmp	.skip

.not_Tsugaru	db	"This enviroment is not Tsugaru!",13,10,'$'
.enable_tsugaru_api:
	; Enable Tsugaru's VNDRV API
	mov	dx, 2f12h
	mov	al, 01h
	out	dx, al

	; Override int 21h ah=09h
	mov	eax, offset int_21h_09h_output_tsugaru
	mov	ebx, offset int21h_table
	add	ebx, 09h * 4	; ah=09h
	mov	[ebx], eax
.skip:
%endif

;------------------------------------------------------------------------------
; Memory infomation
;------------------------------------------------------------------------------
proc8 memory_infomation
	cmp	b [verbose], 0
	jz	near .skip

	mov	edi, offset msg_01

	; memory info
	mov	eax, [all_mem_pages]
	shl	eax, 2				;page to KB
	call	rewrite_next_hash_to_dec

	; allocated protect memory
	mov	eax, [max_EMB_free]
	call	rewrite_next_hash_to_dec
	mov	eax, [EMB_physi_adr]
	call	rewrite_next_hash_to_hex

	; allcated dos memory
	mov	eax, [DOS_alloc_sizep]
	add	eax, b 1fh		;round up
	shr	eax, 10-4		;para to KB
	call	rewrite_next_hash_to_dec
	mov	eax, [DOS_alloc_seg]
	shl	eax, 4			;seg to linear address
	call	rewrite_next_hash_to_hex

	; reserved dos memory
	movzx	eax, b [resv_real_memKB]
	call	rewrite_next_hash_to_dec

	PRINT	msg_01
.skip:

;------------------------------------------------------------------------------
; more memory infomation
;------------------------------------------------------------------------------
proc8 more_memory_infomation
	cmp	b [verbose], 1
	jbe	near .skip

	mov	edi, offset msg_02

	; program code offset
	mov	eax, end_adr
	dec	eax
	call	rewrite_next_hash_to_hex

	mov	eax, [V86_cs]
	call	rewrite_next_hash_to_hex

	; all heap memory
	mov	eax, end_adr
	call	rewrite_next_hash_to_hex

	mov	eax, 10000h
	sub	eax, end_adr
	call	rewrite_next_hash_to_dec

	; free heap memory
	mov	ebx, [free_heap_top]
	mov	edx, [free_heap_bottom]

	mov	eax, ebx
	call	rewrite_next_hash_to_hex
	mov	eax, edx
	dec	eax
	call	rewrite_next_hash_to_hex

	mov	eax, edx
	sub	eax, ebx
	call	rewrite_next_hash_to_dec

	; Real mode vectors backup
	mov	eax, [RVects_save_adr]
	call	rewrite_next_hash_to_hex
	add	eax,  IntVectors *4 -1
	call	rewrite_next_hash_to_hex

	; Real mode interrupt hook routines
	mov	eax, [rint_labels_adr]
	call	rewrite_next_hash_to_hex
	add	eax, IntVectors *4 -1
	call	rewrite_next_hash_to_hex

	; GDT/LDT/IDT/TSS
	mov	eax, [GDT_adr]
	call	rewrite_next_hash_to_hex
	mov	eax, [LDT_adr]
	call	rewrite_next_hash_to_hex
	mov	eax, [IDT_adr]
	call	rewrite_next_hash_to_hex
	mov	eax, [TSS_adr]
	call	rewrite_next_hash_to_hex

	add	eax, TSSsize -1
	call	rewrite_next_hash_to_hex

	; main call buffer
	mov	eax, [call_buf_adr32]
	mov	ebx, [call_buf_size]
	call	rewrite_next_hash_to_hex
	add	eax, ebx
	dec	eax
	call	rewrite_next_hash_to_hex
	mov	eax, ebx
	call	rewrite_next_hash_to_dec

	; work memory
	mov	eax, [work_adr]
	call	rewrite_next_hash_to_hex
	add	eax,  WORK_size -1
	call	rewrite_next_hash_to_hex

	; stack info
	mov	eax, [sw_stack_bottom_orig]
	sub	eax,  SW_stack_size * SW_max_nest
	call	rewrite_next_hash_to_hex
	add	eax,  SW_stack_size * SW_max_nest -1
	call	rewrite_next_hash_to_hex
	mov	eax,  SW_stack_size
	call	rewrite_next_hash_to_dec

	mov	eax, [VCPI_stack_adr]
	sub	eax,  VCPI_stack_size
	call	rewrite_next_hash_to_hex

	mov	eax, [PM_stack_adr]
	sub	eax,  PM_stack_size
	call	rewrite_next_hash_to_hex

	movzx	eax, w [V86_sp]
	sub	eax, V86_stack_size
	call	rewrite_next_hash_to_hex

	; user call buffer
	mov	ebx, [user_cbuf_adr16]
	mov	eax, ebx
	shr	eax, 16
	call	rewrite_next_hash_to_hex
	mov	 ax, bx
	call	rewrite_next_hash_to_hex
	movzx	eax, b [user_cbuf_pages]
	shl	eax, 12
	call	rewrite_next_hash_to_dec

	PRINT	msg_02
.skip:

;------------------------------------------------------------------------------
;���������Ǘ��̐ݒ�
;------------------------------------------------------------------------------
	mov	eax,[EMB_pages]		;EMB�������y�[�W��
	mov	edx,[EMB_physi_adr]	;�󂫕����������擪
	mov	[free_RAM_pages] ,eax	;�S�v���e�N�g�������Ƃ��Ďg�p����
	mov	[free_RAM_padr]  ,edx	;�󂫐擪�����������擪�A�h���X

;------------------------------------------------------------------------------
;���S�������������Z���N�^���쐬
;------------------------------------------------------------------------------
proc8 make_all_mem_sel
	mov	ecx,[all_mem_pages]	;eax <- ���������y�[�W��
	mov	edx,ecx
	mov	edi,[work_adr]		;���[�N������
	dec	edx			;edx = limit�l ( /pages)
	mov	d [edi  ],0		;
	mov	d [edi+4],edx		;
	mov	d [edi+8],0200h		;�������^�C�v / �������x��=0

	mov	eax,ALLMEM_sel		;�S�������A�N�Z�X�Z���N�^
	call	make_selector_4k		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;
	;�S�������Z���N�^�쐬��Ɉȉ��͎��s
	;
	;mov	ecx,[all_mem_pages]	;eax <- ���������y�[�W��
	mov	esi,[free_liner_adr]	;�󂫃��j�A�A�h���X
	mov	edx,esi			;�����A�h���X��1��1

	add	ecx,0xff		;255pages
	xor	 cl,cl			;1MB�P�ʂɐ؂�グ
	shl	ecx,12			;eax = �����A�h���X�ő�l
	mov	[free_liner_adr],ecx	;�󂫃��j�A�A�h���X�X�V
	sub	ecx,esi			;���蓖�Ă郁�����T�C�Y
	shr	ecx,12			;���蓖�Ă�y�[�W��

	; esi = ������惊�j�A�A�h���X
	; edx = ������镨���A�h���X
	; ecx = �������y�[�W��
	call	set_physical_mem

patch_for_386sx:
	mov	al, [cpu_is_386sx]
	test	al, al
	jz	.skip			;386SX is 24bit address bus.
	mov	eax, 01000000h		;Therefore, addresses over 1000000h are always free.
	mov	[free_liner_adr],eax
.skip:

;------------------------------------------------------------------------------
;���Z���N�^�̍쐬�iLDT�� �Z���N�^�j
;------------------------------------------------------------------------------
	;-------------------------------
	;��PSP�Z���N�^�̍쐬
	;-------------------------------
	mov	edi,[work_adr]		;���[�N�A�h���X���[�h
	mov	eax,[top_ladr]		;�v���O�����擪���j�A�A�h���X
	mov	d [edi+4],256 -1	;limit
	mov	d [edi  ],eax		;base
	mov	d [edi+8],0200h		;R/W �^�C�v / �������x��=0
	mov	eax,PSP_sel1		;PSP �Z���N�^1
	call	make_selector		;�������Z���N�^�쐬 edi=�\���� eax=sel
	mov	eax,PSP_sel2		;PSP �Z���N�^2
	call	make_selector		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;-------------------------------
	;��DOS���ϐ��Z���N�^�̍쐬
	;-------------------------------
	xor	ebx,ebx
	mov	eax,DOSMEM_sel		;DOS �������A�N�Z�X�Z���N�^
	mov	  fs,ax			;fs �ɑ��

	mov	 bx,[2Ch]		;���� 2�o�C�g = ENV �̃Z�O�����g
	shl	ebx,4			;16 �{���ă��j�A�A�h���X��
	mov	 ax,[fs:ebx -16 + 3]	;PSP �̃T�C�Y / MCB ���Q�Ƃ��Ă���
	shl	eax,4			;16 �{ para -> byte
	dec	eax			;size -> limit �l
	mov	d [edi  ],ebx		;base
	mov	d [edi+4],eax		;limit / 32KB �Œ�
	;mov	d [edi+8],0200h		;R/W �^�C�v / �������x��=0
	mov	eax,DOSENV_sel		;DOS ���ϐ��Z���N�^
	call	make_selector		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;-------------------------------
	;��DOS�������Z���N�^(in LDT)
	;-------------------------------
	mov	d [edi  ],0			;base
	mov	d [edi+4],(DOSMEMsize / 4096)-1	;1MB���
	;mov	d [edi+8],0200h			;R/W �^�C�v / �������x��=0
	mov	eax,DOSMEM_Lsel			;DOS ���ϐ��Z���N�^
	call	make_selector_4k			;�������Z���N�^�쐬 edi=�\����

;------------------------------------------------------------------------------
;���e�@��Ή����[�`��
;------------------------------------------------------------------------------
%if TOWNS || PC_98 || PC_AT
	mov	b [init_machine32], 1
	%if TOWNS
		call	init_TOWNS_32
	%elif PC_98
		call	init_PC98_32
	%elif PC_AT
		call	init_AT_32
	%endif
%endif

;------------------------------------------------------------------------------
; copy exp name to work
;------------------------------------------------------------------------------
proc8 copy_exp_filename_to_work
	mov	esi, [exp_name_adr]	; file name, no terminate
	mov	ecx, [exp_name_len]	;
	mov	edi, [work_adr]
	test	ecx, ecx
	jnz	.exists_name

	mov	al, [show_title]
	test	al, al
	jz	.skip
	PRINT	msg_10			; show help
.skip:
	jmp	exit_32

.exists_name:
	;
	; copy [esi] to [edi]
	; and check file name include "\" or ":"
	;
	mov	[exp_name_fname_offset], edi
.loop:
	lodsb				; al = [esi++]
	stosb				; [edi++] = al
	cmp	al, '\'
	je	.is_path
	cmp	al, ':'
	je	.is_path
	loop	.loop
	jmp	short .exit

.is_path:
	mov	byte [exp_name_include_path], 1
	mov	     [exp_name_fname_offset], edi
	loop	.loop

.exit:
	mov	byte [edi], 0

;------------------------------------------------------------------------------
; copy parameter PSP to PSP
;------------------------------------------------------------------------------
proc8 copy_exp_pamameter
	mov	edi, 81h
	mov	ecx, 7eh

	cmp	b [esi], ' '
	jnz	short .copy_loop
	inc	esi			; skip first space

.copy_loop:
	mov	al, [esi]		; 1 byte load
	mov	[edi], al
	cmp	al, 0dh
	jz	.copy_end

	inc	esi
	inc	edi
	loop	.copy_loop

.copy_end:
	mov	byte [edi], 0dh
	mov	eax, edi
	sub	al, 81h
	mov	[80h], al		; parameter length


;------------------------------------------------------------------------------
; rewrite argv[0] is command name
;------------------------------------------------------------------------------
;	ENV�̈悪���肸��������Ȃ��ꍇ�́A�r���Œ��߂�B
;
proc32 rewrite_command_name
	mov	ebx, err_00		; set non exists ENV name string
	call	search_env		; ret fs:[edx] is ENV end

	cmp	word fs:[edx], 0001h
	jne	.exit
	add	edx, byte 2

	;
	; copy exp command line name to ENV
	;
	mov	esi, [exp_name_fname_offset]

	xor	eax, eax
	mov	 ax, fs
	lsl	ecx, ax
	sub	ecx, edx		; ecx = remain bytes
	jbe	.exit			; safety

.loop:
	lodsb				; al = [esi++]
	mov	fs:[edx], al		; store
	inc	edx
	loop	.loop

	mov	b fs:[edx], 0		; last byte force write '0'
.exit:

;------------------------------------------------------------------------------
; Completes EXP file extensions
;------------------------------------------------------------------------------
proc8 completes_exp_file_name
	mov	edi, [exp_name_fname_offset]
.loop:
	mov	al, [edi]
	inc	edi

	cmp	al,'.'
	je	short .exist_ext

	test	al,al
	jnz	.loop

	;
	; add file extension
	;
	mov	dword [edi-1], EXP_EXT
	mov	byte  [edi+3], 0	; null

.exist_ext:

;------------------------------------------------------------------------------
; search exp file
;------------------------------------------------------------------------------
proc8 search_exp_file
	;--------------------------------------------------
	; read command line name
	;--------------------------------------------------
	mov	edi, [work_adr]		; edi = file name
	call	check_readable_file
	jnc	.found

	;--------------------------------------------------
	; search
	;--------------------------------------------------
	mov	esi, [work_adr]		; esi = search file name
	mov	edi, esi
	add	edi, 100h		; edi = result store buffer

	cmp	byte [exp_name_include_path], 0
	jne	.not_found

	;--------------------------------------------------
	; check PATH386
	;--------------------------------------------------
	cmp	byte [search_PATH386], 0
	je	.skip_path386

	mov	ebx, offset env_PATH386	; [ebx] = "PATH386"
	call	search_path
	jnc 	.found
.skip_path386:

	;--------------------------------------------------
	; check PATH
	;--------------------------------------------------
	cmp	byte [search_PATH], 0
	je	.skip_path

	mov	ebx, offset env_PATH	; [ebx] = "PATH"
	call	search_path
	jnc	.found
.skip_path:
.not_found:
	;--------------------------------------------------
	; file not found
	;--------------------------------------------------
	PRINT	msg_05
	mov	edx, esi		; search file name
	call	print_string_32

	mov	ah, 21			;'Can not read executable file'
	jmp	error_exit_32

	;--------------------------------------------------
	; file found
	;--------------------------------------------------
.found:
	mov	al,[verbose]		;�璷�\���t���O
	test	al,al			;0?
	jz	.no_verbose		;0 �Ȃ� jmp

	PRINT	msg_05
	mov	edx,edi 		;�t�@�C���� string
	call	print_string_32		;������\�� (null:�I�[)
.no_verbose:

;------------------------------------------------------------------------------
;load and run EXP
;------------------------------------------------------------------------------
	mov	edx, edi		;edx = load file PATH
	mov	esi, [work_adr]		;esi = work address
	call	load_exp
	jc	error_exit_32		;ah = internal error code

	jmp	NEAR run_exp

;------------------------------------------------------------------------------
;���v���O�����̏I��(32bit)
;------------------------------------------------------------------------------
proc32 abort_32
	mov	ah, 25
	jmp	short error_exit_32
proc32 exit_32
	mov	ah, 0
proc32 error_exit_32
	cli
	mov	bx,F386_ds		;ds ����
	mov	 ds,bx			;
	mov	 es,bx			;VCPI �Ő؂芷�����A
	mov	 fs,bx			;�Z�O�����g���W�X�^�͕s��l
	mov	 gs,bx			;
	lss	esp,[PM_stack_adr]	;�X�^�b�N�|�C���^���[�h

	mov	[err_level],ax
	;mov	[err_level],al		;save error level
	;mov	[f386err],ah

	;///////////////////////////////
	;�I�������ŃG���[�𔭐������Ȃ����߂Ƀo�b�t�@�֘A�N���A
	;///////////////////////////////
	call	clear_gp_buffer_32
	call	clear_sw_stack_32

	;///////////////////////////////
	;�e�@��ŗL�̏I������
	;///////////////////////////////
	%if TOWNS || PC_98 || PC_AT
		cmp	b [init_machine32], 0
		je	.skip_exit_machine
		mov	b [init_machine32], 0		;Re-entry prevention

		%if TOWNS
			call	exit_TOWNS_32
		%elif PC_98
			call	exit_PC98_32
		%elif PC_AT
			call	exit_AT_32
		%endif
	.skip_exit_machine:
	%endif

	;///////////////////////////////
	;���A�����[�h�x�N�^�̕���
	;///////////////////////////////
%if RestoreRealVec
RestoreRealVectors:
	push	d (DOSMEM_sel)			;DOS �������A�N�Z�X���W�X�^
	pop	fs				;load
	mov	ecx,IntVectors			;�x�N�^��
	mov	ebx,offset RVects_flag_tbl	;�x�N�^���������t���O�e�[�u��
	mov	esi,[RVects_save_adr]		;esi <- �x�N�^�ۑ��̈�

	align	4
.loop:
	dec	ecx			;ecx -1
	bt	[ebx],ecx		;�����������t���O ?
	jc	.Recovary		;�����������Ă�Ε���
	test	ecx,ecx			;�J�E���^�m�F
	jz	.end
	jmp	short .loop

	align	4
.Recovary:
	mov	eax,[esi + ecx*4]	;�I���W�i���l���[�h
	mov	[fs:ecx*4],eax		;����

	test	ecx,ecx			;�J�E���^�m�F
	jnz	.loop			;���[�v

	align	4
.end:
%endif

	;///////////////////////////////
	;V86 ���[�h�֖߂�
	;///////////////////////////////
	mov	eax,[V86_cs]		;V86�� cs,ds
	mov	ebx,[V86_sp]		;V86�� sp

	cli				;���荞�݋֎~
	push	eax			;V86 gs
	push	eax			;V86 fs
	push	eax			;V86 ds
	push	eax			;V86 es
	push	eax			;V86 ss
	push	ebx			;V86 esp
	pushfd				;eflags
	push	eax			 ;V86 cs
	push	d (offset exit_16) ;V86 EIP / �I�����x��

	mov	ax,0de0ch		;VCPI function 0ch / to V86 mode
	call    far [VCPI_entry]	;VCPI call

