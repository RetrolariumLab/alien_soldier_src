; Update a falling part and emit its periodic particle trail
Projectile_BugmaxScatteredPartFall:                     ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4D3C4
                addi.l  #$1000,$1C(a5)
                tst.w   $5C(a5)
                beq.s   Projectile_BugmaxEmitPeriodicTrailParticle
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxEmitPeriodicTrailParticle:             ; CODE XREF: Boss_BugmaxRiseWithFinalParticles+6   j  ; was: loc_4D3D4
                                        ; Projectile_BugmaxScatteredPartFall+C   j
                move.w  a5,d7
                lsr.w   #4,d7
                add.w   (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Projectile_BugmaxTrailParticleEmissionReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_BugmaxTrailParticleEmissionReturn
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                andi.w  #$7FFF,$E(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                bne.s   Projectile_BugmaxTrailParticleEmissionReturn
                move.b  (RandomNumberState+1).w,d0
                andi.w  #6,d0
                move.w  Projectile_BugmaxTrailSoundSequence(pc,d0.w),d0
                andi.w  #$FF,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_BugmaxTrailParticleEmissionReturn:           ; CODE XREF: Projectile_BugmaxScatteredPartFall+1C   j  ; was: locret_4D43A
                                        ; Projectile_BugmaxScatteredPartFall+24   j
                rts
; End of function Projectile_BugmaxScatteredPartFall
; ---------------------------------------------------------------------------
Projectile_BugmaxTrailSoundSequence:    dc.w    $BB, $BC, $BB, $C1  ; DATA XREF: Projectile_BugmaxScatteredPartFall+68   r  ; was: word_4D43C

; Dispatch the states of a type-$338 hit fragment emitted by an opening linked part
Projectile_BugmaxHitFragmentController:                 ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4D444
                addi.l  #$2000,$1C(a5)
                bsr.w   Projectile_BugmaxCycleFlipMask
                move.w  4(a5),d0
                lea     Projectile_BugmaxHitFragmentStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_BugmaxHitFragmentController
; ---------------------------------------------------------------------------
Projectile_BugmaxHitFragmentStateHandlers:  dc.w    Projectile_BugmaxInitializeHitFragment-*  ; DATA XREF: Projectile_BugmaxHitFragmentController+10   o  ; was: off_4D45C
                dc.w    Projectile_BugmaxUpdateHitFragmentMotion-*
                dc.w    Projectile_BugmaxHitFragmentInactiveState-*

; Initialize the hit fragment's bounce count and optional sprite high bit
Projectile_BugmaxInitializeHitFragment:                 ; DATA XREF: ROM:Projectile_BugmaxHitFragmentStateHandlers   o  ; was: sub_4D462
                move.w  #2,$48(a5)
                addq.w  #2,4(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                beq.s   Projectile_BugmaxHitFragmentInitializationReturn
                ori.w   #$8000,$E(a5)
Projectile_BugmaxHitFragmentInitializationReturn:       ; CODE XREF: Projectile_BugmaxInitializeHitFragment+12   j  ; was: locret_4D47C
                rts
; End of function Projectile_BugmaxInitializeHitFragment
; Update normal bounce motion or the special fragment's collision and floor behavior
Projectile_BugmaxUpdateHitFragmentMotion:               ; DATA XREF: ROM:0004D45E   o  ; was: sub_4D47E
                tst.b   $5F(a5)
                beq.s   Projectile_BugmaxCheckHitFragmentFloor
                bclr    #7,$22(a5)
                bne.s   Projectile_BugmaxHandleSpecialHitFragmentCollision
                bsr.w   Projectile_BugmaxCycleSpecialHitFragmentMapping
Projectile_BugmaxCheckHitFragmentFloor:                 ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+4   j  ; was: loc_4D490
                btst    #7,$1C(a5)
                bne.s   Projectile_BugmaxHitFragmentMotionReturn
                cmpi.w  #$130,$14(a5)
                blt.s   Projectile_BugmaxHitFragmentMotionReturn
                move.w  #$130,$14(a5)
                tst.b   $5F(a5)
                bne.s   Projectile_BugmaxSettleSpecialHitFragmentAtFloor
                move.l  $1C(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_BugmaxHitFragmentMotionReturn
                addq.w  #2,4(a5)
Projectile_BugmaxHitFragmentMotionReturn:               ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+18   j  ; was: locret_4D4CC
                                        ; Projectile_BugmaxUpdateHitFragmentMotion+20   j
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxHandleSpecialHitFragmentCollision:     ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+C   j  ; was: loc_4D4CE
                bclr    #4,$22(a5)
                beq.s   Projectile_BugmaxConvertHitFragmentToParticle
                jmp     Pickup_SpawnSmallFromCurrentObject
; ---------------------------------------------------------------------------
Projectile_BugmaxConvertHitFragmentToParticle:          ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+56   j  ; was: loc_4D4DC
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_BugmaxSettleSpecialHitFragmentAtFloor:       ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+2C   j  ; was: loc_4D4F2
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$32,$26(a5)                    ; '2'
                jmp     Effect_InitSharedExplosionFromCurrent
; End of function Projectile_BugmaxUpdateHitFragmentMotion
; Cycle the special hit fragment among three mapping/tile values
Projectile_BugmaxCycleSpecialHitFragmentMapping:        ; CODE XREF: Projectile_BugmaxUpdateHitFragmentMotion+E   p  ; was: sub_4D506
                tst.b   $5F(a5)
                beq.s   Projectile_BugmaxSpecialHitFragmentMappingReturn
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                beq.s   Projectile_BugmaxSpecialHitFragmentMappingReturn
                cmpi.w  #1,d0
                beq.s   Projectile_BugmaxSelectSpecialHitFragmentMappingA
                cmpi.w  #2,d0
                beq.s   Projectile_BugmaxSelectSpecialHitFragmentMappingB
                move.w  #$C4F7,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxSelectSpecialHitFragmentMappingB:      ; CODE XREF: Projectile_BugmaxCycleSpecialHitFragmentMapping+1A   j  ; was: loc_4D52A
                move.w  #$C4F6,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxSelectSpecialHitFragmentMappingA:      ; CODE XREF: Projectile_BugmaxCycleSpecialHitFragmentMapping+14   j  ; was: loc_4D532
                move.w  #$C4F1,$E(a5)
Projectile_BugmaxSpecialHitFragmentMappingReturn:       ; CODE XREF: Projectile_BugmaxCycleSpecialHitFragmentMapping+4   j  ; was: locret_4D538
                                        ; Projectile_BugmaxCycleSpecialHitFragmentMapping+E   j
                rts
; End of function Projectile_BugmaxCycleSpecialHitFragmentMapping
Projectile_BugmaxHitFragmentInactiveState:              ; DATA XREF: ROM:0004D460   o  ; was: nullsub_109
                rts
; End of function Projectile_BugmaxHitFragmentInactiveState

; Cycle a four-entry XOR mask across the fragment's sprite attribute word
Projectile_BugmaxCycleFlipMask:                         ; CODE XREF: Projectile_BugmaxHitFragmentController+8   p  ; was: sub_4D53C
                                        ; sub_4D608   p
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Projectile_BugmaxFlipMaskCycleReturn
                addq.w  #1,$4A(a5)
                andi.w  #3,$4A(a5)
                move.w  $4A(a5),d0
                add.w   d0,d0
                move.w  Projectile_BugmaxFlipMaskSequence(pc,d0.w),d0
                eor.w   d0,$E(a5)
Projectile_BugmaxFlipMaskCycleReturn:                   ; CODE XREF: Projectile_BugmaxCycleFlipMask+8   j  ; was: locret_4D55E
                rts
; End of function Projectile_BugmaxCycleFlipMask
; ---------------------------------------------------------------------------
Projectile_BugmaxFlipMaskSequence:  dc.w    $1000, $800, $1000, $800  ; was: word_4D560
                                        ; DATA XREF: Projectile_BugmaxCycleFlipMask+1A   r

; Initializes spread projectile with random offset
Projectile_InitBugmaxSpread:                            ; CODE XREF: Boss_BugmaxSpawnSpreadProjectile+10   p  ; was: sub_4D568
                move.w  #$33C,(a0)
                move.w  #$EF80,2(a0)
                move.l  #Projectile_BugmaxSpreadSpriteAnimation,8(a0)
                move.w  $E(a5),$E(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FE02FC04,$2C(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  #$14,$26(a0)
                move.w  #$18,$24(a0)
                move.w  $10(a5),$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$40,d0                         ; '@'
                add.w   d0,$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$FFFF,$1C(a0)
                rts
; End of function Projectile_InitBugmaxSpread
; Apply alternating position jitter and dispatch the type-$33C spread projectile
Projectile_BugmaxSpreadController:                      ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4D5C8
                tst.l   $1C(a5)
                beq.s   Projectile_BugmaxDispatchSpreadState
                move.w  (FrameCounter).w,d0
                andi.w  #1,d0
                beq.s   Projectile_BugmaxApplyPositiveJitterOffset
                subi.w  #$20,$10(a5)                    ; ' '
                subi.w  #$20,$14(a5)                    ; ' '
                bra.s   Projectile_BugmaxDispatchSpreadState
; ---------------------------------------------------------------------------
Projectile_BugmaxApplyPositiveJitterOffset:             ; CODE XREF: Projectile_BugmaxSpreadController+E   j  ; was: loc_4D5E6
                addi.w  #$20,$10(a5)                    ; ' '
                addi.w  #$20,$14(a5)                    ; ' '
Projectile_BugmaxDispatchSpreadState:                   ; CODE XREF: Projectile_BugmaxSpreadController+4   j  ; was: loc_4D5F2
                                        ; Projectile_BugmaxSpreadController+1C   j
                move.w  4(a5),d0
                lea     Projectile_BugmaxSpreadStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_BugmaxSpreadController
; ---------------------------------------------------------------------------
Projectile_BugmaxSpreadStateHandlers:   dc.w    Projectile_BugmaxUpdateSpreadFlight-*  ; DATA XREF: Projectile_BugmaxSpreadController+2E   o  ; was: off_4D5FE
                dc.w    Projectile_BugmaxFadeImpactPalettesOut-*
                dc.w    Projectile_BugmaxHoldImpactPalettes-*
                dc.w    Projectile_BugmaxRestoreImpactPalettes-*
                dc.w    Projectile_BugmaxSpreadInactiveState-*

; Update spread-projectile flight and choose impact fade or particle conversion
Projectile_BugmaxUpdateSpreadFlight:                    ; DATA XREF: ROM:Projectile_BugmaxSpreadStateHandlers   o  ; was: sub_4D608
                bsr.w   Projectile_BugmaxCycleFlipMask
                addi.l  #$800,$1C(a5)
                tst.b   (SharedScratchLong6+3).w
                bne.s   Projectile_BugmaxCheckSpreadTerrainOrFinalTransition
                bclr    #7,$22(a5)
                beq.s   Projectile_BugmaxCheckSpreadTerrainOrFinalTransition
                clr.l   $1C(a5)
                move.w  #$4D80,2(a5)
                move.b  #1,(SharedScratchLong6+3).w
                clr.w   $5C(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_BugmaxSpreadFlightReturn
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                move.w  #$FFFE,$1C(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxCheckSpreadTerrainOrFinalTransition:   ; CODE XREF: Projectile_BugmaxUpdateSpreadFlight+10   j  ; was: loc_4D668
                                        ; Projectile_BugmaxUpdateSpreadFlight+18   j
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                bne.s   Projectile_BugmaxConvertSpreadToParticle
                tst.w   (SharedScratchLong10+2).w
                beq.s   Projectile_BugmaxSpreadFlightReturn
Projectile_BugmaxConvertSpreadToParticle:               ; CODE XREF: Projectile_BugmaxUpdateSpreadFlight+6C   j  ; was: loc_4D67C
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                move.w  #$FFFE,$1C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_BugmaxSpreadFlightReturn:                    ; CODE XREF: Projectile_BugmaxUpdateSpreadFlight+3C   j  ; was: locret_4D690
                                        ; Projectile_BugmaxUpdateSpreadFlight+72   j
                rts
; End of function Projectile_BugmaxUpdateSpreadFlight
; Increase the negative palette level after a spread-projectile contact
Projectile_BugmaxFadeImpactPalettesOut:                 ; DATA XREF: ROM:0004D600   o  ; was: sub_4D692
                bsr.w   Gfx_ApplyBugmaxSpreadImpactPaletteLevel
                subq.w  #2,$5C(a5)
                cmpi.w  #$FFF0,$5C(a5)
                bne.s   Projectile_BugmaxImpactPaletteFadeOutReturn
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Projectile_BugmaxImpactPaletteFadeOutReturn:            ; CODE XREF: Projectile_BugmaxFadeImpactPalettesOut+E   j  ; was: locret_4D6AC
                rts
; End of function Projectile_BugmaxFadeImpactPalettesOut
; Hold both impact-affected palette ranges for $80 frames
Projectile_BugmaxHoldImpactPalettes:                    ; DATA XREF: ROM:0004D602   o  ; was: sub_4D6AE
                bsr.w   Gfx_ApplyBugmaxSpreadImpactPaletteLevel
                subq.w  #1,$48(a5)
                bne.s   Projectile_BugmaxImpactPaletteHoldReturn
                addq.w  #2,4(a5)
Projectile_BugmaxImpactPaletteHoldReturn:               ; CODE XREF: Projectile_BugmaxHoldImpactPalettes+8   j  ; was: locret_4D6BC
                rts
; End of function Projectile_BugmaxHoldImpactPalettes
; Restore the two palette ranges and release the shared impact lock
Projectile_BugmaxRestoreImpactPalettes:                 ; DATA XREF: ROM:0004D604   o  ; was: sub_4D6BE
                bsr.w   Gfx_ApplyBugmaxSpreadImpactPaletteLevel
                move.w  (FrameCounter).w,d7
                andi.w  #$1F,d7
                bne.s   Projectile_BugmaxImpactPaletteRestoreReturn
                addq.w  #2,$5C(a5)
                cmpi.w  #2,$5C(a5)
                bne.s   Projectile_BugmaxImpactPaletteRestoreReturn
                clr.b   (SharedScratchLong6+3).w
                bset    #4,2(a5)
                addq.w  #2,4(a5)
Projectile_BugmaxImpactPaletteRestoreReturn:            ; CODE XREF: Projectile_BugmaxRestoreImpactPalettes+C   j  ; was: locret_4D6E6
                                        ; Projectile_BugmaxRestoreImpactPalettes+18   j
                rts
; End of function Projectile_BugmaxRestoreImpactPalettes
Projectile_BugmaxSpreadInactiveState:                   ; DATA XREF: ROM:0004D606   o  ; was: nullsub_110
                rts
; End of function Projectile_BugmaxSpreadInactiveState

; Apply the spread impact's current fade level to two palette ranges
Gfx_ApplyBugmaxSpreadImpactPaletteLevel:                ; CODE XREF: Projectile_BugmaxFadeImpactPalettesOut   p  ; was: sub_4D6EA
                                        ; sub_4D6AE   p
                move.w  $5C(a5),d0
                move.w  #$1F,d5
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  $5C(a5),d0
                move.w  #$F,d5
                move.w  #$E000,d7
                lea     (PaletteActiveColor48).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Gfx_ApplyBugmaxSpreadImpactPaletteLevel
; Initializes sine wave projectile with angular trajectory
Projectile_InitBugmaxSine:                              ; CODE XREF: Boss_BugmaxSpawnSineProjectile+10   p  ; was: sub_4D718
                move.w  #$340,(a0)
                move.w  #$EF80,2(a0)
                move.l  #Projectile_BugmaxSineSpriteAnimation,8(a0)
                move.w  $E(a5),$E(a0)
                move.b  #$C0,$21(a0)
                move.b  #$80,$23(a0)
                move.l  #$FF01FF01,$2C(a0)
                move.l  #$F408F408,$28(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.w  #$14,$26(a0)
                move.w  #$FF,$24(a0)
                move.w  $10(a5),$10(a0)
                move.b  (RandomNumberState+1).w,d0
                addi.w  #$40,(SharedScratchLong10).w    ; '@'
                move.w  (SharedScratchLong10).w,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a2
                move.w  (a2,d0.w),d0
                ext.l   d0
                asl.l   #1,d0
                move.l  d0,$18(a0)
                move.w  $14(a5),$14(a0)
                move.w  $1C(a5),d0
                add.w   d0,$14(a0)
                rts
; End of function Projectile_InitBugmaxSine
; Dispatch the type-$340 phase-launched projectile and handle terminal collision flags
Projectile_BugmaxSineController:                        ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4D79C
                addi.l  #$2000,$1C(a5)
                tst.w   (SharedScratchLong10+2).w
                bne.w   Projectile_BugmaxExpireSineProjectile
                bclr    #4,$22(a5)
                bne.w   Projectile_BugmaxDropRandomPickupFromSineProjectile
                bclr    #6,$22(a5)
                bne.w   Projectile_BugmaxDropRandomPickupFromSineProjectile
                bclr    #7,$22(a5)
                bne.w   Projectile_BugmaxExpireSineProjectile
                move.w  4(a5),d0
                lea     Projectile_BugmaxSineStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_BugmaxSineController
; ---------------------------------------------------------------------------
Projectile_BugmaxSineStateHandlers: dc.w    Projectile_BugmaxInitializeSineBounceCounter-*  ; DATA XREF: Projectile_BugmaxSineController+32   o  ; was: off_4D7D6
                dc.w    Projectile_BugmaxUpdateSineBounceMotion-*

; Initialize a three-contact counter for the phase-launched bouncing projectile
Projectile_BugmaxInitializeSineBounceCounter:           ; DATA XREF: ROM:Projectile_BugmaxSineStateHandlers   o  ; was: sub_4D7DA
                move.w  #3,$48(a5)
                addq.w  #2,4(a5)
; Check downward terrain contact, reverse vertical velocity, and randomize horizontal velocity
Projectile_BugmaxUpdateSineBounceMotion:                ; DATA XREF: ROM:0004D7D8   o  ; was: loc_4D7E4
                btst    #7,$1C(a5)
                bne.s   Projectile_BugmaxSineBounceMotionReturn
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                beq.s   Projectile_BugmaxSineBounceMotionReturn
                subq.w  #1,$48(a5)
                beq.w   Projectile_BugmaxExpireSineProjectile
                move.l  $1C(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                move.w  d0,$18(a5)
                move.b  #$E3,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_BugmaxSineBounceMotionReturn:                ; CODE XREF: Projectile_BugmaxInitializeSineBounceCounter+10   j  ; was: locret_4D82C
                                        ; Projectile_BugmaxInitializeSineBounceCounter+1E   j
                rts
; ---------------------------------------------------------------------------
Projectile_BugmaxExpireSineProjectile:                  ; CODE XREF: Projectile_BugmaxSineController+C   j  ; was: loc_4D82E
                                        ; Projectile_BugmaxSineController+2A   j
                move.b  #$E4,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$C8,$26(a5)
                move.l  #$FC04F808,$2C(a5)
                jmp     Effect_InitSharedExplosionFromCurrent
; End of function Projectile_BugmaxInitializeSineBounceCounter
; Convert collision-terminated type-$340 projectiles into a random pickup
Projectile_BugmaxDropRandomPickupFromSineProjectile:    ; CODE XREF: Projectile_BugmaxSineController+16   j  ; was: sub_4D854
                                        ; Projectile_BugmaxSineController+20   j
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; End of function Projectile_BugmaxDropRandomPickupFromSineProjectile
Projectile_BugmaxSineInactiveState:                     ; was: nullsub_111
                rts
; End of function Projectile_BugmaxSineInactiveState

; Configure the linked-chain strike object's collision and damage fields
Boss_BugmaxConfigureAimedChainHitbox:                   ; CODE XREF: Boss_BugmaxAnimateAndAimChainStrike+3E   p  ; was: sub_4D85E
                movea.w #(FifteenthEntityType-M68K_RAM),a0
                move.b  #2,$21(a0)
                move.l  #$FC04FC04,$2C(a0)
                clr.b   $22(a0)
                rts
; End of function Boss_BugmaxConfigureAimedChainHitbox
; Consume linked-chain contact state and publish its impact-effect coordinates
Boss_BugmaxHandleAimedChainContactEffect:               ; CODE XREF: Boss_BugmaxExtendAimedChainStrike+4   p  ; was: sub_4D876
                                        ; Boss_BugmaxHoldExtendedChainStrike+4   p
                movea.w #(FifteenthEntityType-M68K_RAM),a0
                tst.w   $5C(a0)
                bne.s   Boss_BugmaxPollAimedChainContactSignal
                bclr    #1,$22(a0)
                beq.s   Boss_BugmaxAimedChainContactReturn
                bset    #1,(ForcedPositionFlags).w
                move.w  #2,$5C(a0)
Boss_BugmaxPollAimedChainContactSignal:                 ; CODE XREF: Boss_BugmaxHandleAimedChainContactEffect+8   j  ; was: loc_4D894
                bclr    #1,(ForcedPositionFlags).w
                bne.s   Boss_BugmaxPublishAimedChainImpactEffect
                clr.w   $5C(a0)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxPublishAimedChainImpactEffect:               ; CODE XREF: Boss_BugmaxHandleAimedChainContactEffect+24   j  ; was: loc_4D8A2
                move.w  #$2BC,(ForcedPositionTimer).w
                bset    #0,(ForcedPositionFlags).w
                bset    #2,(ForcedPositionFlags).w
                move.w  $10(a0),(ForcedPositionX).w
                move.w  $14(a0),(ForcedPositionY).w
Boss_BugmaxAimedChainContactReturn:                     ; CODE XREF: Boss_BugmaxHandleAimedChainContactEffect+10   j  ; was: locret_4D8C0
                rts
; End of function Boss_BugmaxHandleAimedChainContactEffect
; Continue contact handling until the retracting chain reaches the disable threshold
Boss_BugmaxHandleContactOrDisableChainHitbox:           ; CODE XREF: Boss_BugmaxRetractAimedChainStrike+4   p  ; was: sub_4D8C2
                movea.w #(FifteenthEntityType-M68K_RAM),a0
                cmpi.w  #$FFF0,(SharedScratchLong4).w
                bgt.s   Boss_BugmaxHandleAimedChainContactEffect
                clr.b   $21(a0)
                rts
; End of function Boss_BugmaxHandleContactOrDisableChainHitbox
; Poll eight opening objects for hit-fragment flags, then steer the controller
Boss_BugmaxEmitOpeningHitFragmentsAndSteer:             ; CODE XREF: Boss_BugmaxWaitForFirstOpeningScrollThreshold   p  ; was: sub_4D8D4
                                        ; Boss_BugmaxWaitForSecondOpeningScrollThreshold   p
                movem.w a5,-(sp)
                bsr.w   Boss_BugmaxEmitHitFragmentFromCurrentPart
                move.w  #6,d7
                movea.w #(SecondaryEntityType-M68K_RAM),a5
Boss_BugmaxEmitOpeningPartHitFragmentLoop:              ; CODE XREF: Boss_BugmaxEmitOpeningHitFragmentsAndSteer+18   j  ; was: loc_4D8E4
                bsr.w   Boss_BugmaxEmitHitFragmentFromCurrentPart
                lea     $60(a5),a5
                dbf     d7,Boss_BugmaxEmitOpeningPartHitFragmentLoop
                movem.w (sp)+,a5
                bra.w   Boss_BugmaxSteerOpeningControllerToHorizontalTarget
; End of function Boss_BugmaxEmitOpeningHitFragmentsAndSteer
Boss_BugmaxOpeningHitFragmentUnusedStub:                ; was: nullsub_112
                rts
; End of function Boss_BugmaxOpeningHitFragmentUnusedStub

; Consume one linked part's hit flag and emit a normal or special type-$338 fragment
Boss_BugmaxEmitHitFragmentFromCurrentPart:              ; CODE XREF: Boss_BugmaxEmitOpeningHitFragmentsAndSteer+4   p  ; was: sub_4D8FA
                                        ; Boss_BugmaxEmitOpeningHitFragmentsAndSteer:Boss_BugmaxEmitOpeningPartHitFragmentLoop   p
                bclr    #6,$22(a5)
                beq.w   Boss_BugmaxHitFragmentEmissionReturn
                move.w  #4,(PlaneBShakeLevel).w
                btst    #7,(PrimaryEntityXVelocity).w
                beq.s   Boss_BugmaxAcceleratePositiveHitFragmentSpawnOffset
                addi.l  #-$4000,(PrimaryEntityXVelocity).w
                cmpi.l  #$FFFE0000,(PrimaryEntityXVelocity).w
                blt.s   Boss_BugmaxAllocateHitFragment
                move.l  #$FFFE0000,(PrimaryEntityXVelocity).w
                bra.s   Boss_BugmaxAllocateHitFragment
; ---------------------------------------------------------------------------
Boss_BugmaxAcceleratePositiveHitFragmentSpawnOffset:    ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+16   j  ; was: loc_4D92E
                addi.l  #$4000,(PrimaryEntityXVelocity).w
                cmpi.l  #$20000,(PrimaryEntityXVelocity).w
                blt.s   Boss_BugmaxAllocateHitFragment
                move.l  #$20000,(PrimaryEntityXVelocity).w
Boss_BugmaxAllocateHitFragment:                         ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+28   j  ; was: loc_4D948
                                        ; Boss_BugmaxEmitHitFragmentFromCurrentPart+32   j
                lea     (TwentySixthEntityType).w,a0
                jsr     (Projectile_FindFreeSlotForward20).l
                bne.w   Boss_BugmaxHitFragmentEmissionReturn
                move.w  #$338,(a0)
                move.w  (PrimaryEntityXPos).w,$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #8,$20(a0)
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                tst.w   (DifficultyMode).w
                bne.s   Boss_BugmaxSelectHigherSpecialHitFragmentRate
                andi.b  #7,d0
                bne.s   Boss_BugmaxConfigureStandardHitFragment
                bra.s   Boss_BugmaxConfigureSpecialHitFragment
; ---------------------------------------------------------------------------
Boss_BugmaxSelectHigherSpecialHitFragmentRate:          ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+84   j  ; was: loc_4D988
                andi.b  #3,d0
                bne.s   Boss_BugmaxConfigureStandardHitFragment
Boss_BugmaxConfigureSpecialHitFragment:                 ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+8C   j  ; was: loc_4D98E
                move.b  #1,$5F(a0)
                move.w  #$8F80,2(a0)
                move.w  #$44F1,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FE02FE02,$2C(a0)
                move.w  #$14,$26(a0)
                move.w  #2,$24(a0)
                move.l  #$FFFC0000,$1C(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                addq.w  #1,d0
                neg.w   d0
                move.w  d0,$18(a0)
                rts
; ---------------------------------------------------------------------------
; Configure the standard hit-fragment mapping and randomized velocity
Boss_BugmaxConfigureStandardHitFragment:                ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+8A   j  ; was: loc_4D9E0
                                        ; Boss_BugmaxEmitHitFragmentFromCurrentPart+92   j
                move.w  #$CF80,2(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #1,d0
                lsl.w   #2,d0
                move.l  Boss_BugmaxStandardHitFragmentMappings(pc,d0.w),8(a0)
                move.w  $E(a5),$E(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                neg.w   d0
                move.w  d0,$18(a0)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                move.w  d0,$1C(a0)
Boss_BugmaxHitFragmentEmissionReturn:                   ; CODE XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+6   j  ; was: locret_4DA18
                                        ; Boss_BugmaxEmitHitFragmentFromCurrentPart+58   j
                rts
; End of function Boss_BugmaxEmitHitFragmentFromCurrentPart
; ---------------------------------------------------------------------------
Boss_BugmaxStandardHitFragmentMappings: dc.l    Projectile_BugmaxHitFragmentFrame00  ; DATA XREF: Boss_BugmaxEmitHitFragmentFromCurrentPart+F6   r  ; was: off_4DA1A
                dc.l    Projectile_BugmaxHitFragmentFrame01
