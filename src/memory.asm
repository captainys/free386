;******************************************************************************
; Free386 memory functions
;******************************************************************************
;[TAB=8]
;
%include	"macro.inc"
%include	"f386def.inc"

%include	"start.inc"
%include	"free386.inc"

;******************************************************************************
seg16	text class=CODE align=4 use16
;******************************************************************************
; heap memory functions
;******************************************************************************
;	in	ax = size (byte). recommended in multiples of 16.
;		cl = error code (for allocation failure)
;	out	di = offset
;
proc2 heap_malloc
	mov	di,[free_heap_top]	;��ʋ󂫃��������蓖��
	add	[free_heap_top],ax	;�T�C�Y�����Z
	jc	heap_alloc_error
	jmp	short check_heap_mem

proc2 stack_malloc			;���ʂ���̃��������蓖��
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
	ja	heap_alloc_error
	ret
heap_alloc_error:
	mov	ah, cl			;error code
	jmp	error_exit_16

;------------------------------------------------------------------------------
; heap memory functions with zero fill
;------------------------------------------------------------------------------
proc2 heap_calloc
	push	w (mem_clear)		;�߂胉�x��
	jmp	heap_malloc

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
	ret

;******************************************************************************
; DOS memory functions
;******************************************************************************
;------------------------------------------------------------------------------
;alloc memory from DOS
;------------------------------------------------------------------------------
proc2 init_dos_malloc
	xor	eax, eax
	xor	ebx, ebx

	mov	ah, 48h
	mov	bx, 0ffffh
	int	21h
	cmp	ax,08h
	jne	.not_alloc

	mov	ax, [resv_real_memKB]
	shl	ax, 10 - 4		; KB to paragrah
	cmp	bx, ax			; free memory < reserved memory
	jbe	.not_alloc		; jmp

	sub	bx, ax			; bx = can use memory(para)
	dec	bx			; for MCB (1para)
	jz	.not_alloc

	mov	ah, 48h
	int	21h
	jc	.not_alloc

	mov	[DOS_alloc_seg],  ax	;allocate DOS memory segment
	mov	[DOS_alloc_sizep],bx	;allocate DOS memory size(para)
	mov	bp, bx

	mov	dx, ax
	add	ax, 000ffh		;for 4KB fragment
	and	ax, 0ff00h		;mask
	mov	cx, ax			;cx = original seg
	sub	cx, dx			;cx = top frag paras
	sub	bx, cx			;bx = size - frag size

	shl	eax, 4			;para to linear address
	mov	[DOS_mem_ladr], eax	;save

	mov	cx, bx
	and	bx, 0ff00h		;4KB unit
	sub	cx, bx			;cx = bottom frag paras
	mov	dx, cx			;dx = save
	shr	ebx, 12 - 4		;para to page
	mov	[DOS_mem_pages],ebx	;save

	test	cx, cx
	jz	.skip_shrink

	sub	bp, cx			;bp = new para size
	mov	bx, bp			;bx = new para size

	push	es
	mov	es, [DOS_alloc_seg]
	mov	ah, 4ah
	int	21h			;Shrink memory block
	pop	es
	jc	.skip

	mov	[DOS_alloc_sizep],bx	;new dos memory size(para)
	shr	dx, 10 - 4		;para to KB
	add	b [resv_real_memKB],dl	;Reserved memory increase

.skip:
.skip_shrink:
.not_alloc:
	ret

;------------------------------------------------------------------------------
;alloc DOS memory page
;------------------------------------------------------------------------------
;	in	 ax = page
;		 cl = error code (for allocation failure)
;	out	edi = liner address
;
proc2 malloc_dos_page
	cmp	[DOS_mem_pages], ax
	jb	.error

	push	ebx
	sub	[DOS_mem_pages], ax
	movzx	ebx, ax
	shl	ebx, 12		; page to byte

	mov	eax, [DOS_mem_ladr]
	add	[DOS_mem_ladr], ebx
	pop	ebx
	ret

.error:
	mov	ah, cl
	jmp	error_exit_16


;******************************************************************************
; General purpose buffer function
;******************************************************************************
BITS	32
;==============================================================================
; Get general purpose buffer
;==============================================================================
; IN	ds = any
; Ret	Cy = 0 Success
;		edi = buffer pointer
;	Cy = 1 Fail
;		edi = destroy
;
proc4 get_gp_buffer_32
	push	eax
	push	ebx
	push	ds
	pushf

	push	F386_ds
	pop	ds

	cli
	mov	ebx, [gp_buffer_free_bitmap]	; free bitmap
	bsf	eax, ebx			; search '1' bit from ebx low bit.
	jz	.fail				; not found
	cmp	eax, GP_BUFFERS
	jae	.fail

	btr	ebx, eax			; reset eax bit in ebx
	mov	[gp_buffer_free_bitmap], ebx	; save

	mov	edi, [gp_buffer_table + eax*4]

	popf
	clc
.ret:
	pop	ds
	pop	ebx
	pop	eax
	ret
.fail:
	popf
	stc
	jmp	.ret

;==============================================================================
; free general purpose buffer
;==============================================================================
; IN	edi = buffer pointer
;	 ds = any
; Ret	 Cy = 0 Success
;	 Cy = 1 Fail
;
proc4 free_gp_buffer_32
	push	eax
	push	ebx
	push	ds

	push	F386_ds
	pop	ds

	mov	ebx, gp_buffer_table
	xor	eax, eax
.loop:
	cmp	[ebx], edi
	je	.found
	add	ebx, 4
	inc	eax
	cmp	al, GP_BUFFERS
	jb	.loop

	; fail
	stc
	jmp	.ret

.found:
	bts	[gp_buffer_free_bitmap], eax	; set free bit

	clc
.ret:
	pop	ds
	pop	ebx
	pop	eax
	ret

;==============================================================================
; clear general purpose buffer
;==============================================================================
proc4 clear_gp_buffer_32
	mov	d [gp_buffer_free_bitmap], 0ffff_ffffh
	ret


;******************************************************************************
; switch cpu mode stack allocation
;******************************************************************************
BITS	32
;==============================================================================
; allocation from heap
;==============================================================================
; in	-
; out	eax	new stack pointer
;
proc4 alloc_sw_stack_32
	pushf

	cli
	cmp	b [sw_cpumode_nest], SW_max_nest
	jae	short .error
	inc	b [sw_cpumode_nest]

	mov	eax, [sw_stack_bottom]
	sub	d [sw_stack_bottom], SW_stack_size

	popf
	ret

.error:
	mov	ah, 14
	jmp	error_exit_32

;==============================================================================
; free SW stack memory
;==============================================================================
;
proc4 free_sw_stack_32
	pushf

	cli
	cmp	b [sw_cpumode_nest], 0
	je	short .error
	dec	b [sw_cpumode_nest]

	add	d [sw_stack_bottom], SW_stack_size

	popf
	ret

.error:
	mov	ah, 15
	jmp	error_exit_32

;==============================================================================
; clear SW stack
;==============================================================================
proc4 clear_sw_stack_32
	push	eax
	mov	eax, [sw_stack_bottom_orig]
	mov	[sw_stack_bottom], eax

	mov	b [sw_cpumode_nest], 0
	pop	eax
	ret

;==============================================================================
; allocation from heap (16bits)
;==============================================================================
; in	-
; out	ax	new stack pointer
;
BITS	16
proc4 alloc_sw_stack_16
	pushf

	cli
	cmp	b [sw_cpumode_nest], SW_max_nest
	jae	short .error
	inc	b [sw_cpumode_nest]

	mov	eax, [sw_stack_bottom]
	sub	d [sw_stack_bottom], SW_stack_size

	popf
	ret

.error:
	xor	ax, ax
	popf
	ret

;==============================================================================
; free SW stack memory
;==============================================================================
;
proc4 free_sw_stack_16
	pushf

	cli
	cmp	b [sw_cpumode_nest], 0
	je	short .error
	dec	b [sw_cpumode_nest]

	add	d [sw_stack_bottom], SW_stack_size
.error:
	popf
	ret


;******************************************************************************
; DATA
;******************************************************************************
segdata	data class=DATA align=4

global	free_heap_top
global	free_heap_bottom
global	DOS_mem_ladr
global	DOS_mem_pages
global	DOS_alloc_sizep		; use only memory information
global	DOS_alloc_seg		; use only memory information

global	gp_buffer_table
global	sw_stack_bottom
global	sw_stack_bottom_orig

free_heap_top		dd	offset end_adr	; heap memory top    offset
free_heap_bottom	dd	10000h & 0ffffh	; heap memory bottom offset+1

DOS_alloc_seg		dd	0		;allocate DOS memory segment
DOS_alloc_sizep		dd	0		;allocate DOS memory size(para)
DOS_mem_ladr		dd	0		;can use DOS memory linear address
DOS_mem_pages		dd	0		;can use DOS memory pages

gp_buffer_free_bitmap	dd	0ffffffffh	; buffer free flags
gp_buffer_table:
  times	GP_BUFFERS	dd	0		; address

sw_cpumode_nest		dd	0		; Switch cpu mode nest counter
sw_stack_bottom		dd	0		; stack pointer
sw_stack_bottom_orig	dd	0		; original value for reset (AX=2501h)

;******************************************************************************
