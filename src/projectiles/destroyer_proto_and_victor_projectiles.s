; Shared type-$3B8 projectile data and handlers used by Destroyer Proto and
; Victor split shots
Projectile_DestroyerProtoVelocityXTable:    dc.w    4, 0  ; was: word_31FF8
                                        ; Boss_DestroyerProtoBeginDefeatScatter+6   o
                dc.w    3, $8000
                dc.w    2, $D410
                dc.w    1, $C000
                dc.w    0, 0
                dc.w    $FFFE, $4000
                dc.w    $FFFD, $2BF0
                dc.w    $FFFC, $8000
                dc.w    $FFFC, 0
                dc.w    $FFFC, $8000
                dc.w    $FFFD, $2BF0
                dc.w    $FFFE, $4000
                dc.w    0, 0
                dc.w    1, $C000
                dc.w    2, $D410
                dc.w    3, $8000
Projectile_DestroyerProtoVelocityYTable:    dc.w    0, 0  ; was: word_32038
                                        ; Boss_DestroyerProtoBeginDefeatScatter+C   o
                dc.w    1, $C000
                dc.w    2, $D410
                dc.w    3, $8000
                dc.w    4, 0
                dc.w    3, $8000
                dc.w    2, $D410
                dc.w    1, $C000
                dc.w    0, 0
                dc.w    $FFFE, $4000
                dc.w    $FFFD, $2BF0
                dc.w    $FFFC, $8000
                dc.w    $FFFC, 0
                dc.w    $FFFC, $8000
                dc.w    $FFFD, $2BF0
                dc.w    $FFFE, $4000
Projectile_DestroyerProtoSpawnOffsetXTable: dc.l    $300000, $2AC000  ; was: dword_32078
                dc.l    $21F0C0, $144000
                dc.l    0, $FFEBC000
                dc.l    $FFDE0F40, $FFD54000
                dc.l    $FFD00000, $FFD54000
                dc.l    $FFDE0F40, $FFEBC000
                dc.l    0, $144000
                dc.l    $21F0C0, $2AC000
Projectile_DestroyerProtoSpawnOffsetYTable: dc.l    0, $144000  ; was: dword_320B8
                dc.l    $21F0C0, $2AC000
                dc.l    $300000, $2AC000
                dc.l    $21F0C0, $144000
                dc.l    0, $FFEBC000
                dc.l    $FFDE0F40, $FFD54000
                dc.l    $FFD00000, $FFD54000
                dc.l    $FFDE0F40, $FFEBC000
Projectile_DestroyerProtoSpriteAttributeTable:  dc.w    $6B00, $6B00, $6B00, $6B00  ; was: word_320F8
                                        ; Boss_DestroyerProtoAnimatedPartMain+28   o
                dc.w    $6300, $6300, $6300, $6300
                dc.w    $7300, $7300, $7300, $7300
                dc.w    $7B00, $7B00, $7B00, $7B00
Boss_DestroyerProtoPartMappingFrameTable:   dc.l    Boss_DestroyerProtoPartFrame01  ; was: off_32118
                dc.l    Boss_DestroyerProtoPartFrame02
                dc.l    Boss_DestroyerProtoPartFrame03
                dc.l    Boss_DestroyerProtoPartFrame04
                dc.l    Boss_DestroyerProtoPartFrame00
                dc.l    Boss_DestroyerProtoPartFrame04
                dc.l    Boss_DestroyerProtoPartFrame03
                dc.l    Boss_DestroyerProtoPartFrame02
                dc.l    Boss_DestroyerProtoPartFrame01
                dc.l    Boss_DestroyerProtoPartFrame02
                dc.l    Boss_DestroyerProtoPartFrame03
                dc.l    Boss_DestroyerProtoPartFrame04
                dc.l    Boss_DestroyerProtoPartFrame00
                dc.l    Boss_DestroyerProtoPartFrame04
                dc.l    Boss_DestroyerProtoPartFrame03
                dc.l    Boss_DestroyerProtoPartFrame02

; Initializes two fixed-slot Destroyer Proto projectiles from the inner parts
Boss_DestroyerProtoLaunchTwinProjectiles:               ; was: sub_32158
                lea     (QuaternaryEntityType).w,a4
                lea     (EighthEntityType).w,a0
                bsr.w   Projectile_DestroyerProtoInitFromPart
                lea     (SeventhEntityType).w,a4
                lea     (TwentyFourthEntityType).w,a0
; End of function Boss_DestroyerProtoLaunchTwinProjectiles
; Initializes one delayed Destroyer Proto projectile from a linked part
Projectile_DestroyerProtoInitFromPart:                  ; was: sub_3216C
                                        ; Boss_DestroyerProtoLaunchTwinProjectiles+8   p
                move.w  #$EC00,TwentyFourthEntityFlags-TwentyFourthEntityType(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$F808F808,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  #$64,$26(a0)                    ; 'd'
                move.l  #Effect_SpriteAnimation13,8(a0)
                move.w  #$3B8,(a0)
                move.w  $40(a4),d0
                addi.w  #$10,d0
                andi.w  #$1E0,d0
                lsr.w   #3,d0
                move.w  d0,$54(a0)
                lea     Projectile_DestroyerProtoVelocityXTable(pc),a1
                move.l  (a1,d0.w),d1
                move.l  d1,$4C(a0)
                lea     Projectile_DestroyerProtoSpawnOffsetXTable(pc),a1
                move.l  (a1,d0.w),d1
                add.l   $10(a4),d1
                move.l  d1,$10(a0)
                lea     Projectile_DestroyerProtoVelocityYTable(pc),a1
                move.l  (a1,d0.w),d1
                move.l  d1,$50(a0)
                lea     Projectile_DestroyerProtoSpawnOffsetYTable(pc),a1
                move.l  (a1,d0.w),d1
                add.l   $14(a4),d1
                move.l  d1,$14(a0)
                move.b  #0,$20(a0)
                move.w  #$480,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a0)
                move.w  #6,$48(a0)
                move.w  #8,$4A(a0)
                clr.w   4(a0)
                rts
; End of function Projectile_DestroyerProtoInitFromPart
; Dispatches the delayed spread projectile states
Projectile_DestroyerProtoMain:                          ; was: sub_32208
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                move.w  4(a5),d0
                lea     Projectile_DestroyerProtoStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_DestroyerProtoMain
; ---------------------------------------------------------------------------
Projectile_DestroyerProtoStates:    dc.w    Projectile_DestroyerProtoSpawnSpreadCopies-*  ; was: off_32218
                dc.w    Entity_RemoveOutsideArena-*
                dc.w    Projectile_DestroyerProtoRestoreVelocity-*
                dc.w    Projectile_DestroyerProtoCheckHitForPickup-*
                dc.w    Projectile_DestroyerProtoCheckHorizontalReflection-*

; Activates the lead shot and creates seven staggered spread copies
Projectile_DestroyerProtoSpawnSpreadCopies:             ; was: sub_32222
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.l  $4C(a5),$18(a5)
                move.l  $50(a5),$1C(a5)
                move.w  $54(a5),d0
                lea     Projectile_DestroyerProtoMappingFrameTable(pc),a0
                nop
                move.l  (a0,d0.w),8(a5)
                lsr.w   #1,d0
                lea     Projectile_DestroyerProtoSpriteAttributeTable(pc),a0
                move.w  (a0,d0.w),$E(a5)
                move.w  #$CC00,2(a5)
                movea.w a5,a4
                move.w  #6,d0
Projectile_DestroyerProtoSpawnNextSpreadCopy:           ; was: loc_3225E
                adda.w  #$60,a4                         ; '`'
                move.w  #$CC00,2(a4)
                move.w  #$3B8,(a4)
                move.w  #6,$48(a4)
                move.w  #4,4(a4)
                move.l  $4C(a5),$4C(a4)
                move.l  $50(a5),$50(a4)
                move.l  8(a5),8(a4)
                move.w  $E(a5),$E(a4)
                move.b  $21(a5),$21(a4)
                move.l  $10(a5),$10(a4)
                move.l  $14(a5),$14(a4)
                move.l  $2C(a5),$2C(a4)
                move.l  $28(a5),$28(a4)
                move.w  #$64,$26(a4)                    ; 'd'
                move.w  d0,d1
                addq.w  #1,d1
                lsl.w   #2,d1
                move.w  d1,$4A(a4)
                dbf     d0,Projectile_DestroyerProtoSpawnNextSpreadCopy
                addq.w  #2,4(a5)
                rts
; End of function Projectile_DestroyerProtoSpawnSpreadCopies
; ---------------------------------------------------------------------------
Projectile_DestroyerProtoMappingFrameTable: dc.l    Projectile_DestroyerProtoFrame00  ; was: off_322C8
                                        ; Projectile_DestroyerProtoSpawnSpreadCopies+18   o
                dc.l    Projectile_DestroyerProtoFrame01
                dc.l    Projectile_DestroyerProtoFrame02
                dc.l    Projectile_DestroyerProtoFrame03
                dc.l    Projectile_DestroyerProtoFrame04
                dc.l    Projectile_DestroyerProtoFrame03
                dc.l    Projectile_DestroyerProtoFrame02
                dc.l    Projectile_DestroyerProtoFrame01
                dc.l    Projectile_DestroyerProtoFrame00
                dc.l    Projectile_DestroyerProtoFrame01
                dc.l    Projectile_DestroyerProtoFrame02
                dc.l    Projectile_DestroyerProtoFrame03
                dc.l    Projectile_DestroyerProtoFrame04
                dc.l    Projectile_DestroyerProtoFrame03
                dc.l    Projectile_DestroyerProtoFrame02
                dc.l    Projectile_DestroyerProtoFrame01

; Reflects horizontal velocity when collision flag 4 is set
Projectile_DestroyerProtoCheckHorizontalReflection:     ; was: sub_32308
                bclr    #4,$22(a5)
                bne.s   Projectile_DestroyerProtoReflectHorizontal
                bra.s   Entity_RemoveOutsideArena
; End of function Projectile_DestroyerProtoCheckHorizontalReflection
; Converts a collision-flag-4 hit into the shared random-pickup response
Projectile_DestroyerProtoCheckHitForPickup:             ; was: sub_32312
                bclr    #4,$22(a5)
                bne.s   Projectile_ConvertHitToRandomPickup
; End of function Projectile_DestroyerProtoCheckHitForPickup
; Marks a projectile or scattered boss part outside the arena for removal
Entity_RemoveOutsideArena:                              ; was: sub_3231A
                                        ; Boss_DestroyerProtoAnimatedPartMain+40   j
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Projectile_RemoveOutsideArenaNow
                cmpi.w  #$1E0,$10(a5)
                bcc.s   Projectile_RemoveOutsideArenaNow
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcs.s   Projectile_RemoveOutsideArenaNow
                cmpi.w  #$180,$14(a5)
                bcc.s   Projectile_RemoveOutsideArenaNow
                rts
; ---------------------------------------------------------------------------
Projectile_RemoveOutsideArenaNow:                       ; was: loc_3233C
                                        ; Entity_RemoveOutsideArena+E   j
                move.w  #$1000,2(a5)
                rts
; End of function Entity_RemoveOutsideArena
Projectile_ConvertHitToRandomPickup:                    ; was: sub_32344
                                        ; Projectile_HitReactiveShotMain+18   j
                jsr     (RandomNumber).l
                andi.w  #$1F,d0
                jsr     (Pickup_SpawnRandomFromCurrentObject).l
                andi.w  #$FEFF,2(a5)
                rts
; End of function Projectile_ConvertHitToRandomPickup
; Reflects projectile by negating X velocity and advancing state
Projectile_DestroyerProtoReflectHorizontal:             ; was: sub_3235C
                neg.l   $18(a5)
                move.w  #2,4(a5)
                rts
; End of function Projectile_DestroyerProtoReflectHorizontal
; Returns projectile to stored velocity after delay timer expires
Projectile_DestroyerProtoRestoreVelocity:               ; was: sub_32368
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.l  $4C(a5),$18(a5)
                move.l  $50(a5),$1C(a5)
                subq.w  #2,4(a5)
                rts
; End of function Projectile_DestroyerProtoRestoreVelocity
; Updates a hit-reactive shot, spawning an impact object before removal
Projectile_HitReactiveShotMain:                         ; was: sub_32382
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                bsr.w   Entity_RemoveOutsideArena
                bclr    #7,$22(a5)
                beq.w   Entity_UpdateReturn
                bclr    #4,$22(a5)
                bne.w   Projectile_ConvertHitToRandomPickup
Projectile_HitReactiveShotSpawnImpact:                  ; was: loc_3239E
                cmpi.w  #$1A,(StageTableIndex).w
                bne.s   Projectile_HitReactiveShotAllocateImpact
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$20,(PaletteRGBChannelMask).w  ; ' '
                move.b  #8,(PaletteRGBAdjustStep).w
Projectile_HitReactiveShotAllocateImpact:               ; was: loc_323B8
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_HitReactiveShotRemove
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #Effect_SpriteAnimation01,8(a0)
                jsr     (Sprite_InitType160).l
Projectile_HitReactiveShotRemove:                       ; was: loc_323DA
                move.w  #$1000,2(a5)
                rts
; End of function Projectile_HitReactiveShotMain
