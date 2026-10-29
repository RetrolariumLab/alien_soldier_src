; Flying Neo linked-part orientation, facing graphics, and pose interpolation

Boss_FlyingNeoUpdateOrbitAngularImpulse:                ; was: sub_3CDAE
                clr.w   $23E(a5)
                move.w  $536(a5),d0
                andi.w  #$3FC,d0
                move.w  (RandomNumberState).w,d1
                andi.w  #$F,d1
                beq.s   Boss_FlyingNeoOrbitAngularImpulseReturn
                tst.w   $17C(a5)
                bne.s   Boss_FlyingNeoUpdateEnabledOrbitImpulsePhase
                cmpi.w  #$200,d0
                bmi.s   Boss_FlyingNeoSetNegativeOrbitAngularImpulse
                cmpi.w  #$340,d0
                bpl.s   Boss_FlyingNeoTryEnableOrbitImpulsePhase
Boss_FlyingNeoEnableOrbitImpulsePhase:                  ; was: loc_3CDD6
                addq.w  #2,$17C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoTryEnableOrbitImpulsePhase:               ; was: loc_3CDDC
                andi.w  #3,d1
                beq.s   Boss_FlyingNeoEnableOrbitImpulsePhase
Boss_FlyingNeoSetNegativeOrbitAngularImpulse:           ; was: loc_3CDE2
                move.w  #$FFE0,$23E(a5)
Boss_FlyingNeoOrbitAngularImpulseReturn:                ; was: locret_3CDE8
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateEnabledOrbitImpulsePhase:           ; was: loc_3CDEA
                cmpi.w  #$200,d0
                bpl.s   Boss_FlyingNeoSetPositiveOrbitAngularImpulse
                cmpi.w  #$C0,d0
                bmi.s   Boss_FlyingNeoApplyLowAngleOrbitPhaseGate
Boss_FlyingNeoDisableOrbitImpulsePhase:                 ; was: loc_3CDF6
                clr.w   $17C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoApplyLowAngleOrbitPhaseGate:              ; was: loc_3CDFC
                moveq   #3,d2
                btst    #0,(FrameCounter).w
                beq.s   Boss_FlyingNeoTestLowAngleOrbitPhaseGate
                moveq   #7,d2
Boss_FlyingNeoTestLowAngleOrbitPhaseGate:               ; was: loc_3CE08
                and.w   d2,d1
                beq.s   Boss_FlyingNeoDisableOrbitImpulsePhase
Boss_FlyingNeoSetPositiveOrbitAngularImpulse:           ; was: loc_3CE0C
                move.w  #$20,$23E(a5)                   ; ' '
                rts
; End of function Boss_FlyingNeoUpdateOrbitAngularImpulse
; Applies the current facing to linked-part flags and loads its tile set
Boss_FlyingNeoApplyFacingGraphics:                      ; was: sub_3CE14
                                        ; Boss_FlyingNeoPlayerControlled+50   p
                moveq   #3,d0
                movea.w #(TwelfthEntityType-M68K_RAM),a0
                moveq   #8,d7
                tst.w   $54(a5)
                bne.w   Boss_FlyingNeoApplyNonzeroFacingGraphics
                move.l  #$E01CD42E,$28(a5)
                bset    d0,$3CE(a5)
                bclr    d0,$6E(a5)
                move.w  #$E2F4,$6A(a5)
                bset    d0,$12E(a5)
                bset    d0,$2AE(a5)
                bset    d0,$1EE(a5)
                bset    d0,$36E(a5)
Boss_FlyingNeoClearLinkedPartFlipBits:                  ; was: loc_3CE4A
                bclr    d0,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_FlyingNeoClearLinkedPartFlipBits
                lea     Boss_FlyingNeoZeroFacingTileCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Boss_FlyingNeoApplyNonzeroFacingGraphics:               ; was: loc_3CE62
                move.l  #$E01CF040,$28(a5)
                bclr    d0,$3CE(a5)
                bset    d0,$6E(a5)
                move.w  #$F4,$6A(a5)
                bclr    d0,$12E(a5)
                bclr    d0,$2AE(a5)
                bclr    d0,$1EE(a5)
                bclr    d0,$36E(a5)
; Sets the flip bit on all linked parts and loads the nonzero-facing tiles
Boss_FlyingNeoSetLinkedPartFlipBits:                    ; was: loc_3CE88
                bset    d0,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_FlyingNeoSetLinkedPartFlipBits
                lea     Boss_FlyingNeoNonzeroFacingTileCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_FlyingNeoApplyFacingGraphics
; ---------------------------------------------------------------------------
Boss_FlyingNeoDefeatTileCommand:        dc.w    $6C0C, $4000, $301, $5656, $5656, $5656, $5656  ; was: word_3CEA0
Boss_FlyingNeoZeroFacingTileCommand:    dc.w    $6C0C, $2000, $301, $3031, $3233, $3435, $3637  ; was: word_3CEAE
Boss_FlyingNeoNonzeroFacingTileCommand: dc.w    $6C0C, $2000, $301, $3839, $3A3B, $373D, $3E3F  ; was: word_3CEBC

; Initializes consecutive auxiliary sprite records from six-byte descriptors
Boss_FlyingNeoInitializeAuxiliarySprites:               ; was: sub_3CECA
                                        ; Boss_FlyingNeoSetup+A8   p
                move.w  d0,(a0)
                move.b  #$18,$20(a0)
                move.w  d2,2(a0)
                move.w  (a1),$E(a0)
                move.w  2(a1),8(a0)
                move.w  4(a1),$A(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_FlyingNeoInitializeAuxiliarySprites
                rts
; End of function Boss_FlyingNeoInitializeAuxiliarySprites
; ---------------------------------------------------------------------------
Boss_FlyingNeoAuxiliarySpriteDescriptorA:   dc.w    $6386, $A00, $F4F4  ; was: word_3CEF0
Boss_FlyingNeoAuxiliarySpriteDescriptorB:   dc.w    $638F, $500, $F8F8  ; was: word_3CEF6
Boss_FlyingNeoAuxiliarySpriteDescriptorC:   dc.w    $6393, $500, $F8F8  ; was: word_3CEFC
Boss_FlyingNeoAuxiliarySpriteDescriptorD:   dc.w    $6397, 0, $FCFC  ; was: word_3CF02

Boss_FlyingNeoNoOp:                                     ; was: nullsub_78
                rts
; End of function Boss_FlyingNeoNoOp

; Interprets pose commands, advances four interpolation channels, and publishes their angles
Boss_FlyingNeoUpdatePoseAnimation:                      ; was: sub_3CF0A
                                        ; Boss_FlyingNeoPlayerControlled+72   p
                clr.w   $A(a5)
                tst.w   $C(a5)
                bpl.s   Boss_FlyingNeoAdvancePoseInterpolation
Boss_FlyingNeoReadPoseCommand:                          ; was: loc_3CF14
                move.w  $58(a5),d0
                bmi.w   Boss_FlyingNeoApplyPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_FlyingNeoDecodePoseCommand
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_FlyingNeoDecodePoseCommand:                        ; was: loc_3CF36
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_FlyingNeoCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoCheckPoseLoopCommand:                     ; was: loc_3CF46
                cmpi.w  #$FFFF,d3
                bne.s   Boss_FlyingNeoBeginPoseCommand
                clr.w   $58(a5)
                clr.w   6(a5)
                bra.s   Boss_FlyingNeoReadPoseCommand
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginPoseCommand:                         ; was: loc_3CF56
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_FlyingNeoPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_FlyingNeoBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,6(a5)
                addq.w  #1,$A(a5)
                tst.w   $C(a5)
                bmi.s   Boss_FlyingNeoApplyPoseAngles
Boss_FlyingNeoAdvancePoseInterpolation:                 ; was: loc_3CF8C
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #3,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_FlyingNeoApplyPoseAngles:                          ; was: loc_3CF9C
                                        ; Boss_FlyingNeoUpdatePoseAnimation+80   j
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.w  #$1FE,d7
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                move.w  d0,$176(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$1D6(a5)
                move.w  d1,$236(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$296(a5)
                move.w  d0,$2F6(a5)
                move.b  $C(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$356(a5)
                move.w  d1,$3B6(a5)
                rts
; End of function Boss_FlyingNeoUpdatePoseAnimation
; Begins interpolation from the current channels to the selected pose target
Boss_FlyingNeoBeginPoseInterpolation:                   ; was: sub_3CFE8
                movea.l #Boss_FlyingNeoNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #3,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_FlyingNeoBeginPoseInterpolation
; Initializes all four Flying Neo pose channels from bytes at a0
Boss_FlyingNeoInitializePoseChannels:
                movea.w #(SharedScratchLong0-M68K_RAM),a1  ; was: sub_3CFFE
                moveq   #3,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_FlyingNeoInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_FlyingNeoNeutralPoses: dc.w    $408, 0, $808, 0, $408, 4, $808, 4  ; was: word_3D00A
                                        ; Boss_FlyingNeoPlayerControlled:Boss_FlyingNeoApplyPlayerControlPose   o
                dc.w    $FFFF
Boss_FlyingNeoHorizontalSwoopPoses: dc.w    $612, 0, $1212, 0, $612, 4, $1212, 4  ; was: word_3D01C
                dc.w    $FFFF
Boss_FlyingNeoPartAnchorPoses:  dc.w    $828, 8, $E0E, 8, $A10, $C, $A0A, $C  ; was: word_3D02E
                dc.w    $80AF, $828, $10, $E0E, $10, $A10, $14, $A0A
                dc.w    $14, $80AF, $FFFF
Boss_FlyingNeoRisingRetreatPoses:   dc.w    $70C, $18, $4040, $18, $FFFE  ; was: word_3D054
Boss_FlyingNeoDivingArcPoses:       dc.w    $210, $1C, $606, $1C, $220, $20, $808, $20  ; was: word_3D05E
                dc.w    $FFFF
Boss_FlyingNeoRisingArcPoseCommands:    dc.w    $820, $1C, $1216, $1C, $820, $20, $1216, $20  ; was: word_3D070
                dc.w    $FFFF
Boss_FlyingNeoPoseTable:    dc.w    $868, $1C70, $1C70, $868, $3010, $470, $1020, $501B  ; was: word_3D082
                dc.w    $470, $3010, $5020, $1020, $6850, $6850, $7800, $870
                dc.w    $1860, $7008, $6C24, $878, $F860, $6024
