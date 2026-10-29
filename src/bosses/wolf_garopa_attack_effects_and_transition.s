Effect_InitializeWolfGaropaBoundaryPair:                ; was: sub_50CD4
                                        ; Boss_WolfGaropaLoadAttackEffectB+14   p
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  #$418,(a0)
                clr.w   2(a0)
                move.w  d0,$48(a0)
                clr.w   $4C(a0)
                move.w  d1,$14(a0)
                move.b  #$80,$21(a0)
                move.b  #$90,$23(a0)
                move.w  #4,$24(a0)
                move.w  #$115,$26(a0)
                move.l  #$7EF030,d1
                move.l  #$7EF030,d2
                move.w  #$120,d3
                tst.w   d0
                beq.s   Effect_StoreWolfGaropaBoundaryPairParameters
                move.l  #$8200F030,d1
                move.l  #$8200F030,d2
                move.w  #$B0,d3
Effect_StoreWolfGaropaBoundaryPairParameters:           ; was: loc_50D28
                move.l  d1,$28(a0)
                move.l  d2,$2C(a0)
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  d3,$14(a0)
                jsr     (Pickup_SpawnSmall).l
                move.w  #$420,(a0)
                move.w  #$E000,2(a0)
                move.w  #$28,$1C(a0)                    ; '('
                rts
; End of function Effect_InitializeWolfGaropaBoundaryPair
; Forces player to ceiling during Valkirie encounter by adjusting vertical position and checking proximity to boss position
Effect_WolfGaropaBoundaryMain:                          ; was: sub_50D50
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Effect_RemoveWolfGaropaBoundary
                btst    #4,$22(a5)
                beq.s   Effect_UpdateWolfGaropaBoundaryPosition
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #6,(PlaneAShakeLevel).w
                cmpi.w  #$1F0,(PrimaryCameraXPosition).w
                bpl.w   Effect_RemoveWolfGaropaBoundary
                jsr     (Gfx_LoadWolfGaropaTransitionTiles).l
Effect_RemoveWolfGaropaBoundary:                        ; was: loc_50D7E
                                        ; Effect_WolfGaropaBoundaryMain+24   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Effect_UpdateWolfGaropaBoundaryPosition:                ; was: loc_50D86
                move.w  #$1F0,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  (PlayerYPosition).w,d0
                move.w  (PlayerXPosition).w,d1
                tst.w   $48(a5)
                bne.s   Effect_CheckPlayerBelowWolfGaropaBoundaryBand
                addi.w  #$18,d0
                cmp.w   $14(a5),d0
                bmi.s   Effect_CheckPlayerCrossedWolfGaropaBoundaryX
                cmp.w   $10(a5),d1
                bpl.w   Effect_PushPlayerFromWolfGaropaBoundary
                rts
; ---------------------------------------------------------------------------
Effect_CheckPlayerBelowWolfGaropaBoundaryBand:          ; was: loc_50DB4
                subi.w  #$18,d0
                cmp.w   $14(a5),d0
                bpl.s   Effect_CheckPlayerCrossedWolfGaropaBoundaryX
                cmp.w   $10(a5),d1
                bpl.w   Effect_PushPlayerFromWolfGaropaBoundary
                rts
; ---------------------------------------------------------------------------
Effect_CheckPlayerCrossedWolfGaropaBoundaryX:           ; was: loc_50DC8
                                        ; Effect_WolfGaropaBoundaryMain+6C   j
                cmp.w   $10(a5),d1
                bmi.s   Effect_WolfGaropaBoundaryReturn
                move.w  #1,$4C(a5)
Effect_WolfGaropaBoundaryReturn:                        ; was: locret_50DD4
                                        ; Effect_WolfGaropaBoundaryMain+8A   j
                rts
; ---------------------------------------------------------------------------
Effect_PushPlayerFromWolfGaropaBoundary:                ; was: loc_50DD6
                                        ; Effect_WolfGaropaBoundaryMain+72   j
                tst.w   $4C(a5)
                bne.s   Effect_WolfGaropaBoundaryReturn
                move.w  $10(a5),d0
                subq.w  #2,d0
                move.w  d0,(PlayerXPosition).w
                clr.l   (PlayerXVelocity).w
                move.b  #1,(PlayerDashStopFlag).w
                cmpi.w  #$91,(PlayerXPosition).w
                bpl.s   Effect_WolfGaropaBoundaryReturn
                bset    #6,$21(a5)
                tst.w   (Entity57Type).w
                beq.s   Effect_WolfGaropaBoundaryPushReturn
                bset    #4,(Entity57Flags).w
Effect_WolfGaropaBoundaryPushReturn:                    ; was: locret_50E0A
                rts
; End of function Effect_WolfGaropaBoundaryMain
; Manages timer-based screen positioning during Valkirie boss battle with vertical position updates
Effect_WolfGaropaBoundaryFollowerMain:                  ; was: sub_50E0C
                subq.w  #1,$1C(a5)
                bpl.s   Effect_UpdateWolfGaropaBoundaryFollowerPosition
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Effect_UpdateWolfGaropaBoundaryFollowerPosition:        ; was: loc_50E1A
                tst.w   (Entity60Type).w
                beq.s   Effect_ScrollWolfGaropaBoundaryFollower
                move.w  (Entity60XPos).w,d0
                addi.w  #$30,d0                         ; '0'
                move.w  d0,$10(a5)
                bra.s   Effect_UpdateWolfGaropaBoundaryFollowerSprite
; ---------------------------------------------------------------------------
Effect_ScrollWolfGaropaBoundaryFollower:                ; was: loc_50E2E
                subi.l  #$A8000,$10(a5)
Effect_UpdateWolfGaropaBoundaryFollowerSprite:          ; was: loc_50E36
                jmp     Pickup_Update
; End of function Effect_WolfGaropaBoundaryFollowerMain
; Begin Wolf Garopa's defeat transition and clear its active object flags
Boss_WolfGaropaBeginDefeatTransition:                   ; was: sub_50E3C
                move.w  #$40,6(a5)                      ; '@'
                clr.w   $26(a5)
                bset    #0,(StageTimerPauseFlag).w
                move.w  #8,(StageSpawnCountdown).w
                move.b  #2,(BossColorEffectFlags).w
                jmp     Sprite_ClearObjectFlags
; End of function Boss_WolfGaropaBeginDefeatTransition
; Update Wolf Garopa's defeat fade and periodically emit debris effects
Boss_WolfGaropaUpdateDefeatTransition:                  ; was: sub_50E5E
                tst.w   (BossHealth).w
                beq.s   Boss_WolfGaropaAdvanceDefeatTimer
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaAdvanceDefeatTimer:                      ; was: loc_50E66
                subq.w  #1,6(a5)
                bpl.s   Boss_WolfGaropaUpdateDefeatFade
                move.w  #$10,4(a5)
                clr.w   8(a5)
                move.w  #$60,$11C(a5)                   ; '`'
                move.w  #$FEB0,(SecondaryCameraXPos).w
                move.w  #$3E8,d0
                move.w  #$41C,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                moveq   #$1C,d0
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdateDefeatFade:                        ; was: loc_50E98
                cmpi.w  #$20,6(a5)                      ; ' '
                bpl.s   Boss_WolfGaropaAdvanceDefeatPaletteFade
                addq.w  #1,$26(a5)
                move.w  $26(a5),d0
                cmpi.w  #$1C,d0
                bmi.s   Boss_WolfGaropaClampDefeatFadeStep
                moveq   #$1C,d0
Boss_WolfGaropaClampDefeatFadeStep:                     ; was: loc_50EB0
                jsr     (Gfx_ApplyFullActivePaletteFade).l
                bra.w   Boss_WolfGaropaEmitDefeatDebris
; ---------------------------------------------------------------------------
Boss_WolfGaropaAdvanceDefeatPaletteFade:                ; was: loc_50EBA
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
Boss_WolfGaropaEmitDefeatDebris:                        ; was: loc_50EC0
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_WolfGaropaTrySpawnDefeatDebris
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_WolfGaropaTrySpawnDefeatDebris:                    ; was: loc_50ED4
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_WolfGaropaDefeatTransitionReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_WolfGaropaDefeatTransitionReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.l  #Effect_SpriteAnimation18,8(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Boss_WolfGaropaInitializeDefeatDebris
                move.l  #Effect_SpriteAnimation00,8(a0)
Boss_WolfGaropaInitializeDefeatDebris:                  ; was: loc_50F26
                jsr     (Projectile_InitType88).l
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                subi.w  #8,d0
                move.w  d0,$18(a0)
Boss_WolfGaropaDefeatTransitionReturn:                  ; was: locret_50F3C
                                        ; Boss_WolfGaropaUpdateDefeatTransition+84   j
                rts
; End of function Boss_WolfGaropaUpdateDefeatTransition
; Start the post-defeat delay and player-spawn effect
Boss_WolfGaropaBeginPostDefeatDelay:                    ; was: sub_50F3E
                addq.w  #2,4(a5)
                move.w  #$A0,$11C(a5)
                move.b  #4,(PlaneAScrollModeFlags).w
                jmp     TransitionEffect_SpawnAtOwner
; End of function Boss_WolfGaropaBeginPostDefeatDelay
; Count down the post-defeat delay while reducing the fade amount
Boss_WolfGaropaUpdatePostDefeatDelay:                   ; was: sub_50F54
                cmpi.w  #$80,$11C(a5)
                bne.s   Boss_WolfGaropaTickPostDefeatDelay
                move.b  #1,(SoundFadeOutDelay).w
Boss_WolfGaropaTickPostDefeatDelay:                     ; was: loc_50F62
                subq.w  #1,$11C(a5)
                bpl.s   Boss_WolfGaropaUpdatePostDefeatFade
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdatePostDefeatFade:                    ; was: loc_50F70
                subq.w  #2,$26(a5)
                move.w  $26(a5),d0
                bpl.s   Boss_WolfGaropaApplyPostDefeatFade
                moveq   #0,d0
Boss_WolfGaropaApplyPostDefeatFade:                     ; was: loc_50F7C
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; End of function Boss_WolfGaropaUpdatePostDefeatDelay
; Move the auxiliary orb's palette-pulse value toward zero
Boss_WolfGaropaUpdateOrbPalettePulse:                   ; was: sub_50F82
                move.w  $5FE(a5),d0
                bne.s   Boss_WolfGaropaApproachOrbPalettePulseZero
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaApproachOrbPalettePulseZero:             ; was: loc_50F8A
                bpl.s   Boss_WolfGaropaDecreaseOrbPalettePulse
                addq.w  #1,d0
                bra.s   Boss_WolfGaropaApplyOrbPalettePulse
; ---------------------------------------------------------------------------
Boss_WolfGaropaDecreaseOrbPalettePulse:                 ; was: loc_50F90
                subq.w  #1,d0
Boss_WolfGaropaApplyOrbPalettePulse:                    ; was: loc_50F92
                move.w  d0,$5FE(a5)
                movea.w #(PaletteActiveColor49-M68K_RAM),a0
                moveq   #$D,d5
                move.w  $65C(a5),d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_WolfGaropaUpdateOrbPalettePulse
; State handler for Valkirie boss with palette fade initialization on state transitions
