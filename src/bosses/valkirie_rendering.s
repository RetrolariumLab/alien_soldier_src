; Map the current pose bytes to angle fields across all 25 body parts
Anim_ApplyValkiriePoseToParts:                          ; was: sub_5605C
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$116(a5)
                move.b  8(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$176(a5)
                move.b  $C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                move.b  $10(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                move.w  d0,$296(a5)
                move.b  $14(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                move.w  d0,$356(a5)
                move.b  $18(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                move.b  $1C(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                move.w  d0,$476(a5)
                move.b  $20(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$4D6(a5)
                move.w  d0,$536(a5)
                move.b  $24(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                move.w  d0,$5F6(a5)
                move.b  $28(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$656(a5)
                move.w  d1,$6B6(a5)
                move.b  $2C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                addi.w  #$100,d0
                move.b  $30(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$776(a5)
                move.b  $34(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$7D6(a5)
                move.w  d0,$836(a5)
                move.b  $38(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$896(a5)
                move.w  d1,$8F6(a5)
                move.b  $3C(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$956(a5)
                addi.w  #$100,d0
                move.b  $40(a0),d1
                asl.w   #1,d1
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$9B6(a5)
                move.b  $44(a0),d1
                ext.w   d1
                move.w  $B2(a5),d0
                add.w   d1,d0
                move.w  d0,$B4(a5)
                move.w  $112(a5),d0
                add.w   d1,d0
                move.w  d0,$114(a5)
                move.b  $48(a0),d1
                ext.w   d1
                move.w  $172(a5),d0
                add.w   d1,d0
                move.w  d0,$174(a5)
                rts
; End of function Anim_ApplyValkiriePoseToParts
; Interpret Valkirie pose commands, embedded event bytes, and frame delays
Anim_UpdateValkiriePoseScript:                          ; was: sub_56190
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Anim_AdvanceValkiriePoseInterpolation
Anim_ReadValkiriePoseCommand:                           ; was: loc_5619A
                                        ; Anim_ProcessValkiriePoseFrame+E   j
                move.w  $58(a5),d0
                bmi.w   Anim_PrepareValkiriePosePartTraversal
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Anim_CheckValkiriePoseStopMarker
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Anim_ReadValkiriePoseCommand
; ---------------------------------------------------------------------------
Anim_CheckValkiriePoseStopMarker:                       ; was: loc_561B6
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Anim_ProcessValkiriePoseFrame
                move.w  d3,$58(a5)
                bra.w   Anim_PrepareValkiriePosePartTraversal
; End of function Anim_UpdateValkiriePoseScript
Anim_ValkiriePoseNoOp:                                  ; was: nullsub_128
                rts
; End of function Anim_ValkiriePoseNoOp

; Decode a pose-frame command or restart the script at $FFFF
Anim_ProcessValkiriePoseFrame:                          ; was: sub_561CA
                cmpi.w  #$FFFF,d3
                bne.s   Anim_StartValkiriePoseFrame
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Anim_ReadValkiriePoseCommand
; ---------------------------------------------------------------------------
Anim_StartValkiriePoseFrame:                            ; was: loc_561DA
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Anim_CalculateValkiriePoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Anim_PrepareValkiriePosePartTraversal
Anim_AdvanceValkiriePoseInterpolation:                  ; was: loc_5620A
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$12,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Anim_PrepareValkiriePosePartTraversal:                  ; was: loc_5621A
                                        ; Anim_UpdateValkiriePoseScript+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Anim_ProcessValkiriePoseFrame
; Calculate interpolation deltas for the next 19-angle pose frame
Anim_CalculateValkiriePoseDeltas:                       ; was: sub_56224
                movea.l $2FC(a5),a1
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Anim_CalculateValkiriePoseDeltas
; Initialize nineteen Valkirie pose channels from bytes at a0
Boss_ValkirieInitializePoseChannels:                    ; was: sub_56238
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_ValkirieInitializePoseChannels
; ---------------------------------------------------------------------------
Valkirie_State2Poses:       dc.w    $A0F, $190, $606, $190, $1C1C, $1A4, $8002, $A0F, $1B8, $606, $1B8, $1C1C, $1CC, $8001, $FFFF  ; was: word_56244
Valkirie_State4To8Poses:    dc.w    $810, 0, $1010, 0, $8001, $810, $14, $1010, $14, $8001, $FFFF, $810, $140, $1010, $140, $8001  ; was: word_56262
                                        ; Entity_UpdateValkirieBattleState6:Entity_RenderValkirieBattleState6   o
                dc.w    $810, $168, $1010, $168, $8001, $FFFF
Valkirie_StateAAndCPoses:   dc.w    $E12, $154, $8001, $808, $154, $E12, $17C, $8001, $707, $17C, $FFFE  ; was: word_5628E
                                        ; Entity_UpdateValkirieBattleStateC+10   o
Valkirie_State22Poses:  dc.w    $101C, $1CC, $808, $1CC, $8081, $50C, $190, $808, $190, $101C, $1A4, $707, $1A4, $8082, $80C, $1B8  ; was: word_562A4
                dc.w    $606, $1B8, $FFFF
Valkirie_State14Poses:  dc.w    $840, $28, $1018, $1E0, $1818, $1E0, $840, $1F4, $8001, $A0E, $1F4, $606, $1F4, $8008, $507, $208  ; was: word_562CA
                dc.w    $808, $208, $FFFE
Valkirie_State24Poses:      dc.w    $4058, $21C, $7070, $21C, $FFFF  ; was: word_562F0
Valkirie_State18To1EPoses:  dc.w    $1020, $F0, $712, $244, $A0A, $244, $8001, $1258, $258, $608, $258, $8001, $3838, $258, $1870, $26C  ; was: word_562FA
                                        ; Entity_UpdateValkirieBattleState18+1E   o
                dc.w    $8001, $3232, $26C, $FFFE
Valkirie_State20Poses:              dc.w    $A10, $280, $1313, $280, $815, $26C, $FFFE  ; was: word_56322
Valkirie_AirbornePattern00Poses:    dc.w    $1010, $3C, $210, $50, $8003, $204, $50, $505, $50, $8004, $1418, $3C, $8008, $1818, $17C, $FFFE  ; was: word_56330
Valkirie_AirbornePattern01Poses:    dc.w    $1010, $3C, $210, $64, $8003, $204, $64, $404, $64, $8004, $1418, $3C, $8008, $1818, $17C, $FFFE  ; was: word_56350
Valkirie_AirbornePattern02Poses:    dc.w    $1A1A, $78, $420, $8C, $8003, $508, $8C, $808, $8C, $8004, $101A, $78, $8008, $1212, $17C, $FFFE  ; was: word_56370
Valkirie_State12Poses:              dc.w    $408, $F0, $204, $F0, $303, $F0, $106, $12C, $8001, $204, $12C, $303, $12C, $8002, $306, $F0  ; was: word_56390
                                        ; Entity_UpdateValkirieBattleState12+54   o
                dc.w    $204, $F0, $202, $F0, $106, $104, $8001, $204, $104, $303, $104, $8002, $106, $F0, $103, $F0
                dc.w    $202, $F0, $106, $104, $8001, $204, $118, $303, $118, $8002, $FFFF
Valkirie_PoseTable: binclude "data/other/word_563E6.bin"  ; was: word_563E6
Valkirie_PoseFrameDataEnd:                              ; was: word_563E6_End

; Create and initialize the six-object auxiliary Valkirie group
Entity_InitValkirieAuxiliaryGroup:                      ; was: sub_566B6
                                        ; Entity_StartValkirieBattleState14+26   p
                movea.w #(TwentySeventhEntityType-M68K_RAM),a0
                moveq   #5,d7
Entity_ClearValkirieAuxiliaryGroupLoop:                 ; was: loc_566BC
                jsr     (Object_ClearRecord96Bytes).l
                dbf     d7,Entity_ClearValkirieAuxiliaryGroupLoop
                movea.w #(TwentySeventhEntityType-M68K_RAM),a5
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #5,d7
                movea.l #Boss_ValkirieAuxiliaryMetaspritePartDescriptors,a0
                movea.l #Boss_ValkirieAuxiliaryMetaspriteInitialAngles,a1
                movea.l #Boss_ValkirieAuxiliaryMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$47C,(a5)
                move.w  #$8C00,2(a5)
                move.w  #$65,$206(a5)                   ; 'e'
                move.l  #$F808F808,$20C(a5)
                move.l  #$F010F010,$208(a5)
                move.b  #3,(ValkirieAuxFlags).w
                movea.w a5,a0
                movea.w #(Entity_ObjectPool-M68K_RAM),a5
                rts
; End of function Entity_InitValkirieAuxiliaryGroup
; Update the auxiliary group while attached, launching, or tracking a target
Entity_UpdateValkirieAuxiliaryGroup:                    ; was: sub_5671A
                btst    #1,(ValkirieAuxFlags).w
                beq.w   Entity_UpdateDetachedValkirieAuxiliaryGroup
                bclr    #4,(ValkirieAuxFlags).w
                beq.s   Entity_SyncValkirieAuxiliaryGroup
                bclr    #1,(ValkirieAuxFlags).w
                move.w  #$D00,$1E2(a5)
                move.b  #$C0,$201(a5)
                move.b  #$10,$203(a5)
                move.w  #$D1C0,$48(a5)
                move.w  #$D1C0,$4A(a5)
                move.l  #$48000,d0
                clr.w   $23C(a5)
                tst.w   $54(a5)
                bne.s   Entity_LaunchValkirieAuxiliaryGroup
                neg.l   d0
                move.w  #$100,$23C(a5)
Entity_LaunchValkirieAuxiliaryGroup:                    ; was: loc_56768
                move.l  d0,$1F8(a5)
                bra.w   Entity_UpdateValkirieAuxiliaryAnchors
; ---------------------------------------------------------------------------
Entity_SyncValkirieAuxiliaryGroup:                      ; was: loc_56770
                                        ; Entity_UpdateValkirieAuxiliaryGroup+108   j
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  $54(a0),$54(a5)
                move.w  #$D160,$48(a5)
                move.w  #$D160,$4A(a5)
                move.w  $4F0(a0),$190(a5)
                move.w  $4F4(a0),$194(a5)
                move.w  $536(a0),$56(a5)
                bsr.w   Entity_UpdateValkirieAuxiliaryAnchors
                moveq   #8,d5
                move.w  #$1F8,d6
                btst    #0,(ValkirieAuxFlags).w
                bne.s   Entity_RotateValkirieAuxiliaryGroupForward
                cmpi.w  #$100,$B6(a5)
                beq.w   Entity_UpdateValkirieAuxiliaryGroupReturn
                sub.w   d5,$B6(a5)
                and.w   d6,$B6(a5)
                move.w  $B6(a5),$116(a5)
                add.w   d5,$176(a5)
                and.w   d6,$176(a5)
                move.w  $176(a5),$1D6(a5)
                rts
; ---------------------------------------------------------------------------
Entity_RotateValkirieAuxiliaryGroupForward:             ; was: loc_567D2
                cmpi.w  #$140,$B6(a5)
                beq.w   Entity_UpdateValkirieAuxiliaryGroupReturn
                add.w   d5,$B6(a5)
                and.w   d6,$B6(a5)
                move.w  $B6(a5),$116(a5)
                sub.w   d5,$176(a5)
                and.w   d6,$176(a5)
                move.w  $176(a5),$1D6(a5)
                cmpi.w  #$140,$B6(a5)
                bne.w   Entity_UpdateValkirieAuxiliaryGroupReturn
                rts
; ---------------------------------------------------------------------------
Entity_UpdateDetachedValkirieAuxiliaryGroup:            ; was: loc_56804
                bclr    #5,(ValkirieAuxFlags).w
                beq.s   Entity_AdvanceValkirieAuxiliaryAngle
                bset    #1,(ValkirieAuxFlags).w
                clr.w   $1E2(a5)
                move.b  #$80,$201(a5)
                move.b  #$10,$203(a5)
                bra.w   Entity_SyncValkirieAuxiliaryGroup
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieAuxiliaryAngle:                   ; was: loc_56826
                move.w  $56(a5),d1
                addi.w  #$20,d1                         ; ' '
                andi.w  #$1E0,d1
                move.w  d1,$56(a5)
                bne.s   Entity_UpdateValkirieAuxiliaryFlashTimer
                move.b  #$C6,d0
                jsr     (Sound_QueueSFXRequest).l
Entity_UpdateValkirieAuxiliaryFlashTimer:               ; was: loc_56842
                move.w  #$100,d1
                move.w  d1,$236(a5)
                subq.w  #1,$5C(a5)
                bne.s   Entity_ClampValkirieAuxiliaryFlashTimer
                bset    #6,$21(a5)
                bra.s   Entity_TrackValkirieAuxiliaryTarget
; ---------------------------------------------------------------------------
Entity_ClampValkirieAuxiliaryFlashTimer:                ; was: loc_56858
                bpl.s   Entity_TrackValkirieAuxiliaryTarget
                move.w  #$FFFF,$5C(a5)
Entity_TrackValkirieAuxiliaryTarget:                    ; was: loc_56860
                                        ; Entity_UpdateValkirieAuxiliaryGroup:Entity_ClampValkirieAuxiliaryFlashTimer   j
                bsr.w   Entity_UpdateValkirieAuxiliaryAnchors
                move.w  (PrimaryCameraXPosition).w,d1
                add.w   $10(a5),d1
                move.w  $23C(a5),d2
                btst    #7,(ValkirieAuxFlags).w
                beq.s   Entity_AdjustValkirieAuxiliaryVelocity
                bsr.w   Entity_AimValkirieAuxiliaryAtPlayer
Entity_AdjustValkirieAuxiliaryVelocity:                 ; was: loc_5687C
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d2.w),d0
                move.w  (a1,d2.w),d1
                ext.l   d0
                ext.l   d1
                move.l  d0,d2
                move.l  d1,d3
                asl.l   #3,d2
                asl.l   #3,d3
                tst.l   d2
                bmi.s   Entity_AdjustValkirieAuxiliaryNegativeVerticalVelocity
                add.l   d0,$1FC(a5)
                bmi.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity
                cmp.l   $1FC(a5),d2
                bpl.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity
                move.l  d2,$1FC(a5)
                bra.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity
; ---------------------------------------------------------------------------
Entity_AdjustValkirieAuxiliaryNegativeVerticalVelocity:  ; was: loc_568AC
                add.l   d0,$1FC(a5)
                bpl.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity
                cmp.l   $1FC(a5),d2
                bmi.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity
                move.l  d2,$1FC(a5)
Entity_AdjustValkirieAuxiliaryHorizontalVelocity:       ; was: loc_568BC
                                        ; Entity_UpdateValkirieAuxiliaryGroup+18A   j
                tst.l   d3
                bmi.s   Entity_AdjustValkirieAuxiliaryNegativeHorizontalVelocity
                add.l   d1,$1F8(a5)
                bmi.s   Entity_UpdateValkirieAuxiliaryGroupReturn
                cmp.l   $1F8(a5),d3
                bpl.s   Entity_UpdateValkirieAuxiliaryGroupReturn
                move.l  d3,$1F8(a5)
                rts
; ---------------------------------------------------------------------------
Entity_AdjustValkirieAuxiliaryNegativeHorizontalVelocity:  ; was: loc_568D2
                add.l   d1,$1F8(a5)
                bpl.s   Entity_UpdateValkirieAuxiliaryGroupReturn
                cmp.l   $1F8(a5),d3
                bmi.s   Entity_UpdateValkirieAuxiliaryGroupReturn
                move.l  d3,$1F8(a5)
Entity_UpdateValkirieAuxiliaryGroupReturn:              ; was: locret_568E2
                                        ; Entity_UpdateValkirieAuxiliaryGroup+BE   j
                rts
; End of function Entity_UpdateValkirieAuxiliaryGroup
; Select fast positive or negative horizontal velocity from field $23E
Entity_SetValkirieAuxiliaryFastHorizontalVelocity:      ; was: sub_568E4
                tst.w   $23E(a5)
                beq.s   Entity_SetValkirieAuxiliaryFastNegativeVelocity
                move.l  #$2C000,$1F8(a5)
                rts
; ---------------------------------------------------------------------------
Entity_SetValkirieAuxiliaryFastNegativeVelocity:        ; was: loc_568F4
                move.l  #$FFFD4000,$1F8(a5)
                rts
; End of function Entity_SetValkirieAuxiliaryFastHorizontalVelocity
; Clear the part flag, arm its timer, and select a slower horizontal velocity
Entity_SetValkirieAuxiliarySlowHorizontalVelocity:      ; was: sub_568FE
                bclr    #6,$21(a5)
                move.w  #4,$5C(a5)
                tst.w   $23E(a5)
                beq.s   Entity_SetValkirieAuxiliarySlowNegativeVelocity
                move.l  #$12000,$1F8(a5)
                rts
; ---------------------------------------------------------------------------
Entity_SetValkirieAuxiliarySlowNegativeVelocity:        ; was: loc_5691A
                move.l  #$FFFEE000,$1F8(a5)
                rts
; End of function Entity_SetValkirieAuxiliarySlowHorizontalVelocity
; Updates the five-part group between Valkirie's two anchor objects
Entity_UpdateValkirieAuxiliaryAnchors:                  ; was: sub_56924
                                        ; Entity_UpdateValkirieAuxiliaryGroup+7E   p
                moveq   #4,d7
                jmp     Boss_ValkirieUpdateAnchoredMetasprite
; End of function Entity_UpdateValkirieAuxiliaryAnchors
; Calculate the direction from the auxiliary anchor to the player
Entity_AimValkirieAuxiliaryAtPlayer:                    ; was: sub_5692C
                move.w  (FourteenthEntityXPos).w,d0
                move.w  (FourteenthEntityYPos).w,d1
                sub.w   $1F0(a5),d0
                sub.w   $1F4(a5),d1
                jmp     (Math_CalculateDirectionIndex).l
; End of function Entity_AimValkirieAuxiliaryAtPlayer
; Restore the shared Seven Force colors or apply the caller-selected flash set
Gfx_UpdateSevenForceBattlePalette:                      ; was: sub_56942
                                        ; Boss_UpdateMedusa+3A   p
                btst    #0,(FrameCounter+1).w
                bne.s   Gfx_ApplySevenForceBattleFlashPalette
                move.w  (PaletteShadowColor61).w,(PaletteActiveColor61).w
                move.w  (PaletteShadowColor62).w,(PaletteActiveColor62).w
                move.w  (PaletteShadowColor63).w,(PaletteActiveColor63).w
                rts
; ---------------------------------------------------------------------------
Gfx_ApplySevenForceBattleFlashPalette:                  ; was: loc_5695E
                move.w  SevenForce_BattleFlashPaletteColors(pc,d0.w),(PaletteActiveColor61).w
                move.w  SevenForce_BattleFlashPaletteColors+2(pc,d0.w),(PaletteActiveColor62).w
                move.w  SevenForce_BattleFlashPaletteColors+4(pc,d0.w),(PaletteActiveColor63).w
                rts
; End of function Gfx_UpdateSevenForceBattlePalette
; ---------------------------------------------------------------------------
SevenForce_BattleFlashPaletteColors:    binclude "data/palettes/056972.bin"  ; was: word_56972
                                        ; Gfx_UpdateSevenForceBattlePalette+22   r
