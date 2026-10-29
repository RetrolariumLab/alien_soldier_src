; Main loop handler for the unidentified Seven Force form
Boss_UnidentifiedSevenForceMain:                        ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_58C62
                tst.w   4(a5)
                beq.w   Boss_UnidentifiedSevenForceDispatchState
                tst.w   8(a5)
                beq.s   Boss_UnidentifiedSevenForceDispatchState
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #$18,d0
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
Boss_UnidentifiedSevenForceDispatchState:               ; CODE XREF: Boss_UnidentifiedSevenForceMain+4   j  ; was: loc_58C84
                                        ; Boss_UnidentifiedSevenForceMain+C   j
                move.w  4(a5),d0
                movea.w Boss_UnidentifiedSevenForceStateOffsets(pc,d0.w),a0
                adda.l  #Boss_UnidentifiedSevenForceInit,a0
                jmp     (a0)
; End of function Boss_UnidentifiedSevenForceMain
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceStateOffsets:    dc.w    Boss_UnidentifiedSevenForceInit-Boss_UnidentifiedSevenForceInit  ; was: off_58C94
                                        ; DATA XREF: Boss_UnidentifiedSevenForceMain+26   r
                dc.w    Boss_UnidentifiedSevenForceInteractiveState2-Boss_UnidentifiedSevenForceInit
                dc.w    Boss_UnidentifiedSevenForceRenderState4-Boss_UnidentifiedSevenForceInit

; Initialize the unidentified Seven Force composite and enter state 4
Boss_UnidentifiedSevenForceInit:                        ; DATA XREF: Boss_UnidentifiedSevenForceMain+2A   o  ; was: sub_58C9A
                                        ; ROM:Boss_UnidentifiedSevenForceStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$19,d7
                movea.l #Boss_UnidentifiedSevenForceMetaspritePartDescriptors,a0
                movea.l #Boss_UnidentifiedSevenForceMetaspriteInitialAngles,a1
                movea.l #Boss_UnidentifiedSevenForceMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_UnidentifiedSevenForceMetaspritePoseAngles,$2FC(a5)
                move.l  #Boss_UnidentifiedSevenForcePoseKeyframeData,$35C(a5)
                move.w  #$43C,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                movea.l #Boss_UnidentifiedSevenForceObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  #2,$1DE(a5)
                bra.w   Boss_UnidentifiedSevenForceInitState4
; End of function Boss_UnidentifiedSevenForceInit
; Unreferenced initializer for interactive state 2
Boss_UnidentifiedSevenForceInitState2:
                move.w  #2,4(a5)                        ; was: sub_58D00
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; End of function Boss_UnidentifiedSevenForceInitState2
; Apply rotation input and render interactive state 2
Boss_UnidentifiedSevenForceInteractiveState2:           ; DATA XREF: ROM:00058C96   o  ; was: sub_58D2C
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_UnidentifiedSevenForceCheckReverseRotationInput
                addq.w  #2,$56(a5)
Boss_UnidentifiedSevenForceCheckReverseRotationInput:   ; CODE XREF: Boss_UnidentifiedSevenForceInteractiveState2+6   j  ; was: loc_58D38
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_UnidentifiedSevenForcePreparePoseUpdate
                subq.w  #2,$56(a5)
Boss_UnidentifiedSevenForcePreparePoseUpdate:           ; CODE XREF: Boss_UnidentifiedSevenForceInteractiveState2+12   j  ; was: loc_58D44
                andi.w  #$1FE,$56(a5)
                lea     Boss_UnidentifiedSevenForceSharedPose(pc),a1
                nop
                bra.w   Boss_UnidentifiedSevenForceRenderFrame
; End of function Boss_UnidentifiedSevenForceInteractiveState2
; Unreferenced timed state-4 setup entry
Boss_UnidentifiedSevenForceInitTimedState4:
                move.w  #4,4(a5)                        ; was: sub_58D54
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$1B58,(BossHealth).w
                move.w  #$1B58,(BossMaxHealth).w
                move.w  #$80,$11C(a5)
                subq.w  #1,$11C(a5)
                bpl.s   Boss_UnidentifiedSevenForceRenderTimedState4Frame
                moveq   #8,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceRenderTimedState4Frame:      ; CODE XREF: Boss_UnidentifiedSevenForceInitTimedState4+42   j  ; was: loc_58DA0
                lea     Boss_UnidentifiedSevenForceSharedPose(pc),a1
                nop
                bra.w   Boss_UnidentifiedSevenForceRenderFrame
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceInitState4:                  ; CODE XREF: Boss_UnidentifiedSevenForceInit+62   j  ; was: loc_58DAA
                move.w  #4,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; Render dispatch state 4 with the shared pose
Boss_UnidentifiedSevenForceRenderState4:                ; DATA XREF: ROM:00058C98   o  ; was: loc_58DCE
                lea     Boss_UnidentifiedSevenForceSharedPose(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceRenderFrame:                 ; CODE XREF: Boss_UnidentifiedSevenForceInteractiveState2+24   j  ; was: loc_58DD8
                                        ; Boss_UnidentifiedSevenForceRenderTimedState4Frame+6   j
                                        ; Boss_UnidentifiedSevenForceRenderState4+6   j
                bsr.w   Boss_UnidentifiedSevenForceUpdatePose
                bsr.w   Boss_UnidentifiedSevenForceApplyInterpolatedPartAngles
                moveq   #$18,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_UnidentifiedSevenForceRenderFrame
; Project the 18-channel pose buffer into composite-part angles
Boss_UnidentifiedSevenForceApplyInterpolatedPartAngles:  ; CODE XREF: Boss_UnidentifiedSevenForceRenderFrame+4   p  ; was: sub_58DE8
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
                rts
; End of function Boss_UnidentifiedSevenForceApplyInterpolatedPartAngles
; Update the unidentified form's 18-channel pose stream
Boss_UnidentifiedSevenForceUpdatePose:                  ; CODE XREF: Boss_UnidentifiedSevenForceRenderFrame   p  ; was: sub_58F0C
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_UnidentifiedSevenForceAdvancePoseInterpolation
Boss_UnidentifiedSevenForceReadPoseCommand:             ; CODE XREF: Boss_UnidentifiedSevenForceUpdatePose+24   j  ; was: loc_58F16
                                        ; Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_UnidentifiedSevenForcePreparePartAngleProjection
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_UnidentifiedSevenForceHandlePoseControlWord
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_UnidentifiedSevenForceReadPoseCommand
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceHandlePoseControlWord:       ; CODE XREF: Boss_UnidentifiedSevenForceUpdatePose+18   j  ; was: loc_58F32
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation
                move.w  d3,$58(a5)
                bra.w   Boss_UnidentifiedSevenForcePreparePartAngleProjection
; End of function Boss_UnidentifiedSevenForceUpdatePose
Boss_UnidentifiedSevenForceNoOp:                        ; was: nullsub_133
                rts
; End of function Boss_UnidentifiedSevenForceNoOp

; Handle a pose loop command or begin an ordinary interpolation command
Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation:  ; CODE XREF: Boss_UnidentifiedSevenForceUpdatePose+2E   j  ; was: sub_58F46
                cmpi.w  #$FFFF,d3
                bne.s   Boss_UnidentifiedSevenForceBeginPoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_UnidentifiedSevenForceReadPoseCommand
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceBeginPoseInterpolation:      ; CODE XREF: Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation+4   j  ; was: loc_58F56
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_UnidentifiedSevenForceCalculatePoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_UnidentifiedSevenForcePreparePartAngleProjection
Boss_UnidentifiedSevenForceAdvancePoseInterpolation:    ; CODE XREF: Boss_UnidentifiedSevenForceUpdatePose+8   j  ; was: loc_58F86
                subq.w  #1,$C(a5)
                movea.w #(SharedPatternRow0Long0-M68K_RAM),a0
                moveq   #$11,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_UnidentifiedSevenForcePreparePartAngleProjection:  ; CODE XREF: Boss_UnidentifiedSevenForceUpdatePose+E   j  ; was: loc_58F96
                                        ; Boss_UnidentifiedSevenForceUpdatePose+34   j
                move.w  #$1FE,d7
                movea.w #(SharedPatternRow0Long0-M68K_RAM),a0
                rts
; End of function Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation
; Calculate deltas for the unidentified form's 18-channel pose buffer
Boss_UnidentifiedSevenForceCalculatePoseDeltas:         ; CODE XREF: Boss_UnidentifiedSevenForceHandlePoseLoopOrInterpolation+24   p  ; was: sub_58FA0
                movea.l $2FC(a5),a1
                moveq   #$11,d7
                movea.w #(SharedPatternRow0Long0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_UnidentifiedSevenForceCalculatePoseDeltas
; Initialize the unidentified form's eighteen pose channels from bytes at a0
Boss_UnidentifiedSevenForceInitializePoseChannels:
                moveq   #$11,d7                         ; was: sub_58FB4
                movea.w #(SharedPatternRow0Long0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_UnidentifiedSevenForceInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_UnidentifiedSevenForceSharedPose:  dc.w    $2020, 0, $2020, $12, $FFFF  ; was: word_58FC0
                                        ; DATA XREF: Boss_UnidentifiedSevenForceInteractiveState2+1E   o
                                        ; Boss_UnidentifiedSevenForceRenderTimedState4Frame   o
                                        ; Boss_UnidentifiedSevenForceRenderState4   o
Boss_UnidentifiedSevenForcePoseKeyframeData:    dc.w    $40F8, $C49A, $B80A, $E654, $E05E, $EE20, $2022, $12E0  ; was: word_58FCA
                                        ; DATA XREF: Boss_UnidentifiedSevenForceInit+30   o
                dc.w    $E000, $3E04, $C092, $C412, $F058, $D062, $E91C, $201E
                dc.w    $17E4, $E002

; Main update routine for Valkyrie boss, handles state dispatch and palette updates
