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
global		free_liner_adr
global		free_RAM_padr
global		free_RAM_pages

;--- for call_v86.asm -----------------------------
global		to_PM_EIP
global		to_PM_data_ladr
global		VCPI_entry
global		VCPI_stack_adr
global		V86_cs

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

global		all_mem_pages
global		cpu_is_386sx

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
;���p�����^�m�F (free386 �ւ̓���w��)
;------------------------------------------------------------------------------
proc2 parameter_check
	mov	si, 81h			;argument string pointer
	mov	bp, 7fh			;argument max length
	xor	bx, bx

	jmp	short .loop

	;///////////////////////////////
	; set PharLap version to 2.2 (compatible EXE386)
	;///////////////////////////////
.para_2:
	mov	d [pharlap_version], 20643232h	; ' d22'
	jmp	short .loop

	;///////////////////////////////
	; -m : Use memory maximum
	;///////////////////////////////
.para_m:
	mov	b [pool_for_paging], 1	;�y�[�W���O�p�v�[��������
	mov	w [resv_real_memKB], 0	;reserved dos memory = 0
	jmp	short .loop
	;/// Move some parameters to this location. Because does not fit in jmp short.
	;/// jmp short �Ɏ��܂�Ȃ��̂ňꕔ��͂������ɋL�q

.para_maxreal:
.para_minreal:
.para_callbuf:
	add	si, bx
	call	get_next_parameter	;skip next parameter
	jmp	short .loop

.sp_param:
	; RUN386 some parameters
	cmp	eax, 'maxr'
	je	.para_maxreal
	cmp	eax, 'minr'
	je	.para_minreal
	cmp	eax, 'call'
	je	.para_callbuf
	jmp	short .sp_param_return

.loop:
	add	si, bx
	call	get_next_parameter	;si=string, bx=length
	test	bx, bx
	jz	.end_paras		;0

	cmp	b [si],'-'		;'-' parameter?
	jne	.end_paras		;

	mov	eax,[si+1]		;load 4 byte

	jmp	short .sp_param		;for short jump
	.sp_param_return:		;

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
	jmp	short .loop

	;///////////////////////////////
	; -v
	;///////////////////////////////
.para_v:
	cmp	ah,'v'			; -vv?
	je	.v0
	mov	ah,01
.v0:
	mov	b [verbose],ah
	jmp	short .loop

	;///////////////////////////////
	; -q
	;///////////////////////////////
.para_q:
	mov	b [show_title],0	;no title output
	jmp	short .loop

	;///////////////////////////////
	; -p?
	;///////////////////////////////
.para_p:
	and	ah,01			;-p? / al = ?
	mov	[search_PATH],ah	;search PATH flag
	jmp	short .loop

	;///////////////////////////////
	; -c?
	;///////////////////////////////
.para_c:
	test	ah,ah			;-c? / al = ?
	jnz	.c0			
	mov	ah,01			;�w��Ȃ��Ȃ� -c1 �Ɖ���
.c0:	and	ah,03			;bit 1,0 ���o��
	mov	[reset_CRTC],ah
	jmp	short .loop

%if TOWNS
	;///////////////////////////////
	; -n, do not load CoCo/NSD
	;///////////////////////////////
.para_n:
	and	ah,01h			;al = -n?
	mov	b [load_nsdd],ah
	jmp	short .loop
%endif

	;///////////////////////////////
	; -i?
	;///////////////////////////////
.para_i:
	and	ah,01			;-i? / al = ?
	mov	b [check_MACHINE],ah
	jmp	short .loop

	;///////////////////////////////
	; save exp file name
	;///////////////////////////////
.end_paras:
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
	mov	cx, 4		; digits
	mov	di, seg_hex	; store target
	call	bin2hex_16
	PRINT16	seg_msg
.skip:

;------------------------------------------------------------------------------
;���ȈՋ@�픻��
;------------------------------------------------------------------------------
%if MACHINE_CODE			;�@��ėp�łȂ�

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
;��VCPI �̑��݊m�F
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
	mov	ah, 03		; 'EMS not found'
	jmp	error_exit_16

.skip:
	push	ds
	pop	es
%endif

	;
	;----- VCPI �̑��݊m�F -----
	;
VCPI_check:
	mov	ax,0de00h	; AL=00 : VCPI check!
	int	67h		; VCPI call
	test	ah,ah		; �߂�l check
	jz	short .skip	; found VCPI

	mov	ah, 04		; 'VCPI not found'
	jmp	error_exit_16
.skip:

;------------------------------------------------------------------------------
;�����������ʂ̎擾 / VCPI
;------------------------------------------------------------------------------
get_vcip_memory_size:
	mov	ax,0de02h			;VCPI function 02h
	int	67h				;�ŏ�ʃy�[�W�̕����A�h���X
	shr	edx,12				;�A�h���X -> page
	inc	edx				;edx = ���������y�[�W��

	mov	eax, MAX_RAM /4096		;�ő僁�����ʐ���
	cmp	edx, eax
	jb	short .step
	mov	edx, eax
.step:
	mov	[all_mem_pages],edx		;�l�L�^

;------------------------------------------------------------------------------
;���X�^�b�N�������̊m�ۂƐݒ�
;------------------------------------------------------------------------------
	mov	cl, 11			;error code for stack_malloc

	mov	ax,V86_stack_size	;V86�� stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	sp,di			;�X�^�b�N�ؑւ�

	mov	[V86_cs],cs		;cs �ޔ�
	mov	[V86_sp],di		;sp �ޔ�

	mov	ax,PM_stack_size	;�v���e�N�g���[�h�� stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[PM_stack_adr],di	;�L�^

	mov	ax,VCPI_stack_size	;CPU Prot->V86 �؂芷������p stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[VCPI_stack_adr],di	;�L�^

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
	mov	cl, 12			;error code: 'CALL buufer allocation failed'
	mov	[call_buf_size], eax
	call	heap_malloc

	mov	[call_buf_seg16], ds	; real segment
	mov	[call_buf_adr16], di	; offset
	mov	[call_buf_adr32], di	; offset

	;//////////////////////////////////////////////////
	; Universal buffer
	;//////////////////////////////////////////////////
	mov	cl, 12			;error code for heap_malloc
	mov	ax, WORK_size
	call	heap_malloc
	mov	[work_adr],di

	mov	cx, GP_BUFFERS
	mov	si, offset gp_buffer_table
.gp_loop:
	mov	ax, GP_BUFFER_SIZE
	call	heap_malloc
	mov	[si], di	; save
	add	si, 4
	loop	.gp_loop

	mov	b [gp_buffer_remain], GP_BUFFERS

;------------------------------------------------------------------------------
;���@��ŗL�̏������ݒ�i�������ݒ�ό�AXMS���O�j
;------------------------------------------------------------------------------

%if TOWNS
	call	init_TOWNS_16
%elif PC_98
	call	init_PC98_16
%elif PC_AT
	call	init_AT_16
%endif

;------------------------------------------------------------------------------
;��XMS �̊m�F�ƌĂяo���A�h���X�̎擾
;------------------------------------------------------------------------------
XMS_setup:
	mov	ax,4300h	;AH=43h : XMS
	int	2fh		;2fh call
	cmp	al,80h		;XMS install?
	je	.found		;��������� jmp

	mov	ah, 05		;'XMS not found'
	jmp	error_exit_16

.found:
	push	es
	mov	ax,4310h		;XMS �G���g���|�C���g�̎擾
	int	2fh			
	mov	[XMS_entry  ],bx	;OFF
	mov	[XMS_entry+2],es	;SEG
	pop	es

	;/////////////////////////////
	;�o�[�W�����ԍ��̎擾
	xor	ah,ah		;ah = 0
	XMS_function		;XMS call
	mov	[XMS_Ver],ah	;Driver �d�l�̃��W���[�o�[�W�������L�^

	cmp	ah,3		;XMS 3.0?
	mov	al,[verbose]	;�璷�\���t���O
	je	get_EMB_XMS30	;��������� jmp


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
	XMS_function		;XMS call
	test	ax,ax		;ax �̒l�m�F
	jz	get_EMB_failed	;0 �Ȃ玸�s (jmp)

	mov	[total_EMB_free],ax	;�ő咷�A�󂫃������T�C�Y (KB)
	mov	[max_EMB_free]  ,dx	;���󂫃������T�C�Y (KB)

	mov	dx,ax			;edx = �m�ۂ��郁�����T�C�Y
	mov	ah,09h			;�ő�A���󂫃�������S�Ċm��
	XMS_function			;�m��
	test	ax,ax			;ax = 0?
	jz	get_EMB_failed		;0 �Ȃ�m�ێ��s
	mov	[EMB_handle],dx		;EMB�n���h�����Z�[�u

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
	XMS_function			;XMS call
	test	bl,bl			;bl �̒l�m�F
	jnz	get_EMB_failed		;non 0 �Ȃ� jmp

	mov	[max_EMB_free]  ,eax	;�ő咷�A�󂫃������T�C�Y (KB)
	mov	[total_EMB_free],edx	;���󂫃������T�C�Y (KB)
	mov	[EMB_top_adr]   ,ecx	;�Ǘ�����ŏ�ʃA�h���X // ecx=0�̖͗l

	mov	edx,eax			;edx = �m�ۂ��郁�����T�C�Y
	mov	ah,89h			;�ő�A���󂫃�������S�Ċm��
	XMS_function			;�m��
	test	ax,ax			;ax = 0?
	jz	get_EMB_failed		;0 �Ȃ�m�ێ��s
	mov	[EMB_handle],dx		;EMB�n���h�����Z�[�u

;------------------------------------------------------------------------------
;���m�ۂ����g���������̃��b�N �� �g���������̏������ݒ�
;------------------------------------------------------------------------------
proc1 lock_EMB
	mov	ah,0ch		;EMB memory lock
	XMS_function		;
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
	cmp	ecx,0x40000		;256Kpage max
	jb	.jp2
	mov	ecx,0x40000		;1GB max
.jp2:	mov	[EMB_pages],ecx		;�g�p�\�ȃy�[�W���Ƃ��ċL�^

;------------------------------------------------------------------------------
; alloc dos memory
;------------------------------------------------------------------------------
	call	init_dos_malloc

;------------------------------------------------------------------------------
; alloc user call buffer
;------------------------------------------------------------------------------
proc1 alloc_user_call_buffer
	movzx	ax, b [user_cbuf_pages]
	test	ax, ax
	jz	.use_internal_buffer

	mov	cl, 16			;error code: 'User call buufer allocation failed'
	call	dos_malloc_page

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
; initalize page directory and first page table
;------------------------------------------------------------------------------
proc1 init_page_directory
	mov	ax,  2			;page dir + page table 0
	mov	cl, 13			;error code: 'Page table allocation failed'
	call	dos_malloc_page

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
	mov	ax,0de06h		;VCPI 06h, get phisical address
	int	67h			;edx = page directory phisical address
	mov	[to_PM_CR3],edx		;save

	;///////////////////////////////////////////////////
	;Regist first page table to page directory
	;///////////////////////////////////////////////////
	inc	cx			;first page table linear address
	mov	ax,0de06h		;VCPI 06h, get phisical address
	int	67h			;VCPI call
	mov	  dl,07h		;enable entry
	mov	[es:0],edx		;entry first page table

	pop	es

;------------------------------------------------------------------------------
; alloc additional page table from DOS memory
;------------------------------------------------------------------------------
;	When more than 4MB of extended memory is used,
;	additional page tables are required in DOS memory.
;  �g����������4MB�ȏ�g���Ă��鎞�ADOS���������ɒǉ��y�[�W�e�[�u�����K�v�B
;
proc1 alloc_page_table
	mov	eax, [EMB_physi_adr]	; free memory's phisical address
	add	eax, 0fffh		; 4KB Unit
	shr	eax, 22			; to need page tables
	jz	.not_need

	add	[page_tables_in_dos],ax	; count up
	mov	bp, ax			; bp = need tables

	mov	cl, 13			;error code: 'Page table allocation failed'
	call	dos_malloc_page
	mov	ecx, eax		; ecx = linear address
	shr	ecx, 12			; byte to page

	push	es
	push	fs
	mov	fs, [page_dir_seg]
	xor	bx, bx
.loop:
	; cx = target linear adddress/4KB
	mov	ax,0de06h		; get Phisical address
	int	67h			; VCPI call
	mov	dl,07h			; address to table entry
	add	bx, 4
	mov	[fs:bx], edx		; entry to page directory

	; clear page table
	mov	dx, cx
	shl	cx, 12-4		; PAGE to para
	mov	es, cx
	xor	di, di
	mov	cx, 1000h / 4		; 4KB/4
	xor	eax, eax
	rep	stosd

	inc	cx			; for loop
	dec	bp
	jnz	.loop

	pop	fs
	pop	es
.not_need:

;------------------------------------------------------------------------------
; [VCPI] get protected mode interface
;------------------------------------------------------------------------------
proc1 get_VCPI_interface
	push	es

	mov	ax, [page_dir_seg]	;page directory segment
	add	ax, 100h		;page0 table segment
	mov	es, ax
	xor	edi,edi			;es:di = first page table address

	mov	si,[GDT_adr]		;GDT offset
	add	si,VCPI_sel		;ds:si = Descriptor table entries in GDT
	mov	ax,0de01h
	int	67h

	pop	es

	test	ah,ah			;�߂�l check
	jz	.save			;���Ȃ���� jmp

	mov	ah,08			; 'VCPI: Failed to get protected mode interface'
	jmp	error_exit_16

.save:
	mov	[VCPI_entry],ebx
	shl	edi,(12-2)		; di = first unused page table entry in buffer
	mov	[free_liner_adr],edi	;edi = free linear address


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
%if Restore8259A && I8259A_IMR_S
	in	al,I8259A_IMR_S		;8259A �X���[�u
	mov	ah,al			;ah �ֈړ�
	in	al,I8259A_IMR_M		;8259A �}�X�^
	mov	[intr_mask_org],ax	;�L��
%endif


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
	mov	[di + F386_cs    ],ax
	mov	[di + F386_cs  +2],bx
	mov	[di + F386_cs  +4],dx
	mov	[di + F386_cs  +6],cl

	mov	dh,92h			;R/W 386
	mov	[di + F386_ds    ],ax
	mov	[di + F386_ds  +2],bx
	mov	[di + F386_ds  +4],dx
	mov	[di + F386_ds  +6],cl

	mov	dh,9ah			;R/X 286
	mov	[di + F386_cs2   ],ax
	mov	[di + F386_cs2 +2],bx
	mov	[di + F386_cs2 +4],dx

	mov	dh,92h			;R/W 286
	mov	[di + F386_ds2   ],ax
	mov	[di + F386_ds2 +2],bx
	mov	[di + F386_ds2 +4],dx


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
	mov	ax,0de0ah		;VCPI function  0Ah
	int	67h			;get 8259 interrupt vector

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
;��hook int 24h
;------------------------------------------------------------------------------
proc1 setup_int_24h

	mov	ax, 3524h		; read int 24h
	int	21h
	mov	[DOS_int24h_adr], bx
	mov	[DOS_int24h_seg], es

	mov	dx, offset hook_int_24h
	mov	ax, 2524h		; set int 24h
	int	21h

;------------------------------------------------------------------------------
;���b�o�t���[�h�ؑւ�
;------------------------------------------------------------------------------
proc1 cpu_mode_change

	mov	ax,0de0ch		;VCPI function  0Ch
	mov	esi,[top_ladr]		;�v���O�����擪���j�A�A�h���X
	add	esi,offset to_PM_data	;�ؑւ��p�\���̃A�h���X
	mov	[to_PM_data_ladr],esi	;��L���j�A�A�h���X�L�^

	int	67h			;�v���e�N�g���[�h�� start32 ��

	mov	ah, 09			;'VCPI: Failed to change CPU to protected mode'
	jmp	error_exit_16


;==============================================================================
;���T�u���[�`��
;==============================================================================
;------------------------------------------------------------------------------
;�����荞�݃e�[�u���ւ̏����o���ifrom IDT �����ݒ胋�[�`���j
;------------------------------------------------------------------------------
	align	4
write_IDT:
	mov	[di  ],eax		;+00h
	mov	[di+4],edx		;+04h
	add	ax, bp			;���̊��荞�݃A�h���X��
	add	di, 8			;�Z���N�^�I�t�Z�b�g�X�V
	loop	write_IDT
	ret


;------------------------------------------------------------------------------
;���m�ۂ����g���������̊J��
;------------------------------------------------------------------------------
	align	4
free_EMB:
	mov	dx,[EMB_handle]	;dx = EMB�n���h��
	test	dx,dx		;�n���h���̒l�m�F
	jz	.ret		;0 �Ȃ�� ret
	mov	w [EMB_handle], 0

	mov	ah,0dh		;EMB �̃��b�N����
	XMS_function

	mov	ah,0ah		;EMB �̊J��
	XMS_function
	test	ax,ax		;ax = 0 ?
	jnz	.ret		;non 0 �Ȃ� jmp

	PRINT16	err_xms_free	;�u�������J�����s�v
.ret:
	ret


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
	%if Restore8259A && I8259A_IMR_S
		mov	ax,[intr_mask_org]	;�������
		out	I8259A_IMR_M, al	;�}�X�^��
		mov	al,ah			;
		out	I8259A_IMR_S, al	;�X���[�u��
	%endif

	;///////////////////////////////
	;�e�@��ŗL�̏I������
	;///////////////////////////////
	%if TOWNS
		call	exit_TOWNS_16
	%elif PC_98
		call	exit_PC98_16
	%elif PC_AT
		call	exit_AT_16
	%endif

	;///////////////////////////////
	;���������
	;///////////////////////////////
	sti
	call	free_EMB		;�m�ۂ����������̊J��

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
	call	free_EMB
	mov	al, F386ERR
	mov	ah, 4ch
	int	21h			;end


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
