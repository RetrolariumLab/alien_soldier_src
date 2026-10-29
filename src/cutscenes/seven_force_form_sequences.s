; Seven Force Valkirie, Medusa, Sylpheed, and Artemis form states
; State C: fade in the Valkirie palette, then arm its hold timer
Entity_SevenForceValkirieFadeInStateC:                  ; was: sub_54F9E
                subq.w  #1,$48(a5)
                bpl.w   Entity_SevenForceNoOpState
                addq.w  #1,$5E(a5)
                cmpi.w  #$E,$5E(a5)
                bmi.s   Entity_SevenForceValkirieFadeInApplyPalette
                addq.w  #2,4(a5)
                move.w  #$34,$48(a5)                    ; '4'
                clr.w   2(a5)
                move.b  #$96,d0
                jsr     (Sound_QueueBGMRequest).l
                move.b  #$23,d0                         ; '#'
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceValkirieAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
Entity_SevenForceValkirieFadeInApplyPalette:            ; was: loc_54FE0
                bra.w   Gfx_UpdateSevenForceValkiriePaletteFade
; End of function Entity_SevenForceValkirieFadeInStateC
; State E: count down Valkirie hold and fade-out values, then reset
Entity_SevenForceValkirieFadeOutStateE:                 ; was: sub_54FE4
                subq.w  #1,$48(a5)
                bpl.w   Gfx_UpdateSevenForceValkiriePaletteFade
                subq.w  #1,$5E(a5)
                bpl.w   Gfx_UpdateSevenForceValkiriePaletteFade
Entity_SevenForceResetState:                            ; was: loc_54FF4
                                        ; Entity_SevenForceSylpheedFadeOutState20+16   j
                clr.w   4(a5)
                rts
; End of function Entity_SevenForceValkirieFadeOutStateE
; State $10: launch the Medusa entrance trajectory
Entity_SevenForceStartMedusaEntranceState10:            ; was: sub_54FFA
                addq.w  #2,4(a5)
                move.l  #$FFFCC000,$1C(a5)
                move.l  #$12000,$18(a5)
                cmpi.w  #$150,$10(a5)
                bmi.s   Entity_SevenForceUpdateMedusaEntranceState12
                neg.l   $18(a5)
; State $12: apply gravity until Medusa reaches the landing threshold
Entity_SevenForceUpdateMedusaEntranceState12:           ; was: loc_5501A
                addi.l  #$2800,$1C(a5)
                bmi.s   Entity_SevenForceUpdateMedusaEntrancePalette
                cmpi.w  #$F0,$14(a5)
                bmi.s   Entity_SevenForceUpdateMedusaEntrancePalette
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceMedusaAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
                move.b  #1,(SceneSequenceFlags).w
Entity_SevenForceUpdateMedusaEntrancePalette:           ; was: loc_55056
                                        ; Entity_SevenForceStartMedusaEntranceState10+30   j
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceStartMedusaEntranceState10
; State $14: hold Medusa, play the timed cue, and update its palette
Entity_SevenForceMedusaHoldState14:                     ; was: sub_5505A
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceMedusaHoldCheckSound
                addq.w  #2,4(a5)
Entity_SevenForceMedusaHoldCheckSound:                  ; was: loc_55064
                cmpi.w  #$38,$48(a5)                    ; '8'
                bne.s   Entity_SevenForceMedusaHoldApplyPalette
                move.b  #$25,d0                         ; '%'
                jsr     (Sound_QueueSFXRequest).l
Entity_SevenForceMedusaHoldApplyPalette:                ; was: loc_55076
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceMedusaHoldState14
; State $16: advance Medusa's fade value on alternate frames, then reset
Entity_SevenForceMedusaFadeOutState16:                  ; was: sub_5507A
                btst    #0,(FrameCounter+1).w
                beq.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                addq.w  #1,$5E(a5)
                beq.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                bmi.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                bra.w   Entity_SevenForceResetState
; End of function Entity_SevenForceMedusaFadeOutState16
; State $18: launch the Sylpheed entrance trajectory
Entity_SevenForceStartSylpheedEntranceState18:          ; was: sub_55094
                move.b  #1,(SceneSequenceFlags).w
                addq.w  #2,4(a5)
                move.l  #$FFFC8000,$1C(a5)
                move.l  #$18000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bmi.s   Entity_SevenForceUpdateSylpheedEntranceState1A
                neg.l   $18(a5)
; State $1A: apply gravity until Sylpheed reaches the landing threshold
Entity_SevenForceUpdateSylpheedEntranceState1A:         ; was: loc_550BA
                addi.l  #$2800,$1C(a5)
                bmi.s   Entity_SevenForceUpdateSylpheedEntrancePalette
                cmpi.w  #$F0,$14(a5)
                bmi.s   Entity_SevenForceUpdateSylpheedEntrancePalette
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$20,$48(a5)                    ; ' '
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceSylpheedAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
Entity_SevenForceUpdateSylpheedEntrancePalette:         ; was: loc_550F0
                                        ; Entity_SevenForceStartSylpheedEntranceState18+36   j
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceStartSylpheedEntranceState18
; State $1C: hold Sylpheed, play the timed cue, and update its palette
Entity_SevenForceSylpheedHoldState1C:                   ; was: sub_550F4
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceSylpheedHoldApplyPalette
                addq.w  #2,4(a5)
                move.b  #$24,d0                         ; '$'
                jsr     (Sound_QueueSFXRequest).l
Entity_SevenForceSylpheedHoldApplyPalette:              ; was: loc_55108
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceSylpheedHoldState1C
; State $1E: wait for the Sylpheed scroll threshold
Entity_SevenForceWaitForSylpheedScrollState1E:          ; was: sub_5510C
                cmpi.w  #$F760,(PrimaryCameraYPosition).w
                bpl.s   Entity_SevenForceWaitForSylpheedScrollApplyPalette
                addq.w  #2,4(a5)
Entity_SevenForceWaitForSylpheedScrollApplyPalette:     ; was: loc_55118
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceWaitForSylpheedScrollState1E
; State $20: advance Sylpheed's fade value on alternate frames, then reset
Entity_SevenForceSylpheedFadeOutState20:                ; was: sub_5511C
                btst    #0,(FrameCounter+1).w
                beq.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                addq.w  #1,$5E(a5)
                beq.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                bmi.w   Gfx_UpdateSevenForceMultiRangePaletteFade
                bra.w   Entity_SevenForceResetState
; End of function Entity_SevenForceSylpheedFadeOutState20
; State $22: configure and launch the Artemis entrance trajectory
Entity_SevenForceStartArtemisEntranceState22:           ; was: sub_55136
                addq.w  #2,4(a5)
                bclr    #0,(PlayerModeFlags).w
                bclr    #4,(PlayerSpriteAttributes).w
                move.w  #$58,(PlayerStateOffset).w      ; 'X'
                clr.l   (PlayerXVelocity).w
                clr.l   (PlayerYVelocity).w
                move.w  #$34,(PlayerScriptStateOffset).w  ; '4'
                bset    #2,(PlayerRestrictionFlags).w
                jsr     (Sys_ClearObjectBlocks17).l
                move.l  #$38000,$1C(a5)
                move.l  #$22000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bmi.s   Entity_SevenForceUpdateArtemisEntranceState24
                neg.l   $18(a5)
; State $24: decelerate Artemis upward until it reaches the height threshold
Entity_SevenForceUpdateArtemisEntranceState24:          ; was: loc_55182
                subi.l  #$1000,(PlayerYVelocity).w
                subi.l  #$2000,$1C(a5)
                bpl.s   Entity_SevenForceUpdateArtemisEntrancePalette
                cmpi.w  #$100,$14(a5)
                bpl.s   Entity_SevenForceUpdateArtemisEntrancePalette
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
                lea     (SevenForceArtemisAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
Entity_SevenForceUpdateArtemisEntrancePalette:          ; was: loc_551BA
                                        ; Entity_SevenForceStartArtemisEntranceState22+64   j
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceStartArtemisEntranceState22
; State $26: wait for the Artemis completion signal and configure its hold
Entity_SevenForceWaitForArtemisSignalState26:           ; was: sub_551BE
                subi.l  #$1000,(PlayerYVelocity).w
                tst.b   (SceneSequenceFlags).w
                bne.s   Entity_SevenForceWaitForArtemisSignalApplyPalette
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #$10,$4A(a5)
                clr.w   (PlayerStateOffset).w
                move.w  #$FF84,(PlayerYPosition).w
                move.w  #$D0,(PlayerXPosition).w
                bset    #0,(PlayerObjectFlags).w
Entity_SevenForceWaitForArtemisSignalApplyPalette:      ; was: loc_551F2
                bra.w   Gfx_UpdateSevenForceMultiRangePaletteFade
; End of function Entity_SevenForceWaitForArtemisSignalState26
; State $28: run Artemis hold timers and fade-out, then reset
Entity_SevenForceArtemisFadeOutState28:                 ; was: sub_551F6
                tst.w   $48(a5)
                bmi.s   Entity_SevenForceArtemisFadeOutUpdateTimer
                subq.w  #1,$48(a5)
                bpl.w   Gfx_UpdateSevenForceArtemisPaletteFade
                move.b  #1,(SceneSequenceFlags).w
                bclr    #2,(PlayerRestrictionFlags).w
Entity_SevenForceArtemisFadeOutUpdateTimer:             ; was: loc_55210
                subq.w  #1,$4A(a5)
                bne.s   Entity_SevenForceArtemisFadeOutApplyPalette
                jsr     (Gfx_QueueArtemisIndexedRows).l
                bra.s   Entity_SevenForceArtemisFadeOutCheckReset
; ---------------------------------------------------------------------------
Entity_SevenForceArtemisFadeOutApplyPalette:            ; was: loc_5521E
                bpl.w   Gfx_UpdateSevenForceArtemisPaletteFade
Entity_SevenForceArtemisFadeOutCheckReset:              ; was: loc_55222
                btst    #0,(FrameCounter+1).w
                beq.w   Gfx_UpdateSevenForceArtemisPaletteFade
                addq.w  #1,$5E(a5)
                beq.w   Gfx_UpdateSevenForceArtemisPaletteFade
                bmi.w   Gfx_UpdateSevenForceArtemisPaletteFade
                bra.w   Entity_SevenForceResetState
; End of function Entity_SevenForceArtemisFadeOutState28
