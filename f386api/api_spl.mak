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
LINKOP = -exe f386.api -stack 100h -maxdata 100h -nomap

#------------------------------------------------------------------------------

all : f386.api

api_spl.obj: api_spl.asm
	$(ASM) $(ASMOP) api_spl.asm

f386.api: api_spl.obj f386alib.obj
	$(LINK) api_spl f386alib $(LINKOP)
