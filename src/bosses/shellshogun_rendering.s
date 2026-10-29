Boss_ShellshogunRenderSprites:                          ; was: sub_39E5E
                                        ; Boss_ShellshogunDirectionalAttackWindupState+2A   p
                moveq   #$16,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                bsr.w   Boss_ShellshogunPublishScreenPosition
                bsr.w   Boss_ShellshogunUpdateRotatingPart
                bsr.w   Boss_ShellshogunSelectBodyFrameMapping
                bra.w   Boss_ShellshogunUpdateOrbitingParts
; End of function Boss_ShellshogunRenderSprites
; Updates facing and the zero-facing linked-part flag arrangement
Boss_ShellshogunUpdateFacingPartFlags:                  ; was: sub_39E76
                                        ; Boss_ShellshogunJumpAttackWindupState+6   p
                jsr     (Physics_GetPlayerDelta).l
                clr.w   $54(a5)
                tst.w   d1
                bpl.s   Boss_ShellshogunApplyFacingPartFlags
                move.w  #$100,$54(a5)
Boss_ShellshogunApplyFacingPartFlags:                   ; was: loc_39E8A
                tst.w   $54(a5)
                beq.s   Boss_ShellshogunSetZeroFacingPartFlags
; End of function Boss_ShellshogunUpdateFacingPartFlags
; Initializes the linked-part flag arrangement used during setup
Boss_ShellshogunInitializePartFlags:                    ; was: sub_39E90
                moveq   #3,d7
                bset    d7,$6E(a5)
                bset    d7,$CE(a5)
                bclr    d7,$4EE(a5)
                bset    d7,$36E(a5)
                bclr    d7,$78E(a5)
                rts
; End of function Boss_ShellshogunInitializePartFlags
; Installs the linked-part flag arrangement used when facing is zero
Boss_ShellshogunSetZeroFacingPartFlags:                 ; was: sub_39EA8
                moveq   #3,d7
                bclr    d7,$6E(a5)
                bclr    d7,$CE(a5)
                bset    d7,$4EE(a5)
                bclr    d7,$36E(a5)
                bset    d7,$78E(a5)
                rts
; End of function Boss_ShellshogunSetZeroFacingPartFlags
; Enables flag bit seven on eight linked-part records
Boss_ShellshogunEnableLinkedPartFlag7:                  ; was: sub_39EC0
                moveq   #7,d0
                bset    d0,$12E(a5)
                bset    d0,$18E(a5)
                bset    d0,$1EE(a5)
                bset    d0,$24E(a5)
                bset    d0,$54E(a5)
                bset    d0,$5AE(a5)
                bset    d0,$60E(a5)
                bset    d0,$66E(a5)
                rts
; End of function Boss_ShellshogunEnableLinkedPartFlag7
; Update Shellshogun sprite flipping based on rotation angle
Boss_ShellshogunUpdateSpriteFlip:                       ; was: sub_39EE4
                lea     (Boss_ShellshogunRotationFramesF).l,a0
                move.w  $29C(a5),d0
                subi.w  #$110,d0
                move.w  d0,d1
                asr.w   #3,d0
                andi.w  #$1C,d0
                move.l  (a0,d0.w),$248(a5)
                andi.w  #$E7FF,$E(a5)
                add.w   $54(a5),d1
                add.w   $56(a5),d1
                andi.w  #$1FE,d1
                cmpi.w  #$100,d1
                bmi.s   Boss_ShellshogunUpdateSpriteFlipReturn
                ori.w   #$1800,$E(a5)
Boss_ShellshogunUpdateSpriteFlipReturn:                 ; was: locret_39F1E
                rts
; End of function Boss_ShellshogunUpdateSpriteFlip
; Selects the alternating Shellshogun body frame mapping
Boss_ShellshogunSelectBodyFrameMapping:                 ; was: sub_39F20
                move.l  #Boss_ShellshogunSpriteMapping00,$68(a5)
                btst    #3,(FrameCounter+1).w
                bne.s   Boss_ShellshogunSelectBodyFrameMappingReturn
                move.l  #Boss_ShellshogunSpriteMapping01,$68(a5)
Boss_ShellshogunSelectBodyFrameMappingReturn:           ; was: locret_39F38
                rts
; End of function Boss_ShellshogunSelectBodyFrameMapping
; Publishes and clamps the boss-relative shared screen position
Boss_ShellshogunPublishScreenPosition:                  ; was: sub_39F3A
                move.w  #$BC,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$50,d0                         ; 'P'
                move.w  d0,(SecondaryCameraYPos).w
                jmp     Boss_ClampSharedScreenPosition
; End of function Boss_ShellshogunPublishScreenPosition
; Advances the phase and positions three orbiting auxiliary parts
Boss_ShellshogunUpdateOrbitingParts:                    ; was: sub_39F58
                move.w  $1DE(a5),d0
                move.w  $23C(a5),d1
                tst.w   $1DC(a5)
                bne.s   Boss_ShellshogunReverseOrbitPhase
                addq.w  #4,d0
                addq.w  #1,d1
                andi.w  #$1FC,d0
                cmpi.w  #$50,d0                         ; 'P'
                bne.s   Boss_ShellshogunStoreOrbitPhase
                addq.w  #1,$1DC(a5)
                bra.s   Boss_ShellshogunStoreOrbitPhase
; ---------------------------------------------------------------------------
Boss_ShellshogunReverseOrbitPhase:                      ; was: loc_39F7A
                subq.w  #4,d0
                subq.w  #1,d1
                andi.w  #$1FC,d0
                cmpi.w  #$1B0,d0
                bne.s   Boss_ShellshogunStoreOrbitPhase
                clr.w   $1DC(a5)
Boss_ShellshogunStoreOrbitPhase:                        ; was: loc_39F8C
                                        ; Boss_ShellshogunUpdateOrbitingParts+20   j
                move.w  d0,$1DE(a5)
                move.w  d1,$23C(a5)
                movea.w #(TwentyFifthEntityType-M68K_RAM),a0
                movea.l #Math_SineTable,a1
                movea.l #Boss_ShellshogunOrbitingPartSourcesAndRadii,a2
                move.w  $56(a5),d0
                addi.w  #$80,d0
                add.w   $23C(a5),d0
                move.w  $1DE(a5),d2
                move.w  #$1FE,d1
                moveq   #2,d7
Boss_ShellshogunUpdateNextOrbitingPart:                 ; was: loc_39FBA
                and.w   d1,d0
                movea.w (a2)+,a3
                move.w  -$80(a1,d0.w),d4
                move.w  (a1,d0.w),d5
                muls.w  (a2),d4
                muls.w  (a2)+,d5
                asl.l   #2,d4
                asl.l   #2,d5
                add.l   $14(a3),d4
                add.l   $10(a3),d5
                move.l  d4,$14(a0)
                move.l  d5,$10(a0)
                add.w   d2,d0
                lea     $60(a0),a0
                dbf     d7,Boss_ShellshogunUpdateNextOrbitingPart
                rts
; End of function Boss_ShellshogunUpdateOrbitingParts
; ---------------------------------------------------------------------------
Boss_ShellshogunOrbitingPartSourcesAndRadii:    dc.w    $C620, $20, $CF20, 8, $CF80, 6  ; was: word_39FEA

; Selects the linked part and derives its wrapped rotation from the pose
Boss_ShellshogunUpdateLinkedPartRotation:               ; was: sub_39FF6
                                        ; sub_39E5A   p
                move.w  #$C860,$23E(a5)
                move.w  $296(a5),d0
                subi.w  #$80,d0
                move.w  d0,$29C(a5)
                andi.w  #$1FE,$29C(a5)
                rts
; End of function Boss_ShellshogunUpdateLinkedPartRotation
; Updates the rotating part's frame, flips, anchor, and optional trailing parts
Boss_ShellshogunUpdateRotatingPart:                     ; was: sub_3A010
                move.w  $29C(a5),d0
                add.w   $56(a5),d0
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1FE,d0
                bclr    #4,$A2E(a5)
                cmpi.w  #$100,d0
                bpl.s   Boss_ShellshogunUpdateRotatingPartVerticalFlip
                bset    #4,$A2E(a5)
Boss_ShellshogunUpdateRotatingPartVerticalFlip:         ; was: loc_3A032
                bset    #3,$A2E(a5)
                cmpi.w  #$180,d0
                bpl.s   Boss_ShellshogunApplyRotatingPartFacing
                cmpi.w  #$80,d0
                bmi.s   Boss_ShellshogunApplyRotatingPartFacing
                bclr    #3,$A2E(a5)
Boss_ShellshogunApplyRotatingPartFacing:                ; was: loc_3A04A
                                        ; Boss_ShellshogunUpdateRotatingPart+32   j
                tst.w   $54(a5)
                beq.s   Boss_ShellshogunSelectRotatingPartFrame
                eori.w  #$800,$A2E(a5)
Boss_ShellshogunSelectRotatingPartFrame:                ; was: loc_3A056
                asr.w   #4,d0
                andi.w  #$C,d0
                move.l  Boss_ShellshogunRotatingPartFrameTable(pc,d0.w),$A28(a5)
                movea.w $23E(a5),a0
                move.w  $10(a0),$A30(a5)
                move.w  $14(a0),$A34(a5)
                tst.b   $A41(a5)
                bne.s   Boss_ShellshogunPositionTrailingParts
                clr.b   $AA1(a5)
                clr.b   $B01(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunPositionTrailingParts:                  ; was: loc_3A082
                move.b  #$C0,$AA1(a5)
                move.b  #$C0,$B01(a5)
                lea     (Math_SineTable).l,a1
                move.w  $29C(a5),d0
                addi.w  #$80,d0
                tst.w   $54(a5)
                bne.s   Boss_ShellshogunCalculateTrailingPartOffsets
                neg.w   d0
Boss_ShellshogunCalculateTrailingPartOffsets:           ; was: loc_3A0A4
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #7,d1
                asl.l   #7,d2
                move.l  $10(a0),d3
                move.l  $14(a0),d4
                sub.l   d1,d3
                sub.l   d2,d4
                move.l  d3,$A90(a5)
                move.l  d4,$A94(a5)
                sub.l   d1,d3
                sub.l   d2,d4
                move.l  d3,$AF0(a5)
                move.l  d4,$AF4(a5)
                rts
; End of function Boss_ShellshogunUpdateRotatingPart
; ---------------------------------------------------------------------------
Boss_ShellshogunRotatingPartFrameTable: dc.l    Boss_ShellshogunSpriteMapping29  ; was: off_3A0DA
                dc.l    Boss_ShellshogunSpriteMapping28
                dc.l    Boss_ShellshogunSpriteMapping27
                dc.l    Boss_ShellshogunSpriteMapping28
