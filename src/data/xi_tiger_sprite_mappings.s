; Direct metasprite descriptor entry; the rotation sets begin after the body and claw mappings
Boss_XiTigerDirectDescriptorFrame00:    dc.w    $287E, $C00, $AEC  ; was: word_EBA1A
                                        ; ROM:00034D12   o
                dc.w    $287A, $300, $F20C
                dc.w    $A86A, $F00, $EAEC
Boss_XiTigerGroundedBodyMapping:    dc.w    $2829, $E00, $E4FE  ; was: word_EBA2C
                                        ; Boss_XiTigerEnterIdleState+16   o
                dc.w    $2844, $300, $ECF6
                dc.w    $2838, $E00, $FCFE
                dc.w    $2836, $100, $FC1E
                dc.w    $A835, 0, $DCFE
Boss_XiTigerAirborneBodyMapping:    dc.w    $2848, $E00, $FCFE  ; was: word_EBA4A
                                        ; Boss_XiTigerBeginDefeatLeap+C   o
                dc.w    $2829, $E00, $E4FE
                dc.w    $2844, $300, $ECF6
                dc.w    $2836, $100, $FC1E
                dc.w    $A835, 0, $DCFE
Boss_XiTigerClawMappingA:   dc.w    $30A0, $E00, $F3CE  ; was: word_EBA68
                                        ; Boss_XiTigerSetup+7C   o
                dc.w    $B0AC, $F00, $F3EE
Boss_XiTigerClawMappingB:   dc.w    $30EE, 0, $FE4      ; was: word_EBA74
                                        ; ROM:0003E188   o
                dc.w    $30E5, $A00, $17DD
                dc.w    $B0D5, $F00, $F7EC
Boss_XiTigerClawMappingD:   dc.w    $28D3, $400, $A12   ; was: word_EBA86
                                        ; ROM:0003E180   o
                dc.w    $28CB, $D00, $120B
                dc.w    $28CA, 0, $2F4
                dc.w    $28C4, $900, $3FC
                dc.w    $A8BC, $D00, $F3F5
Boss_XiTigerClawMappingC:   dc.w    $2894, $B00, $14F3  ; was: word_EBAA4
                                        ; ROM:0003E184   o
                dc.w    $A884, $F00, $F4F3
; Rotation set A is consumed forward by table A and backward by table C
Boss_XiTigerRotationSetAFrame00:    dc.w    $A123, $F00, $EFF1  ; was: word_EBAB0
                                        ; ROM:00034CC0   o
Boss_XiTigerRotationSetAFrame01:    dc.w    $A117, $E00, $F3F2  ; was: word_EBAB6
                                        ; ROM:00034CBC   o
Boss_XiTigerRotationSetAFrame02:    dc.w    $A107, $F00, $F0F1  ; was: word_EBABC
                                        ; ROM:00034CB8   o
Boss_XiTigerRotationSetAFrame03:    dc.w    $A0FB, $B00, $F2F4  ; was: word_EBAC2
                                        ; ROM:00034CB4   o
Boss_XiTigerRotationSetAFrame04:    dc.w    $A933, $F00, $EFF0  ; was: word_EBAC8
                                        ; ROM:00034CB0   o
Boss_XiTigerRotationSetAFrame05:    dc.w    $A8FB, $B00, $F1F4  ; was: word_EBACE
                                        ; ROM:00034CAC   o
Boss_XiTigerRotationSetAFrame06:    dc.w    $A907, $F00, $EFF0  ; was: word_EBAD4
                                        ; ROM:00034CA8   o
Boss_XiTigerRotationSetAFrame07:    dc.w    $A917, $E00, $F3EE  ; was: word_EBADA
                                        ; ROM:Boss_XiTigerRotationFramesC   o
; Second direct metasprite descriptor entry, outside either rotation set
Boss_XiTigerDirectDescriptorFrame01:    dc.w    $20EF, $B00, $F0E8  ; was: word_EBAE0
                dc.w    $A8EF, $B00, $F000
; Rotation set B is consumed forward by table B and backward by table D
Boss_XiTigerRotationSetBFrame00:    dc.w    $A167, $B00, $EDED  ; was: word_EBAEC
                                        ; ROM:00034CE0   o
Boss_XiTigerRotationSetBFrame01:    dc.w    $A15B, $B00, $EEEC  ; was: word_EBAF2
                                        ; ROM:00034CDC   o
Boss_XiTigerRotationSetBFrame02:    dc.w    $A14F, $E00, $F7E8  ; was: word_EBAF8
                                        ; ROM:00034CD8   o
Boss_XiTigerRotationSetBFrame03:    dc.w    $A143, $E00, $F8E9  ; was: word_EBAFE
                                        ; ROM:00034CD4   o
Boss_XiTigerRotationSetBFrame04:    dc.w    $A197, $E00, $FAEC  ; was: word_EBB04
                                        ; ROM:00034CD0   o
Boss_XiTigerRotationSetBFrame05:    dc.w    $B98B, $E00, $FBEE  ; was: word_EBB0A
                                        ; ROM:00034CCC   o
Boss_XiTigerRotationSetBFrame06:    dc.w    $B97F, $B00, $F8F7  ; was: word_EBB10
                                        ; ROM:00034CC8   o
Boss_XiTigerRotationSetBFrame07:    dc.w    $B973, $B00, $F7F7  ; was: word_EBB16
                                        ; ROM:Boss_XiTigerRotationFramesD   o
Boss_XiTigerClawMappingE:   dc.w    $28A0, $E00, $F613  ; was: word_EBB1C
                dc.w    $A8AC, $F00, $EEF3
