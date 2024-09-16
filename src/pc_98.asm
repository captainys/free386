;******************************************************************************
;�@Free386	PC-9801/9821 dependent code
;******************************************************************************
;
; Written by kattyo
;
; 2001/02/25 256�F���[�h�������ǉ�
; 2001/02/25 256�F���[�h�������̎蔲�����C��
;
seg16	text class=CODE align=4 use16
;==============================================================================
;��PC-98 �ȈՃ`�F�b�N
;==============================================================================
;Ret	Cy=0	PC-98 ���Ǝv��
;	Cy=1	PC-98 ����Ȃ��\�����傫��
;
proc2 check_PC98_16
	xor	bx,bx
	mov	cx,6
	; Do not use multiples of 4.
	; "multiple of 4" is result 0 on timer#01/02
.loop:
	in	al,71h		;timer #00
	xor	bl,al		;xor
	in	al,73h		;timer #01
	xor	bh,al		;xor
	loop	.loop

 	test	bx,bx
 	jz	.not_pc98
 	clc
 	ret
.not_pc98:
	stc
	ret

	;*** �d�g�݉�� ***
	;�^�C�}�͂������ω����Ă�̂ŁA���x�ǂ݂����Ă��ω����Ȃ����
	;����I/O �� �^�C�}������ = PC-98 ���ƍl����B

;==============================================================================
; init PC-98x1 in 16bit mode
;==============================================================================
proc2 init_PC98_16
	ret


BITS	32
;==============================================================================
;��PC-98x1 �̏����ݒ�
;==============================================================================
proc4 init_PC98_32
	;; 16 �F VRAM �����j�A�A�h���X��ɘA���ɒ���t��
	mov	esi, VRAM_16padr	;����t���惊�j�A�A�h���X = RGB GVRAM
	mov	edx, 0000A8000h		;����t���镨���A�h���X
	mov	ecx, 24			;�y�[�W��
	call	set_physical_memory
	
	mov	esi, VRAM_16padr + 24*4096	;A
	mov	edx, 0000E0000h
	mov	ecx, 8
	call	set_physical_memory
	
	mov	eax, 0120h			;���j�A�A�h���X�̃}�b�v
	mov	edi,[work_adr]			;���[�N
	mov	d [edi  ],VRAM_16padr		;���j�A�A�h���X
	mov	d [edi+4],32			;32*4 = 128 KB
	mov	d [edi+8],0200h			;R/W
	call	make_selector_4k
	
	;; CG Window �� e00a5000 �ɒ���t��
	mov	esi, VRAM_CGW		;����t���惊�j�A�A�h���X = RGB GVRAM
	mov	edx, 0000A4000h		;����t���镨���A�h���X
	mov	ecx, 1			;�y�[�W��
	call	set_physical_memory
	
	mov	eax, 0138h			;���j�A�A�h���X�̃}�b�v
	mov	edi,[work_adr]			;���[�N
	mov	d [edi  ],VRAM_CGW		;���j�A�A�h���X
	mov	d [edi+4],1			;1*4 = 4 KB
	mov	d [edi+8],0200h			;R/W
	call	make_selector_4k
	
	
	;; TVRAM �� e00a0000 �ɒ���t��
	mov	esi, VRAM_TEXT		;����t���惊�j�A�A�h���X = RGB GVRAM
	mov	edx, 0000A0000h		;����t���镨���A�h���X
	mov	ecx, 4			;�y�[�W��
	call	set_physical_memory
	
	mov	eax, 0130h			;���j�A�A�h���X�̃}�b�v
	mov	edi,[work_adr]			;���[�N
	mov	d [edi  ],VRAM_TEXT		;���j�A�A�h���X
	mov	d [edi+4],4			;4*4 = 16 KB
	mov	d [edi+8],0200h			;R/W
	call	make_selector_4k
	
	
	;; �����������̃}�b�s���O
	
	mov	ebx,offset PC98_memory_map	;�����A�h���X�̃}�b�v
	call	map_memory			;
	jnc	.success

	mov	ah, 17		; not enough page table memory
	jmp	error_exit_32
.success:

	;; �G�C���A�X�쐬

	mov	esi,offset PC98_selector_alias	;�G�C���A�X�̍쐬
	call	make_aliases			;

.c256mode_not_found:

	ret


;------------------------------------------------------------------------------
;��PC-98x1 �̏I������
;------------------------------------------------------------------------------
proc4 exit_PC98_32
	mov	bl,[reset_CRTC]		;reset / 1 = ������, 2 = CRTC�̂�
	test	bl,bl			;0 ?   / 3 = �����F��
	jz	.no_reset		;�Ȃ�Ώ���������

	;*** CRTC �̏����� ***
	cmp	bl,3			;�����F�� ?
	jne	.res_c			; �łȂ���� jmp

	;*** 256���[�h�`����m�F *******
	mov	edi,[GDT_adr]		;GDT �A�h���X���[�h
	mov	esi,[LDT_adr]		;LDT �A�h���X���[�h
	mov	 cl,[edi + 128h   +5]	;GDT:VRAM (256)
	or	 cl,[esi + 10ch-4 +5]	;LDT:VRAM (256)
	test	 cl,01			;��̂ǂꂩ�� �A�N�Z�X���� ?
	jz	.no_reset_CRTC		;�Ȃ���� jmp

.res_c:	call	PC98_DOS_CRTC_init	;CRTC ������
.no_reset_CRTC:

	;*** VRAM �̏����� ***
	;mov	bl,[reset_CRTC]
	cmp	bl,2			;VRAM �͏��������Ȃ� ?
	je	.no_reset_VRAM		;��������� jmp

	cmp	bl,1			;�K�������� ?
	je	.res_v256		;��������� jmp
	test	cl,01			;256�FVRAM�� �A�N�Z�X���� ?
	jz	.chk_16VRAM		;�Ȃ���� jmp

.res_v256:
	push	esi
	push	edi
	mov	eax,128h		;VRAM �Z���N�^
	mov	  es,ax			;Load
	xor	edi,edi			;edi = 0
	mov	ecx,512*1024 / 4	;512 KB
	xor	eax,eax			;�h��Ԃ��l
	rep	stosd			;0 �N���A
	pop	edi
	pop	esi

.chk_16VRAM:
	cmp	bl,1			;�K�������� ?
	je	.res_v16		;��������� jmp

	mov	 al,[edi + 120h   +5]	;GDT:VRAM (16)
	or	 al,[esi + 104h-4 +5]	;LDT:VRAM (16)
	test	 al,01			;16�FVRAM�� �A�N�Z�X���� ?
	jz	.no_reset_VRAM		;0 �Ȃ� VRAM ���g�p (jmp)

.res_v16:
	mov	eax,120h		;VRAM �Z���N�^
	mov	  es,ax			;Load
	xor	edi,edi			;edi = 0
	mov	ecx,128*1024 / 4	;128 KB
	xor	eax,eax			;�h��Ԃ��l
	rep	stosd			;0 �N���A
.no_reset_VRAM:
.no_reset:
	ret


;------------------------------------------------------------------------------
;��CRTC ������
;------------------------------------------------------------------------------
	align	4
PC98_DOS_CRTC_init:
	;------------------------------------------
	; 256 �F���[�h�̏ꍇ�� 16 �F���[�h�ɖ߂�
	;------------------------------------------
	mov	al, 007h	;���[�h�ύX��
	out	06Ah, al
	mov	al, 020h	;�W���O���t�B�b�N�X���[�h
	out	06Ah, al
	mov	al, 006h	;���[�h�ύX�s��
	out	06Ah, al

	;/// ��ʕ\����~ //////////////
%if STOP_GVRAM
	mov	al, 00Ch
	out	0A2h, al	;��ʕ\����~
%endif
	ret


BITS	16
;==============================================================================
; exit process for PC/AT in 16bit
;==============================================================================
proc2 exit_PC98_16
	ret



;******************************************************************************
; DATA
;******************************************************************************
segdata	data class=DATA align=4

	align	4
PC98_memory_map:
		;sel, base     ,  pages,  type
	dd	128h, 0fff00000h, 512/4,  0200h	;R/W : VRAM (256c)
;	dd	160h, 020000000h, 4096/4, 0200h	;R/W : VRAM (TGUI vram)
;	dd	168h, 020400000h, 64/4,   0200h	;R/W : VRAM (TGUI mmio)
;	dd	170h, 020800000h, 4096/4, 0200h	;R/W : VRAM (TGUI vram)
	dd	0	;end of data

	align	4
PC98_selector_alias:
		;ORG, alias, type
	dd	120h,  104h,  0200h	;VRAM (16)
	dd	128h,  10ch,  0200h	;VRAM (256)
	dd	130h,  114h,  0200h	;TVRAM
	dd	0	;end of data

