;******************************************************************************
;�@Free386�@���f�[�^����
;******************************************************************************
;
segment	data align=4 class=CODE use16
group	comgroup text data
;
;==============================================================================
; Setting
;==============================================================================
env_PATH386	db	'PATH386',0	; �t�@�C���������ɎQ�Ƃ�����ϐ�
env_PATH	db	'PATH',0	;

default_API	db	Free386_API,0	; API file name

;==============================================================================
; General variable
;==============================================================================
pharlap_version	db	'12aJ'		;Ver 1.2aj

err_level	db	0		;�v���O�����G���[���x��
f386err		db	0		;F386 �����G���[���x��
init_machine	db	0		;initalized machin local


	align	4
;==============================================================================
; Buffer information
;==============================================================================

work_adr	dd	0		; �ėp���[�N�̃A�h���X (200h)

	; file and string buffer
call_buf_used	dd	0		; used flag
call_buf_size	dd	0		; byte
call_buf_adr16	dw	0		; offset
call_buf_seg16	dw	0		; segment
call_buf_adr32	dd	0		; address

;--------------------------------------------------------------------
;----- �������֘A��� -----------------------------------------------
;
	;�y�[�W�f�B���N�g����y�[�W�e�[�u���� 4KB ��align ����Ȃ���΂Ȃ炸�A
	;�v���O�����I�[�Ƃ̊ԂɎg���Ȃ��������̈悪�������Ă��܂�
	align	4


VCPI_stack_adr	dd	0		;V86 ���[�h�؂芷�����̂�
		dw	F386_ds		;�@�g�p����X�^�b�N
PM_stack_adr	dd	0		;�v���e�N�g���[�h���̃X�^�b�N
		dw	F386_ds		;
v86_cs		dw	0,0		;V86���[�h�� cs
v86_sp		dw	0,0		;V86���[�h�� sp

		align	4
GDT_adr		dd	0		;GDT �̃I�t�Z�b�g
LDT_adr		dd	0		;LDT �̃I�t�Z�b�g
IDT_adr		dd	0		;IDT �̃I�t�Z�b�g
TSS_adr		dd	0		;TSS �̃I�t�Z�b�g

;--------------------------------------------------------------------
;----- XMS �֘A�f�[�^�̈� -------------------------------------------
;
XMS_Ver		dd	0		;XMS �̃��W���[ Version
XMS_entry	dd	0		;XMS �Ăяo���A�h���X

EMB_handle	dd	0		;EMB �n���h��
EMB_physi_adr	dd	0		;EMB �擪�����h���X (4KB�P�ʂŒl������)
EMB_pages	dd	0		;EMB �T�C�Y(byte) / 4 KB (�[��������)

EMB_top_adr	dd	0		;�Ǘ����� EMB �̍ŏ�ʃA�h���X / XMS3.0
max_EMB_free	dd	0		;�ő�� EMB �󂫃������T�C�Y    (Kbyte)
total_EMB_free	dd	0		;�g�[�^���� EMB �󂫃������T�C�Y(Kbyte)

DOS_mem_adr	dd	0		;�m�ۂ���DOS�������̃A�h���X
DOS_mem_pages	dd	0		;�m�ۂ����y�[�W��

;--------------------------------------------------------------------
;----- �v���e�N�g�������Ǘ���� -------------------------------------
;
free_LINER_ADR	dd	0		;����`(���g�p)���j�A�A�h���X (�Œ��)
free_RAM_padr	dd	0		;�󂫐擪����RAM�y�[�W�A�h���X
free_RAM_pages	dd	0		;���p�\�ȕ���RAM�y�[�W�� (4KB�P��)

	;�ȉ� VCPI ����Ɗ֘A�̔Z������
all_mem_pages	dd	0		;�����������A���������y�[�W��
vcpi_mem_pages	dd	0		;VCPI �̊Ǘ����郁�����y�[�W��

page_dir	dw	0,0	;F386ds	;�y�[�W�f�B���N�g�� �I�t�Z�b�g
page_table0	dw	0,0	;F386ds	;�y�[�W�e�[�u��0 �I�t�Z�b�g

page_table_in_dos_memory_adr	dd	0	;���A���������Ɋm�ۂ����ǉ��̃y�[�W�e�[�u���A�h���X
page_table_in_dos_memory_size	dd	0	;���A���������Ɋm�ۂ����ǉ��̃y�[�W�e�[�u���T�C�Y

;--------------------------------------------------------------------
;----- �f�[�^�̈� ---------------------------------------------------
;
	align	4
top_adr		dd	0		;�v���O�����擪���j�A�A�h���X
intr_mask_org	dw	0		;8259A �I���W�i���l�o�b�N�A�b�v

DTA_off		dd	80h		;DTA �����l
DTA_seg		dw	PSP_sel1,0	;

;----- �f�[�^�̈�Q -------------------------------------------------
;
	align	16
LGDT_data	dw	GDTsize-1	;GDT ���~�b�g
		dd	0		;    ���j�A�A�h���X
LIDT_data	dw	IDTsize-1	;IDT ���~�b�g
		dd	0		;    ���j�A�A�h���X

DOS_int21h_adr	dd	0		;DOS int 21h   CS:IP
VCPI_entry	dd	0		;VCPI �T�[�r�X�G���g��
		dw	VCPI_sel	;VCPI �Z���N�^


	;/// ���A�����[�h�x�N�^�ݒ�p�f�[�^�̈� ////////
	align	4
RVects_flag_tbl	resb	IntVectors/8	;���������t���O �e�[�u��
RVects_save_adr	dd	0		;���A�����[�h�x�N�^�ۑ��̃A�h���X

;
;----- VCPI�֘A�f�[�^�̈� -------------------------------------------
;

	align	4
to_PM_data_ladr	dd	0	;���L�\���̃��j�A�A�h���X

to_PM_data:			;V86 �� PM�\����
to_PM_CR3	dd	0
to_PM_GDTR	dd	0
to_PM_IDTR	dd	0
to_PM_LDTR	dw	LDT_sel
to_PM_TR	dw	TSS_sel
to_PM_EIP	dd	0
to_PM_CS	dw	F386_cs

	align	4
VCPI_cr3	dd	0		;

;==============================================================================
; Messages
;==============================================================================
P_title	db	'Free386(386|DOS-Extender) for '
	db	MACHINE_STRING
	db	' ',VER_STRING
	db	' (C)nabe@abk',13,10,'$'

EXE_err	db	'Do not execute free386.exe (Please run free386.com)',13,10,'$'

end_mes	db	'Finish',13,10,'$'

msg_01	db	'VCPI Found�FVCPI Version $'
msg_02	db	'[VCPI] Physical Memory size  = ###### KB',13,10
	db	'[XMS]  Allocate Ext  Memory  = ###### KB (####_####h)',13,10
	db	'[DOS]  Allocate Real Memory  = ###### KB (####_####h) + 4KB(fragment)',13,10
	db	'[DOS]  Additional Page Table = ###### KB (####_####h)',13,10
	db	'$'
msg_05	db	'Load file name = $'
msg_06	db	'Found XMS 2.0',13,10,'$'
msg_07	db	'Found XMS 3.0',13,10,'$'
msg_10	db	'Usage: free386 <target.exp>',13,10
	db	13,10
	db	'	-v	Verbose (memory information and other)',13,10
	db	'	-vv	More verbose (internal memory information)',13,10
	db	"	-q	Do not output Free386's title and this help",13,10
	db	'	-p	Search .exp file from PATH (with default from PATH386)',13,10
	db	'	-m	Use memory to the maximum with real memory',13,10
	db	'	-2	Set PharLap version is 2.2 (ebx=20643232h)',13,10
%if MACHINE_CODE
	db	'	-c?     Reset CRTC/VRAM. 0:No, 1:RESET, 2:CRTC, 3:Auto(default)',13,10
	db	'	-i	Do not check machine',13,10
%endif
%if TOWNS
	db	'	-n	Do not load NSD driver',13,10
%endif
	db	'$'

internal_mem_msg:
	db	"*** Free386 internal memroy information ***",13,10
	db	'	program code	: 0100 - #### / cs=ds=####',13,10
	db	'	frag memory	: #### - #### / ##### byte free',13,10
	db	'	page table 	: #### - #### /  8192 byte',13,10
	db	'	heap memory	: #### - ffff / ##### byte',13,10
	db	'	free heap memory: #### - #### / ##### byte',13,10
	db	'	real vecs backup: #### - ####',13,10
	db	'	GDT		: #### - ####',13,10
	db	'	LDT		: #### - ####',13,10
	db	'	IDT		: #### - ####',13,10
	db	'	TSS		: #### - ####',13,10
	db	'	call buffer     : #### - #### / ##### byte',13,10
	db	'	general work mem: #### - ####',13,10
	db	'	16bit int hook  : #### - ####',13,10
	db	'	VCPI  call stack: #### -',13,10
	db	'	32bit mode stack: #### -',13,10
	db	'	16bit mode stack: #### - ffff',13,10
	db	'$'

err_01e	db	'EMS Device Header is not found',13,10,'$'
err_01	db	'VCPI is not found',13,10,'$'
err_02	db	'VCPI error',13,10,'$'
err_03	db	'CPU mode not change',13,10,'$'
err_04	db	'XMS: driver not found',13,10,'$'
err_05	db	'XMS: XMS memory allocation failed',13,10,'$'
err_06	db	'XMS: XMS memory release failed',13,10,'$'
err_07	db	'XMS: XMS memory lock failed',13,10,'$'
err_10	db	'Incompatible binary! This binary is for ',MACHINE_STRING,'.',13,10
	db	'If you do not want to check the machine, ',
	db	'please execute with the -i option.',13,10,'$'
err_11	db	'CALL buufer (Real memory) allocate failed',13,10,'$'
err_12	db	'Page table memory (Real memory) allocate failed',13,10,'$'

err_xxh	db	'F386: Unknown error',13,10,'$'
err_21h	db	'F386: Protect memory is insufficient',13,10,'$'
err_22h	db	'F386: Can not read executable file',13,10,'$'
err_23h	db	'F386: Memory is insufficient to load executable file',13,10,'$'
err_24h	db	'F386: Unknown EXP header (Compatible: P3-flat model, MZ-header)',13,10,'$'
err_25h	db	'F386: Real memory heap overflow (*_malloc/*_calloc)',13,10,'$'
err_26h	db	'F386: Not enough stack for switch CPU mode',13,10,'$'
err_27h	db	'F386: Failure to free stack memory for switch CPU mode',13,10,'$'
err_28h	db	'F386: File read error(int 21h fail)',13,10,'$'

	align	4
err_msg_table:
	dw	offset err_xxh	;not use
	dw	offset err_21h
	dw	offset err_22h
	dw	offset err_23h
	dw	offset err_24h
	dw	offset err_25h
	dw	offset err_26h
	dw	offset err_27h
	dw	offset err_28h


