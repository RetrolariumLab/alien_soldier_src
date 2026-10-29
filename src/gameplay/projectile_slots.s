; Scans 28 projectile-capable records forward from slot 26 through slot 53
; Returns A0 at the first zero type word and reports success with Z set
Projectile_FindFreeSlotForward:                         ; was: sub_1C050
                                        ; Projectile_FindFreeOrClearReusableSlot+4   p
                movea.w #(TwentySixthEntityType-M68K_RAM),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
; Scans 20 consecutive 96-byte records forward from the caller-supplied A0
Projectile_FindFreeSlotForward20:                       ; was: loc_1C0A4
                                        ; Boss_LovePenguinInitHomingProjectile+E   p
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
; Scans eight consecutive 96-byte records forward from the caller-supplied A0
Projectile_FindFreeSlotForward8:                        ; was: loc_1C11C
                                        ; Projectile_FindFreeEnemyPoolSlot+4   j
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
; Scans four consecutive 96-byte records forward from the caller-supplied A0
Projectile_FindFreeSlotForward4:                        ; was: loc_1C144
                                        ; Boss_TerobusterSpawnHomingMissile+22   p
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotForward_Return
                lea     $60(a0),a0
                move.w  (a0),d0
                beq.w   *+4
Projectile_FindFreeSlotForward_Return:                  ; was: locret_1C168
                                        ; Projectile_FindFreeSlotForward+10   j
                rts
; End of function Projectile_FindFreeSlotForward
; Scans the same 28 projectile-capable records in reverse, from slot 53 to 26
Projectile_FindFreeSlotReverse:                         ; was: sub_1C16A
                                        ; sub_2A0D6   p
                movea.w #(FiftyThirdEntityType-M68K_RAM),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   Projectile_FindFreeSlotReverse_Return
                lea     -$60(a0),a0
                move.w  (a0),d0
                beq.w   *+4
Projectile_FindFreeSlotReverse_Return:                  ; was: locret_1C282
                                        ; Projectile_FindFreeSlotReverse+10   j
                rts
; End of function Projectile_FindFreeSlotReverse
; Clears all 61 entity records by selecting no preserved active type
Object_ClearEntityRecords:
                moveq   #0,d0                           ; was: sub_1C284
                moveq   #0,d1
; Falls through to the two-type-preserving entry with both types set to zero
; End of function Object_ClearEntityRecords
; Clears active records in the 61-record entity pool except types D0 and D1
Object_ClearEntityRecordsExceptTwoTypes:                ; was: sub_1C288
                                        ; Stage9_UpdateCaterpillarShipTraversal+A0   p
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                moveq   #0,d3
                moveq   #$3C,d7                         ; '<'
Object_ClearRecordsExceptTwoTypes_Loop:                 ; was: loc_1C290
                                        ; Boss_UpdateSireneState4+74   p
                move.w  (a0),d2
                beq.s   Object_ClearRecordsExceptTwoTypes_Next
                cmp.w   d0,d2
                beq.s   Object_ClearRecordsExceptTwoTypes_Next
                cmp.w   d1,d2
                beq.s   Object_ClearRecordsExceptTwoTypes_Next
                move.l  d3,(a0)
                move.l  d3,4(a0)
                move.l  d3,8(a0)
                move.l  d3,$C(a0)
                move.l  d3,$10(a0)
                move.l  d3,$14(a0)
                move.l  d3,$18(a0)
                move.l  d3,$1C(a0)
                move.l  d3,$20(a0)
                move.l  d3,$24(a0)
                move.l  d3,$28(a0)
                move.l  d3,$2C(a0)
                move.l  d3,$30(a0)
                move.l  d3,$34(a0)
                move.l  d3,$38(a0)
                move.l  d3,$3C(a0)
                move.l  d3,$40(a0)
                move.l  d3,$44(a0)
                move.l  d3,$48(a0)
                move.l  d3,$4C(a0)
                move.l  d3,$50(a0)
                move.l  d3,$54(a0)
                move.l  d3,$58(a0)
                move.l  d3,$5C(a0)
Object_ClearRecordsExceptTwoTypes_Next:                 ; was: loc_1C2FA
                                        ; Object_ClearEntityRecordsExceptTwoTypes+E   j
                lea     $60(a0),a0
                dbf     d7,Object_ClearRecordsExceptTwoTypes_Loop
                rts
; End of function Object_ClearEntityRecordsExceptTwoTypes
; Finds a free forward slot; if full, clears the first reusable slot among 27
; candidates and returns that cleared record as successful allocation
Projectile_FindFreeOrClearReusableSlot:                 ; was: sub_1C304
                                        ; sub_2FF1C:loc_2FF62   p
                movem.l d7,-(sp)
                jsr     Projectile_FindFreeSlotForward(pc)  ; (pc)
                beq.s   Projectile_FindFreeOrClearReusableSlot_Return
                movea.w #(TwentySixthEntityType-M68K_RAM),a0
                moveq   #$1A,d7
Projectile_ScanReusableSlots:                           ; was: loc_1C314
                move.w  (a0),d0
                beq.s   Projectile_FindFreeOrClearReusableSlot_Return
                btst    #6,3(a0)
                bne.s   Projectile_ClearReusableSlot
                lea     $60(a0),a0
                dbf     d7,Projectile_ScanReusableSlots
                moveq   #1,d7
Projectile_FindFreeOrClearReusableSlot_Return:          ; was: loc_1C32A
                                        ; Projectile_FindFreeOrClearReusableSlot+12   j
                movem.l (sp)+,d7
                rts
; ---------------------------------------------------------------------------
Projectile_ClearReusableSlot:                           ; was: loc_1C330
                moveq   #0,d7
                move.l  d7,(a0)
                move.l  d7,4(a0)
                move.l  d7,8(a0)
                move.l  d7,$C(a0)
                move.l  d7,$10(a0)
                move.l  d7,$14(a0)
                move.l  d7,$18(a0)
                move.l  d7,$1C(a0)
                move.l  d7,$20(a0)
                move.l  d7,$24(a0)
                move.l  d7,$28(a0)
                move.l  d7,$2C(a0)
                move.l  d7,$30(a0)
                move.l  d7,$34(a0)
                move.l  d7,$38(a0)
                move.l  d7,$3C(a0)
                move.l  d7,$40(a0)
                move.l  d7,$44(a0)
                move.l  d7,$48(a0)
                move.l  d7,$4C(a0)
                move.l  d7,$50(a0)
                move.l  d7,$54(a0)
                move.l  d7,$58(a0)
                move.l  d7,$5C(a0)
                moveq   #0,d7
                movem.l (sp)+,d7
                rts
; End of function Projectile_FindFreeOrClearReusableSlot
; Clears one complete 96-byte object record at A0
Object_ClearRecord96Bytes:                              ; was: sub_1C398
                moveq   #0,d3
                move.l  d3,(a0)
                move.l  d3,4(a0)
                move.l  d3,8(a0)
                move.l  d3,$C(a0)
                move.l  d3,$10(a0)
                move.l  d3,$14(a0)
                move.l  d3,$18(a0)
                move.l  d3,$1C(a0)
                move.l  d3,$20(a0)
                move.l  d3,$24(a0)
                move.l  d3,$28(a0)
                move.l  d3,$2C(a0)
                move.l  d3,$30(a0)
                move.l  d3,$34(a0)
                move.l  d3,$38(a0)
                move.l  d3,$3C(a0)
                move.l  d3,$40(a0)
                move.l  d3,$44(a0)
                move.l  d3,$48(a0)
                move.l  d3,$4C(a0)
                move.l  d3,$50(a0)
                move.l  d3,$54(a0)
                move.l  d3,$58(a0)
                move.l  d3,$5C(a0)
                rts
; End of function Object_ClearRecord96Bytes
