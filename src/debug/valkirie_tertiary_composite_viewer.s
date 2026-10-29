; Minimal type-$3F4 controller followed by an unreferenced pose viewer
Debug_ValkirieType3F4Main:                              ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_51842
                tst.w   4(a5)
                beq.w   Debug_ValkirieType3F4DispatchState
                tst.w   8(a5)
                beq.s   Debug_ValkirieType3F4DispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
Debug_ValkirieType3F4DispatchState:                     ; CODE XREF: Debug_ValkirieType3F4Main+4   j  ; was: loc_51856
                                        ; Debug_ValkirieType3F4Main+C   j
                move.w  4(a5),d0
                movea.w Debug_ValkirieType3F4StateTable(pc,d0.w),a0
                adda.l  #Debug_ValkirieType3F4Initialize,a0
                jmp     (a0)
; End of function Debug_ValkirieType3F4Main
; ---------------------------------------------------------------------------
Debug_ValkirieType3F4StateTable:    dc.w    Debug_ValkirieType3F4Initialize-Debug_ValkirieType3F4Initialize  ; was: off_51866
                                        ; DATA XREF: Debug_ValkirieType3F4Main+18   r
                dc.w    Debug_ValkirieType3F4UpdateWaitFlag-Debug_ValkirieType3F4Initialize

; Initialize the type-$3F4 controller at its fixed position
Debug_ValkirieType3F4Initialize:                        ; DATA XREF: Debug_ValkirieType3F4Main+1C   o  ; was: sub_5186A
                                        ; ROM:Debug_ValkirieType3F4StateTable   o
                move.w  #1,8(a5)
                move.w  #$3F4,(a5)
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
; Type-$3F4 wait state: publish readiness when the global wait clears
Debug_ValkirieType3F4UpdateWaitFlag:                    ; DATA XREF: ROM:00051868   o  ; was: loc_518AA
                tst.w   (MessageSequenceState).w
                bne.s   Debug_ValkirieType3F4WaitReturn
                move.b  #1,(SceneSequenceFlags).w
Debug_ValkirieType3F4WaitReturn:                        ; CODE XREF: Debug_ValkirieType3F4Initialize+44   j  ; was: locret_518B6
                rts
; End of function Debug_ValkirieType3F4Initialize
; Unreferenced controller-input entry for the tertiary composite viewer
Debug_ValkirieTertiaryViewerUpdate:                     ; was: sub_518B8
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_ValkirieTertiaryViewerCheckAngleDecreaseInput
                addq.w  #2,$56(a5)
Debug_ValkirieTertiaryViewerCheckAngleDecreaseInput:    ; CODE XREF: Debug_ValkirieTertiaryViewerUpdate+6   j  ; was: loc_518C4
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_ValkirieTertiaryViewerPreparePoseUpdate
                subq.w  #2,$56(a5)
Debug_ValkirieTertiaryViewerPreparePoseUpdate:          ; CODE XREF: Debug_ValkirieTertiaryViewerUpdate+12   j  ; was: loc_518D0
                andi.w  #$1FE,$56(a5)
                lea     Debug_ValkirieTertiaryViewerPoseScript(pc),a1
                nop
                bra.w   *+4
; ---------------------------------------------------------------------------
Debug_ValkirieTertiaryViewerAdvancePoseAndRender:       ; CODE XREF: Debug_ValkirieTertiaryViewerUpdate+24   j  ; was: loc_518E0
                bsr.w   Debug_ValkirieTertiaryViewerAdvancePoseScript
                moveq   #$19,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Debug_ValkirieTertiaryViewerUpdate
; Interpret pose commands and advance nineteen channels for linked-part angles
Debug_ValkirieTertiaryViewerAdvancePoseScript:          ; CODE XREF: Debug_ValkirieTertiaryViewerUpdate:Debug_ValkirieTertiaryViewerAdvancePoseAndRender   p  ; was: sub_518EC
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Debug_ValkirieTertiaryViewerTickPoseInterpolation
Debug_ValkirieTertiaryViewerReadNextPoseCommand:        ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+24   j  ; was: loc_518F6
                                        ; Debug_ValkirieTertiaryViewerAdvancePoseScript+44   j
                move.w  $58(a5),d0
                bmi.w   Debug_ValkirieTertiaryViewerStorePoseComponents
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Debug_ValkirieTertiaryViewerCheckPoseControlCommand
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Debug_ValkirieTertiaryViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_ValkirieTertiaryViewerCheckPoseControlCommand:    ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+18   j  ; was: loc_51912
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Debug_ValkirieTertiaryViewerHandlePoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Debug_ValkirieTertiaryViewerHandlePoseLoopCommand:      ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+2E   j  ; was: loc_51922
                cmpi.w  #$FFFF,d3
                bne.s   Debug_ValkirieTertiaryViewerBeginPoseCommandInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Debug_ValkirieTertiaryViewerReadNextPoseCommand
; ---------------------------------------------------------------------------
Debug_ValkirieTertiaryViewerBeginPoseCommandInterpolation:  ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+3A   j  ; was: loc_51932
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Debug_ValkirieTertiaryViewerPoseTargets,d0
                movea.l d0,a0
                bsr.w   Debug_ValkirieTertiaryViewerBeginPoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Debug_ValkirieTertiaryViewerStorePoseComponents
Debug_ValkirieTertiaryViewerTickPoseInterpolation:      ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+8   j  ; was: loc_51964
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$12,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Debug_ValkirieTertiaryViewerStorePoseComponents:        ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+E   j  ; was: loc_51974
                                        ; Debug_ValkirieTertiaryViewerAdvancePoseScript+76   j
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
; End of function Debug_ValkirieTertiaryViewerAdvancePoseScript
; Initialize interpolation deltas for the next tertiary-viewer pose command
Debug_ValkirieTertiaryViewerBeginPoseInterpolation:     ; CODE XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+5C   p  ; was: sub_51A86
                lea     (Boss_ValkirieAlternateRotationFramesAndNeutralPose).l,a1
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Debug_ValkirieTertiaryViewerBeginPoseInterpolation
; Initialize the tertiary viewer's nineteen pose channels from bytes at a0
Debug_ValkirieTertiaryViewerInitializePoseChannels:     ; was: sub_51A9C
                moveq   #$12,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Debug_ValkirieTertiaryViewerInitializePoseChannels
; ---------------------------------------------------------------------------
Debug_ValkirieTertiaryViewerPoseScript: dc.b    $20, $20, 0, 0, $20, $20, 0, $12, $FF, $FF  ; was: byte_51AA8
                                        ; DATA XREF: Debug_ValkirieTertiaryViewerUpdate+1E   o
Debug_ValkirieTertiaryViewerPoseTargets:    dc.b    $40, 0, $C0, $94, $C0, $10, $EC, $40, $F0, $60, $F0, $20, $20, $20, $10, $E0  ; was: byte_51AB2
                                        ; DATA XREF: Debug_ValkirieTertiaryViewerAdvancePoseScript+54   o
                dc.b    $E0, 0, $40, 0, $C0, $94, $C0, $10, $EC, $40, $F0, $60, $F0, $20, $20, $20
                dc.b    $10, $E0, $E0, 0
