Sound_BGMPointerTable:  dc.l    Sound_BGM_81            ; was: off_84E78
                                        ; Sound_DriverInterfaceTable+8   o
                dc.l    Sound_BGM_82
                dc.l    Sound_BGM_83
                dc.l    Sound_BGM_84
                dc.l    Sound_BGM_85
                dc.l    Sound_BGM_86
                dc.l    Sound_BGM_87
                dc.l    Sound_BGM_88
                dc.l    Sound_BGM_89
                dc.l    Sound_BGM_8A
                dc.l    Sound_BGM_8B
                dc.l    Sound_BGM_8C
                dc.l    Sound_BGM_8D
                dc.l    Sound_BGM_8E
                dc.l    Sound_BGM_8F
                dc.l    Sound_BGM_90
                dc.l    Sound_BGM_91
                dc.l    Sound_BGM_92
                dc.l    Sound_BGM_93
                dc.l    Sound_BGM_94
                dc.l    Sound_BGM_95
                dc.l    Sound_BGM_96
                dc.l    Sound_BGM_97
                dc.l    Sound_BGM_98
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_81
                dc.l    Sound_BGM_9F
Sound_RequestPriorityTable: dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF  ; was: byte_84EF4
                                        ; Sound_DriverInterfaceTable   o
                dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                dc.b    $55, $5A, $52, $53, $4E, $5B, $5B, $5A, $53, $54, $53, $5A, $5A, $53, $5B, $5A
                dc.b    $54, $5B, $50, $50, $5C, $5A, $53, $53, $5A, $53, $60, $50, $50, $50, $50, $50
                dc.b    $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50
                dc.b    $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $50, $5B, $50, $50, $50, $FF
                dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
                dc.b    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $55
                dc.b    $5A, $50, $5A, $54, $55, $52, $59, $52, $53, $55, $5A, $5A, $4F, $52, $50, $4F
                dc.b    $40, $53, $45, $45, $45, $45, $54, $60, $4E, $45, $5B, $5B, $5A, $5A, $45, $52
                dc.b    $60, $52, $53, $5A, $50, $53, $50, $51, $50, $60, $54, $53, $50, $53, $50, $53
                dc.b    $53, $60, $45, $60, $5A, $40, $5A, $45, $54, $5A, $45, $50, $50, $46, $46, $5B
                dc.b    $59, $54, $54, $5B, $5B, $5A, $5A, $54, $54, $54, $45, $52, $53, $53, $50, $5B
                dc.b    $55, $55, $55, $5B, $5B, $5B, $5B, $5B, $FF, $FF, $FF, $FF, $FF, $FF
; Ordinary SFX pointer base shared by the $40-$7F and $A0-$F8 index paths
Sound_OrdinarySFXPointerTableBase:  dc.l    Sound_SFX_A0  ; was: off_84FF2
                                        ; Sound_DriverInterfaceTable+$C   o
                                        ; Sound_LoadSFX:Sound_SelectHighRangeSFXPointerTable   o
                dc.l    Sound_SFX_A1
                dc.l    Sound_SFX_A2
                dc.l    Sound_SFX_A3
                dc.l    Sound_SFX_A4
                dc.l    Sound_SFX_A5
                dc.l    Sound_SFX_A6
                dc.l    Sound_SFX_A7
                dc.l    Sound_SFX_A8
                dc.l    Sound_SFX_A9
                dc.l    Sound_SFX_AA
                dc.l    Sound_SFX_AB
                dc.l    Sound_SFX_AC
                dc.l    Sound_SFX_AD
                dc.l    Sound_SFX_AE
                dc.l    Sound_SFX_AF
                dc.l    Sound_SFX_B0
                dc.l    Sound_SFX_B1
                dc.l    Sound_SFX_B2
                dc.l    Sound_SFX_B3
                dc.l    Sound_SFX_B4
                dc.l    Sound_SFX_B5
                dc.l    Sound_SFX_B6
                dc.l    Sound_SFX_B7
                dc.l    Sound_SFX_B8
                dc.l    Sound_SFX_B9
                dc.l    Sound_SFX_BA
                dc.l    Sound_SFX_BB
                dc.l    Sound_SFX_BC
                dc.l    Sound_SFX_BD
                dc.l    Sound_SFX_BE
                dc.l    Sound_SFX_BF
                dc.l    Sound_SFX_C0
                dc.l    Sound_SFX_C1
                dc.l    Sound_SFX_C2
                dc.l    Sound_SFX_C3
                dc.l    Sound_SFX_C4
                dc.l    Sound_SFX_C5
                dc.l    Sound_SFX_C6
                dc.l    Sound_SFX_C7
                dc.l    Sound_SFX_C8
                dc.l    Sound_SFX_C9
                dc.l    Sound_SFX_CA
                dc.l    Sound_SFX_CB
                dc.l    Sound_SFX_CC
                dc.l    Sound_SFX_CD
                dc.l    Sound_SFX_CE
                dc.l    Sound_SFX_CF
                dc.l    Sound_SFX_D0
                dc.l    Sound_SFX_D1
                dc.l    Sound_SFX_D2
                dc.l    Sound_SFX_D3
                dc.l    Sound_SFX_D4
                dc.l    Sound_SFX_D5
                dc.l    Sound_SFX_D6
                dc.l    Sound_SFX_D7
                dc.l    Sound_SFX_D8
                dc.l    Sound_SFX_D9
                dc.l    Sound_SFX_DA
                dc.l    Sound_SFX_DB
                dc.l    Sound_SFX_DC
                dc.l    Sound_SFX_DD
                dc.l    Sound_SFX_DE
                dc.l    Sound_SFX_DF
                dc.l    Sound_SFX_E0
                dc.l    Sound_SFX_E1
                dc.l    Sound_SFX_E2
                dc.l    Sound_SFX_E3
                dc.l    Sound_SFX_E4
                dc.l    Sound_SFX_E5
                dc.l    Sound_SFX_E6
                dc.l    Sound_SFX_E7
                dc.l    Sound_SFX_E8
                dc.l    Sound_SFX_E9
                dc.l    Sound_SFX_EA
                dc.l    Sound_SFX_EB
                dc.l    Sound_SFX_EC
                dc.l    Sound_SFX_ED
                dc.l    Sound_SFX_EE
                dc.l    Sound_SFX_EF
                dc.l    Sound_SFX_F0
                dc.l    Sound_SFX_F1
                dc.l    Sound_SFX_F2
                dc.l    Sound_SFX_F3
                dc.l    Sound_SFX_F4
                dc.l    Sound_SFX_F5
                dc.l    Sound_SFX_F6
                dc.l    Sound_SFX_F7
                dc.l    Sound_SFX_F8
Sound_SpecialSFXPointerTable:   dc.l    Sound_SFX_F9    ; was: off_85156
                                        ; Sound_DriverInterfaceTable+4   o
                dc.l    Sound_SFX_FA
                dc.l    Sound_SFX_FB
                dc.l    Sound_SFX_FC
; Low-range table reached through the shared ordinary-SFX arithmetic base
Sound_LowRangeSFXPointerTable:  dc.l    Sound_SFX_40    ; was: off_85166
                dc.l    Sound_SFX_41
                dc.l    Sound_SFX_42
                dc.l    Sound_SFX_43
                dc.l    Sound_SFX_44
                dc.l    Sound_SFX_45
                dc.l    Sound_SFX_46
                dc.l    Sound_SFX_47
                dc.l    Sound_SFX_48
                dc.l    Sound_SFX_49
                dc.l    Sound_SFX_4A
                dc.l    Sound_SFX_4B
                dc.l    Sound_SFX_4C
                dc.l    Sound_SFX_4D
                dc.l    Sound_SFX_4E
                dc.l    Sound_SFX_4F
                dc.l    Sound_SFX_50
                dc.l    Sound_SFX_51
                dc.l    Sound_SFX_52
                dc.l    Sound_SFX_53
                dc.l    Sound_SFX_54
                dc.l    Sound_SFX_55
                dc.l    Sound_SFX_56
                dc.l    Sound_SFX_57
                dc.l    Sound_SFX_58
                dc.l    Sound_SFX_59
                dc.l    Sound_SFX_5A
                dc.l    Sound_SFX_5B
                dc.l    Sound_SFX_5C
                dc.l    Sound_SFX_5D
                dc.l    Sound_SFX_5E
                dc.l    Sound_SFX_5F
                dc.l    Sound_SFX_60
                dc.l    Sound_SFX_61
                dc.l    Sound_SFX_62
                dc.l    Sound_SFX_63
                dc.l    Sound_SFX_64
                dc.l    Sound_SFX_65
                dc.l    Sound_SFX_66
                dc.l    Sound_SFX_67
                dc.l    Sound_SFX_68
                dc.l    Sound_SFX_69
                dc.l    Sound_SFX_6A
                dc.l    Sound_SFX_6B
                dc.l    Sound_SFX_6C
                dc.l    Sound_SFX_6D
                dc.l    Sound_SFX_6E
                dc.l    Sound_SFX_6F
                dc.l    Sound_SFX_70
                dc.l    Sound_SFX_71
                dc.l    Sound_SFX_72
                dc.l    Sound_SFX_73
                dc.l    Sound_SFX_74
                dc.l    Sound_SFX_75
                dc.l    Sound_SFX_76
                dc.l    Sound_SFX_77
                dc.l    Sound_SFX_78
                dc.l    Sound_SFX_79
                dc.l    Sound_SFX_7A
                dc.l    Sound_SFX_7B
                dc.l    Sound_SFX_7C
                dc.l    Sound_SFX_7D
                dc.l    Sound_SFX_7E
                dc.l    Sound_SFX_7F
