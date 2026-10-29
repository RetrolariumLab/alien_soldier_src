; Updates boss metasprite parts
Boss_DeepStriderUpdateParts:                            ; CODE XREF: Boss_DeepStriderIntroRise+C8   j  ; was: sub_3EED8
                                        ; Boss_DeepStriderIntroRise+DE   j
                move.w  #$1FF,d0
                and.w   d0,$56(a5)
                and.w   d0,$1DC(a5)
                and.w   d0,$1DE(a5)
                and.w   d0,$23C(a5)
                and.w   d0,$23E(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.w  $1DC(a5),d0
                moveq   #2,d7
; Updates rotation angles for body parts
Boss_DeepStriderShiftJointAngleHistory:                 ; CODE XREF: Boss_DeepStriderUpdateParts+28   j  ; was: loc_3EEFA
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d7,Boss_DeepStriderShiftJointAngleHistory
                move.w  $1DC(a5),$B6(a5)
                move.w  (SharedScratchLong0).w,d0
                move.w  d0,d1
                add.w   d0,d1
                move.w  d1,$116(a5)
                move.w  (SharedScratchLong0+2).w,d0
                move.w  d0,d1
                add.w   d0,d1
                add.w   d0,d1
                move.w  d1,$176(a5)
                move.w  $1DC(a5),d0
                move.w  #$100,d1
                sub.w   d0,d1
                move.w  d1,$1D6(a5)
                move.w  (SharedScratchLong0).w,d0
                move.w  #$100,d1
                sub.w   d0,d1
                sub.w   d0,d1
                move.w  d1,$236(a5)
                move.w  (SharedScratchLong0+2).w,d0
                move.w  #$100,d1
                sub.w   d0,d1
                sub.w   d0,d1
                sub.w   d0,d1
                move.w  d1,$296(a5)
                move.w  (SharedScratchLong1).w,d0
                move.w  #$100,d1
                sub.w   d0,d1
                sub.w   d0,d1
                sub.w   d0,d1
                sub.w   d0,d1
                move.w  d1,$2F6(a5)
                move.w  d1,d2
                addi.w  #$80,d1
                add.w   $23E(a5),d1
                move.w  d1,$356(a5)
                subi.w  #$80,d2
                sub.w   $23E(a5),d2
                move.w  d2,$3B6(a5)
                move.w  $B6(a5),d1
                addi.w  #$80,d1
                add.w   $23C(a5),d1
                move.w  d1,$4D6(a5)
                move.w  $116(a5),d2
                subi.w  #$80,d2
                add.w   $1DE(a5),d2
                move.w  d2,$416(a5)
                move.w  d2,$476(a5)
                moveq   #$C,d7
                jmp     Sprite_UpdateMetaspriteFourFrameRotationAndLoadCount
; End of function Boss_DeepStriderUpdateParts
; ---------------------------------------------------------------------------
Boss_DeepStriderRotationFramesA:    dc.l    Boss_DeepStriderRotationMappingA0  ; DATA XREF: ROM:0003F00C   o  ; was: off_3EFAE
                dc.l    Boss_DeepStriderRotationMappingA1
                dc.l    Boss_DeepStriderRotationMappingA2
                dc.l    Boss_DeepStriderRotationMappingA3
Boss_DeepStriderRotationFramesB:    dc.l    Boss_DeepStriderRotationMappingB0  ; DATA XREF: ROM:0003F004   o  ; was: off_3EFBE
                                        ; ROM:0003F008   o
                dc.l    Boss_DeepStriderRotationMappingB1
                dc.l    Boss_DeepStriderRotationMappingB2
                dc.l    Boss_DeepStriderRotationMappingB3
Boss_DeepStriderRotationFramesC:    dc.l    Boss_DeepStriderRotationMappingC0  ; DATA XREF: ROM:0003F024   o  ; was: off_3EFCE
                                        ; ROM:0003F030   o
                dc.l    Boss_DeepStriderRotationMappingC1
                dc.l    Boss_DeepStriderRotationMappingC2
                dc.l    Boss_DeepStriderRotationMappingC3
Boss_DeepStriderRotationFramesD:    dc.l    Boss_DeepStriderRotationMappingC3  ; DATA XREF: ROM:0003F020   o  ; was: off_3EFDE
                                        ; ROM:0003F02C   o
                dc.l    Boss_DeepStriderRotationMappingC2
                dc.l    Boss_DeepStriderRotationMappingC1
                dc.l    Boss_DeepStriderRotationMappingC0
Boss_DeepStriderInlineSpriteDescriptorA:    dc.w    $6397, $A00, $F4F4  ; DATA XREF: ROM:0003F014   o  ; was: word_3EFEE
                                        ; ROM:0003F028   o
Boss_DeepStriderInlineSpriteDescriptorB:    dc.w    $63A0, $500, $F8F8  ; DATA XREF: ROM:0003F018   o  ; was: word_3EFF4
Boss_DeepStriderInlineSpriteDescriptorC:    dc.w    $63A4, $500, $F8F8  ; DATA XREF: ROM:0003F01C   o  ; was: word_3EFFA
Boss_DeepStriderMetaspriteDescriptors:      dc.l    Boss_DeepStriderRootMapping+$400000  ; DATA XREF: Boss_DeepStriderIntroRise+E   o  ; was: off_3F000
                dc.l    Boss_DeepStriderRotationFramesB
                dc.l    Boss_DeepStriderRotationFramesB
                dc.l    Boss_DeepStriderRotationFramesA
                dc.l    Boss_DeepStriderRootMapping+$400000
                dc.l    Boss_DeepStriderInlineSpriteDescriptorA+1
                dc.l    Boss_DeepStriderInlineSpriteDescriptorB+1
                dc.l    Boss_DeepStriderInlineSpriteDescriptorC+1
                dc.l    Boss_DeepStriderRotationFramesD+$28000000
                dc.l    Boss_DeepStriderRotationFramesC
                dc.l    Boss_DeepStriderInlineSpriteDescriptorA+1
                dc.l    Boss_DeepStriderRotationFramesD+$28000000
                dc.l    Boss_DeepStriderRotationFramesC
                dc.l    0
Boss_DeepStriderPartRadii:  dc.w    $15, $1210, $1410   ; DATA XREF: Boss_DeepStriderIntroRise+14   o  ; was: word_3F038
                dc.w    $C0A, $C0C, $E10
                dc.w    $1418
Boss_DeepStriderPartLinks:  dc.w    $C007, $C006, $C065  ; was: word_3F046
                                        ; DATA XREF: Boss_DeepStriderIntroRise+1A   o
                dc.w    $C0C4, $C007, $C187
                dc.w    $C1E7, $C247, $C2A7
                dc.w    $C2A7, $C0C4, $C3C4
                dc.w    $C067, 7

; Fires angled projectile from Deep Strider boss using sine table
Boss_DeepStriderFireAngleProjectile:                    ; CODE XREF: Boss_DeepStriderBeginBattleCycle+230   p  ; was: sub_3F062
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Boss_DeepStriderFireAngleProjectileReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_DeepStriderFireAngleProjectileReturn
                move.w  #$350,(a0)
                move.w  #$AD80,2(a0)
                move.w  #$4411,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.b  #$10,$20(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.w  #$50,$26(a0)                    ; 'P'
                move.l  #$FF01FF01,$2C(a0)
                move.w  (RandomNumberState).w,d3
                ext.l   d3
                asl.l   #2,d3
                lea     (Math_SineTable).l,a1
                move.w  $56(a5),d7
                addi.w  #$20,d7                         ; ' '
                andi.w  #$1FE,d7
                move.w  -$80(a1,d7.w),d0
                move.w  (a1,d7.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #4,d0
                asl.l   #3,d1
                move.l  d0,$1C(a0)
                clr.l   $18(a0)
                move.w  $134(a5),$14(a0)
                addq.w  #2,$14(a0)
                move.w  $130(a5),$10(a0)
                btst    #3,$12E(a5)
                beq.s   Boss_DeepStriderApplyPositiveProjectileFacing
                subq.w  #4,$10(a0)
                sub.l   d3,$18(a0)
                sub.l   d1,$18(a0)
                rts
; ---------------------------------------------------------------------------
Boss_DeepStriderApplyPositiveProjectileFacing:          ; CODE XREF: Boss_DeepStriderFireAngleProjectile+94   j  ; was: loc_3F106
                addq.w  #4,$10(a0)
                add.l   d3,$18(a0)
                add.l   d1,$18(a0)
Boss_DeepStriderFireAngleProjectileReturn:              ; CODE XREF: Boss_DeepStriderFireAngleProjectile+8   j  ; was: locret_3F112
                                        ; Boss_DeepStriderFireAngleProjectile+12   j
                rts
; End of function Boss_DeepStriderFireAngleProjectile
