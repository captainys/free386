#----------------------------------------------------------------------------
#
#	use	NASM 0.98+towns02 �ȍ~
#
#----------------------------------------------------------------------------

#///////////////////////////////////////////////////////////////////
# free386 �� PATH386 �́AEXE386 �� PATH �̎��������@�\�������Ă܂��B

#ASM  =run386 -nocrt e:\tool\nasm\nasm.exp
#ASM  =exe386 nasm.exp
ASM  =free386 nasm
ASMOP=-f pharlap


#///////////////////////////////////////////////////////////////////
#High-C �t���� linker ���g�p����ꍇ
#
LINK   = 386link
LINKOP = -exe test_api.exp -stack 1000h -maxdata 1000h

#------------------------------------------------------------------------------

all : test_api.exp

test_api.obj: test_api.asm
	$(ASM) $(ASMOP) test_api.asm

test_api.exp: test_api.obj
	$(LINK) test_api $(LINKOP)
