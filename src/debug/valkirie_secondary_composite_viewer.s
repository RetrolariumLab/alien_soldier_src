; Minimal type-$3F0 controller followed by an unreferenced pose viewer
Debug_ValkirieType3F0Main:                              ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_515AE
                tst.w   4(a5)
                beq.w   Debug_ValkirieType3F0DispatchState
                tst.w   8(a5)
                beq.s   Debug_ValkirieType3F0DispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
Debug_ValkirieType3F0DispatchState:                     ; CODE XREF: Debug_ValkirieType3F0Main+4   j  ; was: loc_515C2
                                        ; Debug_ValkirieType3F0Main+C   j
                move.w  4(a5),d0
                movea.w Debug_ValkirieType3F0StateTable(pc,d0.w),a0
                adda.l  #Debug_ValkirieType3F0Initialize,a0
                jmp     (a0)
; End of function Debug_ValkirieType3F0Main
; ---------------------------------------------------------------------------
Debug_ValkirieType3F0StateTable:    dc.w    Debug_ValkirieType3F0Initialize-Debug_ValkirieType3F0Initialize  ; was: off_515D2
                                        ; DATA XREF: Debug_ValkirieType3F0Main+18   r
                dc.w    Debug_ValkirieType3F0UpdateWaitFlag-Debug_ValkirieType3F0Initialize

; Initialize the type-$3F0 controller at its fixed position
Debug_ValkirieType3F0Initialize:                        ; DATA XREF: Debug_ValkirieType3F0Main+1C   o  ; was: sub_515D6
                                        ; ROM:Debug_ValkirieType3F0StateTable   o
                move.w  #1,8(a5)
                move.w  #$3F0,(a5)
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
; Type-$3F0 wait state: publish readiness when the global wait clears
Debug_ValkirieType3F0UpdateWaitFlag:                    ; DATA XREF: ROM:000515D4   o  ; was: loc_51616
                tst.w   (MessageSequenceState).w
                bne.s   Debug_ValkirieType3F0WaitReturn
                move.b  #1,(SceneSequenceFlags).w
Debug_ValkirieType3F0WaitReturn:                        ; CODE XREF: Debug_ValkirieType3F0Initialize+44   j  ; was: locret_51622
                rts
; End of function Debug_ValkirieType3F0Initialize
; Unreferenced controller-input entry for the secondary composite viewer
Debug_ValkirieSecondaryViewerUpdate:                    ; was: sub_51624
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_ValkirieSecondaryViewerCheckAngleDecreaseInput
                addq.w  #2,$56(a5)
Debug_ValkirieSecondaryViewerCheckAngleDecreaseInput:   ; CODE XREF: Debug_ValkirieSecondaryViewerUpdate+6   j  ; was: loc_51630
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_ValkirieSecondaryViewerPreparePoseUpdate
                subq.w  #2,$56(a5)
Debug_ValkirieSecondaryViewerPreparePoseUpdate:         ; CODE XREF: Debug_ValkirieSecondaryViewerUpdate+12   j  ; was: loc_5163C
                andi.w  #$1FE,$56(a5)
                lea     Debug_ValkirieSecondaryViewerPoseScript(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Debug_ValkirieSecondaryViewerAdvancePoseAndRender:      ; CODE XREF: Debug_ValkirieSecondaryViewerUpdate+24   j  ; was: loc_5164C
                bsr.w   Debug_ValkirieSecondaryViewerAdvancePoseScript
                moveq   #$19,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Debug_ValkirieSecondaryViewerUpdate
; Interpret pose commands and advance nineteen channels for linked-part angles
Debug_ValkirieSecondaryViewerAdvancePoseScript:         ; CODE XREF: Debug_ValkirieSecondaryViewerUpdate:Debug_ValkirieSecondaryViewerAdvancePoseAndRender   p  ; was: sub_51658
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Debug_ValkirieSecondaryViewerTickPoseInterpolation
Debug_ValkirieSecondaryViewerReadNextPoseCommand:       ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+24   j  ; was: loc_51662
                                        ; Debug_ValkirieSecondaryViewerAdvancePoseScript+44   j
                move.w  $58(a5),d0
                bmi.w   Debug_ValkirieSecondaryViewerStorePoseComponents
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Debug_ValkirieSecondaryViewerCheckPoseControlCommand
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Debug_ValkirieSecondaryViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_ValkirieSecondaryViewerCheckPoseControlCommand:   ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+18   j  ; was: loc_5167E
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Debug_ValkirieSecondaryViewerHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Debug_ValkirieSecondaryViewerHandlePoseLoopCommand:     ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+2E   j  ; was: loc_5168E
                cmpi.w  #$FFFF,d3
                bne.s   Debug_ValkirieSecondaryViewerBeginPoseCommandInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Debug_ValkirieSecondaryViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_ValkirieSecondaryViewerBeginPoseCommandInterpolation:  ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+3A   j  ; was: loc_5169E
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Debug_ValkirieSecondaryViewerPoseTargets,d0
                movea.l d0,a0
                bsr.w   Debug_ValkirieSecondaryViewerBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Debug_ValkirieSecondaryViewerStorePoseComponents
Debug_ValkirieSecondaryViewerTickPoseInterpolation:     ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+8   j  ; was: loc_516D0
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$12,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Debug_ValkirieSecondaryViewerStorePoseComponents:       ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+E   j  ; was: loc_516E0
                                        ; Debug_ValkirieSecondaryViewerAdvancePoseScript+76   j
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
; End of function Debug_ValkirieSecondaryViewerAdvancePoseScript
; Initialize interpolation deltas for the next secondary-viewer pose command
Debug_ValkirieSecondaryViewerBeginPoseInterpolation:    ; CODE XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+5C   p  ; was: sub_517F2
                lea     Debug_ValkirieSecondaryViewerPoseTargets(pc),a1
                nop
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Debug_ValkirieSecondaryViewerBeginPoseInterpolation
; Initialize the secondary viewer's nineteen pose channels from bytes at a0
Debug_ValkirieSecondaryViewerInitializePoseChannels:    ; was: sub_51808
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Debug_ValkirieSecondaryViewerInitializePoseChannels
; ---------------------------------------------------------------------------
Debug_ValkirieSecondaryViewerPoseScript:    dc.b    $20, $20, 0, 0, $20, $20, 0, $12, $FF, $FF  ; was: byte_51814
                                        ; DATA XREF: Debug_ValkirieSecondaryViewerUpdate+1E   o
Debug_ValkirieSecondaryViewerPoseTargets:   dc.w    $4000, $C094, $C010, $EC40, $F060, $F020, $2020, $10E0, $E000  ; was: word_5181E
                                        ; DATA XREF: Debug_ValkirieSecondaryViewerAdvancePoseScript+54   o
                                        ; sub_517F2   o
                dc.w    $4000, $C094, $C010, $EC40, $F060, $F020, $2020, $10E0, $E000
