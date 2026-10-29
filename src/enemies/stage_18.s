; Dormant oscillator: no constructor or pinned-TAS execution is known
OrphanedFloatingOscillator:                             ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_2FCF6
                tst.w   4(a5)
                bne.s   OrphanedFloatingOscillator_Update
                addq.w  #2,4(a5)
                move.b  #$20,$21(a5)                    ; ' '
                move.w  #2,$46(a5)
                move.w  #$C500,2(a5)
                move.w  #$480,$E(a5)
                move.l  #SharedCombatSpriteFrame00,8(a5)
                move.w  #$A050,$2A(a5)
                move.w  $10(a5),$4C(a5)
                move.w  $14(a5),$4E(a5)
                clr.w   $50(a5)
                clr.w   $52(a5)
                clr.w   $54(a5)
                move.w  #$160,$10(a5)
                move.w  #$110,$14(a5)
OrphanedFloatingOscillator_Update:                      ; CODE XREF: OrphanedFloatingOscillator+4   j
                subq.w  #1,$54(a5)
                bpl.s   OrphanedFloatingOscillator_ApplyHorizontalMotion
                move.w  #9,$54(a5)
                eori.w  #1,$52(a5)
OrphanedFloatingOscillator_ApplyHorizontalMotion:       ; CODE XREF: OrphanedFloatingOscillator+58   j
                tst.w   $52(a5)
                bne.s   OrphanedFloatingOscillator_MoveRight
                subi.l  #$12000,$10(a5)
                bra.s   OrphanedFloatingOscillator_UpdateVerticalMotion
; ---------------------------------------------------------------------------
OrphanedFloatingOscillator_MoveRight:                   ; CODE XREF: OrphanedFloatingOscillator+6A   j
                addi.l  #$12000,$10(a5)
OrphanedFloatingOscillator_UpdateVerticalMotion:        ; CODE XREF: OrphanedFloatingOscillator+74   j
                tst.w   $50(a5)
                bne.s   OrphanedFloatingOscillator_MoveDown
                move.l  #$FFFEDD00,$1C(a5)
                cmpi.w  #$100,$14(a5)
                bpl.s   OrphanedFloatingOscillator_Return
                eori.w  #1,$50(a5)
                bra.s   OrphanedFloatingOscillator_Return
; ---------------------------------------------------------------------------
OrphanedFloatingOscillator_MoveDown:                    ; CODE XREF: OrphanedFloatingOscillator+82   j
                move.l  #$12300,$1C(a5)
                cmpi.w  #$140,$14(a5)
                bmi.s   OrphanedFloatingOscillator_Return
                eori.w  #1,$50(a5)
OrphanedFloatingOscillator_Return:                      ; CODE XREF: OrphanedFloatingOscillator+92   j
                                        ; OrphanedFloatingOscillator+9A   j
                rts
; End of function OrphanedFloatingOscillator
; Stage 18 moving platform used before and during the Destroyer-Mk2 arena
; Pinned TAS evidence: active at frame 41500 with mapping Stage18And19_MovingPlatformSpriteMapping
Object_MovingPlatform:                                  ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_2FDAA
                bclr    #7,$E(a5)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a5)
                tst.w   4(a5)
                bne.w   Object_MovingPlatform_Update
                addq.w  #2,4(a5)
                move.w  #$CD00,2(a5)
                move.l  #Stage18And19_MovingPlatformSpriteMapping,8(a5)
                move.w  #$4470,$E(a5)
                cmpi.w  #$18,(StageTableIndex).w
                bcc.s   Object_MovingPlatform_FinishInit
                move.l  #Stage10And12_MovingPlatformSpriteMapping,8(a5)
                move.w  #$4000,$E(a5)
Object_MovingPlatform_FinishInit:                       ; CODE XREF: Object_MovingPlatform+34   j
                move.b  #$20,$21(a5)                    ; ' '
                move.w  #2,$46(a5)
                move.l  #$FFE00020,$28(a5)
                move.w  $10(a5),$4C(a5)
                move.w  $14(a5),$4E(a5)
                move.w  $4E(a5),$52(a5)
Object_MovingPlatform_Update:                           ; CODE XREF: Object_MovingPlatform+12   j
                bclr    #0,6(a5)
                bne.s   Object_MovingPlatform_ApplyCollisionBob
                subq.w  #1,$50(a5)
                bpl.s   Object_MovingPlatform_UpdatePosition
                clr.w   $50(a5)
                bra.s   Object_MovingPlatform_UpdatePosition
; ---------------------------------------------------------------------------
Object_MovingPlatform_ApplyCollisionBob:                ; CODE XREF: Object_MovingPlatform+70   j
                cmpi.w  #6,$50(a5)
                bpl.s   Object_MovingPlatform_UpdatePosition
                addq.w  #1,$50(a5)
Object_MovingPlatform_UpdatePosition:                   ; CODE XREF: Object_MovingPlatform+76   j
                                        ; Object_MovingPlatform+7C   j
                move.w  $50(a5),d0
                add.w   $52(a5),d0
                move.w  d0,$14(a5)
                btst    #0,$5F(a5)
                bne.w   Object_MovingPlatform_UpdateVisibility
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                move.w  d0,d5
                bpl.s   Object_MovingPlatform_CheckHorizontalVelocity
                neg.w   d0
Object_MovingPlatform_CheckHorizontalVelocity:          ; CODE XREF: Object_MovingPlatform+AA   j
                cmpi.w  #$10,d0
                bpl.s   Object_MovingPlatform_AccelerateRight
                move.l  $18(a5),d0
                move.l  d0,d1
                bpl.s   Object_MovingPlatform_StopIfSlow
                neg.l   d0
Object_MovingPlatform_StopIfSlow:                       ; CODE XREF: Object_MovingPlatform+BA   j
                cmpi.l  #$2000,d0
                bpl.s   Object_MovingPlatform_SelectAcceleration
                clr.l   $18(a5)
                rts
; ---------------------------------------------------------------------------
Object_MovingPlatform_SelectAcceleration:               ; CODE XREF: Object_MovingPlatform+C4   j
                tst.l   d1
                bmi.s   Object_MovingPlatform_IncreaseHorizontalVelocity
                bpl.s   Object_MovingPlatform_DecreaseHorizontalVelocity
Object_MovingPlatform_AccelerateRight:                  ; CODE XREF: Object_MovingPlatform+B2   j
                tst.w   d5
                bmi.s   Object_MovingPlatform_AccelerateLeft
                tst.w   $18(a5)
                bmi.s   Object_MovingPlatform_IncreaseHorizontalVelocity
                cmpi.w  #2,$18(a5)
                bmi.s   Object_MovingPlatform_IncreaseHorizontalVelocity
                move.l  #$20000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Object_MovingPlatform_IncreaseHorizontalVelocity:       ; CODE XREF: Object_MovingPlatform+CE   j
                                        ; Object_MovingPlatform+DA   j
                addi.l  #$1200,$18(a5)
                rts
; ---------------------------------------------------------------------------
Object_MovingPlatform_AccelerateLeft:                   ; CODE XREF: Object_MovingPlatform+D4   j
                tst.w   $18(a5)
                bpl.s   Object_MovingPlatform_DecreaseHorizontalVelocity
                cmpi.w  #$FFFE,$18(a5)
                bpl.s   Object_MovingPlatform_DecreaseHorizontalVelocity
                move.l  #$FFFE0000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Object_MovingPlatform_DecreaseHorizontalVelocity:       ; CODE XREF: Object_MovingPlatform+D0   j
                                        ; Object_MovingPlatform+FC   j
                subi.l  #$1200,$18(a5)
                rts
; ---------------------------------------------------------------------------
Object_MovingPlatform_UpdateVisibility:                 ; CODE XREF: Object_MovingPlatform+9C   j
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bpl.s   Object_MovingPlatform_Return
                bset    #4,2(a5)
Object_MovingPlatform_Return:                           ; CODE XREF: Object_MovingPlatform+120   j
                rts
; End of function Object_MovingPlatform
; Dispatches the Stage 18 segmented-worm head and its linked segments
; Pinned TAS evidence: two twelve-segment chains are visible at frame 41220
Stage18_SegmentedWormMain:                              ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_2FED4
                tst.w   $50(a5)
                bne.w   Stage18_SegmentedWormSegmentDispatch
                cmpi.w  #2,4(a5)
                bne.s   Stage18_SegmentedWormDispatch
                move.w  $24(a5),d1
                movea.w $44(a5),a0
                move.w  #$B,d0
Stage18_SegmentedWormSumHealth:                         ; CODE XREF: Stage18_SegmentedWormMain+24   j
                add.w   $24(a0),d1
                movea.w $44(a0),a0
                dbf     d0,Stage18_SegmentedWormSumHealth
                cmpi.w  #$CE0,d1
                bcc.s   Stage18_SegmentedWormDispatch
                move.w  #4,4(a5)
Stage18_SegmentedWormDispatch:                          ; CODE XREF: Stage18_SegmentedWormMain+E   j
                                        ; Stage18_SegmentedWormMain+2C   j
                move.w  4(a5),d0
                lea     Stage18_SegmentedWormHeadStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage18_SegmentedWormMain
; ---------------------------------------------------------------------------
Stage18_SegmentedWormHeadStateTable:    dc.w    Stage18_SegmentedWormSpawnSegments-*  ; DATA XREF: Stage18_SegmentedWormMain+38   o
                dc.w    Stage18_SegmentedWormUpdateHead-*
                dc.w    Stage18_SegmentedWormScatterSegments-*
                dc.w    Stage18_SegmentedWormUpdateFallingSegment-*

; Enemy spawner main handler
Stage18_SegmentedWormSpawnSegments:                     ; DATA XREF: ROM:Stage18_SegmentedWormHeadStateTable   o  ; was: sub_2FF1C
                bsr.w   Stage18_SegmentedWormInitCollision
                move.w  #$D00,2(a5)
                clr.b   $21(a5)
                clr.w   $5A(a5)
                tst.w   $5E(a5)
                beq.s   Stage18_SegmentedWormCreateChain
                move.w  $10(a5),d0
                addi.w  #$20,d0                         ; ' '
                cmp.w   (PlayerXPosition).w,d0
                bcc.w   Entity_UpdateReturn
                move.w  #1,$5A(a5)
Stage18_SegmentedWormCreateChain:                       ; CODE XREF: Stage18_SegmentedWormSpawnSegments+16   j
                lea     Stage18_SegmentedWormInitialFrameTable(pc),a4
                nop
                lea     Stage18_SegmentedWormDelayTable(pc),a3
                nop
                movea.w a5,a1
                move.w  #$1000,2(a5)
                move.w  #$B,d7
Stage18_SegmentedWormCreateNextSegment:                 ; CODE XREF: Stage18_SegmentedWormSpawnSegments+8E   j
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.w   Entity_UpdateReturn
                move.w  #$1000,2(a0)
                move.w  #$448,(a0)
                move.w  #1,$50(a0)
                move.w  #$100,$24(a0)
                move.w  a0,$44(a1)
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),$14(a0)
                clr.w   4(a0)
                move.w  d7,d0
                lsl.w   #1,d0
                move.l  (a3,d0.w),$54(a0)
                lsl.w   #1,d0
                move.l  (a4,d0.w),8(a0)
                movea.w a0,a1
                dbf     d7,Stage18_SegmentedWormCreateNextSegment
                move.w  #$D00,2(a5)
                movea.w a5,a0
                move.w  #$B,d7
Stage18_SegmentedWormEnableSegmentCollision:            ; CODE XREF: Stage18_SegmentedWormSpawnSegments+A8   j
                movea.w $44(a0),a0
                move.w  #$CD00,2(a0)
                dbf     d7,Stage18_SegmentedWormEnableSegmentCollision
                clr.w   $44(a1)
                clr.w   $54(a5)
                bsr.w   Stage18_SegmentedWormActivateSegment
                move.l  #Stage18_SegmentedWormSpriteMapping00,8(a5)
                bra.w   Stage18_SegmentedWormSetLaunchVelocity
; End of function Stage18_SegmentedWormSpawnSegments
; Advances a newly created worm segment from state zero to active state two
Stage18_SegmentedWormActivateSegment:                   ; CODE XREF: Stage18_SegmentedWormSpawnSegments+B4   p  ; was: sub_2FFE0
                                        ; sub_304A4   j
                addq.w  #2,4(a5)
; End of function Stage18_SegmentedWormActivateSegment
; Initializes shared collision and display fields for a worm segment
Stage18_SegmentedWormInitCollision:                     ; CODE XREF: Stage18_SegmentedWormSpawnSegments   p  ; was: sub_2FFE4
                move.w  #$CD00,2(a5)
                move.w  #$380,$E(a5)
                move.b  #$20,$20(a5)                    ; ' '
                move.b  #$C0,$21(a5)
                move.l  #$F808F808,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$26(a5)                    ; '('
                move.w  #$100,$24(a5)
                tst.w   (DifficultyMode).w
                beq.w   Entity_UpdateReturn
                move.w  #$104,$24(a5)
                rts
; End of function Stage18_SegmentedWormInitCollision
; ---------------------------------------------------------------------------
Stage18_SegmentedWormInitialFrameTable: dc.l    Stage18_SegmentedWormSpriteMapping08  ; DATA XREF: Stage18_SegmentedWormSpawnSegments:Stage18_SegmentedWormCreateChain   o
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping04
Stage18_SegmentedWormDelayTable:    dc.l    $80004, $40004, $40004, $40004, $40004, $40004
                                        ; DATA XREF: Stage18_SegmentedWormSpawnSegments+34   o
Stage18_SegmentedWormDirectionFrameTables:  dc.l    Stage18_SegmentedWormDirectionFramesA  ; DATA XREF: Stage18_SegmentedWormAdvanceSpinFrame+4   o
                                        ; Stage18_SegmentedWormUpdateFollower+10   o
                dc.l    Stage18_SegmentedWormDirectionFramesB
                dc.l    Stage18_SegmentedWormDirectionFramesC
Stage18_SegmentedWormDirectionFramesA:  dc.l    Stage18_SegmentedWormSpriteMapping00  ; DATA XREF: ROM:Stage18_SegmentedWormDirectionFrameTables   o
                                        ; Stage18_SegmentedWormUpdateHead+18   o
                dc.l    Stage18_SegmentedWormSpriteMapping03
                dc.l    Stage18_SegmentedWormSpriteMapping02
                dc.l    Stage18_SegmentedWormSpriteMapping01
                dc.l    Stage18_SegmentedWormSpriteMapping00
                dc.l    Stage18_SegmentedWormSpriteMapping03
                dc.l    Stage18_SegmentedWormSpriteMapping02
                dc.l    Stage18_SegmentedWormSpriteMapping01
                dc.l    Stage18_SegmentedWormSpriteMapping00
                dc.l    Stage18_SegmentedWormSpriteMapping01
                dc.l    Stage18_SegmentedWormSpriteMapping02
                dc.l    Stage18_SegmentedWormSpriteMapping03
                dc.l    Stage18_SegmentedWormSpriteMapping00
                dc.l    Stage18_SegmentedWormSpriteMapping01
                dc.l    Stage18_SegmentedWormSpriteMapping02
                dc.l    Stage18_SegmentedWormSpriteMapping03
Stage18_SegmentedWormDirectionFramesB:  dc.l    Stage18_SegmentedWormSpriteMapping04  ; DATA XREF: ROM:00030074   o
                dc.l    Stage18_SegmentedWormSpriteMapping07
                dc.l    Stage18_SegmentedWormSpriteMapping06
                dc.l    Stage18_SegmentedWormSpriteMapping05
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping07
                dc.l    Stage18_SegmentedWormSpriteMapping06
                dc.l    Stage18_SegmentedWormSpriteMapping05
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping05
                dc.l    Stage18_SegmentedWormSpriteMapping06
                dc.l    Stage18_SegmentedWormSpriteMapping07
                dc.l    Stage18_SegmentedWormSpriteMapping04
                dc.l    Stage18_SegmentedWormSpriteMapping05
                dc.l    Stage18_SegmentedWormSpriteMapping06
                dc.l    Stage18_SegmentedWormSpriteMapping07
Stage18_SegmentedWormDirectionFramesC:  dc.l    Stage18_SegmentedWormSpriteMapping08  ; DATA XREF: ROM:00030078   o
                dc.l    Stage18_SegmentedWormSpriteMapping11
                dc.l    Stage18_SegmentedWormSpriteMapping10
                dc.l    Stage18_SegmentedWormSpriteMapping09
                dc.l    Stage18_SegmentedWormSpriteMapping08
                dc.l    Stage18_SegmentedWormSpriteMapping11
                dc.l    Stage18_SegmentedWormSpriteMapping10
                dc.l    Stage18_SegmentedWormSpriteMapping09
                dc.l    Stage18_SegmentedWormSpriteMapping08
                dc.l    Stage18_SegmentedWormSpriteMapping09
                dc.l    Stage18_SegmentedWormSpriteMapping10
                dc.l    Stage18_SegmentedWormSpriteMapping11
                dc.l    Stage18_SegmentedWormSpriteMapping08
                dc.l    Stage18_SegmentedWormSpriteMapping09
                dc.l    Stage18_SegmentedWormSpriteMapping10
                dc.l    Stage18_SegmentedWormSpriteMapping11
Stage18_SegmentedWormTileAttributes:    dc.w    $380, $380, $1B80, $1B80, $1B80, $1B80, $380, $380, $1380, $1380, $1380, $B80, $B80, $B80, $B80, $1380
                                        ; DATA XREF: Stage18_SegmentedWormUpdateHead+1C   o
                                        ; Stage18_SegmentedWormAdvanceSpinFrame+24   o

; Updates the worm head and propagates motion through its linked segments
Stage18_SegmentedWormUpdateHead:                        ; DATA XREF: ROM:0002FF16   o  ; was: sub_3015C
                bsr.w   Stage18_SegmentedWormEmitParticle
                bsr.w   Stage18_SegmentedWormAdvanceFollower
                addi.l  #$2000,$1C(a5)
                bsr.w   Stage18_SegmentedWormGetDirectionFrame
                move.w  d0,$58(a5)
                lea     Stage18_SegmentedWormDirectionFramesA(pc),a0
                lea     Stage18_SegmentedWormTileAttributes(pc),a1
                move.l  (a0,d0.w),8(a5)
                lsr.w   #1,d0
                move.w  (a1,d0.w),$E(a5)
                clr.w   d0
                move.w  #0,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   Stage18_SegmentedWormBeginLaunch
                tst.w   $10(a5)
                bmi.s   Stage18_SegmentedWormRemoveChain
                cmpi.w  #$200,$14(a5)
                bcs.w   Entity_UpdateReturn
Stage18_SegmentedWormRemoveChain:                       ; CODE XREF: Stage18_SegmentedWormUpdateHead+40   j
                move.w  #$1000,2(a5)
                movea.w $44(a5),a4
                tst.w   $44(a5)
                beq.w   Entity_UpdateReturn
                move.w  #$B,d6
Stage18_SegmentedWormRemoveNextSegment:                 ; CODE XREF: Stage18_SegmentedWormUpdateHead+74   j
                move.w  #$1000,2(a4)
                tst.w   $44(a4)
                beq.w   Entity_UpdateReturn
                movea.w $44(a4),a4
                dbf     d6,Stage18_SegmentedWormRemoveNextSegment
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormBeginLaunch:                       ; CODE XREF: Stage18_SegmentedWormUpdateHead+3A   j
                move.b  #$EC,d0
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Physics_AlignToTerrain).l
Stage18_SegmentedWormSetLaunchVelocity:                 ; CODE XREF: Stage18_SegmentedWormSpawnSegments+C0   j
                move.l  #$FFFB0000,$1C(a5)
                move.l  $14(a5),$4C(a5)
                move.w  #6,$52(a5)
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                cmpi.w  #$4C0,d0
                bcc.s   Stage18_SegmentedWormLaunchLeft
                eori.w  #1,$5A(a5)
                bne.s   Stage18_SegmentedWormLaunchLeft
                move.l  #$20000,$18(a5)
                move.l  $18(a5),$48(a5)
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormLaunchLeft:                        ; CODE XREF: Stage18_SegmentedWormUpdateHead+AA   j
                                        ; Stage18_SegmentedWormUpdateHead+B2   j
                move.l  #$FFFE0000,$18(a5)
                move.l  $18(a5),$48(a5)
                rts
; End of function Stage18_SegmentedWormUpdateHead
; Emits one randomized particle from a worm segment
Stage18_SegmentedWormEmitParticle:                      ; CODE XREF: Stage18_SegmentedWormUpdateHead   p  ; was: sub_30230
                tst.w   $52(a5)
                beq.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                move.l  #Stage18_SegmentedWormParticleSpriteAnimation,8(a0)
                movea.w a0,a4
                jsr     (Projectile_InitType88).l
                move.w  #$380,$E(a4)
Stage18_SegmentedWormInitializeParticleVelocity:        ; CODE XREF: Stage18_SegmentedWormUpdateFallingSegment+42   p
                move.l  $10(a5),$10(a4)
                move.l  $14(a5),$14(a4)
                jsr     (RandomNumber).l
                andi.w  #$FE,d0
                addi.w  #$100,d0
                bsr.w   Math_LookupSineCosinePairDuplicate
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a4)
                ext.l   d1
                asl.l   #3,d1
                move.l  d1,$1C(a4)
                rts
; End of function Stage18_SegmentedWormEmitParticle
; Advances one following segment after its per-segment delay
Stage18_SegmentedWormAdvanceFollower:                   ; CODE XREF: Stage18_SegmentedWormUpdateHead+4   p  ; was: sub_30288
                                        ; sub_304B0   p
                tst.w   $52(a5)
                beq.w   Entity_UpdateReturn
                subq.w  #1,$52(a5)
                bne.w   Entity_UpdateReturn
                tst.w   $44(a5)
                beq.w   Entity_UpdateReturn
                movea.w $44(a5),a0
                move.l  $48(a5),$18(a0)
                move.l  $48(a5),$48(a0)
                move.l  $4C(a5),$14(a0)
                move.l  $4C(a5),$4C(a0)
                move.l  #$FFFB0000,$1C(a0)
                move.w  #6,$52(a0)
                rts
; End of function Stage18_SegmentedWormAdvanceFollower
; Scatters the twelve linked worm segments and emits reward particles
Stage18_SegmentedWormScatterSegments:                   ; DATA XREF: ROM:0002FF18   o  ; was: sub_302CC
                bsr.w   Stage18_SegmentedWormGetRandomScatterVelocity
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                clr.w   $56(a5)
                clr.b   $21(a5)
                move.w  #0,d0
                jsr     (Pickup_SpawnRandomFromCurrentObject).l
                move.w  #$A,d5
                movea.w $44(a5),a4
                move.w  #$B,d6
Stage18_SegmentedWormScatterNextSegment:                ; CODE XREF: Stage18_SegmentedWormScatterSegments+6A   j
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Stage18_SegmentedWormConfigureScatteredSegment
                move.w  #$FF,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  $10(a4),$10(a0)
                move.w  $14(a4),$14(a0)
Stage18_SegmentedWormConfigureScatteredSegment:         ; CODE XREF: Stage18_SegmentedWormScatterSegments+30   j
                bsr.w   Stage18_SegmentedWormGetRandomScatterVelocity
                move.l  d0,$18(a4)
                move.l  d1,$1C(a4)
                move.w  d5,$56(a4)
                move.w  #4,4(a4)
                clr.b   $21(a4)
                addi.w  #$A,d5
                movea.w $44(a4),a4
                dbf     d6,Stage18_SegmentedWormScatterNextSegment
                move.b  #$C1,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                rts
; End of function Stage18_SegmentedWormScatterSegments
; Returns a randomized scatter velocity from the lower half of the angle table
Stage18_SegmentedWormGetRandomScatterVelocity:          ; CODE XREF: Stage18_SegmentedWormScatterSegments   p  ; was: sub_3034A
                                        ; sub_302CC:Stage18_SegmentedWormConfigureScatteredSegment   p
                jsr     (RandomNumber).l
                andi.w  #$FE,d0
                addi.w  #$100,d0
                bsr.w   Math_LookupSineCosinePairDuplicate
                ext.l   d0
                asl.l   #3,d0
                ext.l   d1
                asl.l   #3,d1
                rts
; End of function Stage18_SegmentedWormGetRandomScatterVelocity
; Updates falling entity that periodically spawns projectiles
Stage18_SegmentedWormUpdateFallingSegment:              ; DATA XREF: ROM:0002FF1A   o  ; was: sub_30366
                                        ; ROM:000304A2   o
                bsr.w   Stage18_SegmentedWormAdvanceSpinFrame
                addi.l  #$2000,$1C(a5)
                clr.w   d0
                clr.w   d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   Stage18_SegmentedWormHideFallingSegment
                addq.w  #1,$56(a5)
                move.w  $56(a5),d0
                andi.w  #$1F,d0
                bne.w   Entity_UpdateReturn
Stage18_SegmentedWormEmitFallingParticle:               ; CODE XREF: Stage18_SegmentedWormUpdateFallingSegment+4E   j
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.w   Entity_UpdateReturn
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                movea.w a0,a4
                jsr     (Projectile_InitType88).l
                bsr.w   Stage18_SegmentedWormInitializeParticleVelocity
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormHideFallingSegment:                ; CODE XREF: Stage18_SegmentedWormUpdateFallingSegment+16   j
                move.w  #$1000,2(a5)
                bra.w   Stage18_SegmentedWormEmitFallingParticle
; End of function Stage18_SegmentedWormUpdateFallingSegment
; Updates animation and graphics based on rotation counter
Stage18_SegmentedWormAdvanceSpinFrame:                  ; CODE XREF: Stage18_SegmentedWormUpdateFallingSegment   p  ; was: sub_303B8
                move.w  $54(a5),d0
                lea     Stage18_SegmentedWormDirectionFrameTables(pc),a0
                movea.l (a0,d0.w),a0
                move.w  $58(a5),d0
                move.w  d0,d1
                andi.w  #$20,d0                         ; ' '
                addi.w  #4,d1
                andi.w  #$1C,d1
                or.w    d1,d0
                move.w  d0,$58(a5)
                lea     Stage18_SegmentedWormTileAttributes(pc),a1
                move.l  (a0,d0.w),8(a5)
                lsr.w   #1,d0
                move.w  (a1,d0.w),$E(a5)
                rts
; End of function Stage18_SegmentedWormAdvanceSpinFrame
; Selects a directional animation frame from the segment velocity
Stage18_SegmentedWormGetDirectionFrame:                 ; CODE XREF: Stage18_SegmentedWormUpdateHead+10   p  ; was: sub_303F0
                                        ; Stage18_SegmentedWormUpdateFollower+18   p
                bsr.w   Stage18_SegmentedWormClassifyVelocityDirection
                tst.l   $18(a5)
                bpl.w   Entity_UpdateReturn
                addi.w  #$20,d0                         ; ' '
                rts
; End of function Stage18_SegmentedWormGetDirectionFrame
; Classifies horizontal and vertical velocity into a directional frame index
Stage18_SegmentedWormClassifyVelocityDirection:         ; CODE XREF: Stage18_SegmentedWormGetDirectionFrame   p  ; was: sub_30402
                move.l  $1C(a5),d1
                move.l  $18(a5),d0
                bmi.s   Stage18_SegmentedWormClassifyLeftwardMotion
                tst.l   d1
                bpl.s   Stage18_SegmentedWormClassifyRightwardDownMotion
                neg.l   d1
                cmpi.l  #$40000,d1
                bcc.s   Stage18_SegmentedWormFrameSteepUp
                cmpi.l  #$10000,d1
                bcc.s   Stage18_SegmentedWormFrameRightUp
                bra.s   Stage18_SegmentedWormFrameRightLevel
; ---------------------------------------------------------------------------
Stage18_SegmentedWormClassifyRightwardDownMotion:       ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+C   j
                cmpi.l  #$40000,d1
                bcc.s   Stage18_SegmentedWormFrameSteepDown
                cmpi.l  #$10000,d1
                bcc.s   Stage18_SegmentedWormFrameRightDown
                bra.s   Stage18_SegmentedWormFrameRightLevel
; End of function Stage18_SegmentedWormClassifyVelocityDirection
Stage18_SegmentedWormUnusedReturn:
                rts
; End of function Stage18_SegmentedWormUnusedReturn

; Classifies vertical motion when horizontal velocity is negative
Stage18_SegmentedWormClassifyLeftwardMotion:            ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+8   j  ; was: sub_30438
                tst.l   d1
                bpl.s   Stage18_SegmentedWormClassifyLeftwardDownMotion
                neg.l   d1
                cmpi.l  #$40000,d1
                bcc.s   Stage18_SegmentedWormFrameSteepUp
                cmpi.l  #$10000,d1
                bcc.s   Stage18_SegmentedWormFrameLeftUp
                bra.s   Stage18_SegmentedWormFrameLeftLevel
; ---------------------------------------------------------------------------
Stage18_SegmentedWormClassifyLeftwardDownMotion:        ; CODE XREF: Stage18_SegmentedWormClassifyLeftwardMotion+2   j
                cmpi.l  #$40000,d1
                bcc.s   Stage18_SegmentedWormFrameSteepDown
                cmpi.l  #$10000,d1
                bcc.s   Stage18_SegmentedWormFrameLeftDown
                bra.s   Stage18_SegmentedWormFrameLeftLevel
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameRightLevel:                   ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+20   j
                                        ; Stage18_SegmentedWormClassifyVelocityDirection+32   j
                move.w  #0,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameRightDown:                    ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+30   j
                move.w  #4,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameSteepDown:                    ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+28   j
                                        ; Stage18_SegmentedWormClassifyLeftwardMotion+1E   j
                move.w  #8,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameLeftDown:                     ; CODE XREF: Stage18_SegmentedWormClassifyLeftwardMotion+26   j
                move.w  #$C,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameLeftLevel:                    ; CODE XREF: Stage18_SegmentedWormClassifyLeftwardMotion+16   j
                                        ; Stage18_SegmentedWormClassifyLeftwardMotion+28   j
                move.w  #$10,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameLeftUp:                       ; CODE XREF: Stage18_SegmentedWormClassifyLeftwardMotion+14   j
                move.w  #$14,d0
                rts
; ---------------------------------------------------------------------------
Stage18_SegmentedWormFrameSteepUp:                      ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+16   j
                                        ; Stage18_SegmentedWormClassifyLeftwardMotion+C   j
                move.w  #$18,d0
                rts
; End of function Stage18_SegmentedWormClassifyLeftwardMotion
; Returns the rightward/upward directional frame index
Stage18_SegmentedWormFrameRightUp:                      ; CODE XREF: Stage18_SegmentedWormClassifyVelocityDirection+1E   j  ; was: sub_3048C
                move.w  #$1C,d0
                rts
; End of function Stage18_SegmentedWormFrameRightUp
; Dispatches an active linked segment by its state
Stage18_SegmentedWormSegmentDispatch:                   ; CODE XREF: Stage18_SegmentedWormMain+4   j  ; was: sub_30492
                move.w  4(a5),d0
                lea     Stage18_SegmentedWormSegmentStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage18_SegmentedWormSegmentDispatch
; ---------------------------------------------------------------------------
Stage18_SegmentedWormSegmentStateTable: dc.w    Stage18_SegmentedWormSegmentInit-*  ; DATA XREF: Stage18_SegmentedWormSegmentDispatch+4   o
                dc.w    Stage18_SegmentedWormSegmentFollow-*
                dc.w    Stage18_SegmentedWormUpdateFallingSegment-*

; Attributes: thunk
; Initializes a linked worm segment
Stage18_SegmentedWormSegmentInit:                       ; DATA XREF: ROM:Stage18_SegmentedWormSegmentStateTable   o  ; was: sub_304A4
                bra.w   Stage18_SegmentedWormActivateSegment
; End of function Stage18_SegmentedWormSegmentInit
; Skips follower propagation when horizontal velocity is zero
Stage18_SegmentedWormSegmentFollow:                     ; DATA XREF: ROM:000304A0   o  ; was: sub_304A8
                tst.l   $18(a5)
                beq.w   Entity_UpdateReturn
; End of function Stage18_SegmentedWormSegmentFollow
; Propagates predecessor motion and updates the segment direction frame
Stage18_SegmentedWormUpdateFollower:                    ; DATA XREF: ROM:OrphanedCrossStageEntityStateTable   o  ; was: sub_304B0
                bsr.w   Stage18_SegmentedWormAdvanceFollower
                addi.l  #$2000,$1C(a5)
                move.w  $54(a5),d0
                lea     Stage18_SegmentedWormDirectionFrameTables(pc),a0
                movea.l (a0,d0.w),a0
                bsr.w   Stage18_SegmentedWormGetDirectionFrame
                move.w  d0,$58(a5)
                lea     Stage18_SegmentedWormTileAttributes(pc),a1
                move.l  (a0,d0.w),8(a5)
                lsr.w   #1,d0
                move.w  (a1,d0.w),$E(a5)
                rts
; End of function Stage18_SegmentedWormUpdateFollower
; State dispatcher for falling object enemy type
