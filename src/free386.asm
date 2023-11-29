;******************************************************************************
;�@Free386 (compatible to RUN386 DOS-Extender)
;		'ABK project' all right reserved. Copyright (C)nabe@abk
;******************************************************************************
;[TAB=8]
;
%include	"nasm_abk.h"		;NASM �p�w�b�_�t�@�C��
%include	"macro.asm"		;�}�N�����̑}��
%include	"f386def.inc"		;�萔���̑}��

%include	"start.inc"		;�t�@�C���擪 / �����`�ϐ�
%include	"sub.inc"		;�֗��ȃT�u���[�`���̃w�b�_�t�@�C��
%include	"f386sub.inc"		;Free386�p �T�u���[�`��
%include	"f386seg.inc"		;�Z�O�����g���C�u����
%include	"f386cv86.inc"		;V86 ���� Protect �჌�x���A�g���[�`��
%include	"int.inc"		;���荞�݃��[�`���̃w�b�_�t�@�C��

;******************************************************************************
; global symbols
;******************************************************************************

	;--- for f386seg.asm ------------------------------
public		GDT_adr, LDT_adr
public		free_TABLE_ladr
public		free_LINER_ADR
public		free_RAM_padr
public		free_RAM_pages
public		DOS_mem_adr
public		DOS_mem_pages
public		page_dir

	;--- for f386cv86.asm -----------------------------
public		to_PM_EIP, to_PM_data_ladr
public		VCPI_entry
public		v86_cs
public		int_buf_adr, int_buf_adr_org
public		int_rwbuf_adr, int_rwbuf_adr_org
public		int_rwbuf_size
public		int_rwbuf_adr
public		VCPI_stack_adr
public		heap_malloc, stack_malloc
public		f386err

	;--- for int.asm ----------------------------------
public		work_adr
public		PM_stack_adr
public		END_program
public		IDT_adr
public		RVects_flag_tbl
public		DTA_off, DTA_seg
public		DOS_int21h_adr
public		top_adr
public		default_API
public		pharlap_version

public		callbuf_adr16
public		callbuf_seg16
public		callbuf_adr32

;******************************************************************************
;���R�[�h(16 bit)
;******************************************************************************
segment	text public align=16 class=CODE use16
;------------------------------------------------------------------------------
;����������
;------------------------------------------------------------------------------
	global	start
start:
	mov	ax,cs
	mov	bx,ds
	cmp	ax,bx		;cs �� ds ���r
	je	.step		;��������΁i.com ̧�فj�����p��

	mov		ds,ax		; ds �� cs ���烍�[�h
	PRINT86		EXE_err		;�ucom �`���Ŏ��s���Ă��������v
	Program_end	F386ERR		; �v���O�����I��(ret = 99)

	align	4
.step:	;///////////////////////////////
	;���g�p DOS �������̊J��
	mov	bx,1000h		;64KB / 16
	mov	ah,4ah			;�������u���b�N�T�C�Y�̕ύX
	int	21h			;DOS call

	call	get_parameter		;�p�����^���(sub.inc)

;------------------------------------------------------------------------------
;���p�����^�m�F (free386 �ւ̓���w��)
;------------------------------------------------------------------------------
parameter_check:
	jmp	short .check_start

	;///////////////////////////////
	; -m : Use memory maximum
	;///////////////////////////////
.para_m:
	mov	b [pool_for_paging],1	;�y�[�W���O�p�v�[��������
	mov	b [real_mem_pages] ,250	;DOS���������ő�܂Ŏg��, 255�w��s��
	mov	b [maximum_heap]   ,1	;�w�b�_�𖳎����čő�q�[�v�����������蓖��
	jmp	.loop
	;/// Move some parameters to this location. Because does not fit in jmp short.
	;/// jmp short �Ɏ��܂�Ȃ��̂ňꕔ��͂������ɋL�q

.check_start:
	mov	cx,[paras]		;�p�����[�^��
	test	cx,cx			;�l�m�F
	jz	.end_paras		;0 �Ȃ�� jmp

	inc	cx			;���[�v�̊֌W��
	mov	bx,offset paras_p	;dx = argv / �p�����[�^�ւ̃|�C���^
.loop:
	dec	cx
	jz	.end_paras

	mov	si,[bx]			;si = argv[N] / �p�����[�^�ւ̃|�C���^
	add	bx,byte 2		;argv++ / �|�C���^���Z
	mov	ax,[si]			;�擪2�������[�h
	cmp	al,'-'			;'-' �Ŏn�܂�p�����^?
	jne	.end_paras		;�������jmp (���[�h�t�@�C�����ƌ��Ȃ�)

	mov	al,[si+2]		;ah's next char

	cmp	ah,'v'
	je	.para_v
	cmp	ah,'q'
	je	.para_q
	cmp	ah,'p'
	je	.para_p
	cmp	ah,'c'
	je	.para_c
	cmp	ah,'m'
	je	.para_m
	cmp	ah,'2'
	je	.para_2
%if TOWNS
	cmp	ah,'n'
	je	.para_n
%endif
	cmp	ah,'i'
	je	.para_i
	jmp	short .loop

	;///////////////////////////////
	; -v
	;///////////////////////////////
.para_v:
	cmp	al,'v'			; -vv?
	je	.v0
	mov	al,01
.v0:
	mov	b [verbose],al
	jmp	short .loop

	;///////////////////////////////
	; -q
	;///////////////////////////////
.para_q:
	mov	b [title_disp],0	;no title output
	jmp	short .loop

	;///////////////////////////////
	; -p?
	;///////////////////////////////
.para_p:
	and	al,01			;-p? / al = ?
	mov	[see_PATH],al		;search PATH flag
	jmp	short .loop

	;///////////////////////////////
	; -c?
	;///////////////////////////////
.para_c:
	test	al,al			;-c? / al = ?
	jnz	.c0			
	mov	al,01			;�w��Ȃ��Ȃ� -c1 �Ɖ���
.c0:	and	al,03			;bit 1,0 ���o��
	mov	[reset_CRTC],al
	jmp	short .loop

	;///////////////////////////////
	; set PharLap version to 2.2 (compatible EXE386)
	;///////////////////////////////
.para_2:
	mov	d [pharlap_version], 20643232h	; ' d22'
	jmp	short .loop

%if TOWNS
	;///////////////////////////////
	; -n, do not load CoCo/NSD
	;///////////////////////////////
.para_n:
	and	al,01h			;al = -n?
	mov	b [nsdd_load],al
	jmp	short .loop
%endif

	;///////////////////////////////
	; -i?
	;///////////////////////////////
.para_i:
	and	al,01			;-i? / al = ?
	mov	b [check_MACHINE],al
	jmp	short .loop

.end_paras:

;------------------------------------------------------------------------------
;���^�C�g���\��
;------------------------------------------------------------------------------
	mov	al,[title_disp]	;�^�C�g���\������?
	test	al,al		;�l check
	jz	.no_title	;0 �Ȃ�\������
	PRINT86	P_title		;�^�C�g���\��
.no_title:


;------------------------------------------------------------------------------
;���ȈՋ@�픻��
;------------------------------------------------------------------------------
%if (MACHINE_CODE != 0)		;�@��ėp�łȂ�

machine_check:
	mov	al,[check_MACHINE]	;�@�픻�ʃt���O
	test	al,al			;�l�m�F
	jz	.no_check		;0 �Ȃ�`�F�b�N���Ȃ�

%if TOWNS
	call	check_TOWNS		;TOWNS������
%elif PC_98
	call	check_PC98		;PC-98x1������
%elif PC_AT
	call	check_AT		;PC/AT�݊��@������
%endif

	jnc	.check_safe		;Cy=0 �Ȃ�Y���@��
	PRINT86		err_10		;�@�픻�ʎ��s
	Program_end	F386ERR		;�I��

.no_check:
.check_safe:
%endif

;------------------------------------------------------------------------------
;��VCPI �̑��݊m�F
;------------------------------------------------------------------------------
	;
	;----- EMS�̑��݊m�F -----
	;
%if Check_EMS
check_ems_driver:
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

	align	2
	;/// �G���[���� /////////
.not_found:
	PRINT86		err_01e		; 'EMS not found'
	Program_end	F386ERR		; �I��

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

	PRINT86		err_01		; 'VCPI not find'
	Program_end	F386ERR		; �I��
.skip:
	
;------------------------------------------------------------------------------
;���y�[�W�f�B���N�g���̃������m��
;------------------------------------------------------------------------------
	;///////////////////////////////////////////////////
	;�y�[�W�f�B���N�g���p�A�h���X�Z�o
	;///////////////////////////////////////////////////
	xor	ebx,ebx			;���16�r�b�g�N���A
	xor	edx,edx			;

	mov	ax,offset end_adr	;�v���O�����Ō���I�t�Z�b�g
	mov	bx,ds			;�f�[�^�Z�O�����g
	mov	dx,bx			;����
	add	ax,0fh			;�[���؏グ
	shr	ax,4			;byte�P�� -> para�P��
	add	bx,ax			;�I�����j�A para �A�h���X
	add	bx,0ffh			;4KB �ȉ��؏グ
	and	bx,0ff00h		;para �P�ʂ̃��j�A�A�h���X

	mov	bp,bx			;���j�A�A�h���X(/16)���R�s�[
	sub	bx,dx			;�Z�O�����g�l������
	shl	bx,4			;�I�t�Z�b�g�ɕϊ�
	mov	[page_dir],bx		;�y�[�W�f�B���N�g���擪�I�t�Z�b�g
	mov	ax,bx
	add	ax,1000h		;+4KB
	mov	[page_table0],ax	;�y�[�W�e�[�u��0�̐擪�I�t�Z�b�g

	; 8KB zero fill
	xor	eax,eax			;eax = 0
	mov	edi,ebx			;�������ݐ�  es:edi
	mov	ecx,2000h / 4		;�������݉�
	rep	stosd			;�y�[�W�e�[�u���������� 0 �N���A

	shl	edx,4			;���̃v���O�����̐擪���j�A�A�h���X
	mov	[top_adr],edx		;�L��

	mov	cx,bp			;page dir ���j�A�A�h���X(/16)
	shr	cx,(12-4)		;para�P�� -> page�P��
	mov	ax,0de06h		;VCPI 06h/�����A�h���X�擾
	int	67h			;�����A�h���X�擾 -> edx
	mov	[to_PM_CR3],edx		;CR3 �̒l�Ƃ��ċL�^

	;///////////////////////////////////////////////////
	;�y�[�W�f�B���N�g��������
	;///////////////////////////////////////////////////
	add	cx,1			;4KB �悪�ŏ��̃y�[�Wtable
	mov	ax,0de06h		;VCPI 06h/�����A�h���X�擾
	int	67h			;VCPI call
	mov	dl,07h			;�L����table�G���g����
	mov	[bx],edx		;�ŏ��̃y�[�W�e�[�u�����G���g������

;------------------------------------------------------------------------------
;���������Ǘ����̐ݒ�
;------------------------------------------------------------------------------
	;�������Ǘ����̐ݒ�F�f�Ѓ������ƁA�󂫍ŏ�ʃ��������Z�o����

	;�y�[�W�f�B���N�g����y�[�W�e�[�u���� 4KB �� align ����Ȃ���΂Ȃ炸�A
	;�v���O�����I�[�Ƃ̊Ԃɋ󂫃������̈悪�������Ă��܂��B >frag_mem

	mov	ax,[page_dir]		;page �f�B���N�g���I�t�Z�b�g
	mov	dx,ax			;dx �ɂ��Z�[�u
	sub	ax,offset end_adr	;ax = �g���ĂȂ��������̈�
	add	dx,2000h		;�󂫍ŏ�ʃ�����
	mov	[frag_mem_size ],ax	;�l���Z�[�u
	mov	[top_mem_offset],dx	;

	;*** ����� malloc �Ȃǂ��g�p�\�ɂȂ� ***

;------------------------------------------------------------------------------
;�����������ʂ̎擾 / VCPI
;------------------------------------------------------------------------------
get_vcip_memory_size:
	mov	ax,0de02h			;VCPI function 02h
	int	67h				;�ŏ�ʃy�[�W�̕����A�h���X
	shr	edx,12				;�A�h���X -> page
	inc	edx				;edx = ���������y�[�W��

	mov	eax, Memory_page_max		;�ő僁�����ʐ���
	cmp	edx, eax
	jb	short .step
	mov	edx, eax
.step:
	mov	[all_mem_pages],edx		;�l�L�^

;------------------------------------------------------------------------------
;��alloc DOS memory - for call buffer / work address
;------------------------------------------------------------------------------
alloc_call_buffer:
	xor	bh, bh
	mov	bl, [callbuf_sizeKB]	;CALL Buffer size (KB)
	test	bl, bl
	jnz	short .step
	mov	bl, 1			;�Œ�1KB�͊m��
	mov	[callbuf_sizeKB], bl
.step:
	xor	eax, eax
	shl	bx, 10-4 		; KB to para
	mov	ah, 48h
	int	21h
	jnc	.alloc		;�����Ȃ� jmp

	PRINT86		err_11		; CALL buffer�m�ێ��s
	Program_end	F386ERR		; �I��

.alloc:
	mov	[callbuf_seg16], ax	; real segment
	shl	eax, 4
	mov	[callbuf_adr32],eax	; liner address

	;//////////////////////////////////////////////////
	;�ėp���[�N�̈�
	;//////////////////////////////////////////////////
	mov	ax,WORK_SIZE		;�ėp���[�N�T�C�Y
	call	heap_malloc		;��ʃ��������蓖��
	mov	[work_adr],di		;�L�^

;------------------------------------------------------------------------------
;���@��ŗL�̏������ݒ�i�������ݒ�ό�j
;------------------------------------------------------------------------------

%if TOWNS
	call	init_TOWNS
%elif PC_98
	;call	init_PC98
%elif PC_AT
	;call	init_AT
%endif

;------------------------------------------------------------------------------
;���X�^�b�N�������̊m�ۂƐݒ�
;------------------------------------------------------------------------------
	mov	ax,V86_stack_size	;V86�� stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	sp,di			;�X�^�b�N�ؑւ�

	mov	[v86_cs],cs		;cs �ޔ�
	mov	[v86_sp],di		;sp �ޔ�

	mov	ax,PM_stack_size	;�v���e�N�g���[�h�� stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[PM_stack_adr],di	;�L�^

	mov	ax,VCPI_stack_size	;CPU Prot->V86 �؂芷������p stack
	call	stack_malloc		;���ʃ��������蓖��
	mov	[VCPI_stack_adr],di	;�L�^

;------------------------------------------------------------------------------
;�����̑��̃������̊m�ۂƐݒ�
;------------------------------------------------------------------------------
	xor	edi,edi			;��� 16 bit �N���A

	;//////////////////////////////////////////////////
	;���A�����[�h�x�N�^�ۑ��̈�
	mov	ax,Real_Vectors *4	;INT �̐�
	call	heap_malloc		;��ʃ��������蓖��
	mov	[RVects_save_adr],di	;�L�^

	;���A�����[�h�x�N�^�̕ۑ�
	push	ds
	xor	esi,esi			;�]����
	mov	 ds,si			;ds = 0
	mov	ecx,Real_Vectors	;�]���� = �x�N�^��
	rep	movsd			;�ꊇ�]��  ds:esi -> es:edi
	pop	ds

	;//////////////////////////////////////////////////
	;GDT/LDT/TSS
	mov	ax,GDTsize		;Global Descriptor Table's size
	call	heap_calloc		;��ʃ��������蓖��
	mov	[GDT_adr],di		;�L�^

	mov	ax,LDTsize		;Local Descriptor Table's size
	call	heap_calloc		;��ʃ��������蓖��
	mov	[LDT_adr],di		;�L�^

	mov	ax,IDTsize		;Interrupt Descriptor Table's size
	call	heap_calloc		;��ʃ��������蓖��
	mov	[IDT_adr],di		;�L�^

	mov	ax,TSSsize		;Task State Segment's size
	call	heap_calloc		;��ʃ��������蓖��
	mov	[TSS_adr],di		;�L�^

	;//////////////////////////////////////////////////
	;V86����Protect�A�g���[�`���̃Z�b�g�A�b�v

	call	setup_cv86		;in f386cv86.asm

	;//////////////////////////////////////////////////
	;�v���e�N�g���[�h����V86 ����o�b�t�@
	mov	ax,INT_BUF_size * ISTK_nest_max	;�o�b�t�@�T�C�Y
	call	heap_malloc			;��ʃ��������蓖��
	mov	[int_buf_adr],di		;�L�^
	mov	[int_buf_adr_org],di

	mov	ax,INT_RWBUF_size		;�t�@�C�����o�͐�p
	mov	[int_rwbuf_size],ax
	call	heap_malloc			;��ʃ��������蓖��
	mov	[int_rwbuf_adr],di		;�L�^
	mov	[int_rwbuf_adr_org],di


;------------------------------------------------------------------------------
;��XMS �̊m�F�ƌĂяo���A�h���X�̎擾
;------------------------------------------------------------------------------
XMS_setup:
	mov	ax,4300h	;AH=43h : XMS
	int	2fh		;2fh call
	cmp	al,80h		;XMS install?
	je	.found		;��������� jmp

	PRINT86		err_04		;�uXMS ��������Ȃ��v
	Program_end	F386ERR		; �I��

	align	2
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
get_EMB_XMS20:
%if USE_XMS20
	test	al,al		;�璷�ȕ\��?
	jz	.step		;0 �Ȃ� jmp
	PRINT86	msg_06		;�uXMS2.0 �����v

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


	align	4
	;///////////////////////
	;�������m�ێ��s
	;///////////////////////
%endif
get_EMB_failed:
	PRINT86		err_05
	Program_end	F386ERR		; �I��


;------------------------------------------------------------------------------
;���g���������̊m�� (use XMS3.0)
;------------------------------------------------------------------------------
get_EMB_XMS30:
	test	al,al		;�璷�ȕ\��?
	jz	.step		;0 �Ȃ� jmp
	PRINT86	msg_07		;�uXMS3.0 �����v

.step:
	mov	ah,88h		;EMB �󂫃������₢���킹
	XMS_function		;XMS call
	test	bl,bl		;bl �̒l�m�F
	jnz	get_EMB_failed	;non 0 �Ȃ� jmp

	mov	[max_EMB_free]  ,eax	;�ő咷�A�󂫃������T�C�Y (KB)
	mov	[total_EMB_free],edx	;���󂫃������T�C�Y (KB)
	mov	[EMB_top_adr ]  ,ecx	;�Ǘ�����ŏ�ʃA�h���X

	mov	edx,eax			;edx = �m�ۂ��郁�����T�C�Y
	mov	ah,89h			;�ő�A���󂫃�������S�Ċm��
	XMS_function			;�m��
	test	ax,ax			;ax = 0?
	jz	get_EMB_failed		;0 �Ȃ�m�ێ��s
	mov	[EMB_handle],dx		;EMB�n���h�����Z�[�u
	jmp	short lock_EMB		;EMB�̃��b�N


;------------------------------------------------------------------------------
;���m�ۂ����g���������̃��b�N �� �g���������̏������ݒ�
;------------------------------------------------------------------------------
	align	4
lock_failed:
	call	free_EMB	;EMB �̊J��
	PRINT86	err_07		;�u���b�N���s�v
	Program_END F386ERR	;�v���O�����I��

	align	4
lock_EMB:
	mov	ah,0ch		;EMB �̃��b�N
	XMS_function		;
	test	ax,ax		;ax = 0?
	jz	lock_failed	;0 �Ȃ烍�b�N���s

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
	jz	short .jp
	dec	ecx
.jp:	shr	ecx,2			;KB�P�� �� page �P��
	cmp	ecx,0x40000		;256Kpage max
	jb	.jp2
	mov	ecx,0x40000		;1GB max
.jp2:	mov	[EMB_pages],ecx		;�g�p�\�ȃy�[�W���Ƃ��ċL�^

;------------------------------------------------------------------------------
;alloc DOS memory - for page table
;------------------------------------------------------------------------------
alloc_page_table:
	mov	ebx, [EMB_physi_adr]	; free Phisical address
	shr	ebx, 22			; to need page tables
	jz	.skip

	mov	bp, bx			; need tables save to bp

	xor	eax, eax
	inc	ebx			; for fragment
	shl	ebx, 12 - 4 		; PAGE to para
	mov	ah, 48h
	int	21h
	jnc	.alloc			; jump if success

	call		free_EMB
	PRINT86		err_12
	Program_end	F386ERR

.alloc:
	shl	eax, 4
	mov	[page_table_in_dos_memory_adr] ,eax	; liner address
	shl	ebx, 4
	mov	[page_table_in_dos_memory_size],ebx	; size

	; prepare loop
	add	eax, 0fffh		; for align 4KB
	shr	eax, 12
	mov	cx, ax
	mov	bx, [page_dir]
.loop:
	mov	ax,0de06h		; get Phisical address
	int	67h			; VCPI call
	mov	dl,07h			; address to table entry
	add	bx, 4
	mov	[bx], edx		; entry to page directory

	; clear page table
	push	cx
	shl	cx, 12-4		; PAGE to para
	mov	es, cx
	xor	di, di
	mov	cx, 1000h / 4		; 4KB/4
	xor	eax, eax
	rep	stosd
	pop	cx

	inc	cx			; for loop
	dec	bp
	jnz	.loop

	push	ds
	pop	es
.skip:

;------------------------------------------------------------------------------
;��DOS memory for exp
;------------------------------------------------------------------------------
alloc_real_mem_for_exp:
	xor	eax, eax
	xor	bh, bh
	mov	bl, b [real_mem_pages]	;CALL Buffer size (page)
	mov	cl, bl
	inc	bl			;4KB���E�����p��1�����m��
	shl	bx, 8			;Page to para(Byte/16)

	mov	ah,48h
	int	21h
	jnc	.success

	cmp	ax,08h
	jnz	.fail

	;�����̓������s��, bx=�ő僁����
	and	bx, 0ff00h		;4KB�P�ʂ�
	mov	cx, bx
	shr	cx, 8			;para to page
	dec	cl

	;�ēx���蓖�Ď��s
	mov	ah,48h
	int	21h
	jc	.fail

.success:
	shl	eax, 4			; para to offset
	add	eax, 0x00000fff
	and	eax, 0xfffff000
	mov	[DOS_mem_adr], eax	; 4KB page top
	mov	[DOS_mem_pages], cl	
.fail:

;------------------------------------------------------------------------------
;��VCPI�p�Z���N�^�̏�����
;------------------------------------------------------------------------------
	;///////////////////////////////////////////////////
	;VCPI �Ăяo��  01h
	;///////////////////////////////////////////////////
	xor	edi,edi			;edi �̏��16bit �N���A
	mov	si,[GDT_adr]		;GDT �ւ̃I�t�Z�b�g���[�h
	add	si,VCPI_sel		;VCPI �̃Z�O�����g�z�u�A�h���X��
	mov	di,[page_table0]	;�y�[�W�e�[�u��0 �擪�I�t�Z�b�g�ۑ�
	mov	ax,0de01h		;
	int	67h			;VCPI Function

	test	ah,ah			;�߂�l check
	jz	save_VCPI_statas	;���Ȃ���� jmp

	call		free_EMB	; �g���������̊J��
	PRINT86		err_02		; 'VCPI not find'
	Program_end	F386ERR		; �I��

	align	4
save_VCPI_statas:
	mov	[VCPI_entry],ebx	;VCPI �T�[�r�X�G���g��
	sub	 di,[page_table0]	;���[�U�poffset - �擪offset
	shl	edi,(12-2)		;edi ���[�U�[�p���j�A�A�h���X�J�n�ʒu
	mov	[free_LINER_ADR],edi	;����`�̃��j�A�A�h���X�Œ�ʔԒn


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
%if SAVE_8259A && enable_INTR
	in	al,I8259A_IMR_S		;8259A �X���[�u
	mov	ah,al			;ah �ֈړ�
	in	al,I8259A_IMR_M		;8259A �}�X�^
	mov	[intr_mask_org],ax	;�L��
%endif

	;///////////////////////////////////////////////////
	;int21h �A�h���X�L��
	;///////////////////////////////////////////////////
	xor	ax,ax			;ax = 0
	mov	gs,ax			;es = 0
	mov	eax,[gs:21h*4]		;DOS function CS:IP
	mov	[DOS_int21h_adr],eax	;�L�^


;------------------------------------------------------------------------------
;���b�o�t���[�h�ؑւ�����
;------------------------------------------------------------------------------
	mov	eax,[top_adr]		;�v���O�����擪���j�A�A�h���X
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

	;mov	w [to_PM_LDTR],LDT_sel		;LDTR�̒l�i�����l��`�ρj
	;mov	w [to_PM_TR]  ,TSS_sel		;TR�̒l�i�����l��`�ρj
	mov	d [to_PM_EIP] ,offset start32	;EIP �̒l
	;mov	w [to_PM_CS]  ,F386_cs		;CS �̒l�i�����l��`�ρj


;------------------------------------------------------------------------------
;��GDT �����ݒ胋�[�`��
;------------------------------------------------------------------------------
;GDT ���� LDT / IDT / TSS / DOS������ �Z���N�^�̐ݒ�
;
	mov	 di,[GDT_adr]	;GDT �̃I�t�Z�b�g
	mov	ebx,[top_adr]	;���̃v���O�����̐擪���j�A�A�h���X(bit 31-0)

	;/// Free386�p CS/DS �ݒ� ///////////////////////////////////

	mov	dl,[top_adr +2]	;bit 16-23
	mov	ax,0ffffh	;���~�b�g�l

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

	mov	[di + LDT_sel + 2],ecx		;�x�[�X�A�h���X�ݒ�
	mov	[di + LDT_RW  + 2],ecx		;
	mov	[di + LDT_sel],ax		;���~�b�g�l�ݒ�
	mov	[di + LDT_RW ],ax		;

	mov	w [di + LDT_sel + 5],0082h	;�����ݒ� (LDT)
	mov	w [di + LDT_RW  + 5],4092h	;�����ݒ� (Read/Write)

	;/// GDT/IDT �A�N�Z�X�p�Z���N�^�̐ݒ� ///////////////////////

	mov	ecx,[GDT_adr]			;GDT �I�t�Z�b�g
	mov	edx,[IDT_adr]			;IDT �I�t�Z�b�g
	add	ecx,ebx				;�擪�A�h���X���Z
	add	edx,ebx				;  �V
	mov	[di + GDT_RW + 2],ecx		;�x�[�X�A�h���X�ݒ�
	mov	[di + IDT_RW + 2],edx		;  �V
	mov	w [di + GDT_RW],GDTsize-1	;���~�b�g�l�ݒ�
	mov	w [di + IDT_RW],IDTsize-1	;
	mov	w [di + GDT_RW +5],4092h	;�����ݒ� (Read/Write)
	mov	w [di + IDT_RW +5],4092h	;�����ݒ� (Read/Write)

	;/// TSS �Z���N�^�̐ݒ� /////////////////////////////////////

	mov	ecx,[TSS_adr]			;TSS �̃I�t�Z�b�g
	add	ecx,ebx				;�擪�A�h���X���Z
	mov	ax,TSSsize -1			;TSS �̑傫�� -1

	mov	[di + TSS_sel + 2],ecx		;�x�[�X�A�h���X�ݒ�
	mov	[di + TSS_RW  + 2],ecx		;
	mov	[di + TSS_sel],ax		;���~�b�g�l�ݒ�
	mov	[di + TSS_RW ],ax		;

	mov	w [di + TSS_sel + 5],0089h	;�����ݒ� (���p�\/Avail TSS)
	mov	w [di + TSS_RW  + 5],4092h	;�����ݒ� (Read/Write)

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


	;////////////////////////////////////////////////////////////
	;/// ���ݒ� IDT ///////////////////////////////////////////

	;;mov	w [offset IDT + int_ret_PM *8],offset ret_PM_handler
	;;mov	w [offset IDT + int_ret_PM2*8],offset ret_PM_handler2

	;/// �ݒ�I�� ///////////////////////////////////////////////
	;////////////////////////////////////////////////////////////


;------------------------------------------------------------------------------
;�����荞�݃e�[�u�������ݒ胋�[�`��
;------------------------------------------------------------------------------
;	dw	offset %1	;offset  bit 0-15
;	dw	F386_cs		;selctor
;	dw	0ee00h		;���� (386���荞�݃Q�[�g) / �������x��3
;	dw	00000h		;offset  bit 16-31
setup_IDT:
	mov	 ax,F386_cs	;�Z���N�^
	xor	edx,edx		;��ʃr�b�g�N���A
	shl	eax,16		;��ʂ�
	mov	edx,0ee00h	;386���荞�݃Q�[�g / �������x��3
	mov	di,[IDT_adr]	;���荞�݃e�[�u���擪

	;/// CPU �������荞�ݐݒ� /////////////////////////
	mov	ax,offset PM_int_00h	;���荞�� #00
	mov	cx,20h			;00h �` 1fh
	mov	bp,8			;���Z�l
	call	write_IDT		;IDT �֏�������

	;/// DOS���荞�ݐݒ� //////////////////////////////
	mov	cx,10h			;20h �` 2fh
	mov	si,offset DOS_int_list	;DOS ���荞�݃��X�g

	align	4
.loop1:	mov	ax,[si]			;jmp ��ǂݏo��
	mov	[di  ],eax		;+00h
	mov	[di+4],edx		;+04h
	add	si,byte 4		;���̊��荞�݃��X�g����
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


	;/// �n�[�h�E�F�A���荞�� /////////////////////////
%if enable_INTR
	mov	ax,offset intr_M0	;���荞�݃}�X�^�� #00
	mov	di,[IDT_adr]		;���荞�݃e�[�u���擪
	mov	cx,8			;���[�v��
	add	di,INTR_MASTER *8	;�}�X�^�����荞�ݔԍ� *8
	call	write_IDT		;IDT �֏�������

	mov	ax,offset intr_S0	;���荞�݃X���[�u�� #00
	mov	di,[IDT_adr]		;���荞�݃e�[�u���擪
	mov	cx,8			;���[�v��
	add	di,INTR_SLAVE *8	;�X���[�u�����荞�ݔԍ� *8
	call	write_IDT		;IDT �֏�������
%endif

;------------------------------------------------------------------------------
;���b�o�t���[�h�ؑւ�
;------------------------------------------------------------------------------
	mov	ax,0de0ch		;VCPI function  0Ch
	mov	esi,[top_adr]		;�v���O�����擪���j�A�A�h���X
	add	esi,offset to_PM_data	;�ؑւ��p�\���̃A�h���X
	mov	[to_PM_data_ladr],esi	;��L���j�A�A�h���X�L�^

	int	67h			;�v���e�N�g���[�h�� start32 ��

	call		free_EMB	; �g���������̊J��
	PRINT86		err_03		; CPU �ؑւ����s
	Program_end	F386ERR		; �I��


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
	add	ax,bp			;���̊��荞�݃A�h���X��
	add	di,bp			;�Z���N�^�I�t�Z�b�g�X�V
	loop	write_IDT
	ret


;------------------------------------------------------------------------------
;���������A���P�[�V����
;------------------------------------------------------------------------------
;	in	ax = size (byte)
;	out	di = offset
;
;���d�������A���P�[�V�����̉���͍l���Ă��Ȃ��B
;16 �̔{���ȊO�͎w�肵�Ȃ����Ƃ��]�܂����B
;
	align	4
heap_malloc:		;��ʂ���̃��������蓖��
%if USE_frag_mem
	cmp	ax,[frag_mem_size]	;�f�Љ��������̃T�C�Y�Ɣ�r
	ja	.not_frag_mem		;if �����傫�� jmp

	mov	di,[frag_mem_offset]	;�f�Љ��������̊��蓖��
	sub	[frag_mem_size  ],ax	;���蓖�Ă��������ʂ�����
	add	[frag_mem_offset],ax	;�󂫃������������|�C���^���X�V
	ret
%endif
	align	4
.not_frag_mem:		;��ʋ󂫃������̒P���Ȋ��蓖��
	mov	di,[top_mem_offset]	;��ʋ󂫃��������蓖��
	add	[top_mem_offset],ax	;�T�C�Y�����Z
	jmp	short check_heap_mem

	align	4
stack_malloc:		;���ʂ���̃��������蓖��
	mov	di,[down_mem_offset]	;�ŉ��ʋ󂫃�����
	sub	[down_mem_offset],ax	;�V���Ȓl���L�^
	; jmp	short check_heap_mem
check_heap_mem:
	push	ax
	push	bx
	mov	ax,[top_mem_offset]
	mov	bx,[down_mem_offset]
	dec	ax
	dec	bx
	cmp	ax,bx
	pop	bx
	pop	ax
	ja	.error
	ret
.error:
	mov	ah, 25h			;error code
	jmp	program_err_end


	;//////////////////////////////////////////////////
	;0 �����������������̎擾
	;//////////////////////////////////////////////////
	align	4
heap_calloc:
	push	w (mem_clear)		;�߂胉�x��
	jmp	heap_malloc

	align	4
stack_calloc:
	std
	push	w (mem_clear)		;�߂胉�x��
	jmp	stack_malloc

	align	4
mem_clear:		;�������� 0 �N���A
	push	eax
	push	ecx
	push	edi

	movzx	ecx,ax			;ecx �������T�C�Y
	movzx	edi,di			;edi �������ݐ�
	xor	eax,eax			;eax = 0
	shr	ecx,2			;4 �Ŋ���
	rep	stosd			;�������h��Ԃ� ->es:[edi]

	pop	edi
	pop	ecx
	pop	eax
	cld
	ret


;------------------------------------------------------------------------------
;���m�ۂ����g���������̊J��
;------------------------------------------------------------------------------
	align	4
free_EMB:
	mov	dx,[EMB_handle]	;dx = EMB�n���h��
	test	dx,dx		;�n���h���̒l�m�F
	jz	.ret		;0 �Ȃ�� ret

	mov	ah,0dh		;EMB �̃��b�N����
	XMS_function

	mov	ah,0ah		;EMB �̊J��
	XMS_function
	test	ax,ax		;ax = 0 ?
	jnz	.ret		;non 0 �Ȃ� jmp
	PRINT86	err_06		;�u�������J�����s�v

.ret	ret


;##############################################################################
;==============================================================================
;���v���O�����̏I�� (16 bit)
;==============================================================================
	align	4
END_program16:
	;////////////////////////////////////////////////////////////
	;/// ���荞�݃}�X�N���� /////////////////////////////////////
%if SAVE_8259A && enable_INTR
	mov	ax,[intr_mask_org]	;�������
	out	I8259A_IMR_M, al	;�}�X�^��
	mov	al,ah			;
	out	I8259A_IMR_S, al	;�X���[�u��
%endif

%if TOWNS
	call	end_TOWNS16
%endif

	sti
	call	free_EMB		;�m�ۂ����������̊J��

	mov	ax,[err_level]		;AH = Free386 ERR / AL = Program ERR
	test	ah,ah			;check
	jnz	program_err_end		;non 0 �Ȃ�G���[�I��

	mov	ah,4ch
	int	21h			;����I��


;------------------------------------------------------------------------------
;�������G���[����
;------------------------------------------------------------------------------
	align	4
program_err_end:
	sub	ah,20h			;�����G���[�R�[�h 00h�`1fh �͌���
	movzx	si,ah			;si �ɃG���[�ԍ���
	add	si,si			;si*2
	mov	dx,[end_msg_table + si]	;�G���[���b�Z�[�W�̃A�h���X

	mov	ah,09h			;���b�Z�[�W�\��
	int	21h			;DOS call

	Program_end	F386ERR		; �I��


;******************************************************************************
;���R�[�h(32 bit)
;******************************************************************************
BITS	32

%include	"f386prot.asm"		;�v���e�N�g���[�h�E���C���v���O����

;------------------------------------------------------------------------------
;���v���O�����̏I��(32bit)
;------------------------------------------------------------------------------
	align	4
END_program:
	cli
	mov	bx,F386_ds		;ds ����
	mov	ds,ebx			;
	mov	es,ebx			;VCPI �Ő؂芷�����A
	mov	fs,ebx			;�Z�O�����g���W�X�^�͕s��l
	mov	gs,ebx			;
	lss	esp,[PM_stack_adr]	;�X�^�b�N�|�C���^���[�h

	mov	[err_level],al		;�G���[���x���L�^

	;///////////////////////////////
	;�e�@��ŗL�̏I������
	;///////////////////////////////
%if TOWNS || PC_98 || PC_AT
	mov	al,[init_machine]
	test	al,al
	jz	.skip_machin_recovery

%if TOWNS
	call	end_TOWNS		;TOWNS �̏I������
%elif PC_98
	call	end_PC98		;PC-98x1 �̏I������
%elif PC_AT
	call	end_AT			;PC/AT�݊��@�̏I������
%endif

.skip_machin_recovery:
%endif
	;///////////////////////////////
	;���A�����[�h�x�N�^�̕���
	;///////////////////////////////
%if Rec_Real_Vec
Rec_vector:
	push	d (DOSMEM_sel)			;DOS �������A�N�Z�X���W�X�^
	pop	fs				;load
	mov	ecx,Real_Vectors		;�x�N�^��
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
	mov	eax,[v86_cs]		;V86�� cs,ds
	mov	ebx,[v86_sp]		;V86�� sp

	cli				;���荞�݋֎~
	push	eax			;V86 gs
	push	eax			;V86 fs
	push	eax			;V86 ds
	push	eax			;V86 es
	push	eax			;V86 ss
	push	ebx			;V86 esp
	pushfd				;eflags
	push	eax			 ;V86 cs
	push	d (offset END_program16) ;V86 EIP / �I�����x��

	mov	ax,0de0ch		;VCPI function 0ch / to V86 mode
	call    far [VCPI_entry]	;VCPI call


;******************************************************************************
;���@��ˑ��R�[�h
;******************************************************************************

%if TOWNS
	%include "towns.asm"
%endif

%if PC_98
	%include "pc98.asm"
%endif

%if PC_AT
	%include "at.asm"
%endif

;******************************************************************************
;���f�[�^
;******************************************************************************

%include	"f386data.asm"		;�f�[�^���C���N���[�h

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	align	16	;�K�{�I�I
end_adr:

;******************************************************************************
;******************************************************************************
