;******************************************************************************
;�@Free386	���v���e�N�g���[�h��������
;******************************************************************************
;
; 2001/01/18 �t�@�C���𕪗�
;
;
;
BITS	32
;==============================================================================
;���v���e�N�g���[�h �X�^�[�g���x��
;==============================================================================
	align	16
start32:
	mov	ebx,F386_ds		;ds �Z���N�^
	mov	ds,ebx			;ds ���[�h
	mov	es,ebx			;es
	mov	fs,ebx			;fs
	mov	gs,ebx			;gs
	lss	esp,[PM_stack_adr]	;�X�^�b�N�|�C���^���[�h

;------------------------------------------------------------------------------
;�����荞�ݐݒ�
;------------------------------------------------------------------------------
	;///////////////////////////////
	;int 23h �̃t�b�N
	;///////////////////////////////
	mov	eax,2506h		;��Ƀv���e�N�g���[�h�Ŕ������銄�荞��
	mov	 cl,23h			;CTRL-C ���荞��
	mov	edx,offset END_program	;hook �惋�[�`��

	push	cs
	pop	ds			;ds:edx = �G�g���[�A�h���X
	int	21h			;DOS-Extender function

	mov	ds,ebx			;ds ����

	;///////////////////////////////
	;Free386 �Ǝ����荞�݂̐ݒ�
	;///////////////////////////////
	call	setup_F386_int		;see int_f386.asm

%if (enable_INTR)
	sti			;���荞�݋���
%endif

;------------------------------------------------------------------------------
; Memory detail infomation
;------------------------------------------------------------------------------
internal_mem_dump:
	mov	al, [verbose]
	cmp	al, 2
	jb	near .skip

	mov	edi, internal_mem_msg

	mov	eax, end_adr
	dec	eax
	call	rewrite_next_hash_to_hex

	mov	eax, [v86_cs]
	call	rewrite_next_hash_to_hex

	mov	eax, end_adr
	call	rewrite_next_hash_to_hex

	mov	eax, [page_dir]
	dec	eax
	call	rewrite_next_hash_to_hex

	mov	eax, [frag_mem_size]
	call	rewrite_next_hash_to_deg

	mov	eax, [page_dir]
	call	rewrite_next_hash_to_hex
	add	eax, 1fffh
	call	rewrite_next_hash_to_hex
	inc	eax
	call	rewrite_next_hash_to_hex

	mov	ebx, [top_mem_offset]
	mov	edx, [down_mem_offset]

	mov	eax, 10000h
	sub	eax, [page_dir]
	call	rewrite_next_hash_to_deg

	mov	eax, ebx
	call	rewrite_next_hash_to_hex
	mov	eax, edx
	dec	eax
	call	rewrite_next_hash_to_hex

	mov	eax, edx
	sub	eax, ebx
	call	rewrite_next_hash_to_deg

	; Real mode vectors backup
	mov	eax, [RVects_save_adr]
	call	rewrite_next_hash_to_hex
	add	eax,  IntVectors *4 -1
	call	rewrite_next_hash_to_hex

	; GDT/LDT/IDT/TSS
	mov	eax, [GDT_adr]
	call	rewrite_next_hash_to_hex
	add	eax, GDTsize -1
	call	rewrite_next_hash_to_hex

	mov	eax, [LDT_adr]
	call	rewrite_next_hash_to_hex
	add	eax, LDTsize -1
	call	rewrite_next_hash_to_hex

	mov	eax, [IDT_adr]
	call	rewrite_next_hash_to_hex
	add	eax, IDTsize -1
	call	rewrite_next_hash_to_hex

	mov	eax, [TSS_adr]
	call	rewrite_next_hash_to_hex
	add	eax, TSSsize -1
	call	rewrite_next_hash_to_hex

	; work memory
	mov	eax, [work_adr]
	call	rewrite_next_hash_to_hex
	add	eax,  WORK_size -1
	call	rewrite_next_hash_to_hex

	; stack info
	mov	eax, [VCPI_stack_adr]
	sub	eax,  VCPI_stack_size
	call	rewrite_next_hash_to_hex

	mov	eax, [PM_stack_adr]
	sub	eax,  PM_stack_size
	call	rewrite_next_hash_to_hex

	movzx	eax, w [v86_sp]
	sub	eax, V86_stack_size
	call	rewrite_next_hash_to_hex

	PRINT	internal_mem_msg
.skip:

;------------------------------------------------------------------------------
;���������Ǘ��̐ݒ�
;------------------------------------------------------------------------------
make_page_tables:
	mov	al,[verbose]
	test	al,al
	jz	near .no_verbose

	mov	edi, msg_02

	;/// �������������� ///
	mov	eax,[all_mem_pages]	;�������h���C�n�ɂ���Ď��ۂƂ͈Ⴄ�l���Ԃ�
	shl	eax,2			;4�{���� eax = XXX KB
	call	rewrite_next_hash_to_deg

	;/// �m�ۂ����g�������� ///
	mov	eax,[max_EMB_free]
	call	rewrite_next_hash_to_deg
	mov	eax,[EMB_physi_adr]
	call	rewrite_next_hash_to_hex

	;/// ���A�������� ///
	mov	eax,[DOS_mem_pages]	;
	shl	eax, 2			;page to KB
	call	rewrite_next_hash_to_deg
	mov	eax,[DOS_mem_adr]
	call	rewrite_next_hash_to_hex

	;/// call buffer ///
	movzx	eax,b [callbuf_sizeKB]
	call	rewrite_next_hash_to_deg
	mov	eax,[callbuf_adr32]
	call	rewrite_next_hash_to_hex

	;/// Additional page table memory ///
	mov	eax, [page_table_in_dos_memory_size]
	shr	eax, 10
	call	rewrite_next_hash_to_deg
	mov	eax,[page_table_in_dos_memory_adr]
	call	rewrite_next_hash_to_hex

	PRINT_	msg_02
.no_verbose:

	;--------------------------------------------------
	;�������Ǘ����̐ݒ�
	;--------------------------------------------------
	mov	eax,[EMB_pages]		;EMB�������y�[�W��
	mov	edx,[EMB_physi_adr]	;�󂫕����������擪
	mov	[free_RAM_pages] ,eax	;�S�v���e�N�g�������Ƃ��Ďg�p����
	mov	[free_RAM_padr]  ,edx	;�󂫐擪�����������擪�A�h���X

	test	eax,eax			;�v���e�N�g��������
	jnz	.step			;0 �łȂ���Όp��(jmp)

	F386_end	21h		;�������Ȃ�
.step:

;------------------------------------------------------------------------------
;���S�������������Z���N�^���쐬
;------------------------------------------------------------------------------
make_all_mem_sel:
	mov	ecx,[all_mem_pages]	;eax <- ���������y�[�W��
	mov	edx,ecx
	mov	edi,[work_adr]		;���[�N������
	dec	edx			;edx = limit�l ( /pages)
	mov	d [edi  ],0		;
	mov	d [edi+4],edx		;
	mov	d [edi+8],0200h		;�������^�C�v / �������x��=0

	mov	eax,ALLMEM_sel		;�S�������A�N�Z�X�Z���N�^
	call	make_mems_4k		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;
	;�S�������Z���N�^�쐬��Ɉȉ��͎��s
	;
	;mov	ecx,[all_mem_pages]	;eax <- ���������y�[�W��
	mov	esi,[free_LINER_ADR]	;�󂫃��j�A�A�h���X
	mov	edx,esi			;�����A�h���X��1��1

	add	ecx,0xff		;255pages
	xor	 cl,cl			;1MB�P�ʂɐ؂�グ
	shl	ecx,12			;eax = �����A�h���X�ő�l
	mov	[free_LINER_ADR],ecx	;�󂫃��j�A�A�h���X�X�V
	sub	ecx,esi			;���蓖�Ă郁�����T�C�Y
	shr	ecx,12			;���蓖�Ă�y�[�W��

	; esi = ������惊�j�A�A�h���X
	; edx = ������镨���A�h���X
	; ecx = �������y�[�W��
	call	set_physical_mem

;------------------------------------------------------------------------------
;���Z���N�^�̍쐬�iLDT�� �Z���N�^�j
;------------------------------------------------------------------------------
	;-------------------------------
	;��PSP�Z���N�^�̍쐬
	;-------------------------------
	mov	edi,[work_adr]		;���[�N�A�h���X���[�h
	mov	eax,[top_adr]		;�v���O�����擪���j�A�A�h���X
	mov	d [edi+4],256 -1	;limit
	mov	d [edi  ],eax		;base
	mov	d [edi+8],0200h		;R/W �^�C�v / �������x��=0
	mov	eax,PSP_sel1		;PSP �Z���N�^1
	call	make_mems		;�������Z���N�^�쐬 edi=�\���� eax=sel
	mov	eax,PSP_sel2		;PSP �Z���N�^2
	call	make_mems		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;-------------------------------
	;��DOS���ϐ��Z���N�^�̍쐬
	;-------------------------------
	xor	ebx,ebx
	mov	eax,DOSMEM_sel		;DOS �������A�N�Z�X�Z���N�^
	mov	 fs,eax			;fs �ɑ��

	mov	 bx,[2Ch]		;���� 2�o�C�g = ENV �̃Z�O�����g
	shl	ebx,4			;16 �{���ă��j�A�A�h���X��
	mov	 ax,[fs:ebx -16 + 3]	;PSP �̃T�C�Y / MCB ���Q�Ƃ��Ă���
	shl	eax,4			;16 �{ para -> byte
	dec	eax			;size -> limit �l
	mov	d [edi  ],ebx		;base
	mov	d [edi+4],eax		;limit / 32KB �Œ�
	;mov	d [edi+8],0200h		;R/W �^�C�v / �������x��=0
	mov	eax,DOSENV_sel		;DOS ���ϐ��Z���N�^
	call	make_mems		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;-------------------------------
	;��DOS�������Z���N�^(in LDT)
	;-------------------------------
	mov	d [edi  ],0			;base
	mov	d [edi+4],(DOSMEMsize / 4096)-1	;1MB���
	;mov	d [edi+8],0200h			;R/W �^�C�v / �������x��=0
	mov	eax,DOSMEM_Lsel			;DOS ���ϐ��Z���N�^
	call	make_mems_4k			;�������Z���N�^�쐬 edi=�\����

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
.file	db	"dump.txt",0
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
;���e�@��Ή����[�`��
;------------------------------------------------------------------------------
%if TOWNS || PC_98 || PC_AT
	mov	b [init_machine], 1
	push	edx
	push	ebp
	push	fs
	push	gs

%if TOWNS
	call	setup_TOWNS		;TOWNS �ŗL�̐ݒ�
%elif PC_98
	call	setup_PC98		;PC-98x1 �ŗL�̐ݒ�
%elif PC_AT
	call	setup_AT		;PC/AT�݊��@ �ŗL�̐ݒ�
%endif

	pop	gs
	pop	fs
	pop	ebp
	pop	edx
%endif

;------------------------------------------------------------------------------
;���p�����[�^���
;------------------------------------------------------------------------------
;[sub.asm]
;paras		dw	0,0		;���������p�����[�^�[�̐�
;paras_last	dw	0,0		;0dh �̈ʒu
;paras_p	resw	max_paras	;�|�C���^�z��
;
	mov	ecx,[paras]		;�p�����[�^��
	test	ecx,ecx			;�l�m�F
	jz	no_file			;0 �Ȃ�� jmp

	mov	edi,[work_adr]		;��Ɨ̈�offset ���[�h
	xor	esi,esi			;MSBs (���16�r�b�g) ����
	mov	eax,offset paras_p	;�p�����[�^�ւ̃|�C���^ eax = argv

	align	4
para_analyze_loop:
	mov	si,[eax]		;�p�����[�^�ւ̃|�C���^ esi = argv[N]
	cmp	b [esi],'-'		;��r
	jne	find_file		;'-' �Ŏn�܂�Ȃ�������� file���Ƃ���

	;*** �p�����[�^��̓��[�`�� ***
	add	eax,byte (2)
	loop	para_analyze_loop

	align	4
no_file:
	mov	al, [show_TITLE]
	test	al, al
	jz	.skip
	PRINT		msg_10		;�g�����\��
.skip:
	Program_END	00		;�v���O�����I������


	align	4
find_file:
	mov	al,[esi]		;
	mov	[edi],al		;�t�@�C�����Ȃǂ��L�^ -> work
	inc	esi
	inc	edi
	test	al,al
	jnz	find_file		;���s�t�@�C�������Ђ����畡��

	dec	esi			;�Ō�� '0' �̈ʒu�ɖ߂�
	mov	ecx,[paras_last]	;�����̈ʒu
	mov	edi,81h			;PSP �̈����擪�ʒu
	sub	ecx,esi			;���� - ���݈ʒu
	mov	[80h],cl		;PSP �ɋL�^ / �p�����^��

	test	ecx,ecx			;ecx = 0?
	jz	para_copy_loop_exit

	align	4
para_copy_loop:
	mov	al,[esi]		;1 byte load
	inc	esi			;

	test	al,al
	jz	rec_space		;0 �Ȃ�󔒂ɕ���

	mov	[edi],al		;�L�^
	inc	edi
	loop	para_copy_loop
	jmp	para_copy_loop_exit

	align	4
rec_space:
	mov	byte [edi],' '		;�󔒋L�^
	inc	edi
	loop	para_copy_loop

para_copy_loop_exit:
	mov	byte [edi],0dh		;�I�[�L��


;------------------------------------------------------------------------------
;��EXP �t�@�C�����̕⊮�ƌ���
;------------------------------------------------------------------------------
	;
	;�g���q�⊮
	;
	mov	edi,[work_adr]

	align	4
find_period:
	mov	al,[edi]	;1 byte load
	inc	edi

	cmp	al,'.'		;if �g���q����?
	je	search_file	;  then jmp

	test	al,al		;0?
	jnz	find_period	

	;
	;�g���q�̒ǉ�
	;
	mov	d [edi-1],EXP_EXT	;�g���q�⊮
	mov	b [edi+3],0		;�I�[�L��

	;
	;�t�@�C���̌���
	;
	align	4
search_file:
	;////// PATH386 �̌��� /////////
	mov	al,[search_PATH386]	;��������?
	test	al,al
	jz	.step

	mov	esi,[work_adr]		;�����t�@�C����
	mov	ebx,offset env_PATH386	;���ϐ���
	call	searchpath		;�t�@�C������
	test	eax,eax			;���ʔ��f
	je	.file_found		;�t�@�C������ (jmp)

	;////// PATH �̌��� ////////////
.step:	mov	al,[search_PATH]	;��������?
	test	al,al
	jz	.step2

	mov	esi,[work_adr]		;�����t�@�C����
	mov	ebx,offset env_PATH	;���ϐ���
	call	searchpath		;�t�@�C������
	test	eax,eax			;���ʔ��f
	je	.file_found		;�t�@�C������ (jmp)
	jmp	.not_found

	;////// �J�����g�f�B���N�g���̊m�F
.step2:
	mov	edx,[work_adr]		;�����������t�@�C�����̂��郏�[�N
 	mov	 cl,6			;���ׂẴt�@�C��
	mov	ah,4eh			;����
	int	21h

	mov	edi,edx			;edi = �t�@�C�����|�C���^
	jnc	.file_found		;���������Ȃ� jmp

.not_found:
	;------ file_not_found ------
	PRINT	msg_05
	mov	edx,[work_adr]		;���������t�@�C����
	call	string_print		;������\�� (null:�I�[)
	F386_end	22h

	;
	;���[�h�t�@�C�����̕\��
	;
	align	4
.file_found:
	mov	al,[verbose]		;�璷�\���t���O
	test	al,al			;0?
	jz	.no_verbose		;0 �Ȃ� jmp

	PRINT	msg_05
	mov	edx,edi 		;�t�@�C���� string
	call	string_print		;������\�� (null:�I�[)
.no_verbose:

;------------------------------------------------------------------------------
;��EXP �t�@�C���̃��[�h
;------------------------------------------------------------------------------
call_load_exp:
	mov	esi,[work_adr]		;���[�N�̈惍�[�h
	call	load_exp		;EXP �t�@�C���̃��[�h
	jnc	.skip			;���[�h�����Ȃ� EXP �t�@�C���̎��s

	mov	[f386err],al		;�G���[�ԍ��L�^
	xor	al,al
	mov	ah,4ch
	int	21h			;�v���O�����I��
.skip:

;------------------------------------------------------------------------------
;��EXP �t�@�C�����s
;------------------------------------------------------------------------------
	jmp	NEAR run_exp

