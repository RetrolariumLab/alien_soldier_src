Boss_WolfGaropaUpdateMetaspriteAndOrb:                  ; CODE XREF: Boss_WolfGaropaUpdateInitialPose+12   j  ; was: sub_50220
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+A8   j
                moveq   #$18,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                bsr.w   Boss_WolfGaropaSpawnOrbitSpark
                bsr.w   Boss_WolfGaropaUpdateOrbPalettePulse
                move.w  $10(a5),$35E(a5)
                move.w  $14(a5),$3BC(a5)
                move.w  #$130,d0
                sub.w   $35E(a5),d0
                move.w  $3BC(a5),d1
                addi.w  #$10,d1
                move.w  d0,(SecondaryCameraXPos).w
                add.w   (PlaneBShakeOffset).w,d0
                move.w  d1,(SecondaryCameraYPos).w
                move.w  (SecondaryCameraXPos).w,d0
                bmi.s   Boss_WolfGaropaCheckOrbScrollOffsetMinimum
                cmpi.w  #$108,d0
                bmi.s   Boss_WolfGaropaStoreOrbAttachmentOrigins
Boss_WolfGaropaClampOrbScrollOffsetMinimum:             ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+50   j  ; was: loc_50264
                move.w  #$FEF6,(SecondaryCameraXPos).w
                bra.s   Boss_WolfGaropaStoreOrbAttachmentOrigins
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckOrbScrollOffsetMinimum:             ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+3C   j  ; was: loc_5026C
                cmpi.w  #$FEF6,d0
                bmi.s   Boss_WolfGaropaClampOrbScrollOffsetMinimum
Boss_WolfGaropaStoreOrbAttachmentOrigins:               ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+42   j  ; was: loc_50272
                                        ; Boss_WolfGaropaUpdateMetaspriteAndOrb+4A   j
                move.w  $35E(a5),d0
                addi.w  #-$A,d0
                move.w  d0,$970(a5)
                move.w  $3BC(a5),d0
                addi.w  #-$34,d0
                move.w  d0,$974(a5)
                move.w  $53E(a5),d2
                sub.w   $A16(a5),d2
                bmi.w   Boss_WolfGaropaCheckNegativeOrbFacingDelta
                cmpi.w  #4,d2
                bmi.s   Boss_WolfGaropaPositionOrbFacingPart
                cmpi.w  #$100,d2
                bpl.w   Boss_WolfGaropaDecreaseOrbFacingAngle
Boss_WolfGaropaIncreaseOrbFacingAngle:                  ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+9A   j  ; was: loc_502A4
                addq.w  #2,$A16(a5)
                andi.w  #$1FE,$A16(a5)
                bra.s   Boss_WolfGaropaPositionOrbFacingPart
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckNegativeOrbFacingDelta:             ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+72   j  ; was: loc_502B0
                cmpi.w  #$FFFC,d2
                bpl.s   Boss_WolfGaropaPositionOrbFacingPart
                cmpi.w  #$FF00,d2
                bmi.w   Boss_WolfGaropaIncreaseOrbFacingAngle
Boss_WolfGaropaDecreaseOrbFacingAngle:                  ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+80   j  ; was: loc_502BE
                subq.w  #2,$A16(a5)
                andi.w  #$1FE,$A16(a5)
Boss_WolfGaropaPositionOrbFacingPart:                   ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+7A   j  ; was: loc_502C8
                                        ; Boss_WolfGaropaUpdateMetaspriteAndOrb+8E   j
                move.w  $A16(a5),d0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #3,d1
                asl.l   #4,d2
                swap    d1
                swap    d2
                move.w  $53C(a5),d0
                asr.w   #3,d0
                add.w   d0,d1
                add.w   $35E(a5),d2
                addi.w  #$12,d2
                move.w  d2,$9D0(a5)
                add.w   $3BC(a5),d1
                addi.w  #-$47,d1
                move.w  d1,$9D4(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  $3C(a0),d5
                ext.w   d5
                move.b  $40(a0),d6
                ext.w   d6
                move.w  $35E(a5),d2
                addi.w  #$38,d2                         ; '8'
                add.w   d5,d2
                move.w  d2,$A90(a5)
                move.w  $3BC(a5),d3
                addi.w  #-$1C,d3
                add.w   d6,d3
                move.w  d3,$A94(a5)
                moveq   #0,d7
                move.b  $38(a0),d7
                cmpi.w  #$30,d7                         ; '0'
                bmi.s   Boss_WolfGaropaSelectNearPlayerMapping
                move.l  #Boss_WolfGaropaFarPlayerMapping,d1
                addi.w  #$24,d2                         ; '$'
                addi.w  #-6,d3
                bra.s   Boss_WolfGaropaStorePlayerRelativeMapping
; ---------------------------------------------------------------------------
Boss_WolfGaropaSelectNearPlayerMapping:                 ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+11C   j  ; was: loc_5034E
                move.l  #Boss_WolfGaropaNearPlayerMapping,d1
                addi.w  #$1E,d2
                addi.w  #-$12,d3
Boss_WolfGaropaStorePlayerRelativeMapping:              ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+12C   j  ; was: loc_5035C
                move.l  d1,$A88(a5)
                move.l  #Boss_WolfGaropaOrbNeutralMapping,d1
                cmpi.w  #$40,d7                         ; '@'
                bpl.s   Boss_WolfGaropaStoreOrbMappingAndPosition
                move.l  #Boss_WolfGaropaOrbAlternateMapping,d1
Boss_WolfGaropaStoreOrbMappingAndPosition:              ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+14A   j  ; was: loc_50372
                move.l  d1,$AE8(a5)
                move.b  $44(a0),d6
                ext.w   d6
                move.w  d2,$AF0(a5)
                add.w   d6,d3
                move.w  d3,$AF4(a5)
                tst.w   (BossHealth).w
                bne.s   Boss_WolfGaropaAdvanceOrbPalettePhase
                bra.s   Boss_WolfGaropaUpdateOrbFrameAndTiles
; ---------------------------------------------------------------------------
Boss_WolfGaropaAdvanceOrbPalettePhase:                  ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+16A   j  ; was: loc_5038E
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_WolfGaropaUpdateOrbFrameAndTiles
                addi.w  #$20,(PaletteActiveColor63).w   ; ' '
                andi.w  #$EE,(PaletteActiveColor63).w
Boss_WolfGaropaUpdateOrbFrameAndTiles:                  ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+16C   j  ; was: loc_503A4
                                        ; Boss_WolfGaropaUpdateMetaspriteAndOrb+176   j
                bsr.w   Boss_WolfGaropaUpdateOrbPositionAndFrame
                bra.w   Gfx_UpdateWolfGaropaOrbTiles
; End of function Boss_WolfGaropaUpdateMetaspriteAndOrb
; Set the orb-facing flag from its horizontal position relative to the camera
Boss_WolfGaropaUpdateOrbFacingFlag:                     ; CODE XREF: Boss_WolfGaropaUpdateBattleStartWait+B2   p  ; was: sub_503AC
                move.w  (PlayerCenterX).w,d0
                sub.w   $9D0(a5),d0
                move.w  d0,d1
                bpl.s   Boss_WolfGaropaCheckOrbFacingDistance
                neg.w   d0
Boss_WolfGaropaCheckOrbFacingDistance:                  ; CODE XREF: Boss_WolfGaropaUpdateOrbFacingFlag+A   j  ; was: loc_503BA
                cmpi.w  #6,d0
                bmi.s   Boss_WolfGaropaOrbFacingUpdateReturn
                bset    #3,$9CE(a5)
                tst.w   d1
                bpl.s   Boss_WolfGaropaOrbFacingUpdateReturn
                bclr    #3,$9CE(a5)
Boss_WolfGaropaOrbFacingUpdateReturn:                   ; CODE XREF: Boss_WolfGaropaUpdateOrbFacingFlag+12   j  ; was: locret_503D0
                                        ; Boss_WolfGaropaUpdateOrbFacingFlag+1C   j
                rts
; End of function Boss_WolfGaropaUpdateOrbFacingFlag
; Lazily initialize attack effect A and load its graphics
Boss_WolfGaropaTryLoadAttackEffectA:                    ; CODE XREF: Boss_WolfGaropaUpdateLaunchMotion+6   p  ; was: sub_503D2
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Boss_WolfGaropaLoadAttackEffectA
Boss_WolfGaropaAttackEffectAReturn:                     ; CODE XREF: Boss_WolfGaropaTryLoadAttackEffectA+E   j  ; was: locret_503D8
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaLoadAttackEffectA:                       ; CODE XREF: Boss_WolfGaropaTryLoadAttackEffectA+4   j  ; was: loc_503DA
                cmpi.w  #$10,(PrimaryCameraXPosition).w
                bpl.s   Boss_WolfGaropaAttackEffectAReturn
                move.b  #1,(WolfGaropaEffectActive).w
                moveq   #0,d0
                move.w  #$E2,d1
                bsr.w   Effect_InitializeWolfGaropaBoundaryPair
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     Boss_WolfGaropaAttackEffectATileTransfer(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedColumns).l
                lea     Boss_WolfGaropaAttackEffectAIndexedRowDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_WolfGaropaTryLoadAttackEffectA
; ---------------------------------------------------------------------------
Boss_WolfGaropaAttackEffectATileTransfer:   dc.w    $4658, $4000, $102, $2A2B, $2C2D, $2E2F  ; was: word_50414
                                        ; DATA XREF: Boss_WolfGaropaTryLoadAttackEffectA+2A   o
Boss_WolfGaropaAttackEffectAIndexedRowDescriptor:   dc.w    $4C50, $4000, $401, $3031, $3233, $2634, $3536, $3738  ; was: word_50420
                                        ; DATA XREF: Boss_WolfGaropaTryLoadAttackEffectA+36   o

; Gate attack-effect-B initialization on its shared loaded flag
Boss_WolfGaropaTryLoadAttackEffectB:                    ; CODE XREF: Boss_WolfGaropaUpdateUpperType424Sequence+1C   p  ; was: sub_50430
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Boss_WolfGaropaLoadAttackEffectB
Boss_WolfGaropaAttackEffectBReturn:                     ; CODE XREF: Boss_WolfGaropaLoadAttackEffectB+6   j  ; was: locret_50436
                rts
; End of function Boss_WolfGaropaTryLoadAttackEffectB
; Initialize attack effect B and queue its indexed tilemap rows
Boss_WolfGaropaLoadAttackEffectB:                       ; CODE XREF: Boss_WolfGaropaTryLoadAttackEffectB+4   j  ; was: sub_50438
                cmpi.w  #$10,(PrimaryCameraXPosition).w
                bpl.s   Boss_WolfGaropaAttackEffectBReturn
                move.b  #1,(WolfGaropaEffectActive).w
                moveq   #1,d0
                move.w  #$DE,d1
                bsr.w   Effect_InitializeWolfGaropaBoundaryPair
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     Boss_WolfGaropaAttackEffectBIndexedRowDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_WolfGaropaLoadAttackEffectB
; ---------------------------------------------------------------------------
Boss_WolfGaropaAttackEffectBIndexedRowDescriptor:   dc.w    $4458, $4000, $101, $3C3B, $3D3F  ; was: word_50466
                                        ; DATA XREF: Boss_WolfGaropaLoadAttackEffectB+22   o

; Unreferenced loader for attack-effect graphics variant C
Boss_WolfGaropaTryLoadAttackEffectC:                    ; was: sub_50470
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Boss_WolfGaropaLoadAttackEffectC
Boss_WolfGaropaAttackEffectCReturn:                     ; CODE XREF: Boss_WolfGaropaTryLoadAttackEffectC+E   j  ; was: locret_50476
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaLoadAttackEffectC:                       ; CODE XREF: Boss_WolfGaropaTryLoadAttackEffectC+4   j  ; was: loc_50478
                cmpi.w  #$10,(PrimaryCameraXPosition).w
                bpl.s   Boss_WolfGaropaAttackEffectCReturn
                move.b  #1,(WolfGaropaEffectActive).w
                lea     Boss_WolfGaropaAttackEffectCIndexedRowDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_WolfGaropaTryLoadAttackEffectC
; ---------------------------------------------------------------------------
Boss_WolfGaropaAttackEffectCIndexedRowDescriptor:   dc.w    $4C50, $4000, $301, $4243, $4445, $4647, $4849  ; was: word_50492
                                        ; DATA XREF: Boss_WolfGaropaTryLoadAttackEffectC+16   o

; Update the auxiliary orb mapping, center, radius, and attached endpoint
Boss_WolfGaropaUpdateOrbPositionAndFrame:               ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb:Boss_WolfGaropaUpdateOrbFrameAndTiles   p  ; was: sub_504A0
                subq.w  #4,$53C(a5)
                bpl.s   Boss_WolfGaropaCalculateOrbCenter
                clr.w   $53C(a5)
Boss_WolfGaropaCalculateOrbCenter:                      ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+4   j  ; was: loc_504AA
                move.w  $A76(a5),d0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                moveq   #$20,d3                         ; ' '
                moveq   #$36,d4                         ; '6'
                sub.w   $53C(a5),d3
                sub.w   $53C(a5),d4
                muls.w  d3,d1
                muls.w  d4,d2
                swap    d1
                swap    d2
                cmpi.w  #$120,d0
                bmi.s   Boss_WolfGaropaApplyOrbVerticalBias
                cmpi.w  #$1E0,d0
                bmi.s   Boss_WolfGaropaStoreOrbCenter
Boss_WolfGaropaApplyOrbVerticalBias:                    ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+34   j  ; was: loc_504DC
                addq.w  #6,d1
Boss_WolfGaropaStoreOrbCenter:                          ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+3A   j  ; was: loc_504DE
                add.w   $974(a5),d1
                add.w   $970(a5),d2
                move.w  d1,$A34(a5)
                move.w  d2,$A30(a5)
                lea     Boss_WolfGaropaOrbDirectionalMappingTable(pc),a1
                nop
                movea.w #(TwentyEighthEntityType-M68K_RAM),a0
                andi.w  #$E7FF,$E(a0)
                jsr     (Sprite_UpdateFourDirectionFrame).l
                movea.w #(ThirtyFirstEntityType-M68K_RAM),a0
                jsr     (Gfx_AnimateWolfGaropaOrbAtA0).l
                move.w  $6BC(a5),d0
                btst    #3,$65E(a5)
                beq.s   Boss_WolfGaropaReduceOrbEndpointRadius
                addi.w  #$C,d0
                cmpi.w  #$180,d0
                bmi.s   Boss_WolfGaropaStoreOrbEndpointRadius
                move.w  #$180,d0
                bra.s   Boss_WolfGaropaStoreOrbEndpointRadius
; ---------------------------------------------------------------------------
Boss_WolfGaropaReduceOrbEndpointRadius:                 ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+78   j  ; was: loc_5052A
                subq.w  #2,d0
                bpl.s   Boss_WolfGaropaStoreOrbEndpointRadius
                bclr    #7,$B42(a5)
                clr.w   $6BC(a5)
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaStoreOrbEndpointRadius:                  ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+82   j  ; was: loc_5053A
                                        ; Boss_WolfGaropaUpdateOrbPositionAndFrame+88   j
                move.w  d0,$6BC(a5)
                bset    #7,$B42(a5)
                btst    #1,$65E(a5)
                beq.s   Boss_WolfGaropaPositionOrbEndpoint
                btst    #2,(FrameCounter+1).w
                beq.s   Boss_WolfGaropaPositionOrbEndpoint
                bclr    #7,$B42(a5)
Boss_WolfGaropaPositionOrbEndpoint:                     ; CODE XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+AA   j  ; was: loc_5055A
                                        ; Boss_WolfGaropaUpdateOrbPositionAndFrame+B2   j
                move.w  $A76(a5),d3
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d3.w),d1
                move.w  (a0,d3.w),d2
                muls.w  d0,d1
                muls.w  d0,d2
                swap    d1
                swap    d2
                add.w   $A34(a5),d1
                add.w   $A30(a5),d2
                move.w  d1,$B54(a5)
                move.w  d2,$B50(a5)
                rts
; End of function Boss_WolfGaropaUpdateOrbPositionAndFrame
; ---------------------------------------------------------------------------
Boss_WolfGaropaOrbDirectionalMappingTable:  dc.l    Boss_WolfGaropaOrbDirectionMapping0  ; DATA XREF: Boss_WolfGaropaUpdateOrbPositionAndFrame+4E   o  ; was: off_50586
                dc.l    Boss_WolfGaropaOrbDirectionMapping1
                dc.l    Boss_WolfGaropaOrbDirectionMapping2
                dc.l    Boss_WolfGaropaOrbDirectionMapping3

; Select the orb tile-transfer descriptor from the global frame counter
Gfx_UpdateWolfGaropaOrbTiles:                           ; CODE XREF: Boss_WolfGaropaUpdateMetaspriteAndOrb+188   j  ; was: sub_50596
                move.w  (FrameCounter).w,d0
                asl.w   #1,d0
                andi.w  #$C,d0
                movea.l Boss_WolfGaropaOrbTileTransferTable(pc,d0.w),a0
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_UpdateWolfGaropaOrbTiles
; ---------------------------------------------------------------------------
Boss_WolfGaropaOrbTileTransferTable:    dc.l    Boss_WolfGaropaOrbTileTransferFrame0  ; DATA XREF: Gfx_UpdateWolfGaropaOrbTiles+A   r  ; was: off_505AA
                dc.l    Boss_WolfGaropaOrbTileTransferFrame1
                dc.l    Boss_WolfGaropaOrbTileTransferFrame2
                dc.l    Boss_WolfGaropaOrbTileTransferFrame1
Boss_WolfGaropaOrbTileTransferFrame0:   dc.b    $64, $92, $20, 0, 1, 0, $C, $D  ; was: byte_505BA
                                        ; DATA XREF: ROM:Boss_WolfGaropaOrbTileTransferTable   o
Boss_WolfGaropaOrbTileTransferFrame1:   dc.b    $64, $92, $20, 0, 1, 0, $E, $F  ; was: byte_505C2
                                        ; DATA XREF: ROM:000505AE   o
                                        ; ROM:000505B6   o
Boss_WolfGaropaOrbTileTransferFrame2:   dc.b    $64, $92, $20, 0, 1, 0, $10, $11  ; was: byte_505CA
                                        ; DATA XREF: ROM:000505B2   o

; Interpret pose-script commands and update all composite-part angles
Boss_WolfGaropaAdvancePoseScript:                       ; CODE XREF: Boss_WolfGaropaUpdateInitialPose+E   p  ; was: sub_505D2
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+7A   p
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_WolfGaropaTickPoseInterpolation
Boss_WolfGaropaReadNextPoseCommand:                     ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+24   j  ; was: loc_505DC
                                        ; Boss_WolfGaropaAdvancePoseScript+44   j
                move.w  $58(a5),d0
                bmi.w   Boss_WolfGaropaStorePoseAngleGroup1
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_WolfGaropaCheckPoseControlCommand
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_WolfGaropaReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckPoseControlCommand:                 ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+18   j  ; was: loc_505F8
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_WolfGaropaHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaHandlePoseLoopCommand:                   ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+2E   j  ; was: loc_50608
                cmpi.w  #$FFFF,d3
                bne.s   Boss_WolfGaropaBeginPoseCommandInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_WolfGaropaReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginPoseCommandInterpolation:           ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+3A   j  ; was: loc_50618
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_WolfGaropaPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_WolfGaropaBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_WolfGaropaStorePoseAngleGroup1
Boss_WolfGaropaTickPoseInterpolation:                   ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+8   j  ; was: loc_5064A
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$12,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_WolfGaropaStorePoseAngleGroup1:                    ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+E   j  ; was: loc_5065A
                                        ; Boss_WolfGaropaAdvancePoseScript+76   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.l  #Boss_WolfGaropaPoseAngleOutsideRangeMapping,d5
                move.l  #Boss_WolfGaropaPoseAngleMidRangeMapping,d6
                move.b  (a0),d0
                ext.w   d0
                move.w  d0,d1
                add.w   $B2(a5),d0
                move.w  d0,$B4(a5)
                add.w   $112(a5),d1
                move.w  d1,$114(a5)
                move.b  4(a0),d0
                ext.w   d0
                move.w  d0,d1
                add.w   $172(a5),d0
                move.w  d0,$174(a5)
                add.w   $1D2(a5),d1
                move.w  d1,$1D4(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                move.w  d0,$296(a5)
                move.b  $C(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$2F6(a5)
                move.w  d1,$356(a5)
                move.b  $10(a0),d0
                asl.w   #1,d0
                move.w  d0,d2
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                and.w   d7,d2
                move.l  d5,$368(a5)
                cmpi.w  #$10,d2
                bmi.s   Boss_WolfGaropaStorePoseAngleGroup2
                cmpi.w  #$100,d2
                bpl.s   Boss_WolfGaropaStorePoseAngleGroup2
                move.l  d6,$368(a5)
Boss_WolfGaropaStorePoseAngleGroup2:                    ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+106   j  ; was: loc_506E4
                                        ; Boss_WolfGaropaAdvancePoseScript+10C   j
                move.b  $14(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                move.w  d0,$476(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$4D6(a5)
                move.w  d1,$536(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                move.w  d0,d2
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                and.w   d7,d2
                move.l  d5,$548(a5)
                cmpi.w  #$10,d2
                bmi.s   Boss_WolfGaropaStorePoseAngleGroup3
                cmpi.w  #$100,d2
                bpl.s   Boss_WolfGaropaStorePoseAngleGroup3
                move.l  d6,$548(a5)
Boss_WolfGaropaStorePoseAngleGroup3:                    ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+14E   j  ; was: loc_5072C
                                        ; Boss_WolfGaropaAdvancePoseScript+154   j
                move.b  $20(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$5F6(a5)
                move.w  d0,$656(a5)
                move.b  $24(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$6B6(a5)
                move.w  d1,$716(a5)
                move.b  $28(a0),d0
                asl.w   #1,d0
                move.w  d0,d2
                addi.w  #$10,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$776(a5)
                and.w   d7,d2
                move.l  d5,$728(a5)
                cmpi.w  #$10,d2
                bmi.s   Boss_WolfGaropaStorePoseAngleGroup4
                cmpi.w  #$100,d2
                bpl.s   Boss_WolfGaropaStorePoseAngleGroup4
                move.l  d6,$728(a5)
Boss_WolfGaropaStorePoseAngleGroup4:                    ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+19A   j  ; was: loc_50778
                                        ; Boss_WolfGaropaAdvancePoseScript+1A0   j
                move.b  $2C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$7D6(a5)
                move.w  d0,$836(a5)
                move.b  $30(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$896(a5)
                move.w  d1,$8F6(a5)
                move.b  $34(a0),d0
                asl.w   #1,d0
                move.w  d0,d2
                add.w   d1,d0
                addi.w  #$10,d0
                and.w   d7,d0
                move.w  d0,$956(a5)
                and.w   d7,d2
                move.l  d5,$908(a5)
                cmpi.w  #$10,d2
                bmi.s   Boss_WolfGaropaPoseScriptReturn
                cmpi.w  #$100,d2
                bpl.s   Boss_WolfGaropaPoseScriptReturn
                move.l  d6,$908(a5)
Boss_WolfGaropaPoseScriptReturn:                        ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+1E6   j  ; was: locret_507C4
                                        ; Boss_WolfGaropaAdvancePoseScript+1EC   j
                rts
; End of function Boss_WolfGaropaAdvancePoseScript
; Initialize interpolation deltas for the next pose-script command
Boss_WolfGaropaBeginPoseInterpolation:                  ; CODE XREF: Boss_WolfGaropaAdvancePoseScript+5C   p  ; was: sub_507C6
                lea     Boss_WolfGaropaPoseTable(pc),a1
                nop
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_WolfGaropaBeginPoseInterpolation
; Initialize nineteen Wolf Garopa pose channels from bytes at a0
Boss_WolfGaropaInitializePoseChannels:                  ; was: sub_507DC
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_WolfGaropaInitializePoseChannels
; ---------------------------------------------------------------------------
                dc.b    $FF, $FF
Boss_WolfGaropaHorizontalMotionAPoses:  dc.w    $506, $36, $8089, $303, $48, $808A, $605, $5A, $808B, $205, $6C, $8004, $303, $6C, $80D, $12  ; was: word_507EA
                                        ; DATA XREF: Boss_WolfGaropaUpdateHorizontalTargetMotion+1C   o
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+50   o
                dc.w    $505, $12, $808, $24, $FFFE
Boss_WolfGaropaHorizontalMotionPoseB:   dc.w    $90A, $36, $8089, $404, $48, $808A, $807, $5A, $808B, $306, $6C, $8004, $303, $6C, $80D, $12  ; was: word_50814
                                        ; DATA XREF: Boss_WolfGaropaUpdateHorizontalTargetMotion:Boss_WolfGaropaAccelerateTowardLeftTarget   o
                dc.w    $505, $12, $808, $24, $FFFE
Boss_WolfGaropaBallisticTransitionBPoses:   dc.w    $810, $B4, $606, $B4, $8040, $606, $B4, $8089, $FFFE  ; was: word_5083E
                                        ; DATA XREF: Boss_WolfGaropaUpdateBallisticTransitionB:Boss_WolfGaropaAdvanceBallisticTransitionPose   o
Boss_WolfGaropaHorizontalAirbornePoses: dc.w    $C0C, $7E, $808B, $A0A, $90, $8088, $C0C, $A2, $808A, $A0A, $B4, $8089, $FFFF  ; was: word_50850
                                        ; DATA XREF: Boss_WolfGaropaUpdateBallisticTransitionB:Boss_WolfGaropaAdvanceAirbornePose   o
Boss_WolfGaropaFinalBallisticPoses: dc.w    $408, $24, $808, $24, $FFFE  ; was: word_5086A
                                        ; DATA XREF: Boss_WolfGaropaUpdateFinalBallisticMotion+10   o
Boss_WolfGaropaLaunchPoses: dc.w    $506, $36, $8089, $203, $48, $808A, $405, $5A, $808B, $104, $FC, $8044, $304, $FC, $A12, $C6  ; was: word_50874
                                        ; DATA XREF: Boss_WolfGaropaUpdateInitialPose+8   o
                                        ; sub_50160   o
                dc.w    $A0A, $C6, $606, $D8, $606, $EA, $FFFE
Boss_WolfGaropaPoseTable:   binclude "data/other/word_508A2.bin"  ; was: word_508A2
Boss_WolfGaropaPoseTargetsEnd:                          ; was: word_508A2_End

; Calculate the player angle and steer the orb toward it
Boss_WolfGaropaSteerOrbAngleTowardPlayer:               ; CODE XREF: Boss_WolfGaropaUpdateBattleStartWait+BE   p  ; was: sub_509B0
                movea.w #(TwentyEighthEntityType-M68K_RAM),a5
                jsr     (Math_CalculateAngleToPlayer).l
                movea.w #(Entity_ObjectPool-M68K_RAM),a5
                moveq   #0,d3
                moveq   #4,d7
                cmpi.w  #$14,$4DE(a5)
                beq.s   Boss_WolfGaropaApproachOrbAngle
                tst.w   $4DE(a5)
                bmi.s   Boss_WolfGaropaApproachOrbAngle
                moveq   #2,d7
; End of function Boss_WolfGaropaSteerOrbAngleTowardPlayer
; Approach the requested wrapped orb angle and report completion in D3
Boss_WolfGaropaApproachOrbAngle:                        ; CODE XREF: Boss_WolfGaropaUpdateBattleStartWait+44   j  ; was: sub_509D2
                                        ; Boss_WolfGaropaUpdateBattleStartWait+16C   p
                sub.w   $A76(a5),d2
                bmi.w   Boss_WolfGaropaCheckNegativeOrbAngleDelta
                cmpi.w  #$C,d2
                bmi.w   Boss_WolfGaropaOrbAngleReached
                cmpi.w  #$100,d2
                bpl.w   Boss_WolfGaropaDecreaseOrbAngle
Boss_WolfGaropaIncreaseOrbAngle:                        ; CODE XREF: Boss_WolfGaropaApproachOrbAngle+2E   j  ; was: loc_509EA
                add.w   d7,$A76(a5)
                andi.w  #$1FE,$A76(a5)
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckNegativeOrbAngleDelta:              ; CODE XREF: Boss_WolfGaropaApproachOrbAngle+4   j  ; was: loc_509F6
                cmpi.w  #$FFF4,d2
                bpl.s   Boss_WolfGaropaOrbAngleReached
                cmpi.w  #$FF00,d2
                bmi.w   Boss_WolfGaropaIncreaseOrbAngle
Boss_WolfGaropaDecreaseOrbAngle:                        ; CODE XREF: Boss_WolfGaropaApproachOrbAngle+14   j  ; was: loc_50A04
                sub.w   d7,$A76(a5)
                andi.w  #$1FE,$A76(a5)
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaOrbAngleReached:                         ; CODE XREF: Boss_WolfGaropaApproachOrbAngle+C   j  ; was: loc_50A10
                                        ; Boss_WolfGaropaApproachOrbAngle+28   j
                addq.w  #1,d3
                rts
; End of function Boss_WolfGaropaApproachOrbAngle
; Allocate the two records forming the orb-emitted projectile pair
Boss_WolfGaropaSpawnOrbProjectilePair:                  ; CODE XREF: Boss_WolfGaropaUpdateBattleStartWait+132   j  ; was: sub_50A14
                move.w  #1,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_WolfGaropaOrbProjectilePairReturn
                movea.l #Weapon_SharedShotInitialSpriteFrame,a1
                jsr     (Sprite_InitFromTable).l
                move.b  #4,$20(a0)
                move.w  #$8040,2(a0)
                movea.w a0,a3
                move.w  #$1C,$53C(a5)
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_WolfGaropaOrbProjectilePairReturn
                move.b  #$36,d0                         ; '6'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$408,(a0)
                move.w  #$CC00,2(a0)
                move.b  #$42,$21(a0)                    ; 'B'
                move.l  #$FE02FE02,$2C(a0)
                move.w  #4,$26(a0)
                move.b  #8,$20(a0)
                move.w  $A76(a5),d0
                move.w  d0,d2
                lea     (Math_SineTable).l,a2
                move.w  Math_QuarterSineTable-Math_SineTable(a2,d0.w),d3
                move.w  (a2,d0.w),d4
                muls.w  #$80,d3
                muls.w  #$80,d4
                move.l  d3,d5
                move.l  d4,d6
                swap    d5
                swap    d6
                add.w   $A34(a5),d5
                add.w   $A30(a5),d6
                move.w  d5,$14(a0)
                move.w  d6,$10(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,d5
                move.b  (RandomNumberState+1).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,d6
                move.w  d5,$14(a3)
                move.w  d6,$10(a3)
                asr.l   #2,d3
                asr.l   #2,d4
                move.l  d3,$1C(a0)
                move.l  d4,$18(a0)
                move.w  #$8480,$E(a0)
                jmp     Projectile_SelectWolfGaropaDirectionMapping
; ---------------------------------------------------------------------------
Boss_WolfGaropaOrbProjectilePairReturn:                 ; CODE XREF: Boss_WolfGaropaSpawnOrbProjectilePair+12   j  ; was: locret_50AEE
                                        ; Boss_WolfGaropaSpawnOrbProjectilePair+3C   j
                rts
; End of function Boss_WolfGaropaSpawnOrbProjectilePair
; Wave projectile
Projectile_WolfGaropaOrbShot:                           ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_50AF0
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_WolfGaropaOrbShotFallback
                btst    #7,$22(a5)
                beq.s   Projectile_WolfGaropaCheckOrbShotArenaBounds
                btst    #4,$22(a5)
                beq.s   Projectile_WolfGaropaReflectOrbShotHorizontally
Projectile_WolfGaropaOrbShotFallback:                   ; CODE XREF: Projectile_WolfGaropaOrbShot+4   j  ; was: loc_50B06
                btst    #0,(RandomNumberState+1).w
                bne.s   Projectile_WolfGaropaMarkOrbShotForRemoval
                jsr     (Pickup_SpawnSmallFromCurrentObject).l
                ori.w   #$A00,2(a5)
                move.l  #$FFFA8000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_WolfGaropaReflectOrbShotHorizontally:        ; CODE XREF: Projectile_WolfGaropaOrbShot+14   j  ; was: loc_50B24
                neg.l   $18(a5)
Projectile_WolfGaropaConvertOrbShotToType160:           ; CODE XREF: Projectile_WolfGaropaOrbShot+8C   j  ; was: loc_50B28
                neg.l   $1C(a5)
                move.l  #SharedCombatSpriteAnimation03,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_WolfGaropaCheckOrbShotArenaBounds:           ; CODE XREF: Projectile_WolfGaropaOrbShot+C   j  ; was: loc_50B3A
                move.w  $10(a5),d0
                cmpi.w  #$78,d0                         ; 'x'
                bpl.s   Projectile_WolfGaropaCheckOrbShotRemainingBounds
Projectile_WolfGaropaMarkOrbShotForRemoval:             ; CODE XREF: Projectile_WolfGaropaOrbShot+1C   j  ; was: loc_50B44
                                        ; Projectile_WolfGaropaOrbShot+60   j
                bset    #4,2(a5)
Projectile_WolfGaropaOrbShotReturn:                     ; CODE XREF: Projectile_WolfGaropaOrbShot+70   j  ; was: locret_50B4A
                rts
; ---------------------------------------------------------------------------
Projectile_WolfGaropaCheckOrbShotRemainingBounds:       ; CODE XREF: Projectile_WolfGaropaOrbShot+52   j  ; was: loc_50B4C
                cmpi.w  #$288,d0
                bpl.s   Projectile_WolfGaropaMarkOrbShotForRemoval
                cmpi.w  #$98,$14(a5)
                bmi.s   Projectile_WolfGaropaMarkOrbShotForRemoval
                cmpi.w  #$150,$14(a5)
                bmi.s   Projectile_WolfGaropaOrbShotReturn
                move.b  #$37,d0                         ; '7'
                jsr     (Sound_QueueSFXRequest).l
                move.l  $18(a5),d0
                asr.l   #2,d0
                subi.l  #$28000,d0
                move.l  d0,$18(a5)
                bra.s   Projectile_WolfGaropaConvertOrbShotToType160
; End of function Projectile_WolfGaropaOrbShot
; Defeat sequence init
