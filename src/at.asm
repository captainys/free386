;******************************************************************************
;�@Free386	PC/AT dependent code
;******************************************************************************
;
BITS	16
;==============================================================================
; check maachine type is PC/AT
;==============================================================================
;Ret	Cy=0	true
;	Cy=1	false
;
check_AT_16:
	xor	ah,ah		;AH = 0
%rep	4		;������J��Ԃ�
	in	al,41h		;�^�C�} �J�E���^#01
 	xor	ah,al		;xor
	in	al,42h		;�^�C�} �J�E���^#02
 	xor	ah,al		;xor
%endrep

 	test	ah,ah		;�l�m�F
	jz	.not_AT		;0 �Ȃ� AT �ł͂Ȃ�
	clc	;����
	ret

.not_AT:
	stc	;���s
	ret

;==============================================================================
; init PC/AT in 16bit mode
;==============================================================================
proc init_AT_16
	ret


BITS	32
;==============================================================================
;��PC/AT�݊��@�̏����ݒ�
;==============================================================================
proc init_AT_32
	mov	ebx,offset AT_memory_map	;�������̃}�b�v
	call	map_memory			;

	mov	esi,offset AT_selector_alias	;�G�C���A�X�̍쐬
	call	make_aliases			;

	;/// VESA3.0 �̊m�F ////////////////////////
	mov	ax,4f00h	;install VESA?
	mov	di,[work_adr]	;�o�b�t�@�A�h���X (�{�[�h��/Ver �ȂǑ������Ԃ�)
	V86_INT	10h		;VGA/VESA BIOS call
	cmp	ax,004fh	;�T�|�[�g����Ă�H
	jne	.no_VESA	;�Ⴆ�� VESA �Ȃ�(jmp)
	jmp	.no_VESA	;for debug**************************

	;/// VESA3.0 Protect Mode Bios �̌��� //////
	push	b (DOSMEM_sel)
	pop	es

	mov	eax,'PMID'	;In other ASM 'DIMP'
	mov	edi,0c0000h	;VESA-BIOS
	mov	edx,0c8000h	;�����I���A�h���X

	align	4
	;*** �ᑬ�Ȍ������[�`��(���ǋ���) ***
.loop:	cmp	[es:edi],eax	;�v���e�N�g���[�h�C���t�H���[�V�����u���b�N�H
	je	.check_PMIB	;
	inc	edi
	cmp	edi,edx		;�I���A�h���X�H
	jne	.loop
	jmp	.no_VESA	;�����ł���

	align	4
.check_PMIB:			;�`�F�b�N�T���̊m�F
	mov	ecx,13h
	mov	al,[es:edi]	;�擪

	align	4
.check_loop:
	add	al,[es:edi+ecx]	;���Z
	loop	.check_loop
	test	al,al		;al=0?
	jnz	.loop		;check sum error �Ȃ瑱������

	;/// VESA3.0 Protect Mode Interface���� ///
	xor	esi,esi
	call	AT_VESA30_alloc	;VESA3.0 PMode-BIOS �̔z�u

	align	4
.no_VESA:
	ret


;------------------------------------------------------------------------------
;��VESA 3.0 Protect Mode Interface �̃Z�b�g�A�b�v
;------------------------------------------------------------------------------
	align	4
AT_VESA30_alloc.exit:
	ret

	align	4
AT_VESA30_alloc:
	and	edi,7fffh		;��ʃr�b�g�𖳎�
	mov	[VESA_PMIB],edi		;�v���e�N�g���[�h�\���̂� offset

	mov	ecx,64/4 +1 +VESA_buf_size	;64KB + 4KB + buf �̃�����
	call	alloc_RAM			;�������A���P�[�V����
	jc	.exit				;�G���[�Ȃ� exit

	mov	edi,[work_adr]		;���[�N�A�h���X���[�h

	;/// VESA �Ăяo�����̃��[�N ///
	mov	d [edi  ],esi		;�x�[�X�A�h���X
	mov	d [edi+4],VESA_buf_size	;limit�l
	mov	d [edi+8],0200h		;R/X / �������x��=0
	mov	eax,VESA_buf_sel	;VESA buffer segment
	call	make_mems_4k		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;/// VESA Code Selector ////////
	add	esi,(VESA_buf_size+1)*1000h	;4KB �]���ɂ��炷
	mov	d [edi  ],esi		;�x�[�X�A�h���X
	mov	d [edi+4],0ffffh	;limit�l 64KB (32KB �ł̓_��)
	mov	d [edi+8],1a00h		;R/X 286 / �������x��=0
	mov	eax,VESA_cs		;VESA code segment
	call	make_mems		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;/// VESA Data Selector ////////
	mov	d [edi+8],1200h		;R/W 286 / �������x��=0
	mov	eax,VESA_ds		;VESA data segment(cs alias)
	call	make_mems		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;/// VESA �� Selector ////////
	sub	esi,1000h		;4KB�߂�
	mov	edi,[work_adr]		;���[�N�A�h���X���[�h
	mov	d [edi  ],esi		;�x�[�X�A�h���X
	mov	d [edi+4],0		;limit�l (4KB)
	mov	d [edi+8],0200h		;R/W / �������x��=0
	mov	eax,VESA_ds2		;VESA data segment
	call	make_mems_4k		;�������Z���N�^�쐬 edi=�\���� eax=sel

	;/// VESA ���f�[�^�N���A /////
	mov	eax,VESA_ds2		;���f�[�^�Z���N�^
	mov	es ,eax			;�Z���N�^�ݒ�
	xor	edi,edi			;edi = 0
	mov	ecx,600h / 4		;600h /4
	xor	eax,eax			;0 �N���A
	rep	stosd			;�h��ׂ�

	;/// VESA-BIOS �̃R�s�[ ////////
	mov	eax,VESA_ds		;VESA BIOS �̏������ݐ�
	mov	ebx,DOSMEM_sel		;VESA BIOS �]�����Z���N�^
	mov	es ,eax			;�Z���N�^�ݒ�
	mov	ds ,ebx			;
	xor	edi,edi			;edi = 0
	mov	esi,0c0000h		;VESA BIOS
	mov	ecx, 10000h / 4		;64KB /4
	rep	movsd

	mov	ebp,F386_ds		;
	mov	ds ,ebp			;ds ����
	mov	edi,[VESA_PMIB]		;PM BIOS �\����

	;/// PM-BIOS �\���� �ւ̐ݒ� ///
	mov	w [es:edi+08h],VESA_ds2	;���Z���N�^
	mov	w [es:edi+0ah],VESA_A0	;a0000h - bffffh
	mov	w [es:edi+0ch],VESA_B0	;b0000h - bffffh
	mov	w [es:edi+0eh],VESA_B8	;b8000h - bffffh
	mov	w [es:edi+10h],VESA_ds	;VESA cs alias
	mov	b [es:edi+12h],1	;in Protect Mode

	;*** far return op-code �̒���t�� ****
	mov	w [es:0fffeh],0cb66h	;32bit far return

	;*** VESA-BIOS �̏����� ********
	movzx	ecx,w [es:edi+6]	;���������[�`���ʒu
	push	ds			;ds �ۑ�
	push	cs
	push	d (offset .VESA_ret0)	;�߂胉�x��
	push	d (0fffeh)		;far return op-code �̂���A�h���X
	push	d (VESA_cs)
	push	ecx			;���������[�`��
	retf				;���[�`���R�[��
	;���ӁI
	;�@VESA3.0 �� Protect Mode Bios �́ALinux �Ȃǂ̃Z�O�����g��
	;�g�p���Ȃ�����z�肵�Ă��A(o32) near return ����悤�ɂȂ��Ă���(;_;

.VESA_ret0:
	mov	es,[esp]		;es = F386_ds
	pop	ds			;ds ����
	PRINT	VESA30_init		;�����������̃��b�Z�[�W

	;----------------------------------------------------------------------
	;VESA bios call �̏���
	;----------------------------------------------------------------------
	mov	ebx,offset VESA_call_point	;call ���߈ʒu
	mov	edx,offset VESA_call_point2	;
	mov	eax,[VESA_PMIB]			;�v���e�N�g���[�h�\���̂̈ʒu
	add	eax,byte 4			;entry point �̈ʒu
	mov	[ebx-2],ax			;call ���̎Q�ƃ������̏�������
	mov	[edx-2],ax			;

	push	es
	mov	eax,VESA_ds			;VESA�f�[�^�Z�O�����g(cs alias)
	mov	es ,eax				;es �ݒ�
	mov	edi,VESA_call_adr		;call �v���O�����ݒ�ʒu
	mov	esi,offset VESA_call		;�R�s�[��

	mov	ecx,(VESA_call_end-VESA_call)/4	;���[�`���T�C�Y /4
	rep	movsd				;call-code �̓]��

	;----------------------------------------------------------------------
	;VRAM �̒���t��
	;----------------------------------------------------------------------
	push	cs
	push	d (offset .VESA_ret1)	;�߂胉�x��
	push	d (VESA_cs)		;

	mov	eax,offset VESA_call2 + VESA_call_adr
	sub	eax,offset VESA_call	;�����Z�o
	push	eax			;call-code �A�h���X

	mov	ebx,VRAM_sel		;VRAM_sel
	mov	 es,ebx			;es �� VRAM�Z���N�^�ݒ�
	mov	edx,VRAM_padr		;�ݒ肷�镨���A�h���X
	mov	 cx,dx			;cx = bit  0-15
	shr	edx,16			;dx = bit 31-16

	mov	ax,4f07h		;�����������̐ݒ�
	xor	ebx,ebx			;bl=bh=0
	retf				;���[�`���R�[��

	align	4
.VESA_ret1:
	pop	es
	ret

VESA_entry:
	dd	VESA_call_adr
	dw	VESA_cs

	;------------------------------------------------
	;VESA bios call �̂��߂̃��[�`�� (Copy ���Ďg��)
	;------------------------------------------------
	align	4
BITS	16
VESA_call:
	push	es
	push	w (VESA_buf_sel)	;es = �o�b�t�@�Z���N�^
	pop	es			;

	xor	di,di			;es:di = buffer
	push	di	;=push 0	;32bit return �𔭍s���Ă�̂� >VESA
	call	word [cs:0000h]		;VESA-BIOS call
VESA_call_point:
	pop	es
	db	66h			;size pureffix (���̖��߂�use32�ŉ���)
	retf				;32bit retf

	align	4
	;/// es�w�� call ///////////////
VESA_call2:
	push	w 0
	call	word [cs:0000h]
VESA_call_point2:
	db	66h
	retf

	align	4			;�����s�I�I
VESA_call_end:
BITS	32


BITS	32
;==============================================================================
; exit process for PC/AT in 32bit
;==============================================================================
proc exit_AT_32
	ret


BITS	16
;==============================================================================
; exit process for PC/AT in 16bit
;==============================================================================
proc exit_AT_16
	ret


;==============================================================================
;��AT�ŗL�̃���������ݒ�p�f�[�^
;==============================================================================

VESA30_init	db	'VESA3.0 Protect Mode BIOS inisalized!!',13,10,'$'

	align	4
VESA_PMIB	dd	0		;VESA Protect-Mode-Info-Block (�\����)

AT_memory_map:
		; sel  , base     ,   pages -1, type/level
	dd	100h   ,0ffff0000h,    64/4 -1, 0a00h	;R/X : boot-ROM
	dd	VESA_A0,   0a0000h,    64/4 -1, 0200h	;R/W : for VESA 3.0
	dd	VESA_B0,   0b0000h,    64/4 -1, 0200h	;R/W : for VESA 3.0
	dd	VESA_B8,   0b8000h,    32/4 -1, 0200h	;R/W : for VESA 3.0
	dd	VRAM_sel,VRAM_padr,VRAM_size-1, 0200h	;R/W : VRAM
	dd	0	;end of data

	align	4
AT_selector_alias:
		;ORG, alias, type/level
	dd	100h,  108h,  0000h	;boot-ROM
	dd	120h,  128h,  0200h	;VRAM alias
	dd	120h,  104h,  0200h	;VRAM alias
	dd	128h,  10ch,  0200h	;VRAM alias
	dd	0			;end of data


