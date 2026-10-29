; Antroid charge, ram, and defeat states

; Initializes ram-attack state $1E and selects its horizontal direction
Boss_AntroidBeginRamAttack:                             ; was: sub_37D3A
                move.w  #$1E,4(a5)
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #1,$11C(a5)
                clr.w   $56(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$FFFE0000,$1C(a5)
                move.l  #$20000,$18(a5)
                move.w  #$100,$54(a5)
                cmpi.w  #$CC0,$BC(a5)
                bmi.w   Boss_AntroidBeginRamAttackUpdateFacing
                neg.l   $18(a5)
                clr.w   $54(a5)
Boss_AntroidBeginRamAttackUpdateFacing:                 ; was: loc_37D96
                bsr.w   Boss_AntroidFacePlayer
; End of function Boss_AntroidBeginRamAttack
; Boss ram attack with collision
Boss_AntroidRamAttack:                                  ; was: sub_37D9A
                cmpi.w  #$180,$56(a5)
                beq.s   Boss_AntroidRamAttackUpdate
                subq.w  #8,$56(a5)
                andi.w  #$1FE,$56(a5)
Boss_AntroidRamAttackUpdate:                            ; was: loc_37DAC
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bsr.w   Boss_AntroidUpdateRamAttackPose
                addi.l  #$4000,$1C(a5)
                bmi.s   Boss_AntroidRamAttackReturn
                cmpi.w  #$148,$14(a5)
                bmi.w   Boss_AntroidRamAttackReturn
                move.w  #5,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                subq.w  #1,$11C(a5)
                bpl.w   Boss_AntroidRamAttackRebound
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$148,$14(a5)
Boss_AntroidRamAttackReturn:                            ; was: locret_37DF4
                                        ; Boss_AntroidRamAttack+2C   j
                rts
; ---------------------------------------------------------------------------
Boss_AntroidRamAttackRebound:                           ; was: loc_37DF6
                move.l  #$FFFE0000,$1C(a5)
                rts
; End of function Boss_AntroidRamAttack
; Advances Antroid's defeat fade before entering the final delay state
Boss_AntroidDefeatFadeState:                            ; was: sub_37E00
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                addq.w  #1,$11C(a5)
                move.w  $11C(a5),d0
                cmpi.w  #$A0,d0
                bpl.s   Boss_AntroidEnterDefeatDelayState
                subi.w  #$90,d0
                bmi.s   Boss_AntroidDefeatFadeUpdateEffects
                bsr.w   Boss_AntroidApplyDefeatPaletteFade
Boss_AntroidDefeatFadeUpdateEffects:                    ; was: loc_37E1E
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
; End of function Boss_AntroidDefeatFadeState
; Updates the ram-attack pose, debris, and alternating sprite flip
Boss_AntroidUpdateRamAttackPose:                        ; was: sub_37E2A
                bsr.w   Boss_AntroidSpawnRamDebris
                lea     Boss_AntroidRamPoses(pc),a1
                nop
                jsr     Boss_AntroidUpdatePoseAnimation(pc)  ; (pc)
                nop
                bsr.w   Boss_AntroidRenderPose
                move.l  #Boss_AntroidBlinkAlternateMapping,$C8(a5)
                bset    #4,$CE(a5)
                eori.w  #$800,$CE(a5)
                rts
; End of function Boss_AntroidUpdateRamAttackPose
; Enters Antroid's final defeat delay and clears unrelated objects
Boss_AntroidEnterDefeatDelayState:                      ; was: sub_37E54
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$14,6(a5)
                moveq   #$30,d0                         ; '0'
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
; Counts down Antroid's final defeat delay while updating the fade
Boss_AntroidDefeatDelayState:                           ; was: sub_37E6C
                subq.w  #1,6(a5)
                move.w  6(a5),d0
                bpl.s   Boss_AntroidDefeatDelayUpdateFade
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Boss_AntroidDefeatDelayUpdateFade:                      ; was: loc_37E7E
                cmpi.w  #$10,d0
                bmi.w   Boss_AntroidApplyDefeatPaletteFade
                moveq   #$10,d0
                bra.w   Boss_AntroidApplyDefeatPaletteFade
; End of function Boss_AntroidDefeatDelayState
