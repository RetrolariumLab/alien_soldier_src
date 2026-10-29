; Destroyer Proto defeat scatter, arena effects, and animated part helpers
Boss_DestroyerProtoBeginDefeatScatter:                  ; was: sub_31D9A
                clr.b   $21(a5)
                movea.w a5,a4
                lea     Projectile_DestroyerProtoVelocityXTable(pc),a0
                nop
                lea     Projectile_DestroyerProtoVelocityYTable(pc),a1
                nop
                move.w  #5,d7
Boss_DestroyerProtoScatterNextPart:                     ; was: loc_31DB0
                adda.w  #$60,a4                         ; '`'
                jsr     (RandomNumber).l
                andi.w  #$3C,d0                         ; '<'
                move.l  (a0,d0.w),$18(a4)
                move.l  (a1,d0.w),$1C(a4)
                clr.b   $21(a4)
                move.w  #2,4(a4)
                dbf     d7,Boss_DestroyerProtoScatterNextPart
                move.w  #$100,$4A(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.b   (PlaneAScrollModeFlags).w
                move.b  #3,(VDPReg11Shadow+1).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerProtoBeginDefeatScatter
; Emits one randomized defeat particle around the boss
Boss_DestroyerProtoEmitDefeatParticle:                  ; was: sub_31DF6
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_InitType88).l
                clr.b   $20(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d0                         ; ' '
                subi.w  #$20,d1                         ; ' '
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
                move.w  (RandomNumberState+2).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$1C(a0)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #7,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Boss_DestroyerProtoDefeatParticleMappingTable(pc,d0.w),8(a0)
                ori.w   #$8000,$E(a0)
                rts
; End of function Boss_DestroyerProtoEmitDefeatParticle
; ---------------------------------------------------------------------------
Boss_DestroyerProtoDefeatParticleMappingTable:  dc.l    Effect_SpriteAnimation00  ; was: off_31E7C
                dc.l    Effect_SpriteAnimation03
                dc.l    Effect_SpriteAnimation01
                dc.l    Effect_SpriteAnimation04
                dc.l    Effect_SpriteAnimation02
                dc.l    Effect_SpriteAnimation05
                dc.l    Effect_SpriteAnimation02
                dc.l    Effect_SpriteAnimation06

; Runs the defeat particle, palette, and arena-rotation effects until removal
Boss_DestroyerProtoUpdateDefeatExplosion:               ; was: sub_31E9C
                bsr.w   Boss_DestroyerProtoEmitDefeatParticle
                jsr     Boss_DestroyerProtoApplyDefeatPaletteFade(pc)  ; (pc)
                nop
                jsr     Boss_DestroyerProtoRotateArenaEffectEntries(pc)  ; (pc)
                nop
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                movea.l #Boss_DestroyerProtoDefeatGraphicsLoadDescriptor,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$1000,2(a5)
                rts
; End of function Boss_DestroyerProtoUpdateDefeatExplosion
; ---------------------------------------------------------------------------
Boss_DestroyerProtoDefeatGraphicsLoadDescriptor:    dc.w    $4000, $4000, $303, 0, 0, 0, 0, 0, 0, 0, 0  ; was: word_31EC8

; Rotates selected entries in the arena effect buffer during defeat
Boss_DestroyerProtoRotateArenaEffectEntries:            ; was: sub_31EDE
                move.w  $4A(a5),d0
                cmpi.w  #$40,d0                         ; '@'
                bcc.w   Entity_UpdateReturn
                andi.w  #1,d0
                bne.w   Entity_UpdateReturn
                lea     (HScrollPlaneARow32).w,a0
                lea     Boss_DestroyerProtoArenaEffectRotationTable(pc),a1
                nop
                clr.w   d1
                move.w  #$BF,d0
Boss_DestroyerProtoRotateNextArenaEffectEntry:          ; was: loc_31F02
                move.w  (a0),d2
                andi.w  #$1FF,d2
                cmpi.w  #$140,d2
                bcs.s   Boss_DestroyerProtoApplyArenaEffectRotation
                cmpi.w  #$180,d2
                bcs.s   Boss_DestroyerProtoAdvanceArenaEffectEntry
Boss_DestroyerProtoApplyArenaEffectRotation:            ; was: loc_31F14
                add.w   (a1,d1.w),d2
                move.w  d2,(a0)
Boss_DestroyerProtoAdvanceArenaEffectEntry:             ; was: loc_31F1A
                addq.w  #4,a0
                addq.w  #2,d1
                andi.w  #$1E,d1
                dbf     d0,Boss_DestroyerProtoRotateNextArenaEffectEntry
                rts
; End of function Boss_DestroyerProtoRotateArenaEffectEntries
; ---------------------------------------------------------------------------
Boss_DestroyerProtoArenaEffectRotationTable:    dc.w    1, $FFFF  ; was: word_31F28
                dc.w    5, $FFFB
                dc.w    7, $FFF9
                dc.w    3, $FFFD
                dc.w    6, $FFFA
                dc.w    2, $FFFE
                dc.w    8, $FFF8
                dc.w    4, $FFFC

; Applies palette fade effect based on timer and fade direction
Boss_DestroyerProtoApplyPaletteFade:                    ; was: sub_31F48
                                        ; Boss_DestroyerProtoFadeTwinShots+4   p
                move.w  $4A(a5),d0
                andi.w  #$E,d0
                move.w  #$F,d5
                lea     (PaletteActiveColor48).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_DestroyerProtoApplyPaletteFade
; Applies the short defeat palette fade
Boss_DestroyerProtoApplyDefeatPaletteFade:              ; was: sub_31F5E
                cmpi.w  #$E,$4A(a5)
                bcc.w   Entity_UpdateReturn
                move.w  #$E000,d7
                move.w  #$F,d0
                sub.w   $4A(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                lea     (PaletteActiveBuffer).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_DestroyerProtoApplyDefeatPaletteFade
; Updates an ordinary linked part, or culls it after scatter activation
Boss_DestroyerProtoPartMain:                            ; was: sub_31F86
                tst.w   4(a5)
                bne.w   Entity_RemoveOutsideArena
; End of function Boss_DestroyerProtoPartMain
; Recomputes an entity's position from its parent, polar angle, and radius
Entity_UpdatePolarPositionFromParent:                   ; was: sub_31F8E
                                        ; EntityType390_TerminalBeginAttackCycle   p
                movea.w $44(a5),a4
                move.w  $40(a5),d0
                bsr.w   Math_LookupSineCosinePairDuplicate
                move.w  $42(a5),d2
                muls.w  d2,d0
                add.l   $10(a4),d0
                move.l  d0,$10(a5)
                muls.w  d2,d1
                add.l   $14(a4),d1
                move.l  d1,$14(a5)
                rts
; End of function Entity_UpdatePolarPositionFromParent
; Updates an animated linked part and selects its angle-dependent frame
Boss_DestroyerProtoAnimatedPartMain:                    ; was: sub_31FB4
                tst.w   4(a5)
                bne.w   Boss_DestroyerProtoAnimatedPartAdvance
                bsr.w   Entity_UpdatePolarPositionFromParent
Boss_DestroyerProtoAnimatedPartSelectFrame:             ; was: loc_31FC0
                move.w  $46(a5),d0
                addi.w  #$10,d0
                andi.w  #$1E0,d0
                lsr.w   #3,d0
                lea     Boss_DestroyerProtoPartMappingFrameTable(pc),a0
                nop
                move.l  (a0,d0.w),8(a5)
                lsr.w   #1,d0
                lea     Projectile_DestroyerProtoSpriteAttributeTable(pc),a0
                nop
                move.w  (a0,d0.w),$E(a5)
                rts
; ---------------------------------------------------------------------------
Boss_DestroyerProtoAnimatedPartAdvance:                 ; was: loc_31FEA
                addi.w  #$20,$46(a5)                    ; ' '
                bsr.w   Boss_DestroyerProtoAnimatedPartSelectFrame
                bra.w   Entity_RemoveOutsideArena
; End of function Boss_DestroyerProtoAnimatedPartMain
; ---------------------------------------------------------------------------
