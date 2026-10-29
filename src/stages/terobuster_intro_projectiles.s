; Initialize the Stage 7 boundary-projectile cursor and progressive tile row
Stage7_InitializeTerobusterIntroProjectiles:            ; was: sub_D5BC
                move.w  #$CC,(TerobusterProjectileY).w
                clr.w   (TerobusterTileRowIndex).w
                rts
; End of function Stage7_InitializeTerobusterIntroProjectiles
; Spawn one type-$178 boundary projectile on alternate frames
Stage7_SpawnTerobusterIntroProjectile:                  ; was: sub_D5C8
                                        ; Stage7_InitializeTerobusterEncounter   p
                                        ; Stage7_UpdatePostTerobusterIntro   p
                btst    #0,(FrameCounter+1).w
                bne.s   Stage7_SpawnTerobusterIntroProjectile_Return
                movea.w #(FortySixthEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward8).l
                bne.s   Stage7_SpawnTerobusterIntroProjectile_Return
                move.w  #$178,(a0)
                move.w  #$8100,2(a0)
                move.w  #$2240,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.w  #8,$48(a0)
                move.b  #$60,$20(a0)                    ; '`'
                clr.w   $10(a0)
                move.w  (TerobusterProjectileY).w,$14(a0)
                addi.w  #$11,(TerobusterProjectileY).w
                cmpi.w  #$13C,(TerobusterProjectileY).w
                bmi.s   Stage7_SpawnTerobusterIntroProjectile_Return
                move.w  #$CC,(TerobusterProjectileY).w
Stage7_SpawnTerobusterIntroProjectile_Return:           ; was: locret_D622
                                        ; Stage7_SpawnTerobusterIntroProjectile+12   j
                rts
; End of function Stage7_SpawnTerobusterIntroProjectile
; Keep the short-lived Stage 7 boundary projectile screen-anchored and flickering
Projectile_TerobusterIntroBoundary:                     ; was: sub_D624
                subq.w  #1,$48(a5)
                bpl.s   Projectile_TerobusterIntroBoundary_Update
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_TerobusterIntroBoundary_Update:              ; was: loc_D632
                move.w  #$1114,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                bset    #7,2(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_TerobusterIntroBoundary_Return
                bclr    #7,2(a5)
Projectile_TerobusterIntroBoundary_Return:              ; was: locret_D652
                rts
; End of function Projectile_TerobusterIntroBoundary
; Progress through the Terobuster intro row descriptors, then alternate the
; final two rows every eight frames
Stage7_UpdateTerobusterIntroTileRows:                   ; was: sub_D654
                                        ; Stage7_UpdatePostTerobusterIntro+4   p
                move.w  (TerobusterTileRowIndex).w,d0
                cmpi.w  #$14,d0
                bmi.s   Stage7_AdvanceTerobusterIntroTileRows
                lea     Stage7_TerobusterIndexedRowCommandF8F9(pc),a0
                nop
                btst    #3,(FrameCounter+1).w
                bne.s   Stage7_QueueTerobusterIntroTileRows
                lea     Stage7_TerobusterIndexedRowCommandFAFB(pc),a0
                nop
Stage7_QueueTerobusterIntroTileRows:                    ; was: loc_D672
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Stage7_UpdateTerobusterIntroTileRows_Return:            ; was: locret_D678
                rts
; ---------------------------------------------------------------------------
Stage7_AdvanceTerobusterIntroTileRows:                  ; was: loc_D67A
                move.w  (FrameCounter).w,d1
                andi.w  #7,d1
                bne.s   Stage7_UpdateTerobusterIntroTileRows_Return
                movea.l Stage7_TerobusterIntroIndexedRowCommandPointers(pc,d0.w),a0
                addq.w  #4,(TerobusterTileRowIndex).w
                jmp     Tilemap_QueueIndexedRows
; End of function Stage7_UpdateTerobusterIntroTileRows
; ---------------------------------------------------------------------------
Stage7_TerobusterIntroIndexedRowCommandPointers:
                dc.l    Stage7_TerobusterIndexedRowCommandF0F1  ; was: off_D692
                dc.l    Stage7_TerobusterIndexedRowCommandF2F3
                dc.l    Stage7_TerobusterIndexedRowCommandF4F5
                dc.l    Stage7_TerobusterIndexedRowCommandF6F7
                dc.l    Stage7_TerobusterIndexedRowCommandF8F9
Stage7_TerobusterIndexedRowCommandF0F1:
                dc.b    $44, $B4, $40, 0, 1, 0, $F0, $F1  ; was: byte_D6A6
                                        ; ROM:Stage7_TerobusterIntroIndexedRowCommandPointers   o
Stage7_TerobusterIndexedRowCommandF2F3:
                dc.b    $44, $B4, $40, 0, 1, 0, $F2, $F3  ; was: byte_D6AE
Stage7_TerobusterIndexedRowCommandF4F5:
                dc.b    $44, $B4, $40, 0, 1, 0, $F4, $F5  ; was: byte_D6B6
Stage7_TerobusterIndexedRowCommandF6F7:
                dc.b    $44, $B4, $40, 0, 1, 0, $F6, $F7  ; was: byte_D6BE
Stage7_TerobusterIndexedRowCommandF8F9:
                dc.b    $44, $B4, $40, 0, 1, 0, $F8, $F9  ; was: byte_D6C6
                                        ; ROM:0000D6A2   o
Stage7_TerobusterIndexedRowCommandFAFB:
                dc.b    $44, $B4, $40, 0, 1, 0, $FA, $FB  ; was: byte_D6CE
