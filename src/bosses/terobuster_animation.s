Boss_TerobusterInterpolateAnimation:                    ; CODE XREF: Boss_TerobusterDecisionState+100   p  ; was: sub_391CC
                                        ; Boss_TerobusterDecisionState:Boss_TerobusterMissileAttackBSelectPoseCommands   p
                clr.w   $1DC(a5)
                tst.w   $C(a5)
                bpl.s   Boss_TerobusterAdvancePoseInterpolation
Boss_TerobusterReadPoseCommand:                         ; CODE XREF: Boss_TerobusterInterpolateAnimation+2A   j  ; was: loc_391D6
                move.w  $58(a5),d0
                bmi.s   Boss_TerobusterApplyAngles
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_TerobusterCheckPoseLoopCommand
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_TerobusterCheckPoseLoopCommand:                    ; CODE XREF: Boss_TerobusterInterpolateAnimation+18   j  ; was: loc_391EC
                cmpi.w  #$FFFF,d3
                bne.s   Boss_TerobusterBeginPoseCommand
                clr.w   $58(a5)
                bra.s   Boss_TerobusterReadPoseCommand
; ---------------------------------------------------------------------------
Boss_TerobusterBeginPoseCommand:                        ; CODE XREF: Boss_TerobusterInterpolateAnimation+24   j  ; was: loc_391F8
                addq.w  #4,$58(a5)
                subq.w  #1,$17E(a5)
                addq.w  #1,$1DC(a5)
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_TerobusterPoseTable,d0
                movea.l d0,a0
                bsr.w   Boss_TerobusterCalculateDeltas
                move.b  (PoseDurationByte).w,d1
                ext.w   d1
                add.w   d1,$C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_TerobusterApplyAngles
Boss_TerobusterAdvancePoseInterpolation:                ; CODE XREF: Boss_TerobusterInterpolateAnimation+8   j  ; was: loc_3922E
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #5,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
; End of function Boss_TerobusterInterpolateAnimation
; Applies animation angles to 9 boss body parts
Boss_TerobusterApplyAngles:                             ; CODE XREF: Boss_TerobusterDecisionState:Boss_TerobusterDecisionAnimate   p  ; was: sub_3923E
                                        ; Boss_TerobusterBeginTileReveal:Boss_TerobusterRenderIntroPose   p
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                movea.w #(SharedScratchLong3-M68K_RAM),a1
                tst.w   $A(a5)
                beq.s   Boss_TerobusterApplyPoseSides
                exg     a0,a1
Boss_TerobusterApplyPoseSides:                          ; CODE XREF: Boss_TerobusterApplyAngles+10   j  ; was: loc_39252
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.w  d0,$116(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$176(a5)
                move.w  d1,$1D6(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$236(a5)
                move.b  (a1),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$296(a5)
                move.w  d0,$2F6(a5)
                move.b  4(a1),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$356(a5)
                move.w  d1,$3B6(a5)
                move.b  8(a1),d0
                asl.w   #1,d0
                add.w   d1,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                rts
; End of function Boss_TerobusterApplyAngles
; Calculates interpolation deltas for smooth animation
Boss_TerobusterCalculateDeltas:                         ; CODE XREF: Boss_TerobusterInterpolateAnimation+4E   p  ; was: sub_392B0
                movea.l #Boss_TerobusterNeutralPose,a1
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #5,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_TerobusterCalculateDeltas
; Expands six packed pose-channel bytes into the interpolation buffer
Boss_TerobusterInitializePoseChannels:                  ; CODE XREF: Boss_TerobusterSetup+120   p  ; was: sub_392C6
                                        ; Boss_TerobusterIntro+20   p
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                moveq   #5,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_TerobusterInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_TerobusterFallingRockPoses:        dc.w    4, 0, $FFFF  ; DATA XREF: Boss_TerobusterDecisionState:Boss_TerobusterSpawnFallingRocks   o  ; was: word_392D2
Boss_TerobusterFallingRockFinalePoses:  dc.w    3, 0, 1, $36, $FFFF  ; was: word_392D8
                                        ; DATA XREF: Boss_TerobusterDecisionState+28A   o
Boss_TerobusterDescentPoses:    dc.w    $10, $2A, $20, $30, $FFFE  ; was: word_392E2
                                        ; DATA XREF: Boss_TerobusterDescentState+28   o
Boss_TerobusterLandingFirstPoses:   dc.w    $FD12, $30, $34, $30, $F040, $24, $20, $24, $FFFE  ; was: word_392EC
                                        ; DATA XREF: Boss_TerobusterLandingState:Boss_TerobusterSelectLandingPose   o
Boss_TerobusterLandingSecondPoseCommands:   dc.w    $1C, 0, $FFFE  ; DATA XREF: Boss_TerobusterLandingCheckComplete   o  ; was: word_392FE
Boss_TerobusterMissileAttackAPoses:         dc.w    5, 0, $FA0E, 0, $E, 6, $14, $C, 5, $12, $FA0E, $12, $E, $18, $14, $1E  ; was: word_39304
                                        ; DATA XREF: Boss_TerobusterDecisionState+FA   o
                dc.w    $FFFF
Boss_TerobusterMissileAttackBPoses: dc.w    $14, $1E, $E, $18, 5, $12, $FA0E, $12, $14, $C, $E, 6, 5, 0, $FA0E, 0  ; was: word_39326
                                        ; DATA XREF: Boss_TerobusterDecisionState+1BA   o
                dc.w    $FFFF
Boss_TerobusterMissileAttackBDelayedPoseCommands:   dc.w    6, $1E, 8, $18, 3, $12, $FA08, $12, 6, $C, 8, 6, 3, 0, $FA08, 0  ; was: word_39348
                                        ; DATA XREF: Boss_TerobusterDecisionState+1B4   o
                dc.w    $FFFF
Boss_TerobusterPoseTable:   dc.w    $1330, $F840, $30D0, $F460, $C030, $44C8, $3060, $9024  ; was: word_3936A
                                        ; DATA XREF: Boss_TerobusterSetup+11A   o
                                        ; Boss_TerobusterBeginStageGateDelay   o
                dc.w    $24F8, $4030, $D013, $30F8, $3044, $C8F4, $60C0, $2424
                dc.w    $F830, $6090, $2040, $E020, $40E0, $4000, $CC40, $CC
Boss_TerobusterIntroPoseChannels:   dc.w    $70, $D400, $70D4, $1431, $F842, $2ED0  ; was: word_3939A
                                        ; DATA XREF: Boss_TerobusterIntro+1A   o

; Initializes Terobuster's five-byte intro palette sequence
Boss_TerobusterInitializePaletteSequence:               ; CODE XREF: Boss_TerobusterIntro+24   p  ; was: sub_393A6
                movea.l #(M68K_RAM_PHYSICAL+(TerobusterIntroPalette-M68K_RAM)),a0
                move.b  #$CE,d0
                move.b  #$C5,(a0)+
                move.b  d0,(a0)+
                move.b  d0,(a0)+
                move.b  d0,(a0)+
                move.b  d0,(a0)+
                rts
; End of function Boss_TerobusterInitializePaletteSequence
; Loads a compressed Terobuster intro-tile record by bounded index
Boss_TerobusterLoadIntroTilesByIndex:                   ; CODE XREF: Boss_TerobusterTileRevealState+E   p  ; was: sub_393BE
                asl.w   #2,d0
                bmi.s   Boss_TerobusterLoadIntroTilesReturn
                cmpi.w  #$4C,d0                         ; 'L'
                bpl.s   Boss_TerobusterLoadIntroTilesReturn
                movea.l Boss_TerobusterIntroTileLoadTable(pc,d0.w),a0
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Boss_TerobusterLoadIntroTilesReturn:                    ; CODE XREF: Boss_TerobusterLoadIntroTilesByIndex+2   j  ; was: locret_393D2
                                        ; Boss_TerobusterLoadIntroTilesByIndex+8   j
                rts
; End of function Boss_TerobusterLoadIntroTilesByIndex
; ---------------------------------------------------------------------------
Boss_TerobusterIntroTileLoadTable:  dc.l    Boss_TerobusterIntroTileLoadStep00  ; DATA XREF: Boss_TerobusterLoadIntroTilesByIndex+A   r  ; was: off_393D4
                dc.l    Boss_TerobusterIntroTileLoadStep01
                dc.l    Boss_TerobusterIntroTileLoadStep02
                dc.l    Boss_TerobusterIntroTileLoadStep03
                dc.l    Boss_TerobusterIntroTileLoadStep04
                dc.l    Boss_TerobusterIntroTileLoadStep05
                dc.l    Boss_TerobusterIntroTileLoadStep06
                dc.l    Boss_TerobusterIntroTileLoadStep07
                dc.l    Boss_TerobusterIntroTileLoadStep08
                dc.l    Boss_TerobusterIntroTileLoadStep09
                dc.l    Boss_TerobusterIntroTileLoadStep10
                dc.l    Boss_TerobusterIntroTileLoadStep11
                dc.l    Boss_TerobusterIntroTileLoadStep12
                dc.l    Boss_TerobusterIntroTileLoadStep13
                dc.l    Boss_TerobusterIntroTileLoadStep14
                dc.l    Boss_TerobusterIntroTileLoadStep15
                dc.l    Boss_TerobusterIntroTileLoadStep16
                dc.l    Boss_TerobusterIntroTileLoadStep17
                dc.l    Boss_TerobusterIntroTileLoadStep18
Boss_TerobusterIntroTileLoadStep18: dc.b    $42, $51, $40, 0, 4, 0, $C2, $C7, $C6, $C6, $C6, 0  ; was: byte_39420
                                        ; DATA XREF: ROM:0003941C   o
Boss_TerobusterIntroTileLoadStep17: dc.b    $42, $51, $40, 0, 4, 0, $C3, $C8, $B9, $B9, $B9, 0  ; was: byte_3942C
                                        ; DATA XREF: ROM:00039418   o
Boss_TerobusterIntroTileLoadStep16: dc.b    $42, $51, $40, 0, 4, 0, $C4, $C9, $C6, $C6, $C6, 0  ; was: byte_39438
                                        ; DATA XREF: ROM:00039414   o
Boss_TerobusterIntroTileLoadStep15: dc.b    $42, $51, $40, 0, 4, 0, $C5, $CA, $B9, $B9, $B9, 0  ; was: byte_39444
                                        ; DATA XREF: ROM:00039410   o
Boss_TerobusterIntroTileLoadStep14: dc.b    $42, $59, $40, 0, 3, 0, $CB, $C7, $C6, $C6  ; was: byte_39450
                                        ; DATA XREF: ROM:0003940C   o
Boss_TerobusterIntroTileLoadStep13: dc.b    $42, $59, $40, 0, 3, 0, $CC, $C8, $B9, $B9  ; was: byte_3945A
                                        ; DATA XREF: ROM:00039408   o
Boss_TerobusterIntroTileLoadStep12: dc.b    $42, $59, $40, 0, 3, 0, $CD, $C9, $C6, $C6  ; was: byte_39464
                                        ; DATA XREF: ROM:00039404   o
Boss_TerobusterIntroTileLoadStep11: dc.b    $42, $59, $40, 0, 3, 0, $CE, $CA, $B9, $B9  ; was: byte_3946E
                                        ; DATA XREF: ROM:00039400   o
Boss_TerobusterIntroTileLoadStep10: dc.b    $42, $61, $40, 0, 2, 0, $CB, $C7, $C6, 0  ; was: byte_39478
                                        ; DATA XREF: ROM:000393FC   o
Boss_TerobusterIntroTileLoadStep09: dc.b    $42, $61, $40, 0, 2, 0, $CC, $C8, $B9, 0  ; was: byte_39482
                                        ; DATA XREF: ROM:000393F8   o
Boss_TerobusterIntroTileLoadStep08: dc.b    $42, $61, $40, 0, 2, 0, $CD, $C9, $C6, 0  ; was: byte_3948C
                                        ; DATA XREF: ROM:000393F4   o
Boss_TerobusterIntroTileLoadStep07: dc.b    $42, $61, $40, 0, 2, 0, $CE, $CA, $B9, 0  ; was: byte_39496
                                        ; DATA XREF: ROM:000393F0   o
Boss_TerobusterIntroTileLoadStep06: dc.b    $42, $69, $40, 0, 1, 0, $CB, $C7  ; was: byte_394A0
                                        ; DATA XREF: ROM:000393EC   o
Boss_TerobusterIntroTileLoadStep05: dc.b    $42, $69, $40, 0, 1, 0, $CC, $C8  ; was: byte_394A8
                                        ; DATA XREF: ROM:000393E8   o
Boss_TerobusterIntroTileLoadStep04: dc.b    $42, $69, $40, 0, 1, 0, $CD, $C9  ; was: byte_394B0
                                        ; DATA XREF: ROM:000393E4   o
Boss_TerobusterIntroTileLoadStep03: dc.b    $42, $69, $40, 0, 1, 0, $CE, $CA  ; was: byte_394B8
                                        ; DATA XREF: ROM:000393E0   o
Boss_TerobusterIntroTileLoadStep02: dc.b    $42, $71, $40, 0, 1, 0, $CE, $CB  ; was: byte_394C0
                                        ; DATA XREF: ROM:000393DC   o
Boss_TerobusterIntroTileLoadStep01: dc.b    $42, $71, $40, 0, 1, 0, $CE, $CD  ; was: byte_394C8
                                        ; DATA XREF: ROM:000393D8   o
Boss_TerobusterIntroTileLoadStep00: dc.b    $42, $71, $40, 0, 1, 0, $CE, $CE  ; was: byte_394D0
                                        ; DATA XREF: ROM:Boss_TerobusterIntroTileLoadTable   o

; Main Shellshogun boss handler with state dispatch
