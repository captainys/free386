;******************************************************************************
; Free386 memory functions
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"
%include	"free386.inc"

segment	text align=4 class=CODE use16
;******************************************************************************
; heap memory functions
;******************************************************************************
;	in	ax = size (byte). recommended in multiples of 16.
;	out	di = offset
;
proc heap_malloc
	cmp	ax,[frag_mem_size]	;�f�Љ��������̃T�C�Y�Ɣ�r
	ja	.not_frag_mem		;if �����傫�� jmp

	mov	di,[frag_mem_offset]	;�f�Љ��������̊��蓖��
	sub	[frag_mem_size  ],ax	;���蓖�Ă��������ʂ�����
	add	[frag_mem_offset],ax	;�󂫃������������|�C���^���X�V
	ret

	align	4
.not_frag_mem:				;��ʋ󂫃������̒P���Ȋ��蓖��
	mov	di,[free_heap_top]	;��ʋ󂫃��������蓖��
	add	[free_heap_top],ax	;�T�C�Y�����Z
	jmp	short check_heap_mem

	align	4
proc stack_malloc			;���ʂ���̃��������蓖��
	mov	di,[free_heap_bottom]	;�ŉ��ʋ󂫃�����
	sub	[free_heap_bottom],ax	;�V���Ȓl���L�^
	; jmp	short check_heap_mem

check_heap_mem:
	push	ax
	push	bx
	mov	ax,[free_heap_top]
	mov	bx,[free_heap_bottom]
	dec	ax
	dec	bx
	cmp	ax,bx
	pop	bx
	pop	ax
	ja	.error
	ret
.error:
	mov	ah, 25h			;error code
	jmp	error_exit_16

;------------------------------------------------------------------------------
; heap memory functions with zero fill
;------------------------------------------------------------------------------
proc heap_calloc
	push	w (mem_clear)		;�߂胉�x��
	jmp	heap_malloc

	align	4
proc stack_calloc
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



;******************************************************************************
; General purpose buffer function
;******************************************************************************
BITS	32
;==============================================================================
; Get general purpose buffer
;==============================================================================
; out	eax = buffer pointer, 0 is failed
;
proc get_gp_buffer_32
	pushfd
	push	ebx
	push	ecx
	push	ds

	mov	cx, F386_ds
	mov	ds, cx

	cli
	mov	eax, [gp_buffer_remain]
	test	eax, eax
	jz	.fail

	dec	eax
	mov	[gp_buffer_remain], eax

	mov	eax, 80000000h
	mov	ebx, [gp_buffer_used]
	xor	ecx, ecx
.loop:
	inc	ecx
	cmp	cl, 32
	jz	short .fail
	rol	eax, 1
	test	ebx, eax
	jnz	short .loop

	or	ebx, eax
	mov	[gp_buffer_used], ebx	; set used flag

	mov	eax, [gp_buffer_table -4 + ecx*4]
.ret:
	pop	ds
	pop	ecx
	pop	ebx
	popfd
	ret
.fail:
	xor	eax, eax
	jmp	short .ret

;==============================================================================
; free general purpose buffer
;==============================================================================
; in	eax = buffer pointer
; out	eax = 0 success
;	    = 1 failed
;
proc free_gp_buffer_32
	pushfd
	push	ebx
	push	ecx
	push	ds

	mov	cx, F386_ds
	mov	ds, cx

	mov	ebx, gp_buffer_table
	xor	ecx, ecx
.loop:
	cmp	[ebx], eax
	je	.found
	add	ebx, 4
	inc	ecx
	cmp	cl, GP_BUFFERS
	jb	.loop
	jmp	.fail

.found:
	mov	ebx, [gp_buffer_used]
	btc	ebx, ecx	; cy <- ecx bit and ecx bit revers
	jnc	.fail		; used flag not set

	mov	[gp_buffer_used], ebx
	inc	d [gp_buffer_remain]

	xor	eax, eax
.ret:
	pop	ds
	pop	ecx
	pop	ebx
	popfd
	ret

.fail:
	mov	eax, 1
	jmp	short .ret


BITS	16
;==============================================================================
; Get general purpose buffer (16bits)
;==============================================================================
; out	ax = buffer pointer, 0 is failed
;
proc get_gp_buffer_16
	pushf
	push	ebx
	push	ecx

	cli
	mov	ax, [gp_buffer_remain]
	test	ax, ax
	jz	.fail

	dec	ax
	mov	[gp_buffer_remain], ax

	mov	eax, 80000000h
	mov	ebx, [gp_buffer_used]
	xor	ecx, ecx
.loop:
	inc	cx
	cmp	cl, 32
	jz	short .fail
	rol	eax, 1
	test	ebx, eax
	jnz	short .loop

	or	ebx, eax
	mov	[gp_buffer_used], ebx	; set used flag

	mov	ax, [gp_buffer_table -4 + ecx*4]
.ret:
	pop	ecx
	pop	ebx
	popf
	ret
.fail:
	xor	ax, ax
	jmp	short .ret

;==============================================================================
; free general purpose buffer (16bits)
;==============================================================================
; in	ax = buffer pointer
; out	ax = 0 success
;	   = 1 failed
;
proc free_gp_buffer_16
	pushf
	push	ebx
	push	ecx

	mov	bx, gp_buffer_table
	xor	ecx, ecx
.loop:
	cmp	[bx], ax
	je	.found
	add	bx, 4
	inc	cx
	cmp	cl, GP_BUFFERS
	jb	.loop
	jmp	.fail

.found:
	mov	ebx, [gp_buffer_used]
	btc	ebx, ecx	; cy <- ecx bit and ecx bit revers
	jnc	.fail		; used flag not set

	mov	[gp_buffer_used], ebx
	inc	w [gp_buffer_remain]

	xor	ax, ax
.ret:
	pop	ecx
	pop	ebx
	popf
	ret

.fail:
	mov	ax, 1
	jmp	short .ret


;******************************************************************************
; DATA
;******************************************************************************
segment	data align=4 class=CODE use16
group	comgroup text data

global	frag_mem_offset
global	frag_mem_size
global	free_heap_top
global	free_heap_bottom
global	gp_buffer_remain
global	gp_buffer_table

frag_mem_offset		dd	offset end_adr	; �v���O�������[�i�f�[�^�̈�܂ށj
frag_mem_size		dd	0		; �����ŃZ�[�u
free_heap_top		dd	offset end_adr	; ���R�Ɏg�����ԏ�ʂ̃�����
free_heap_bottom	dd	10000h & 0ffffh	; ���R�Ɏg�����ԉ��ʂ̃�����+1

gp_buffer_remain	dd	GP_BUFFERS	; remain buffers
gp_buffer_used		dd	0		; buffer used flag
gp_buffer_table:
  times	GP_BUFFERS	dd	0		; address


;******************************************************************************
