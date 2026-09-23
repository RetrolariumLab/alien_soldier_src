; ---------------------------------------------------------------------------
BattleBanner_StaticSpriteLine:  dc.l    $C6A0010A       ; DATA XREF: BattleBanner_HoldReadyLine   o  ; was: dword_B43E
                                        ; sub_AADC   o
                dc.l    $680B0004
BattleBanner_MovingSpriteLine:  dc.l    $C6AA00FF       ; DATA XREF: BattleBanner_AnimateFightLine+1E   o  ; was: dword_B446
                dc.l    $680B0006

; Start the boss-message sequence and publish its wait gate
BossMessage_Start:                                      ; CODE XREF: Boss_DestroyerProtoIntroApproachState+28   p  ; was: sub_B44E
                                        ; Boss_VictorFlyIn+1E   p
                bclr    #1,(StageRouteFlags).w
                bne.s   BossMessage_StartReadyFightBanner
                bclr    #0,(MessageSequenceFlags).w
                cmpi.w  #4,(MessageMode).w
                bmi.s   BossMessage_SelectScript
BossMessage_StartReadyFightBanner:                      ; CODE XREF: BossMessage_Start+6   j  ; was: loc_B464
                move.w  #$1E,(MessageSequenceState).w
                move.l  #BattleBanner_GlyphSourceList,(MessageGlyphSourcePtr).w
                move.w  #$5400,(MessageGlyphVRAMCursor).w
                move.b  #4,(VDPReg18Shadow+1).w
                rts
; ---------------------------------------------------------------------------
BossMessage_SelectScript:                               ; CODE XREF: BossMessage_Start+14   j  ; was: loc_B480
                asl.w   #3,d0
                cmpi.w  #2,(MessageMode).w
                bne.s   BossMessage_StartScript
                addi.w  #4,d0
BossMessage_StartScript:                                ; CODE XREF: BossMessage_Start+3A   j  ; was: loc_B48E
                move.w  #$10,(MessageSequenceState).w
                move.l  BossMessageScriptPointerTable(pc,d0.w),(MessageScriptCursor).w
                rts
; End of function BossMessage_Start
; ---------------------------------------------------------------------------
BossMessageScriptPointerTable:  dc.l    BossMessageScript_DeepStriderGroup  ; was: off_B49C
                dc.l    BossMessageScript_DeepStriderGroup
                dc.l    BossMessageScript_AntroidGroup
                dc.l    BossMessageScript_AntroidGroup
                dc.l    BossMessageScript_UnusedSlot2
                dc.l    BossMessageScript_UnusedSlot2
                dc.l    BossMessageScript_CommonGroup   ; text?
                dc.l    BossMessageScript_CommonGroup   ; text?
                dc.l    BossMessageScript_ShellshogunGroup
                dc.l    BossMessageScript_ShellshogunGroup
                dc.l    BossMessageScript_JokerGroup
                dc.l    BossMessageScript_JokerGroup
                dc.l    BossMessageScript_MadamBarbar
                dc.l    BossMessageScript_MadamBarbar
                dc.l    BossMessageScript_FlyingNeo
                dc.l    BossMessageScript_FlyingNeo
                dc.l    ShipAndValkirieMessageScript
                dc.l    ShipAndValkirieMessageScript

; Starts the ship-name script, selecting the configured message-mode entry
ShipName_StartScript:                                   ; CODE XREF: ShipSequence_ShowName+4   p  ; was: sub_B4E4
                                        ; ShipSequence_WaitForVerticalPosition+10   p
                bset    #0,(MessageSequenceFlags).w
                asl.w   #3,d0
                cmpi.w  #2,(MessageMode).w
                bne.s   ShipName_SelectScript
                addi.w  #4,d0
ShipName_SelectScript:                                  ; CODE XREF: ShipName_StartScript+E   j  ; was: loc_B4F8
                move.w  #2,(MessageSequenceState).w
                move.l  ShipNameScriptPointerTable(pc,d0.w),(MessageScriptCursor).w
                rts
; End of function ShipName_StartScript
; ---------------------------------------------------------------------------
ShipNameScriptPointerTable: dc.l    ShipAndValkirieMessageScript, ShipAndValkirieMessageScript  ; was: word_B506
                dc.w    4, $FFFF, $D08A, $1D1E, $B11, $F02, 0
                dc.w    $2113, $1811, $19, $1000, $1E12, $F00, $1619, $1D0B, $1811, $F16, $F1D
                dc.w    $FF00
StageIntro_GlyphSourceList: dc.w    $102, $304, $506, $708, $90A, $1D1E, $B11, $FFF  ; was: word_B534
                                        ; DATA XREF: StageIntro_InitializeBanner+10   o
BattleBanner_GlyphSourceList:   dc.w    $1C0F, $B0E, $2310, $1311, $121E, $2929, $29FF  ; was: word_B544
                                        ; DATA XREF: BattleBanner_PrepareGlyphs+C   o
                                        ; BossMessage_Start+1C   o
Results_TimeBonusGlyphSourceList:   dc.w    $102, $304, $506, $708, $90A, $1D1E, $B11, $F0D  ; was: word_B552
                                        ; DATA XREF: Results_InitializeTimeBonus+4   o
                dc.w    $161C, $C19, $181F, $FF00
StageIntro_EmergencyGlyphSourceList:    dc.w    $F17, $1C11, $180D, $23FF  ; was: word_B56A
                                        ; DATA XREF: StageIntro_InitializeEmergencyBanner+4   o
BossMessageScript_CommonGroup:  dc.b    0, 6, 0, $1E, $FF, $FF, $D0, $90  ; was: byte_B572
                                        ; DATA XREF: ROM:0000B4B4   o
                                        ; ROM:0000B4B8   o
                dc.b    $5A, $32, $39, $3E, $D8, $82, $80, $A3  ; text?
                dc.b    $7F, $AB, $8D, $A4, $B2, $C5, $DA, $D9
                dc.b    $4E, $40, $5B, $6D, $3F, $5A, $D9, $FF
                dc.b    $D0, $90, $4E, $64, $49, $39, $48, $B2
                dc.b    $CC, $C8, $92, $A3, $C8, $C0, $DA, $43
                dc.b    0, $42, $30, $5B, $3D, $47, $5D, $34
                dc.b    $32, $D9, $FF, 0, $D0, $90, $9F, $8A
                dc.b    $87, $A2, $5D, 0, $31, $79, $42, $37
                dc.b    $56, $55, $63, $76, $47, $33, $35, $5A
                dc.b    $D8, $83, $80, $D9, $FF, 0, $D0, $90
                dc.b    $3A, $30, $D8, $35, $35, $79, $42, $36
                dc.b    $58, $5D, $56, $DB, $89, $8A, $9E, $45
                dc.b    $3B, $42, $58, $55, $65, $DB, $FF, 0
BossMessageScript_ShellshogunGroup: dc.b    0, 6, 0, $1E, $FF, $FF, $D0, $90  ; was: byte_B5E2
                                        ; DATA XREF: ROM:0000B4BC   o
                                        ; ROM:0000B4C0   o
                dc.b    $32, $46, $79, $DB, 0, $86, $8C, $52
                dc.b    $48, $51, $DB, 0, $93, $94, $58, $41
                dc.b    $DB, $93, $94, $58, $41, $DB, $DB, $FF
                dc.b    $D0, $90, $3D, $79, $3B, $76, $D8, $8A
                dc.b    $CC, $A4, $8A, $C7, $DA, $AE, $AB, $45
                dc.b    $42, $8D, $DA, $A6, $DA, $DB, $DB, $FF
                dc.b    $D0, $90, $34, $32, $79, $D8, $83, $A5
                dc.b    $49, $82, $80, $A3, $7F, $AB, $8D, $A4
                dc.b    $B2, $C5, $DA, $DB, $DB, $FF, $D0, $90
                dc.b    $81, $BA, $48, $B9, $86, $48, $70, $32
                dc.b    $51, $DB, 0, $83, $A5, $48, $32, $61
                dc.b    $36, $45, $41, $31, $42, $39, $56, $55
                dc.b    $35, $DB, $FF, 0
BossMessageScript_UnusedSlot2:  dc.b    0, 6, 0, $16, $FF, $FF, $D0, $90  ; was: byte_B64E
                                        ; DATA XREF: ROM:0000B4AC   o
                                        ; ROM:0000B4B0   o
                dc.b    $83, $A5, $48, $44, $49, $D8, $98, $94
                dc.b    $CA, $BB, $80, $C0, $DA, $D9, $FF, 0
                dc.b    $D0, $90, $3C, $4E, $44, $31, $D9, $85
                dc.b    $89, $9D, $48, 0, $63, $5C, $3D, $31
                dc.b    $49, $D8, $39, $39, $6A, 0, $34, $5B
                dc.b    $55, $D9, $FF, 0, $D0, $90, $32, $55
                dc.b    $3D, $33, $D9, $83, $A5, $49, 0, $83
                dc.b    $80, $BF, $A5, $45, $44, $55, $4E, $6A
                dc.b    0, $31, $36, $42, $58, $55, $D9, $FF
                dc.b    $D0, $90, $98, $84, $45, 0, $49, $31
                dc.b    $55, $48, $49, $D8, $83, $9D, $82, $3A
                dc.b    $5C, $48, $4D, $32, $3A, $D9, $FF, 0
BossMessageScript_AntroidGroup: dc.b    0, 6, 0, $18, $FF, $FF, $D0, $90  ; was: byte_B6B6
                                        ; DATA XREF: ROM:0000B4A4   o
                                        ; ROM:0000B4A8   o
                dc.b    $34, $49, $5A, $32, $D9, $34, $48, $56
                dc.b    $49, $D8, $93, $94, $A1, $97, $67, $DC
                dc.b    $FF, 0, $D0, $90, $8B, $84, $A4, $BF
                dc.b    $8B, $48, 0, $96, $9F, $A3, $E2, 0
                dc.b    $B2, $C5, $9D, $3C, $55, $5C, $63, $76
                dc.b    $44, $31, $D9, $FF, $D0, $90, $5A, $37
                dc.b    $47, $3F, $35, $31, $D8, $BE, $80, $BC
                dc.b    $CA, $DA, $DC, $DC, $FF, 0, $D0, $90
                dc.b    $32, $5C, $6B, $32, $48, 0, $63, $35
                dc.b    $5C, $67, $D9, $90, $85, $30, $32, $65
                dc.b    $D9, $FF
BossMessageScript_DeepStriderGroup: dc.b    0, 6, 0, $1C, $FF, $FF, $D0, $90  ; was: byte_B710
                                        ; DATA XREF: ROM:BossMessageScriptPointerTable   o
                                        ; ROM:0000B4A0   o
                dc.b    $87, $80, $88, $86, $DB, $87, $80, $88
                dc.b    $86, $DB, $BD, $8D, $81, $9C, $81, $85
                dc.b    $3D, $5A, $DB, $DB, $FF, 0, $D0, $90
                dc.b    $AA, $A5, $AA, $A5, $49, $D8, $BD, $A3
                dc.b    $C7, $86, $39, $32, $3B, $E2, 0, $3F
                dc.b    $51, $53, $5B, $44, $31, $DB, $FF, 0
                dc.b    $D0, $90, $58, $56, $55, $52, $48, $44
                dc.b    $53, 0, $58, $79, $42, $4F, $57, $31
                dc.b    $D8, $BB, $DA, $A6, $DA, $D9, $FF, 0
                dc.b    $D0, $90, $80, $AB, $8E, $DA, $8C, $C2
                dc.b    $8E, $DA, $D8, $8B, $8E, $AB, $BB, $80
                dc.b    $3D, $5A, $DB, $DB, $FF, 0
BossMessageScript_MadamBarbar:  dc.b    0, 6, 0, $22, $FF, $FF, $D0, $90  ; was: byte_B776
                                        ; DATA XREF: ROM:0000B4CC   o
                                        ; ROM:0000B4D0   o
                dc.b    $5B, $3F, $3B, $49, 0, $86, $A2, $BD
                dc.b    $BB, $DA, $BB, $DA, $43, $52, $32, $3B
                dc.b    $4E, $3C, $D9, $6B, $66, $A9, $A6, $8A
                dc.b    $86, $D9, $FF, 0, $D0, $90, $67, $31
                dc.b    $63, $44, $92, $88, $A6, $E2, 0, $8F
                dc.b    $C7, $85, $C8, $43, $31, $36, $4E, $3C
                dc.b    $5A, $D9, $9A, $9A, $9A, $D8, $D8, $D8
                dc.b    $FF, 0, $D0, $90, $58, $56, $55, $52
                dc.b    $5C, $44, $53, 0, $58, $79, $42, $4F
                dc.b    $57, $31, $D8, $BB, $DA, $A6, $DA, $D9
                dc.b    $FF, 0, $D0, $90, $6B, $32, $6A, $52
                dc.b    $31, $31, $38, $6B, 0, $32, $4E, $3E
                dc.b    $32, $67, $44, $D8, $83, $9D, $82, $D9
                dc.b    $FF, 0
BossMessageScript_FlyingNeo:    dc.b    0, 6, 0, $22, $FF, $FF, $D0, $90  ; was: byte_B7E8
                                        ; DATA XREF: ROM:0000B4D4   o
                                        ; ROM:0000B4D8   o
                dc.b    $61, $6E, $3A, $3F, $67, $44, $D9, $39
                dc.b    $48, $7F, $89, $A4, $92, $8E, $80, $AC
                dc.b    $DA, $48, $90, $A2, $E2, $5B, $3C, $56
                dc.b    $3F, $35, $DC, $FF, $D0, $90, $50, $35
                dc.b    $3B, $48, $5A, $3B, $4F, $67, $D8, $93
                dc.b    $84, $9D, $45, $44, $56, $D9, $40, $36
                dc.b    $77, $32, $49, $52, $32, $34, $5B, $54
                dc.b    $67, $D9, $FF, 0, $D0, $90, $91, $A6
                dc.b    $A3, $8B, $92, $48, $80, $95, $45, $44
                dc.b    $54, $3A, $5D, $54, $58, $5D, $79, $3F
                dc.b    $35, $DB, $DB, $7F, $89, $A4, $92, $DB
                dc.b    $DB, $FF, $D0, $90, $82, $80, $A3, $7F
                dc.b    $AB, $8D, $A4, $B2, $C5, $DA, $43, $3B
                dc.b    $42, $48, $4D, $39, $54, $49, $6B, $39
                dc.b    $4C, $58, $79, $3F, $DB, $DB, $FF, 0
BossMessageScript_JokerGroup:   dc.b    0, 6, 0, $22, $FF, $FF, $D0, $90  ; was: byte_B868
                                        ; DATA XREF: ROM:0000B4C4   o
                                        ; ROM:0000B4C8   o
                dc.b    $61, $6E, $3A, $3F, $67, $44, $D9, $39
                dc.b    $48, $7F, $89, $A4, $92, $8E, $80, $AC
                dc.b    $DA, $48, $90, $A2, $E2, $5B, $3C, $56
                dc.b    $3F, $35, $DC, $FF, $D0, $90, $50, $35
                dc.b    $3B, $48, $5A, $3B, $4F, $67, $D8, $93
                dc.b    $84, $9D, $45, $44, $56, $D9, $40, $36
                dc.b    $77, $32, $49, $52, $32, $34, $5B, $54
                dc.b    $67, $D9, $FF, 0, $D0, $90, $91, $A6
                dc.b    $A3, $8B, $92, $48, $80, $95, $45, $44
                dc.b    $54, $3A, $5D, $54, $58, $5D, $79, $3F
                dc.b    $35, $DB, $DB, $7F, $89, $A4, $92, $DB
                dc.b    $DB, $FF, $D0, $90, $82, $80, $A3, $7F
                dc.b    $AB, $8D, $A4, $B2, $C5, $DA, $43, $3B
                dc.b    $42, $48, $4D, $39, $54, $49, $6B, $39
                dc.b    $4C, $58, $79, $3F, $DB, $DB, $FF, 0
ShipAndValkirieMessageScript:   dc.b    0, 4, $FF, $FF, $D0, $90, $35, $79  ; was: byte_B8E8
                                        ; DATA XREF: ROM:0000B4DC   o
                                        ; ROM:0000B4E0   o
                dc.b    $D8, $D8, $D8, 0, $35, $33, $6A, $40
                dc.b    $76, $5C, $D8, $D8, $D8, $DC, $DC, $FF
