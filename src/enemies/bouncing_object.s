; Shared bouncing object, pickup release, and effect conversion
Enemy_UpdateBouncingObject:                             ; was: sub_3F114
                tst.w   (StageSpawnCountdown).w
                bpl.s   Enemy_ResetBouncingObjectMotion
                bclr    #7,$22(a5)
                beq.s   Enemy_CheckBouncingObjectFloor
                bclr    #4,$22(a5)
                beq.s   Enemy_ResetBouncingObjectMotion
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Enemy_ResetBouncingObjectMotion
                jsr     (Pickup_SpawnSmall).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                bra.s   Enemy_ResetBouncingObjectMotion
; ---------------------------------------------------------------------------
Enemy_CheckBouncingObjectFloor:                         ; was: loc_3F146
                jsr     (Collision_GetEntityPosition).l
                beq.s   Enemy_ApplyBouncingObjectGravity
Enemy_ResetBouncingObjectMotion:                        ; was: loc_3F14E
                                        ; Enemy_UpdateBouncingObject+14   j
                neg.w   $18(a5)
                move.w  #$FFFE,$1C(a5)
                lea     (Projectile_SpawnSpriteFrames).l,a1  ; make offsets?
                jmp     Sprite_InitCurrentFromTable
; ---------------------------------------------------------------------------
Enemy_ApplyBouncingObjectGravity:                       ; was: loc_3F164
                addi.l  #$E00,$1C(a5)
                bmi.s   Enemy_UpdateBouncingObjectReturn
                cmpi.w  #$14C,$14(a5)
                bmi.s   Enemy_UpdateBouncingObjectReturn
                clr.l   $18(a5)
                move.l  #$FFFC0000,$1C(a5)
Projectile_ConvertCurrentToSharedEffect:                ; was: loc_3F182
                move.l  #SharedProjectileDuration4Animation,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                move.w  #$4000,$E(a5)
Enemy_UpdateBouncingObjectReturn:                       ; was: locret_3F196
                                        ; Enemy_UpdateBouncingObject+60   j
                rts
; End of function Enemy_UpdateBouncingObject
