; Launches the boss into the scripted defeat leap
Boss_XiTigerBeginDefeatLeap:                            ; CODE XREF: Boss_XiTigerMain+42   j  ; was: sub_3DEBA
                move.w  #$1C,4(a5)
                move.w  #$30,(ExplosionSoundDelay).w    ; '0'
                move.l  #Boss_XiTigerAirborneBodyMapping,$68(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFFB4000,$1C(a5)
                move.l  #$12000,$18(a5)
                move.w  #$100,$54(a5)
                cmpi.w  #$100,$BC(a5)
                bmi.s   Boss_XiTigerApplyDefeatLeapFacing
                neg.l   $18(a5)
                clr.w   $54(a5)
Boss_XiTigerApplyDefeatLeapFacing:                      ; CODE XREF: Boss_XiTigerBeginDefeatLeap+42   j  ; was: loc_3DF06
                bsr.w   Boss_XiTigerApplyFacingGraphics
                clr.w   $1DC(a5)
                clr.w   $1DE(a5)
; End of function Boss_XiTigerBeginDefeatLeap
; Applies gravity until the scripted defeat leap reaches the floor
Boss_XiTigerDefeatLeapState:                            ; DATA XREF: ROM:0003D8A4   o  ; was: sub_3DF12
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                addi.l  #$4000,$1C(a5)
                bmi.s   Boss_XiTigerUpdateDefeatLeapPose
                move.w  $914(a5),d0
                cmp.w   $23C(a5),d0
                bmi.s   Boss_XiTigerUpdateDefeatLeapPose
                addq.w  #2,4(a5)
                move.w  #$C0,$11C(a5)
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #8,(PlaneBShakeLevel).w
                move.l  #$C000,(StageCameraYVelocity).w
                move.w  #$FFFF,(MidgameVerticalPhase).w
                clr.l   $1C(a5)
                move.w  #$CF20,$4A(a5)
                move.w  $23C(a5),$914(a5)
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_XiTigerUpdateDefeatLeapPose:                       ; CODE XREF: Boss_XiTigerDefeatLeapState+E   j  ; was: loc_3DF6A
                                        ; Boss_XiTigerDefeatLeapState+18   j
                lea     Boss_XiTigerLoopingAirbornePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bsr.w   Boss_XiTigerUpdateSprites
                bra.w   Boss_XiTigerSpawnDefeatParticle
; End of function Boss_XiTigerDefeatLeapState
; Holds the landing pose, decelerates, and emits scripted projectiles
Boss_XiTigerDefeatLandingDelayState:                    ; DATA XREF: ROM:0003D8A6   o  ; was: sub_3DF7C
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$11C(a5)
                bpl.s   Boss_XiTigerDecelerateDefeatLanding
                addq.w  #2,4(a5)
                clr.w   6(a5)
                move.b  #$14,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_XiTigerDecelerateDefeatLanding:                    ; CODE XREF: Boss_XiTigerDefeatLandingDelayState+A   j  ; was: loc_3DF9A
                tst.l   $18(a5)
                beq.s   Boss_XiTigerUpdateDefeatLandingPose
                bpl.s   Boss_XiTigerDeceleratePositiveDefeatVelocity
                addi.l  #$1000,$18(a5)
                bra.s   Boss_XiTigerUpdateDefeatLandingPose
; ---------------------------------------------------------------------------
Boss_XiTigerDeceleratePositiveDefeatVelocity:           ; CODE XREF: Boss_XiTigerDefeatLandingDelayState+24   j  ; was: loc_3DFAC
                subi.l  #$1000,$18(a5)
Boss_XiTigerUpdateDefeatLandingPose:                    ; CODE XREF: Boss_XiTigerDefeatLandingDelayState+22   j  ; was: loc_3DFB4
                                        ; Boss_XiTigerDefeatLandingDelayState+2E   j
                lea     Boss_XiTigerDefeatPoses(pc),a1
                nop
Boss_XiTigerUpdateDefeatPoseAndProjectile:              ; CODE XREF: Boss_XiTigerDefeatFadeState+40   j  ; was: loc_3DFBA
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bsr.w   Boss_XiTigerUpdateSprites
                bra.w   Boss_XiTigerSpawnDefeatParticle
; End of function Boss_XiTigerDefeatLandingDelayState
; Fades the defeated boss for 32 frames before clearing stage objects
Boss_XiTigerDefeatFadeState:                            ; DATA XREF: ROM:0003D8A8   o  ; was: sub_3DFD2
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bsr.w   Boss_ApplyDefeatPaletteFade
                addq.w  #1,6(a5)
                cmpi.w  #$20,6(a5)                      ; ' '
                bmi.s   Boss_XiTigerUpdateDefeatFadePose
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                clr.w   8(a5)
                move.w  #$FEB0,(SecondaryCameraXPos).w
                move.w  #$114,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateDefeatFadePose:                       ; CODE XREF: Boss_XiTigerDefeatFadeState+14   j  ; was: loc_3E00C
                lea     Boss_XiTigerDefeatPoses(pc),a1
                nop
                bra.s   Boss_XiTigerUpdateDefeatPoseAndProjectile
; End of function Boss_XiTigerDefeatFadeState
; Counts down to the player-spawn effect while retaining the defeat-palette fade
Boss_XiTigerDefeatSpawnDelayState:                      ; DATA XREF: ROM:0003D8AA   o  ; was: sub_3E014
                subq.w  #1,$11C(a5)
                bpl.s   Boss_XiTigerApplyDefeatSpawnDelayPaletteFade
                addq.w  #2,4(a5)
                jsr     (TransitionEffect_SpawnAtOwner).l
                addi.w  #$20,$14(a0)                    ; ' '
Boss_XiTigerApplyDefeatSpawnDelayPaletteFade:           ; CODE XREF: Boss_XiTigerDefeatSpawnDelayState+4   j  ; was: loc_3E02A
                bra.w   Boss_ApplyDefeatPaletteFade
; End of function Boss_XiTigerDefeatSpawnDelayState
; Drains the defeat counter before starting the final hide delay
Boss_XiTigerDefeatCounterDrainState:                    ; DATA XREF: ROM:0003D8AC   o  ; was: sub_3E02E
                subq.w  #2,6(a5)
                bne.s   Boss_XiTigerApplyDefeatCounterDrainPaletteFade
                addq.w  #2,4(a5)
                move.w  #$80,$11C(a5)
Boss_XiTigerApplyDefeatCounterDrainPaletteFade:         ; CODE XREF: Boss_XiTigerDefeatCounterDrainState+4   j  ; was: loc_3E03E
                bra.w   Boss_ApplyDefeatPaletteFade
; End of function Boss_XiTigerDefeatCounterDrainState
; Hides the boss after the final defeat delay
Boss_XiTigerDefeatHideDelayState:                       ; DATA XREF: ROM:0003D8AE   o  ; was: sub_3E042
                subq.w  #1,$11C(a5)
                bpl.s   Boss_XiTigerDefeatHideDelayReturn
                bset    #4,2(a5)
Boss_XiTigerDefeatHideDelayReturn:                      ; CODE XREF: Boss_XiTigerDefeatHideDelayState+4   j  ; was: locret_3E04E
                rts
; End of function Boss_XiTigerDefeatHideDelayState
; Updates boss sprite rendering
Boss_XiTigerUpdateSprites:                              ; CODE XREF: Boss_XiTigerFallingLanding+6A   j  ; was: sub_3E050
                                        ; Boss_XiTigerBattleStart+30   j
                moveq   #$17,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                bsr.w   Boss_XiTigerPublishScreenPosition
                bsr.w   Boss_XiTigerUpdateClaws
                rts
; End of function Boss_XiTigerUpdateSprites
; Sets Xi-Tiger boss facing direction based on player position
Boss_XiTigerSetFacingDirection:                         ; CODE XREF: Boss_XiTigerEnterIdleState+9A   j  ; was: sub_3E062
                                        ; Boss_XiTigerEnterIdleState+DC   p
                clr.w   $54(a5)
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_XiTigerApplyFacingGraphics
                move.w  #$100,$54(a5)
; End of function Boss_XiTigerSetFacingDirection
; Applies the current facing to the body and claw-part flip bits
Boss_XiTigerApplyFacingGraphics:                        ; CODE XREF: Boss_XiTigerSetup+BC   p  ; was: sub_3E076
                                        ; Boss_XiTigerBeginDefeatLeap:Boss_XiTigerApplyDefeatLeapFacing   p
                moveq   #3,d5
                tst.w   $54(a5)
                beq.s   Boss_XiTigerApplyZeroFacingGraphics
                bset    d5,$6E(a5)
                bset    d5,$2AE(a5)
                bset    d5,$5AE(a5)
                bclr    d5,$CE(a5)
                bclr    d5,$7EE(a5)
                rts
; ---------------------------------------------------------------------------
Boss_XiTigerApplyZeroFacingGraphics:                    ; CODE XREF: Boss_XiTigerApplyFacingGraphics+6   j  ; was: loc_3E094
                bclr    d5,$6E(a5)
                bclr    d5,$2AE(a5)
                bclr    d5,$5AE(a5)
                bset    d5,$CE(a5)
                bset    d5,$7EE(a5)
                rts
; End of function Boss_XiTigerApplyFacingGraphics
; Selects one of two body anchors from the relative claw-part heights
Boss_XiTigerSelectBodyAnchorByClawHeight:
                move.w  $6D4(a5),d0                     ; was: sub_3E0AA
                cmp.w   $914(a5),d0
                bpl.s   Boss_XiTigerSelectPrimaryBodyAnchor
                move.w  #$CF20,$48(a5)
                move.w  #$CF20,$4A(a5)
                move.w  $23C(a5),$914(a5)
                rts
; ---------------------------------------------------------------------------
Boss_XiTigerSelectPrimaryBodyAnchor:                    ; CODE XREF: Boss_XiTigerSelectBodyAnchorByClawHeight+8   j  ; was: loc_3E0C8
                move.w  #$CCE0,$48(a5)
                move.w  #$CCE0,$4A(a5)
                move.w  $23C(a5),$6D4(a5)
                rts
; End of function Boss_XiTigerSelectBodyAnchorByClawHeight
; Selects one of two body mappings from the global frame bit
Boss_XiTigerSelectBodyMapping:                          ; CODE XREF: Boss_XiTigerCloseRangeAttackState+68   p  ; was: sub_3E0DC
                move.l  #Boss_XiTigerGroundedBodyMapping,$68(a5)
                btst    #3,(FrameCounter+1).w
                bne.s   Boss_XiTigerSelectBodyMappingReturn
                move.l  #Boss_XiTigerAirborneBodyMapping,$68(a5)
Boss_XiTigerSelectBodyMappingReturn:                    ; CODE XREF: Boss_XiTigerSelectBodyMapping+E   j  ; was: locret_3E0F4
                rts
; End of function Boss_XiTigerSelectBodyMapping
; Updates claw sprites based on state
Boss_XiTigerUpdateClaws:                                ; CODE XREF: Boss_XiTigerUpdateSprites+C   p  ; was: sub_3E0F6
                movea.w #(SeventhEntityType-M68K_RAM),a0
                move.w  #$CA80,$E(a0)
                move.w  #0,d1
                tst.w   $1DE(a5)
                beq.s   Boss_XiTigerConfigureSecondClaw
                move.w  #$C280,$E(a0)
                move.w  #$10,d1
Boss_XiTigerConfigureSecondClaw:                        ; CODE XREF: Boss_XiTigerUpdateClaws+12   j  ; was: loc_3E114
                bsr.s   Boss_XiTigerUpdateClawMapping
                movea.w #(TwelfthEntityType-M68K_RAM),a0
                move.w  #$C280,$E(a0)
                move.w  #$10,d1
                tst.w   $1DC(a5)
                beq.s   Boss_XiTigerUpdateClawMapping
                move.w  #$CA80,$E(a0)
                move.w  #0,d1
; End of function Boss_XiTigerUpdateClaws
; Applies angle and facing flips, then selects the claw mapping
Boss_XiTigerUpdateClawMapping:                          ; CODE XREF: Boss_XiTigerUpdateClaws:Boss_XiTigerConfigureSecondClaw   p  ; was: sub_3E134
                                        ; Boss_XiTigerUpdateClaws+32   j
                move.w  $56(a0),d0
                add.w   $56(a5),d0
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1FE,d0
                cmpi.w  #$100,d0
                bmi.s   Boss_XiTigerApplyClawFacingFlip
                eori.w  #$1800,$E(a0)
Boss_XiTigerApplyClawFacingFlip:                        ; CODE XREF: Boss_XiTigerUpdateClawMapping+14   j  ; was: loc_3E150
                tst.w   $54(a5)
                beq.s   Boss_XiTigerSelectClawMapping
                eori.w  #$800,$E(a0)
Boss_XiTigerSelectClawMapping:                          ; CODE XREF: Boss_XiTigerUpdateClawMapping+20   j  ; was: loc_3E15C
                asr.w   #4,d0
                andi.w  #$C,d0
                add.w   d1,d0
                move.l  Boss_XiTigerClawMappings(pc,d0.w),8(a0)
                rts
; End of function Boss_XiTigerUpdateClawMapping
; ---------------------------------------------------------------------------
Boss_XiTigerClawMappings:   dc.l    Boss_XiTigerClawMappingA  ; DATA XREF: Boss_XiTigerUpdateClawMapping+30   r  ; was: off_3E16C
                dc.l    Boss_XiTigerClawMappingB
                dc.l    Boss_XiTigerClawMappingC
                dc.l    Boss_XiTigerClawMappingD
                dc.l    Boss_XiTigerClawMappingE
                dc.l    Boss_XiTigerClawMappingD
                dc.l    Boss_XiTigerClawMappingC
                dc.l    Boss_XiTigerClawMappingB

; Publishes the boss position as the shared secondary screen position
Boss_XiTigerPublishScreenPosition:                      ; CODE XREF: Boss_XiTigerUpdateSprites+8   p  ; was: sub_3E18C
                move.w  #$C0,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$50,d0                         ; 'P'
                move.w  d0,(SecondaryCameraYPos).w
                jmp     Boss_ClampSharedScreenPosition
; End of function Boss_XiTigerPublishScreenPosition
; Applies the current boss defeat counter to the shared palette buffer
Boss_ApplyDefeatPaletteFade:                            ; CODE XREF: Boss_ShellshogunDefeatLaunchState+C   p  ; was: sub_3E1AA
                                        ; Boss_ShellshogunDefeatPaletteState:Boss_ShellshogunApplyDefeatPaletteFade   j
                move.w  6(a5),d0
                asr.w   #1,d0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #$3F,d5                         ; '?'
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_ApplyDefeatPaletteFade
; Spawns a randomized particle during the scripted defeat sequence
Boss_XiTigerSpawnDefeatParticle:                        ; CODE XREF: Boss_XiTigerDefeatLeapState+66   j  ; was: sub_3E1C0
                                        ; Boss_XiTigerDefeatLandingDelayState+52   j
                jsr     (Projectile_PrepareImpactSpawnAfterDelay).l
                bne.s   Boss_XiTigerSpawnDefeatParticleReturn
                movea.l #Projectile_SpawnSpriteFrames,a1  ; make offsets?
                jsr     (Sprite_InitTypeA4FromTable).l
                move.b  #0,$20(a0)
                move.w  #$FFFD,$1C(a0)
                move.w  (RandomNumberState+2).w,$1E(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d0                         ; ' '
                subi.w  #$10,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
Boss_XiTigerSpawnDefeatParticleReturn:                  ; CODE XREF: Boss_XiTigerSpawnDefeatParticle+6   j  ; was: locret_3E21A
                rts
; End of function Boss_XiTigerSpawnDefeatParticle
