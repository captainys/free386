;******************************************************************************
;�@Free386 (compatible to RUN386 DOS-Extender)
;		'ABK project' all right reserved. Copyright (C)nabe@abk
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"

%include	"start.inc"
%include	"sub.inc"
%include	"sub32.inc"
%include	"memory.inc"
%include	"selector.inc"
%include	"call_v86.inc"
%include	"int.inc"

; PC model dependent
%include	"pc.inc"

;******************************************************************************
; global symbols
;******************************************************************************

;--- for selector.asm ------------------------------
global		GDT_adr
global		LDT_adr
global		page_dir_ladr
global		all_mem_pages

;--- for call_v86.asm -----------------------------
global		to_PM_EIP
global		to_PM_data_ladr
global		VCPI_entry
global		safe_stack_adr
global		V86_cs

global		use_vcpi
global		LGDT_data
global		LIDT_data
global		RM_LIDT_data
global		to_PM_LDTR
global		to_PM_CR3

;--- for int.asm ----------------------------------
global		IDT_adr
global		PM_stack_adr
global		RVects_flag_tbl
global		DTA_off
global		DTA_seg
global		default_API
global		pharlap_version

global		call_buf_used
global		call_buf_size
global		call_buf_adr16
global		call_buf_seg16
global		call_buf_adr32

global		user_cbuf_adr16
global		user_cbuf_seg16
global		user_cbuf_ladr

%ifdef USE_VCPI_8259A_API
global		vcpi_8259m
global		vcpi_8259s
%endif

;--- other ----------------------------------------
global		error_exit_16
global		exit_32
global		error_exit_32

global		top_ladr
global		end_adr
global		work_adr

; for pc_*.asm
global		cpu_is_386sx
global		msg_all_mem_type
global		XMS_entry
global		msg_xms_ver

;******************************************************************************
;���R�[�h(16 bit)
;******************************************************************************
seg16	text class=CODE align=4 use16
;------------------------------------------------------------------------------
; start
;------------------------------------------------------------------------------
	global	start
start:
	xor	eax,eax

	mov	ax,cs		; check ".exe" or ".com"
	mov	bx,ds
	cmp	ax,bx		; cs <=> ds
	je	.step		; 

	mov	ds,ax
	mov	ah,01		;'please run free386.com'
	jmp	error_exit_16

.step:
	shl	eax, 4		; seg to linear address
	mov	[top_ladr], eax	; save

	;///////////////////////////////
	;64KB�ȏ��DOS�������J��
	;///////////////////////////////
	mov	bx,1000h		;64KB / 16
	mov	ah,4ah			;�������u���b�N�T�C�Y�̕ύX
	int	21h			;DOS call

;------------------------------------------------------------------------------
; parse arguments
;------------------------------------------------------------------------------
proc2 parameter_check
	mov	si, 81h			;argument string pointer
	mov	bp, 7fh			;argument max length
	xor	bx, bx

.loop:
	add	si, bx
	call	get_next_parameter	;si=string, bx=length
	test	bx, bx
	jz	.end			;0

	cmp	b [si],'-'		;'-' parameter?
	jne	.end			;

	mov	eax,[si+1]		;load 4 byte
	cmp	ah, 20h
	ja	.skip
	mov	ah, 0			;rewrite CR and other
.skip:
	jmp	.run386_parameters
.run386_parameters_ret:
	;---------------------------------------------------
	; Free386 parameters
	;---------------------------------------------------
	cmp	al,'v'
	je	.para_v
	cmp	al,'q'
	je	.para_q
	cmp	al,'p'
	je	.para_p
	cmp	al,'c'
	je	.para_c
	cmp	al,'m'
	je	.para_m
	cmp	al,'2'
	je	.para_2
%if TOWNS
	cmp	al,'n'
	je	.para_n
%endif
	cmp	al,'i'
	je	.para_i
	jmp	.loop

	;///////////////////////////////
	; -v, -vv
	;///////////////////////////////
.para_v:
	mov	cl, 1
	cmp	ah,'v'			; -vv?
	sete	ch			; if ah='v' set ch=1
	add	cl, ch
	mov	[verbose], cl
	jmp	.loop

	;///////////////////////////////
	; -q
	;///////////////////////////////
.para_q:
	mov	b [show_title],0	;no title output
	jmp	.loop

	;///////////////////////////////
	; -p?
	;///////////////////////////////
.para_p:
	and	ah,01			;-p? / al = ?
	mov	[search_PATH],ah	;search PATH flag
	jmp	.loop

	;///////////////////////////////
	; -c?
	;///////////////////////////////
.para_c:
	test	ah,ah			;-c? / al = ?
	jnz	.c0			
	mov	ah,01			;�w��Ȃ��Ȃ� -c1 �Ɖ���
.c0:	and	ah,03			;bit 1,0 ���o��
	mov	[reset_CRTC],ah
	jmp	.loop

	;///////////////////////////////
	; -i?
	;///////////////////////////////
.para_i:
	and	ah,01h			;-i? / al = ?
	mov	b [check_MACHINE],ah
	jmp	.loop


%if TOWNS
	;///////////////////////////////
	; -n, do not load CoCo/NSD
	;///////////////////////////////
.para_n:
	and	ah,01h			;al = -n?
	mov	b [load_nsdd],ah
	jmp	.loop
%endif

	;///////////////////////////////
	; set PharLap version to 2.2 (compatible EXE386)
	;///////////////////////////////
.para_2:
	mov	d [pharlap_version], 20643232h	; ' d22'
	jmp	.loop

	;///////////////////////////////
	; -m : Use memory maximum
	;///////////////////////////////
.para_m:
	xor	ax, ax
	mov	[pool_for_paging], al	;reserved paging memory = 0
	mov	[resv_real_memKB], ax	;reserved dos memory = 0
	mov	b [user_cbuf_pages],1	;user call buffer size = 1page(4KB)
	jmp	.loop

	;---------------------------------------------------
	; RUN386 parameters
	;---------------------------------------------------
proc1 .run386_parameters
	cmp	eax, 'maxr'
	je	.para_maxreal
	cmp	eax, 'minr'
	je	.para_minreal
	cmp	eax, 'call'
	je	.para_callbuf
	jmp	.run386_parameters_ret

proc1 .parse_next_decimal
	add	si, bx
	call	get_next_parameter	;skip next parameter
	test	bx, bx
	jz	.parse_fail		;0
	jmp	parse_decimal_string	;parse [si]
	; eax = number, ret to caller

.parse_fail:
	pop	ax			;remove ret address
	jmp	.end			;exit

	;///////////////////////////////
	; -maxreal 32768 [byte]
	;///////////////////////////////
.para_maxreal:
	call	.parse_next_decimal
	shr	eax, 10			;byte to KB
	mov	cx, [resv_real_memKB]
	cmp	cx, ax			;current -  max
	jbe	.maxr_skip		;current <= max
	mov	[resv_real_memKB], ax	;if set current>max
.maxr_skip:
	jmp	.loop

	;///////////////////////////////
	; -minreal 8192 [byte]
	;///////////////////////////////
.para_minreal:
	call	.parse_next_decimal
	add	eax, 03ffh		;+1023 byte
	shr	eax, 10			;byte to KB
	mov	cx, [resv_real_memKB]
	cmp	cx, ax			;current -  min
	jae	.minr_skip		;current >= min
	mov	[resv_real_memKB], ax	;if set current>min
.minr_skip:
	jmp	.loop

	;///////////////////////////////
	; -callbuf 32 [KB]
	;///////////////////////////////
.para_callbuf:
	call	.parse_next_decimal
	add	eax, 3		;round up 4KB
	shr	eax, 2		;KB to page
	cmp	eax, 0ffh
	jbe	.cb_skip
	mov	al, 255
.cb_skip:
	mov	[user_cbuf_pages], al
	jmp	.loop

	;---------------------------------------------------
	; save exp file name
	;---------------------------------------------------
.end:
	mov	[exp_name_adr], si
	mov	[exp_name_len], bx


;------------------------------------------------------------------------------
;���^�C�g���\��
;------------------------------------------------------------------------------
proc2 print_title
	mov	al,[show_title]	;�^�C�g���\������?
	test	al,al		;�l check
	jz	.no_title	;0 �Ȃ�\������
	PRINT16	P_title		;�^�C�g���\��
.no_title:

	cmp	b [verbose], 2
	jb	.skip

	mov	ax, cs		; number
	mov	di, seg_hex	; store target
	call	bin2hex4_16
	PRINT16	seg_msg
.skip:

;------------------------------------------------------------------------------
; machine check
;------------------------------------------------------------------------------
%if MACHINE_CODE			;not DOS general purpose

proc1 machine_check
	mov	al,[check_MACHINE]	;�@�픻�ʃt���O
	test	al,al			;�l�m�F
	jz	.no_check		;0 �Ȃ�`�F�b�N���Ȃ�

	%if TOWNS
		call	check_TOWNS_16
	%elif PC_98
		call	check_PC98_16
	%elif PC_AT
		call	check_AT_16
	%endif

	jnc	.check_true		;Cy=0 �Ȃ�Y���@��
	mov	ah, 02			;�@�픻�ʎ��s
	jmp	error_exit_16		;�I��

.no_check:
.check_true:

%endif

;------------------------------------------------------------------------------
; check VCPI
;------------------------------------------------------------------------------
%if CHECK_EMS
proc1 check_ems_driver
	;
	; check EMS
	;
	mov	ax,3567h	;int 67h �̃x�N�^�擾
	int	21h		;es:[bx] = �x�N�^�ʒu
	mov	bx,000ah	;�h���C�o�m�F�p������J�n�ʒu 'EMMXXXX0'

	mov	ax,[es:bx  ]	;�O����4�����m�F
	mov	dx,[es:bx+2]	;
	cmp	ax,'EM'
	jne	short .not_found
	cmp	dx,'MX'
	jne	short .not_found

	mov	ax,[es:bx+4]	;�㔼4����
	mov	dx,[es:bx+6]	;
	cmp	ax,'XX'
	jne	short .not_found
	cmp	dx,'X0'
	je	short .skip

.not_found:
	mov	b [use_vcpi], 0
	jmp	skip_vcpi_check
.skip:
%endif

	;
	;----- VCPI �̑��݊m�F -----
	;
VCPI_check:
	mov	ax,0de00h	; AL=00 : VCPI check!
	int	67h		; VCPI call
	test	ah,ah		; �߂�l check
	jz	short .found	; found VCPI

	mov	b [use_vcpi], 0
	jmp	.skip

.found:
	cmp	b [verbose], 0
	jz	.skip
	PRINT16	msg_09		;'Found VCPI'
.skip:
skip_vcpi_check:
	push	ds
	pop	es		; recovery ES

;------------------------------------------------------------------------------
;�����������ʂ̎擾 / VCPI
;------------------------------------------------------------------------------
proc1 get_total_memory_size
	cmp	b [use_vcpi], 0
	jz	.skip

	mov	ax,0de02h			;VCPI function 02h
	int	67h				;�ŏ�ʃy�[�W�̕����A�h���X
	shr	edx,12				;�A�h���X -> page
	inc	edx				;edx = ���������y�[�W��

	mov	eax, MAX_RAM /4096		;�ő僁�����ʐ���
	cmp	edx, eax
	jb	short .step
	mov	edx, eax
	mov	[all_mem_pages],edx		;save
.step:
.skip:

;------------------------------------------------------------------------------
;���X�^�b�N�������̊m�ۂƐݒ�
;------------------------------------------------------------------------------
proc1 alloc_stack
	mov	cl, 11			;error code for stack_malloc

	mov	ax,V86_stack_size	;V86�� stack
	call	stack_malloc		;���ʃ��������蓖��
	test	di,di
	jnz	.skip
	sub	di,4
.skip:
	mov	sp,di			;�X�^�b�N�ؑւ�

	mov	[V86_cs],cs		;cs �ޔ�
	mov	[V86_sp],di		;sp �ޔ�

	mov	ax,PM_stack_size	;�v���e�N�g���[�h�� stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[PM_stack_adr],di	;�L�^

	mov	ax,SAFE_stack_size	;CPU Prot->V86 �؂芷������p stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[safe_stack_adr],di	;�L�^

	; CPU mode change stack
	mov	ax, SW_stack_size * SW_max_nest
	call	stack_malloc
	mov	[sw_stack_bottom]     ,di
	mov	[sw_stack_bottom_orig],di

;------------------------------------------------------------------------------
; Memory setting
;------------------------------------------------------------------------------
proc1 memory_setting
	;//////////////////////////////////////////////////
	; Save real mode interrupt table: 0000:0000-03ff
	;//////////////////////////////////////////////////
	xor	edi,edi
	mov	ax, IntVectors *4
	mov	cl, 11			; error code for heap_malloc
	call	heap_malloc
	mov	[RVects_save_adr],di	; save address

	; copy
	push	ds
	xor	esi,esi			; source
	mov	 ds,si			; ds = 0
	mov	ecx,IntVectors
	rep	movsd			; es:edi <- ds:esi
	pop	ds

	;//////////////////////////////////////////////////
	; alloc real mode int hook memory and other setup
	;//////////////////////////////////////////////////
	call	setup_cv86		;in call_v86.asm

	;//////////////////////////////////////////////////
	;GDT/LDT/TSS
	;//////////////////////////////////////////////////
	mov	cl, 11			;error code for heap_malloc

	mov	ax,GDTsize		;Global Descriptor Table's size
	call	heap_calloc
	mov	[GDT_adr],di

	mov	ax,LDTsize		;Local Descriptor Table's size
	call	heap_calloc
	mov	[LDT_adr],di

	mov	ax,IDTsize		;Interrupt Descriptor Table's size
	call	heap_calloc
	mov	[IDT_adr],di

	mov	ax,TSSsize		;Task State Segment's size
	call	heap_calloc
	mov	[TSS_adr],di

	;//////////////////////////////////////////////////
	; main call buffer
	;//////////////////////////////////////////////////
	movzx	eax, b [call_buf_sizeKB]
	shl	eax, 10
	cmp	eax, 10000h
	jb	.cb_skip
	mov	eax, 0ffffh
.cb_skip:
	mov	cl, 12			;error code: 'Buffer allocation failed'
	mov	[call_buf_size], eax
	call	heap_malloc

	mov	[call_buf_seg16], ds	; real segment
	mov	[call_buf_adr16], di	; offset
	mov	[call_buf_adr32], di	; offset

	;//////////////////////////////////////////////////
	; GP buffer
	;//////////////////////////////////////////////////
	mov	si, offset gp_buffer_table
.gp_loop:
	mov	ax, GP_BUFFER_SIZE
	call	heap_malloc
	mov	[si], di	; save
	add	si, 4
	cmp	si, gp_buffer_table + GP_BUFFERS*4
	jb	.gp_loop

	;//////////////////////////////////////////////////
	; Universal buffer
	;//////////////////////////////////////////////////
	mov	ax, WORK_size
	call	heap_malloc
	mov	[work_adr],di

;------------------------------------------------------------------------------
; alloc dos memory
;------------------------------------------------------------------------------
	call	init_dos_malloc		;memory.asm

;------------------------------------------------------------------------------
; alloc user call buffer	// use by init_TOWNS_16
;------------------------------------------------------------------------------
proc1 alloc_user_call_buffer
	movzx	ax, b [user_cbuf_pages]
	test	ax, ax
	jz	.use_internal_buffer

	mov	cl, 16			;error code: 'User call buffer allocation failed'
	call	malloc_dos_page

	mov	[user_cbuf_ladr], eax	;linear address
	shr	eax, 4
	mov	[user_cbuf_seg16], ax	;dos segment
	jmp	short .skip

.use_internal_buffer:
	mov	eax, [call_buf_adr16]
	mov	ebx, [call_buf_adr32]
	add	ebx, [top_ladr]
	mov	[user_cbuf_adr16], eax	; Seg:Off
	mov	[user_cbuf_ladr],  ebx	; linear address

	; rewrite size
	movzx	ax, [call_buf_sizeKB]
	shr	ax, 2
	mov	[user_cbuf_pages], al

.skip:

;------------------------------------------------------------------------------
;���@��ŗL�̏������ݒ�i�������ݒ�ό�AXMS���O�j
;------------------------------------------------------------------------------
%if TOWNS || PC_98 || PC_AT
	mov	b [init_machine16], 1
	%if TOWNS
		call	init_TOWNS_16
	%elif PC_98
		call	init_PC98_16
	%elif PC_AT
		call	init_AT_16
	%endif

%elif DOS_GENERAL_PURPOSE
	call	init_DOS_general_purpose_16
%endif

;------------------------------------------------------------------------------
; setup XMS
;------------------------------------------------------------------------------
proc1 XMS_setup
	mov	ax,4300h	;AH=43h
	int	2fh		;2fh call
	cmp	al,80h		;XMS install?
	je	.found

	mov	ax, [XMS_entry]	;xms_emulator registed?
	test	ax, ax
	jnz	.setted_xms_entry

.not_found:
	mov	ah, 05		;'XMS not found'
	jmp	error_exit_16

.found:
	push	es
	mov	ax,4310h		;get XMS Entry
	int	2fh			
	mov	[XMS_entry  ],bx	;OFF
	mov	[XMS_entry+2],es	;SEG
	pop	es

.setted_xms_entry:
	;/////////////////////////////
	; get XMS version
	;/////////////////////////////
	xor	ah, ah		;ah = 0
	call	far [XMS_entry]	;XMS call
	test	ah, ah		;check ah for XMS emulator
	jz	.not_found	;occurs only on XMS emulator

	cmp	ah, 3		;XMS 3.0?
	mov	al, [verbose]	;�璷�\���t���O
	je	get_EMB_XMS30	;��������� jmp

%if !USE_XMS20
	jmp	.not_found
%endif

;------------------------------------------------------------------------------
;���g���������̊m�� (use XMS2.0) / Max 64MB
;------------------------------------------------------------------------------
%if USE_XMS20
proc1 get_EMB_XMS20
	test	al,al		;�璷�ȕ\��?
	jz	.step		;0 �Ȃ� jmp
	PRINT16	msg_06		;'Found XMS 2.0'

.step:
	mov	ah,08h		;EMB �󂫃������₢���킹
	call	far [XMS_entry]	;XMS call
	test	ax,ax		;ax �̒l�m�F
	jz	get_EMB_failed	;0 �Ȃ玸�s (jmp)

	mov	[total_EMB_free],ax	;�ő咷�A�󂫃������T�C�Y (KB)
	mov	[max_EMB_free]  ,dx	;���󂫃������T�C�Y (KB)

	mov	dx,ax			;edx = �m�ۂ��郁�����T�C�Y
	mov	ah,09h			;�ő�A���󂫃�������S�Ċm��
	call	far [XMS_entry]		;XMS call
	test	ax,ax			;ax = 0?
	jz	get_EMB_failed		;0 �Ȃ�m�ێ��s
	mov	[EMB_handle], dx	;EMB�n���h�����Z�[�u
	mov	[EMB_handle_valid], ax	;EMB handle is valid

	jmp	lock_EMB	;�m�ۂ����������̃��b�N
%endif

	;///////////////////////
	;�������m�ێ��s
	;///////////////////////
get_EMB_failed:
	mov	ah, 06		; 'XMS memory allocation failed'
	jmp	error_exit_16

;------------------------------------------------------------------------------
;���g���������̊m�� (use XMS3.0)
;------------------------------------------------------------------------------
proc1 get_EMB_XMS30
	test	al,al		;�璷�ȕ\��?
	jz	.step		;0 �Ȃ� jmp
	PRINT16	msg_07		;'Found XMS 3.0'

.step:
	mov	ah,88h			;EMB �󂫃������₢���킹
	call	far [XMS_entry]		;XMS call
	test	bl,bl			;bl �̒l�m�F
	jnz	get_EMB_failed		;non 0 �Ȃ� jmp

	mov	[max_EMB_free]  ,eax	;�ő咷�A�󂫃������T�C�Y (KB)
	mov	[total_EMB_free],edx	;���󂫃������T�C�Y (KB)
					;ecx = �Ǘ�����ŏ�ʃA�h���X, himem.sys is not set
	mov	edx,eax			;edx = �m�ۂ��郁�����T�C�Y
	mov	ah,89h			;�ő�A���󂫃�������S�Ċm��
	call	far [XMS_entry]		;XMS call
	test	ax,ax			;ax = 0?
	jz	get_EMB_failed		;0 �Ȃ�m�ێ��s
	mov	[EMB_handle],dx		;EMB�n���h�����Z�[�u
	mov	[EMB_handle_valid], ax	;EMB handle is valid

;------------------------------------------------------------------------------
;���m�ۂ����g���������̃��b�N �� �g���������̏������ݒ�
;------------------------------------------------------------------------------
proc1 lock_EMB
	mov	ah,0ch		;EMB memory lock
	call	far [XMS_entry]	;XMS call
	test	ax,ax		;ax = 0?
	jnz	.skip		;non 0 is success

	mov	ah, 07		;'XMS memory lock failed'
	jmp	error_exit_16

.skip:
	;
	;DX:BX = �������u���b�N�擪�����A�h���X
	;
	shl	edx,16		;��ʂ�
	mov	 dx,bx		;edx = �擪�����A�h���X
	mov	eax,edx		;eax �� copy

	add	edx,     0fffh		;�[���؂�グ
	and	edx,0fffff000h		;bit 11-0 �̃N���A
	mov	[EMB_physi_adr],edx	;���ۂɎg�p����擪�����A�h���X

	mov	ecx,[max_EMB_free]	;�m�ۂ��ꂽ�������T�C�Y (KB)
	sub	edx,eax			;���p�J�n�A�h���X - �m�ۂ����A�h���X
	jz	short .jp1
	dec	ecx
.jp1:	shr	ecx,2			;KB�P�� �� page �P��
	cmp	ecx,0x40000		;1GB max
	jb	.jp2
	mov	ecx,0x40000		;1GB max
.jp2:	mov	[EMB_pages],ecx		;�g�p�\�ȃy�[�W���Ƃ��ċL�^


;------------------------------------------------------------------------------
; estimate all_mem_pages
;------------------------------------------------------------------------------
; [all_mem_pages] is not set on non VCPI enviroment.

proc1 estimate_all_mem_pages
	mov	eax, [all_mem_pages]
	test	eax, eax
	jnz	.skip

	mov	eax, [EMB_physi_adr]
	add	eax, 0fffh
	shr	eax, 12			; address to pages
	add	eax, ecx		; ecx = [EMB_pages]

	add	eax, 0ffh		;
	xor	al, al			; unit to 1MB

	mov	[all_mem_pages], eax
	mov	d [msg_all_mem_type], 'est.'
.skip:

;------------------------------------------------------------------------------
; initalize page directory and first page table
;------------------------------------------------------------------------------
proc1 init_page_directory
	mov	ax,  2			;page dir + page table 0
	mov	cl, 13			;error code: 'Page table allocation failed'
	call	malloc_dos_page

	mov	[page_dir_ladr],eax	;page directory linear address
	shr	eax, 4
	mov	[page_dir_seg], ax	;page directory dos segment

	; 8KB zero fill
	push	es
	mov	es, ax			;page dir segment

	xor	eax,eax			;eax = 0
	xor	edi,edi			;es:edi
	mov	ecx,2000h / 4		;loop
	rep	stosd			;zero fill

	mov	ecx, [page_dir_ladr]
	shr	ecx, 12			;byte to page
	call	get_phisical_address_of_page

	mov	[to_PM_CR3],edx		;save

	;///////////////////////////////////////////////////
	;Regist first page table to page directory
	;///////////////////////////////////////////////////
	inc	cx			;first page table linear address
	call	get_phisical_address_of_page
	mov	  dl,07h		;enable entry
	mov	[es:0],edx		;entry first page table

	pop	es

;------------------------------------------------------------------------------
;��DOS-Extender ���̍\�z�ƕϐ��̏����iV86 ���j
;------------------------------------------------------------------------------
	;///////////////////////////////////////////////////
	;DTA �f�B�t�H���g�A�h���X�ݒ�
	;///////////////////////////////////////////////////
	;mov	dx,[DTA_off]		;�f�[�^�̈�ɋL�q���Ă��� offset
	;mov	ah,1ah			;DTA �A�h���X�ݒ�
	;int	21h

	;///////////////////////////////////////////////////
	;���荞�݃}�X�N�ۑ�
	;///////////////////////////////////////////////////
%if Restore8259A
%ifdef I8259A_IMR_S
	in	al,I8259A_IMR_S		;8259A �X���[�u
	mov	ah,al			;ah �ֈړ�
	in	al,I8259A_IMR_M		;8259A �}�X�^
	mov	[intr_mask_org],ax	;�L��
%endif
%endif

;------------------------------------------------------------------------------
; initalize first page table
;------------------------------------------------------------------------------
proc1 init_first_page_table
	push	es

	mov	ax, [page_dir_seg]	;page directory segment
	add	ax, 100h		;page0 table segment
	mov	es, ax
	xor	edi,edi			;es:di = first page table address

	cmp	b [use_vcpi], 0
	jnz	.vcpi

	mov	cx, 110h		; 1.1MB = 110000h / 1000h = 110h pages
	xor	ebx, ebx
	mov	bl,  b 7		; phisical address + page table entry bits
.lp:
	mov	es:[di], ebx
	add	di, 4			; next entry
	add	ebx, 1000h		; next address
	loop	.lp

	xor	bl, bl
	mov	[page_init_ladr], ebx	; init linear address = 110000h
	jmp	.end


.vcpi:
	mov	si,[GDT_adr]		;GDT offset
	add	si,VCPI_sel		;ds:si = Descriptor table entries in GDT
	mov	ax,0de01h
	int	67h

	test	ah,ah			;�߂�l check
	jz	.save			;���Ȃ���� jmp

	mov	ah, 08			; 'VCPI: Failed to get protected mode interface'
	jmp	error_exit_16

.save:
	mov	[VCPI_entry],ebx
	shl	edi,(12-2)		; di = first unused page table entry in buffer
	mov	[page_init_ladr],edi	;edi = init linear address
.end:
	pop	es

;------------------------------------------------------------------------------
;���b�o�t���[�h�ؑւ�����
;------------------------------------------------------------------------------
proc1 setup_PM_struct
	mov	eax,[top_ladr]		;�v���O�����擪���j�A�A�h���X
	mov	ecx,[GDT_adr]		;GDT �I�t�Z�b�g
	mov	edx,[IDT_adr]		;IDT �I�t�Z�b�g
	add	ecx,eax			;���j�A�A�h���X
	add	edx,eax			;
	mov	esi,offset LGDT_data	;���[�h�l���L�^���郊�j�A�A�h���X
	mov	edi,offset LIDT_data	;
	mov	[si+2],ecx		;���[�h�p�f�[�^�̈�ɋL�^
	mov	[dI+2],edx		;
	add	esi,eax			;���j�A�A�h���X�Z�o
	add	edi,eax			;
	mov	[to_PM_GDTR],esi	;GDT �ւ̃��[�h�l�̂��郊�j�A�A�h���X
	mov	[to_PM_IDTR],edi	;IDT �ւ̃��[�h�l�̂��郊�j�A�A�h���X

	;mov	w [to_PM_LDTR],LDT_load_sel	;LDTR�̒l�i�����l��`�ρj
	;mov	w [to_PM_TR]  ,TSS_load_sel	;TR�̒l�i�����l��`�ρj
	mov	d [to_PM_EIP] ,offset start32	;EIP �̒l
	;mov	w [to_PM_CS]  ,F386_cs		;CS �̒l�i�����l��`�ρj

;------------------------------------------------------------------------------
;��GDT �����ݒ胋�[�`��
;------------------------------------------------------------------------------
;GDT ���� LDT / IDT / TSS / DOS������ �Z���N�^�̐ݒ�
;
proc1 setup_LDT_IDT_TSS

	mov	 di,[GDT_adr]	;GDT �̃I�t�Z�b�g
	mov	ebx,[top_ladr]	;���̃v���O�����̐擪���j�A�A�h���X(bit 31-0)

	;/// Free386�p CS/DS �ݒ� ///////////////////////////////////

	mov	dl,[top_ladr +2]	;bit 16-23
	mov	ax,0ffffh		;���~�b�g�l

	mov	cl,40h			;386�`��
	mov	dh,9ah			;R/X 386
	mov	[di + F386_cs   ],ax
	mov	[di + F386_cs +2],bx
	mov	[di + F386_cs +4],dx
	mov	[di + F386_cs +6],cl

	mov	dh,92h			;R/W 386
	mov	[di + F386_ds   ],ax
	mov	[di + F386_ds +2],bx
	mov	[di + F386_ds +4],dx
	mov	[di + F386_ds +6],cl

	mov	dh,9ah			;R/X 286
	mov	[di + F386_cs286   ],ax
	mov	[di + F386_cs286 +2],bx
	mov	[di + F386_cs286 +4],dx

	mov	dh,92h			;R/W 286
	mov	[di + F386_ds286   ],ax
	mov	[di + F386_ds286 +2],bx
	mov	[di + F386_ds286 +4],dx


	;/// LDT �Z���N�^�̐ݒ� /////////////////////////////////////

	mov	ecx,[LDT_adr]			;LDT �̃I�t�Z�b�g
	add	ecx,ebx				;�擪�A�h���X���Z
	mov	 ax,LDTsize -1			;LDT �̑傫�� -1

	mov	[di + LDT_load_sel   + 2],ecx	;�x�[�X�A�h���X�ݒ�
	mov	[di + LDT_sel        + 2],ecx	;
	mov	[di + LDT_load_sel      ],ax	;���~�b�g�l�ݒ�
	mov	[di + LDT_sel           ],ax	;
	mov	w [di + LDT_load_sel + 5],0082h	;�����ݒ� (LDT)
	mov	w [di + LDT_sel      + 5],4092h	;�����ݒ� (Read/Write)

	;/// GDT/IDT �A�N�Z�X�p�Z���N�^�̐ݒ� ///////////////////////

	mov	ecx,[GDT_adr]			;GDT �I�t�Z�b�g
	mov	edx,[IDT_adr]			;IDT �I�t�Z�b�g
	add	ecx,ebx				;�擪�A�h���X���Z
	add	edx,ebx				;  �V
	mov	[di + GDT_sel   + 2],ecx	;�x�[�X�A�h���X�ݒ�
	mov	[di + IDT_sel   + 2],edx	;  �V
	mov	w [di + GDT_sel    ],GDTsize-1	;���~�b�g�l�ݒ�
	mov	w [di + IDT_sel    ],IDTsize-1	;
	mov	w [di + GDT_sel + 5],4092h	;�����ݒ� (Read/Write)
	mov	w [di + IDT_sel + 5],4092h	;�����ݒ� (Read/Write)

	;/// TSS �Z���N�^�̐ݒ� /////////////////////////////////////

	mov	ecx,[TSS_adr]			;TSS �̃I�t�Z�b�g
	add	ecx,ebx				;�擪�A�h���X���Z
	mov	ax,TSSsize -1			;TSS �̑傫�� -1

	mov	[di + TSS_load_sel   + 2],ecx	;�x�[�X�A�h���X�ݒ�
	mov	[di + TSS_sel        + 2],ecx	;
	mov	[di + TSS_load_sel      ],ax	;���~�b�g�l�ݒ�
	mov	[di + TSS_sel           ],ax	;
	mov	w [di + TSS_load_sel + 5],0089h	;�����ݒ� (���p�\/Avail TSS)
	mov	w [di + TSS_sel      + 5],4092h	;�����ݒ� (Read/Write)

	;/// DOS������/�S�������A�N�Z�X�p�Z���N�^ ///////////////////
	mov	edx, [all_mem_pages]		;���������y�[�W��
	dec	edx

	;���~�b�g�l�ݒ�
	mov	w [di + DOSMEM_sel],(DOSMEMsize / 4096) -1
	mov	  [di + ALLMEM_sel],dx		;���ʂ̂ݐݒ�

	shr	edx,8				;bit8-11 �� ���~�b�g�lbit16-19
	and	dx,00f00h			;�������}�X�N
	or	dx,0c092h			;��������ݒ�

	mov	w [di + DOSMEM_sel +5],0c092h	;�����ݒ� (���p�\/Avail TSS)
	mov	  [di + ALLMEM_sel +5],dx	;�����ݒ� (Read/Write)

;------------------------------------------------------------------------------
;�����荞�݃e�[�u�������ݒ胋�[�`��
;------------------------------------------------------------------------------
;	dw	offset %1	;offset  bit 0-15
;	dw	F386_cs		;selctor
;	dw	0ee00h		;���� (386���荞�݃Q�[�g) / �������x��3
;	dw	00000h		;offset  bit 16-31
proc1 setup_IDT
	mov	 ax,F386_cs	;�Z���N�^
	shl	eax,16		;��ʂ�
	mov	edx,0ee00h	;386���荞�݃Q�[�g / �������x��3
	mov	di,[IDT_adr]	;���荞�݃e�[�u���擪

	;/// CPU �������荞�ݐݒ� /////////////////////////
	mov	ax,offset PM_int_00h	;���荞�� #00
	mov	bp,4			;�I�t�Z�b�g���Z�l
	mov	cx,20h			;���[�v�� (00-1fh)
	call	write_IDT		;IDT �֏�������

	;/// DOS���荞�ݐݒ� //////////////////////////////
	mov	cx,10h			;20h �` 2fh
	mov	si,offset DOS_int_list	;DOS ���荞�݃��X�g
	mov	bp, 8

	align	4
.loop1:	mov	ax,[si]			;jmp ��ǂݏo��
	mov	[di  ],eax		;+00h
	mov	[di+4],edx		;+04h
	add	si,byte 2		;���̊��荞�݃��X�g����
	add	di,bp			;�Z���N�^�I�t�Z�b�g�X�V
	loop	.loop1

	;/// �_�~�[���[�`���̔z�u /////////////////////////
	mov	cx,100h - 30h		;30h �` 0ffh
	mov	ax,offset PM_int_dummy	;�_�~�[���[�`��

	align	4
.loop2:	mov	[di  ],eax		;+00h
	mov	[di+4],edx		;+04h
	add	di,bp			;�Z���N�^�I�t�Z�b�g�X�V
	loop	.loop2

;------------------------------------------------------------------------------
; Hardware interrupt IDT setup
;------------------------------------------------------------------------------
proc1 setup_hardware_int_IDT

%ifdef USE_VCPI_8259A_API
	cmp	b [use_vcpi], 0
	jnz	.call_vcpi

	%if DOS_GENERAL_PURPOSE
	push	edx			;keep edx
	call	get_8259a_vector	;auto detect machine
	pop	edx
	jnc	.continue		;ret bx/cx
	%endif

	mov	ah, 04			;'VCPI not found and failed to detect machine'
	jmp	error_exit_16

.call_vcpi:
	mov	ax,0de0ah		;VCPI function 0Ah
	int	67h			;get 8259 interrupt vector
.continue:
	mov	[vcpi_8259m], bl
	mov	[vcpi_8259s], cl
	mov	si, cx
	shl	bx, 3
	shl	si, 3
%else
	mov	bx, HW_INT_MASTER *8
	mov	si, HW_INT_SLAVE  *8
%endif
	mov	di, [IDT_adr]		;IDT table offset
	add	si, di			;si = slave  start offset
	add	di, bx			;di = master start offset

	mov	bp, 4	; �e�[�u���I�t�Z�b�g���Z�l

	mov	ax,HW_int_master_table	;���荞�݃}�X�^�� #00
	mov	cx,8			;���[�v��
	;mov	di, di			;�}�X�^�����荞�ݔԍ� *8
	call	write_IDT		;IDT �֏�������

	mov	ax,HW_int_slave_table	;���荞�݃X���[�u�� #00
	mov	cx,8			;���[�v��
	mov	di, si			;�X���[�u�����荞�ݔԍ� *8
	call	write_IDT		;IDT �֏�������

;------------------------------------------------------------------------------
; hook int 24h
;------------------------------------------------------------------------------
proc1 setup_int_24h
	push	es

	mov	ax, 3524h		; read int 24h
	int	21h
	mov	[DOS_int24h_adr], bx
	mov	[DOS_int24h_seg], es

	mov	dx, offset hook_int_24h
	mov	ax, 2524h		; set int 24h
	int	21h

	pop	es

;------------------------------------------------------------------------------
;[VCPI] change CPU mode
;------------------------------------------------------------------------------
proc1 cpu_mode_change
	cmp	b [use_vcpi], 0
	jz	cpu_mode_change_from_real_mode

	mov	ax,0de0ch		;VCPI function  0Ch
	mov	esi,[top_ladr]		;�v���O�����擪���j�A�A�h���X
	add	esi,offset to_PM_data	;�ؑւ��p�\���̃A�h���X
	mov	[to_PM_data_ladr],esi	;��L���j�A�A�h���X�L�^

	int	67h			;�v���e�N�g���[�h�� start32 ��

	mov	ah, 09			;'VCPI: Failed to change CPU to protected mode'
	jmp	error_exit_16

;------------------------------------------------------------------------------
; change CPU mode from real mode
;------------------------------------------------------------------------------
proc1 cpu_mode_change_from_real_mode
	cli
	lgdt	[LGDT_data]
	lidt	[LIDT_data]
	mov	eax, [to_PM_CR3]
	mov	cr3, eax

	mov	eax, cr0
	or	eax, 80000001h	; PG=PE=1
	mov	cr0, eax

	db	0eah			;��far jmp
	dw	offset .32
	dw	F386_cs

	BITS	32
.32:
	lldt	cs:[to_PM_LDTR]
	ltr	cs:[to_PM_TR]
	jmp	start32
	BITS	16

;==============================================================================
;���T�u���[�`��
;==============================================================================
;------------------------------------------------------------------------------
;�����荞�݃e�[�u���ւ̏����o���ifrom IDT �����ݒ胋�[�`���j
;------------------------------------------------------------------------------
proc2 write_IDT
	mov	[di  ],eax		;+00h
	mov	[di+4],edx		;+04h
	add	ax, bp			;���̊��荞�݃A�h���X��
	add	di, 8			;�Z���N�^�I�t�Z�b�g�X�V
	loop	write_IDT
	ret

;------------------------------------------------------------------------------
; linear page number to phisical address
;------------------------------------------------------------------------------
;	in	cx	page number
;	out	edx	phisical address
;
proc2	get_phisical_address_of_page
	cmp	b [use_vcpi], 0
	jnz	.vcpi

	xor	edx, edx
	mov	dx, cx
	shl	edx, 12
	ret

.vcpi:
	push	ax
	mov	ax,0de06h		; get Phisical address
	int	67h			; VCPI call
	test	ah,ah
	pop	ax
	jnz	.vcpi_error
	ret

.vcpi_error:
	pop	ax			; remove ret
	mov	ah, 10			; 'VCPI: Failed to get phisical address of page'
	jmp	error_exit_16

;------------------------------------------------------------------------------
; hook for int 24
;------------------------------------------------------------------------------
proc2 hook_int_24h
	pushf
	call	far [cs:DOS_int24h_adr]

	cmp	al,02h
	jne	.ret
	int	23h		; Force end program
.ret:
	iret
	; �{�� al=2 �̂Ƃ��́ACTRL-C ���[�`���iint 23h�j���Ă΂��͂������A
	; �Ȃ����Ă΂�Ȃ��iDOS6�ɂĊm�F�j�̂ŁA
	; ���܂�ǂ����@�ł͂Ȃ��������I�ɌĂ�ł���B

;##############################################################################
;==============================================================================
;���v���O�����̏I�� (16 bit)
;==============================================================================
proc2 exit_16
	;////////////////////////////////////////////////////////////
	;/// ���荞�݃}�X�N���� /////////////////////////////////////
	%if Restore8259A
	%ifdef I8259A_IMR_S
		mov	ax,[intr_mask_org]	;�������
		out	I8259A_IMR_M, al	;�}�X�^��
		mov	al,ah			;
		out	I8259A_IMR_S, al	;�X���[�u��
	%endif
	%endif

	;///////////////////////////////
	;���������
	;///////////////////////////////
	sti
	call	before_exit_16		;�m�ۂ����������̊J��

	mov	ax,[err_level]		;AH = Free386 ERR / AL = Program ERR
	test	ah,ah			;check
	jnz	error_exit_16		;non 0 �Ȃ�G���[�I��

	mov	ah,4ch
	int	21h			;����I��


;------------------------------------------------------------------------------
;error exit
;------------------------------------------------------------------------------
; in	ah = Free386's internal error code
;
proc2 error_exit_16
	;
	; search error message
	;
	test	ah, ah
	jz	.exit			;ah=0, no error message

	mov	bx, err_msg_table
.loop0:
	dec	ah
	jz	.found

	mov	cx, 256			;safety
.loop1:
	mov	al, [bx]
	inc	bx
	cmp	al, '$'
	je	.loop0
	dec	cx
	jnz	.loop1
	;
	; safety
	;
	mov	bx, err_00
.found:
	cmp	b [bx], 0		;output only when verbose flag
	jnz	.print
	cmp	b [verbose], 0
	jz	.exit

.print:
	PRINT16	err_head
	mov	dx,bx
	mov	ah,09h			;output error message
	int	21h
.exit:
	call	before_exit_16

	mov	al, F386ERR
	mov	ah, 4ch
	int	21h			;end


;------------------------------------------------------------------------------
;before exit
;------------------------------------------------------------------------------
proc2 before_exit_16
%if TOWNS || PC_98 || PC_AT
	cmp	b [init_machine16], 0
	jz	.skip
	%if TOWNS
		call	exit_TOWNS_16
	%elif PC_98
		call	exit_PC98_16
	%elif PC_AT
		call	exit_AT_16
	%endif
.skip:
%endif

proc1 .free_EMB
	mov	ax, [EMB_handle_valid]
	test	ax, ax
	jz	.ret

	mov	w [EMB_handle_valid], 0

	mov	dx,[EMB_handle]	;dx = EMB handle
	mov	ah,0dh		;unlock EMB
	call	far [XMS_entry]

	mov	ah,0ah		;free EMB
	call	far [XMS_entry]
	test	ax,ax		;ax = 0?
	jnz	.ret

	PRINT16	err_xms_free
.ret:
	ret

;******************************************************************************
; 32bit mode code
;******************************************************************************
seg32	text32 class=CODE align=4 use32

%include	"f386prot.asm"

;******************************************************************************
; DATA
;******************************************************************************
segdata	data class=DATA align=4

%include	"f386data.asm"

;******************************************************************************
;heap
;******************************************************************************
segheap	heap class=DATA align=16
end_adr:
	;
	; Below is the heap memory area.
	;
;******************************************************************************
;******************************************************************************
