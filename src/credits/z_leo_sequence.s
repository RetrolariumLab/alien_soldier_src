Boss_ZLeoMainController:                                ; was: sub_220D0
                tst.w   (SharedScratchLong0).w
                beq.w   Boss_ZLeoMainController_DispatchState
                bsr.w   Boss_ZLeoUpdateScroll
                bsr.w   Boss_ZLeoPlacePlayerAtMarker
Boss_ZLeoMainController_DispatchState:                  ; was: loc_220E0
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_ZLeoStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_ZLeoMainController
; ---------------------------------------------------------------------------
Boss_ZLeoStateHandlers: dc.w    Boss_ZLeoIntroSequence-*  ; was: off_220EC
                dc.w    Boss_ZLeoIntroSequence_ParticleWait-*
                dc.w    Boss_ZLeoWaitMarkerPosition-*
                dc.w    Boss_ZLeoWaitTimer-*
                dc.w    Boss_ZLeoCameraScroll-*
                dc.w    Boss_ZLeoWaitForScrollThreshold-*
                dc.w    Boss_ZLeoConfigureParticleBurst-*
                dc.w    Boss_ZLeoWaitParticleBurst-*
                dc.w    Boss_ZLeoStartReverseScroll-*
                dc.w    Boss_ZLeoWaitForScrollSignChange-*
                dc.w    Boss_ZLeoWaitForMarkerEnd-*
                dc.w    Boss_ZLeoSetParticleMode4-*
                dc.w    Boss_ZLeoWaitParticleMode4-*
                dc.w    Boss_ZLeoStartFinalDelay-*
                dc.w    Boss_ZLeoWaitFinalDelay-*
                dc.w    Boss_ZLeoFadeToEnding-*
                dc.w    Boss_ZLeoPrepareEndingExit-*
                dc.w    Boss_ZLeoWaitEndingExit-*
                dc.w    Boss_ZLeoSequenceIdle-*

; Initializes the Z-Leo ending sequence, camera, and particle emitter
Boss_ZLeoIntroSequence:                                 ; was: sub_22112
                addq.w  #2,(SharedScratchLong0).w
                clr.w   (PlayerInvulnTimer).w
                lea     (Entity_ObjectPool).w,a0
                move.w  #$10,(a0)
                move.w  #$C00,2(a0)
                clr.w   $C(a0)
                move.w  #$40,$10(a0)                    ; '@'
                move.w  #$F0,$14(a0)
                move.w  #1,(SharedScratchLong4).w
                move.w  #$A0,(SharedScratchLong4+2).w
                move.w  #$F0,(SharedScratchLong5).w
                move.w  #$1F,(SharedScratchLong5+2).w
                move.w  #$7F,(SharedScratchLong6).w
                move.w  #7,(SharedScratchLong7).w
                bsr.w   Boss_ZLeoSpawnParticles
                move.w  #$40,(SharedScratchLong0+2).w   ; '@'
; Emits particles while the intro countdown runs; it touches no palette
Boss_ZLeoIntroSequence_ParticleWait:                    ; was: loc_22166
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoIntroSequence_Return
                move.w  #4,(PrimaryEntityXVelocity).w
                addq.w  #2,(SharedScratchLong0).w
                bsr.w   Boss_ZLeoSpawnImpactObject
Boss_ZLeoIntroSequence_Return:                          ; was: locret_2217E
                rts
; End of function Boss_ZLeoIntroSequence
; Waits for the marker object X to reach $1E0 before advancing state
Boss_ZLeoWaitMarkerPosition:                            ; was: sub_22180
                bsr.w   Boss_ZLeoSpawnParticles
                cmpi.w  #$1E0,(PrimaryEntityXPos).w
                bcs.s   Boss_ZLeoWaitMarkerPosition_Return
                clr.w   (PrimaryEntityXVelocity).w
                move.w  #$40,(SharedScratchLong0+2).w   ; '@'
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitMarkerPosition_Return:                     ; was: locret_2219A
                rts
; End of function Boss_ZLeoWaitMarkerPosition
; Emits particles while waiting for the state timer
Boss_ZLeoWaitTimer:                                     ; was: sub_2219C
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoWaitTimer_Return
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitTimer_Return:                              ; was: locret_221AA
                rts
; End of function Boss_ZLeoWaitTimer
; Scrolls camera upward with acceleration until reaching final position
Boss_ZLeoCameraScroll:                                  ; was: sub_221AC
                cmpi.w  #$60,(SharedScratchLong4+2).w   ; '`'
                blt.s   Boss_ZLeoCameraScroll_ConfigureParticles
                move.w  (SharedScratchLong2+2).w,d0
                sub.w   d0,(SharedScratchLong4+2).w
                bsr.w   Boss_ZLeoSpawnParticles
                bra.s   Boss_ZLeoCameraScroll_Accelerate
; ---------------------------------------------------------------------------
Boss_ZLeoCameraScroll_ConfigureParticles:               ; was: loc_221C2
                move.w  #1,(SharedScratchLong4).w
                move.w  #$160,(SharedScratchLong4+2).w
                move.w  #$F0,(SharedScratchLong5).w
                move.w  #$FF,(SharedScratchLong5+2).w
                move.w  #$7F,(SharedScratchLong6).w
                move.w  #7,(SharedScratchLong7).w
                bsr.w   Boss_ZLeoSpawnParticles
Boss_ZLeoCameraScroll_Accelerate:                       ; was: loc_221EA
                addi.l  #$800,(SharedScratchLong2+2).w
                cmpi.l  #$80000,(SharedScratchLong2+2).w
                bne.s   Boss_ZLeoCameraScroll_Return
                bset    #0,(PrimaryEntityFlags).w
                move.l  #$78000,(PrimaryEntityXVelocity).w
                addq.w  #2,(SharedScratchLong0).w
                move.w  #$160,(SharedScratchLong4+2).w
Boss_ZLeoCameraScroll_Return:                           ; was: locret_22214
                rts
; End of function Boss_ZLeoCameraScroll
; Waits for the camera scroll to cross the next threshold
Boss_ZLeoWaitForScrollThreshold:                        ; was: sub_22216
                bsr.w   Boss_ZLeoSpawnParticles
                cmpi.w  #$120,(PrimaryEntityXPos).w
                bgt.s   Boss_ZLeoWaitForScrollThreshold_Return
                move.l  (SharedScratchLong2+2).w,(PrimaryEntityXVelocity).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitForScrollThreshold_Return:                 ; was: locret_2222C
                rts
; End of function Boss_ZLeoWaitForScrollThreshold
; Configures a two-particle burst
Boss_ZLeoConfigureParticleBurst:                        ; was: sub_2222E
                move.w  #2,(SharedScratchLong4).w
                move.w  #$160,(SharedScratchLong4+2).w
                move.w  #$F0,(SharedScratchLong5).w
                move.w  #$FF,(SharedScratchLong5+2).w
                move.w  #$7F,(SharedScratchLong6).w
                move.w  #7,(SharedScratchLong7).w
                bsr.w   Boss_ZLeoSpawnParticles
                addq.w  #2,(SharedScratchLong0).w
                move.w  #$80,(SharedScratchLong0+2).w
                rts
; End of function Boss_ZLeoConfigureParticleBurst
; Emits the configured burst until its timer expires
Boss_ZLeoWaitParticleBurst:                             ; was: sub_22262
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoWaitParticleBurst_Return
                move.w  #$80,(SharedScratchLong0+2).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitParticleBurst_Return:                      ; was: locret_22276
                rts
; End of function Boss_ZLeoWaitParticleBurst
; Starts the reverse camera scroll
Boss_ZLeoStartReverseScroll:                            ; was: sub_22278
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoStartReverseScroll_Return
                bclr    #0,(PrimaryEntityFlags).w
                move.l  #$FFFE0000,(PrimaryEntityXVelocity).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoStartReverseScroll_Return:                     ; was: locret_22294
                rts
; End of function Boss_ZLeoStartReverseScroll
; Waits for the reverse scroll velocity to change sign
Boss_ZLeoWaitForScrollSignChange:                       ; was: sub_22296
                bsr.w   Boss_ZLeoSpawnParticles
                addi.l  #$1000,(PrimaryEntityXVelocity).w
                btst    #7,(PrimaryEntityXVelocity).w
                bne.s   Boss_ZLeoWaitForScrollSignChange_Return
                move.b  #$D5,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitForScrollSignChange_Return:                ; was: locret_222B8
                rts
; End of function Boss_ZLeoWaitForScrollSignChange
; Waits for the marker object to return to X $1E0
Boss_ZLeoWaitForMarkerEnd:                              ; was: sub_222BA
                bsr.w   Boss_ZLeoSpawnParticles
                addi.l  #$1000,(PrimaryEntityXVelocity).w
                cmpi.w  #$1E0,(PrimaryEntityXPos).w
                blt.s   Boss_ZLeoWaitForMarkerEnd_Return
                addq.w  #1,(SharedScratchLong4).w
                addq.w  #2,(SharedScratchLong0).w
                move.w  #$80,(SharedScratchLong0+2).w
Boss_ZLeoWaitForMarkerEnd_Return:                       ; was: locret_222DC
                rts
; End of function Boss_ZLeoWaitForMarkerEnd
; Selects four particles per update after a delay
Boss_ZLeoSetParticleMode4:                              ; was: sub_222DE
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoSetParticleMode4_Return
                move.w  #$80,(SharedScratchLong0+2).w
                move.w  #4,(SharedScratchLong4).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoSetParticleMode4_Return:                       ; was: locret_222F8
                rts
; End of function Boss_ZLeoSetParticleMode4
; Emits four particles per update until the timer expires
Boss_ZLeoWaitParticleMode4:                             ; was: sub_222FA
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoWaitParticleMode4_Return
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitParticleMode4_Return:                      ; was: locret_22308
                rts
; End of function Boss_ZLeoWaitParticleMode4
; Starts the final ending delay
Boss_ZLeoStartFinalDelay:                               ; was: sub_2230A
                bsr.w   Boss_ZLeoSpawnParticles
                move.w  #$40,(SharedScratchLong0+2).w   ; '@'
                addq.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_ZLeoStartFinalDelay
; Waits for the final ending delay
Boss_ZLeoWaitFinalDelay:                                ; was: sub_2231A
                bsr.w   Boss_ZLeoSpawnParticles
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoWaitFinalDelay_Return
                clr.w   (SharedScratchLong0+2).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitFinalDelay_Return:                         ; was: locret_2232C
                rts
; End of function Boss_ZLeoWaitFinalDelay
; Fades the Z-Leo scene and clears its palette buffer
Boss_ZLeoFadeToEnding:                                  ; was: sub_2232E
                move.w  (SharedScratchLong0+2).w,d0
                bsr.w   Credits_ApplyFadeStep
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   Boss_ZLeoFadeToEnding_UpdateParticles
                btst    #1,(VBlankFrameCounter+1).w
                bne.s   Boss_ZLeoFadeToEnding_UpdateParticles
                addq.w  #1,(SharedScratchLong0+2).w
                cmpi.w  #$E,(SharedScratchLong0+2).w
                bls.s   Boss_ZLeoFadeToEnding_Return
                addq.w  #2,(SharedScratchLong0).w
                lea     (PaletteShadowBuffer).w,a0
                move.w  #$1F,d7
                moveq   #0,d0
Boss_ZLeoFadeToEnding_ClearPaletteBufferLoop:           ; was: loc_22360
                move.l  d0,(a0)+
                dbf     d7,Boss_ZLeoFadeToEnding_ClearPaletteBufferLoop
                move.w  #$80,(SharedScratchLong0+2).w
                move.b  #$C1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_ZLeoFadeToEnding_Return:                           ; was: locret_22376
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoFadeToEnding_UpdateParticles:                  ; was: loc_22378
                                        ; Boss_ZLeoFadeToEnding+16   j
                bsr.w   Boss_ZLeoSpawnParticles
                rts
; End of function Boss_ZLeoFadeToEnding
; Prepares the final fade before leaving the Z-Leo sequence
Boss_ZLeoPrepareEndingExit:                             ; was: sub_2237E
                move.w  #$E,d0
                bsr.w   Credits_ApplyFadeStep
                subq.w  #1,(SharedScratchLong0+2).w
                bne.s   Boss_ZLeoPrepareEndingExit_Return
                move.w  #$E,(SharedScratchLong0+2).w
                clr.l   (SharedScratchLong2+2).w
                clr.w   (SharedScratchLong4).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoPrepareEndingExit_Return:                      ; was: locret_2239E
                rts
; End of function Boss_ZLeoPrepareEndingExit
; Finishes the fade and advances to the post-Z-Leo game mode
Boss_ZLeoWaitEndingExit:                                ; was: sub_223A0
                move.w  (SharedScratchLong0+2).w,d0
                bsr.w   Credits_ApplyFadeStep
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   Boss_ZLeoWaitEndingExit_Return
                btst    #1,(VBlankFrameCounter+1).w
                bne.s   Boss_ZLeoWaitEndingExit_Return
                subq.w  #1,(SharedScratchLong0+2).w
                bpl.s   Boss_ZLeoWaitEndingExit_Return
                move.w  #$8C,(GameModeIndex).w
                addq.w  #2,(SharedScratchLong0).w
Boss_ZLeoWaitEndingExit_Return:                         ; was: locret_223C8
                                        ; Boss_ZLeoWaitEndingExit+16   j
                rts
; End of function Boss_ZLeoWaitEndingExit
Boss_ZLeoSequenceIdle:                                  ; was: nullsub_56
                rts
; End of function Boss_ZLeoSequenceIdle

; Applies one indexed fade step to the ending palette
Credits_ApplyFadeStep:                                  ; was: sub_223CC
                                        ; Boss_ZLeoPrepareEndingExit+4   p
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Credits_ApplyFadeStep
; Integrates the Z-Leo scroll velocity
Boss_ZLeoUpdateScroll:                                  ; was: sub_223E2
                move.l  (SharedScratchLong2+2).w,d0
                add.l   d0,(PrimaryCameraXPosition).w
                rts
; End of function Boss_ZLeoUpdateScroll
; Unreachable: would nudge the player four pixels per frame from the D-pad
Orphaned_ZLeoMovePlayerByInput:
                btst    #2,(ControllerHeldState).w      ; was: sub_223EC
                beq.s   Orphaned_ZLeoMovePlayerByInput_CheckRight
                subq.w  #4,(PlayerXPosition).w
Orphaned_ZLeoMovePlayerByInput_CheckRight:              ; was: loc_223F8
                btst    #3,(ControllerHeldState).w
                beq.s   Orphaned_ZLeoMovePlayerByInput_CheckUp
                addq.w  #4,(PlayerXPosition).w
Orphaned_ZLeoMovePlayerByInput_CheckUp:                 ; was: loc_22404
                btst    #0,(ControllerHeldState).w
                beq.s   Orphaned_ZLeoMovePlayerByInput_CheckDown
                subq.w  #4,(PlayerYPosition).w
Orphaned_ZLeoMovePlayerByInput_CheckDown:               ; was: loc_22410
                btst    #1,(ControllerHeldState).w
                beq.s   Orphaned_ZLeoMovePlayerByInput_Return
                addq.w  #4,(PlayerYPosition).w
Orphaned_ZLeoMovePlayerByInput_Return:                  ; was: locret_2241C
                rts
; End of function Orphaned_ZLeoMovePlayerByInput
; Unreachable: would drive the player position around a sine orbit
Orphaned_ZLeoOrbitPlayerPosition:
                lea     (Math_SineTable).l,a4           ; was: sub_2241E
                addi.w  #4,(SharedScratchLong1).w
                addi.w  #2,(SharedScratchLong1+2).w
                move.w  (SharedScratchLong1).w,d0
                addi.w  #$1FE,d0
                move.w  (a4,d0.w),d0
                muls.w  #$40,d0                         ; '@'
                addi.l  #$1200000,d0
                move.l  d0,(PlayerXPosition).w
                move.w  (SharedScratchLong1+2).w,d0
                addi.w  #$1FE,d0
                move.w  (a4,d0.w),d0
                muls.w  #$20,d0                         ; ' '
                addi.l  #$F00000,d0
                move.l  d0,(PlayerYPosition).w
                rts
; End of function Orphaned_ZLeoOrbitPlayerPosition
; Shows the player at the marker while the marker stays between X $80 and $1C0
Boss_ZLeoPlacePlayerAtMarker:                           ; was: sub_22466
                cmpi.w  #$80,(PrimaryEntityXPos).w
                blt.s   Boss_ZLeoPlacePlayerAtMarker_HideAndPark
                cmpi.w  #$1C0,(PrimaryEntityXPos).w
                bgt.s   Boss_ZLeoPlacePlayerAtMarker_HideAndPark
                bset    #7,(PlayerObjectFlags).w
                move.l  (PrimaryEntityXPos).w,(PlayerXPosition).w
                move.l  (PrimaryEntityYPos).w,(PlayerYPosition).w
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoPlacePlayerAtMarker_HideAndPark:               ; was: loc_2248A
                                        ; Boss_ZLeoPlacePlayerAtMarker+E   j
                move.l  #$60,(PlayerXPosition).w        ; '`'
                bclr    #7,(PlayerObjectFlags).w
                rts
; End of function Boss_ZLeoPlacePlayerAtMarker
; Spawns randomized Z-Leo ending particles and their periodic sound
Boss_ZLeoSpawnParticles:                                ; was: sub_2249A
                                        ; sub_22112:loc_22166   p
                move.w  (SharedScratchLong4).w,d7
                subq.w  #1,d7
                bmi.w   Boss_ZLeoSpawnParticles_Return
Boss_ZLeoSpawnParticles_Loop:                           ; was: loc_224A4
                jsr     (RandomNumber).l
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_ZLeoSpawnParticles_Return
                jsr     (Sprite_InitType160).l
                move.b  #$60,$20(a0)                    ; '`'
                move.b  (RandomNumberState+2).w,d6
                andi.w  #3,d6
                add.w   d6,d6
                move.b  (RandomNumberState).w,d0
                move.w  (SharedScratchLong5+2).w,d1
                and.w   d1,d0
                and.w   d1,d0
                addq.w  #1,d1
                lsr.w   #1,d1
                sub.w   d1,d0
                add.w   (SharedScratchLong4+2).w,d0
                add.w   Boss_ZLeoParticleXOffsets(pc,d6.w),d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                move.w  (SharedScratchLong6).w,d1
                and.w   d1,d0
                addq.w  #1,d1
                lsr.w   #1,d1
                sub.w   d1,d0
                add.w   (SharedScratchLong5).w,d0
                add.w   Boss_ZLeoParticleYOffsets(pc,d6.w),d0
                move.w  d0,$14(a0)
                move.l  (SharedScratchLong2+2).w,d0
                asr.l   #1,d0
                move.l  d0,$18(a0)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #7,d0
                lsl.w   #2,d0
                move.l  Boss_ZLeoParticleSpritePointers(pc,d0.w),8(a0)
                dbf     d7,Boss_ZLeoSpawnParticles_Loop
                tst.w   (SharedScratchLong7).w
                beq.s   Boss_ZLeoSpawnParticles_Return
                move.w  (RandomNumberState).w,d0
                and.w   (SharedScratchLong7).w,d0
                bne.s   Boss_ZLeoSpawnParticles_Return
                cmpi.w  #$18,(SharedScratchLong0).w
                bcc.s   Boss_ZLeoSpawnParticles_SelectFinalSfx
                move.b  #$30,d0                         ; '0'
                bra.s   Boss_ZLeoSpawnParticles_PlaySfx
; ---------------------------------------------------------------------------
Boss_ZLeoSpawnParticles_SelectFinalSfx:                 ; was: loc_22540
                move.b  #$2F,d0                         ; '/'
Boss_ZLeoSpawnParticles_PlaySfx:                        ; was: loc_22544
                jsr     (Sound_QueueSFXRequest).l
Boss_ZLeoSpawnParticles_Return:                         ; was: locret_2254A
                                        ; Boss_ZLeoSpawnParticles+16   j
                rts
; End of function Boss_ZLeoSpawnParticles
; ---------------------------------------------------------------------------
Boss_ZLeoParticleXOffsets:          dc.w    $20, 0, $FFE0, 0  ; was: word_2254C
Boss_ZLeoParticleYOffsets:          dc.w    0, $A, $FFF0, 0  ; was: word_22554
Boss_ZLeoParticleSpritePointers:    dc.l    SharedCombatSpriteAnimation00  ; was: off_2255C
                dc.l    SharedCombatSpriteAnimation01
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation03
                dc.l    SharedCombatSpriteAnimation03
                dc.l    SharedCombatSpriteAnimation05
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation00

; Spawns the impact object that starts the Z-Leo ending transition
Boss_ZLeoSpawnImpactObject:                             ; was: sub_2257C
                lea     (PlayerObjectType).w,a5
                move.b  #$41,d0                         ; 'A'
                jsr     (Sound_QueueSFXRequest).l
                movea.w #(PlayerSpecialObjectSlot-M68K_RAM),a0
                move.w  #$230,(a0)
                move.b  #$54,$21(a0)                    ; 'T'
                move.w  #$4000,2(a0)
                move.l  #Player_TeleportDashProjectileSpriteMapping,8(a0)
                move.w  $E(a5),d0
                andi.w  #$FFFF,d0
                move.w  d0,$E(a0)
                eori.w  #$1000,$E(a0)
                move.b  $20(a5),$20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                rts
; End of function Boss_ZLeoSpawnImpactObject
; ---------------------------------------------------------------------------
Credits_UnidentifiedTrailingData:   binclude "data/other/unused_5.bin"  ; was: unused_5
Credits_UnidentifiedTrailingData_End:                   ; was: unused_5_End

; Demo playback system with input recording and VDP state management
