Stage10_BeetleWaveController:                           ; was: sub_2E6C2
                move.w  #$120,$10(a5)
                move.w  #$154,$14(a5)
                move.w  4(a5),d0
                lea     Stage10_BeetleWaveStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage10_BeetleWaveController
; ---------------------------------------------------------------------------
Stage10_BeetleWaveStateOffsets: dc.w    Stage10_BeetleWaveInitState-*  ; was: off_2E6DA
                dc.w    Stage10_BeetleWaveSpawnState-*
                dc.w    Stage10_BeetleWaveWaitForBeetleState-*
                dc.w    Stage10_BeetleWaveDelayState-*

; Initializes the invisible Stage 10 beetle-wave controller
Stage10_BeetleWaveInitState:                            ; was: sub_2E6E2
                move.w  #$D00,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage10_BeetleWaveInitState
; Creates the next beetle at a randomized vertical offset and screen edge
Stage10_BeetleWaveSpawnState:                           ; was: sub_2E6EE
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage10_BeetleWaveSpawnState_Return
                jsr     (RandomNumber).l
                move.w  a0,$4C(a5)
                addq.w  #2,4(a5)
                move.w  #$2D4,(a0)
                move.w  $14(a5),$14(a0)
                move.w  $5E(a5),$5E(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                add.w   d0,$14(a0)
                move.b  (RandomNumberState).w,d0
                andi.b  #1,d0
                beq.s   Stage10_BeetleWaveSpawnState_PlaceAtLeftEdge
                move.w  #$1C8,$10(a0)
                rts
; ---------------------------------------------------------------------------
; Places the new beetle at the left screen edge
Stage10_BeetleWaveSpawnState_PlaceAtLeftEdge:           ; was: loc_2E734
                move.w  #$78,$10(a0)                    ; 'x'
Stage10_BeetleWaveSpawnState_Return:                    ; was: locret_2E73A
                rts
; End of function Stage10_BeetleWaveSpawnState
; Waits until the current beetle leaves its type-$2D4 controller
Stage10_BeetleWaveWaitForBeetleState:                   ; was: sub_2E73C
                movea.w $4C(a5),a0
                cmpi.w  #$2D4,(a0)
                beq.s   Stage10_BeetleWaveWaitForBeetleState_Return
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Stage10_BeetleWaveWaitForBeetleState_Return:            ; was: locret_2E750
                rts
; End of function Stage10_BeetleWaveWaitForBeetleState
; Delays before the next beetle, or finishes in the special stage variant
Stage10_BeetleWaveDelayState:                           ; was: sub_2E752
                subq.w  #1,$48(a5)
                bne.s   Stage10_BeetleWaveDelayState_Return
                cmpi.w  #$1B8,(Entity57Type).w
                beq.s   Stage10_BeetleWaveDelayState_FinishSpecialStage
                move.w  #2,4(a5)
Stage10_BeetleWaveDelayState_Return:                    ; was: locret_2E766
                rts
; ---------------------------------------------------------------------------
Stage10_BeetleWaveDelayState_FinishSpecialStage:        ; was: loc_2E768
                bset    #4,2(a5)
                rts
; End of function Stage10_BeetleWaveDelayState
; Initializes Stage 10 beetle enemy sprite
Enemy_Stage10BeetleInit:                                ; was: sub_2E770
                move.w  #$EF00,2(a5)
                moveq   #0,d1
                ori.w   #$8000,d1
                move.w  d1,$E(a5)
                move.b  #0,$20(a5)
                move.b  #$80,$21(a5)
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F010F010,$28(a5)
                lea     Enemy_Stage10BeetleSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                move.l  #Enemy_Stage10BeetleLoopAnimation,8(a5)
                clr.w   $C(a5)
                rts
; End of function Enemy_Stage10BeetleInit
; ---------------------------------------------------------------------------
Enemy_Stage10BeetleSpriteParameters:    dc.w    $1804, $1100  ; was: word_2E7C8

; Updates the Stage 10 beetle or converts it to defeat debris
Enemy_Stage10BeetleController:                          ; was: sub_2E7CC
                tst.w   4(a5)
                beq.s   Enemy_Stage10BeetleController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertStage10BeetleToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertStage10BeetleToDefeatDebris
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Dispatches beetle movement, facing, and grounded animation
Enemy_Stage10BeetleController_UpdateState:              ; was: loc_2E7EC
                bsr.s   Enemy_DispatchStage10BeetleState
                bsr.w   Enemy_UpdateHorizontalFlipFromVelocity
                tst.l   $1C(a5)
                bne.s   Enemy_Stage10BeetleController_Return
                move.l  #Enemy_Stage10BeetleLoopAnimation,8(a5)
                clr.w   $C(a5)
Enemy_Stage10BeetleController_Return:                   ; was: locret_2E804
                rts
; End of function Enemy_Stage10BeetleController
; Dispatches the Stage 10 beetle's current state
Enemy_DispatchStage10BeetleState:                       ; was: sub_2E806
                move.w  4(a5),d0
                lea     Enemy_Stage10BeetleStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage10BeetleState
; ---------------------------------------------------------------------------
Enemy_Stage10BeetleStateOffsets:    dc.w    Enemy_Stage10BeetleInitState-*  ; was: off_2E812
                dc.w    Enemy_Stage10BeetleInitialDelayState-*
                dc.w    Enemy_Stage10BeetleRoamState-*
                dc.w    Enemy_Stage10BeetleBounceState-*
                dc.w    Enemy_Stage10BeetleExitState-*

; Initializes beetle sprite, direction, and first movement delay
Enemy_Stage10BeetleInitState:                           ; was: sub_2E81C
                moveq   #0,d0
                bsr.w   Enemy_Stage10BeetleInit
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                cmpi.w  #$120,$10(a5)
                bcc.s   Enemy_Stage10BeetleInitState_MoveLeft
                move.w  #1,$18(a5)
                bra.s   Enemy_Stage10BeetleInitialDelayState
; ---------------------------------------------------------------------------
Enemy_Stage10BeetleInitState_MoveLeft:                  ; was: loc_2E83C
                move.w  #$FFFF,$18(a5)
; Waits before entering randomized roaming movement
Enemy_Stage10BeetleInitialDelayState:                   ; was: loc_2E842
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage10BeetleInitialDelayState_Return
                clr.w   $4C(a5)
                bsr.w   Enemy_Stage10BeetleLoadNextMoveDelay
                move.w  #$100,$4E(a5)
                addq.w  #2,4(a5)
Enemy_Stage10BeetleInitialDelayState_Return:            ; was: locret_2E85A
                rts
; End of function Enemy_Stage10BeetleInitState
; Updates randomized roaming until the bounce sequence begins
Enemy_Stage10BeetleRoamState:                           ; was: sub_2E85C
                btst    #0,$5F(a5)
                beq.s   Enemy_Stage10BeetleRoamState_UpdateMotion
                subq.w  #1,$4E(a5)
                beq.s   Enemy_Stage10BeetleRoamState_BeginBounce
Enemy_Stage10BeetleRoamState_UpdateMotion:              ; was: loc_2E86A
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage10BeetleRoamState_Return
                bsr.w   Enemy_Stage10BeetleLoadNextMoveDelay
                move.b  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                add.w   d0,d0
                lea     (Math_SineTable).l,a1
                move.w  (a1,d0.w),d0
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a5)
Enemy_Stage10BeetleRoamState_Return:                    ; was: locret_2E890
                rts
; ---------------------------------------------------------------------------
Enemy_Stage10BeetleRoamState_BeginBounce:               ; was: loc_2E892
                clr.l   $18(a5)
                move.l  #$FFFB8000,$1C(a5)
                move.w  #3,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage10BeetleRoamState
; Loads the next cyclic movement delay from the timing table
Enemy_Stage10BeetleLoadNextMoveDelay:                   ; was: sub_2E8AA
                                        ; Enemy_Stage10BeetleRoamState+14   p
                move.w  $4C(a5),d0
                move.w  Enemy_Stage10BeetleMoveDelays(pc,d0.w),$48(a5)
                addq.w  #2,$4C(a5)
                cmpi.w  #$20,$4C(a5)                    ; ' '
                bcs.s   Enemy_Stage10BeetleLoadNextMoveDelay_Return
                clr.w   $4C(a5)
Enemy_Stage10BeetleLoadNextMoveDelay_Return:            ; was: locret_2E8C4
                rts
; End of function Enemy_Stage10BeetleLoadNextMoveDelay
; ---------------------------------------------------------------------------
Enemy_Stage10BeetleMoveDelays:  dc.w    $10, 8, $20, $40, 8, $10, 8, $10, 4, 8, $10, $40, 8, 8, 4, $20  ; was: word_2E8C6

; Applies gravity and performs three terrain-aligned bounces
Enemy_Stage10BeetleBounceState:                         ; was: sub_2E8E6
                addi.l  #$2000,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_Stage10BeetleBounceState_Return
                cmpi.w  #$150,$14(a5)
                bgt.w   Enemy_ConvertStage12FallingObjectToEffect
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Collision_InitBufferPointers).l
                tst.w   d2
                beq.s   Enemy_Stage10BeetleBounceState_Return
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Physics_AlignToTerrain).l
                move.l  #$FFFE0000,$1C(a5)
                subq.w  #1,$4A(a5)
                bne.s   Enemy_Stage10BeetleBounceState_Return
                addq.w  #2,4(a5)
Enemy_Stage10BeetleBounceState_Return:                  ; was: locret_2E92A
                                        ; Enemy_Stage10BeetleBounceState+26   j
                rts
; End of function Enemy_Stage10BeetleBounceState
; Applies gravity until the beetle exits through the lower boundary
Enemy_Stage10BeetleExitState:                           ; was: sub_2E92C
                addi.l  #$2000,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_Stage10BeetleExitState_Return
                cmpi.w  #$150,$14(a5)
                bgt.w   Enemy_ConvertStage12FallingObjectToEffect
Enemy_Stage10BeetleExitState_Return:                    ; was: locret_2E946
                rts
; End of function Enemy_Stage10BeetleExitState
; Converts an inactive or defeated beetle to type-$2D8 debris
Enemy_ConvertStage10BeetleToDefeatDebris:               ; was: sub_2E948
                                        ; Enemy_Stage10BeetleController+12   j
                tst.w   $24(a5)
                bmi.s   Enemy_ConvertStage10BeetleToDefeatDebris_Activate
                btst    #4,$22(a5)
                bne.s   Enemy_ConvertStage10BeetleToDefeatDebris_Activate
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Effect_SpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Enemy_ConvertStage10BeetleToDefeatDebris_Activate:      ; was: loc_2E97A
                                        ; Enemy_ConvertStage10BeetleToDefeatDebris+C   j
                clr.w   4(a5)
                move.w  #$2D8,(a5)
                move.w  #$10,$48(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #$FFFB8000,$1C(a5)
                rts
; End of function Enemy_ConvertStage10BeetleToDefeatDebris
; Updates falling beetle debris, then creates an explosion and pickup
Enemy_UpdateStage10BeetleDefeatDebris:                  ; was: sub_2E99E
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateStage10BeetleDefeatDebris_Blink
                jsr     (Effect_SpawnExplosionA).l
                moveq   #$F,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateStage10BeetleDefeatDebris_Blink:            ; was: loc_2E9BA
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateStage10BeetleDefeatDebris_Return
                bclr    #7,2(a5)
Enemy_UpdateStage10BeetleDefeatDebris_Return:           ; was: locret_2E9CE
                rts
; End of function Enemy_UpdateStage10BeetleDefeatDebris
; Unreachable copy of the defeat-conversion half of the live converter above
Orphaned_Stage10BeetleConvertIfActive:
                tst.w   $24(a5)                         ; was: sub_2E9D0
                bmi.s   Orphaned_Stage10BeetleConvertIfActiveReturn
                btst    #4,$22(a5)
                bne.s   Orphaned_Stage10BeetleConvertIfActiveReturn
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Effect_SpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Orphaned_Stage10BeetleConvertIfActiveReturn:            ; was: locret_2E9FA
                                        ; Orphaned_Stage10BeetleConvertIfActive+C   j
                rts
; End of function Orphaned_Stage10BeetleConvertIfActive
