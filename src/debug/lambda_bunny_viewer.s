Debug_LambdaBunnyViewerMain:                            ; was: sub_50FA6
                tst.w   4(a5)
                beq.w   Debug_LambdaBunnyViewerDispatchState
                tst.w   8(a5)
                beq.s   Debug_LambdaBunnyViewerDispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
Debug_LambdaBunnyViewerDispatchState:                   ; was: loc_50FBA
                                        ; Debug_LambdaBunnyViewerMain+C   j
                move.w  4(a5),d0
                movea.w Debug_LambdaBunnyViewerStateTable(pc,d0.w),a0
                adda.l  #Debug_LambdaBunnyViewerIdle,a0
                jmp     (a0)
; End of function Debug_LambdaBunnyViewerMain
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerStateTable:  dc.w    Debug_LambdaBunnyViewerInitialize-Debug_LambdaBunnyViewerIdle  ; was: off_50FCA
                dc.w    Debug_LambdaBunnyViewerUpdate-Debug_LambdaBunnyViewerIdle

Debug_LambdaBunnyViewerIdle:                            ; was: nullsub_119
                                        ; Debug_LambdaBunnyViewerFaceLeft+4   j
                rts
; End of function Debug_LambdaBunnyViewerIdle

; Initialize Lambda Bunny (entity type $3EC) as a pad-driven pose viewer
Debug_LambdaBunnyViewerInitialize:                      ; was: sub_50FD0
                tst.w   (DataLoaderControl).w
                bmi.w   Debug_LambdaBunnyViewerIdle
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$14,d7
                movea.l #Boss_ValkirieMetaspriteDescriptors,a0
                movea.l #Boss_ValkiriePartRadii,a1
                movea.l #Boss_ValkiriePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$3EC,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                move.w  #0,$176(a5)
                move.w  #$100,$356(a5)
                move.w  #$10,d0
                move.w  #$4300,d1
                move.w  #$C000,d2
                move.w  d0,$7E0(a5)
                move.w  d2,$7E2(a5)
                move.w  d1,$7EE(a5)
                move.b  #$20,$800(a5)                   ; ' '
                move.l  #Debug_LambdaBunnyViewerPartPairMappingA,$7E8(a5)
                move.w  d0,$840(a5)
                move.w  d2,$842(a5)
                move.w  d1,$84E(a5)
                move.b  #$1C,$860(a5)
                move.l  #Debug_LambdaBunnyViewerPartPairMappingC,$848(a5)
                move.w  d0,$8A0(a5)
                move.w  d2,$8A2(a5)
                move.w  d1,$8AE(a5)
                move.b  #$28,$8C0(a5)                   ; '('
                move.l  #Debug_LambdaBunnyViewerPartPairMappingA,$8A8(a5)
                move.w  d0,$900(a5)
                move.w  d2,$902(a5)
                move.w  d1,$90E(a5)
                move.b  #$24,$920(a5)                   ; '$'
                move.l  #Debug_LambdaBunnyViewerPartPairMappingC,$908(a5)
                move.w  #$C300,d1
                move.w  d0,$960(a5)
                move.w  d2,$962(a5)
                move.w  d1,$96E(a5)
                move.b  #$18,$980(a5)
                move.l  #Debug_LambdaBunnyViewerFixedPartMapping,$968(a5)
                move.w  d0,$9C0(a5)
                move.w  d2,$9C2(a5)
                move.w  d1,$9CE(a5)
                move.b  #$18,$9E0(a5)
                move.l  #Debug_LambdaBunnyViewerExtendedGunMapping,$9C8(a5)
                movea.l #Debug_LambdaBunnyViewerObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                bsr.w   Debug_LambdaBunnyViewerLoadLeftTiles
                bra.w   *+4
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerConfigureInteractiveState:       ; was: loc_510DA
                move.w  #2,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$CD40,$48(a5)
                move.w  #$120,$730(a5)
                move.w  #$CF20,$4A(a5)
                move.w  #$148,$914(a5)
; Interactive viewer update: facing, angle, pose, linked parts, and screen anchor
Debug_LambdaBunnyViewerUpdate:                          ; was: loc_51116
                tst.w   (MessageSequenceState).w
                bne.s   Debug_LambdaBunnyViewerProcessFacingInput
                move.b  #1,(SceneSequenceFlags).w
Debug_LambdaBunnyViewerProcessFacingInput:              ; was: loc_51122
                btst    #6,(ControllerHeldState).w
                beq.s   Debug_LambdaBunnyViewerCheckFaceRightInput
                bsr.w   Debug_LambdaBunnyViewerFaceLeft
Debug_LambdaBunnyViewerCheckFaceRightInput:             ; was: loc_5112E
                btst    #5,(ControllerHeldState).w
                beq.s   Debug_LambdaBunnyViewerCheckAngleIncreaseInput
                bsr.w   Debug_LambdaBunnyViewerFaceRight
Debug_LambdaBunnyViewerCheckAngleIncreaseInput:         ; was: loc_5113A
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_LambdaBunnyViewerCheckAngleDecreaseInput
                addq.b  #1,$29F(a5)
Debug_LambdaBunnyViewerCheckAngleDecreaseInput:         ; was: loc_51146
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_LambdaBunnyViewerPreparePoseUpdate
                subq.b  #1,$29F(a5)
Debug_LambdaBunnyViewerPreparePoseUpdate:               ; was: loc_51152
                andi.w  #$1FE,$56(a5)
                lea     Debug_LambdaBunnyViewerPoses(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerUpdatePoseAndParts:              ; was: loc_51162
                bsr.w   Debug_LambdaBunnyViewerAdvancePoseScript
                moveq   #$14,d7
                jsr     (Sprite_SetMetaspriteTraversalPointers).l
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.w  #$FFF3,d7
                tst.w   $54(a5)
                beq.s   Debug_LambdaBunnyViewerPositionUpperPartPair
                neg.w   d7
Debug_LambdaBunnyViewerPositionUpperPartPair:           ; was: loc_5117E
                move.w  d7,d0
                add.w   $640(a5),d0
                move.w  d0,$820(a5)
                move.w  d0,$880(a5)
                move.l  #Debug_LambdaBunnyViewerPartPairMappingA,$7E8(a5)
                move.b  $38(a0),d0
                ext.w   d0
                cmpi.w  #4,d0
                bmi.s   Debug_LambdaBunnyViewerStoreUpperPartPairPosition
                move.l  #Debug_LambdaBunnyViewerPartPairMappingB,$7E8(a5)
Debug_LambdaBunnyViewerStoreUpperPartPairPosition:      ; was: loc_511A8
                add.w   $644(a5),d0
                addi.w  #$28,d0                         ; '('
                move.w  d0,$824(a5)
                move.w  d0,$884(a5)
                move.w  d7,d0
                add.w   $7C0(a5),d0
                move.w  d0,$8E0(a5)
                move.w  d0,$940(a5)
                move.l  #Debug_LambdaBunnyViewerPartPairMappingA,$8A8(a5)
                move.b  $3C(a0),d0
                ext.w   d0
                cmpi.w  #4,d0
                bmi.s   Debug_LambdaBunnyViewerStoreLowerPartPairPosition
                move.l  #Debug_LambdaBunnyViewerPartPairMappingB,$8A8(a5)
Debug_LambdaBunnyViewerStoreLowerPartPairPosition:      ; was: loc_511E2
                add.w   $7C4(a5),d0
                addi.w  #$28,d0                         ; '('
                move.w  d0,$8E4(a5)
                move.w  d0,$944(a5)
                moveq   #$18,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bclr    #4,$54E(a5)
                bclr    #4,$6CE(a5)
                moveq   #6,d5
                tst.w   $54(a5)
                beq.s   Debug_LambdaBunnyViewerPositionGun
                neg.w   d5
Debug_LambdaBunnyViewerPositionGun:                     ; was: loc_51210
                add.w   $D0(a5),d5
                move.w  $D4(a5),d6
                addi.w  #-8,d6
                move.b  $29F(a5),d3
                cmpi.b  #$70,d3                         ; 'p'
                bmi.s   Debug_LambdaBunnyViewerPositionExtendedGun
                addi.w  #2,d5
                addi.w  #-6,d6
                move.w  d5,$970(a5)
                move.w  d6,$974(a5)
                bsr.w   Debug_LambdaBunnyViewerUpdateGunMapping
                bra.w   Debug_LambdaBunnyViewerUpdateScreenAnchor
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerPositionExtendedGun:             ; was: loc_5123E
                lea     (Math_SineTable).l,a0
                move.l  #Debug_LambdaBunnyViewerExtendedGunMapping,$9C8(a5)
                bset    #3,$9CE(a5)
                move.w  #$1A0,d7
                tst.w   $54(a5)
                beq.s   Debug_LambdaBunnyViewerCalculateExtendedGunOffsets
                bclr    #3,$9CE(a5)
                move.w  #$160,d7
Debug_LambdaBunnyViewerCalculateExtendedGunOffsets:     ; was: loc_51266
                move.w  -$80(a0,d7.w),d1
                move.w  (a0,d7.w),d2
                ext.w   d3
                muls.w  d3,d1
                muls.w  d3,d2
                move.l  d1,$9D4(a5)
                move.l  d2,$9D0(a5)
                asr.l   #2,d1
                asr.l   #2,d2
                move.l  d1,$974(a5)
                move.l  d2,$970(a5)
                add.w   d5,$970(a5)
                add.w   d6,$974(a5)
                addq.w  #4,d5
                addi.w  #-$C,d6
                add.w   d5,$9D0(a5)
                add.w   d6,$9D4(a5)
Debug_LambdaBunnyViewerUpdateScreenAnchor:              ; was: loc_5129E
                move.w  #$A7,d0
                tst.w   $54(a5)
                beq.s   Debug_LambdaBunnyViewerStoreScreenAnchor
                move.w  #$97,d0
Debug_LambdaBunnyViewerStoreScreenAnchor:               ; was: loc_512AC
                sub.w   $70(a5),d0
                move.w  $74(a5),d1
                addi.w  #$3C,d1                         ; '<'
                move.w  d0,(SecondaryCameraXPos).w
                move.w  d1,(SecondaryCameraYPos).w
                jsr     (Boss_ClampSharedScreenPosition).l
                rts
; End of function Debug_LambdaBunnyViewerInitialize
; Face the composite sprite left and load its left-facing tiles
Debug_LambdaBunnyViewerFaceLeft:                        ; was: sub_512C8
                tst.w   $54(a5)
                beq.w   Debug_LambdaBunnyViewerIdle
                clr.w   $54(a5)
                moveq   #3,d0
                bclr    d0,$E(a5)
                bclr    d0,$CE(a5)
                bclr    d0,$60E(a5)
                bclr    d0,$78E(a5)
                bclr    d0,$5AE(a5)
                bclr    d0,$72E(a5)
                bclr    d0,$7EE(a5)
                bclr    d0,$84E(a5)
                bclr    d0,$8AE(a5)
                bclr    d0,$90E(a5)
                bclr    d0,$96E(a5)
                bra.w   Debug_LambdaBunnyViewerLoadLeftTiles
; End of function Debug_LambdaBunnyViewerFaceLeft
; Face the composite sprite right and load its right-facing tiles
Debug_LambdaBunnyViewerFaceRight:                       ; was: sub_51306
                tst.w   $54(a5)
                bne.w   Debug_LambdaBunnyViewerIdle
                move.w  #$100,$54(a5)
                moveq   #3,d0
                bset    d0,$E(a5)
                bset    d0,$CE(a5)
                bset    d0,$60E(a5)
                bset    d0,$78E(a5)
                bset    d0,$5AE(a5)
                bset    d0,$72E(a5)
                bset    d0,$7EE(a5)
                bset    d0,$84E(a5)
                bset    d0,$8AE(a5)
                bset    d0,$90E(a5)
                bset    d0,$96E(a5)
                lea     Debug_LambdaBunnyViewerRightHeadColumns(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Debug_LambdaBunnyViewerFaceRight
; Load the viewer's left-facing tile set
Debug_LambdaBunnyViewerLoadLeftTiles:                   ; was: sub_5134E
                                        ; Debug_LambdaBunnyViewerFaceLeft+3A   j
                lea     Debug_LambdaBunnyViewerLeftHeadColumns(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Debug_LambdaBunnyViewerLoadLeftTiles
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerRightHeadColumns:    dc.w    $6100, $2000, $102, $2829, $2A2B, $2C2D  ; was: word_5135A
Debug_LambdaBunnyViewerLeftHeadColumns:     dc.w    $6100, $2000, $102, $8A89, $8C8B, $8E8D  ; was: word_51366

; Copy the gun-part transform and select its mapping from the aiming angle
Debug_LambdaBunnyViewerUpdateGunMapping:                ; was: sub_51372
                move.w  $2B0(a5),$9D0(a5)
                move.w  $2B4(a5),$9D4(a5)
                move.w  $2AE(a5),$9CE(a5)
                move.w  $2F6(a5),d0
                addi.w  #$10,d0
                asr.w   #3,d0
                andi.w  #$1C,d0
                move.l  Debug_LambdaBunnyViewerGunMappingTable(pc,d0.w),$9C8(a5)
                rts
; End of function Debug_LambdaBunnyViewerUpdateGunMapping
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerGunMappingTable: dc.l    Debug_LambdaBunnyViewerGunMapping0  ; was: off_5139A
                dc.l    Debug_LambdaBunnyViewerGunMapping1
                dc.l    Debug_LambdaBunnyViewerGunMapping2
                dc.l    Debug_LambdaBunnyViewerGunMapping3
                dc.l    Debug_LambdaBunnyViewerGunMapping4
                dc.l    Debug_LambdaBunnyViewerGunMapping5
                dc.l    Debug_LambdaBunnyViewerGunMapping6
                dc.l    Debug_LambdaBunnyViewerGunMapping7

; Interpret pose commands and update all sixteen composite-part values
Debug_LambdaBunnyViewerAdvancePoseScript:               ; was: sub_513BA
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Debug_LambdaBunnyViewerTickPoseInterpolation
Debug_LambdaBunnyViewerReadNextPoseCommand:             ; was: loc_513C4
                                        ; Debug_LambdaBunnyViewerAdvancePoseScript+44   j
                move.w  $58(a5),d0
                bmi.w   Debug_LambdaBunnyViewerStorePoseComponents
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Debug_LambdaBunnyViewerCheckPoseControlCommand
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Debug_LambdaBunnyViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerCheckPoseControlCommand:         ; was: loc_513E0
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Debug_LambdaBunnyViewerHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerHandlePoseLoopCommand:           ; was: loc_513F0
                cmpi.w  #$FFFF,d3
                bne.s   Debug_LambdaBunnyViewerBeginPoseCommandInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Debug_LambdaBunnyViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerBeginPoseCommandInterpolation:   ; was: loc_51400
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Debug_LambdaBunnyViewerPoseTable,d0
                movea.l d0,a0
                bsr.w   Debug_LambdaBunnyViewerBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Debug_LambdaBunnyViewerStorePoseComponents
Debug_LambdaBunnyViewerTickPoseInterpolation:           ; was: loc_51432
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$10,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Debug_LambdaBunnyViewerStorePoseComponents:             ; was: loc_51442
                                        ; Debug_LambdaBunnyViewerAdvancePoseScript+76   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                move.b  8(a0),d0
                ext.w   d0
                addq.w  #6,d0
                move.w  d0,$B4(a5)
                move.b  $C(a0),d0
                ext.w   d0
                addi.w  #8,d0
                move.w  d0,$114(a5)
                move.b  $10(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                move.w  d0,$236(a5)
                move.b  $14(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$296(a5)
                move.w  d1,$2F6(a5)
                move.b  $18(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                move.w  d0,$416(a5)
                move.b  $1C(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$476(a5)
                move.w  d1,$4D6(a5)
                move.b  $20(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$536(a5)
                move.b  $24(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                move.w  d0,$5F6(a5)
                move.w  d0,$656(a5)
                move.b  $28(a0),d0
                ext.w   d0
                move.w  d0,$654(a5)
                move.b  $2C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$6B6(a5)
                move.b  $30(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                move.w  d0,$776(a5)
                move.w  d0,$7D6(a5)
                move.b  $34(a0),d0
                ext.w   d0
                move.w  d0,$7D4(a5)
                rts
; End of function Debug_LambdaBunnyViewerAdvancePoseScript
; Initialize interpolation deltas for the next viewer pose command
Debug_LambdaBunnyViewerBeginPoseInterpolation:          ; was: sub_51514
                lea     Debug_LambdaBunnyViewerPoseBaseValues(pc),a1
                nop
                moveq   #$10,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Debug_LambdaBunnyViewerBeginPoseInterpolation
; Initialize the viewer's seventeen fixed-point pose channels from bytes at a0
Debug_LambdaBunnyViewerInitializePoseChannels:          ; was: sub_5152A
                moveq   #$10,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Debug_LambdaBunnyViewerInitializePoseChannels
; ---------------------------------------------------------------------------
Debug_LambdaBunnyViewerPoseBaseValues:  dc.b    $40, $C0, $80, $80, $A0, $80, $A0, $80, $80, $A0, $80, 0, $A0, $80, $80, $80  ; was: byte_51536
Debug_LambdaBunnyViewerPoses:           dc.b    $10, $18, 0, 0, $10, $10, 0, 0, $10, $18, 0, $10, $20, $20, 0, $10  ; was: byte_51546
                dc.b    $FF, $FF, 8, $C, 0, $20, $12, $12, 0, $20, 2, 4, 0, $30, 9, 9
                dc.b    0, $30, $10, $30, 0, $20, $FF, $FE
Debug_LambdaBunnyViewerPoseTable:   dc.b    $BC, $4A, $11, $F, $2C, $98, $78, $A8, $E8, $36, 3, $90, $54, 4, 2, 3  ; was: byte_5156E
                dc.b    $CA, $41, $E, $12, $30, $96, $78, $AC, $D8, $1A, $FC, $A0, $3A, $FC, $A, 0
                dc.b    $C0, $46, $10, $12, 8, $F8, $50, $18, $E0, $50, 4, $A0, $20, 4, 0, 4
                dc.b    $B8, $3C, $11, $F, $F8, $C8, $48, 8, $C0, $40, $FC, $A0, $14, 4, 0, 6
