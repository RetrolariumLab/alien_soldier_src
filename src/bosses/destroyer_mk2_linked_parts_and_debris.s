; Add d0 to seven consecutive scroll-layer values at a0
Gfx_UpdateMultipleScrollLayers:                         ; was: sub_4B68C
                add.w   (HScrollPlaneARow184).w,d0
                move.w  #6,d7
Gfx_UpdateMultipleScrollLayerBlocksLoop:                ; was: loc_4B694
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                lea     $10(a0),a0
                dbf     d7,Gfx_UpdateMultipleScrollLayerBlocksLoop
                rts
; End of function Gfx_UpdateMultipleScrollLayers
; Change the type-$248 component mapping after its delay
Object_DestroyerMk2SwitchComponentMapping:              ; was: sub_4B6AC
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2SwitchComponentMappingReturn
                move.l  #Boss_DestroyerMk2ComponentMapping,8(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2SwitchComponentMappingReturn:        ; was: locret_4B6C4
                rts
; End of function Object_DestroyerMk2SwitchComponentMapping
; Decrement the type-$248 timer and advance when it expires
Object_DestroyerMk2WaitThenAdvanceState:                ; was: sub_4B6C6
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2WaitThenAdvanceReturn
                addq.w  #2,4(a5)
Object_DestroyerMk2WaitThenAdvanceReturn:               ; was: locret_4B6D0
                rts
; End of function Object_DestroyerMk2WaitThenAdvanceState
; Deactivate the component after the stage gate and apply its scroll preset
Object_DestroyerMk2DeactivateAndApplyScrollPreset:      ; was: sub_4B6D2
                tst.w   (DataLoaderControl).w
                bmi.w   Object_DestroyerMk2StageGateReturn
                addq.w  #2,4(a5)
                andi.w  #$7FFF,2(a5)
                move.w  $4E(a5),d0
                lea     Object_DestroyerMk2DeactivationScrollHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2DeactivateAndApplyScrollPreset
; ---------------------------------------------------------------------------
Object_DestroyerMk2DeactivationScrollHandlers:  dc.w    Object_DestroyerMk2ApplyDeactivationScrollPresetA-*  ; was: off_4B6F0
                dc.w    Object_DestroyerMk2ApplyDeactivationScrollPresetB-*
                dc.w    Object_DestroyerMk2ApplyDeactivationScrollPresetC-*
                dc.w    Object_DestroyerMk2ApplyDeactivationScrollPresetD-*

; Apply deactivation scroll preset A
Object_DestroyerMk2ApplyDeactivationScrollPresetA:      ; was: sub_4B6F8
                move.l  #$448032C1,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyDeactivationScrollPresetA
; Apply deactivation scroll preset B
Object_DestroyerMk2ApplyDeactivationScrollPresetB:      ; was: sub_4B706
                move.l  #$449832A1,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyDeactivationScrollPresetB
; Apply deactivation scroll preset C
Object_DestroyerMk2ApplyDeactivationScrollPresetC:      ; was: sub_4B714
                move.l  #$4C8031C1,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyDeactivationScrollPresetC
; Apply deactivation scroll preset D
Object_DestroyerMk2ApplyDeactivationScrollPresetD:      ; was: sub_4B722
                move.l  #$4C9831A1,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Object_DestroyerMk2ApplyDeactivationScrollPresetD
; Reset the component for reuse after the stage gate
Object_DestroyerMk2ResetAfterStageGate:                 ; was: sub_4B730
                tst.w   (DataLoaderControl).w
                bmi.s   Object_DestroyerMk2StageGateResetReturn
                clr.w   4(a5)
Object_DestroyerMk2StageGateResetReturn:                ; was: locret_4B73A
                rts
; End of function Object_DestroyerMk2ResetAfterStageGate
; Dispatch type-$25C moving parts by mode field $46
Object_DestroyerMk2MovingPartMain:                      ; was: sub_4B73C
                move.w  $46(a5),d0
                lea     Object_DestroyerMk2MovingPartModeHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2MovingPartMain
; ---------------------------------------------------------------------------
Object_DestroyerMk2MovingPartModeHandlers:  dc.w    Object_DestroyerMk2CentralPartStateDispatch-*  ; was: off_4B748
                dc.w    Object_DestroyerMk2BouncingPartAStateDispatch-*
                dc.w    Object_DestroyerMk2BouncingPartBStateDispatch-*

; Dispatch the central moving part by state field 4
Object_DestroyerMk2CentralPartStateDispatch:            ; was: sub_4B74E
                move.w  4(a5),d0
                lea     Object_DestroyerMk2CentralPartStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2CentralPartStateDispatch
; ---------------------------------------------------------------------------
Object_DestroyerMk2CentralPartStateHandlers:    dc.w    Object_DestroyerMk2ReleaseCentralPart-*  ; was: off_4B75A
                dc.w    Object_DestroyerMk2UpdateFallingCentralPart-*
                dc.w    Object_DestroyerMk2MovingPartIdle-*

; Release the central part after the controller transition or health trigger
Object_DestroyerMk2ReleaseCentralPart:                  ; was: sub_4B760
                cmpi.w  #$2A,(PrimaryEntityState).w     ; '*'
                bcc.s   Object_DestroyerMk2ReleaseCentralPartNow
                tst.w   $24(a5)
                bpl.s   Object_DestroyerMk2ReleaseCentralPartReturn
Object_DestroyerMk2ReleaseCentralPartNow:               ; was: loc_4B76E
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                subq.w  #1,(SharedScratchLong4).w
                addq.w  #2,4(a5)
                move.w  #$FFFC,$1C(a5)
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bmi.s   Object_DestroyerMk2LaunchCentralPartRight
                move.w  #$FFFE,$18(a5)
                rts
; ---------------------------------------------------------------------------
Object_DestroyerMk2LaunchCentralPartRight:              ; was: loc_4B798
                move.w  #2,$18(a5)
Object_DestroyerMk2ReleaseCentralPartReturn:            ; was: locret_4B79E
                rts
; End of function Object_DestroyerMk2ReleaseCentralPart
; Rotate and accelerate the released central part while emitting particles
Object_DestroyerMk2UpdateFallingCentralPart:            ; was: sub_4B7A0
                addi.l  #$4000,$1C(a5)
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1C0,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                ori.w   #$8000,$E(a5)
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Object_DestroyerMk2CheckFallingCentralPartBounds
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Object_DestroyerMk2CheckFallingCentralPartBounds
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                move.b  $20(a5),$20(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                jsr     (Projectile_InitType88).l
                subq.b  #4,$20(a0)
                ori.w   #$8000,$E(a0)
Object_DestroyerMk2CheckFallingCentralPartBounds:       ; was: loc_4B7FC
                                        ; Object_DestroyerMk2UpdateFallingCentralPart+30   j
                cmpi.w  #$180,$14(a5)
                bcs.s   Object_DestroyerMk2FallingCentralPartReturn
                move.w  #$1000,2(a5)
Object_DestroyerMk2FallingCentralPartReturn:            ; was: locret_4B80A
                rts
; End of function Object_DestroyerMk2UpdateFallingCentralPart
Object_DestroyerMk2MovingPartIdle:                      ; was: nullsub_106
                rts
; End of function Object_DestroyerMk2MovingPartIdle

; Handle the first bouncing-part collision mode and dispatch its state
Object_DestroyerMk2BouncingPartAStateDispatch:          ; was: sub_4B80E
                cmpi.w  #8,4(a5)
                bcc.s   Object_DestroyerMk2DispatchBouncingPartAState
                bclr    #7,$22(a5)
                beq.s   Object_DestroyerMk2DispatchBouncingPartAState
                bclr    #4,$22(a5)
                beq.s   Object_DestroyerMk2ReflectBouncingPartA
                move.l  #$FFFC0000,$1C(a5)
Object_DestroyerMk2ReflectBouncingPartA:                ; was: loc_4B82E
                neg.l   $18(a5)
                clr.b   $21(a5)
                move.w  #8,4(a5)
Object_DestroyerMk2DispatchBouncingPartAState:          ; was: loc_4B83C
                                        ; Object_DestroyerMk2BouncingPartAStateDispatch+E   j
                move.w  4(a5),d0
                lea     Object_DestroyerMk2BouncingPartAStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2BouncingPartAStateDispatch
; ---------------------------------------------------------------------------
Object_DestroyerMk2BouncingPartAStateHandlers:  dc.w    Object_DestroyerMk2InitializeBouncingPartA-*  ; was: off_4B848
                dc.w    Object_DestroyerMk2WaitAndStopBouncingPartA-*
                dc.w    Object_DestroyerMk2RotateBouncingPartAThenLaunch-*
                dc.w    Object_DestroyerMk2RotateBouncingPartAUntilXBound-*
                dc.w    Object_DestroyerMk2AccelerateBouncingPartADownward-*

; Initialize the first bouncing-part motion sequence
Object_DestroyerMk2InitializeBouncingPartA:             ; was: sub_4B852
                addq.w  #2,4(a5)
                move.w  #$14,$48(a5)
                move.w  #4,$18(a5)
                btst    #0,$45(a5)
                bne.s   Object_DestroyerMk2SetPositiveVerticalVelocityA
                move.w  #$FFFF,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Object_DestroyerMk2SetPositiveVerticalVelocityA:        ; was: loc_4B872
                move.w  #1,$1C(a5)
                rts
; End of function Object_DestroyerMk2InitializeBouncingPartA
; Stop the first bouncing part after its initial delay
Object_DestroyerMk2WaitAndStopBouncingPartA:            ; was: sub_4B87A
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2BouncingPartAStopReturn
                clr.w   $18(a5)
                clr.w   $1C(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2BouncingPartAStopReturn:             ; was: locret_4B892
                rts
; End of function Object_DestroyerMk2WaitAndStopBouncingPartA
; Rotate the first bouncing part, then seed its horizontal velocity
Object_DestroyerMk2RotateBouncingPartAThenLaunch:       ; was: sub_4B894
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2BouncingPartALaunchReturn
                move.w  #2,$18(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2BouncingPartALaunchReturn:           ; was: locret_4B8B6
                rts
; End of function Object_DestroyerMk2RotateBouncingPartAThenLaunch
; Rotate the first bouncing part until its X coordinate reaches the bound
Object_DestroyerMk2RotateBouncingPartAUntilXBound:      ; was: sub_4B8B8
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                cmpi.w  #$1E0,$10(a5)
                bcs.s   Object_DestroyerMk2BouncingPartAXBoundReturn
                move.w  #$1000,2(a5)
Object_DestroyerMk2BouncingPartAXBoundReturn:           ; was: locret_4B8D8
                rts
; End of function Object_DestroyerMk2RotateBouncingPartAUntilXBound
; Rotate and accelerate the first bouncing part downward until its Y bound
Object_DestroyerMk2AccelerateBouncingPartADownward:     ; was: sub_4B8DA
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                addi.l  #$4000,$1C(a5)
                cmpi.w  #$180,$14(a5)
                blt.s   Object_DestroyerMk2BouncingPartAFallReturn
                move.w  #$1000,2(a5)
Object_DestroyerMk2BouncingPartAFallReturn:             ; was: locret_4B902
                rts
; End of function Object_DestroyerMk2AccelerateBouncingPartADownward
; Handle the second bouncing-part collision mode and dispatch its state
Object_DestroyerMk2BouncingPartBStateDispatch:          ; was: sub_4B904
                cmpi.w  #8,4(a5)
                bcc.s   Object_DestroyerMk2DispatchBouncingPartBState
                tst.w   (SharedScratchLong7+2).w
                beq.s   Object_DestroyerMk2CheckBouncingPartBCollision
                move.w  $44(a5),$1C(a5)
                bra.s   Object_DestroyerMk2ReflectBouncingPartB
; ---------------------------------------------------------------------------
Object_DestroyerMk2CheckBouncingPartBCollision:         ; was: loc_4B91A
                bclr    #7,$22(a5)
                beq.s   Object_DestroyerMk2DispatchBouncingPartBState
                bclr    #4,$22(a5)
                beq.s   Object_DestroyerMk2ReflectBouncingPartB
                move.l  #$FFFC0000,$1C(a5)
Object_DestroyerMk2ReflectBouncingPartB:                ; was: loc_4B932
                                        ; Object_DestroyerMk2BouncingPartBStateDispatch+24   j
                move.w  #1,(SharedScratchLong7+2).w
                neg.l   $18(a5)
                clr.b   $21(a5)
                move.w  #8,4(a5)
Object_DestroyerMk2DispatchBouncingPartBState:          ; was: loc_4B946
                                        ; Object_DestroyerMk2BouncingPartBStateDispatch+1C   j
                move.w  4(a5),d0
                lea     Object_DestroyerMk2BouncingPartBStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2BouncingPartBStateDispatch
; ---------------------------------------------------------------------------
Object_DestroyerMk2BouncingPartBStateHandlers:  dc.w    Object_DestroyerMk2InitializeBouncingPartB-*  ; was: off_4B952
                dc.w    Object_DestroyerMk2WaitAndStopBouncingPartB-*
                dc.w    Object_DestroyerMk2RotateAndMoveBouncingPartB-*
                dc.w    Object_DestroyerMk2RotateBouncingPartBUntilXBound-*
                dc.w    Object_DestroyerMk2AccelerateBouncingPartBDownward-*

; Initialize the second bouncing-part motion sequence
Object_DestroyerMk2InitializeBouncingPartB:             ; was: sub_4B95C
                addq.w  #2,4(a5)
                move.w  #$14,$48(a5)
                move.w  #4,$18(a5)
                rts
; End of function Object_DestroyerMk2InitializeBouncingPartB
; Stop the second bouncing part after its initial delay
Object_DestroyerMk2WaitAndStopBouncingPartB:            ; was: sub_4B96E
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2BouncingPartBStopReturn
                clr.w   $18(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2BouncingPartBStopReturn:             ; was: locret_4B982
                rts
; End of function Object_DestroyerMk2WaitAndStopBouncingPartB
; Rotate and move the second bouncing part vertically during its timer
Object_DestroyerMk2RotateAndMoveBouncingPartB:          ; was: sub_4B984
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                move.w  $44(a5),d0
                add.w   d0,$14(a5)
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2BouncingPartBMoveReturn
                move.w  #2,$18(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2BouncingPartBMoveReturn:             ; was: locret_4B9AE
                rts
; End of function Object_DestroyerMk2RotateAndMoveBouncingPartB
; Rotate the second bouncing part until its X coordinate reaches the bound
Object_DestroyerMk2RotateBouncingPartBUntilXBound:      ; was: sub_4B9B0
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                cmpi.w  #$1E0,$10(a5)
                bcs.s   Object_DestroyerMk2BouncingPartBXBoundReturn
                move.w  #$1000,2(a5)
Object_DestroyerMk2BouncingPartBXBoundReturn:           ; was: locret_4B9D0
                rts
; End of function Object_DestroyerMk2RotateBouncingPartBUntilXBound
; Rotate and accelerate the second bouncing part downward until its Y bound
Object_DestroyerMk2AccelerateBouncingPartBDownward:     ; was: sub_4B9D2
                addi.w  #$10,$4C(a5)
                move.w  $4C(a5),d2
                andi.w  #$1FE,d2
                bsr.w   Boss_DestroyerMk2SelectCurrentObjectForFrame
                addi.l  #$4000,$1C(a5)
                cmpi.w  #$180,$14(a5)
                blt.s   Object_DestroyerMk2BouncingPartBFallReturn
                move.w  #$1000,2(a5)
Object_DestroyerMk2BouncingPartBFallReturn:             ; was: locret_4B9FA
                rts
; End of function Object_DestroyerMk2AccelerateBouncingPartBDownward
; Dispatch type-$24C horizontal motion while the object remains in bounds
Object_DestroyerMk2HorizontalPartMain:                  ; was: sub_4B9FC
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                cmpi.w  #$C10,d0
                bcs.s   Object_DestroyerMk2MarkHorizontalPartOutOfBounds
                cmpi.w  #$E70,d0
                bhi.s   Object_DestroyerMk2MarkHorizontalPartOutOfBounds
                move.w  4(a5),d0
                lea     Object_DestroyerMk2HorizontalPartStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2HorizontalPartMain
; ---------------------------------------------------------------------------
Object_DestroyerMk2HorizontalPartStateHandlers: dc.w    Object_DestroyerMk2FlickerThenStartHorizontalPart-*  ; was: off_4BA1C
                dc.w    Object_DestroyerMk2AccelerateHorizontalPart-*

; Flicker during the delay, then start horizontal motion
Object_DestroyerMk2FlickerThenStartHorizontalPart:      ; was: sub_4BA20
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2HorizontalPartStartReturn
                ori.w   #$8000,2(a5)
                move.w  $4C(a5),$18(a5)
                addq.w  #2,4(a5)
Object_DestroyerMk2HorizontalPartStartReturn:           ; was: locret_4BA3C
                rts
; End of function Object_DestroyerMk2FlickerThenStartHorizontalPart
; Add the stored acceleration to horizontal velocity
Object_DestroyerMk2AccelerateHorizontalPart:            ; was: sub_4BA3E
                move.l  $50(a5),d0
                add.l   d0,$18(a5)
                rts
; End of function Object_DestroyerMk2AccelerateHorizontalPart
; Mark the horizontal part when its world X is outside the allowed range
Object_DestroyerMk2MarkHorizontalPartOutOfBounds:       ; was: sub_4BA48
                                        ; Object_DestroyerMk2HorizontalPartMain+12   j
                bset    #4,2(a5)
                rts
; End of function Object_DestroyerMk2MarkHorizontalPartOutOfBounds
; Dispatch the type-$260 eight-fragment group controller
Object_DestroyerMk2FragmentGroupMain:                   ; was: sub_4BA50
                move.w  4(a5),d0
                lea     Object_DestroyerMk2FragmentGroupStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_DestroyerMk2FragmentGroupMain
; ---------------------------------------------------------------------------
Object_DestroyerMk2FragmentGroupStateHandlers:  dc.w    Object_DestroyerMk2FragmentGroupIdle-*  ; was: off_4BA5C
                dc.w    Object_DestroyerMk2InitializeFragmentGroup-*
                dc.w    Object_DestroyerMk2WaitForFragmentGroupCompletion-*
                dc.w    Object_DestroyerMk2ResetFragmentGroupAfterDelay-*

Object_DestroyerMk2FragmentGroupIdle:                   ; was: nullsub_107
                rts
; End of function Object_DestroyerMk2FragmentGroupIdle

; Initialize eight type-$260 fragment records with directional motion
Object_DestroyerMk2InitializeFragmentGroup:             ; was: sub_4BA66
                addq.w  #2,4(a5)
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bmi.s   Object_DestroyerMk2SelectLeftFragmentMotion
                move.w  #$30,d1                         ; '0'
                move.w  #4,d2
                bra.s   Object_DestroyerMk2CalculateFragmentDistance
; ---------------------------------------------------------------------------
Object_DestroyerMk2SelectLeftFragmentMotion:            ; was: loc_4BA7E
                move.w  #$FFD0,d1
                move.w  #$FFFC,d2
Object_DestroyerMk2CalculateFragmentDistance:           ; was: loc_4BA86
                sub.w   d1,d0
                bpl.s   Object_DestroyerMk2ScaleFragmentDistance
                neg.w   d0
Object_DestroyerMk2ScaleFragmentDistance:               ; was: loc_4BA8C
                lsr.w   #2,d0
                cmpi.w  #$110,(PlayerYPosition).w
                bcs.s   Object_DestroyerMk2SelectUpwardFragmentVelocity
                move.w  #4,d3
                bra.s   Object_DestroyerMk2InitializeFragmentRecords
; ---------------------------------------------------------------------------
Object_DestroyerMk2SelectUpwardFragmentVelocity:        ; was: loc_4BA9C
                move.w  #$FFFC,d3
Object_DestroyerMk2InitializeFragmentRecords:           ; was: loc_4BAA0
                movea.w #(SeventeenthEntityType-M68K_RAM),a0
                move.w  #7,d7
                clr.w   d6
Object_DestroyerMk2InitializeFragmentRecordLoop:        ; was: loc_4BAAA
                move.w  #$260,(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FF02FF02,$2C(a0)
                move.w  #$80,$26(a0)
                move.w  #$6D00,2(a0)
                move.l  #SharedCombatSpriteAnimation12,8(a0)
                move.w  #$8480,$E(a0)
                clr.w   $C(a0)
                move.l  $10(a5),$10(a0)
                add.w   d1,$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  d6,$48(a0)
                move.w  d0,$4A(a0)
                move.w  d2,$4C(a0)
                move.w  d3,$50(a0)
                addq.w  #4,d6
                lea     $60(a0),a0
                dbf     d7,Object_DestroyerMk2InitializeFragmentRecordLoop
                move.w  #8,$52(a5)
                rts
; End of function Object_DestroyerMk2InitializeFragmentGroup
; Wait for the fragment-group completion counter to clear
Object_DestroyerMk2WaitForFragmentGroupCompletion:      ; was: sub_4BB0C
                tst.w   $52(a5)
                bne.s   Object_DestroyerMk2FragmentGroupWaitReturn
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Object_DestroyerMk2FragmentGroupWaitReturn:             ; was: locret_4BB1C
                rts
; End of function Object_DestroyerMk2WaitForFragmentGroupCompletion
; Return the fragment-group controller to idle after its delay
Object_DestroyerMk2ResetFragmentGroupAfterDelay:        ; was: sub_4BB1E
                subq.w  #1,$48(a5)
                bne.s   Object_DestroyerMk2FragmentGroupResetReturn
                clr.w   4(a5)
Object_DestroyerMk2FragmentGroupResetReturn:            ; was: locret_4BB28
                rts
; End of function Object_DestroyerMk2ResetFragmentGroupAfterDelay
; Dispatch persistent transition debris by state field 4
Object_TransitionDebrisMain:                            ; was: sub_4BB2A
                move.w  4(a5),d0
                lea     Object_TransitionDebrisStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Object_TransitionDebrisMain
; ---------------------------------------------------------------------------
Object_TransitionDebrisStateHandlers:   dc.w    Object_TransitionDebrisDelayAndEnable-*  ; was: off_4BB36
                dc.w    Object_TransitionDebrisLaunchHorizontally-*
                dc.w    Object_TransitionDebrisSwitchToVerticalMotion-*
                dc.w    Object_TransitionDebrisResolveBoundsOrCollision-*

; Delay, enable drawing, and advance the transition debris
Object_TransitionDebrisDelayAndEnable:                  ; was: sub_4BB3E
                subq.w  #1,$48(a5)
                bpl.s   Object_TransitionDebrisEnableReturn
                move.w  #$10,$48(a5)
                ori.w   #$8000,2(a5)
                addq.w  #2,4(a5)
Object_TransitionDebrisEnableReturn:                    ; was: locret_4BB54
                rts
; End of function Object_TransitionDebrisDelayAndEnable
; Load stored horizontal velocity after the launch delay
Object_TransitionDebrisLaunchHorizontally:              ; was: sub_4BB56
                subq.w  #1,$48(a5)
                bpl.s   Object_TransitionDebrisLaunchReturn
                move.l  $4C(a5),$18(a5)
                addq.w  #2,4(a5)
                move.b  #$E8,d0
                jsr     (Sound_QueueSFXRequest).l
Object_TransitionDebrisLaunchReturn:                    ; was: locret_4BB70
                rts
; End of function Object_TransitionDebrisLaunchHorizontally
; Stop horizontal motion and switch to stored vertical velocity
Object_TransitionDebrisSwitchToVerticalMotion:          ; was: sub_4BB72
                subq.w  #1,$4A(a5)
                bpl.s   Object_TransitionDebrisVerticalMotionReturn
                clr.w   $18(a5)
                move.l  $50(a5),$1C(a5)
                addq.w  #2,4(a5)
Object_TransitionDebrisVerticalMotionReturn:            ; was: locret_4BB86
                rts
; End of function Object_TransitionDebrisSwitchToVerticalMotion
; Remove out-of-bounds debris or convert collided debris to a type-$88 effect
Object_TransitionDebrisResolveBoundsOrCollision:        ; was: sub_4BB88
                cmpi.w  #$180,$14(a5)
                bcc.s   Object_TransitionDebrisRemoveOutsideVerticalBounds
                cmpi.w  #$80,$14(a5)
                bls.s   Object_TransitionDebrisRemoveOutsideVerticalBounds
                moveq   #0,d0
                move.w  d0,d1
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                bne.s   Object_TransitionDebrisConvertAfterCollision
                rts
; ---------------------------------------------------------------------------
Object_TransitionDebrisRemoveOutsideVerticalBounds:     ; was: loc_4BBA8
                                        ; Object_TransitionDebrisResolveBoundsOrCollision+E   j
                subq.w  #1,(QuaternaryEntityWork52).w
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Object_TransitionDebrisConvertAfterCollision:           ; was: loc_4BBB4
                move.w  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                subq.w  #1,(QuaternaryEntityWork52).w
                clr.b   $21(a5)
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                move.w  $1C(a5),d0
                neg.w   d0
                asr.w   #1,d0
                move.w  d0,$1C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                move.w  d0,$18(a5)
                rts
; End of function Object_TransitionDebrisResolveBoundsOrCollision
; Cycles two palette-buffer words every four frames
Gfx_DestroyerMk2CyclePaletteWords:                      ; was: sub_4BBF0
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Gfx_DestroyerMk2PaletteCycleReturn
                move.w  (SharedScratchLong6).w,d0
                move.w  Gfx_DestroyerMk2PrimaryPaletteCycleTable(pc,d0.w),(PaletteActiveColor51).w
                move.w  Gfx_DestroyerMk2SecondaryPaletteCycleTable(pc,d0.w),(PaletteActiveColor52).w
                addq.w  #2,(SharedScratchLong6).w
                cmpi.w  #$14,(SharedScratchLong6).w
                bne.s   Gfx_DestroyerMk2PaletteCycleReturn
                clr.w   (SharedScratchLong6).w
Gfx_DestroyerMk2PaletteCycleReturn:                     ; was: locret_4BC1A
                                        ; Gfx_DestroyerMk2CyclePaletteWords+24   j
                rts
; End of function Gfx_DestroyerMk2CyclePaletteWords
; ---------------------------------------------------------------------------
Gfx_DestroyerMk2PrimaryPaletteCycleTable:   dc.w    $2C8, $A6, $84, $62, $40, $20, $40, $62, $84, $A6  ; was: word_4BC1C
Gfx_DestroyerMk2SecondaryPaletteCycleTable: dc.w    $64, $44, $42, $22, $20, 0, $20, $22, $42, $44  ; was: word_4BC30

; Updates the fixed and orbiting linked-object geometry
Boss_DestroyerMk2UpdateLinkedObjectGeometry:            ; was: sub_4BC44
                                        ; sub_4ABC6   p
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  $4C(a0),d0
                add.w   d0,$14(a0)
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  $4C(a0),d0
                add.w   d0,$14(a0)
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  #3,d7
                movea.w #(FifthEntityType-M68K_RAM),a0
Boss_DestroyerMk2UpdateLinkedComponentLoop:             ; was: loc_4BC8C
                cmpi.w  #4,$4E(a0)
                bcc.s   Boss_DestroyerMk2SelectLowerComponentScrollGroup
                lea     (HScrollPlaneARow75).w,a1
                bra.s   Boss_DestroyerMk2UpdateLinkedComponentPosition
; ---------------------------------------------------------------------------
Boss_DestroyerMk2SelectLowerComponentScrollGroup:       ; was: loc_4BC9A
                lea     (HScrollPlaneARow200).w,a1
Boss_DestroyerMk2UpdateLinkedComponentPosition:         ; was: loc_4BC9E
                move.w  (a1),d0
                addi.w  #$C0,d0
                add.w   $4A(a0),d0
                add.w   $58(a0),d0
                move.w  d0,$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  $4C(a0),d0
                add.w   d0,$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2UpdateLinkedComponentLoop
                move.l  (SharedScratchLong3).w,d0
                add.l   d0,(SharedScratchLong2).w
                andi.w  #$1FF,(SharedScratchLong2).w
                clr.w   d3
                move.b  $20(a5),d3
                movea.w #(NinthEntityType-M68K_RAM),a0
                move.w  (SharedScratchLong1).w,d5
                move.w  (SharedScratchLong2).w,d6
                lea     (Math_SineTable).l,a1
                move.w  #7,d7
Boss_DestroyerMk2UpdateOrbitingPartLoop:                ; was: loc_4BCF0
                tst.w   4(a0)
                bne.w   Boss_DestroyerMk2AdvanceOrbitingPartLoop
                move.w  $4C(a0),d0
                add.w   d6,d0
                andi.w  #$1FE,d0
                move.w  (a1,d0.w),d1
                move.w  $4A(a0),d2
                add.w   d5,d2
                muls.w  d2,d1
                add.l   $10(a5),d1
                move.l  d1,$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  d0,d2
                bsr.w   Boss_DestroyerMk2SelectOrbitingPartFrame
                move.w  -$80(a1,d0.w),d1
                muls.w  #$40,d1                         ; '@'
                swap    d1
                neg.w   d1
                tst.w   d1
                bpl.s   Boss_DestroyerMk2ClearOrbitingPartFlip
                ori.w   #$8000,$E(a0)
                bra.s   Boss_DestroyerMk2StoreOrbitingPartPriority
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ClearOrbitingPartFlip:                 ; was: loc_4BD3A
                andi.w  #$7FFF,$E(a0)
Boss_DestroyerMk2StoreOrbitingPartPriority:             ; was: loc_4BD40
                add.w   d3,d1
                move.b  d1,$20(a0)
Boss_DestroyerMk2AdvanceOrbitingPartLoop:               ; was: loc_4BD46
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2UpdateOrbitingPartLoop
                rts
; End of function Boss_DestroyerMk2UpdateLinkedObjectGeometry
; Select the current object and fall through to frame selection
Boss_DestroyerMk2SelectCurrentObjectForFrame:           ; was: sub_4BD50
                                        ; Object_DestroyerMk2RotateBouncingPartAThenLaunch+E   p
                movea.w a5,a0
; End of function Boss_DestroyerMk2SelectCurrentObjectForFrame
; Selects an orbiting part's mapping and sprite attributes from its angle
Boss_DestroyerMk2SelectOrbitingPartFrame:               ; was: sub_4BD52
                addi.w  #$20,d2                         ; ' '
                andi.w  #$1C0,d2
                lsr.w   #4,d2
                move.l  Boss_DestroyerMk2OrbitingPartMappingTable(pc,d2.w),8(a0)
                lsr.w   #1,d2
                move.w  Boss_DestroyerMk2OrbitingPartSpriteAttributeTable(pc,d2.w),$E(a0)
                rts
; End of function Boss_DestroyerMk2SelectOrbitingPartFrame
; ---------------------------------------------------------------------------
Boss_DestroyerMk2OrbitingPartMappingTable:  dc.l    Boss_DestroyerMk2OrbitingPartMapping0  ; was: off_4BD6C
                dc.l    Boss_DestroyerMk2OrbitingPartMapping1
                dc.l    Boss_DestroyerMk2OrbitingPartMapping2
                dc.l    Boss_DestroyerMk2OrbitingPartMapping1
                dc.l    Boss_DestroyerMk2OrbitingPartMapping0
                dc.l    Boss_DestroyerMk2OrbitingPartMapping3
                dc.l    Boss_DestroyerMk2OrbitingPartMapping4
                dc.l    Boss_DestroyerMk2OrbitingPartMapping3
Boss_DestroyerMk2OrbitingPartSpriteAttributeTable:  dc.w    $6300, $6300, $6300, $6B00, $6300, $6B00, $6300, $6300, $838, 0, $F706, $6728, $838, 5, $F706, $670C  ; was: word_4BD8C

; Activate idle linked records according to the encounter flag byte
Boss_DestroyerMk2ActivateLinkedPartsFromFlags:
                tst.w   (SixthEntityState).w            ; was: sub_4BDAC
                bne.s   Boss_DestroyerMk2CheckConditionalNearPartActivation
                move.w  #2,(SixthEntityState).w
Boss_DestroyerMk2CheckConditionalNearPartActivation:    ; was: loc_4BDB8
                btst    #6,(ControllerHeldState).w
                beq.s   Boss_DestroyerMk2CheckFarPartActivationFlags
                tst.w   (FifthEntityState).w
                bne.s   Boss_DestroyerMk2CheckFarPartActivationFlags
                move.w  #2,(FifthEntityState).w
Boss_DestroyerMk2CheckFarPartActivationFlags:           ; was: loc_4BDCC
                                        ; Boss_DestroyerMk2ActivateLinkedPartsFromFlags+18   j
                btst    #1,(ControllerHeldState).w
                beq.s   Boss_DestroyerMk2LinkedPartFlagActivationReturn
                btst    #5,(ControllerHeldState).w
                beq.s   Boss_DestroyerMk2CheckSecondFarPartActivation
                tst.w   (EighthEntityState).w
                bne.s   Boss_DestroyerMk2CheckSecondFarPartActivation
                move.w  #2,(EighthEntityState).w
Boss_DestroyerMk2CheckSecondFarPartActivation:          ; was: loc_4BDE8
                                        ; Boss_DestroyerMk2ActivateLinkedPartsFromFlags+34   j
                btst    #6,(ControllerHeldState).w
                beq.s   Boss_DestroyerMk2LinkedPartFlagActivationReturn
                tst.w   (SeventhEntityState).w
                bne.s   Boss_DestroyerMk2LinkedPartFlagActivationReturn
                move.w  #2,(SeventhEntityState).w
Boss_DestroyerMk2LinkedPartFlagActivationReturn:        ; was: locret_4BDFC
                                        ; Boss_DestroyerMk2ActivateLinkedPartsFromFlags+42   j
                rts
; End of function Boss_DestroyerMk2ActivateLinkedPartsFromFlags
; Fills 40 foreground-scroll rows with the negated stage scroll position
Gfx_DestroyerMk2UpdateForegroundScrollRows:             ; was: sub_4BDFE
                lea     (HScrollPlaneARow32).w,a0
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                move.w  #$27,d7                         ; '''
Gfx_DestroyerMk2UpdateForegroundScrollRowsLoop:         ; was: loc_4BE0C
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Gfx_DestroyerMk2UpdateForegroundScrollRowsLoop
                rts
; End of function Gfx_DestroyerMk2UpdateForegroundScrollRows
; Update the controller debris effect and emit one randomized sprite particle
Projectile_DestroyerMk2DebrisMain:                      ; was: sub_4BE16
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                move.w  #2,(PlaneBShakeLevel).w
                move.w  #4,(PlaneAShakeLevel).w
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_DestroyerMk2DebrisSpawnReturn
                jsr     (Sprite_InitType160).l
                clr.b   $20(a0)
                move.w  #6,$18(a0)
                move.w  (RandomNumberState+2).w,$1A(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$1F,d0
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$24,d0                         ; '$'
                subi.w  #$24,d1                         ; '$'
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$1C(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #7,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Projectile_DestroyerMk2DebrisMappingTable(pc,d0.w),8(a0)
                ori.w   #$8000,$E(a0)
Projectile_DestroyerMk2DebrisSpawnReturn:               ; was: locret_4BE98
                rts
; End of function Projectile_DestroyerMk2DebrisMain
; ---------------------------------------------------------------------------
Projectile_DestroyerMk2DebrisMappingTable:  dc.l    SharedCombatSpriteAnimation00  ; was: off_4BE9A
                dc.l    SharedCombatSpriteAnimation03
                dc.l    SharedCombatSpriteAnimation01
                dc.l    SharedCombatSpriteAnimation04
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation05
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation06

Object_DestroyerMk2StageGateReturn:                     ; was: nullsub_108
                                        ; Object_DestroyerMk2ActivateFromLinkedState+14   j
                rts
; End of function Object_DestroyerMk2StageGateReturn
