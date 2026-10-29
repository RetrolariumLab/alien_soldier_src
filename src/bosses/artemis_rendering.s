Boss_UpdateArtemisActivePartVerticalPosition:           ; was: sub_584DC
                                        ; Boss_RenderArtemisPose+36   p
                move.w  $14(a0),d0
                move.w  d6,$14(a0)
                sub.w   d6,d0
                sub.w   d0,$74(a0)
                rts
; End of function Boss_UpdateArtemisActivePartVerticalPosition
; Distribute the current pose-frame channels across the Artemis metasprite
Boss_ApplyArtemisPoseToParts:                           ; was: sub_584EC
                moveq   #7,d6
                move.b  (a0),d3
                asl.w   #1,d3
                and.w   d7,d3
                move.w  d3,$B6(a5)
                move.b  4(a0),d4
                asl.w   #1,d4
                and.w   d7,d4
                move.w  d4,$116(a5)
                move.b  8(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$176(a5)
                move.w  d1,$1D6(a5)
                move.b  $C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                moveq   #0,d0
                move.w  $10(a0),d0
                swap    d0
                asr.l   d6,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$296(a5)
                move.w  d0,$2F6(a5)
                swap    d0
                moveq   #0,d1
                move.w  $14(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$356(a5)
                move.w  d1,$3B6(a5)
                swap    d1
                moveq   #0,d0
                move.w  $18(a0),d0
                swap    d0
                asr.l   d6,d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$476(a5)
                moveq   #0,d0
                move.w  $20(a0),d0
                swap    d0
                asr.l   d6,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$4D6(a5)
                move.w  d0,$536(a5)
                swap    d0
                moveq   #0,d1
                move.w  $24(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$596(a5)
                move.w  d1,$5F6(a5)
                swap    d1
                moveq   #0,d0
                move.w  $28(a0),d0
                swap    d0
                asr.l   d6,d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$656(a5)
                moveq   #0,d0
                move.w  $2C(a0),d0
                swap    d0
                asr.l   d6,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$6B6(a5)
                move.w  d0,d2
                subi.w  #$40,d2                         ; '@'
                and.w   d7,d2
                move.w  d2,$716(a5)
                swap    d0
                moveq   #0,d1
                move.w  $30(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$776(a5)
                move.w  d1,$7D6(a5)
                swap    d1
                moveq   #0,d0
                move.w  $34(a0),d0
                swap    d0
                asr.l   d6,d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$836(a5)
                moveq   #0,d0
                move.w  $38(a0),d0
                swap    d0
                asr.l   d6,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$896(a5)
                move.w  d0,d2
                subi.w  #$40,d2                         ; '@'
                and.w   d7,d2
                move.w  d2,$8F6(a5)
                swap    d0
                moveq   #0,d1
                move.w  $3C(a0),d1
                swap    d1
                asr.l   d6,d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$956(a5)
                move.w  d1,$9B6(a5)
                swap    d1
                moveq   #0,d0
                move.w  $40(a0),d0
                swap    d0
                asr.l   d6,d0
                add.l   d1,d0
                swap    d0
                and.w   d7,d0
                move.w  d0,$A16(a5)
                moveq   #0,d0
                move.w  $44(a0),d0
                swap    d0
                asr.l   d6,d0
                move.l  #$1E00000,d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$A76(a5)
                swap    d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$AD6(a5)
                swap    d1
                add.l   d0,d1
                swap    d1
                and.w   d7,d1
                move.w  d1,$B36(a5)
                move.b  $48(a0),d1
                ext.w   d1
                move.w  $B2(a5),d0
                add.w   d1,d0
                move.w  d0,$B4(a5)
                move.w  $112(a5),d0
                add.w   d1,d0
                move.w  d0,$114(a5)
                tst.b   $3BD(a5)
                bne.s   Boss_UpdateArtemisPoseAngleChannel
                clr.w   $4C(a0)
                rts
; ---------------------------------------------------------------------------
Boss_UpdateArtemisPoseAngleChannel:                     ; was: loc_586AC
                move.w  $4C(a0),d1
                asr.w   #6,d1
                and.w   d7,d1
                move.w  d1,$56(a5)
                rts
; End of function Boss_ApplyArtemisPoseToParts
; Interpret the current Artemis pose script and advance its interpolation
Boss_UpdateArtemisPoseScript:                           ; was: sub_586BA
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_AdvanceArtemisPoseInterpolation
Boss_ReadArtemisPoseScriptCommand:                      ; was: loc_586C4
                                        ; Boss_LoadArtemisPoseFrame+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_PrepareArtemisPoseRender
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ProcessArtemisPoseScriptEntry
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ReadArtemisPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_ProcessArtemisPoseScriptEntry:                     ; was: loc_586E0
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_LoadArtemisPoseFrame
                move.w  d3,$58(a5)
                bra.w   Boss_PrepareArtemisPoseRender
; End of function Boss_UpdateArtemisPoseScript
; UNKNOWN CODE-002: no static entry path; see docs/unknowns.md
Boss_ArtemisPoseScriptUnreferencedReturn:               ; was: nullsub_131
                rts
; End of function Boss_ArtemisPoseScriptUnreferencedReturn

; Load a pose frame or restart the script at the $FFFF command
Boss_LoadArtemisPoseFrame:                              ; was: sub_586F4
                cmpi.w  #$FFFF,d3
                bne.s   Boss_StartArtemisPoseFrame
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ReadArtemisPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_StartArtemisPoseFrame:                             ; was: loc_58704
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_CalculateArtemisPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_PrepareArtemisPoseRender
Boss_AdvanceArtemisPoseInterpolation:                   ; was: loc_58734
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$13,d7
                tst.b   $3BD(a5)
                beq.s   Boss_ApplyArtemisPoseInterpolation
                addq.w  #1,d7
Boss_ApplyArtemisPoseInterpolation:                     ; was: loc_58746
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_PrepareArtemisPoseRender:                          ; was: loc_5874C
                                        ; Boss_UpdateArtemisPoseScript+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Boss_LoadArtemisPoseFrame
; Calculate interpolation deltas for the next Artemis pose frame
Boss_CalculateArtemisPoseInterpolation:                 ; was: sub_58756
                movea.l $2FC(a5),a1
                moveq   #$13,d7
                tst.b   $3BD(a5)
                beq.s   Boss_PrepareArtemisPoseInterpolationBuffer
                addq.w  #1,d7
Boss_PrepareArtemisPoseInterpolationBuffer:             ; was: loc_58764
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_CalculateArtemisPoseInterpolation
; Initialize twenty or twenty-one Artemis pose channels from bytes at a0
Boss_ArtemisInitializePoseChannels:                     ; was: sub_58772
                moveq   #$13,d7
                tst.b   $3BD(a5)
                beq.s   Boss_ArtemisInitializePoseChannelBuffer
                addq.w  #1,d7
Boss_ArtemisInitializePoseChannelBuffer:                ; was: loc_5877C
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_ArtemisInitializePoseChannels
; ---------------------------------------------------------------------------
Artemis_State2And4Poses:    dc.w    $1010, $50, $4040, $64, $FFFE  ; was: word_58786
                                        ; Boss_UpdateArtemisState4+20   o
Artemis_State8Poses:        dc.w    $808, $50, $E10, $64, $4040, $64, $FFFE  ; was: word_58790
Artemis_StateAPoseScript:   dc.w    $C0C, $78, $1212, $8C, $840, $A0, $1818, $A0  ; was: word_5879E
                dc.w    $FFFE
Artemis_StateCAndEPoseScript:   dc.w    $C14, 0, $40E, 0, $208, 0, $20B, $3C  ; was: word_587B0
                                        ; sub_5818C:Artemis_StateEPoseScriptTable   o
                dc.w    $208, 0, $20B, $3C, $208, 0, $20B, $3C
                dc.w    $1010, 0, $80E, $28, $909, $28, $A0A, $3C
                dc.w    $FFFE
Artemis_StateEPoseScript6:  dc.w    $810, 0, $80E, $28, $909, $28, $A0A, $3C  ; was: word_587E2
                                        ; Boss_UpdateArtemisStateE+9C   o
                dc.w    $FFFE
Artemis_StateEPoseScript4:  dc.w    $40A, 0, $60C, $28, $505, $28, $606, $3C  ; was: word_587F4
                                        ; Boss_UpdateArtemisStateE+94   o
                dc.w    $FFFE
Artemis_StateEPoseScript2:  dc.w    $1034, 0, $30C, $28, $1010, $28, $410, $3C  ; was: word_58806
                                        ; Boss_UpdateArtemisStateE+8C   o
                dc.w    $FFFE
Artemis_StateEPoseScript1:  dc.w    $818, $28, $2020, $28, $1818, $3C, $FFFE  ; was: word_58818
Artemis_State10And12Poses:  dc.w    $A0A, $B4, $808, $C8, $1515, $DC, $8001, $A0E  ; was: word_58826
                                        ; Boss_UpdateArtemisState12+C   o
                dc.w    $F0, $505, $F0, $800F, $818, $104, $A0A, $104
                dc.w    $FFFE
Artemis_State14And16Poses:  dc.w    $820, $118, $1A1A, $118, $8001, $E0E, $12C, $8002  ; was: word_58848
                                        ; Boss_UpdateArtemisState16+14   o
                dc.w    $1111, $140, $1212, $154, $8080, $80E, $168, $C0C
                dc.w    $168, $FFFE
Artemis_PoseTable:  binclude "data/other/word_5886C.bin"  ; was: word_5886C
Artemis_PoseFrameDataEnd:                               ; was: word_5886C_End
