; Seven Force Sirene and finale states with palette and particle effects
; State $2A: launch the Sirene entrance trajectory
Entity_SevenForceStartSireneEntranceState2A:            ; was: sub_5523C
                addq.w  #2,4(a5)
                move.w  #$34,(PlayerScriptStateOffset).w  ; '4'
                move.l  #$FFFC8000,$1C(a5)
                move.l  #$22000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bmi.s   Entity_SevenForceUpdateSireneEntranceState2C
                neg.l   $18(a5)
; State $2C: apply gravity until Sirene reaches the lower threshold
Entity_SevenForceUpdateSireneEntranceState2C:           ; was: loc_55262
                addi.l  #$2000,$1C(a5)
                bmi.s   Entity_SevenForceUpdateSireneEntrancePalette
                cmpi.w  #$170,$14(a5)
                bmi.s   Entity_SevenForceUpdateSireneEntrancePalette
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$40,$48(a5)                    ; '@'
Entity_SevenForceUpdateSireneEntrancePalette:           ; was: loc_55282
                                        ; Entity_SevenForceStartSireneEntranceState2A+36   j
                bra.w   Gfx_UpdateSevenForceArtemisPaletteFade
; End of function Entity_SevenForceStartSireneEntranceState2A
; State $2E: hold Sirene while advancing its palette counter
Entity_SevenForceSireneHoldState2E:                     ; was: sub_55286
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceSireneHoldUpdatePalette
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                move.b  #$28,d0                         ; '('
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceSireneAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
Entity_SevenForceSireneHoldUpdatePalette:               ; was: loc_552AC
                addq.w  #1,$5E(a5)
                beq.w   Gfx_UpdateSevenForceArtemisPaletteFade
                bmi.w   Gfx_UpdateSevenForceArtemisPaletteFade
                rts
; End of function Entity_SevenForceSireneHoldState2E
; State $30: reset the Seven Force intro controller
Entity_SevenForceResetState30:                          ; was: sub_552BA
                bra.w   Entity_SevenForceResetState
; End of function Entity_SevenForceResetState30
; State $32: apply the first timed Sirene palette and sound event
Entity_SevenForceSirenePaletteEventState32:             ; was: sub_552BE
                cmpi.w  #$9C,(StageStateOffset).w
                bne.s   Entity_SevenForceSirenePaletteEventState32Return
                move.b  #$27,d0                         ; '''
                jsr     (Sound_QueueSFXRequest).l
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceSireneTimedAssetSetA).l,a1
                jsr     (Boss_LoadAssetSet).l
                bra.w   Entity_SevenForceResetState
; ---------------------------------------------------------------------------
Entity_SevenForceSirenePaletteEventState32Return:       ; was: locret_552EA
                rts
; End of function Entity_SevenForceSirenePaletteEventState32
; State $34: apply the second timed Sirene palette and sound event
Entity_SevenForceSirenePaletteEventState34:             ; was: sub_552EC
                cmpi.w  #$A6,(StageStateOffset).w
                bne.s   Entity_SevenForceSirenePaletteEventState34Return
                move.b  #$26,d0                         ; '&'
                jsr     (Sound_QueueSFXRequest).l
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceSireneTimedAssetSetB).l,a1
                jsr     (Boss_LoadAssetSet).l
                bra.w   Entity_SevenForceResetState
; ---------------------------------------------------------------------------
Entity_SevenForceSirenePaletteEventState34Return:       ; was: locret_55318
                rts
; End of function Entity_SevenForceSirenePaletteEventState34
; State $36: run the random explosion sequence and arm its wait state
Entity_SevenForceExplosionSequenceState36:              ; was: sub_5531A
                addq.w  #1,$48(a5)
                cmpi.w  #2,$48(a5)
                bne.s   Entity_SevenForceExplosionSequenceCheckTransition
                move.b  #3,d0
                jsr     (Sound_QueueSFXRequest).l
Entity_SevenForceExplosionSequenceCheckTransition:      ; was: loc_55330
                bsr.w   Gfx_UpdateSevenForceArtemisPaletteFade
                cmpi.w  #$98,(StageStateOffset).w
                bne.s   Entity_SevenForceSpawnRandomExplosion
                addq.w  #2,4(a5)
                move.w  #$200,$48(a5)
                move.b  #1,(SoundFadeOutDelay).w
                move.w  #$C0,(ExplosionSoundDelay).w
Entity_SevenForceSpawnRandomExplosion:                  ; was: loc_55352
                                        ; sub_553CC:Entity_SevenForceExplosionWaitUpdate   p
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Entity_SevenForceSpawnRandomExplosionReturn
                jsr     (Sprite_InitType160).l
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                btst    #0,(RandomNumberState).w
                beq.s   Entity_SevenForceInitRandomExplosionMotion
                move.l  #SharedCombatSpriteAnimation01,8(a0)
Entity_SevenForceInitRandomExplosionMotion:             ; was: loc_5538A
                move.b  #0,$20(a0)
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                asl.w   #1,d0
                addi.l  #$80000,d0
                move.l  d0,$1C(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$FF,d0
                andi.w  #$FF,d1
                subi.w  #$80,d0
                subi.w  #$80,d1
                addi.w  #$120,d0
                addi.w  #$F0,d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Entity_SevenForceSpawnRandomExplosionReturn:            ; was: locret_553CA
                rts
; End of function Entity_SevenForceExplosionSequenceState36
; State $38: keep spawning explosions until the wait timer expires
Entity_SevenForceExplosionWaitState38:                  ; was: sub_553CC
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceExplosionWaitUpdate
                addq.w  #2,4(a5)
                move.b  #1,(SceneSequenceFlags).w
Entity_SevenForceExplosionWaitUpdate:                   ; was: loc_553DC
                bsr.w   Entity_SevenForceSpawnRandomExplosion
                addq.w  #1,$5E(a5)
                beq.w   Gfx_UpdateSevenForceArtemisPaletteFade
                bmi.w   Gfx_UpdateSevenForceArtemisPaletteFade
                rts
; End of function Entity_SevenForceExplosionWaitState38
; State $3A: wait for the final-fade trigger and arm shared transition work
Entity_SevenForceArmFinalFadeState3A:                   ; was: sub_553EE
                cmpi.w  #$A2,(StageStateOffset).w
                bne.s   Entity_SevenForceArmFinalFadeReturn
                addq.w  #2,4(a5)
                clr.w   $5E(a5)
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                move.b  #1,(AlternateTimeBonusSound).w
Entity_SevenForceArmFinalFadeReturn:                    ; was: locret_5540A
                rts
; End of function Entity_SevenForceArmFinalFadeState3A
; State $3C: spawn transition particles while fading the palette
Entity_SevenForceFinalFadeState3C:                      ; was: sub_5540C
                bsr.w   Effect_SpawnSevenForceTransitionParticle
                subq.w  #1,$5E(a5)
                cmpi.w  #$FFF2,$5E(a5)
                bpl.s   Entity_SevenForceApplyFinalFade
                addq.w  #2,4(a5)
                move.w  #$210,$48(a5)
Entity_SevenForceApplyFinalFade:                        ; was: loc_55426
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #$1F,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Entity_SevenForceFinalFadeState3C
; State $3E: spawn transition particles and enter the next stage state
Entity_SevenForceFinishIntroState3E:                    ; was: sub_5543A
                bsr.w   Effect_SpawnSevenForceTransitionParticle
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceFinishIntroReturn
                tst.w   (GameplayExitMode).w
                bne.s   Entity_SevenForceFinishIntroReturn
                move.b  #$93,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                jmp     Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
Entity_SevenForceFinishIntroReturn:                     ; was: locret_5545E
                                        ; Entity_SevenForceFinishIntroState3E+E   j
                rts
; End of function Entity_SevenForceFinishIntroState3E
; Apply Valkirie's single-range intro palette fade
Gfx_UpdateSevenForceValkiriePaletteFade:                ; was: sub_55460
                                        ; Entity_SevenForceValkirieFadeOutStateE+4   j
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #$3F,d5                         ; '?'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  #$EEE,(PaletteActiveColor50).w
                rts
; End of function Gfx_UpdateSevenForceValkiriePaletteFade
; Apply the shared three-range Seven Force palette fade
Gfx_UpdateSevenForceMultiRangePaletteFade:              ; was: sub_5547C
                                        ; sub_5505A:Entity_SevenForceMedusaHoldApplyPalette   j
                movea.w #(PaletteActiveColor16-M68K_RAM),a0
                moveq   #$F,d5
                move.w  $5E(a5),d0
                neg.w   d0
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveColor33-M68K_RAM),a0
                moveq   #$1B,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  #$EEE,(PaletteActiveColor50).w
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveColor01-M68K_RAM),a0
                moveq   #$E,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Gfx_UpdateSevenForceMultiRangePaletteFade
; Apply Artemis's four-range intro palette fade
Gfx_UpdateSevenForceArtemisPaletteFade:                 ; was: sub_554C0
                                        ; sub_551F6:Entity_SevenForceArtemisFadeOutApplyPalette   j
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveColor01-M68K_RAM),a0
                moveq   #$E,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveColor21-M68K_RAM),a0
                moveq   #7,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  $5E(a5),d0
                neg.w   d0
                movea.w #(PaletteActiveColor16-M68K_RAM),a0
                moveq   #4,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.w  #$EEE,(PaletteActiveColor50).w
                move.w  $5E(a5),d0
                movea.w #(PaletteActiveColor33-M68K_RAM),a0
                moveq   #$1B,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Gfx_UpdateSevenForceArtemisPaletteFade
; Initialize the shared form-transition sprite from camera coordinates
Entity_InitSevenForceTransitionSprite:                  ; was: sub_55518
                                        ; Entity_StartSevenForceSylpheedTransition+6   p
                move.b  #$14,$20(a5)
                clr.w   $C(a5)
                move.w  #$CD00,2(a5)
                move.l  #Boss_ValkirieMetaspriteFrame,8(a5)
                move.w  #$6300,$E(a5)
                move.w  (PrimaryEntityXPos).w,$10(a5)
                move.w  (PrimaryEntityYPos).w,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                rts
; End of function Entity_InitSevenForceTransitionSprite
; Spawn a randomized particle during the final Seven Force transition
Effect_SpawnSevenForceTransitionParticle:               ; was: sub_5554C
                                        ; sub_5543A   p
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Effect_SpawnSevenForceTransitionParticleReturn
                move.w  #$188,(a0)
                move.w  #$8400,2(a0)
                move.w  #$10,$48(a0)
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                addq.w  #8,d0
                swap    d0
                asr.l   #2,d0
                move.l  d0,$1C(a0)
                move.l  d0,$18(a0)
                move.b  #$70,$20(a0)                    ; 'p'
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$FF,d0
                andi.w  #$7F,d1
                subi.w  #$80,d0
                addi.w  #$120,d0
                addi.w  #$A0,d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  #$44F4,$E(a0)
                btst    #0,(RandomNumberState).w
                bne.s   Effect_InitSevenForceTransitionParticleMapping
                move.w  #$44F5,$E(a0)
Effect_InitSevenForceTransitionParticleMapping:         ; was: loc_555BA
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
Effect_SpawnSevenForceTransitionParticleReturn:         ; was: locret_555C6
                rts
; End of function Effect_SpawnSevenForceTransitionParticle
