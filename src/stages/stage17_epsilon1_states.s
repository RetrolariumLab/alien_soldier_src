Stage17_InitializeEpsilon1Transition:                   ; was: sub_E11C
                tst.w   (GameplayExitMode).w
                bne.s   Stage17_InitializeEpsilon1Transition_Return
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                jsr     (Stage_StartInterstageTransition).l
                move.w  #$8002,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.b  #$80,(GameplayControlFlags).w
                move.b  #$8B,(PendingStageBGMRequest).w
Stage17_InitializeEpsilon1Transition_Return:            ; was: locret_E14C
                rts
; End of function Stage17_InitializeEpsilon1Transition

; Unreferenced controller-driven update of one indexed palette word
UnreferencedUpdateIndexedPaletteWord:
                btst    #0,(ControllerHeldState).w      ; was: sub_E14E
                beq.s   UnreferencedUpdateIndexedPaletteWord_CheckDecrease
                addq.w  #2,(PaletteTestSelector).w
UnreferencedUpdateIndexedPaletteWord_CheckDecrease:     ; was: loc_E15A
                btst    #1,(ControllerHeldState).w
                beq.s   UnreferencedUpdateIndexedPaletteWord_Select
                subq.w  #2,(PaletteTestSelector).w
UnreferencedUpdateIndexedPaletteWord_Select:            ; was: loc_E166
                move.w  (PaletteTestSelector).w,d0
                move.w  d0,d1
                asr.w   #2,d0
                andi.w  #$1E,d0
                beq.s   UnreferencedUpdateIndexedPaletteWord_Return
                addi.w  #-$1CE0,d0
                movea.w d0,a0
                andi.w  #6,d1
                move.w  UnreferencedIndexedPaletteWords(pc,d1.w),(a0)
UnreferencedUpdateIndexedPaletteWord_Return:            ; was: locret_E182
                rts
; End of function UnreferencedUpdateIndexedPaletteWord
; ---------------------------------------------------------------------------
UnreferencedIndexedPaletteWords:    dc.w    $200, $400, $622, $844, $5478, $A950  ; was: word_E184

; Unreferenced type-$308 transition-object and Stage 17 parallax updater
UnreferencedCreateType308AndUpdateStage17Parallax:
                move.w  #$2E,(PlayerScriptStateOffset).w  ; '.'  ; was: sub_E190
                move.w  #$20,(Epsilon1TransitionY).w    ; ' '
                move.w  #$308,(SecondaryEntityType).w
                clr.w   (SecondaryEntityState).w
                bsr.w   Stage17_UpdateEpsilon1Parallax
                tst.w   (SecondaryEntityType).w
                bne.s   UnreferencedCreateType308AndUpdateStage17Parallax_Return
                addq.w  #2,(StageStateOffset).w
                clr.w   (PlayerScriptStateOffset).w
                bclr    #0,(SceneSequenceFlags).w
UnreferencedCreateType308AndUpdateStage17Parallax_Return:  ; was: locret_E1BE
                rts
; End of function UnreferencedCreateType308AndUpdateStage17Parallax

; Update the Stage 17 pre-Epsilon-1 transition and its parallax
Stage17_UpdatePreEpsilon1Transition:                    ; was: sub_E1C0
                                        ; ROM:0000D9CA   o
                move.w  #$18,(Epsilon1TransitionY).w
                bsr.w   Stage17_UpdateEpsilon1Parallax
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage17_UpdatePreEpsilon1Transition_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage17_UpdatePreEpsilon1Transition_Return:             ; was: locret_E1D4
                rts
; End of function Stage17_UpdatePreEpsilon1Transition

; Submit Epsilon 1's assets and enter the encounter state
Stage17_InitializeEpsilon1Encounter:                    ; was: sub_E1D6
                bsr.w   Stage17_UpdateEpsilon1Parallax
                addq.w  #2,(StageStateOffset).w
                lea     (Boss_Epsilon1AssetSet).l,a1
                bra.w   Boss_LoadAssetSet
; End of function Stage17_InitializeEpsilon1Encounter

; Wait for Epsilon 1 to clear, then enter the planet-transition state
Stage17_UpdateEpsilon1Encounter:                        ; was: sub_E1E8
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage17_UpdateEpsilon1Parallax
                addq.w  #2,(StageStateOffset).w
; End of function Stage17_UpdateEpsilon1Encounter

; Update Stage 17's vertical position and eight parallax rows
Stage17_UpdateEpsilon1Parallax:                         ; was: sub_E1F2
                                        ; Stage17_UpdatePreEpsilon1Transition+6   p
                btst    #0,(SceneSequenceFlags).w
                beq.s   Stage17_UpdateEpsilon1Parallax_Active
                rts
; ---------------------------------------------------------------------------
Stage17_UpdateEpsilon1Parallax_Active:                  ; was: loc_E1FC
                move.w  (Epsilon1TransitionY).w,d0
                subi.w  #$28,d0                         ; '('
                neg.w   d0
                move.w  d0,(PrimaryCameraYPosition).w
                move.l  #$FFFEA000,(Epsilon1ParallaxStep).w
                move.l  (Epsilon1ParallaxPos).w,d0
                add.l   (Epsilon1ParallaxStep).w,d0
                move.l  d0,(Epsilon1ParallaxPos).w
                asr.l   #8,d0
                move.l  d0,d1
                muls.w  #4,d0
                muls.w  #3,d1
                asl.l   #8,d0
                asl.l   #8,d1
                swap    d0
                swap    d1
                movea.w #(VScrollPlaneBColumn0-M68K_RAM),a0
                move.w  d0,(a0)
                move.w  d1,4(a0)
                move.w  d1,8(a0)
                move.w  d1,$C(a0)
                move.w  d1,$40(a0)
                move.w  d1,$44(a0)
                move.w  d1,$48(a0)
                move.w  d0,$4C(a0)
                rts
; End of function Stage17_UpdateEpsilon1Parallax

; Start the post-Epsilon-1 planet transition
Stage17_StartPlanetTransition:                          ; was: sub_E256
                tst.w   (GameplayExitMode).w
                bne.w   Stage17_UpdateEpsilon1Parallax
                move.w  #$8002,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.b  #$80,(GameplayControlFlags).w
                bset    #2,(PaletteFadeControlFlags).w
                move.w  #4,(SetupTransitionIndex).w
                move.w  #4,(GameplayExitMode).w
                rts
; End of function Stage17_StartPlanetTransition
