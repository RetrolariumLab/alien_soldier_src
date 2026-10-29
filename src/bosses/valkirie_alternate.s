Boss_ValkirieAlternateMain:                             ; was: sub_58FEE
                tst.w   4(a5)
                beq.w   Boss_ValkirieAlternateDispatchState
                tst.w   8(a5)
                beq.s   Boss_ValkirieAlternateDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_ValkirieAlternateUpdatePalette
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_ValkirieAlternateUpdatePalette
                tst.w   (BossHealth).w
                bne.s   Boss_ValkirieAlternateUpdatePalette
                moveq   #$C,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateUpdatePalette:                    ; was: loc_5901A
                                        ; Boss_ValkirieAlternateMain+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #$1E,d0
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
Boss_ValkirieAlternateDispatchState:                    ; was: loc_5902E
                                        ; Boss_ValkirieAlternateMain+C   j
                move.w  4(a5),d0
                movea.w Boss_ValkirieAlternateStateOffsets(pc,d0.w),a0
                adda.l  #Boss_ValkirieAlternateInit,a0
                jmp     (a0)
; End of function Boss_ValkirieAlternateMain
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateStateOffsets: dc.w    Boss_ValkirieAlternateInit-Boss_ValkirieAlternateInit  ; was: off_5903E
                dc.w    Boss_ValkirieAlternateRenderState2-Boss_ValkirieAlternateInit
                dc.w    Boss_ValkirieAlternateRenderState4-Boss_ValkirieAlternateInit

; Initialize the alternate Valkirie metasprite and enter dispatch state 4
Boss_ValkirieAlternateInit:                             ; was: sub_59044
                                        ; ROM:Boss_ValkirieAlternateStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$8300,(MetaspriteBaseTileWord).w
                moveq   #$17,d7
                movea.l #Boss_ValkirieAlternateMetaspritePartDescriptors,a0
                movea.l #Boss_ValkirieAlternateMetaspriteInitialAngles,a1
                movea.l #Boss_ValkirieAlternateMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_ValkirieAlternateMetaspritePoseAngles,$2FC(a5)
                move.l  #Boss_ValkirieAlternatePoseTable,$35C(a5)
                move.w  #$440,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                movea.l #Boss_ValkirieAlternateObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  #2,$1DE(a5)
                bra.w   Boss_ValkirieAlternateInitState4
; End of function Boss_ValkirieAlternateInit
; Initialize alternate dispatch state 2 at position ($120,$E0)
Boss_ValkirieAlternateInitState2:
                move.w  #2,4(a5)                        ; was: sub_590AA
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.b   (BossColorEffectFlags).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; End of function Boss_ValkirieAlternateInitState2
; Render dispatch state 2 with the shared looping pose
Boss_ValkirieAlternateRenderState2:                     ; was: sub_590DA
                lea     Boss_ValkirieAlternateStatePoses(pc),a1
                nop
                bra.w   Boss_ValkirieAlternateRenderFrame
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateInitState4:                       ; was: loc_590E4
                move.w  #4,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.b   (BossColorEffectFlags).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$70,$11C(a5)                   ; 'p'
; Render dispatch state 4 with the shared looping pose
Boss_ValkirieAlternateRenderState4:                     ; was: loc_5911A
                lea     Boss_ValkirieAlternateStatePoses(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateRenderFrame:                      ; was: loc_59124
                                        ; Boss_ValkirieAlternateRenderState2+46   j
                bsr.w   Boss_ValkirieAlternateUpdatePose
                bsr.w   Boss_ValkirieAlternateApplySymmetricAngles
                moveq   #$16,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_ValkirieAlternateRenderFrame
; Sets symmetric sprite angles for left/right mirrored parts
Boss_ValkirieAlternateApplySymmetricAngles:             ; was: sub_59134
                move.w  #$100,d6
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                move.w  d6,d5
                sub.w   d0,d5
                and.w   d7,d5
                move.w  d5,$3B6(a5)
                move.b  4(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                move.w  d6,d5
                sub.w   d0,d5
                and.w   d7,d5
                move.w  d5,$416(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$296(a5)
                move.w  d6,d5
                sub.w   d0,d5
                and.w   d7,d5
                move.w  d5,$476(a5)
                move.b  $C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                move.w  d6,d5
                sub.w   d0,d5
                and.w   d7,d5
                move.w  d5,$4D6(a5)
                move.b  $10(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                move.w  d6,d5
                sub.w   d0,d5
                and.w   d7,d5
                move.w  d5,$536(a5)
                move.w  #$80,$B6(a5)
                move.w  #$80,$176(a5)
                move.b  $18(a0),d3
                asl.w   #1,d3
                and.w   d7,d3
                move.w  d3,$596(a5)
                move.w  d6,d5
                sub.w   d3,d5
                and.w   d7,d5
                move.w  d5,$6B6(a5)
                move.b  $1C(a0),d3
                asl.w   #1,d3
                and.w   d7,d3
                move.w  d3,$5F6(a5)
                move.w  d3,$656(a5)
                move.w  d6,d5
                sub.w   d3,d5
                and.w   d7,d5
                move.w  d5,$716(a5)
                move.w  d5,$776(a5)
                move.b  $20(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$7D6(a5)
                move.w  d2,$836(a5)
                move.w  d6,d5
                sub.w   d2,d5
                and.w   d7,d5
                move.w  d5,$896(a5)
                move.w  d5,$8F6(a5)
                move.b  $24(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$116(a5)
                move.b  $28(a0),d1
                ext.w   d1
                move.w  d1,d2
                asr.w   #1,d2
                move.w  $112(a5),d0
                sub.w   d2,d0
                move.w  d0,$114(a5)
                move.w  $B2(a5),d0
                add.w   d2,d0
                move.w  d0,$B4(a5)
                move.w  $592(a5),d0
                add.w   d1,d0
                move.w  d0,$594(a5)
                move.w  $5F2(a5),d0
                add.w   d2,d0
                move.w  d0,$5F4(a5)
                move.w  $652(a5),d0
                add.w   d2,d0
                move.w  d0,$654(a5)
                move.w  $6B2(a5),d0
                add.w   d1,d0
                move.w  d0,$6B4(a5)
                move.w  $712(a5),d0
                add.w   d2,d0
                move.w  d0,$714(a5)
                move.w  $772(a5),d0
                add.w   d2,d0
                move.w  d0,$774(a5)
                move.w  $7D2(a5),d0
                sub.w   d1,d0
                move.w  d0,$7D4(a5)
                move.w  $832(a5),d0
                sub.w   d1,d0
                move.w  d0,$834(a5)
                move.w  $892(a5),d0
                sub.w   d2,d0
                move.w  d0,$894(a5)
                move.w  $8F2(a5),d0
                sub.w   d2,d0
                move.w  d0,$8F4(a5)
                move.b  $2C(a0),d1
                ext.w   d1
                move.w  d1,d2
                move.w  $1D2(a5),d0
                add.w   d2,d0
                move.w  d0,$1D4(a5)
                move.w  $232(a5),d0
                add.w   d2,d0
                move.w  d0,$234(a5)
                move.w  $292(a5),d0
                add.w   d2,d0
                move.w  d0,$294(a5)
                move.w  $2F2(a5),d0
                add.w   d2,d0
                move.w  d0,$2F4(a5)
                move.w  $352(a5),d0
                add.w   d2,d0
                move.w  d0,$354(a5)
                move.w  $3B2(a5),d0
                add.w   d2,d0
                move.w  d0,$3B4(a5)
                move.w  $412(a5),d0
                add.w   d2,d0
                move.w  d0,$414(a5)
                move.w  $472(a5),d0
                add.w   d2,d0
                move.w  d0,$474(a5)
                move.w  $4D2(a5),d0
                add.w   d2,d0
                move.w  d0,$4D4(a5)
                move.w  $532(a5),d0
                add.w   d2,d0
                move.w  d0,$534(a5)
                rts
; End of function Boss_ValkirieAlternateApplySymmetricAngles
; Update the alternate 12-channel pose stream
Boss_ValkirieAlternateUpdatePose:                       ; was: sub_592FE
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_ValkirieAlternateAdvancePoseInterpolation
Boss_ValkirieAlternateReadPoseCommand:                  ; was: loc_59308
                                        ; Boss_ValkirieAlternateHandlePoseLoopOrInterpolation+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_ValkirieAlternatePreparePartAngleProjection
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ValkirieAlternateHandlePoseControlWord
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ValkirieAlternateReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateHandlePoseControlWord:            ; was: loc_59324
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_ValkirieAlternateHandlePoseLoopOrInterpolation
                move.w  d3,$58(a5)
                bra.w   Boss_ValkirieAlternatePreparePartAngleProjection
; End of function Boss_ValkirieAlternateUpdatePose
Boss_ValkirieAlternateNoOp:                             ; was: nullsub_134
                rts
; End of function Boss_ValkirieAlternateNoOp

; Handle a pose loop command or begin an ordinary interpolation command
Boss_ValkirieAlternateHandlePoseLoopOrInterpolation:    ; was: sub_59338
                cmpi.w  #$FFFF,d3
                bne.s   Boss_ValkirieAlternateBeginPoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ValkirieAlternateReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateBeginPoseInterpolation:           ; was: loc_59348
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_ValkirieAlternateCalculatePoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_ValkirieAlternatePreparePartAngleProjection
Boss_ValkirieAlternateAdvancePoseInterpolation:         ; was: loc_59378
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$B,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_ValkirieAlternatePreparePartAngleProjection:       ; was: loc_59388
                                        ; Boss_ValkirieAlternateUpdatePose+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Boss_ValkirieAlternateHandlePoseLoopOrInterpolation
; Calculate deltas for the alternate 12-channel pose buffer
Boss_ValkirieAlternateCalculatePoseDeltas:              ; was: sub_59392
                movea.l $2FC(a5),a1
                moveq   #$B,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_ValkirieAlternateCalculatePoseDeltas
; Initialize the alternate twelve-channel pose buffer from bytes at a0
Boss_ValkirieAlternateInitializePoseChannels:
                moveq   #$B,d7                          ; was: sub_593A6
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_ValkirieAlternateInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_ValkirieAlternateStatePoses:   dc.w    $2020, 0, $2020, $C, $FFFF  ; was: word_593B2
                                        ; Boss_ValkirieAlternateRenderState4   o
Boss_ValkirieAlternatePoseTable:    dc.w    $8080, $8080, $8040, $6060, $A040, 0, $8080, $8080  ; was: word_593BC
                dc.w    $8040, $6060, $A040, 0

; Intro stop position
