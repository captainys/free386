;******************************************************************************
;�@Segment and memory routine	for Free386
;******************************************************************************
;[TAB=8]
;
;
%include	"macro.inc"
%include	"f386def.inc"
%include	"free386.inc"
%include	"memory.inc"

;******************************************************************************
seg32	text32 class=CODE align=4 use32
;******************************************************************************
; IN	eax = selector
;	[edi]	dword	base offset
;	[edi+4]	dword	limit (20bit, byte)
;	[edi+8]	byte	DPL (0-3)
;	[edi+9]	byte	selector type (0-15)
;
; supprot only 32bit meomory selector.
;
proc4 make_selector
	push	ebx
	call	do_make_selector
	pop	ebx
	ret

proc4 make_selector_4k
	push	ebx
	call	do_make_selector
	or	b [ebx+6], 80h	;G bit=1, limit unit is 4K
	pop	ebx
	ret

proc4 do_make_selector
	push	eax
	push	ecx
	push	edx

	mov	ebx, [GDT_adr]
	test	al, 4		;check bit 2
	jz	.is_GDT	 	; 0 is GDT
	mov	ebx, [LDT_adr]
.is_GDT:
	and	eax, 0fff8h
	add	ebx, eax	;ebx = target selector pointer

	mov	eax, [edi+4]	;eax = limit
	mov	[ebx], ax	;save bit0-15
	and	eax,0f0000h	;eax = limit bit16-19

	mov	ecx, [edi]	;ecx = base
	mov	[ebx+2], cx	;base bit0-15
	mov	al, [edi+2]	;eax bit0-7 <= base bit16-23
	and	ecx, 0ff000000h	;base bit24�`31
	or	eax, ecx	;eax bit24-31 <= base bit24-31

	mov	cx, [edi+8]	;cl=DPL, ch=type
	and	ch, 0fh		;type mask
	and	cl, 3		;DPL
	shl	cl, 5		;bit5-6 = DPL
	or	cl, ch		;cl bit0-3=type, bit5-6=DPL
	mov	ah, cl		;eax bit8-11=type, bit13-14=DPL

	or	ah, 90h		;eax bit12=DT=1(code or data)
				;eax bit15=Present=1
	bts	eax, 22		;eax bit22=Operation size=1(32bit seg)
	mov	[ebx+4], eax	;save

	pop	edx
	pop	ecx
	pop	eax
	ret

;------------------------------------------------------------------------------
;���������������w�胊�j�A�A�h���X�ɔz�u����
;------------------------------------------------------------------------------
;	esi = ������惊�j�A�A�h���X (4KB Unit)
;	edx = ������镨���A�h���X   (4KB Unit)
;	ecx = �������y�[�W��
;
;	Ret	Cy = 0 ����
;		Cy = 1 �y�[�W�e�[�u��������Ȃ�
;
proc4 set_physical_mem
	test	ecx,ecx		;������y�[�W���� 0
	jz	.ret		;�������� ret

	pusha
	push	es
	mov	eax,ALLMEM_sel		;�S�������A�N�Z�X�Z���N�^
	mov	  es,ax			;es �Ƀ��[�h
	or	 dl,7			;�y�[�W�� bit0-2 = ����, R/W, Level 0-3
	mov	ebp,1000h		;const
	jmp	short .next_page_table	;���[�v�X�^�[�g

	align	4
.loop_start:
	;edi = page table top
	and	edi,0xfffff000		;table dir entry
	mov	ebx,esi			;linear address
	shr	ebx,10
	and	ebx,0xffc
	or	edi,ebx
	mov	eax,0fffh		;const
	jmp	.lp0

	align	4
	;/// main loop ////////////////////////////
	; ecx = �������y�[�W��
	; edx = ������镨��������
	; edi = ���j�A�A�h���X�ɑΉ������y�[�W�G���g���̃A�h���X
	; esi = ���j�A�A�h���X
.loop:
	test	edi,eax	;=0fffh		;if �I�t�Z�b�g�� 0 �ɖ߂�����
	jz	short .next_page_table	;  �V���ȃy�[�W�e�[�u���쐬 (jmp)

.lp0:	mov	[es:edi],edx		;�y�[�W���G���g��
	add	edi,byte 4		;�e�[�u�����I�t�Z�b�g
	add	edx,ebp ;=1000h		;�����A�h���X       + 4K
	add	esi,ebp ;=1000h		;�������A�h���X + 4K

	loop	.loop			;������y�[�W�����A���[�v
	;///////////////////////////// end loop ///
	pop	es
	popa
.ret:	clc
	ret

	align	4
.next_page_table:
	; must save reg : ecx,edx,esi
	mov	ebx,esi			;ebx = ������惊�j�A�A�h���X
	shr	ebx,20			;bit 31-20
	and	 bl, 0fch		;bit 21,20 �̃N���A
	add	ebx,[page_dir_ladr]	;page dir
	mov	edi,[es:ebx]		;���j�A�A�h���X���Q��
	test	edi,edi			;if entry != 0 �i�e�[�u�������݂���j
	jnz	short .loop_start	;  jmp

	;/// �V���ȃy�[�W�e�[�u���̍쐬 ///
	mov	eax,[free_RAM_pages]	;�󂫕����������擪
	test	eax,eax			;�l�m�F
	jz	.no_free_memory		;0 �Ȃ� jmp
	dec	eax			;�c��y�[�W�������Z
	mov	[free_RAM_pages],eax	;�l���L�^

	;/// new entry 'page table' to 'page dir' ///
	mov	eax,[free_RAM_padr]	;�󂫕����������擪
	mov	edi,eax			;edi��save
	or	 al,7			;page entry
	mov	[es:ebx],eax		;entry
	add	eax,ebp	;=1000h		;4KB step
	xor	 al,al			;����bit clear
	mov	[free_RAM_padr],eax	;�󂫕���������

	;/// zero clear ��������e�[�u����0�N���A���� ///
	push	ecx
	push	edi
	;
	mov	ecx,1000h /4		;�h��Ԃ���
	xor	eax,eax			;0 �N���A
	rep	stosd			;�h��Ԃ�
	;
	pop	edi
	pop	ecx
	jmp	.loop_start


.no_free_memory:	;�y�[�W�e�[�u���쐬�̂��߂̃��������s��
	pop	es
	popa
	stc			;�L�����[�Z�b�g
	ret


;------------------------------------------------------------------------------
;��DOS RAM �A���P�[�V����
;------------------------------------------------------------------------------
;	ecx = �ő�\����y�[�W��
;
;	Ret	Cy = 0 ����
;			eax = ���蓖�Ă��y�[�W��
;			esi = ���蓖�Đ擪���j�A�A�h���X
;		Cy = 1 �y�[�W�e�[�u��������Ȃ� (esi�j��)
;
proc4 alloc_DOS_mem
	push	ebx
	push	ecx
	push	edx

	mov	esi,[free_linear_adr]	;�������A�h���X
	mov	eax,[DOS_mem_pages]
	test	eax,eax
	jz	.no_mapping		;DOS�������Ȃ�
	test	ecx,ecx
	jz	.no_mapping		;�v��=0

	cmp	eax,ecx			;�󂫃y�[�W�� - �v���y�[�W��
	jae	.enough
	mov	ecx,eax			;����Ȃ���΁A���邾���\��t��
.enough:
	mov	edx,[DOS_mem_ladr]	;DOS������
	call	set_physical_mem	;���������蓖��
	jc	.not_enough_page_table	;�������s���G���[

	sub	[DOS_mem_pages]  ,ecx	;�󂫃������y�[�W�����Z
	mov	eax, ecx
	shl	ecx, 12			;byte �P�ʂ�
	add	[DOS_mem_ladr]   ,ecx	;��DOS������
	add	[free_linear_adr],ecx	;�󂫃������A�h���X�X�V

	clc
.exit:
	pop	edx
	pop	ecx
	pop	ebx
	ret

.no_mapping:
	xor	eax, eax
	clc
	jmp	short .exit

.not_enough_page_table:
	stc
	jmp	short .exit


;------------------------------------------------------------------------------
;��RAM �A���P�[�V����
;------------------------------------------------------------------------------
;	ecx = �\�����y�[�W��
;
;	Ret	Cy = 0 ����
;			esi = ���蓖�Đ擪���j�A�A�h���X
;		Cy = 1 �y�[�W�e�[�u���܂��̓�����������Ȃ� (esi�j��)
;
proc4 alloc_RAM
	push	eax
	push	ebx
	push	ecx
	push	edx

	mov	esi, [free_linear_adr]	;�������A�h���X
	test	ecx, ecx
	jz	.no_alloc

	call	get_maxalloc_with_adr	;eax = �ő劄�蓖�ĉ\�������y�[�W��
					;ebx = �y�[�W�e�[�u���p�ɕK�v�ȃy�[�W��

	cmp	eax,ecx			;�󂫃y�[�W�� - �v���y�[�W��
	jb	.no_free_memory		;��������΃������s��

	mov	edx,[free_RAM_padr]	;�󂫕���������
	shl	ebx,12			;�y�[�W�e�[�u���p�ɕK�v�ȃ�����(byte)
	add	edx,ebx			;������镨�������������炷
	call	set_physical_mem	;���������蓖��
	jc	.no_free_memory		;�������s���G���[

	sub	[free_RAM_pages],ecx	;�󂫃������y�[�W�����Z
	shl	ecx,12			;byte �P�ʂ�
	add	[free_RAM_padr] ,ecx	;�󂫕��������������炷

	add	esi, ecx		;�󂫃������A�h���X�X�V
	mov	[free_linear_adr], esi	;�󂫃A�h���X�X�V

.no_alloc:
	clc		;�L�����[�N���A
.exit:
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

	;�y�[�W�e�[�u���쐬�̂��߂̃��������s��
.no_free_memory:
	stc
	jmp	short .exit

;------------------------------------------------------------------------------
;��RAM �A���P�[�V����
;------------------------------------------------------------------------------
;	esi = �\��t����惊�j�A�A�h���X
;	ecx = �\�����y�[�W��
;
;	Ret	Cy = 0 ����
;			esi = ���蓖�Čナ�j�A�A�h���X = esi + ecx*4KB
;		Cy = 1 �y�[�W�e�[�u���܂��̓�����������Ȃ� (esi�j��)
;
proc4 alloc_RAM_with_ladr
	push	eax
	push	ebx
	push	ecx
	push	edx

	test	ecx,ecx
	jz	.no_alloc

	call	get_maxalloc_with_adr	;eax = �ő劄�蓖�ĉ\�������y�[�W��
					;ebx = �y�[�W�e�[�u���p�ɕK�v�ȃy�[�W��
	cmp	eax,ecx			;�󂫃y�[�W�� - �v���y�[�W��
	jb	.no_free_memory		;��������΃������s��

	mov	edx,[free_RAM_padr]	;�󂫕���������
	shl	ebx,12			;�y�[�W�e�[�u���p�ɕK�v�ȃ�����(byte)
	add	edx,ebx			;������镨�������������炷
	call	set_physical_mem	;���������蓖��
	jc	.no_free_memory		;�������s���G���[

	sub	[free_RAM_pages],ecx	;�󂫃������y�[�W�����Z
	shl	ecx,12			;byte �P�ʂ�
	add	[free_RAM_padr] ,ecx	;�󂫕��������������炷

.no_alloc:
	clc		;�L�����[�N���A
.exit:
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

	;�y�[�W�e�[�u���쐬�̂��߂̃��������s��
.no_free_memory:
	stc
	jmp	short .exit


;------------------------------------------------------------------------------
;���e�[�u����ǂݏo���A������������z�u���Z���N�^���쐬����
;------------------------------------------------------------------------------
;����	ds:ebx �������}�b�s���O�e�[�u��
;
proc4 map_memory
	mov	eax,[ebx]		;�쐬���郁�����Z���N�^
	test	eax,eax			;�l check
	jz	.exit			;0 �Ȃ�I��

	mov	edx,[ebx + 04h]		;edx = ������镨���A�h���X
	mov	ecx,[ebx + 08h]		;ecx = �������y�[�W�� -1
	mov	esi,edx			;esi = ������惊�j�A�A�h���X
	inc	ecx			;+1 ����
	call	set_physical_mem	;�����������̔z�u

	lea	edi,[ebx + 4]		;�Z���N�^�쐬�\����
	call	make_selector_4k	;eax=�쐬����Z���N�^  edi=�\����

	add	ebx,byte 10h		;�A�h���X�X�V
	jmp	short map_memory	;���[�v

.exit:	ret


;------------------------------------------------------------------------------
;���Z���N�^�̃G�C���A�X���쐬����
;------------------------------------------------------------------------------
;����	ds:esi	�G�C���A�X�e�[�u��
;
proc4 make_aliases
	;esi = �G�C���A�X�e�[�u��
	mov	ebx,[esi  ]		;�R�s�[��  �Z���N�^�l
	mov	ecx,[esi+4]		;�R�s�[����Z���N�^�l
	mov	eax,[esi+8]		;seg type
	test	ebx,ebx			;�l�m�F
	jz	.ret
	call	make_alias		;�ʖ��쐬

	add	esi,byte 0ch		;�A�h���X�X�V
	jmp	short make_aliases	;���[�v
.ret:	ret


proc4 make_alias
	;-----------------------------------------------------
	;���G�C���A�X�쐬  ebx -> ecx, ah=type, al=level
	;-----------------------------------------------------
	push	eax
	mov	eax,ebx			;eax = �Z���N�^�l
	call	sel2adr			;Ret ebx:�A�h���X
	mov	edx,ebx			;edx : �R�s�[���A�h���X
	mov	eax,ecx			;eax
	call	sel2adr			;ebx : �R�s�[��A�h���X

	;edx -> ebx
	mov	eax,[edx  ]		;�R�s�[��
	mov	[ebx  ],eax		;�R�s�[��

	pop	eax
	;ah=type, al=level

	mov	ecx,[edx+4]		;�R�s�[��
	and	ch,90h			;bit 7,4 �̂ݎ��o��
	shl	al,5			;level bit 6-5
	or	ch,al			;level �̒l��������
	or	ch,ah			;type �̒l��������
	mov	[ebx+4],ecx		;
	ret


;==============================================================================
;���T�u���[�`��
;==============================================================================
;------------------------------------------------------------------------------
;�E�ő劄�蓖�ĉ\�������ʎ擾
;------------------------------------------------------------------------------
;Ret	eax = �ő劄�蓖�ĉ\�������y�[�W��
;
proc4 get_maxalloc
	push	ecx

	mov	eax, [free_RAM_pages]	;�c�蕨���y�[�W�����[�h
	mov	ecx, eax		;
	add	ecx, 000003ffh		;�J��グ���������� 1024 �ŏ��Z
	shr	ecx, 10			;ecx = �y�[�W�e�[�u���ɕK�v�ȃy�[�W��
	sub	eax,ecx			;�c��y�[�W�� - �y�[�W�e�[�u���p������

	pop	ecx
	ret

;------------------------------------------------------------------------------
;�E�ő劄�蓖�ĉ\�������ʎ擾
;------------------------------------------------------------------------------
;IN	esi = �x�[�X�A�h���X
;Ret	eax = �ő劄�蓖�ĉ\�������y�[�W��
;	ebx = �y�[�W�e�[�u���p�ɕK�v�ȃy�[�W��
;
proc4 get_maxalloc_with_adr
	push	ecx
	push	es

	push	DOSMEM_sel
	pop	es

	mov	eax, esi		;�������A�h���X
	shr	eax, 20			;bit 31-20
	and	 al, 0fch		;bit 21,20 �̃N���A
	add	eax, es:[page_dir_ladr]	;����t���擪�̃y�[�W�e�[�u�����m�F

	xor	ebx, ebx
	test	eax, eax
	jz	.step			;���݂��Ȃ��Ƃ��� jump

	mov	eax, esi		;����t���惊�j�A�A�h���X
	shr	eax, 12
	and	eax, 03ffh		;�g�p�ρA�y�[�W�G���g����
	mov	ecx, 0400h ;=1024	;1�e�[�u���̍ő�y�[�V�G���g����
	sub	ecx, eax		;ecx = �y�[�W�e�[�u�����ρA�y�[�W�G���g����

.step:
	mov	eax, [free_RAM_pages]	;�c�蕨���y�[�W�����[�h
	mov	ebx, eax		;
	sub	ebx, ecx		;�y�[�W�e�[�u���̗v��Ȃ��G���g����������
	add	ebx, 000003ffh		;�J��グ���������� 1024 �ŏ��Z
	shr	ebx, 10			;ecx = �y�[�W�e�[�u���p�ɕK�v�ȃy�[�W��
	sub	eax, ebx		;�c��y�[�W�� - �y�[�W�e�[�u���p������

	pop	es
	pop	ecx
	ret


;------------------------------------------------------------------------------
;�E�w��Z���N�^�̍Ō�����j�A�A�h���X�擾
;------------------------------------------------------------------------------
;IN	eax = �Z���N�^
;Ret	eax = �Z���N�^�Ō���̃��j�A�A�h���X
;
proc4 get_selector_last
	push	ebx
	push	ecx
	push	edx

	mov	edx,eax		;�Z���N�^�l�ۑ�
	call	sel2adr		;�f�B�X�N���v�^�A�h���X�ɕϊ� ->ebx

	mov	ecx,[ebx+4]  	;bit 31-24
	mov	eax,[ebx+2]	;bit 23-0
	and	ecx,0ff000000h	;�}�X�N
	and	eax, 00ffffffh	;
	or	eax,ecx		;�l����

	lsl	ecx,edx		;ecx = ���~�b�g�l
	inc	ecx		;ecx = �T�C�Y
	add	eax,ecx		;eax = �Z���N�^�Ō�����j�A�A�h���X

	pop	edx
	pop	ecx
	pop	ebx
	ret


;------------------------------------------------------------------------------
;�E�Z���N�^�l���f�B�X�N���v�^�̃A�h���X�ϊ�
;------------------------------------------------------------------------------
;	IN	eax = �Z���N�^�l
;	Ret	ebx = �A�h���X�B�Z���N�^�s������ ebx=0
;		eax �ȊO�͒l�ۑ�
;
proc4 sel2adr
	mov	ebx,[cs:GDT_adr]	;GDT �ւ̃|�C���^
	test	eax,4		 	;�Z���N�^�l�� bit 2 ?
	jz	short .GDT	 	; if 0 jmp

	mov	ebx,[cs:LDT_adr] 	;LDT �ւ̃|�C���^
	cmp	eax,LDTsize
	ja	short .fail
	jmp	.success
.GDT:
	cmp	eax,GDTsize
	ja	short .fail
.success:
	and	al,0f8h			;bit 2-0 �N���A
	add	ebx,eax			;���Z
	ret
.fail:
	xor	ebx,ebx
	ret

;------------------------------------------------------------------------------
;�ELDT���̋󂫃Z���N�^����
;------------------------------------------------------------------------------
;	IN	(ds = F386_ds �ł��邱��)
;	Ret	eax = �󂫃Z���N�^ (Cy=0)
;		    = 0 ���s       (Cy=1)
;
proc4 search_free_LDTsel
	push	ebx
	push	ecx

	mov	eax,LDT_sel	;LDT �̃Z���N�^�l
	lsl	ecx,eax		;ecx = LDT �T�C�Y
	mov	eax,[LDT_adr] 	;LDT �̃A�h���X
	add	ecx,[LDT_adr] 	;LDT �I���A�h���X
	add	eax,byte 4	;+4

.loop:	add	eax,byte 8	;�A�h���X�X�V
	cmp	eax,ecx		;�T�C�Y�Ɣ�r
	ja	.no_desc	;�T�C�Y�I�[�o = �f�B�X�N���v�^�s��
	test	b [eax+1],80h	;P �r�b�g(���݃r�b�g)
	jz	.found		;0 �Ȃ�󂫃f�B�X�N���v�^
	jmp	short .loop

.found:
	sub	eax,[LDT_adr] 	;LDT�A�h���X�擪������
	pop	ecx		;eax = �󂫃Z���N�^
	pop	ebx
	clc
	ret

.no_desc:
	xor	eax,eax		;eax =0
	pop	ecx
	pop	ebx
	stc
	ret

;------------------------------------------------------------------------------
;�E�S�Ẵf�[�^�Z���N�^�̃����[�h
;------------------------------------------------------------------------------
proc4 selector_reload
	push	ds
	push	es
	push	fs
	push	gs
	push	ss

	pop	ss
	pop	gs
	pop	fs
	pop	es
	pop	ds
	ret

;------------------------------------------------------------------------------
; regist managed LDT selector
;------------------------------------------------------------------------------
; IN	ax = selector
;
proc4 regist_managed_LDTsel
	push	eax
	push	ecx

	mov	ecx, [managed_LDTsels]
	cmp	ecx, LDTsize/8
	jae	.exit				; ignore

	mov	[managed_LDTsel_list + ecx*2], ax
	inc	ecx
	mov	[managed_LDTsels], ecx

.exit:
	pop	ecx
	pop	eax
	ret

;------------------------------------------------------------------------------
; remove managed  LDT selector
;------------------------------------------------------------------------------
; IN	ax = selector
;
; RET	cy = 0	removed
;	cy = 1	not found
;
proc4 remove_managed_LDTsel
	push	eax
	push	ebx
	push	ecx
	push	edx

	test	ax, ax
	jz	.not_found

	mov	edx, [managed_LDTsels]
	mov	ebx, managed_LDTsel_list
	xor	ecx ,ecx
.loop:
	cmp	[ebx + ecx*2], ax
	je	.found
	inc	ecx
	cmp	ecx, edx
	jb	.loop

.not_found:
	stc
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

.found:
	mov	ax, [ebx + edx*2 - 2]	; last
	mov	[ebx + ecx*2], ax	; copy
	dec	edx
	mov	[managed_LDTsels], edx

	clc
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	ret

;------------------------------------------------------------------------------
; Update free linear address
;------------------------------------------------------------------------------
; Find a free linear address to create a new selector.
;
proc4 update_free_linear_adr
	pusha

	mov	eax, ALLMEM_sel
	lsl	edi, eax		; edi = current upper linear address

	mov	ebx, [LDT_adr]
	mov	ecx, [managed_LDTsels]
	mov	esi, managed_LDTsel_list

.loop:
	test	ecx, ecx
	jz	.exit
	dec	ecx

	movzx	eax, w [esi]		; eax = selector
	add	esi, 2

	lsl	ebp, eax		; ebp = limit
	inc	ebp			; ebp = size

	and	al, 0f8h		; 0ch -> 08h(offset)

	mov	edx, [ebx + eax +2]	; base bit0-23
	mov	eax, [ebx + eax +4]	; base bit24-31
	and	edx, 000ffffffh
	and	eax, 0ff000000h
	or	eax, edx		; eax = base

	cmp	eax, 040000000h		; ignore system mapping?
	ja	.loop

	add	eax, ebp		; base + size
	cmp	eax, edi		; tmp - current
	jbe	.loop

	mov	edi, eax
	jmp	.loop

.exit:
	add	edi, LADR_ROOM_size + (LADR_UNIT -1)	;
	and	edi, 0ffffffffh     - (LADR_UNIT -1)	;
	mov	[free_linear_adr], edi			; update

	popa
	ret


;//////////////////////////////////////////////////////////////////////////////
; DATA
;//////////////////////////////////////////////////////////////////////////////
segdata	data class=DATA align=4

global	managed_LDTsels
global	managed_LDTsel_list

managed_LDTsels	dd	0
managed_LDTsel_list:			; managed LDT selector list
%rep	(LDTsize/8)
	dw	0
%endrep

