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
	align	4
int_21h_30h:
	clear_cy	; stack eflags clear

	;eax �̏��16bit �� 'DX' ������
	and	eax,0ffffh	;����16bit ���o��
	shl	eax,16		;��x��ʂւ��炷
	mov	 ax,4458h	;'DX' : Dos-Extender
	rol	eax,16		;��ʃr�b�g�Ɖ��ʃr�b�g����ꊷ����

	cmp	ebx,'RAHP'	;RUN386 funciton? / 'PHAR'
	je	.run386
	cmp	ebx,'XDJF'	;FM TOWNS un-documented funciton? / 'FJDX'
	je	.fujitsu
	cmp	ebx,'F386'	;Free386 funciton?
	je	.free386

	;DOS Version �̎擾
	jmp	call_V86_int21	;DOS Version �̎擾

.run386:
	pushf
	push	cs
	call	call_V86_int21
	;
	;Phar Lap �o�[�W�������
	;	�e�X�g�l�FEAX=44581406  EBX=4A613231  ECX=56435049  EDX=0
	mov	ebx, [cs:pharlap_version]	; 'Ja21' or ' d22'
	mov	ecx, 'IPCV'			;="VCPI" / ��' DOS','DPMI' �����邪�Ή����ĂȂ�
	xor	edx, edx			;edx = 0
	iret

.fujitsu:
	mov	eax, 'XDJF'	; 'FJDX'
	mov	ebx, ' neK'	; 'Ken '
	mov	ecx, 40633300h	; '@c3', 0
	iret

.free386:
	mov	al,Major_ver	;Free386 ���W���o�[�W����
	mov	ah,Minor_ver	;Free386 �}�C�i�[�o�[�W����
	mov	ebx,F386_Date	;���t
	mov	ecx,0		;reserved
	mov	edx,' ABK'	;for Free386 check
	iret

;------------------------------------------------------------------------------
;�E�v���O�����I��  AH=00h,4ch
;------------------------------------------------------------------------------
	align	4
int_21h_00h:
	xor	al,al			;���^�[���R�[�h = 0 / DOS�݊�
int_21h_4ch:
	add	esp,12			;�X�^�b�N����
	jmp	exit_32		;DOS-Extender �I������

	;���{���͂����� DOS_Extender �I������������

;------------------------------------------------------------------------------
;�ELDT���ɃZ���N�^���쐬�����������m��  AH=48h
;------------------------------------------------------------------------------
	align	4
int_21h_48h:
	push	esi
	push	ecx
	push	ebx
	push	ds

	push	d (F386_ds)
	pop	ds

	mov	ecx,ebx		;ecx = �v���y�[�W��
	call	alloc_RAM
	jc	.fail		;���s?

	call	search_free_LDTsel	;��LDT����
	test	eax,eax			;�߂�l�m�F
	jz	.fail			;���s?

	dec	ebx		;�T�C�Y -1
	mov	edi,[work_adr]	;���[�N�A�h���X
	mov	[edi  ],esi	;�x�[�X�A�h���X
	mov	[edi+4],ebx	;limit
	mov	d [edi+8],0200h	;R/W 386
	push	eax
	call	make_mems_4k	;�Z���N�^�쐬 / eax = �Z���N�^
	pop	eax

	pop	ds
	pop	ebx
	pop	ecx
	pop	esi
	clear_cy
	iret


	align	4
.fail:	call	get_maxalloc	;eax = �ő劄�蓖�ă�������(page)
	mov	ebx,eax		;ebx �ɐݒ�
	mov	eax,8		;�G���[�R�[�h
	pop	ds
	pop	ecx		;ebx �ǂݎ̂�
	pop	ecx
	pop	esi
	set_cy
	iret


;------------------------------------------------------------------------------
;�ELDT���̃Z���N�^���폜�������������  AH=49h
;------------------------------------------------------------------------------
	align	4
int_21h_49h:			;���Ή��̋@�\ / ��������������Ă��Ȃ�
	push	eax
	push	ebx
	push	ds

	mov	eax,F386_ds
	mov	 ds,eax

	mov	eax,es			;eax = �����Z���N�^
	call	sel2adr			;�A�h���X�ϊ�
	and	b [ebx + 5],7fh		;P(����) bit �� 0 �N���A

	xor	eax,eax			;eax = 0
	mov	 es,eax			;es  = 0

	pop	ds
	pop	ebx
	pop	eax
	clear_cy
	iret


;------------------------------------------------------------------------------
;�E�Z�O�����g�̑傫���ύX  AH=4ah
;------------------------------------------------------------------------------
	align	4
int_21h_4ah:			;����������@�\�Ȃ�
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	push	ds

	mov	eax,F386_ds
	mov	 ds,eax
	mov	edi,ebx			;edi = �ύX��T�C�Y(�l�ۑ��p)

	mov	eax,es			;eax = �����Z���N�^
	verr	ax			;�ǂݍ��߂�Z���N�^�H
	jnz	.dont_exist

	lsl	edx,eax			;���݂̃��~�b�g�l
	inc	edx			;ebx = size
	shr	edx,12			;size [page]
	sub	ebx,edx			;�ύX�� - �ύX�O
	jc	.decrease		;�k���Ȃ� jmp
	je	.ret			;�����Ȃ�ύX�Ȃ�
	mov	ecx,ebx			;ecx = �����y�[�W��

	mov	eax,es			;eax = �Z���N�^
	call	get_selector_last	;�Z���N�^�̍ŏI���j�A�A�h���X
	mov	esi,eax			;�Z���N�^limit

					;in  esi = �\��t����x�[�X�A�h���X
	call	get_maxalloc_with_adr	;out eax = ���蓖�ĉ\��, ebx=�e�[�u���p�y�[�W��
	cmp	eax,ecx			;�� - �K�v��
	jb	.fail			;����Ȃ���Ύ��s

					;in  esi = �\��t����x�[�X�A�h���X
					;    ecx = �\��t����y�[�W��
	call	alloc_RAM_with_ladr	;���������蓖��
	jc	.fail

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

.ret:	pop	ds
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clear_cy
	iret

.fail:	call	get_maxalloc_with_adr
	mov	ebx, eax
	mov	eax, 8
.fail2:	pop	ds
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	add	esp,8
	set_cy
	iret

.dont_exist:
	mov	eax,9
	jmp	short .fail2

	align	4
.decrease:
%if 0
	; ���������J�����邱�Ƃ�����̂ŁA
	; �Z���N�^�T�C�Y�����̂܂܂ɂ��Ă����A�����������Ƃɂ���B
	; �Z���N�^�T�C�Y�����炵�Ă��܂��ƁA
	; �ēx4ah�Ń������g������Ƃ��Ƀ������s���ŃG���[�ɂȂ��Ă��܂��B
	; ��High-C�R���p�C����386linkp��
	;

	; �Z���N�^�T�C�Y�����炷
	mov	edi,ebx		;edi = �����T�C�Y(page / ����)
	add	edx,ebx		;edx = �ύX��T�C�Y(page)

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

	mov	eax,es			;eax = �Z���N�^
	call	get_selector_last	;�Z���N�^�Ō�����j�A�A�h���X�擾

	mov	ebx,eax			;ebx = �߂�l

	calli	DOS_Ext_fn_2509h	;�����A�h���X�擾 / ret ecx

	mov	[free_RAM_padr] ,ecx	;�����A�h���X
	sub	[free_RAM_pages],edi	;�󂫃������y�[�W�����Z (= ����������)
%endif
	jmp	.ret



;******************************************************************************
;�EDOS-Extender �g���t�@���N�V����  AH=25h,35H
;******************************************************************************
	align	4
DOS_Extender_fn:
	push	eax			;

	cmp	al,DOS_Ext_MAXF		;�e�[�u���ő�l
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
;�E���Ή����X�g
;------------------------------------------------------------------------------
DOS_Ext_fn_2512h:		;�f�B�o�O�̂��߂̃v���O�������[�h
DOS_Ext_fn_2516h:		;Ver2.2�ȍ~  �������g�̃�������LDT����S�ĉ��(?)
	set_cy
	iret

;------------------------------------------------------------------------------
;�E���m�̃t�@���N�V����
;------------------------------------------------------------------------------
	align	4
DOS_Ext_unknown:
	mov	eax,0a5a5a5a5h		;DOS-Extender �̃}�j���A���̋L�q�ǂ���
	set_cy
	iret


;------------------------------------------------------------------------------
;�E���m�̋@�\  AX=2500h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2500h:
	mov	eax,0a5a5a5a5h
	iret
	;
	;RUN386 / EXE386 �����̌��ʁB�L�����[���ω������B
	;-> �����ȃt�@���N�V�������A�G���[�ŃL�����[���Z�b�g���ꂽ�Ƃ��́A
	;   eax �̂ݕω��� eax = 0A5A5A5A5h �ɂȂ�Ƃ̋L�q (RUN386 �}�j���A��)


;------------------------------------------------------------------------------
;�EV86����Protect �f�[�^�\���̂̃��Z�b�g  AX=2501h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2501h:
	push	ds

	push	d (F386_ds)
	pop	ds

	call	clear_gp_buffer_32	; Reset GP buffer
	call	clear_sw_stack_32	; Reset CPU mode change stack

	pop	ds
	clear_cy
	iret


;------------------------------------------------------------------------------
;�EProtect ���[�h�̊��荞�݃x�N�^�擾  AX=2502h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2502h:
	push	ecx
	push	ds

	movzx	ecx,cl		;0 �g�� mov
	push	d (F386_ds)	;
	pop	ds		;ds load

%if (enable_INTR)
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
	align	4
DOS_Ext_fn_2503h:
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
proc DOS_Ext_fn_2504h
	push	eax
	push	ecx
	push	ds

	movzx	ecx,cl			;0 �g�����[�h
	mov	ax,F386_ds		;
	mov	ds,eax			;ds load

%if (enable_INTR)
%if ((HW_INT_MASTER < 20h) || (HW_INT_SLAVE  < 20h))
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
	align	4
DOS_Ext_fn_2505h:
	call	set_V86_vector
	clear_cy
	iret

proc set_V86_vector
	push	ds
	push	ebx
	push	ecx

	movzx	ecx,cl		;0 �g�����[�h

	push	d (DOSMEM_sel)	;DOS �������Z���N�^
	pop	ds		;ds load
	mov	[ecx*4],ebx	;000h-3ffh �̊��荞�݃e�[�u���ɐݒ�

	mov	ebx,offset RVects_flag_tbl	;�x�N�^���������t���O�e�[�u��
	add	ebx,[cs:top_adr]		;Free 386 �̐擪���j�A�A�h���X
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
	align	4
DOS_Ext_fn_2506h:
	push	ebx
	push	ecx
	push	esi
	push	ds

	movzx	ecx,cl		;0 �g�����[�h
	push	d (F386_ds)	;ds
	pop	ds		;

	mov	ebx,[V86_cs]		;V86 �x�N�^ CS
	shl	ebx,16			;��ʂ�
	mov	esi,[rint_labels_adr]	;int 0    �� hook ���[�`���A�h���X
	lea	 bx,[esi+ecx*4]		;int cl �Ԃ� hook ���[�`���A�h���X
	call	set_V86_vector		;�x�N�^�ݒ�

	pop	ds
	pop	esi
	pop	ecx
	pop	ebx
	jmp	DOS_Ext_fn_2504h		;�v���e�N�g���[�h�̊��荞�݃x�N�^�ݒ�


;------------------------------------------------------------------------------
;�E���A��(V86)���[�h�ƃv���e�N�g���[�h�̊��荞�ݐݒ�@AX=2507h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2507h:
	;call	set_V86_vector
	;jmp	DOS_Ext_fn_2504h	;�v���e�N�g���[�h�̊��荞�ݐݒ�

		;��

	push	d (offset DOS_Ext_fn_2504h)
	jmp	set_V86_vector


;------------------------------------------------------------------------------
;�E�Z�O�����g�Z���N�^�̃x�[�X���j�A�A�h���X���擾  AX=2508h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2508h:
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
	align	4
DOS_Ext_fn_2509h:
	push	ecx
	push	edx
	push	ds
	push	es

	push	d (F386_ds)
	push	d (ALLMEM_sel)
	pop	es		;�S�������A�N�Z�X�Z���N�^
	pop	ds		;ds �ݒ�

	mov	ecx,ebx		;ecx = ���j�A�A�h���X
	shr	ecx,20		;bit 31-20 ���o��
	and	 cl,0fch	;bit 21,20 �� 0 �N���A
	add	ecx,[page_dir]	;�y�[�W�f�B���N�g��
	mov	edx,[ecx]	;�e�[�u������f�[�^������

	test	edx,edx		;�l�`�F�b�N
	jz	.error		;0 �Ȃ� jmp
	and	edx,0fffff000h	;bit 0-11 clear

	mov	ecx,ebx		;ecx = ���j�A�A�h���X
	shr	ecx,10		;bit 31-10 ���o��
	and	ecx,0ffch	;bit 31-22,11,10 ���N���A

	mov	ecx,[es:edx+ecx] ;�y�[�W�e�[�u����ړI�̃y�[�W������
	test	 cl,1		 ;bit 0 ?  (P:���݃r�b�g)
	jz	.error		 ;if 0 jmp

	mov	edx,ebx		;edx = ���j�A�A�h���X
	and	ecx,0fffff000h	;bit 31-12 �����o��
	and	edx,     0fffh	;bit 11-0
	or	ecx,edx		;�l��������

	pop	es
	pop	ds
	pop	edx
	add	esp,byte 4	;ecx = �߂�l �Ȃ̂� pop ���Ȃ�
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
;�E�����A�h���X�̃}�b�s���O�@AX=250ah
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_250ah:			;���Ή��I�I
	push	ds
	push	esi
	push	edi
	push	edx
	push	ecx
	push	ebx	;�X�^�b�N���ԕύX�s�I

	mov	edx,F386_ds	;ds ���[�h
	mov	 ds,edx		;ds �ɐݒ�

	mov	ebx,es		;�w��Z���N�^���[�h
	pushf			;*
	push	cs		;* �Z���N�^�x�[�X�A�h���X�擾
	call	DOS_Ext_fn_2508h	;*
	mov	eax,ecx		;eax = �x�[�X�A�h���X
	lsl	ebx,ebx		;ebx = ���~�b�g�l
	inc	ebx		;ebx = �T�C�Y
	mov	edi,ebx		;edi �ɂ�
	add	ecx,ebx		;ecx = �Z���N�^�̈�Ԍ��
	shr	edi,12		;edi = page�P�ʂ̃T�C�Y

	test	ecx,0fffh	;����12�r�b�g�`�F�b�N
	jnz	.fail0		;�y�[�W�P�ʊ�����łȂ����̂̓W�����v

	mov	esi,ecx			;esi = ������惊�j�A�A�h���X
	mov	ecx,[esp+4]		;ecx = �������y�[�W��
	mov	edx,[esp]		;edx = ������镨���A�h���X
	add	edi,ecx			;edi = ������̃T�C�Y
	call	set_physical_mem	;�����
	jc	.fail1			;�y�[�W�e�[�u���s��

	mov	eax,ebx			;eax = �Z���N�^���I�t�Z�b�g
	mov	ecx,edi			;ecx = �V�����T�C�Y
	dec	ecx			;limit�l��

	mov	ebx,es		;�w��Z���N�^
	mov	edx,[GDT_adr]	;GDT �ւ̃|�C���^
	test	ebx,4		;�Z���N�^�l��bit2�� check
	jz	short .GDT	; 0 �Ȃ��GDT �Ȃ̂ł��̂܂ܼެ���
	mov	edx,[LDT_adr]	;LDT �ւ̃|�C���^
.GDT:	and	ebx,0fff8h	;�f�B�X�N���v�^��8byte�P�ʂȂ̂ŉ���3bit�؎̂�
	add	ebx,edx

	mov	[ebx  ],cx	;limit�l bit 15-0
	mov	dl,[ebx+6]	;DT+6 �ǂݏo��
	shr	ecx,16		;�E�V�t�g
	and	dl,0f0h		;�Z���N�^���
	and	cl,00fh		;limit�l bit 19-16
	or	dl,cl		;limit�l��������
	mov	[ebx+6],dl	;

	call	selector_reload	;�S�Z���N�^�̃����[�h (hack.txt�Q�Ƃ̂���)

	pop	ebx
	pop	ecx
	pop	edx
	pop	edi
	pop	esi
	pop	ds
	clear_cy
	iret

.fail1:	mov	eax,8	;�y�[�W�e�[�u���s��
	jmp	short .fail
.fail0:	mov	eax,9	;�Z���N�^���s��
.fail:	pop	ebx
	pop	ecx
	pop	edx
	pop	edi
	pop	esi
	pop	ds
	set_cy
	iret


;------------------------------------------------------------------------------
;�E�n�[�h�E�F�A���荞�݃x�N�^�̎擾�@AX=250ch
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_250ch:
	mov	al,HW_INT_MASTER
	mov	ah,HW_INT_SLAVE
	clear_cy
	iret


;------------------------------------------------------------------------------
;�E���A�����[�h�����N���̎擾�@AX=250dh
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_250dh:
	xor	ecx,ecx
	mov	ebx, d [cs:call_buf_adr16]
	mov	 cl, b [cs:call_buf_sizeKB]
	shl	ecx, 10
	mov	edx, d [cs:call_buf_adr32]

	mov	eax, DOSMEM_Lsel
	mov	 es, eax

	mov	 ax, [V86_cs]
	shl	eax, 16
	mov	 ax, offset callf32_from_V86

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
DOS_Ext_fn_250fh:
	push	eax
	push	ebp
	push	esi
	push	edi
	push	ecx
	push	ebx	;�X�^�b�N���ԕύX�s�I
	cmp	ebx, 0ffffh
	ja	.fail		;

	mov	ebx, es		;in : bx=selector
	calli	DOS_Ext_fn_2508h	;�Z���N�^�x�[�X�A�h���X�擾
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
.loop:				 ;in = ebx
	calli	DOS_Ext_fn_2509h ;�����A�h���X�ւ̕ϊ�
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
;�E���A�����[�h�̃��[�`��far�R�[���@AX=250eh
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_250eh:		;���Ή��I�I�@V86 call���A�t���O�ۑ����Ȃ�

	test	ecx,ecx		;�X�^�b�N�R�s�[��
	jnz	.fail		;�w�肪����Ύ��s

	push	eax		;+14h : eax ���X�^�b�N�Q�ƒ���

	mov	eax,ebx		;eax =0
	shr	eax,16		;ax = cs (seg-reg)
	push	eax		;+10h : gs
	push	eax		;+0ch : fs
	push	eax		;+08h : es
	push	eax		;+04h : ds
	push	ebx		;+00h : �Ăяo���A�h���X

	mov	eax,[esp+14h]	;eax����
	call	call_V86	;�ړI���[�`���� call

	add	esp,14h		;�X�^�b�N����
	clear_cy
	iret

.fail:
	mov	eax,1		;�G���[�R�[�h(�R)
	set_cy
	iret


;------------------------------------------------------------------------------
;�E���A�����[�h�̃��[�`��far�R�[���@AX=2510h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2510h:		;���Ή��I�I
	test	ecx,ecx		;�X�^�b�N�R�s�[��
	jnz	.fail		;�w�肪����Ύ��s

	push	edx		;�X�^�b�N�Q�Ƃɒ��ӁI�I
	push	eax		;�X�^�b�N�Q�Ƃɒ��ӁI�I

	xor	eax,eax			;��ʃN���A
	movzx	eax,w [es:edx + 6]
	push	eax			;gs
	movzx	eax,w [es:edx + 4]
	push	eax			;fs
	movzx	eax,w [es:edx + 2]
	push	eax			;es
	movzx	eax,w [es:edx]
	push	eax			;ds
	push	ebx			;�Ăяo���A�h���X

	mov	eax,[es:edx + 08h]	;�p�����^�u���b�N���烍�[�h
	mov	ebx,[es:edx + 0ch]	;
	mov	ecx,[es:edx + 10h]	;
	mov	edx,[es:edx + 14h]	;
	call	call_V86		;�ړI���[�`���� call
	;*** �t���O�͐ݒ肳��Ă��� ***

	;+00h	call adress / cs:ip
	;+04h	V86 ds
	;+08h	V86 es
	;+0ch	V86 fs
	;+10h	V86 gs
	;+14h	eax
	;+18h	edx

	mov	[esp+14h], eax		;save

	mov	eax,edx
	mov	edx,[esp +18h]		;edx ���� / �X�b�^�N�Q�ƁI�I

	mov	[es:edx+14h],eax	;edx
	mov	[es:edx+10h],ecx
	mov	[es:edx+0ch],ebx
	pop	eax			;�ǂݎ̂�
	pop	eax			;ds
	mov	[es:edx    ],ax
	pop	eax			;es
	mov	[es:edx+ 2h],ax
	pop	eax			;fs
	mov	[es:edx+ 4h],ax
	pop	eax			;gs
	mov	[es:edx+ 6h],ax

	pushf				;flag
	pop	eax			;
	mov	[es:edx+08h],eax	;flags save
	and	eax, 0cfeh		;IF/IOPL �ȊO���o�� / Cy=0
	and	w [esp + 10h],0f300h	;IF/IOPL �Ȃǎ��o��
	or	  [esp + 10h],ax	;���ʂ̃t���O��������

	pop	eax
	pop	edx
	iret

.fail:
	mov	eax,1			;�G���[�R�[�h(�R)
	set_cy
	iret


;------------------------------------------------------------------------------
;�E���A�����[�h���荞�݂̎��s�@AX=2511h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2511h:
	push	es
	push	edx		;�l�ۑ��p�X�^�b�N�̈�m��
	push	edx		;�X�^�b�N�Q�Ƃɒ��ӁI�I

%if INT_HOOK && PRINT_TSUGARU
	push	ebx
	push	ecx
	push	edx

	mov	ebx, edx
	mov	ecx, 12h
	mov	dx, 2F18h
	mov	al, 0ah
	out	dx, al

	pop	edx
	pop	ecx
	pop	ebx
%endif

	xor	eax,eax			;��ʃN���A
	movzx	eax,w [edx + 8]
	push	eax			;gs
	movzx	eax,w [edx + 6]
	push	eax			;fs
	movzx	eax,w [edx + 4]
	push	eax			;es
	movzx	eax,w [edx + 2]
	push	eax			;ds

	mov	eax,DOSMEM_sel		;DOS �������A�N�Z�X�Z���N�^
	mov	 es,eax			;load
	movzx	eax,b [edx]		;ds:edx ���犄�荞�ݔԍ��ǂݏo��
	push	d [es:eax*4]		;�x�N�^�A�h���X�擾 = �Ăяo���A�h���X

	mov	eax,[edx + 0ah]		;�p�����^�u���b�N���烍�[�h
	mov	edx,[edx + 0eh]		;

	call	call_V86		;�ړI���[�`���� call
	;*** �t���O�͐ݒ肳��Ă��� ***

	mov	[esp],edx		;�X�^�b�N�g�b�v�֋L�^
	mov	edx,[esp +14h]		;edx ���� / �X�b�^�N�Q�ƁI�I

	mov	[esp +18h],eax		;eax �ۑ�
	pop	eax			;0 : edx
	mov	[edx +14],eax
	pop	eax			;1 : ds
	mov	[edx + 2],ax
	pop	eax			;2 : es
	mov	[edx + 4],ax
	pop	eax			;3 : fs
	mov	[edx + 6],ax
	pop	eax			;4 : gs
	mov	[edx + 8],ax

	;�t���O�Z�[�u
	setc	al
	and	b [esp + 14h],0feh	;Cy�ȊO���o��
	or	b [esp + 14h],al	;Cy��������

	pop	edx
	pop	eax	;�����������̈�B�����ϐ��̈揜��
	pop	es
	iret


;------------------------------------------------------------------------------
;�E�G�C���A�X�Z���N�^�̍쐬�@AX=2513h
;------------------------------------------------------------------------------
;	bx = �G�C���A�X���쐬����Z���N�^
;	cl = �f�B�X�N���v�^�� +5 byte �ڂɃZ�b�g����l
;	ch = bit 6 �݈̂Ӗ��������AUSE����(16bit/32bit)���w��
;
	align	4
DOS_Ext_fn_2513h:
	push	ds
	push	edx
	push	ecx
	push	ebx
	push	eax	;�߂�l�𒼐ڏ������ނ̂ŁA�Ō�̐ς�

	push	d (F386_ds)	;
	pop	ds		;ds �ݒ�
	movzx	ebx,bx		;0 �g�����[�h

	call	search_free_LDTsel	;�󂫃Z���N�^����
	test	eax,eax			;�߂�l�m�F
	jz	short .fail		;0 �Ȃ玸�s

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

	pop	eax		;eax �ʒu�̃X�^�b�N�ǂݎ̂�
	pop	edx
	pop	ecx
	pop	ebx
	pop	ds
	clear_cy
	iret

	align	4
.fail:	mov	eax,8
.ret:	pop	edx	; eax�ǂݎ̂�
	pop	ebx
	pop	ecx
	pop	edx
	pop	ds
	set_cy
	iret


	align	4
.void:
	mov	eax,9		;�Z���N�^���s��
	jmp	short .ret


;------------------------------------------------------------------------------
;�E�Z�O�����g�����̕ύX�@AX=2514h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2514h:
	push	ecx
	push	ebx
	push	eax
	push	ds

	push	d (F386_ds)	;
	pop	ds		;ds �ݒ�

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
	align	4
DOS_Ext_fn_2515h:
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
;�EDOS����o�b�t�@�̃A�h���X�擾�@AX=2517h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_2517h:
	mov	ecx,F386_ds
	mov	 es,ecx
	mov	ebx,[es:call_buf_adr32]
	mov	ecx,[es:call_buf_adr16]

	; buffer size
	xor	ecx, ecx
	mov	 cl, b [es:call_buf_sizeKB]
	shl	ecx, 10

	clear_cy
	iret


;------------------------------------------------------------------------------
;�EDOS�������u���b�N�A���P�[�V�����@AX=25c0h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_25c0h:
	mov	ah,48h			;�������u���b�N�擾
	jmp	call_V86_int21		;DOS call


;------------------------------------------------------------------------------
;�EDOS�������u���b�N�̉���@AX=25c1h
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;�EMS-DOS�������u���b�N�̃T�C�Y�ύX�@AX=25c2h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_25c1h:
	push	eax
	mov	ah,49h			;�������u���b�N���
	jmp	short fn_Cxh_step

	align	4
DOS_Ext_fn_25c2h:			;�������u���b�N�̃T�C�Y�ύX
	push	eax
	mov	ah,49h			;DOS function
fn_Cxh_step:
	push	ecx			;gs
	push	ecx			;fs
	push	ecx			;es
	push	ecx			;ds
	push	d [cs:DOS_int21h_adr]	;�Ăяo���A�h���X / int 21h
	call	call_V86		;�ړI���[�`���� call
	jc	.fail			;���s

	add	esp,14h			;�X�^�b�N����
	pop	eax			;eax ����
	clear_cy
	iret

.fail:	add	esp,byte 14h + 4	;�X�^�b�N����
	set_cy
	iret


;------------------------------------------------------------------------------
;�EDOS�v���O�������q�v���Z�X�Ƃ��Ď��s  AX=25c3h
;------------------------------------------------------------------------------
	align	4
DOS_Ext_fn_25c3h:
	jmp	int_21h_4bh		;int 21h / 4bh �Ɠ���

;//////////////////////////////////////////////////////////////////////////////
