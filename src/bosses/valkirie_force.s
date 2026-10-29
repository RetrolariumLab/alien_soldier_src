; Main dispatcher for Valkirie Force boss using state-based jumptable
Boss_ValkirieForceMain:                                 ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_53500
                tst.w   4(a5)
                beq.w   Boss_ValkirieForceDispatchState
                tst.w   8(a5)
                beq.s   Boss_ValkirieForceDispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
Boss_ValkirieForceDispatchState:                        ; CODE XREF: Boss_ValkirieForceMain+4   j  ; was: loc_53514
                                        ; Boss_ValkirieForceMain+C   j
                move.w  4(a5),d0
                movea.w Boss_ValkirieForceStateOffsets(pc,d0.w),a0
                adda.l  #Boss_ValkirieForceInit,a0
                jmp     (a0)
; End of function Boss_ValkirieForceMain
; ---------------------------------------------------------------------------
Boss_ValkirieForceStateOffsets: dc.w    Boss_ValkirieForceInit-Boss_ValkirieForceInit  ; was: off_53524
                                        ; DATA XREF: Boss_ValkirieForceMain+18   r
                dc.w    Boss_ValkirieForceInteractiveState-Boss_ValkirieForceInit

; Initialize the Valkirie Force metasprite and enter its interactive state
Boss_ValkirieForceInit:                                 ; DATA XREF: Boss_ValkirieForceMain+1C   o  ; was: sub_53528
                                        ; ROM:Boss_ValkirieForceStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$19,d7
                movea.l #Boss_ZLeoValkirieForceSharedMetaspriteData,a0
                movea.l #Boss_ZLeoValkirieForceSharedMetaspriteData,a1
                movea.l #Boss_ZLeoValkirieForceSharedMetaspriteData,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$3FC,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                move.w  #2,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; Apply rotation input, update the looping pose, and render the metasprite
Boss_ValkirieForceInteractiveState:                     ; DATA XREF: ROM:00053526   o  ; was: loc_5358A
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_ValkirieForceCheckReverseRotationInput
                addq.w  #2,$56(a5)
Boss_ValkirieForceCheckReverseRotationInput:            ; CODE XREF: Boss_ValkirieForceInit+68   j  ; was: loc_53596
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_ValkirieForcePreparePoseUpdate
                subq.w  #2,$56(a5)
Boss_ValkirieForcePreparePoseUpdate:                    ; CODE XREF: Boss_ValkirieForceInit+74   j  ; was: loc_535A2
                andi.w  #$1FE,$56(a5)
                lea     Boss_ValkirieForceInteractivePose(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Boss_ValkirieForceRenderFrame:                          ; CODE XREF: Boss_ValkirieForceInit+86   j  ; was: loc_535B2
                bsr.w   Boss_ValkirieForceUpdatePose
                moveq   #$19,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_ValkirieForceInit
; Interprets the pose stream and applies interpolated angles to all linked parts
Boss_ValkirieForceUpdatePose:                           ; CODE XREF: Boss_ValkirieForceInit:Boss_ValkirieForceRenderFrame   p  ; was: sub_535BE
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_ValkirieForceAdvancePoseInterpolation
Boss_ValkirieForceReadPoseCommand:                      ; CODE XREF: Boss_ValkirieForceUpdatePose+24   j  ; was: loc_535C8
                                        ; Boss_ValkirieForceUpdatePose+44   j
                move.w  $58(a5),d0
                bmi.w   Boss_ValkirieForceApplyInterpolatedPartAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ValkirieForceHandlePoseControlWord
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ValkirieForceReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ValkirieForceHandlePoseControlWord:                ; CODE XREF: Boss_ValkirieForceUpdatePose+18   j  ; was: loc_535E4
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_ValkirieForceHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ValkirieForceHandlePoseLoopCommand:                ; CODE XREF: Boss_ValkirieForceUpdatePose+2E   j  ; was: loc_535F4
                cmpi.w  #$FFFF,d3
                bne.s   Boss_ValkirieForceBeginPoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ValkirieForceReadPoseCommand
; ---------------------------------------------------------------------------
Boss_ValkirieForceBeginPoseInterpolation:               ; CODE XREF: Boss_ValkirieForceUpdatePose+3A   j  ; was: loc_53604
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_ValkirieForcePoseKeyframeData,d0
                movea.l d0,a0
                bsr.w   Boss_ValkirieForceCalculatePoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_ValkirieForceApplyInterpolatedPartAngles
Boss_ValkirieForceAdvancePoseInterpolation:             ; CODE XREF: Boss_ValkirieForceUpdatePose+8   j  ; was: loc_53636
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$12,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_ValkirieForceApplyInterpolatedPartAngles:          ; CODE XREF: Boss_ValkirieForceUpdatePose+E   j  ; was: loc_53646
                                        ; Boss_ValkirieForceUpdatePose+76   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
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
                rts
; End of function Boss_ValkirieForceUpdatePose
; Calculates nineteen-channel interpolation deltas for the next pose keyframe
Boss_ValkirieForceCalculatePoseDeltas:                  ; CODE XREF: Boss_ValkirieForceUpdatePose+5C   p  ; was: sub_53758
                lea     (Boss_ZLeoValkirieForceSharedMetaspriteData).l,a1
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_ValkirieForceCalculatePoseDeltas
; Unreferenced wrapper that initializes nineteen pose channels from bytes at a0
Boss_ValkirieForceInitializePoseChannels:               ; was: sub_5376E
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_ValkirieForceInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_ValkirieForceInteractivePose:  dc.w    $2020, 0, $2020, $12, $FFFF  ; was: word_5377A
                                        ; DATA XREF: Boss_ValkirieForceInit+80   o
Boss_ValkirieForcePoseKeyframeData: dc.w    $4000, $C094, $C010, $EC40, $F060, $F020, $2020, $10E0, $E000, $4000, $C094, $C010, $EC40, $F060, $F020, $2020  ; was: word_53784
                                        ; DATA XREF: Boss_ValkirieForceUpdatePose+54   o
                dc.w    $10E0, $E000
