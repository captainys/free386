;******************************************************************************
;�@Free386	���荞�ݏ������[�`�� / DOS-Extender �T�[�r�X
;******************************************************************************
;[TAB=8]
;
;==============================================================================
;��DOS-Extender�d�l DOS fuction (int 21)
;==============================================================================
;------------------------------------------------------------------------------
;�EVerison ���擾  AH=30h
;------------------------------------------------------------------------------
proc4 int_21h_30h
	clear_cy	; stack eflags clear

	;eax �̏��16bit �� 'DX' ������
	and	eax,0ffffh	;����16bit ���o��
	shl	eax,16		;��x��ʂւ��炷
	mov	 ax,4458h	;'DX' : Dos-Extender
	rol	eax,16		;��ʃr�b�g�Ɖ��ʃr�b�g����ꊷ����

	cmp	ebx,'RAHP'	;RUN386 funciton / 'PHAR'
	je	.run386
	cmp	ebx,'XDJF'	;FM TOWNS un-documented funciton / 'FJDX'
	je	.fujitsu
	cmp	ebx,'F386'	;Free386 funciton
	je	.free386

	;DOS Version �̎擾
	jmp	call_V86_int21_iret	;get DOS Version

.run386:
	V86_INT	21h

	;
	;Phar Lap �o�[�W�������
	;	�e�X�g�l�FEAX=44581406  EBX=4A613231  ECX=56435049  EDX=0
	mov	ebx, [cs:pharlap_version]	; '12Ja' or '22d '
	mov	ecx, 'IPCV'			;="VCPI", �� "DPMI" ������B
	cmp	b cs:[use_vcpi], 0
	jnz	.skip
	mov	ecx, 'SOD'			;="DOS\0", 00444F53h
.skip:	
	xor	edx, edx			;edx = 0
	iret

.fujitsu:
	mov	eax, 'XDJF'	; 'FJDX'
	mov	ebx, 'neK '	; ' Ken'
	mov	ecx, 40633300h	; '@c3', 0
	iret

.free386:
	mov	al,Major_ver	;Free386 ���W���o�[�W����
	mov	ah,Minor_ver	;Free386 �}�C�i�[�o�[�W����
	mov	ebx,F386_Date	;���t
	mov	ecx,0		;reserved
	mov	edx,' ABK'	;for Free386 check, 4b424120h
	iret

;------------------------------------------------------------------------------
;�E�v���O�����I��  AH=00h,4ch
;------------------------------------------------------------------------------
proc1 int_21h_00h
	xor	al,al		;���^�[���R�[�h = 0 / DOS�݊�
proc4 int_21h_4ch
	add	esp,12		;�X�^�b�N����
	jmp	exit_32		;DOS-Extender �I������

	;���{���͂����� DOS_Extender �I������������

;------------------------------------------------------------------------------
; create selector in LDT
;------------------------------------------------------------------------------
; in	ebx = alloc pages
; ret	 cy = 0	success
;		AX  = created selector
;	 cy = 1	fail.
;		AX  = 8 not enough selector or memory
;		ebx = free pages
;
proc4 int_21h_48h
	push	esi
	push	edi
	push	ecx
	push	ds

	push	F386_ds
	pop	ds

	call	search_free_LDTsel
	test	eax, eax		;eax = selector
	jz	.fail

	call	update_free_linear_adr	;update for create selector

	mov	ecx, ebx		;ecx = alloc pages
	call	alloc_RAM		;esi = linear address
	jc	.fail

	mov	ecx, ebx		;ecx = pages
	dec	ecx
	mov	edi,[work_adr]
	mov	[edi  ],esi		;base
	mov	[edi+4],ecx		;limit
	mov	w [edi+8],0200h		;R/W 386, DPL=0

	test	ebx, ebx
	jz	.zero_selector

	call	make_selector_4k	;eax=selector, [edi]=options
	jmp	.end

.zero_selector:		; pages = 0
	mov	[edi+4], ebx		;limit=0 (size = 1byte)
	call	make_selector		;eax=selector, [edi]=options

.end:
	call	regist_managed_LDTsel	;ax=selector

	pop	ds
	pop	ecx
	pop	edi
	pop	esi
	clear_cy
	iret


.fail:	call	get_maxalloc	;eax = �ő劄�蓖�ă�������(page)
	mov	ebx,eax		;ebx �ɐݒ�
	mov	eax,8		;�G���[�R�[�h

	pop	ds
	pop	ecx
	pop	edi
	pop	esi
	set_cy
	iret


;------------------------------------------------------------------------------
;�ELDT���̃Z���N�^���폜�������������  AH=49h
;------------------------------------------------------------------------------
; ����������������Ă��Ȃ�
proc4 int_21h_49h
	push	eax
	push	ebx
	push	ds

	push	F386_ds
	pop	ds

	mov	eax, es			;eax = �����Z���N�^
	call	remove_managed_LDTsel	;remove from list

	call	sel2adr			;�A�h���X�ϊ�
	and	b [ebx + 5],7fh		;P(����) bit �� 0 �N���A

	xor	eax,eax			;eax = 0
	mov	  es,ax			;es  = 0

	pop	ds
	pop	ebx
	pop	eax
	clear_cy
	iret


;------------------------------------------------------------------------------
;�E�Z���N�^�̑傫���ύX  AH=4ah
;------------------------------------------------------------------------------
;  in	 es = selector
;	ebx = new page size
;
;	incompatible: not free memory
;	��݊�: ����������@�\�Ȃ�
;
proc4 int_21h_4ah
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ds
	push	fs

	push	F386_ds
	pop	ds
	push	ALLMEM_sel
	pop	fs

	mov	edi,ebx			;edi = �ύX��T�C�Y(�l�ۑ�)
	mov	eax,es			;eax = �����Z���N�^
	verr	ax			;�ǂݍ��߂�Z���N�^�H
	jnz	.not_exist

	lsl	edx,eax			;���݂̃��~�b�g�l
	inc	edx			;ebx = size
	shr	edx,12			;size [page]
	sub	ebx,edx			;�ύX�� - �ύX�O
	jb	.decrease		;�k���Ȃ� jmp
	je	.ret			;�����Ȃ�ύX�Ȃ�
	mov	ecx,ebx			;ecx = �����y�[�W��

	mov	eax,es			;eax = �Z���N�^
	call	get_selector_last	;eax = �Z���N�^�̍ŏI���j�A�A�h���X
	mov	esi,eax			;esi = eax

	; ������ɂ��łɃy�[�W�����݂���΁A
	; ���̕����ɕ��������������ςƂ݂Ȃ��B
	mov	edx, [page_dir_ladr]

.check_page_table:
	mov	ebx, esi
	shr	ebx, 24 - 4
	and	ebx, 0ffch
	mov	ebx, [fs:edx + ebx]	; ebx = page table physical address
	test	bl, 1			; check Present bit
	jz	.check_end
	and	ebx, 0fffff000h

	mov	eax, esi
	shr	eax, 12 - 2
	and	eax, 0ffch
	mov	eax, [fs:ebx + eax]
	test	al, 1			; check Present bit
	jz	.check_end

	add	esi, 1000h		; Add 4KB
	dec	ecx			; pgaes--
	jnz	short .check_page_table
	jmp	short .alloc_end

.check_end:
					;in  esi = �\��t����x�[�X�A�h���X
	call	get_maxalloc_with_adr	;out eax = ���蓖�ĉ\��, ebx=�e�[�u���p�y�[�W��
	cmp	eax,ecx			;�� - �K�v��
	jb	.fail			;����Ȃ���Ύ��s

					;in  esi = �\��t����x�[�X�A�h���X
					;    ecx = �\��t����y�[�W��
	call	alloc_RAM_with_ladr	;���������蓖��
	jc	.fail			;out esi = esi + ecx*4K

.alloc_end:
	dec	edi			;edi = �ύX�ナ�~�b�g�l
	mov	eax,es			;
	mov	edx,edi			;edx = �ύX�ナ�~�b�g�l
	call	sel2adr			;
	shr	edx,16			;bit 31-16
	mov	al,[ebx + 6]		;
	mov	[ebx],di		;bit 15-0
	and	al,0f0h			;�Z���N�^���
	and	dl,00fh			;bit 19-16
	or	al,dl			;�l��������
	mov	[ebx + 6],al		;

	call	selector_reload		;�S�Z���N�^�����[�h

.ret:	pop	fs
	pop	ds
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clear_cy
	iret

.not_exist:
	mov	eax, 9
	jmp	short .fail2

.fail:	call	get_maxalloc_with_adr
	mov	ebx, eax
	mov	eax, 8
.fail2:	pop	fs
	pop	ds
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	add	esp,8
	set_cy
	iret

.decrease:
	; �������͊J�����Ȃ����AOpenWatcom�ɂ�
	; �Z���N�^�T�C�Y���Q�Ƃ��ă����������v�������Ă���̂ŁA
	; �Z���N�^�T�C�Y�͌��炵�Ă����B

	; �Z���N�^�T�C�Y�����炷
	mov	edi,ebx		;edi = ����page�T�C�Y
	add	edx,ebx		;edx = �ύX��page�T�C�Y
	dec	edx		;size to limit

	mov	eax,es		;eax = �Z���N�^�l
	call	sel2adr		;ebx = �f�B�X�N���v�^�f�[�^�̃A�h���X

	mov	al,[ebx+6]	;�Z���N�^ m+6
	mov	[ebx],dx	;bit 15-0
	shr	edx,16		;�E�V�t�g
	and	al,0f0h		;
	and	dl,00fh		;bit 19-16
	or	al,dl		;�l����
	mov	[ebx+6],al	;�l�ݒ�

	call	selector_reload	;�S�Z���N�^�̃����[�h
	jmp	.ret


;******************************************************************************
;�EDOS-Extender functions  AH=25h,35H
;******************************************************************************
proc4 DOS_Extender_fn
	push	eax			;

	cmp	al,DOSX_fn_MAX		;�e�[�u���ő�l
	ja	.chk_02			;����ȏ�Ȃ� jmp

	movzx	eax,al				;�@�\�ԍ�
	mov	eax,[cs:DOSExt_fn_table +eax*4]	;�W�����v�e�[�u���Q��

	xchg	[esp],eax		;eax���� & �W�����v��L�^
	ret				;�e�[�u���W�����v


	align	4
.chk_02:
	sub	al,0c0h			;C0h-C3h
	cmp	al,003h			;chk ?
	ja	.no_func		;����ȏ�Ȃ� jmp

	movzx	eax,al				;�@�\�ԍ� (al)
	mov	eax,[cs:DOSExt_fn_table2+eax*4]	;�W�����v�e�[�u���Q��

	xchg	[esp],eax		;�Ăяo��
	ret				;


	align	4
.no_func:		;���m�̃t�@���N�V����
	pop	eax
	iret



;------------------------------------------------------------------------------
; Not support
;------------------------------------------------------------------------------
DOSX_fn_2512h:		;�f�B�o�O�̂��߂̃v���O�������[�h
DOSX_fn_2516h:		;Ver2.2�ȍ~  �������g�̃�������LDT����S�ĉ��(?)
	set_cy
	iret

;------------------------------------------------------------------------------
;�E���m�̃t�@���N�V����
;------------------------------------------------------------------------------
proc4 DOSX_unknown
	mov	eax,0a5a5a5a5h		;DOS-Extender �̃}�j���A���̋L�q�ǂ���
	set_cy
	iret

;------------------------------------------------------------------------------
;�EV86����Protect �f�[�^�\���̂̃��Z�b�g  AX=2501h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2501h
	push	ds

	push	F386_ds
	pop	ds

	call	clear_gp_buffer_32	; Reset GP buffer
	call	clear_sw_stack_32	; Reset CPU mode change stack

	pop	ds
	clear_cy
	iret


;------------------------------------------------------------------------------
;�EProtect ���[�h�̊��荞�݃x�N�^�擾  AX=2502h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2502h
	push	ecx
	push	ds

	movzx	ecx,cl		;0 �g�� mov
	push	F386_ds	;
	pop	ds		;ds load

%if ((HW_INT_MASTER < 20h) || (HW_INT_SLAVE < 20h))
	cmp	cl,20h		;
	ja	.normal		;�ʏ�̏���

	lea	ecx,[intr_table + ecx*8]
	mov	ebx,[ecx  ]	;�I�t�Z�b�g
	mov	 es,[ecx+4]	;�Z���N�^

	pop	ds
	pop	ecx
	clear_cy
	iret

	align	4
.normal:
%endif

	shl	ecx,3		;ecx = ecx*8
	add	ecx,[IDT_adr]	;IDT�擪���Z

	mov	ebx,[ecx+4]	;bit 31-16
	mov	 bx,[ecx  ]	;bit 15-0
	mov	 es,[ecx+2]	;�Z���N�^�l

	pop	ds
	pop	ecx
	clear_cy
	iret


;------------------------------------------------------------------------------
;�E���A��(V86) ���[�h�̊��荞�݃x�N�^�擾  AX=2503h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2503h
	push	ds
	push	ecx

	movzx	ecx,cl		;0 �g�����[�h

	mov	bx,DOSMEM_sel	;DOS �������Z���N�^
	mov	ds,bx		;ds load
	mov	ebx,[ecx*4]	;000h-3ffh �̊��荞�݃e�[�u���Q��

	pop	ecx
	pop	ds
	clear_cy
	iret


;------------------------------------------------------------------------------
;�EProtect ���[�h�̊��荞�݃x�N�^�ݒ�  AX=2504h
;------------------------------------------------------------------------------
; in 	cl     = interrupt number
;	ds:edx = entry point
;
proc4 DOSX_fn_2504h
	push	eax
	push	ecx
	push	ds

	push	F386_ds
	pop	ds

	movzx	ecx,cl

%if ((HW_INT_MASTER < 20h) || (HW_INT_SLAVE < 20h))
	cmp	cl,20h		;
	ja	.normal		;�ʏ�̏���

	lea	ecx,[intr_table + ecx*8]	;�e�[�u���I�t�Z�b�g
	mov	eax,[esp]			;ax = ���荞�ݐ� ds

	mov	[ecx  ],edx	;�I�t�Z�b�g
	mov	[ecx+4],eax	;�Z���N�^

	pop	ds
	pop	ecx
	pop	eax
	clear_cy
	iret

	align	4
.normal:
%endif

	shl	ecx,3			;ecx = ecx*8
	add	ecx,[IDT_adr]		;IDT�擪���Z
	mov	eax,[esp]		;ax = ���荞�ݐ� ds

	mov	[ecx  ],dx		;bit 15-0
	mov	[ecx+2],ax		;�Z���N�^�l
	shr	edx,16			;���16bit
	mov	[ecx+6],dx		;bit 31-16

	pop	ds
	pop	ecx
	pop	eax
	clear_cy
.exit:	iret


;------------------------------------------------------------------------------
;�E���A��(V86) ���[�h�̊��荞�݃x�N�^�ݒ�  AX=2505h
;------------------------------------------------------------------------------
; in	 cl = interrupt number
;	ebx = handler address / SEG:OFF
;
proc4 DOSX_fn_2505h
	call	set_V86_vector
	clear_cy
	iret

proc4 set_V86_vector
	push	ds
	push	ebx
	push	ecx

	movzx	ecx,cl		;0 �g�����[�h

	push	DOSMEM_sel	;DOS �������Z���N�^
	pop	ds		;ds load
	mov	[ecx*4],ebx	;000h-3ffh �̊��荞�݃e�[�u���ɐݒ�

	mov	ebx,offset RVects_flag_tbl	;�x�N�^���������t���O�e�[�u��
	add	ebx,[cs:top_ladr]		;Free 386 �̐擪���j�A�A�h���X
	bts	[ebx],ecx			;int �����������t���O���Z�b�g
	;��ebx ��擪�Ƀ��������r�b�g��ƌ��Ȃ��A
	;�@���̃r�b�g��� ecx bit �� 1 �ɃZ�b�g���閽�߁B

	pop	ecx
	pop	ebx
	pop	ds
.exit:	ret

;------------------------------------------------------------------------------
;�E��Ƀv���e�N�g���[�h�Ŕ������銄�荞�݂̐ݒ�  AX=2506h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2506h
	push	ebx
	push	ecx
	push	esi
	push	ds

	push	F386_ds
	pop	ds

	movzx	ecx,cl

	mov	ebx,[V86_cs]		;V86 �x�N�^ CS
	shl	ebx,16			;��ʂ�
	mov	esi,[V86int_table_adr]	;int 0    �� hook ���[�`���A�h���X
	lea	 bx,[esi+ecx*4]		;int cl �Ԃ� hook ���[�`���A�h���X
	call	set_V86_vector		;�x�N�^�ݒ�

	pop	ds
	pop	esi
	pop	ecx
	pop	ebx
	jmp	DOSX_fn_2504h		;�v���e�N�g���[�h�̊��荞�݃x�N�^�ݒ�


;------------------------------------------------------------------------------
;�E���A��(V86)���[�h�ƃv���e�N�g���[�h�̊��荞�ݐݒ�@AX=2507h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2507h
	;call	set_V86_vector
	;jmp	DOSX_fn_2504h	;�v���e�N�g���[�h�̊��荞�ݐݒ�

		;��

	push	offset DOSX_fn_2504h
	jmp	set_V86_vector


;------------------------------------------------------------------------------
;�E�Z�O�����g�Z���N�^�̃x�[�X���j�A�A�h���X���擾  AX=2508h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2508h
	verr	bx		;�Z���N�^���L����?
	jnz	short .void	;����

	push	eax
	push	ebx

	movzx	eax,bx		;eax = �Z���N�^
	call	sel2adr		;�f�B�X�N���v�^�A�h���X�ɕϊ� ->ebx

	mov	ecx,[cs:ebx+4]	;bit 31-24
	mov	eax,[cs:ebx+2]	;bit 23-0
	and	ecx,0ff000000h	;�}�X�N
	and	eax, 00ffffffh	;
	or	ecx,eax		;�l����

	pop	ebx
	pop	eax
	clear_cy
	iret

.void:
	mov	eax, 9		;�Z���N�^���s��
	set_cy
	iret



;------------------------------------------------------------------------------
;�E���j�A�A�h���X���畨���A�h���X�ւ̕ϊ��@AX=2509h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2509h
	push	ecx
	push	edx
	push	ds
	push	es

	push	F386_ds
	pop	ds			;ds �ݒ�
	push	ALLMEM_sel
	pop	es			;�S�������A�N�Z�X�Z���N�^

	mov	ecx,ebx			;ecx = ���j�A�A�h���X
	shr	ecx,20			;bit 31-20 ���o��
	and	 cl,0fch		;bit 21,20 �� 0 �N���A
	add	ecx,[page_dir_ladr]	;�y�[�W�f�B���N�g��
	mov	edx,[es:ecx]		;�e�[�u������f�[�^������

	test	edx,edx			;�l�`�F�b�N
	jz	.error			;0 �Ȃ� jmp
	and	edx,0fffff000h		;bit 0-11 clear

	mov	ecx,ebx			;ecx = ���j�A�A�h���X
	shr	ecx,10			;bit 31-10 ���o��
	and	ecx,0ffch		;bit 31-22,11,10 ���N���A

	mov	ecx,[es:edx+ecx]	 ;�y�[�W�e�[�u����ړI�̃y�[�W������
	test	 cl,1			 ;bit 0 ?  (P:���݃r�b�g)
	jz	.error			 ;if 0 jmp

	mov	edx,ebx			;edx = ���j�A�A�h���X
	and	ecx,0fffff000h		;bit 31-12 �����o��
	and	edx,     0fffh		;bit 11-0
	or	ecx,edx			;�l��������

	pop	es
	pop	ds
	pop	edx
	add	esp,byte 4		;ecx = �߂�l �Ȃ̂� pop ���Ȃ�
	clear_cy
	iret


	align	4
.error:
	pop	es
	pop	ds
	pop	edx
	pop	ecx
	set_cy
	iret


;------------------------------------------------------------------------------
; map phisical memory at end of selector
;------------------------------------------------------------------------------
; IN	 AX = 250ah
;	 es = target selector
;	ebx = phisical memory address
;	ecx = mapping pages
;
proc4 DOSX_fn_250ah
	push	ds
	push	esi
	push	edi
	push	ebp
	push	edx
	push	ecx	;ecx is stack+4 top
	push	ebx	;ebx is stack   top

	push	F386_ds
	pop	ds

	mov	ebx,es		;ebx = selector
	test	bl, 04
	jz	.fail0		;not support GDT

	callint	DOSX_fn_2508h	;get selector base address
	jc	.fail0		;ecx = base

	lsl	ebx, ebx	;ebx = limit
	test	ebx, ebx
	jz	.skip
	inc	ebx		;ebx = size
.skip:
	mov	edi, ebx	;edi = size
	mov	ebp, ebx	;ebp = size (save old size)
	add	edi, ecx	;ecx = selector limit linear address +1

	test	edi, 0fffh	;UNIT is 4K?
	jnz	.fail0

	mov	esi, ecx	;esi = map linear address
	mov	edx, [esp]	;edx = map phisical address
	mov	ecx, [esp+4]	;ecx = map pages
	test	ecx, ecx
	jz	.end		;if ecx=0

	call	set_physical_mem
	jc	.fail1		;not enough page table

	mov	eax, ebp	;eax = old size
	shr	eax, 12
	mov	eax, ecx	;eax = new size/4K
	dec	eax		;eax = limit

	;-------------------------------------------------------------
	; save to LDT
	;-------------------------------------------------------------
	mov	ecx, es
	and	 cl, 0f8h	;0ch -> 08h
	mov	ebx, [LDT_adr]
	add	ebx, ecx	;ebx = selector's descriptor pointer

	mov	[ebx], ax	;limit  bit0-15
	mov	dl, [ebx+6]
	shr	eax, 16		;eax = limit16-19
	and	dl, 070h	;save original selector info
	and	al, 00fh	;limit bit16-19
	or	al, dl		;mix
	or	al, 80h		;Force G bit
	mov	[ebx+6], al	;


	call	selector_reload

.end:
	mov	eax, ebp	;new mapping offset of selector
	clc
.exit:
	pop	ebx
	pop	ecx
	pop	edx
	pop	ebp
	pop	edi
	pop	esi
	pop	ds
	iret_save_cy

.fail0:	mov	eax,9		;invalid selector
	stc
	jmp	.exit

.fail1:	mov	eax,8		;not enough page table
	stc
	jmp	.exit


;------------------------------------------------------------------------------
;�E�n�[�h�E�F�A���荞�݃x�N�^�̎擾�@AX=250ch
;------------------------------------------------------------------------------
proc4 DOSX_fn_250ch

	%ifdef USE_VCPI_8259A_API
		mov	ax,[cs:vcpi_8259m]
	%else
		mov	al,HW_INT_MASTER
		mov	ah,HW_INT_SLAVE
	%endif

	clear_cy
	iret


;------------------------------------------------------------------------------
;�E���A�����[�h�����N���̎擾�@AX=250dh
;------------------------------------------------------------------------------
; out	   eax = CS:IP   - far call routine address
;	   ecx = buffer size
;	   ebx = Seg:Off - 16bit buffer address
;	es:edx = buffer protect mode address
;
proc4 DOSX_fn_250dh
	mov	ebx, d [cs:user_cbuf_adr16]
	movzx	ecx, b [cs:user_cbuf_pages]
	shl	ecx, 12				; page to byte

	mov	eax, DOSMEM_sel
	mov	 es, ax
	mov	edx, d [cs:user_cbuf_ladr]

	mov	 ax, [cs:V86_cs]
	shl	eax, 16
	mov	 ax, offset call32_from_V86

	clear_cy
	iret


;------------------------------------------------------------------------------
;�E�v���e�N�g���[�h�A�h���X�����A�����[�h�A�h���X�ɕϊ��@AX=250fh
;------------------------------------------------------------------------------
;	es:ebx	address
;	ecx	size
;
;	Ret:	ecx=seg:off
;
proc4 DOSX_fn_250fh
	push	eax
	push	ebp
	push	esi
	push	edi
	push	ecx
	push	ebx	;�X�^�b�N���ԕύX�s�I
	cmp	ebx, 0ffffh
	ja	.fail		;

	mov	ebx, es		;in : bx=selector
	callint	DOSX_fn_2508h	;�Z���N�^�x�[�X�A�h���X�擾
	jc	.fail		;out: ecx=base

	mov	ebx, [esp]	;ebx = offset
	mov	edi, [esp+4]	;edi = size
	add	ecx, ebx	;ecx = ebx = base + offset
	mov	ebx, ecx	;
	and	ecx, 000000fffh	;�[��
	and	ebx, 0fffff000h	;4KB�P��
	add	edi, ecx	;�[�����T�C�Y�ɉ��Z
	jc	.fail		;�I�[�o�[�t���[

	xor	esi, esi
.loop:				;in = ebx
	callint	DOSX_fn_2509h	;�����A�h���X�ւ̕ϊ�
				;out= ecx
	cmp	ecx, 010ffefh	;���j�A�A�h���X�͈�
	ja	.fail		;DOS�������͈͊O �Ȃ� jmp
	test	esi, esi
	jnz	.check
	mov	esi, ecx	;
	mov	ebp, ecx	;�ŏ��̕����A�h���X�L�^
	jmp	short .step
.check:
	add	esi, 01000h	;1�O�̕����A�h���X+4K
	cmp	ecx, esi	;��v���邩�H
	jnz	.fail		;�s�A���Ȃ玸�s
.step:
	add	ebx, 01000h	;���j�A�A�h���X +4KB
	sub	edi, 01000h	;�T�C�Y         -4KB
	ja	.loop

	;convert to real-mode seg:off
	mov	ecx, ebp
	shl	ecx, 16-4	;bit31-16 = DOS seg
	mov	 cx, [esp]	;bit15- 0 = offset

	pop	ebx
	pop	eax		;ecx ����
	pop	edi
	pop	esi
	pop	ebp
	pop	eax
	clear_cy
	iret

.fail:
	pop	ebx
	pop	ecx
	pop	edi
	pop	esi
	pop	ebp
	pop	eax
	set_cy
	iret


;------------------------------------------------------------------------------
; far call to real mode routine //  AX=250eh
;------------------------------------------------------------------------------
; in	ebx = call far address
;	ecx = stack copy count (word)
; ret	 cy = 0	success
;	 cy = 1	fail. eax = 1 not enough real-mode stack space
;
%define	COPY_STACK_MAX_WORDS	((SW_stack_size - 40h)/2)

proc4 DOSX_fn_250eh
	start_sdiff
	pushf_x
	cmp	ecx, COPY_STACK_MAX_WORDS
	ja	.fail

	push_x	eax
	push_x	ecx
	push_x	ds

	push	F386_ds
	pop	ds

	lea	eax, [esp + .sdiff + 0ch]	; copy stack offset
	mov	[cv86_copy_stack], eax
	shl	ecx, 1				; ecx is copy word count
	mov	[cv86_copy_size],  ecx

	pop_x	ds
	pop_x	ecx
	pop_x	eax
	popf_x
	end_sdiff

	push	ebx				; far call point
	push	O_CV86_FARCALL
	call	call_V86_clear_stack
	clc
	jmp	all_flags_save_iret

.fail:
	mov	eax, 1
	popf
	set_cy
	iret

;------------------------------------------------------------------------------
; far call real mode routine // AX=2510h
;------------------------------------------------------------------------------
; in	   ebx = call far address
;	   ecx = stack copy count (word)
;	ds:edx = parameter block
; ret	cy = 0	success
;	   edx = unchange
;	cy = 1	fail. eax = 1 not enough real-mode stack space
;
proc4 DOSX_fn_2510h
	call_DumpDsEdx	18h		; dump, if set DUMP_DS_EDX

	start_sdiff
	push_x	es
	pushf_x
	cmp	ecx, COPY_STACK_MAX_WORDS
	ja	.fail

	push	F386_ds
	pop	es

	;--------------------------------------------------
	; check copy stack size
	;--------------------------------------------------
	push_x	ecx

	lea	eax, [esp + .sdiff + 0ch]
	mov	es:[cv86_copy_stack], eax	; copy stack top
	shl	ecx, 1				; ecx is copy word count
	mov	es:[cv86_copy_size],  ecx	; copy bytes

	pop_x	ecx
	popf_x

	;--------------------------------------------------
	; set V86 segments
	;--------------------------------------------------
	movzx	eax,w [edx]
	mov	es:[cv86_ds], eax
	movzx	eax,w [edx + 02h]
	mov	es:[cv86_es], eax
	movzx	eax,w [edx + 04h]
	mov	es:[cv86_fs], eax
	movzx	eax,w [edx + 06h]
	mov	es:[cv86_gs], eax

	push_x	edx			; save parameter block pointer
	;--------------------------------------------------
	; set register and call
	;--------------------------------------------------
	push	ebx			; far call point
	push	O_CV86_FARCALL		; options

	mov	eax, [edx + 08h]	; load from parameter block
	mov	ebx, [edx + 0ch]
	mov	ecx, [edx + 10h]	;
	mov	edx, [edx + 14h]	;
	call	call_V86_clear_stack

	;--------------------------------------------------
	; save register
	;--------------------------------------------------
	; *** NOT USE eax! ***
	xchg	[esp], edx		; edx   = parameter block pointer
					; [esp] = return edx
	mov	[edx + 0ch], ebx
	mov	[edx + 10h], ecx	
	pop_x	ebx			; ebx = return edx
	mov	[edx + 14h], ebx	; save

	pushf_x
	pop_x	ebx
	mov	[edx + 08h], ebx	; save flags

	;--------------------------------------------------
	; save V86 segments
	;--------------------------------------------------
	mov	ebx, es:[cv86_ds]
	mov	[edx + 00h], bx
	mov	ebx, es:[cv86_es]
	mov	[edx + 02h], bx
	mov	ebx, es:[cv86_fs]
	mov	[edx + 04h], bx
	mov	ebx, es:[cv86_gs]
	mov	[edx + 06h], bx

	;--------------------------------------------------
	; return
	;--------------------------------------------------
	mov	ebx, [edx + 0ch]

	pop_x	es
	end_sdiff

	clc
	jmp	all_flags_save_iret

.fail:
	mov	eax, 1
	popf
	pop	es
	set_cy
	iret

;------------------------------------------------------------------------------
;�E���A�����[�h���荞�݂̎��s�@AX=2511h
;------------------------------------------------------------------------------
; in	ds:edx
;	+00h w int number
;	+02h w ds
;	+04h w es
;	+06h w fs
;	+08h w gs
;	+0ah d eax
;	+0eh d edx
;
proc4 DOSX_fn_2511h
	call_DumpDsEdx	12h		; dump, if set DUMP_DS_EDX

	push	es
	push	edx

	push	F386_ds
	pop	es

	;--------------------------------------------------
	; set V86 segments
	;--------------------------------------------------
	movzx	eax,w [edx + 02h]
	mov	es:[cv86_ds], eax
	movzx	eax,w [edx + 04h]
	mov	es:[cv86_es], eax
	movzx	eax,w [edx + 06h]
	mov	es:[cv86_fs], eax
	movzx	eax,w [edx + 08h]
	mov	es:[cv86_gs], eax

	;--------------------------------------------------
	; call V86 int
	;--------------------------------------------------
	movzx	eax, byte [edx]
	push	eax			; int number
	push	O_CV86_INT

	mov	eax, [edx + 0ah]
	mov	edx, [edx + 0eh]
	call	call_V86_clear_stack

	;--------------------------------------------------
	; save register
	;--------------------------------------------------
	; stack	+00h edx	parameter block pointer
	;	+04h  es
	;
	xchg	[esp], eax		; eax = parameter block
	xchg	eax, edx		; edx = parameter block
	mov	[edx + 0eh], eax	; save return edx

	; stack	+00h eax
	;	+04h  es
	mov	eax, es:[cv86_ds]
	mov	[edx + 02h], ax
	mov	eax, es:[cv86_es]
	mov	[edx + 04h], ax
	mov	eax, es:[cv86_fs]
	mov	[edx + 06h], ax
	mov	eax, es:[cv86_gs]
	mov	[edx + 08h], ax

	pop	eax
	pop	es
	jmp	all_flags_save_iret


;------------------------------------------------------------------------------
;�E�G�C���A�X�Z���N�^�̍쐬�@AX=2513h
;------------------------------------------------------------------------------
;	bx = �G�C���A�X���쐬����Z���N�^
;	cl = �f�B�X�N���v�^�� +5 byte �ڂɃZ�b�g����l
;	ch = bit 6 �݈̂Ӗ��������AUSE����(16bit/32bit)���w��
;
proc4 DOSX_fn_2513h
	push	ds
	push	edx
	push	ecx
	push	ebx
	push	eax	;�߂�l�𒼐ڏ������ނ̂ŁA�Ō�̐ς�

	push	F386_ds
	pop	ds

	movzx	ebx,bx
	test	bl, 04h			;LDT flag?
	jz	.fail

	call	search_free_LDTsel	;�󂫃Z���N�^����
	test	eax,eax			;�߂�l�m�F
	jz	.fail

	call	regist_managed_LDTsel	;regist eax

	mov	[esp], eax	;�R�s�[��Z���N�^�i�߂�l�L�^�j

	push	ebx
	call	sel2adr		;LDT���A�h���X�ɕϊ�
	mov	edx,ebx		;edx = �R�s�[��A�h���X
	pop	eax		;eax = �R�s�[���Z���N�^
	call	sel2adr		;ebx = �R�s�[���A�h���X

	test	ebx, ebx
	jz	short .void
	test	b [ebx+5], 080h	;P bit
	jz	short .void

	;copy  ebx->edx
	mov	eax,[ebx]	;�R�s�[
	mov	[edx],eax	;

	mov	eax,[ebx+4]	;
	shl	ecx,8		;�V�t�g
	and	ecx,000407f00h	;bit 15-0  ���o��
	and	eax,0ffbf80ffh	;bit 23-16 �̊Y�������}�X�N
	or	eax,ecx		;�����̒l��������
	mov	[edx+4],eax	;

	pop	eax		;load eax
	pop	ebx
	pop	ecx
	pop	edx
	pop	ds
	clear_cy
	iret

.fail:	mov	eax,8
.ret:	pop	ebx	; skip eax
	pop	ebx
	pop	ecx
	pop	edx
	pop	ds
	set_cy
	iret

.void:
	mov	eax,9	;invalid selector
	jmp	short .ret


;------------------------------------------------------------------------------
;�E�Z�O�����g�����̕ύX�@AX=2514h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2514h
	push	ecx
	push	ebx
	push	eax
	push	ds

	push	F386_ds
	pop	ds

	movzx	eax,bx		;eax = �Z���N�^
	call	sel2adr		;ebx = �A�h���X

	test	ebx, ebx		;�͈͊O�̂Ƃ�ebx=0
	jz	short .void
	test	b [ebx+5], 080h		;P bit
	jz	short .void

	mov	eax, [ebx+4]	;���ݒl���[�h
	shl	ecx,8		;�V�t�g
	and	ecx,000407f00h	;bit 15-0  ���o��
	and	eax,0ffbf80ffh	;bit 23-16 �̊Y�������}�X�N

	or	eax,ecx		;�����̒l��������
	mov	[ebx+4],eax	;

	pop	ds
	pop	ecx
	pop	ebx
	pop	eax
	clear_cy
	iret

.void:
	mov	eax,9		;�Z���N�^���s��
	pop	ds
	pop	ebx		;eax�ǂݎ̂�
	pop	ebx
	pop	ecx
	set_cy
	iret


;------------------------------------------------------------------------------
;�E�Z�O�����g�����̎擾�@AX=2515h
;------------------------------------------------------------------------------
proc4 DOSX_fn_2515h
	push	ebx
	push	eax

	movzx	eax,bx		;eax = �Z���N�^
	call	sel2adr		;ebx = �A�h���X
	test	ebx, ebx	;�͈͊O�̂Ƃ�ebx=0
	jz	short .void

	mov	cx,[cs:ebx+5]	;USE / Type ���[�h

	pop	eax
	pop	ebx
	clear_cy
	iret

.void:
	mov	eax,9		;�Z���N�^���s��
	pop	ds
	pop	ebx		;eax�ǂݎ̂�
	pop	ebx
	set_cy
	iret


;------------------------------------------------------------------------------
;AX=2517h: GET INFO ON DOS DATA BUFFER, Phar Lap v2.1c+
;------------------------------------------------------------------------------
;out es:ebx = protect mode buffer address
;	ecx = real mode address, Seg:Off
;	edx = size (byte)
;
proc4 DOSX_fn_2517h
	mov	eax, DOSMEM_sel
	mov	 es, ax
	mov	ebx, d [cs:user_cbuf_ladr]

	mov	ecx, d [cs:user_cbuf_adr16]
	movzx	edx, b [cs:user_cbuf_pages]
	shl	edx, 12				; page to byte

	clear_cy
	iret


;------------------------------------------------------------------------------
;�EDOS�������u���b�N�A���P�[�V�����@AX=25c0h
;------------------------------------------------------------------------------
proc4 DOSX_fn_25c0h
	mov	ah,48h
	jmp	call_V86_int21_iret


;------------------------------------------------------------------------------
;�EDOS�������u���b�N�̉���@AX=25c1h
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;�EMS-DOS�������u���b�N�̃T�C�Y�ύX�@AX=25c2h
;------------------------------------------------------------------------------
proc4 DOSX_fn_25c1h
	push	eax
	mov	ah,49h		; free memory block
	jmp	short DOSX_fn_25c2h.step

proc4 DOSX_fn_25c2h		; resize memory block
	push	eax
	mov	ah,49h
.step:
	V86_INT	21h
	jc	.fail

	pop	eax		; success
	clear_cy
	iret

.fail:	add	esp, 4		; remove eax // eax = error code
	set_cy
	iret


;------------------------------------------------------------------------------
;�EDOS�v���O�������q�v���Z�X�Ƃ��Ď��s  AX=25c3h
;------------------------------------------------------------------------------
;DOSX_fn_25c3h
;	jmp	int_21h_4bh		;int 21h / 4bh �Ɠ���
;
;//////////////////////////////////////////////////////////////////////////////
