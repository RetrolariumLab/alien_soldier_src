; Projectile-pattern substates selected by the main controller's state $24
Boss_DestroyerMk2LinkedActivationPatternDispatch:       ; was: sub_4B04C
                                        ; Boss_DestroyerMk2DispatchProjectilePatternState+24   o
                move.w  (SharedScratchLong7).w,d0
                lea     Boss_DestroyerMk2LinkedActivationPatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2LinkedActivationPatternDispatch
; ---------------------------------------------------------------------------
Boss_DestroyerMk2LinkedActivationPatternHandlers:   dc.w    Boss_DestroyerMk2ActivateNearLinkedPart-*  ; was: off_4B058
                dc.w    Boss_DestroyerMk2WaitThenActivateFarLinkedPart-*
                dc.w    Boss_DestroyerMk2WaitThenActivateLinkedPair-*
                dc.w    Boss_DestroyerMk2AdvanceMainState-*

; Activate the nearer linked part on the player's side
Boss_DestroyerMk2ActivateNearLinkedPart:                ; was: sub_4B060
                addq.w  #2,(SharedScratchLong7).w
                move.w  (PlayerCenterX).w,d0
                cmp.w   $10(a5),d0
                bgt.s   Boss_DestroyerMk2SelectRightNearLinkedPart
                movea.w #(FifthEntityType-M68K_RAM),a0
                bra.s   Boss_DestroyerMk2ActivateSelectedNearLinkedPart
; ---------------------------------------------------------------------------
Boss_DestroyerMk2SelectRightNearLinkedPart:             ; was: loc_4B074
                movea.w #(SixthEntityType-M68K_RAM),a0
Boss_DestroyerMk2ActivateSelectedNearLinkedPart:        ; was: loc_4B078
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
                move.w  #$20,$48(a5)                    ; ' '
                rts
; End of function Boss_DestroyerMk2ActivateNearLinkedPart
; After a delay, activate the farther linked part on the player's side
Boss_DestroyerMk2WaitThenActivateFarLinkedPart:         ; was: sub_4B084
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2FarLinkedActivationReturn
                addq.w  #2,(SharedScratchLong7).w
                move.w  (PlayerCenterX).w,d0
                cmp.w   $10(a5),d0
                bgt.s   Boss_DestroyerMk2SelectRightFarLinkedPart
                movea.w #(SeventhEntityType-M68K_RAM),a0
                bra.s   Boss_DestroyerMk2ActivateSelectedFarLinkedPart
; ---------------------------------------------------------------------------
Boss_DestroyerMk2SelectRightFarLinkedPart:              ; was: loc_4B09E
                movea.w #(EighthEntityType-M68K_RAM),a0
Boss_DestroyerMk2ActivateSelectedFarLinkedPart:         ; was: loc_4B0A2
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
                move.w  #$40,$48(a5)                    ; '@'
Boss_DestroyerMk2FarLinkedActivationReturn:             ; was: locret_4B0AC
                rts
; End of function Boss_DestroyerMk2WaitThenActivateFarLinkedPart
; After a delay, activate the two linked parts on the player's side
Boss_DestroyerMk2WaitThenActivateLinkedPair:            ; was: sub_4B0AE
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2LinkedPairActivationReturn
                addq.w  #2,(SharedScratchLong7).w
                move.w  (PlayerCenterX).w,d0
                cmp.w   $10(a5),d0
                bgt.s   Boss_DestroyerMk2SelectRightLinkedPair
                movea.w #(FifthEntityType-M68K_RAM),a0
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
                movea.w #(SeventhEntityType-M68K_RAM),a0
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
                rts
; ---------------------------------------------------------------------------
Boss_DestroyerMk2SelectRightLinkedPair:                 ; was: loc_4B0D4
                movea.w #(SixthEntityType-M68K_RAM),a0
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
                movea.w #(EighthEntityType-M68K_RAM),a0
                bsr.w   Boss_DestroyerMk2ActivateLinkedPartIfIdle
Boss_DestroyerMk2LinkedPairActivationReturn:            ; was: locret_4B0E4
                rts
; End of function Boss_DestroyerMk2WaitThenActivateLinkedPair
; Short pattern which activates the central linked part, then exits
Boss_DestroyerMk2SingleLinkedActivationDispatch:        ; was: sub_4B0E6
                                        ; ROM:0004B032   o
                move.w  (SharedScratchLong7).w,d0
                lea     Boss_DestroyerMk2SingleLinkedActivationHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2SingleLinkedActivationDispatch
; ---------------------------------------------------------------------------
Boss_DestroyerMk2SingleLinkedActivationHandlers:    dc.w    Boss_DestroyerMk2ActivateCentralLinkedPart-*  ; was: off_4B0F2
                dc.w    Boss_DestroyerMk2AdvancePatternPhase-*
                dc.w    Boss_DestroyerMk2AdvanceMainState-*

; Activate the central linked part and advance the nested pattern phase
Boss_DestroyerMk2ActivateCentralLinkedPart:             ; was: sub_4B0F8
                bsr.w   Boss_DestroyerMk2SelectCentralLinkedPart
                addq.w  #2,(SharedScratchLong7).w
                rts
; End of function Boss_DestroyerMk2ActivateCentralLinkedPart
; Advance the nested projectile-pattern phase
Boss_DestroyerMk2AdvancePatternPhase:                   ; was: sub_4B102
                addq.w  #2,(SharedScratchLong7).w
                rts
; End of function Boss_DestroyerMk2AdvancePatternPhase
; Two-state projected-effect sweep selected by the projectile-pattern table
Boss_DestroyerMk2ProjectedSweepPatternDispatch:         ; was: sub_4B108
                                        ; Boss_DestroyerMk2DispatchProjectilePatternState+1E   o
                move.w  (SharedScratchLong7).w,d0
                lea     Boss_DestroyerMk2ProjectedSweepPatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2ProjectedSweepPatternDispatch
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ProjectedSweepPatternHandlers: dc.w    Boss_DestroyerMk2InitializeProjectedSweep-*  ; was: off_4B114
                dc.w    Boss_DestroyerMk2UpdateProjectedSweep-*

; Initialize sweep origin, direction, angle, and four-step counter
Boss_DestroyerMk2InitializeProjectedSweep:              ; was: sub_4B118
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                bmi.s   Boss_DestroyerMk2InitializeLeftwardProjectedSweep
                move.w  #$30,$58(a5)                    ; '0'
                move.w  #$1E0,$5A(a5)
                bra.s   Boss_DestroyerMk2FinishProjectedSweepSetup
; ---------------------------------------------------------------------------
Boss_DestroyerMk2InitializeLeftwardProjectedSweep:      ; was: loc_4B130
                move.w  #$FFD0,$58(a5)
                move.w  #$120,$5A(a5)
Boss_DestroyerMk2FinishProjectedSweepSetup:             ; was: loc_4B13C
                move.w  $10(a5),d0
                add.w   d0,$58(a5)
                move.w  #5,$5C(a5)
                addq.w  #2,(SharedScratchLong7).w
                rts
; End of function Boss_DestroyerMk2InitializeProjectedSweep
; Project one effect per frame, then play its completion sound and exit
Boss_DestroyerMk2UpdateProjectedSweep:                  ; was: sub_4B150
                move.w  #4,d1
                move.w  #$8004,d2
                move.w  $58(a5),d3
                move.w  $14(a5),d4
                move.w  $5A(a5),d6
                andi.w  #$1FE,d6
                jsr     (Boss_DestroyerMk2SpawnProjectedShot).l
                btst    #7,$58(a5)
                bmi.s   Boss_DestroyerMk2AdvanceSweepAngleBackward
                addi.w  #$10,$5A(a5)
                bra.s   Boss_DestroyerMk2TickProjectedSweep
; ---------------------------------------------------------------------------
Boss_DestroyerMk2AdvanceSweepAngleBackward:             ; was: loc_4B17E
                addi.w  #-$10,$5A(a5)
Boss_DestroyerMk2TickProjectedSweep:                    ; was: loc_4B184
                subq.w  #1,$5C(a5)
                bne.s   Boss_DestroyerMk2ProjectedSweepReturn
                move.b  #$E9,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Boss_DestroyerMk2AdvanceMainState
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ProjectedSweepReturn:                  ; was: locret_4B198
                rts
; End of function Boss_DestroyerMk2UpdateProjectedSweep
; Three-state pattern which emits three type-$258 projectiles
Boss_DestroyerMk2TripleProjectilePatternDispatch:       ; was: sub_4B19A
                                        ; Boss_DestroyerMk2DispatchProjectilePatternState+2C   o
                move.w  (SharedScratchLong7).w,d0
                lea     Boss_DestroyerMk2TripleProjectilePatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2TripleProjectilePatternDispatch
; ---------------------------------------------------------------------------
Boss_DestroyerMk2TripleProjectilePatternHandlers:   dc.w    Boss_DestroyerMk2InitializeTripleProjectilePattern-*  ; was: off_4B1A6
                dc.w    Boss_DestroyerMk2SpawnNextTripleProjectile-*
                dc.w    Boss_DestroyerMk2WaitBetweenTripleProjectiles-*

; Initialize the three-projectile repetition counter
Boss_DestroyerMk2InitializeTripleProjectilePattern:     ; was: sub_4B1AC
                move.w  #3,$4A(a5)
                addq.w  #2,(SharedScratchLong7).w
; Allocate and initialize the next type-$258 projectile
Boss_DestroyerMk2SpawnNextTripleProjectile:             ; was: loc_4B1B6
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_DestroyerMk2FinishTripleProjectileSpawn
                move.w  #$258,(a0)
                move.w  #$CD00,2(a0)
                move.b  #$10,$23(a0)
                move.w  #$28,$26(a0)                    ; '('
                move.b  #$C0,$21(a0)
                move.l  #$F808FE02,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  #$30,$24(a0)                    ; '0'
                move.b  d1,$20(a0)
                move.l  #Boss_DestroyerMk2OrbitingPartMapping2,8(a0)
                move.w  #$EB00,$E(a0)
                clr.w   $4C(a0)
                move.w  #2,$46(a0)
                move.w  $4A(a5),$44(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Boss_DestroyerMk2FinishTripleProjectileSpawn:           ; was: loc_4B21E
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,(SharedScratchLong7).w
                rts
; End of function Boss_DestroyerMk2InitializeTripleProjectilePattern
; Wait before repeating the three-projectile pattern
Boss_DestroyerMk2WaitBetweenTripleProjectiles:          ; was: sub_4B22A
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2TripleProjectileDelayReturn
                subq.w  #1,$4A(a5)
                beq.w   Boss_DestroyerMk2AdvanceMainState
                subq.w  #2,(SharedScratchLong7).w
Boss_DestroyerMk2TripleProjectileDelayReturn:           ; was: locret_4B23C
                rts
; End of function Boss_DestroyerMk2WaitBetweenTripleProjectiles
; Two-state ten-projectile spread pattern
Boss_DestroyerMk2ProjectileSpreadPatternDispatch:       ; was: sub_4B23E
                                        ; Boss_DestroyerMk2DispatchProjectilePatternState+30   o
                move.w  (SharedScratchLong7).w,d0
                lea     Boss_DestroyerMk2ProjectileSpreadPatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2ProjectileSpreadPatternDispatch
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ProjectileSpreadPatternHandlers:   dc.w    Boss_DestroyerMk2SpawnTenProjectileSpread-*  ; was: off_4B24A
                dc.w    Boss_DestroyerMk2AdvanceMainState-*

; Allocate ten type-$258 projectiles using the parameter table below
Boss_DestroyerMk2SpawnTenProjectileSpread:              ; was: sub_4B24E
                move.w  #(Boss_DestroyerMk2InitializeProjectileSpreadLoop-*),d7
Boss_DestroyerMk2InitializeProjectileSpreadLoop:        ; was: loc_4B252
                moveq   #0,d6
Boss_DestroyerMk2ProjectileSpreadSpawnLoop:             ; was: loc_4B254
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_DestroyerMk2AdvanceProjectileSpreadLoop
                move.w  #$258,(a0)
                move.w  #$CD00,2(a0)
                move.b  #$10,$23(a0)
                move.w  #$28,$26(a0)                    ; '('
                move.b  #$C0,$21(a0)
                move.l  #$F808FE02,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  #$30,$24(a0)                    ; '0'
                move.b  d1,$20(a0)
                move.l  #Boss_DestroyerMk2OrbitingPartMapping2,8(a0)
                move.w  #$EB00,$E(a0)
                clr.w   $4C(a0)
                move.w  #4,$46(a0)
                move.w  Boss_DestroyerMk2ProjectileSpreadParameterTable(pc,d6.w),$44(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),d0
                move.w  d0,$14(a0)
                addq.w  #2,d6
Boss_DestroyerMk2AdvanceProjectileSpreadLoop:           ; was: loc_4B2C0
                dbf     d7,Boss_DestroyerMk2ProjectileSpreadSpawnLoop
                clr.w   (SharedScratchLong7+2).w
                addq.w  #2,(SharedScratchLong7).w
                rts
; End of function Boss_DestroyerMk2SpawnTenProjectileSpread
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ProjectileSpreadParameterTable:    dc.w    0, $FFFE, 2, $FFFC, 4, 0, $FFE0, $20, $FFC0, $40  ; was: word_4B2CE

; Enter the recurring projectile-pattern state and start its delay
Boss_DestroyerMk2EnterProjectilePatternCycle:           ; was: sub_4B2E2
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2EnterProjectilePatternCycle
; Wait for the pattern delay, then return to main state $22
Boss_DestroyerMk2WaitThenRepeatProjectilePatterns:      ; was: sub_4B2F2
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2ProjectilePatternCycleReturn
                move.w  #$22,4(a5)                      ; '"'
Boss_DestroyerMk2ProjectilePatternCycleReturn:          ; was: locret_4B302
                rts
; End of function Boss_DestroyerMk2WaitThenRepeatProjectilePatterns
; Wait for five linked parts to become idle before disabling collision
Boss_DestroyerMk2WaitForLinkedPartsToDeactivate:        ; was: sub_4B304
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                tst.w   (FifthEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartWaitReturn
                tst.w   (SixthEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartWaitReturn
                tst.w   (SeventhEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartWaitReturn
                tst.w   (EighthEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartWaitReturn
                tst.w   (QuaternaryEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartWaitReturn
                bsr.w   Boss_DestroyerMk2ClearLinkedCollisionFields
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2LinkedPartWaitReturn:                  ; was: locret_4B334
                                        ; Boss_DestroyerMk2WaitForLinkedPartsToDeactivate+E   j
                rts
; End of function Boss_DestroyerMk2WaitForLinkedPartsToDeactivate
; Run the debris helper until the final-transition timer expires
Boss_DestroyerMk2RunDebrisTransitionTimer:              ; was: sub_4B336
                jsr     Projectile_DestroyerMk2DebrisMain(pc)  ; (pc)
                nop
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2DebrisTransitionReturn
                addq.w  #2,4(a5)
Boss_DestroyerMk2DebrisTransitionReturn:                ; was: locret_4B346
                rts
; End of function Boss_DestroyerMk2RunDebrisTransitionTimer
; Fade the transition palette, then load the first replacement tile set
Gfx_DestroyerMk2FadeAndLoadFirstTransitionTiles:        ; was: sub_4B348
                bsr.s   Gfx_DestroyerMk2ApplyTransitionPaletteFade
                addq.w  #1,$48(a5)
                cmpi.w  #$F,$48(a5)
                bne.s   Gfx_DestroyerMk2FirstTransitionTileLoadReturn
                addq.w  #2,4(a5)
                lea     Gfx_DestroyerMk2FirstTransitionTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; ---------------------------------------------------------------------------
Gfx_DestroyerMk2FirstTransitionTileLoadDescriptor:  dc.w    $4480, $4000, $104, 0, 0, 0, 0, 0  ; was: word_4B366
; ---------------------------------------------------------------------------
Gfx_DestroyerMk2FirstTransitionTileLoadReturn:          ; was: locret_4B376
                rts
; End of function Gfx_DestroyerMk2FadeAndLoadFirstTransitionTiles
; Apply one step of the final-transition palette fade
Gfx_DestroyerMk2ApplyTransitionPaletteFade:             ; was: sub_4B378
                                        ; sub_4B394   p
                move.w  $48(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Gfx_DestroyerMk2ApplyTransitionPaletteFade
; Apply the last fade step and load the second replacement tile set
Gfx_DestroyerMk2FadeAndLoadSecondTransitionTiles:       ; was: sub_4B394
                bsr.s   Gfx_DestroyerMk2ApplyTransitionPaletteFade
                addq.w  #2,4(a5)
                lea     Gfx_DestroyerMk2SecondTransitionTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Gfx_DestroyerMk2FadeAndLoadSecondTransitionTiles
; ---------------------------------------------------------------------------
Gfx_DestroyerMk2SecondTransitionTileLoadDescriptor: dc.w    $4490, $4000, $104, 0, 0, 0, 0, 0  ; was: word_4B3A6

; Release transition input/display flags and advance the main state
Boss_DestroyerMk2ClearTransitionControlFlags:           ; was: sub_4B3B6
                bsr.s   Gfx_DestroyerMk2ApplyTransitionPaletteFade
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                bclr    #3,$4C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2ClearTransitionControlFlags
; Preserve types $240 and $3DC while clearing the remaining object pool
Boss_DestroyerMk2ClearObjectsForNextEncounter:          ; was: sub_4B3D0
                bsr.s   Gfx_DestroyerMk2ApplyTransitionPaletteFade
                move.w  #$240,d0
                move.w  #$3DC,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #4,(PlaneAScrollModeFlags).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2ClearObjectsForNextEncounter
; Count the transition fade back down, remove this entity, and advance
Boss_DestroyerMk2FinishTransitionPaletteFade:           ; was: sub_4B3EC
                bsr.s   Gfx_DestroyerMk2ApplyTransitionPaletteFade
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2TransitionPaletteFadeReturn
                clr.w   (a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2TransitionPaletteFadeReturn:           ; was: locret_4B3FA
                rts
; End of function Boss_DestroyerMk2FinishTransitionPaletteFade
; Select the central linked part for the shared activation helper
Boss_DestroyerMk2SelectCentralLinkedPart:               ; was: sub_4B3FC
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
; End of function Boss_DestroyerMk2SelectCentralLinkedPart
; Advance a selected linked part only when it is idle
Boss_DestroyerMk2ActivateLinkedPartIfIdle:              ; was: sub_4B400
                                        ; sub_4B084:Boss_DestroyerMk2ActivateSelectedFarLinkedPart   p
                tst.w   4(a0)
                bne.s   Boss_DestroyerMk2LinkedPartActivationReturn
                addq.w  #2,4(a0)
Boss_DestroyerMk2LinkedPartActivationReturn:            ; was: locret_4B40A
                rts
; End of function Boss_DestroyerMk2ActivateLinkedPartIfIdle
; Project four effects at successive angles and play sound $E9
Boss_DestroyerMk2EmitFourProjectedEffects:
                move.w  (PlayerCenterX).w,d0            ; was: sub_4B40C
                sub.w   $10(a5),d0
                bmi.s   Boss_DestroyerMk2InitializeLeftwardEffectProjection
                move.w  #$30,$58(a5)                    ; '0'
                move.w  #$1D0,$5A(a5)
                bra.s   Boss_DestroyerMk2FinishEffectProjectionSetup
; ---------------------------------------------------------------------------
Boss_DestroyerMk2InitializeLeftwardEffectProjection:    ; was: loc_4B424
                move.w  #$FFD0,$58(a5)
                move.w  #$D0,$5A(a5)
Boss_DestroyerMk2FinishEffectProjectionSetup:           ; was: loc_4B430
                move.w  $10(a5),d0
                add.w   d0,$58(a5)
                move.w  #4,$5C(a5)
Boss_DestroyerMk2ProjectedEffectLoop:                   ; was: loc_4B43E
                move.w  #4,d1
                move.w  #$8004,d2
                move.w  $58(a5),d3
                move.w  $14(a5),d4
                move.w  $5A(a5),d6
                jsr     (Boss_DestroyerMk2SpawnProjectedShot).l
                addi.w  #$20,$5A(a5)                    ; ' '
                subq.w  #1,$5C(a5)
                bne.s   Boss_DestroyerMk2ProjectedEffectLoop
                move.b  #$E9,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Boss_DestroyerMk2EmitFourProjectedEffects
; Adds a uniform offset to all 255 scroll rows until the first row reaches $110
Gfx_DestroyerMk2ApplyUniformScrollOffset:               ; was: sub_4B470
                cmpi.w  #$110,(DestroyerMk2ScrollRows).w
                bge.s   Gfx_DestroyerMk2ReportScrollOffsetLimit
                move.w  #$FE,d7
                lea     (DestroyerMk2ScrollRows).w,a0
Gfx_DestroyerMk2ApplyUniformScrollOffsetLoop:           ; was: loc_4B480
                add.w   d0,(a0)+
                dbf     d7,Gfx_DestroyerMk2ApplyUniformScrollOffsetLoop
                clr.w   d0
                rts
; ---------------------------------------------------------------------------
Gfx_DestroyerMk2ReportScrollOffsetLimit:                ; was: loc_4B48A
                move.w  #1,d0
                rts
; End of function Gfx_DestroyerMk2ApplyUniformScrollOffset
; Entity type $248 component and component-projectile state dispatcher
Object_DestroyerMk2ComponentMain:                       ; was: sub_4B490
                move.w  4(a5),d0
                lea     Object_DestroyerMk2ComponentStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2ComponentMain
; ---------------------------------------------------------------------------
Object_DestroyerMk2ComponentStateHandlers:  dc.w    Object_DestroyerMk2ComponentIdle-*  ; was: off_4B49C
                dc.w    Object_DestroyerMk2ActivateFromLinkedState-*
                dc.w    Object_DestroyerMk2InitializeProjectile-*
                dc.w    Object_DestroyerMk2SpawnProjectile-*
                dc.w    Object_DestroyerMk2InitializeMovement-*
                dc.w    Object_DestroyerMk2UpdateMovement-*
                dc.w    Object_DestroyerMk2SwitchComponentMapping-*
                dc.w    Object_DestroyerMk2WaitThenAdvanceState-*
                dc.w    Object_DestroyerMk2DeactivateAndApplyScrollPreset-*
                dc.w    Object_DestroyerMk2ResetAfterStageGate-*

Object_DestroyerMk2ComponentIdle:                       ; was: nullsub_105
                rts
; End of function Object_DestroyerMk2ComponentIdle

; Activate after the referenced linked part becomes idle
Object_DestroyerMk2ActivateFromLinkedState:             ; was: sub_4B4B2
                tst.w   (DataLoaderControl).w
                bmi.w   Object_DestroyerMk2StageGateReturn
                move.w  $4E(a5),d0
                movea.w Object_DestroyerMk2LinkedObjectAddressTable(pc,d0.w),a0
                tst.w   4(a0)
                bne.w   Object_DestroyerMk2StageGateReturn
                addq.w  #2,4(a5)
                ori.w   #$8000,2(a5)
                lea     Object_DestroyerMk2ActivationScrollHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2ActivateFromLinkedState
; ---------------------------------------------------------------------------
Object_DestroyerMk2ActivationScrollHandlers:    dc.w    Object_DestroyerMk2ApplyScrollPresetA-*  ; was: off_4B4DC
                dc.w    Object_DestroyerMk2ApplyScrollPresetB-*
                dc.w    Object_DestroyerMk2ApplyScrollPresetC-*
                dc.w    Object_DestroyerMk2ApplyScrollPresetD-*

; Apply stage-14 component scroll preset A
Object_DestroyerMk2ApplyScrollPresetA:                  ; was: sub_4B4E4
                move.l  #$44804001,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyScrollPresetA
; Apply stage-14 component scroll preset B
Object_DestroyerMk2ApplyScrollPresetB:                  ; was: sub_4B4F2
                move.l  #$44984001,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyScrollPresetB
; Apply stage-14 component scroll preset C
Object_DestroyerMk2ApplyScrollPresetC:                  ; was: sub_4B500
                move.l  #$4C804001,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyScrollPresetC
; Apply stage-14 component scroll preset D
Object_DestroyerMk2ApplyScrollPresetD:                  ; was: sub_4B50E
                move.l  #$4C984001,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyScrollPresetD
; ---------------------------------------------------------------------------
Object_DestroyerMk2LinkedObjectAddressTable:    dc.w    $C800, $C7A0, $C8C0, $C860  ; was: word_4B51C

; Initialize a component's mapping and projectile delay
Object_DestroyerMk2InitializeProjectile:                ; was: sub_4B524
                tst.w   (DataLoaderControl).w
                bmi.w   Object_DestroyerMk2StageGateReturn
                move.l  #Boss_DestroyerMk2ProjectileMapping,8(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Object_DestroyerMk2InitializeProjectile
; Spawn a type-$248 projectile using the component-index tables
Object_DestroyerMk2SpawnProjectile:                     ; was: sub_4B540
                subq.w  #1,$48(a5)
                bpl.w   Object_DestroyerMk2ProjectileSpawnReturn
                addq.w  #2,4(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Object_DestroyerMk2ProjectileSpawnReturn
                move.w  #$248,(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.b  #$10,$23(a0)
                move.l  #$FC04D42C,$2C(a0)
                move.w  #$100,$26(a0)
                move.w  #$CD00,2(a0)
                move.l  #Boss_DestroyerMk2SpawnedProjectileMapping,8(a0)
                move.w  #$4300,$E(a0)
                move.b  $20(a5),$20(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  $4E(a5),d0
                move.w  Object_DestroyerMk2ProjectileXOffsetTable(pc,d0.w),d1
                add.w   d1,$10(a0)
                move.w  Object_DestroyerMk2ProjectileYOffsetTable(pc,d0.w),d1
                add.w   d1,$14(a0)
                move.w  Object_DestroyerMk2ProjectileDirectionTable(pc,d0.w),$4C(a0)
                add.w   d0,d0
                move.l  Object_DestroyerMk2ProjectileVelocityTable(pc,d0.w),$50(a0)
                tst.w   (DifficultyMode).w
                beq.s   Object_DestroyerMk2SetNormalProjectileDelay
                move.w  #$C,$48(a5)
                move.w  #$C,$48(a0)
                rts
; ---------------------------------------------------------------------------
Object_DestroyerMk2SetNormalProjectileDelay:            ; was: loc_4B5D0
                move.w  #$18,$48(a5)
                move.w  #$18,$48(a0)
Object_DestroyerMk2ProjectileSpawnReturn:               ; was: locret_4B5DC
                                        ; Object_DestroyerMk2SpawnProjectile+12   j
                rts
; End of function Object_DestroyerMk2SpawnProjectile
; ---------------------------------------------------------------------------
Object_DestroyerMk2ProjectileXOffsetTable:  dc.w    $18, $FFE8  ; was: word_4B5DE
                dc.w    $18, $FFE8
Object_DestroyerMk2ProjectileYOffsetTable:  dc.w    1, 1  ; was: word_4B5E6
                dc.w    $FFFF, $FFFF
Object_DestroyerMk2ProjectileDirectionTable:    dc.w    $FFFF, 1  ; was: word_4B5EE
                dc.w    $FFFF, 1
Object_DestroyerMk2ProjectileVelocityTable: dc.l    $FFFFE000, $2000  ; was: dword_4B5F6
                dc.l    $FFFFE000, $2000

; Initialize velocity and acceleration selected by component index
Object_DestroyerMk2InitializeMovement:                  ; was: sub_4B606
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2MovementInitReturn
                move.w  $4E(a5),d0
                clr.l   $58(a5)
                add.w   d0,d0
                move.l  Object_DestroyerMk2InitialVelocityTable(pc,d0.w),$50(a5)
                move.l  Object_DestroyerMk2AccelerationTable(pc,d0.w),$54(a5)
                addq.w  #2,4(a5)
                move.b  #$E7,d0
                jsr     (Sound_QueueSFXRequest).l
Object_DestroyerMk2MovementInitReturn:                  ; was: locret_4B630
                rts
; End of function Object_DestroyerMk2InitializeMovement
; ---------------------------------------------------------------------------
Object_DestroyerMk2InitialVelocityTable:    dc.l    $20000, $FFFE0000  ; was: dword_4B632
                dc.l    $20000, $FFFE0000
Object_DestroyerMk2AccelerationTable:   dc.l    $FFFFE000, $2000  ; was: dword_4B642
                dc.l    $FFFFE000, $2000

; Integrate component motion and apply its offset to seven scroll layers
Object_DestroyerMk2UpdateMovement:                      ; was: sub_4B652
                move.l  $54(a5),d0
                add.l   d0,$50(a5)
                move.l  $50(a5),d0
                add.l   d0,$58(a5)
                move.w  $58(a5),d0
                cmpi.w  #4,$4E(a5)
                bcc.s   Object_DestroyerMk2SelectLowerScrollLayerGroup
                lea     (HScrollPlaneARow75).w,a0
                bra.s   Object_DestroyerMk2ApplyMovementToScrollLayers
; ---------------------------------------------------------------------------
Object_DestroyerMk2SelectLowerScrollLayerGroup:         ; was: loc_4B674
                lea     (HScrollPlaneARow200).w,a0
Object_DestroyerMk2ApplyMovementToScrollLayers:         ; was: loc_4B678
                bsr.s   Gfx_UpdateMultipleScrollLayers
                tst.l   $58(a5)
                bne.s   Object_DestroyerMk2MovementUpdateReturn
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2MovementUpdateReturn:                ; was: locret_4B68A
                rts
; End of function Object_DestroyerMk2UpdateMovement
