; Sharpsteel complex-phase states, blade collision/graphics, and pose commands

Boss_SharpsteelWaitForComplexAlignmentState:            ; was: sub_484E4
                move.w  $314(a5),d0
                sub.w   (Entity57YPos).w,d0
                cmpi.w  #$38,d0                         ; '8'
                bmi.s   Boss_SharpsteelInitializeComplexAcceleration
                bsr.w   Boss_SharpsteelUpdateBladeAnglesFromPose
                bra.w   Boss_SharpsteelUpdateBladePresentation
; ---------------------------------------------------------------------------
Boss_SharpsteelInitializeComplexAcceleration:
                addq.w  #2,4(a5)
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                bset    #0,(Entity57Work5A).w
                clr.l   (Entity57YVel).w
                move.l  #$8000,(Entity57XVel).w
                move.l  #$A000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bmi.s   Boss_SharpsteelAccelerateComplexMotionState
                neg.l   $18(a5)
                neg.l   (Entity57XVel).w
; Advances the complex-phase motion until the blade animation trigger fires
Boss_SharpsteelAccelerateComplexMotionState:            ; was: loc_48534
                addi.l  #$1200,$1C(a5)
                btst    #0,$23E(a5)
                bne.s   Boss_SharpsteelBeginComplexOscillation
                move.w  $314(a5),d0
                subi.w  #$30,d0                         ; '0'
                move.w  d0,(Entity57YPos).w
                lea     Boss_SharpsteelComplexOscillationPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginComplexOscillation:
                addq.w  #2,4(a5)
                bset    #1,(Entity57Work5A).w
                clr.w   $11E(a5)
                addi.l  #$A000,$1C(a5)
                move.l  #$15000,d0
                tst.w   $18(a5)
                bpl.s   Boss_SharpsteelApplyComplexHorizontalVelocity
                neg.l   d0
Boss_SharpsteelApplyComplexHorizontalVelocity:
                move.l  d0,$18(a5)
; Oscillates vertically until the blade pose supplies its completion trigger
Boss_SharpsteelComplexOscillationState:                 ; was: loc_48582
                tst.w   $58(a5)
                bmi.s   Boss_SharpsteelBeginBladeShotBurst
                bsr.w   Boss_SharpsteelUpdateVerticalOscillation
                lea     Boss_SharpsteelComplexOscillationPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginBladeShotBurst:
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $23E(a5)
                move.w  #3,$11C(a5)
; Emits pose-triggered blade shots while steering toward the player
Boss_SharpsteelBladeShotBurstState:                     ; was: loc_485AE
                btst    #1,$23E(a5)
                beq.s   Boss_SharpsteelCheckBladeShotBurstRepeat
                bsr.w   Boss_SharpsteelSpawnSixBladeShots
Boss_SharpsteelCheckBladeShotBurstRepeat:
                btst    #0,$23E(a5)
                beq.s   Boss_SharpsteelUpdateBladeShotBurstMotion
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                subq.w  #1,$11C(a5)
                bmi.s   Boss_SharpsteelFinishBladeShotBurst
Boss_SharpsteelUpdateBladeShotBurstMotion:
                bsr.w   Boss_SharpsteelSteerTowardPlayerX
                bsr.w   Boss_SharpsteelUpdateVerticalOscillation
                lea     Boss_SharpsteelComplexExitPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishBladeShotBurst:
                addq.w  #2,4(a5)
; Falls to the lower bound before returning to the post-dive cycle selector
Boss_SharpsteelComplexExitFallState:                    ; was: loc_485E8
                addi.l  #$2000,$1C(a5)
                cmpi.w  #$200,$14(a5)
                bpl.w   Boss_SharpsteelSelectPostDiveCycle
                lea     Boss_SharpsteelComplexExitPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; End of function Boss_SharpsteelWaitForComplexAlignmentState
; Alternates vertical acceleration between the Y $170/$172 bounds
Boss_SharpsteelUpdateVerticalOscillation:               ; was: sub_48604
                                        ; Boss_SharpsteelWaitForComplexAlignmentState+F2   p
                tst.w   $11E(a5)
                bne.s   Boss_SharpsteelUpdateDownwardOscillation
                move.l  $1C(a5),d0
                bpl.s   Boss_SharpsteelAccelerateOscillationUpward
                cmpi.w  #$170,$14(a5)
                bmi.s   Boss_SharpsteelToggleVerticalOscillationPhase
                cmpi.l  #$FFFE8000,d0
                bmi.s   Boss_SharpsteelUpdateVerticalOscillationReturn
Boss_SharpsteelAccelerateOscillationUpward:
                subi.l  #$E00,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelUpdateDownwardOscillation:
                move.l  $1C(a5),d0
                bmi.s   Boss_SharpsteelAccelerateOscillationDownward
                cmpi.w  #$172,$14(a5)
                bpl.s   Boss_SharpsteelToggleVerticalOscillationPhase
                cmpi.l  #$18000,d0
                bpl.s   Boss_SharpsteelUpdateVerticalOscillationReturn
Boss_SharpsteelAccelerateOscillationDownward:
                addi.l  #$E00,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelToggleVerticalOscillationPhase:
                                        ; Boss_SharpsteelUpdateVerticalOscillation+32   j
                eori.w  #2,$11E(a5)
Boss_SharpsteelUpdateVerticalOscillationReturn:
                                        ; Boss_SharpsteelUpdateVerticalOscillation+3A   j
                rts
; End of function Boss_SharpsteelUpdateVerticalOscillation
; Accelerates horizontal velocity toward PlayerCenterX, with speed limits
Boss_SharpsteelSteerTowardPlayerX:                      ; was: sub_48652
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_SharpsteelHandlePlayerRightOfRoot
                move.l  $18(a5),d0
                bpl.s   Boss_SharpsteelAccelerateLeftTowardPlayer
                cmpi.l  #$FFFD8000,$18(a5)
                bmi.s   Boss_SharpsteelHorizontalSteeringReturn
Boss_SharpsteelAccelerateLeftTowardPlayer:
                subi.l  #$3000,$18(a5)
Boss_SharpsteelHorizontalSteeringReturn:
                                        ; Boss_SharpsteelSteerTowardPlayerX+32   j
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelHandlePlayerRightOfRoot:
                move.l  $18(a5),d0
                bmi.s   Boss_SharpsteelAccelerateRightTowardPlayer
                cmpi.l  #$28000,$18(a5)
                bpl.s   Boss_SharpsteelHorizontalSteeringReturn
Boss_SharpsteelAccelerateRightTowardPlayer:
                addi.l  #$3000,$18(a5)
                rts
; End of function Boss_SharpsteelSteerTowardPlayerX
; Runs blade pose commands, palette updates, core frames, and part rendering
Boss_SharpsteelUpdateBladeAssembly:                     ; was: sub_48690
                                        ; Boss_SharpsteelWaitForPlayerAfterBladeEntranceState+A   j
                bsr.w   Boss_SharpsteelRunBladePoseCommands
Boss_SharpsteelUpdateBladePresentation:
                                        ; Boss_SharpsteelWaitForComplexAlignmentState+12   j
                bsr.w   Boss_SharpsteelUpdateBackgroundPaletteFade
                bsr.w   Boss_SharpsteelUpdateCoreSpriteFrames
                moveq   #$11,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_SharpsteelUpdateBladeAssembly
; Clears the sprite-priority bit on all 18 embedded blade parts
Boss_SharpsteelClearBladePartPriorityBits:              ; was: sub_486A4
                                        ; Boss_SharpsteelInitializeAttackSelection+82   p
                movea.w a5,a0
                moveq   #7,d0
                moveq   #$11,d7
Boss_SharpsteelClearBladePartPriorityBitsLoop:
                bclr    d0,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_SharpsteelClearBladePartPriorityBitsLoop
                rts
; End of function Boss_SharpsteelClearBladePartPriorityBits
; Sets the sprite-priority bit on all 18 embedded blade parts
Boss_SharpsteelSetBladePartPriorityBits:                ; was: sub_486B8
                                        ; Boss_SharpsteelOpeningVerticalTurnState+2C   p
                movea.w a5,a0
                moveq   #7,d0
                moveq   #$11,d7
Boss_SharpsteelSetBladePartPriorityBitsLoop:
                bset    d0,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_SharpsteelSetBladePartPriorityBitsLoop
                rts
; End of function Boss_SharpsteelSetBladePartPriorityBits
; Clears sprite priority on blade-part group A
Boss_SharpsteelClearBladeGroupAPriorityBits:            ; was: sub_486CC
                bclr    #7,$24E(a5)
                bclr    #7,$2AE(a5)
                bclr    #7,$30E(a5)
                bclr    #7,$36E(a5)
                rts
; End of function Boss_SharpsteelClearBladeGroupAPriorityBits
; Sets sprite priority on blade-part group A
Boss_SharpsteelSetBladeGroupAPriorityBits:              ; was: sub_486E6
                                        ; Boss_SharpsteelFarRangeBladeAttackState+10   p
                bset    #7,$24E(a5)
                bset    #7,$2AE(a5)
                bset    #7,$30E(a5)
                bset    #7,$36E(a5)
                rts
; End of function Boss_SharpsteelSetBladeGroupAPriorityBits
; Clears sprite priority on blade-part group B
Boss_SharpsteelClearBladeGroupBPriorityBits:            ; was: sub_48700
                bclr    #7,$3CE(a5)
                bclr    #7,$42E(a5)
                bclr    #7,$48E(a5)
                bclr    #7,$4EE(a5)
                rts
; End of function Boss_SharpsteelClearBladeGroupBPriorityBits
; Sets sprite priority on blade-part group B
Boss_SharpsteelSetBladeGroupBPriorityBits:              ; was: sub_4871A
                bset    #7,$3CE(a5)
                bset    #7,$42E(a5)
                bset    #7,$48E(a5)
                bset    #7,$4EE(a5)
                rts
; End of function Boss_SharpsteelSetBladeGroupBPriorityBits
; Enables collision and writes the collision value for the outer blade group
Boss_SharpsteelEnableOuterBladeHitboxes:
                bset    #6,$5C1(a5)                     ; was: sub_48734
                bset    #6,$681(a5)
                move.w  d1,$5C6(a5)
                move.w  d1,$686(a5)
                movea.w #(EleventhEntityType-M68K_RAM),a0
                bra.s   Boss_SharpsteelEnableLinkedBladeHitboxes
; End of function Boss_SharpsteelEnableOuterBladeHitboxes
; Enables collision and writes the collision value for the inner blade group
Boss_SharpsteelEnableInnerBladeHitboxes:                ; was: sub_4874E
                                        ; Boss_SharpsteelCloseRangeBladeAttackState+18   p
                bset    #6,$561(a5)
                bset    #6,$621(a5)
                move.w  d1,$566(a5)
                move.w  d1,$626(a5)
                movea.w #(SeventhEntityType-M68K_RAM),a0
Boss_SharpsteelEnableLinkedBladeHitboxes:
                moveq   #6,d0
                bset    d0,$21(a0)
                bset    d0,$81(a0)
                bset    d0,$E1(a0)
                bset    d0,$141(a0)
                move.w  d1,$26(a0)
                move.w  d1,$86(a0)
                move.w  d1,$E6(a0)
                move.w  d1,$146(a0)
                rts
; End of function Boss_SharpsteelEnableInnerBladeHitboxes
; Disables collision for the outer blade group
Boss_SharpsteelDisableOuterBladeHitboxes:
                bclr    #6,$5C1(a5)                     ; was: sub_4878A
                bclr    #6,$681(a5)
                movea.w #(EleventhEntityType-M68K_RAM),a0
                bra.s   Boss_SharpsteelDisableLinkedBladeHitboxes
; End of function Boss_SharpsteelDisableOuterBladeHitboxes
; Disables collision for the inner blade group
Boss_SharpsteelDisableInnerBladeHitboxes:               ; was: sub_4879C
                                        ; Boss_SharpsteelCloseRangeBladeAttackState+2E   p
                bclr    #6,$561(a5)
                bclr    #6,$621(a5)
                movea.w #(SeventhEntityType-M68K_RAM),a0
Boss_SharpsteelDisableLinkedBladeHitboxes:
                moveq   #6,d0
                bclr    d0,$21(a0)
                bclr    d0,$81(a0)
                bclr    d0,$E1(a0)
                bclr    d0,$141(a0)
                rts
; End of function Boss_SharpsteelDisableInnerBladeHitboxes
; Writes one collision value to four blade parts
Boss_SharpsteelSetBladeCollisionValuesA:
                move.w  d0,$686(a5)                     ; was: sub_487C0
                move.w  d0,$566(a5)
                move.w  d0,$386(a5)
                move.w  d0,$326(a5)
                rts
; End of function Boss_SharpsteelSetBladeCollisionValuesA
; Writes one collision value to the complementary four blade parts
Boss_SharpsteelSetBladeCollisionValuesB:
                move.w  d0,$626(a5)                     ; was: sub_487D2
                move.w  d0,$5C6(a5)
                move.w  d0,$506(a5)
                move.w  d0,$4A6(a5)
                rts
; End of function Boss_SharpsteelSetBladeCollisionValuesB
; Enables the two collision flags on all six core segments
Boss_SharpsteelEnableCoreSegmentCollision:              ; was: sub_487E4
                move.w  #$50,d0                         ; 'P'
                or.b    d0,$21(a5)
                or.b    d0,$81(a5)
                or.b    d0,$E1(a5)
                or.b    d0,$141(a5)
                or.b    d0,$1A1(a5)
                or.b    d0,$201(a5)
                rts
; End of function Boss_SharpsteelEnableCoreSegmentCollision
; Disables the two collision flags on all six core segments
Boss_SharpsteelDisableCoreSegmentCollision:             ; was: sub_48802
                                        ; Boss_SharpsteelInitializeDiveAttack+42   p
                move.w  #$FFAF,d0
                and.b   d0,$21(a5)
                and.b   d0,$81(a5)
                and.b   d0,$E1(a5)
                and.b   d0,$141(a5)
                and.b   d0,$1A1(a5)
                and.b   d0,$201(a5)
                rts
; End of function Boss_SharpsteelDisableCoreSegmentCollision
; Updates the directional sprite frames of the two visible core objects
Boss_SharpsteelUpdateCoreSpriteFrames:                  ; was: sub_48820
                lea     Boss_SharpsteelCoreDirectionalSpriteFrames(pc),a1
                nop
                movea.w #(TenthEntityType-M68K_RAM),a0
                andi.w  #$E7FF,$E(a0)
                jsr     (Sprite_UpdateFourDirectionFrame).l
                movea.w #(FourteenthEntityType-M68K_RAM),a0
                andi.w  #$E7FF,$E(a0)
                jmp     Sprite_UpdateFourDirectionFrame
; End of function Boss_SharpsteelUpdateCoreSpriteFrames
; ---------------------------------------------------------------------------
Boss_SharpsteelCoreDirectionalSpriteFrames: dc.l    Boss_SharpsteelCoreDirectionalMapping0
                dc.l    Boss_SharpsteelCoreDirectionalMapping1
                dc.l    Boss_SharpsteelCoreDirectionalMapping2
                dc.l    Boss_SharpsteelCoreDirectionalMapping3

; Configures blade-part mappings and tile attributes for graphics set A
Boss_SharpsteelConfigureBladeGraphicsSetA:              ; was: sub_48856
                                        ; Boss_SharpsteelManualControlState+8   p
                move.w  #$EB9C,$24E(a5)
                move.w  #$B00,$248(a5)
                move.w  #$F4F0,$24A(a5)
                move.w  #$FB9C,$3CE(a5)
                move.w  #$B00,$3C8(a5)
                move.w  #$F4F0,$3CA(a5)
                moveq   #0,d1
                move.w  #$F7FF,d2
                cmpi.w  #$100,$56(a5)
                bpl.s   Boss_SharpsteelSelectBladeGraphicsTableA
                move.w  #$800,d1
                eori.w  #$1800,$24E(a5)
                eori.w  #$1800,$3CE(a5)
Boss_SharpsteelSelectBladeGraphicsTableA:
                lea     Boss_SharpsteelBladeGraphicsMappingsA(pc),a0
                nop
                bra.s   Boss_SharpsteelApplyBladeGraphicsSet
; End of function Boss_SharpsteelConfigureBladeGraphicsSetA
; Configures blade-part mappings and tile attributes for graphics set B
Boss_SharpsteelConfigureBladeGraphicsSetB:              ; was: sub_488A0
                                        ; Boss_SharpsteelInitializeShrimpCycle+4A   p
                move.w  #$EB90,$24E(a5)
                move.w  #$E00,$248(a5)
                move.w  #$F0F4,$24A(a5)
                move.w  #$E390,$3CE(a5)
                move.w  #$E00,$3C8(a5)
                move.w  #$F0F4,$3CA(a5)
                moveq   #0,d1
                move.w  #$EFFF,d2
                cmpi.w  #$80,$56(a5)
                bmi.s   Boss_SharpsteelSelectBladeGraphicsTableB
                cmpi.w  #$180,$56(a5)
                bpl.s   Boss_SharpsteelSelectBladeGraphicsTableB
                move.w  #$1000,d1
                eori.w  #$1800,$24E(a5)
                eori.w  #$1800,$3CE(a5)
Boss_SharpsteelSelectBladeGraphicsTableB:
                                        ; Boss_SharpsteelConfigureBladeGraphicsSetB+38   j
                lea     Boss_SharpsteelBladeGraphicsMappingsB(pc),a0
                nop
Boss_SharpsteelApplyBladeGraphicsSet:
                movea.w a5,a1
                moveq   #5,d7
Boss_SharpsteelApplyBladeGraphicsSetLoop:
                and.w   d2,$E(a1)
                or.w    d1,$E(a1)
                move.l  (a0)+,8(a1)
                lea     $60(a1),a1
                dbf     d7,Boss_SharpsteelApplyBladeGraphicsSetLoop
                rts
; End of function Boss_SharpsteelConfigureBladeGraphicsSetB
; ---------------------------------------------------------------------------
Boss_SharpsteelBladeGraphicsMappingsB:  dc.l    Boss_SharpsteelBladeGraphicsBMapping0
                dc.l    Boss_SharpsteelBladeGraphicsBMapping1
                dc.l    Boss_SharpsteelBladeGraphicsBMapping2
                dc.l    Boss_SharpsteelBladeGraphicsBMapping3
                dc.l    Boss_SharpsteelBladeGraphicsBMapping4
                dc.l    Boss_SharpsteelBladeGraphicsBMapping5
Boss_SharpsteelBladeGraphicsMappingsA:  dc.l    Boss_SharpsteelBladeGraphicsAMapping0
                dc.l    Boss_SharpsteelBladeGraphicsAMapping1
                dc.l    Boss_SharpsteelBladeGraphicsAMapping2
                dc.l    Boss_SharpsteelBladeGraphicsAMapping3
                dc.l    Boss_SharpsteelBladeGraphicsAMapping4
                dc.l    Boss_SharpsteelBladeGraphicsAMapping5

; Sets collision-box group sizes for the outer blade group
Boss_SharpsteelSetOuterBladeGroupSizes:                 ; was: sub_4893A
                                        ; Boss_SharpsteelInitializeDiveAttack+52   p
                moveq   #$18,d0
                bsr.s   Boss_SharpsteelSelectOuterBladeGroup
                moveq   #$18,d0
; End of function Boss_SharpsteelSetOuterBladeGroupSizes
; Sets collision-box group sizes for the inner blade group
Boss_SharpsteelSetInnerBladeGroupSizes:                 ; was: sub_48940
                                        ; Boss_SharpsteelInitializeBladeEntrance+50   p
                movea.w #(SeventhEntityType-M68K_RAM),a0
                bra.s   Boss_SharpsteelStoreBladeGroupSizes
; ---------------------------------------------------------------------------
Boss_SharpsteelSelectOuterBladeGroup:
                                        ; Boss_SharpsteelSetOuterBladeGroupSizes+2   p
                movea.w #(EleventhEntityType-M68K_RAM),a0
Boss_SharpsteelStoreBladeGroupSizes:
                move.b  d0,$20(a0)
                move.b  d0,$80(a0)
                move.b  d0,$E0(a0)
                subq.w  #8,d0
                move.b  d0,$140(a0)
                rts
; End of function Boss_SharpsteelSetInnerBladeGroupSizes
; Loads 3 palette colors based on frame counter
Boss_SharpsteelUpdateFlashingPaletteColors:
                moveq   #6,d0                           ; was: sub_4895E
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_SharpsteelSelectFlashingPaletteTriplet
                moveq   #0,d0
Boss_SharpsteelSelectFlashingPaletteTriplet:
                movea.w #(PaletteActiveColor51-M68K_RAM),a0
                move.w  Boss_SharpsteelFlashingPaletteTriplets(pc,d0.w),(a0)+
                move.w  Boss_SharpsteelFlashingPaletteTriplets+2(pc,d0.w),(a0)+
                move.w  Boss_SharpsteelFlashingPaletteTriplets+4(pc,d0.w),(a0)+
                rts
; End of function Boss_SharpsteelUpdateFlashingPaletteColors
; ---------------------------------------------------------------------------
Boss_SharpsteelFlashingPaletteTriplets: dc.w    $8C8, $664, $220, $EEE, $AAA, $888
                                        ; Boss_SharpsteelUpdateFlashingPaletteColors+14   r

; Controls background palette fade with limits
Boss_SharpsteelUpdateBackgroundPaletteFade:             ; was: sub_48988
                move.w  $3BE(a5),d0
                bne.s   Boss_SharpsteelSelectBackgroundFadeStep
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelSelectBackgroundFadeStep:
                move.w  $3BC(a5),d7
                bne.s   Boss_SharpsteelApplyBackgroundFadeMode
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_SharpsteelApplyBackgroundFadeMode
                moveq   #1,d7
Boss_SharpsteelApplyBackgroundFadeMode:
                                        ; Boss_SharpsteelUpdateBackgroundPaletteFade+14   j
                cmpi.w  #2,d0
                beq.s   Boss_SharpsteelDecreaseBackgroundFade
                move.w  $35E(a5),d0
                add.w   d7,d0
                move.w  d0,$35E(a5)
                bmi.s   Boss_SharpsteelClampIncreasingBackgroundFade
                moveq   #0,d0
                bra.s   Boss_SharpsteelFinishBackgroundFade
; ---------------------------------------------------------------------------
Boss_SharpsteelClampIncreasingBackgroundFade:
                cmpi.w  #$FFF8,d0
                bpl.s   Boss_SharpsteelApplyBackgroundPalette
                move.w  #$FFF8,d0
                bra.s   Boss_SharpsteelApplyBackgroundPalette
; ---------------------------------------------------------------------------
Boss_SharpsteelDecreaseBackgroundFade:
                move.w  $35E(a5),d0
                sub.w   d7,d0
                move.w  d0,$35E(a5)
                bmi.s   Boss_SharpsteelClampDecreasingBackgroundFade
                moveq   #0,d0
                bra.s   Boss_SharpsteelApplyBackgroundPalette
; ---------------------------------------------------------------------------
Boss_SharpsteelClampDecreasingBackgroundFade:
                cmpi.w  #$FFF8,d0
                bpl.s   Boss_SharpsteelApplyBackgroundPalette
                move.w  #$FFF8,d0
Boss_SharpsteelFinishBackgroundFade:
                clr.w   $3BE(a5)
Boss_SharpsteelApplyBackgroundPalette:
                                        ; Boss_SharpsteelUpdateBackgroundPaletteFade+38   j
                movea.w #(PaletteActiveColor50-M68K_RAM),a0
                moveq   #$D,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_SharpsteelUpdateBackgroundPaletteFade
; Parses pose commands, interpolates pose bytes, and derives blade-part angles
Boss_SharpsteelRunBladePoseCommands:                    ; was: sub_489F0
                                        ; sub_48690   p
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_SharpsteelApplyBladePoseInterpolationStep
Boss_SharpsteelParseBladePoseCommandLoop:
                                        ; Boss_SharpsteelRunBladePoseCommands+44   j
                move.w  $58(a5),d0
                bmi.w   Boss_SharpsteelUpdateBladeAnglesFromPose
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_SharpsteelReadBladePoseCommand
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_SharpsteelParseBladePoseCommandLoop
; ---------------------------------------------------------------------------
Boss_SharpsteelReadBladePoseCommand:
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_SharpsteelHandleBladePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelHandleBladePoseLoopCommand:
                cmpi.w  #$FFFF,d3
                bne.s   Boss_SharpsteelBeginBladePoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_SharpsteelParseBladePoseCommandLoop
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginBladePoseInterpolation:
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_SharpsteelBladePoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_SharpsteelInitializeBladePoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_SharpsteelUpdateBladeAnglesFromPose
Boss_SharpsteelApplyBladePoseInterpolationStep:
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #7,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_SharpsteelUpdateBladeAnglesFromPose:
                                        ; Boss_SharpsteelRunBladePoseCommands+E   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  #$180,d1
                move.w  #$80,d2
                sub.w   d0,d1
                and.w   d7,d1
                move.w  d1,$B6(a5)
                and.w   d7,d1
                move.w  d1,$116(a5)
                add.w   d0,d2
                and.w   d7,d2
                move.w  d2,$176(a5)
                add.w   d0,d2
                and.w   d7,d2
                move.w  d2,$1D6(a5)
                and.w   d7,d2
                move.w  d2,$236(a5)
                move.w  $B6(a5),d1
                move.b  4(a0),d2
                asl.w   #1,d2
                subi.w  #$80,d2
                add.w   d1,d2
                and.w   d7,d2
                move.w  d2,$296(a5)
                move.b  8(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$2F6(a5)
                move.b  $C(a0),d2
                asl.w   #1,d2
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$356(a5)
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$3B6(a5)
                move.w  d3,$596(a5)
                move.w  d3,$656(a5)
                move.b  $10(a0),d2
                asl.w   #1,d2
                addi.w  #$80,d2
                add.w   d1,d2
                and.w   d7,d2
                move.w  d2,$416(a5)
                move.b  $14(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$476(a5)
                move.b  $18(a0),d2
                asl.w   #1,d2
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$4D6(a5)
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$536(a5)
                move.w  d3,$5F6(a5)
                move.w  d3,$6B6(a5)
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d4
                move.b  $1C(a0),d0
                beq.s   Boss_SharpsteelApplyBladePoseOffsets
                ext.w   d0
                ext.l   d0
                move.w  d0,d1
                asr.w   #1,d1
                move.l  d0,d2
                divs.w  #3,d2
                asr.w   #2,d4
Boss_SharpsteelApplyBladePoseOffsets:
                move.w  $B2(a5),d3
                sub.w   d4,d3
                move.w  d3,$B4(a5)
                move.w  $112(a5),d3
                sub.w   d2,d3
                move.w  d3,$114(a5)
                move.w  $172(a5),d3
                sub.w   d2,d3
                move.w  d3,$174(a5)
                move.w  $1D2(a5),d3
                sub.w   d1,d3
                move.w  d3,$1D4(a5)
                move.w  $232(a5),d3
                sub.w   d0,d3
                move.w  d3,$234(a5)
                rts
; End of function Boss_SharpsteelRunBladePoseCommands
; Calculates interpolation deltas from the current pose to a target pose
Boss_SharpsteelInitializeBladePoseInterpolation:        ; was: sub_48B84
                movea.l #Boss_SharpsteelNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #7,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_SharpsteelInitializeBladePoseInterpolation
; Initializes eight Sharpsteel blade pose channels from bytes at a0
Boss_SharpsteelInitializeBladePoseChannels:             ; was: sub_48B9A
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                moveq   #7,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_SharpsteelInitializeBladePoseChannels
; ---------------------------------------------------------------------------
Boss_SharpsteelManualControlPoseCommands:   dc.b    $20, $20, 0, $10, $20, $20, 0, $18, $FF, $FF
Boss_SharpsteelHighSpeedPoseCommands:       dc.b    $C, $C, 0, $38, 7, $C, 0, $40, 7, 7, 0, $40, $C, $C, 0, $48
                dc.b    7, $C, 0, $50, $80, 1, 7, 7, 0, $50, $FF, $FF
Boss_SharpsteelRightwardPoseCommands:   dc.b    $A, $A, 0, $38, 5, $A, 0, $40, 5, 5, 0, $40, $A, $A, 0, $48
                dc.b    5, $A, 0, $50, $80, 1, 5, 5, 0, $50, $FF, $FF
Boss_SharpsteelAssemblyTriggerPoses:    dc.b    $10, $18, 0, $58, 8, 8, 0, $58, $10, $14, 0, $60, $2C, $2C, 0, $60
                dc.b    $C, $14, 0, $68, $14, $14, 0, $68, $10, $12, 0, $70, $12, $12, 0, $70
                dc.b    $FF, $FE
Boss_SharpsteelAssemblyDelayPoses:  dc.b    5, $A, 0, 0, 8, 8, 0, 0, 5, $A, 0, 8, 8, 8, 0, 8
                                        ; Boss_SharpsteelAccelerateBladeAssemblyState+3E   o
                dc.b    $80, 1, $FF, $FF
Boss_SharpsteelOpeningTurnPoses:        dc.b    $A, $A, 0, $10, $10, $18, 0, $18, $C, $C, 0, $18, $FF, $FE
Boss_SharpsteelAssemblyThresholdPoses:  dc.b    $32, $32, 0, $20, 8, $A, 0, $28, 8, 8, 0, $28, $FF, $FE
Boss_SharpsteelAssemblySweepPoses:      dc.b    5, 9, 0, $30, $12, $12, 0, $30, 6, $20, 0, $28, $11, $11, 0, $28
                dc.b    $FF, $FE
Boss_SharpsteelFarRangeAttackPoses: dc.b    $13, $1C, 0, $80, $C, $C, 0, $80, $C, $40, 0, $88, $80, 1, 9, $D
                dc.b    0, $88, $A, $A, 0, $88, $80, 2, $18, $1C, 0, $78, 6, 6, 0, $78
                dc.b    $FF, $FE
Boss_SharpsteelCloseRangeAttackPoses:   dc.b    $13, $1C, 0, $90, $C, $C, 0, $90, $C, $40, 0, $98, $80, 1, 9, $D
                dc.b    0, $98, $A, $A, 0, $98, $80, 2, $16, $1A, 0, $78, 6, 6, 0, $78
                dc.b    $FF, $FE
Boss_SharpsteelDivePoses:               dc.b    6, $20, 0, 0, $A, $A, 0, 0, $10, $10, 0, $18, $FF, $FE
Boss_SharpsteelComplexOscillationPoses: dc.b    8, $10, 0, $A8, $20, $20, 0, $A8, $A, $30, 0, $B0, 4, 8, 0, $B0
                                        ; Boss_SharpsteelWaitForComplexAlignmentState+A8   o
                dc.b    $80, 1, 2, 4, 0, $B0, $18, $18, 0, $B0, $FF, $FE
Boss_SharpsteelComplexExitPoses:    dc.b    8, $10, 0, $B8, $20, $20, 0, $B8, $80, 2, $A, $30, 0, $C0, 4, 8
                                        ; Boss_SharpsteelWaitForComplexAlignmentState+116   o
                dc.b    0, $C0, $80, 1, 2, 4, 0, $B8, $18, $18, 0, $B8, $FF, $FE
Boss_SharpsteelBladePoseTable:  dc.b    0, $18, $C0, $30, $E8, $40, $D0, 3, 0, 8, $D8, $2C, $F8, $28, $D4, $18
                dc.b    0, $10, $C0, $C8, $F0, $40, $38, $60, 0, 8, 4, 8, $F8, $FC, $F8, 0
                dc.b    0, $20, $E0, 0, $E0, $20, 0, $23, 0, $18, $B4, 0, $E8, $4C, 0, $F8
                dc.b    0, $20, 0, $D0, $E0, 0, $30, $48, $FC, 0, $7F, 8, $F0, $40, $C0, 3
                dc.b    $18, 8, $10, $D8, $D8, $E8, $F8, 3, 0, $10, $C0, $28, $F8, 0, $18, 3
                dc.b    $EC, $38, $30, 2, $20, $40, $C0, 3, $EC, $10, $D0, $CC, $F0, $30, $34, $30
                dc.b    0, $10, $E0, $C8, $F0, $20, $38, 8, $20, $10, $E0, $C8, $F0, $20, $38, 8
                dc.b    $F6, $20, $E0, $F8, $10, $60, $FC, $14, 0, $18, 0, $E0, $E8, 0, $20, $38
                dc.b    $F6, $30, $10, $28, $F0, $24, $20, $F8, $18, $10, $E0, $EA, $E0, $10, $14, $24
                dc.b    $18, $10, $A0, $E0, $E0, $34, $38, $20, $F0, $20, $F0, 8, $E8, 8, $17, $FC
Boss_SharpsteelComplexPhaseInitialPose: dc.b    0, $20, $10, $20, $E0, $20, 0, 3, $F0, $1C, $24, $1C, $20, $38, $B0, $50
                dc.b    $12, $30, 0, $28, $E8, $30, $E0, $30, 0, $18, $C0, $30, $E8, $40, $D0, 3
                dc.b    0, $18, $C0, $30, $E8, $40, $D0, 3
