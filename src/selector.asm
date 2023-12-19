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

;------------------------------------------------------------------------------

global	make_selector
global	make_selector_4k
global	set_physical_mem
global	alloc_DOS_mem
global	alloc_RAM
global	alloc_RAM_with_ladr

global	map_memory		;������������z�u���Z���N�^���쐬�A�e�[�u���Q��
global	make_aliases		;�Z���N�^�̃G�C���A�X���쐬�i�e�[�u���Q�Ɓj
global	make_alias		;�Z���N�^�̃G�C���A�X���쐬
global	get_maxalloc		;�ő劄�蓖�ĉ\������(page)�擾
global	get_maxalloc_with_adr	;�ő劄�蓖�ĉ\������(page)�擾
global	get_selector_last	;�Z���N�^�Ō�����j�A�A�h���X(+1)�擾
global	sel2adr			;�Z���N�^�l to �A�h���X�ϊ�
global	search_free_LDTsel	;��LDT�Z���N�^�̌���
global	selector_reload		;�S�f�[�^�Z���N�^�̃����[�h

;******************************************************************************
segment	text32 class=CODE align=4 use32
;******************************************************************************
;------------------------------------------------------------------------------
;���������Z�O�����g���쐬���܂�
;------------------------------------------------------------------------------
;void make_selector(int selctor,struct mem_descriptor *memd)
;
;	selctor	�� �Z���N�^�l�i�쐬����Z���N�^�l�j
;
;struct	mem_descriptor
;{
;	int	base;	// ���j�A��ԃx�[�X�I�t�Z�b�g
;	int	limit;	// ���~�b�g�l�i�P�� byte�j
;	char	level;	// �������x��(0�`3)
;	char	type;	// �������Z�O�����g�^�C�v�iget_gdt�����ߒ�`�Q�Ɓj
;};		   	//  �K�� 00h�`0fh(0�`15) �̊Ԃ̒l�ł��邱�ƁB
;			//  ���ǉ��Fbit 4 �� 1 �Ȃ�� 286�`���̃Z�O�����g�쐬
;	eax = selector
;	edi = �\���� offset
;
;mtask �̂��̂Ƃ͔�݊��I�I
	align	4
make_selector:
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	es

	mov	bx,F386_ds	;F386 �������Z���N�^
	mov	es,ebx		;

	mov	ebx,eax		;�w��ڸ��l
	;mov	edi,[ebp+0ch]	;�ި������^�������\���̵̾��

	mov	ecx,[es:GDT_adr] ;GDT �ւ̃|�C���^
	test	ebx,4		 ;�ڸ��l���ޯ�2������
	jz	short .GDT	 ; 0 �Ȃ��GDT �Ȃ̂ł��̂܂� jmp
	mov	ecx,[es:LDT_adr] ;LDT �ւ̃|�C���^
.GDT:
	and	ebx,0fff8h	;DT��8byte�P�ʂȂ̂ŉ���3bit�؎̂�
	add	ebx,ecx

	mov	edx,[edi+4]	;���~�b�g�l���[�h
	mov	[es:ebx],dx	;���~�b�g�l���e�[�u���ɃZ�b�gbit0�`15
	and	edx,0f0000h	;���~�b�g�l�� bit16�`19 �����o��

	test	b [edi+9],10h	;286�`���H
	jnz	.s286		;bit �� �����Ă�� jmp
	or	edx,400000h	;���� 386�`��
.s286:
	mov	eax,[edi]	;base offset
	mov	[es:ebx+2],ax	;base bit0�`15
	mov	ecx,eax
	shr	ecx,8		;base�� bit16�`23
	and	eax,0ff000000h	;base�� bit24�`31
	mov	dl,ch		;bit 16�`23 set
	or	edx,eax		;bit 24�`31 set

	mov	ax,[edi+8]	;�������x��(dl)��seg-type(dh)�����[�h
	and	ah,0fh		;Type �t�B�[���h�̒l�}�X�N
	shl	al,5		;bit5�6 �̈ʒu�ɂ����Ă���
	or	al,ah		;�������x���ƃZ�O�����g�^�C�v��������
	or	al,90h		;���݂���(80h) ���݃r�b�g(P�r�b�g) �� 1��
	mov	dh,al		;�L�^�preg�Ɋi�[   �@�{DT1(mem �`��):10h
	mov	[es:ebx+4],edx	;�e�[�u���ɋL�^

	pop	es
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	ret


;------------------------------------------------------------------------------
;���������Z�O�����g���쐬���܂��i4KB �P�ʁj
;------------------------------------------------------------------------------
;void make_selector(int selctor,struct mem_descriptor *memd)
;
;	selctor	�� �Z���N�^�l�i�쐬����Z���N�^�l�j
;
;struct	mem_descriptor
;{
;	int	base;	// ���j�A��ԃx�[�X�I�t�Z�b�g
;	int	limit;	// ���~�b�g�l�i�P�� 4 Kbyte�j
;	char	level;	// �������x��(0�`3)
;	char	type;	// �������Z�O�����g�^�C�v�iget_gdt�����ߒ�`�Q�Ɓj
;};		   	//  �K�� 00h�`0fh(0�`15) �̊Ԃ̒l�ł��邱�ƁB
;			//  ���ǉ��Fbit 4 �� 1 �Ȃ�� 286�`���̃Z�O�����g�쐬
;	eax = selector
;	edi = �\���� offset
;
	align 4
make_selector_4k:
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	es

	mov	ebx,F386_ds	;F386 �������Z���N�^
	mov	 es,ebx		;

	mov	ebx,eax		;�w��ڸ��l
	;mov	edi,[ebp+0ch]	;�ި������^�������\���̵̾��

	mov	ecx,[es:GDT_adr] ;GDT �ւ̃|�C���^
	test	ebx,4		 ;�ڸ��l���ޯ�2������
	jz	short .GDT	 ; 0 �Ȃ��GDT �Ȃ̂ł��̂܂ܼެ���
	mov	ecx,[es:LDT_adr] ;LDT �ւ̃|�C���^
.GDT:
	and	ebx,0fff8h	;�ި�������� 8�޲ĒP�ʂȂ̂ŉ���3�ޯĐ؎̂�
	add	ebx,ecx

	mov	edx,[edi+4]	;�ЯĒl
	mov	[es:ebx],dx	;�ЯĒl��ð��قɾ�� bit0�`15
	and	edx,0f0000h	;�ЯĒl�� bit16�`19 �����o��
	or	edx,800000h	;���� 4KB�P�ʂ̃��~�b�g

	test	b [edi+9],10h	;286�`���H
	jnz	.s286		;bit �� �����Ă�� jmp
	or	edx,400000h	;���� 386�`��
.s286:
	mov	eax,[edi]	;�ް��̾��۰��
	mov	[es:ebx+2],ax	;�ް� bit0�`15
	mov	ecx,eax
	shr	ecx,8		;�ް��� bit16�`23
	and	eax,0ff000000h	;�ް��� bit24�`31
	mov	dl,ch		;bit 16�`23���
	or	edx,eax		;bit 24�`31���

	mov	ax,[edi+8]	;��������(dl) �� ����������(dh)��۰��
	and	ah,0fh		;Type �t�B�[���h�̒l�}�X�N
	shl	al,5		;bit5�6 �̈ʒu�ɂ����Ă���
	or	al,ah		;�������x���ƃZ�O�����g�^�C�v��������
	or	al,90h		;���݂���(80h) ���݃r�b�g(P�r�b�g) �� 1��
	mov	dh,al		;�L�^�pڼ޽��Ɋi�[   �@�{DT1(mem �`��):10h
	mov	[es:ebx+4],edx	;ð��قɋL�^

	pop	es
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	ret


	align	4
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
proc set_physical_mem
	test	ecx,ecx		;������y�[�W���� 0
	jz	NEAR .ret	;�������� ret

	pusha
	push	es
	mov	eax,ALLMEM_sel		;�S�������A�N�Z�X�Z���N�^
	mov	 es,eax			;es �Ƀ��[�h
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


	align	4
.no_free_memory:	;�y�[�W�e�[�u���쐬�̂��߂̃��������s��
	pop	es
	popa
	stc			;�L�����[�Z�b�g
	ret



;------------------------------------------------------------------------------
;��DOS RAM �A���P�[�V����
;------------------------------------------------------------------------------
;	ecx = �\�����y�[�W��
;
;	Ret	Cy = 0 ����
;			eax = ���蓖�Ă��y�[�W��
;			esi = ���蓖�Đ擪���j�A�A�h���X
;		Cy = 1 �y�[�W�e�[�u��������Ȃ� (esi�j��)
	
	align	4
alloc_DOS_mem:
	push	ebx
	push	ecx
	push	edx

	mov	eax,[DOS_mem_pages]
	test	eax,eax
	jz	.no_dos_mem		;DOS�������Ȃ�

	cmp	eax,ecx			;�󂫃y�[�W�� - �v���y�[�W��
	jae	.enough
	mov	ecx,eax			;����Ȃ���΁A���邾���\��t��
.enough:
	mov	edx,[DOS_mem_ladr]	;DOS������
	mov	esi,[free_liner_adr]	;�������A�h���X
	call	set_physical_mem	;���������蓖��
	jc	.no_free_memory		;�������s���G���[

	sub	[DOS_mem_pages] ,ecx	;�󂫃������y�[�W�����Z
	mov	eax, ecx
	shl	ecx, 12			;byte �P�ʂ�
	add	[DOS_mem_ladr]  ,ecx	;��DOS������
	add	[free_liner_adr],ecx	;�󂫃������A�h���X�X�V

	clc
.exit:
	pop	edx
	pop	ecx
	pop	ebx
	ret

.no_dos_mem:
	xor	eax, eax
	mov	esi, [free_liner_adr]
	clc
	jmp	short .exit

.no_free_memory:
	stc
	jmp	short .exit


	align	4
;------------------------------------------------------------------------------
;��RAM �A���P�[�V����
;------------------------------------------------------------------------------
;	ecx = �\�����y�[�W��
;
;	Ret	Cy = 0 ����
;			esi = ���蓖�Đ擪���j�A�A�h���X
;		Cy = 1 �y�[�W�e�[�u���܂��̓�����������Ȃ� (esi�j��)
;
	align	4
alloc_RAM:
	push	eax
	push	ebx
	push	ecx
	push	edx

	test	ecx,ecx
	jz	.no_alloc

	mov	esi, [free_liner_adr]	;�������A�h���X
	call	get_maxalloc_with_adr	;eax = �ő劄�蓖�ĉ\�������y�[�W��
					;ebx = �y�[�W�e�[�u���p�ɕK�v�ȃy�[�W��

	cmp	eax,ecx			;�󂫃y�[�W�� - �v���y�[�W��
	jb	.no_free_memory		;��������΃������s��

	mov	edx,[free_RAM_padr]	;�󂫕���������
	;mov	esi,[free_liner_adr]	;�������A�h���X
	shl	ebx,12			;�y�[�W�e�[�u���p�ɕK�v�ȃ�����(byte)
	add	edx,ebx			;������镨�������������炷
	call	set_physical_mem	;���������蓖��
	jc	.no_free_memory		;�������s���G���[

	sub	[free_RAM_pages],ecx	;�󂫃������y�[�W�����Z
	shl	ecx,12			;byte �P�ʂ�
	add	[free_RAM_padr] ,ecx	;�󂫕��������������炷

.no_alloc:
	add	esi, ecx				;�󂫃������A�h���X�X�V
	add	esi,LADR_ROOM_size + (LADR_UNIT -1)	;�[���؏グ
	and	esi,0ffc00000h				;���� 20�r�b�g�؎̂� (4MB �̔{����)
	add	[free_liner_adr] ,esi			;�󂫃A�h���X�X�V

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
	align	4
alloc_RAM_with_ladr:
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

	add	esi, ecx		;�V�����Ō���A�h���X
	mov	eax, [free_liner_adr]	;�󂫃A�h���X
	cmp	eax, esi
	ja	.step

	add	esi, LADR_ROOM_size + (LADR_UNIT -1)	;�[���؏グ
	and	esi, 0ffc00000h				;���� 20�r�b�g�؎̂� (4MB �̔{����)
	add	[free_liner_adr], esi			;�󂫃A�h���X�X�V

.step:
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
	align	4
map_memory:
	mov	eax,[ebx]		;�쐬���郁�����Z���N�^
	test	eax,eax			;�l check
	jz	.exit			;0 �Ȃ�I��

	mov	edx,[ebx + 04h]		;edx = ������镨���A�h���X
	mov	ecx,[ebx + 08h]		;ecx = �������y�[�W�� -1
	mov	esi,edx			;esi = ������惊�j�A�A�h���X
	inc	ecx			;+1 ����
	call	set_physical_mem	;�����������̔z�u

	lea	edi,[ebx + 4]		;�Z���N�^�쐬�\����
	call	make_selector_4k		;eax=�쐬����Z���N�^  edi=�\����

	add	ebx,byte 10h		;�A�h���X�X�V
	jmp	short map_memory	;���[�v

.exit:	ret


;------------------------------------------------------------------------------
;���Z���N�^�̃G�C���A�X���쐬����
;------------------------------------------------------------------------------
;����	ds:esi	�G�C���A�X�e�[�u��
;
	align	4
make_aliases:
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


	align	4
make_alias:
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
	align	4
get_maxalloc:
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
	align	4
get_maxalloc_with_adr:
	push	ecx
	push	es
	push	d DOSMEM_sel
	pop	es

	mov	ebx, esi			;�������A�h���X
	shr	ebx, 20				;bit 31-20
	and	 bl, 0fch			;bit 21,20 �̃N���A
	mov	eax, [es:page_dir_ladr+ebx]	;����t���擪�̃y�[�W�e�[�u�����m�F

	xor	ebx, ebx
	test	eax, eax
	jz	.step			;���݂��Ȃ��Ƃ��� jump

	;
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
	align	4
get_selector_last:
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
	align	4
sel2adr:
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
	align	4
search_free_LDTsel:
	push	ebx
	push	ecx

	mov	eax,LDT_sel	;LDT �̃Z���N�^�l
	lsl	ecx,eax		;ecx = LDT �T�C�Y
	mov	eax,[LDT_adr] 	;LDT �̃A�h���X
	add	ecx,[LDT_adr] 	;LDT �I���A�h���X
	add	eax,byte 4	;+4

	align	4
.loop:	add	eax,byte 8	;�A�h���X�X�V
	cmp	eax,ecx		;�T�C�Y�Ɣ�r
	ja	.no_desc	;�T�C�Y�I�[�o = �f�B�X�N���v�^�s��
	test	b [eax+1],80h	;P �r�b�g(���݃r�b�g)
	jz	.found		;0 �Ȃ�󂫃f�B�X�N���v�^
	jmp	short .loop

	align	4
.found:
	sub	eax,[LDT_adr] 	;LDT�A�h���X�擪������
	pop	ecx		;eax = �󂫃Z���N�^
	pop	ebx
	clc
	ret


	align	4
.no_desc:
	xor	eax,eax		;eax =0
	pop	ecx
	pop	ebx
	stc
	ret

;------------------------------------------------------------------------------
;�E�S�Ẵf�[�^�Z���N�^�̃����[�h
;------------------------------------------------------------------------------
	align	4
selector_reload:
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
;------------------------------------------------------------------------------
