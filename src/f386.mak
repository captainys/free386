#----------------------------------------------------------------------------
#Free386 MAKEFILE
#
#	use	NASM 0.98+towns02 or +towns03 only
#	linker	MS-Link
#	com	exe2bin
#
#----------------------------------------------------------------------------

#
#���{�� NASM 0.98 ���ł� %include ���߂̃o�O�ɂ��A�Z���u�����Ƀn���O���܂��B
#�@free386.asm �� %include ���߂����炵�Ă������� -> free386.asm �ɓ�������
#

#///////////////////////////////////////////////////////////////////
# free386 �� PATH386 �́AEXE386 �� PATH �̎��������@�\�������Ă܂��B

#ASM  =run386 -nocrt e:\tool\nasm\nasm.exp
#ASM  =exe386 nasm.exp
ASM  =free386 nasm
ASMOP=-f obj


#///////////////////////////////////////////////////////////////////
#MS linker ���g�p����ꍇ
#
LINK    = link
MSLINKOP= ,free386.exe,nul,,nul

#///////////////////////////////////////////////////////////////////
#Turbo linker ���g�p����ꍇ
#
#LINK    = link
#LINKOP  = /3
#MSLINKOP= ,free386.exe,nul,,nul

#///////////////////////////////////////////////////////////////////
#High-C �t���� linker ���g�p����ꍇ
#
#LINK   = free386 386linkp
#LINKOP = -86 -exe free386.exe

#///////////////////////////////////////////////////////////////////
#F-BASIC386�t���� linker ���g�p����ꍇ
#  (���̃����J�� High-C�t��linker �ƃo�[�W�����Ⴂ + �����i�Ɏv����)
#
#LINK   = free386 d:\fb386\bascom\tlinkp
#LINKOP = -86 -exe free386.exe

#///////////////////////////////////////////////////////////////////
#alink.exp ���g�p����ꍇ
#
#LINK   = free386 alink
#LINKOP = -oEXE -o free386.exe



#///////////////////////////////////////////////////////////////////
#com �t�@�C���ϊ�
#
COM  =exe2bin
#COM  =exe2com
#COM  =free386 exe2com

#------------------------------------------------------------------------------

all : free386.com

start.obj: start.asm f386def.inc
	$(ASM) $(ASMOP) start.asm

sub.obj: sub.asm f386def.inc
	$(ASM) $(ASMOP) sub.asm

f386sub.obj: f386sub.asm f386def.inc f386seg.inc start.inc
	$(ASM) $(ASMOP) f386sub.asm

f386seg.obj: f386seg.asm f386def.inc free386.inc
	$(ASM) $(ASMOP) f386seg.asm

f386cv86.obj: f386cv86.asm f386def.inc free386.inc macro.asm
	$(ASM) $(ASMOP) f386cv86.asm

int.obj: int.asm int_dos.asm int_dosx.asm int_f386.asm int_data.asm macro.asm f386def.inc
	$(ASM) $(ASMOP) int.asm

free386.obj: free386.asm f386def.inc f386data.asm f386prot.asm towns.asm at.asm pc98.asm
	$(ASM) $(ASMOP) free386.asm

free386.exe: start.obj f386sub.obj free386.obj sub.obj f386seg.obj f386cv86.obj int.obj
	$(LINK) $(LINKOP) start.obj sub.obj f386sub.obj f386seg.obj f386cv86.obj int.obj free386.obj$(MSLINKOP)
#------���ӁFfree386.obj ��K���Ō���Ƀ����N���邱�ƁI�I------

free386.com: free386.exe
	$(COM) free386.exe free386.com
