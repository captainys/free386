;******************************************************************************
;�@Free386�@���f�[�^����
;******************************************************************************
;
segment	data align=4 class=CODE use16
group	comgroup text data
;/////////////////////////////////////////////////////////////////////////////
;����ʕϐ�
;/////////////////////////////////////////////////////////////////////////////
	align	4
stack_pointer:
_esp	dd	0		;esp �ۑ��p
_ss	dd	0		;ss

	;/// �n�[�h�E�F�A���荞�� < 20h ���̑ޔ�̈� ///
%if Restore8259A
%if ((HW_INT_MASTER < 20h) || (HW_INT_SLAVE < 20h))
intr_table	resb	8*20h		;8 byte *20h
%endif
%endif


;/////////////////////////////////////////////////////////////////////////////
;��int 20h-2fh / DOS���荞�݃��X�g�iIDT�ݒ�p�j
;/////////////////////////////////////////////////////////////////////////////
	align	4
DOS_int_list:
	;##### DOS ���荞�� ###############################
	dw	offset	PM_int_20h
	dw	offset	PM_int_21h
	dw	offset	PM_int_22h
	dw	offset	PM_int_23h
	dw	offset	PM_int_24h
	dw	offset	PM_int_25h
	dw	offset	PM_int_26h
	dw	offset	PM_int_27h
	dw	offset	PM_int_28h
	dw	offset	PM_int_29h
	dw	offset	PM_int_2ah
	dw	offset	PM_int_2bh
	dw	offset	PM_int_2ch
	dw	offset	PM_int_2dh
	dw	offset	PM_int_2eh
	dw	offset	PM_int_2fh


;/////////////////////////////////////////////////////////////////////////////
;��int 21h / ���荞�݃e�[�u���i�����g�p�j
;/////////////////////////////////////////////////////////////////////////////
	align	4
int21h_table:
	;### function 00h-07h ######
	dd	offset int_21h_00h	;�v���O�����I�� ret = 0ffh
	dd	offset call_V86_int21	;�G�R�[�t���L�[����
	dd	offset call_V86_int21	;1�����W���o��
	dd	offset call_V86_int21	;1�����W���⏕���� (AUX)
	dd	offset call_V86_int21	;1�����W���⏕�o�� (AUX)
	dd	offset call_V86_int21	;1�����W�����X�g�o�� (PRN)
	dd	offset call_V86_int21	;���ڕW�����o��
	dd	offset call_V86_int21	;����(�t�B���^�Ȃ�)�W������

	;### function 08h-0eh ######
	dd	offset call_V86_int21	;�G�R�[�����L�[����
	dd	offset int_21h_09h	;������̏o��
	dd	offset int_21h_0ah	;�o�b�t�@�t���W��1�s����
	dd	offset call_V86_int21	;�L�[�{�[�h�X�e�[�^�X�`�F�b�N
	dd	offset call_V86_int21	;�o�b�t�@�N���A & ����
	dd	offset call_V86_int21	;DISK reset (file buffer flash)
	dd	offset call_V86_int21	;�J�����g�h���C�u�̕ύX

	;### function 0fh-17h ######
%rep	(18h-0fh)
	dd	offset int_21h_notsupp	;FCB / �T�|�[�g����
%endrep

	;### function 18h-1fh ######
	dd	offset int_21h_unknown	;unkonwn
	dd	offset call_V86_int21	;�J�����g�h���C�u�擾
	dd	offset int_21h_1ah	;�f�B�X�N�]���A�h���X�ݒ�(for 4eh,4fh)
	dd	offset int_21h_1bh	;�J�����g�h���C�u�̃f�B�X�N���擾
	dd	offset int_21h_1ch	;�C�Ӄh���C�u�̃f�B�X�N���擾
	dd	offset int_21h_unknown	;unkonwn
	dd	offset int_21h_unknown	;unkonwn
	dd	offset int_21h_unknown	;unkonwn

	;### function 20h-27h ######
	dd	offset int_21h_unknown	;unkonwn
	dd	offset int_21h_notsupp	;FCB / �T�|�[�g����
	dd	offset int_21h_notsupp	;FCB
	dd	offset int_21h_notsupp	;FCB
	dd	offset int_21h_notsupp	;FCB
	dd	offset DOS_Extender_fn	;DOS-Extender �t�@���N�V����
	dd	offset int_21h_notsupp	;PSP�쐬 / �T�|�[�g����
	dd	offset int_21h_notsupp	;FCB

	;### function 28h-2fh ######
	dd	offset int_21h_notsupp	;FCB / �T�|�[�g����
	dd	offset int_21h_notsupp	;FCB
	dd	offset call_V86_int21	;���t�擾
	dd	offset call_V86_int21	;���t�ݒ�
	dd	offset call_V86_int21	;�����擾
	dd	offset call_V86_int21	;�����ݒ�
	dd	offset call_V86_int21	;�x���t�@�C�t���O�� �Z�b�g/���Z�b�g
	dd	offset int_21h_2fh	;�f�B�X�N�]���A�h���X�擾(for 4eh,4fh)

	;### function 30h-37h ######
	dd	offset int_21h_30h	;Version ���擾
	dd	offset int_21h_31h	;�풓�I��
	dd	offset int_21h_notsupp	;DOS �f�B�X�N�u���b�N����
	dd	offset call_V86_int21	;CTRL-C ���o��� �ݒ�^�擾
	dd	offset int_21h_ret_esbx	;InDOS�t���O�̃A�h���X�擾
	dd	offset DOS_Extender_fn	;DOS-Extender �t�@���N�V����
	dd	offset call_V86_int21	;�f�B�X�N�c��e�ʎ擾
	dd	offset int_21h_unknown	;unknown

	;### function 38h-3fh ######
	dd	offset int_21h_38h	;���ʏ��̎擾�^�ݒ�
	dd	offset int_21h_ds_edx	;�T�u�f�B���N�g���̍쐬
	dd	offset int_21h_ds_edx	;�T�u�f�B���N�g���̍폜
	dd	offset int_21h_ds_edx	;�J�����g�f�B���N�g���̕ύX
	dd	offset int_21h_ds_edx	;�t�@�C��:�쐬
	dd	offset int_21h_ds_edx	;�t�@�C��:�I�[�v��
	dd	offset call_V86_int21	;�t�@�C��:�N���[�Y
	dd	offset int_21h_3fh	;�t�@�C��:�ǂݍ���

	;### function 40h-47h ######
	dd	offset int_21h_40h	;�t�@�C��:��������
	dd	offset int_21h_ds_edx	;�t�@�C��:�폜
	dd	offset call_V86_int21	;�t�@�C��:�|�C���^�ړ�
	dd	offset int_21h_ds_edx	;�t�@�C��:�����̎擾/�ݒ�
	dd	offset int_21h_44h	;IOCTRL
	dd	offset call_V86_int21	;�t�@�C��:�n���h���̓�d��
	dd	offset call_V86_int21	;�t�@�C��:�n���h���̋����I�ȓ�d��
	dd	offset int_21h_47h	;�J�����g�f�B���N�g���̎擾

	;### function 48h-4fh ######
	dd	offset int_21h_48h	;P������:LDT�Z�O�����g�쐬�ƃ������m��
	dd	offset int_21h_49h	;P������:LDT�Z�O�����g�ƃ������̉��
	dd	offset int_21h_4ah	;P������:�Z�O�����g���������蓖�ĕύX
	dd	offset int_21h_notsupp	;�q�v���O�����̎��s
	dd	offset int_21h_4ch	;�v���O�����I��
	dd	offset call_V86_int21	;�q�v���O�����̃��^�[���R�[�h�擾
	dd	offset int_21h_ds_edx	;�ŏ��Ɉ�v����t�@�C���̌���
	dd	offset call_V86_int21	;���Ɉ�v����t�@�C���̌���

	;### function 50h-57h ######
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_ret_esbx	;�擪 MCB �擾 / IO.SYS���[�N�A�h���X�擾
	dd	offset int_21h_unknown	;unknown
	dd	offset call_V86_int21	;�x���t�@�C�t���O�̎擾
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_56h	;�t�@�C���̈ړ��i���l�[���j
	dd	offset call_V86_int21	;�t�@�C���̎��ԏ�� �擾/�ݒ�

	;### function 58h-5fh ######
	dd	offset call_V86_int21	;���������蓖�ĕ��@�̕ύX
	dd	offset call_V86_int21	;�g���G���[�R�[�h�̎擾
	dd	offset int_21h_ds_edx	;�e���v�����t�@�C���̍쐬
	dd	offset int_21h_ds_edx	;�V�K�t�@�C���̍쐬
	dd	offset call_V86_int21	;�t�@�C���A�N�Z�X�� ���b�N/�A�����b�N
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_notsupp	;MS-Networks �֘A
	dd	offset int_21h_notsupp	;MS-Networks �֘A

	;### function 60h-67h ######
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_62h	;PSP�Z�O�����g�𓾂�
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_unknown	;unknown
	dd	offset int_21h_unknown	;unknown
	dd	offset call_V86_int21	;�I�[�v���\�ȍő�n���h�����̐ݒ�

%rep	(int_21h_fn_MAX - 67h)
	dd	offset int_21h_unknown	;unknown
%endrep


;/////////////////////////////////////////////////////////////////////////////
;��DOS-Extender �t�@���N�V�����e�[�u�� / int 21h ax=25xxh
;/////////////////////////////////////////////////////////////////////////////
DOSExt_fn_table:
	;### function 00h-07h ######
	dd	offset DOSX_unknown	;(�s��)
	dd	offset DOSX_fn_2501h	;CPU���[�h�؂芷���\���̂̃��Z�b�g
	dd	offset DOSX_fn_2502h	;�v���e�N�g���[�h���荞�݃x�N�^�̎擾
	dd	offset DOSX_fn_2503h	;���A�����[�h���荞�݃x�N�^�̎擾
	dd	offset DOSX_fn_2504h	;�v���e�N�g���[�h���荞�݃x�N�^�̐ݒ�
	dd	offset DOSX_fn_2505h	;���A�����[�h���荞�݃x�N�^�̐ݒ�
	dd	offset DOSX_fn_2506h	;��Ƀv���e�N�g���[�h�œ��삷�銄�荞��
	dd	offset DOSX_fn_2507h	;���A��/�v���e�N�g�̊��荞�݃x�N�^�ݒ�

	;### function 08h-0fh ######
	dd	offset DOSX_fn_2508h	;�Z���N�^�̃x�[�X���j�A�A�h���X�擾
	dd	offset DOSX_fn_2509h	;���j�A�A�h���X���畨���A�h���X�ւ̕ϊ�
	dd	offset DOSX_fn_250ah	;�����������̃}�b�s���O
	dd	offset DOSX_unknown	;(�s��)
	dd	offset DOSX_fn_250ch	;�n�[�h�E�F�A���荞�݂̃x�N�^�ԍ��擾
	dd	offset DOSX_fn_250dh	;DOS�����������N���̓���
	dd	offset DOSX_fn_250eh	;DOS���[�`���̃R�[��(no use �Z�O�����g)
	dd	offset DOSX_fn_250fh	;�A�h���X��DOS�A�h���X�ɕϊ�

	;### function 10h-17h ######
	dd	offset DOSX_fn_2510h	;DOS���[�`���̃R�[��(far call)
	dd	offset DOSX_fn_2511h	;DOS���[�`����INT�R�[��(int XXh)
	dd	offset DOSX_fn_2512h	;�f�B�o�N�̂��߂̃v���O�������[�h
	dd	offset DOSX_fn_2513h	;�Z���N�^�̃G�C���A�X�쐬
	dd	offset DOSX_fn_2514h	;�Z���N�^�̑����ύX
	dd	offset DOSX_fn_2515h	;�Z���N�^�̑����擾
	dd	offset DOSX_unknown	;??
	dd	offset DOSX_fn_2517h	;DOS����o�b�t�@�̃A�h���X�擾


DOSExt_fn_table2:	;C0h�`C3h
	;### function 18h-1fh ######
	dd	offset DOSX_fn_25c0h
	dd	offset DOSX_fn_25c1h
	dd	offset DOSX_fn_25c2h
	dd	offset int_21h_notsupp


;/////////////////////////////////////////////////////////////////////////////
;��Free386 function table
;/////////////////////////////////////////////////////////////////////////////
F386fn_table:
	;### function 00h-07h ######
	dd	offset F386fn_00h
	dd	offset F386fn_01h
	dd	offset F386fn_02h
	dd	offset F386fn_03h
	dd	offset F386fn_04h
	dd	offset F386fn_05h
	dd	offset F386fn_06h
	dd	offset F386fn_07h

	;### function 08h-0fh ######
	dd	offset F386fn_08h
	dd	offset F386fn_09h
	dd	offset F386fn_0ah
	dd	offset F386fn_0bh
	dd	offset F386fn_0ch
	dd	offset F386fn_0dh
	dd	offset F386fn_0eh
	dd	offset F386fn_0fh

	;### function 10h-17h ######
	dd	offset F386fn_10h
	dd	offset F386fn_11h
	dd	offset F386fn_12h
	dd	offset F386fn_13h
	dd	offset F386fn_14h
	dd	offset F386fn_15h
	dd	offset F386fn_16h
	dd	offset F386fn_17h

%rep	(F386_INT_fn_MAX - 17h)
	dd	offset F386fn_unknown	;�_�~�[
%endrep
