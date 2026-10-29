; Convert the controller, body records, and linked visuals into staggered defeat objects
Boss_ShieldViperBeginStaggeredDefeat:                   ; DATA XREF: ROM:0004E056   o  ; was: sub_4EC5E
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperConfigureStaggeredDefeatRecords
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                move.w  #$37C,(a0)
                clr.w   4(a0)
                move.l  #Boss_ShieldViperControllerAngularMappingRecords,$4C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  8(a5),8(a0)
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.w  $56(a5),$56(a0)
Boss_ShieldViperConfigureStaggeredDefeatRecords:        ; CODE XREF: Boss_ShieldViperBeginStaggeredDefeat+6   j  ; was: loc_4EC9E
                clr.b   $21(a5)
                bclr    #7,2(a5)
                move.w  #2,d6
                move.w  #$17,d7
                lea     $60(a5),a1
Boss_ShieldViperConfigureNextDefeatRecord:              ; CODE XREF: Boss_ShieldViperBeginStaggeredDefeat+96   j  ; was: loc_4ECB4
                movea.w a1,a0
                tst.w   $5C(a1)
                beq.s   Boss_ShieldViperConvertRecordToDefeatObject
                movea.w $5C(a1),a0
                move.w  #$1000,2(a1)
Boss_ShieldViperConvertRecordToDefeatObject:            ; CODE XREF: Boss_ShieldViperBeginStaggeredDefeat+5C   j  ; was: loc_4ECC6
                btst    #7,2(a0)
                beq.s   Boss_ShieldViperAdvanceDefeatRecordLoop
                move.w  #$37C,(a0)
                clr.w   4(a0)
                move.w  d6,$48(a0)
                addq.w  #2,d6
                tst.b   $5E(a1)
                bne.s   Boss_ShieldViperClearAlternateDefeatMapping
                move.l  #Boss_ShieldViperBodyAngularMappingRecords,$4C(a0)
                bra.s   Boss_ShieldViperAdvanceDefeatRecordLoop
; ---------------------------------------------------------------------------
Boss_ShieldViperClearAlternateDefeatMapping:            ; CODE XREF: Boss_ShieldViperBeginStaggeredDefeat+82   j  ; was: loc_4ECEC
                clr.l   $4C(a0)
Boss_ShieldViperAdvanceDefeatRecordLoop:                ; CODE XREF: Boss_ShieldViperBeginStaggeredDefeat+6E   j  ; was: loc_4ECF0
                                        ; Boss_ShieldViperBeginStaggeredDefeat+8C   j
                lea     $60(a1),a1
                dbf     d7,Boss_ShieldViperConfigureNextDefeatRecord
                move.w  d6,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginStaggeredDefeat
; Wait for the staggered body-defeat timers, then seed the palette-cycle interval
Boss_ShieldViperWaitForStaggeredDefeat:                 ; DATA XREF: ROM:0004E058   o  ; was: sub_4ED02
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperStaggeredDefeatWaitReturn
                addi.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperStaggeredDefeatWaitReturn:              ; CODE XREF: Boss_ShieldViperWaitForStaggeredDefeat+4   j  ; was: locret_4ED12
                rts
; End of function Boss_ShieldViperWaitForStaggeredDefeat
; Run the palette cycle for $80 frames before entering the final fade
Boss_ShieldViperRunPostDefeatPaletteCycle:              ; DATA XREF: ROM:0004E05A   o  ; was: sub_4ED14
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPostDefeatPaletteCycleReturn
                clr.w   $48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperPostDefeatPaletteCycleReturn:           ; CODE XREF: Boss_ShieldViperRunPostDefeatPaletteCycle+A   j  ; was: locret_4ED28
                rts
; End of function Boss_ShieldViperRunPostDefeatPaletteCycle
; Step the final palette fade on eligible frames, then signal its completion
Boss_ShieldViperRunFinalDefeatPaletteFade:              ; DATA XREF: ROM:0004E05C   o  ; was: sub_4ED2A
                move.w  $48(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_ShieldViperFinalDefeatPaletteFadeReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_ShieldViperFinalDefeatPaletteFadeReturn
                addq.w  #1,$48(a5)
                cmpi.w  #$E,$48(a5)
                bne.s   Boss_ShieldViperFinalDefeatPaletteFadeReturn
                move.w  #$1000,$9C2(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperFinalDefeatPaletteFadeReturn:           ; CODE XREF: Boss_ShieldViperRunFinalDefeatPaletteFade+20   j  ; was: locret_4ED70
                                        ; Boss_ShieldViperRunFinalDefeatPaletteFade+28   j
                rts
; End of function Boss_ShieldViperRunFinalDefeatPaletteFade
; Hold the final palette step for four frames, then remove the controller
Boss_ShieldViperHoldFinalDefeatPaletteAndRemove:        ; DATA XREF: ROM:0004E05E   o  ; was: sub_4ED72
                move.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperFinalRemovalWaitReturn
                move.w  #$1000,2(a5)
Boss_ShieldViperFinalRemovalWaitReturn:                 ; CODE XREF: Boss_ShieldViperHoldFinalDefeatPaletteAndRemove+1A   j  ; was: locret_4ED94
                rts
; End of function Boss_ShieldViperHoldFinalDefeatPaletteAndRemove
; Update a type-$370 body record's angular offset and dispatch its local state
Boss_ShieldViperBodyRecordMain:                         ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4ED96
                movea.w a5,a0
                bsr.w   Boss_ShieldViperApproachAngularOffsetByTwoSteps
                move.w  4(a5),d0
                lea     Boss_ShieldViperBodyRecordStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_ShieldViperBodyRecordMain
; ---------------------------------------------------------------------------
Boss_ShieldViperBodyRecordStateOffsets: dc.w    Boss_ShieldViperBodyRecordIdle-*  ; DATA XREF: Boss_ShieldViperBodyRecordMain+A   o  ; was: off_4EDA8
                dc.w    Boss_ShieldViperBeginLinkedPartEjection-*
                dc.w    Boss_ShieldViperWaitThenLaunchLinkedPart-*
                dc.w    Boss_ShieldViperUpdateEjectedLinkedPart-*
                dc.w    Boss_ShieldViperDetachedBodyRecordIdle-*
                dc.w    Boss_ShieldViperBeginLinkedPartReturn-*
                dc.w    Boss_ShieldViperContractLinkedPartReturnRadius-*
                dc.w    Boss_ShieldViperFinishLinkedPartReturn-*

Boss_ShieldViperBodyRecordIdle:                         ; DATA XREF: ROM:Boss_ShieldViperBodyRecordStateOffsets   o  ; was: nullsub_115
                rts
; End of function Boss_ShieldViperBodyRecordIdle

; Copy one body record's visuals to its linked type-$10 record and hide the body record
Boss_ShieldViperBeginLinkedPartEjection:                ; DATA XREF: ROM:0004EDAA   o  ; was: sub_4EDBA
                movea.w $5C(a5),a0
                move.w  2(a5),2(a0)
                move.l  8(a5),8(a0)
                move.w  $E(a5),$E(a0)
                move.b  $20(a5),$20(a0)
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                andi.w  #$1FF,d0
                move.w  d0,$56(a0)
                clr.w   $50(a0)
                andi.w  #$7FFF,2(a5)
                move.b  $21(a5),$5A(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
; Keep the linked record on its body until the stagger timer expires, then launch it
Boss_ShieldViperWaitThenLaunchLinkedPart:               ; DATA XREF: ROM:0004EDAC   o  ; was: loc_4EDFE
                movea.w $5C(a5),a0
                lea     Boss_ShieldViperBodyAngularMappingRecords(pc),a1
                nop
                bsr.w   Boss_ShieldViperPositionLinkedPartFromBodyRecord
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedPartLaunchWaitReturn
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                btst    #7,(SharedScratchLong0).w
                beq.s   Boss_ShieldViperAddPositiveQuarterTurnToLaunchAngle
                addi.w  #-$80,d0
                bra.s   Boss_ShieldViperStoreLinkedPartLaunchVelocity
; ---------------------------------------------------------------------------
Boss_ShieldViperAddPositiveQuarterTurnToLaunchAngle:    ; CODE XREF: Boss_ShieldViperBeginLinkedPartEjection+66   j  ; was: loc_4EE28
                addi.w  #$80,d0
Boss_ShieldViperStoreLinkedPartLaunchVelocity:          ; CODE XREF: Boss_ShieldViperBeginLinkedPartEjection+6C   j  ; was: loc_4EE2C
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                muls.w  #$10,d0
                muls.w  #$10,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedPartLaunchWaitReturn:             ; CODE XREF: Boss_ShieldViperBeginLinkedPartEjection+56   j  ; was: locret_4EE52
                rts
; End of function Boss_ShieldViperBeginLinkedPartEjection
; Rotate the ejected linked record's mapping and retire it outside the arena bounds
Boss_ShieldViperUpdateEjectedLinkedPart:                ; DATA XREF: ROM:0004EDAE   o  ; was: sub_4EE54
                movea.w $5C(a5),a0
                tst.b   $5E(a5)
                bne.s   Boss_ShieldViperCheckEjectedLinkedPartBounds
                bsr.w   Gfx_ShieldViperUpdateRecordAngularMapping
Boss_ShieldViperCheckEjectedLinkedPartBounds:           ; CODE XREF: Boss_ShieldViperUpdateEjectedLinkedPart+8   j  ; was: loc_4EE62
                cmpi.w  #$60,$10(a0)                    ; '`'
                bcs.s   Boss_ShieldViperRemoveEjectedLinkedPart
                cmpi.w  #$1E0,$10(a0)
                bhi.s   Boss_ShieldViperRemoveEjectedLinkedPart
                cmpi.w  #$60,$14(a0)                    ; '`'
                bcs.s   Boss_ShieldViperRemoveEjectedLinkedPart
                cmpi.w  #$1A0,$14(a0)
                bhi.s   Boss_ShieldViperRemoveEjectedLinkedPart
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperRemoveEjectedLinkedPart:                ; CODE XREF: Boss_ShieldViperUpdateEjectedLinkedPart+14   j  ; was: loc_4EE84
                                        ; Boss_ShieldViperUpdateEjectedLinkedPart+1C   j
                andi.w  #$7FFF,2(a0)
                move.w  #$1000,2(a0)
                clr.w   $5C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperUpdateEjectedLinkedPart
Boss_ShieldViperDetachedBodyRecordIdle:                 ; DATA XREF: ROM:0004EDB0   o  ; was: nullsub_116
                rts
; End of function Boss_ShieldViperDetachedBodyRecordIdle

; Recreate a linked visual at radius $300 to begin its return to the body record
Boss_ShieldViperBeginLinkedPartReturn:                  ; DATA XREF: ROM:0004EDB2   o  ; was: sub_4EE9C
                movea.w $5C(a5),a0
                move.w  2(a5),2(a0)
                bset    #7,2(a0)
                move.l  8(a5),8(a0)
                move.w  $E(a5),$E(a0)
                move.b  $20(a5),$20(a0)
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                addi.w  #$80,d0
                andi.w  #$1FF,d0
                move.w  d0,$56(a0)
                move.w  #$300,$50(a0)
                addq.w  #2,4(a5)
; Contract the linked record's radius by $10 per frame until it reaches its body
Boss_ShieldViperContractLinkedPartReturnRadius:         ; DATA XREF: ROM:0004EDB4   o  ; was: loc_4EEDC
                movea.w $5C(a5),a0
                lea     Boss_ShieldViperBodyAngularMappingRecords(pc),a1
                nop
                bsr.w   Boss_ShieldViperPositionLinkedPartFromBodyRecord
                subi.w  #$10,$50(a0)
                bne.s   Boss_ShieldViperLinkedPartContractionReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedPartContractionReturn:            ; CODE XREF: Boss_ShieldViperBeginLinkedPartReturn+54   j  ; was: locret_4EEFC
                rts
; End of function Boss_ShieldViperBeginLinkedPartReturn
; Hold the linked record at its body, then restore the body's display and collision state
Boss_ShieldViperFinishLinkedPartReturn:                 ; DATA XREF: ROM:0004EDB6   o  ; was: sub_4EEFE
                movea.w $5C(a5),a0
                lea     Boss_ShieldViperBodyAngularMappingRecords(pc),a1
                nop
                bsr.w   Boss_ShieldViperPositionLinkedPartFromBodyRecord
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedPartReturnWaitReturn
                move.b  $5A(a5),$21(a5)
                ori.w   #$8000,2(a5)
                move.w  #$1000,2(a0)
                clr.w   $5C(a5)
                clr.w   4(a5)
Boss_ShieldViperLinkedPartReturnWaitReturn:             ; CODE XREF: Boss_ShieldViperFinishLinkedPartReturn+12   j  ; was: locret_4EF2C
                rts
; End of function Boss_ShieldViperFinishLinkedPartReturn
; Dispatch a type-$378 pattern shot, or convert a visible shot during boss defeat
Projectile_ShieldViperPatternShotMain:                  ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4EF2E
                btst    #0,(PrimaryEntityWork58).w
                beq.s   Projectile_ShieldViperDispatchPatternShotState
                btst    #7,2(a5)
                beq.s   Projectile_ShieldViperRemoveHiddenPatternShotAfterDefeat
                move.w  #4,$48(a5)
                move.l  #Boss_ShieldViperBodyAngularMappingRecords,$4C(a5)
                move.w  #$37C,(a5)
                clr.w   4(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperRemoveHiddenPatternShotAfterDefeat:  ; CODE XREF: Projectile_ShieldViperPatternShotMain+E   j  ; was: loc_4EF56
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperDispatchPatternShotState:         ; CODE XREF: Projectile_ShieldViperPatternShotMain+6   j  ; was: loc_4EF5E
                move.w  4(a5),d0
                lea     Projectile_ShieldViperPatternShotStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_ShieldViperPatternShotMain
; ---------------------------------------------------------------------------
Projectile_ShieldViperPatternShotStateOffsets:  dc.w    Projectile_ShieldViperWaitForPatternShotActivation-*  ; DATA XREF: Projectile_ShieldViperPatternShotMain+34   o  ; was: off_4EF6A
                dc.w    Projectile_ShieldViperBlinkPatternShotBeforeLaunch-*
                dc.w    Projectile_ShieldViperUpdatePatternShotFlight-*

; Wait for the spawner-provided stagger timer, then enable collision and blinking
Projectile_ShieldViperWaitForPatternShotActivation:     ; DATA XREF: ROM:Projectile_ShieldViperPatternShotStateOffsets   o  ; was: sub_4EF70
                subq.w  #1,$4A(a5)
                bne.s   Projectile_ShieldViperPatternShotActivationWaitReturn
                move.w  #$10,$48(a5)
                move.b  #$C0,$21(a5)
                move.b  #$10,$23(a5)
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F808F808,$28(a5)
                move.w  #$80,$26(a5)
                addq.w  #2,4(a5)
Projectile_ShieldViperPatternShotActivationWaitReturn:  ; CODE XREF: Projectile_ShieldViperWaitForPatternShotActivation+4   j  ; was: locret_4EFA2
                rts
; End of function Projectile_ShieldViperWaitForPatternShotActivation
; Rotate and blink the pattern shot for sixteen frames before loading its velocity
Projectile_ShieldViperBlinkPatternShotBeforeLaunch:     ; DATA XREF: ROM:0004EF6C   o  ; was: sub_4EFA4
                bsr.w   Gfx_ShieldViperUpdateCurrentPatternShotAngularMapping
                btst    #0,(FrameCounter+1).w
                beq.s   Projectile_ShieldViperShowPatternShotDuringBlink
                bclr    #7,2(a5)
                bra.s   Projectile_ShieldViperContinuePatternShotLaunchDelay
; ---------------------------------------------------------------------------
Projectile_ShieldViperShowPatternShotDuringBlink:       ; CODE XREF: Projectile_ShieldViperBlinkPatternShotBeforeLaunch+A   j  ; was: loc_4EFB8
                bset    #7,2(a5)
Projectile_ShieldViperContinuePatternShotLaunchDelay:   ; CODE XREF: Projectile_ShieldViperBlinkPatternShotBeforeLaunch+12   j  ; was: loc_4EFBE
                subq.w  #1,$48(a5)
                bne.s   Projectile_ShieldViperPatternShotLaunchDelayReturn
                bset    #7,2(a5)
                move.l  $4C(a5),$18(a5)
                move.l  $50(a5),$1C(a5)
                addq.w  #2,4(a5)
Projectile_ShieldViperPatternShotLaunchDelayReturn:     ; CODE XREF: Projectile_ShieldViperBlinkPatternShotBeforeLaunch+1E   j  ; was: locret_4EFDA
                rts
; End of function Projectile_ShieldViperBlinkPatternShotBeforeLaunch
; Rotate an active pattern shot and retire it after it crosses its directional bound
Projectile_ShieldViperUpdatePatternShotFlight:          ; DATA XREF: ROM:0004EF6E   o  ; was: sub_4EFDC
                bsr.w   Gfx_ShieldViperUpdateCurrentPatternShotAngularMapping
                btst    #7,$18(a5)
                bne.s   Projectile_ShieldViperCheckPatternShotLeftBound
                cmpi.w  #$1E0,$10(a5)
                bhi.s   Projectile_ShieldViperRemoveOutOfBoundsPatternShot
                bra.s   Projectile_ShieldViperCheckPatternShotVerticalBound
; ---------------------------------------------------------------------------
Projectile_ShieldViperCheckPatternShotLeftBound:        ; CODE XREF: Projectile_ShieldViperUpdatePatternShotFlight+A   j  ; was: loc_4EFF2
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Projectile_ShieldViperRemoveOutOfBoundsPatternShot
Projectile_ShieldViperCheckPatternShotVerticalBound:    ; CODE XREF: Projectile_ShieldViperUpdatePatternShotFlight+14   j  ; was: loc_4EFFA
                btst    #7,$1C(a5)
                bne.s   Projectile_ShieldViperCheckPatternShotTopBound
                cmpi.w  #$1A0,$14(a5)
                bhi.s   Projectile_ShieldViperRemoveOutOfBoundsPatternShot
                bra.s   Projectile_ShieldViperPatternShotFlightReturn
; ---------------------------------------------------------------------------
Projectile_ShieldViperCheckPatternShotTopBound:         ; CODE XREF: Projectile_ShieldViperUpdatePatternShotFlight+24   j  ; was: loc_4F00C
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcs.s   Projectile_ShieldViperRemoveOutOfBoundsPatternShot
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperRemoveOutOfBoundsPatternShot:     ; CODE XREF: Projectile_ShieldViperUpdatePatternShotFlight+12   j  ; was: loc_4F016
                                        ; Projectile_ShieldViperUpdatePatternShotFlight+1C   j
                move.w  #$1000,2(a5)
Projectile_ShieldViperPatternShotFlightReturn:          ; CODE XREF: Projectile_ShieldViperUpdatePatternShotFlight+2E   j  ; was: locret_4F01C
                rts
; End of function Projectile_ShieldViperUpdatePatternShotFlight
; Use the current type-$378 shot as the record for the shared angular-mapping update
Gfx_ShieldViperUpdateCurrentPatternShotAngularMapping:  ; CODE XREF: Projectile_ShieldViperBlinkPatternShotBeforeLaunch   p  ; was: sub_4F01E
                                        ; Projectile_ShieldViperUpdatePatternShotFlight   p
                movea.w a5,a0
; Fall through to update its mapping and angle
; Select a body mapping from record angle $56, then advance that angle by $10
Gfx_ShieldViperUpdateRecordAngularMapping:              ; CODE XREF: Boss_ShieldViperUpdateEjectedLinkedPart+A   p  ; was: sub_4F020
                move.w  $56(a0),d0
                lea     Boss_ShieldViperBodyAngularMappingRecords(pc),a1
                nop
                bsr.w   Gfx_ShieldViperSelectMappingFromQuantizedAngle
                addi.w  #$10,$56(a0)
                rts
; End of function Gfx_ShieldViperUpdateRecordAngularMapping
; Position a linked visual at its radial offset from the owning body record
Boss_ShieldViperPositionLinkedPartFromBodyRecord:       ; CODE XREF: Boss_ShieldViperBeginLinkedPartEjection+4E   p  ; was: sub_4F036
                                        ; Boss_ShieldViperBeginLinkedPartReturn+4A   p
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                btst    #7,(SharedScratchLong0).w
                beq.s   Boss_ShieldViperAddPositiveQuarterTurnToLinkedPartAngle
                addi.w  #-$80,d0
                bra.s   Boss_ShieldViperCalculateLinkedPartPosition
; ---------------------------------------------------------------------------
Boss_ShieldViperAddPositiveQuarterTurnToLinkedPartAngle:  ; CODE XREF: Boss_ShieldViperPositionLinkedPartFromBodyRecord+E   j  ; was: loc_4F04C
                addi.w  #$80,d0
Boss_ShieldViperCalculateLinkedPartPosition:            ; CODE XREF: Boss_ShieldViperPositionLinkedPartFromBodyRecord+14   j  ; was: loc_4F050
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                muls.w  $50(a0),d0
                muls.w  $50(a0),d1
                add.l   $10(a5),d0
                add.l   $14(a5),d1
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                tst.b   $5E(a5)
                bne.s   Boss_ShieldViperLinkedPartPositionReturn
                move.w  $54(a0),d0
                bsr.w   Gfx_ShieldViperSelectMappingFromQuantizedAngle
                addi.w  #$10,$54(a0)
Boss_ShieldViperLinkedPartPositionReturn:               ; CODE XREF: Boss_ShieldViperPositionLinkedPartFromBodyRecord+48   j  ; was: locret_4F08E
                rts
; End of function Boss_ShieldViperPositionLinkedPartFromBodyRecord
; Move one record's current angular offset toward its target by at most two steps
Boss_ShieldViperApproachAngularOffsetByTwoSteps:        ; CODE XREF: Boss_ShieldViperUpdate+76   p  ; was: sub_4F090
                                        ; Boss_ShieldViperBodyRecordMain+2   p
                move.w  #1,d7
Boss_ShieldViperApproachAngularOffsetLoop:              ; CODE XREF: Boss_ShieldViperApproachAngularOffsetByTwoSteps:Boss_ShieldViperAdvanceAngularOffsetIteration   j  ; was: loc_4F094
                move.w  $54(a0),d0
                sub.w   $52(a0),d0
                andi.w  #$1FF,d0
                beq.s   Boss_ShieldViperAngularOffsetApproachReturn
                cmpi.w  #$100,d0
                bcs.w   Boss_ShieldViperIncrementAngularOffset
                subq.w  #1,$52(a0)
                bra.s   Boss_ShieldViperAdvanceAngularOffsetIteration
; ---------------------------------------------------------------------------
Boss_ShieldViperIncrementAngularOffset:                 ; CODE XREF: Boss_ShieldViperApproachAngularOffsetByTwoSteps+16   j  ; was: loc_4F0B0
                addq.w  #1,$52(a0)
Boss_ShieldViperAdvanceAngularOffsetIteration:          ; CODE XREF: Boss_ShieldViperApproachAngularOffsetByTwoSteps+1E   j  ; was: loc_4F0B4
                dbf     d7,Boss_ShieldViperApproachAngularOffsetLoop
Boss_ShieldViperAngularOffsetApproachReturn:            ; CODE XREF: Boss_ShieldViperApproachAngularOffsetByTwoSteps+10   j  ; was: locret_4F0B8
                rts
; End of function Boss_ShieldViperApproachAngularOffsetByTwoSteps
; Initialize a type-$374 Shield Viper orbit shot and its optional sound
Projectile_InitShieldViperOrbitShot:                    ; CODE XREF: Boss_ShieldViperEmitOrbitShotBurst+1C   p  ; was: sub_4F0BA
                                        ; Boss_ShieldViperEmitOrbitShotOnFrameGate+18   p
                move.w  #$374,(a0)
                move.w  #$CC80,2(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FF01FF01,$2C(a0)
                move.l  #Projectile_ShieldViperOrbitShotFrame00,8(a0)
                move.w  #$8300,$E(a0)
                move.w  #$28,$26(a0)                    ; '('
                move.w  #$10,$48(a0)
                clr.w   $C(a0)
                btst    #1,(FrameCounter+1).w
                bne.s   Projectile_ShieldViperOrbitShotInitializationReturn
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_ShieldViperOrbitShotInitializationReturn
                move.b  #$58,d0                         ; 'X'
                jsr     (Sound_QueueSFXRequest).l
Projectile_ShieldViperOrbitShotInitializationReturn:    ; CODE XREF: Projectile_InitShieldViperOrbitShot+3C   j  ; was: locret_4F10A
                                        ; Projectile_InitShieldViperOrbitShot+44   j
                rts
; End of function Projectile_InitShieldViperOrbitShot
; Advance a type-$374 orbit shot's timed animation or release its destruction pickup
Projectile_ShieldViperOrbitShotMain:                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4F10C
                bclr    #4,$22(a5)
                bne.s   Projectile_ShieldViperDropPickupFromDestroyedOrbitShot
                tst.w   4(a5)
                beq.s   Projectile_ShieldViperLoadNextOrbitShotFrame
                subq.w  #1,$48(a5)
                bne.s   Projectile_ShieldViperOrbitShotReturn
                clr.w   4(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperLoadNextOrbitShotFrame:           ; CODE XREF: Projectile_ShieldViperOrbitShotMain+C   j  ; was: loc_4F126
                move.w  $5C(a5),d0
                lea     Projectile_ShieldViperOrbitShotAnimationRecords(pc),a1
                nop
                move.w  (a1,d0.w),$48(a5)
                bmi.s   Projectile_ShieldViperRemoveCompletedOrbitShot
                move.l  4(a1,d0.w),8(a5)
                clr.w   $C(a5)
                addq.w  #8,$5C(a5)
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperRemoveCompletedOrbitShot:         ; CODE XREF: Projectile_ShieldViperOrbitShotMain+2A   j  ; was: loc_4F14C
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ShieldViperDropPickupFromDestroyedOrbitShot:  ; CODE XREF: Projectile_ShieldViperOrbitShotMain+6   j  ; was: loc_4F154
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Projectile_ShieldViperOrbitShotReturn:                  ; CODE XREF: Projectile_ShieldViperOrbitShotMain+12   j  ; was: locret_4F15C
                rts
; End of function Projectile_ShieldViperOrbitShotMain
; Nine eight-byte records: duration, unused word, and mapping pointer
Projectile_ShieldViperOrbitShotAnimationRecords:    dc.w    2  ; field_0  ; was: stru_4F15E
                                        ; DATA XREF: Projectile_ShieldViperOrbitShotMain+1E   o
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame00  ; field_4
                dc.w    2                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame01  ; field_4
                dc.w    3                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame02  ; field_4
                dc.w    3                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame03  ; field_4
                dc.w    4                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame04  ; field_4
                dc.w    4                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame05  ; field_4
                dc.w    3                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame06  ; field_4
                dc.w    3                               ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame07  ; field_4
                dc.w    $FFFF                           ; field_0
                dc.w    0                               ; field_2
                dc.l    Projectile_ShieldViperOrbitShotFrame07  ; field_4

; Defeat main handler
