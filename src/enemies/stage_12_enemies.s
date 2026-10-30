Enemy_InitStage12ShrimpSprite:                          ; was: sub_2E2BE
                                        ; Enemy_Stage12LauncherInitState+2   p
                move.w  #$EF00,2(a5)
                moveq   #0,d1
                ori.w   #$8000,d1
                move.w  d1,$E(a5)
                move.b  #$10,$20(a5)
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F808F808,$28(a5)
                lea     Enemy_Stage12ShrimpSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_InitStage12ShrimpSprite
; ---------------------------------------------------------------------------
Enemy_Stage12ShrimpSpriteParameters:    dc.w    $1804, $1100, $1802, $1100  ; was: word_2E304

; Selects the current shrimp animation
Enemy_UpdateStage12ShrimpAnimation:                     ; was: sub_2E30C
                                        ; Enemy_Stage12LauncherController+2C   j
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateStage12ShrimpAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_Stage12ShrimpAnimations(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateStage12ShrimpAnimation_Return:              ; was: locret_2E31E
                rts
; End of function Enemy_UpdateStage12ShrimpAnimation
; ---------------------------------------------------------------------------
Enemy_Stage12ShrimpAnimations:  dc.l    Enemy_ShrimpSlowAnimation  ; was: off_2E320
                dc.l    Enemy_ShrimpFastAnimation

; Updates the Stage 12 floater or converts it to shared defeat debris
Enemy_Stage12FloaterController:                         ; was: sub_2E328
                tst.w   4(a5)
                beq.s   Enemy_Stage12FloaterController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertStage12ObjectToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertStage12ObjectToDefeatDebris
                bclr    #7,$22(a5)
                bne.w   Enemy_ConvertStage12ObjectToDefeatDebris
                jsr     (RandomNumber).l
                clr.w   6(a5)
Enemy_Stage12FloaterController_UpdateState:             ; was: loc_2E352
                bsr.s   Enemy_DispatchStage12FloaterState
                bra.w   Enemy_UpdateStage12ShrimpAnimation
; End of function Enemy_Stage12FloaterController
; Dispatches the Stage 12 floater's current state
Enemy_DispatchStage12FloaterState:                      ; was: sub_2E358
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_Stage12FloaterStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage12FloaterState
; ---------------------------------------------------------------------------
Enemy_Stage12FloaterStateOffsets:   dc.w    Enemy_Stage12FloaterInitState-*  ; was: off_2E368
                dc.w    Enemy_Stage12FloaterWaitForPlayerState-*
                dc.w    Enemy_Stage12FloaterRiseState-*
                dc.w    Enemy_Stage12FloaterReleaseState-*
                dc.w    Enemy_UpdateStage12FallingObject-*
                dc.w    Enemy_Stage12SharedNoOpState-*
                dc.w    Enemy_Stage12FloaterNoOpState-*

; Initializes the floater sprite and first player-distance wait state
Enemy_Stage12FloaterInitState:                          ; was: sub_2E376
                moveq   #0,d0
                bsr.w   Enemy_InitStage12ShrimpSprite
                move.w  #4,$5C(a5)
                addq.w  #2,4(a5)
; Waits until the player is close enough to start upward motion
Enemy_Stage12FloaterWaitForPlayerState:                 ; was: loc_2E386
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$60,d0                         ; '`'
                bcc.w   Enemy_Stage12FloaterWaitForPlayerState_Return
                move.l  #$FFFE0000,$1C(a5)
                addq.w  #2,4(a5)
Enemy_Stage12FloaterWaitForPlayerState_Return:          ; was: locret_2E3A0
                rts
; End of function Enemy_Stage12FloaterInitState
; Advances after the floater rises above its Y boundary
Enemy_Stage12FloaterRiseState:                          ; was: sub_2E3A2
                cmpi.w  #$150,$14(a5)
                bcc.s   Enemy_Stage12FloaterRiseState_Return
                addq.w  #2,4(a5)
Enemy_Stage12FloaterRiseState_Return:                   ; was: locret_2E3AE
                rts
; End of function Enemy_Stage12FloaterRiseState
; Waits for open terrain, then releases the floater with randomized horizontal motion
Enemy_Stage12FloaterReleaseState:                       ; was: sub_2E3B0
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Collision_InitBufferPointers).l
                tst.w   d2
                bne.s   Enemy_Stage12FloaterReleaseState_Return
                addq.w  #2,4(a5)
                move.b  #$C0,$21(a5)
                move.l  #$FFFB8000,$1C(a5)
                move.w  #8,$5C(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                add.w   d0,d0
                lea     (Math_SineTable).l,a1
                move.w  (a1,d0.w),d0
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a5)
Enemy_Stage12FloaterReleaseState_Return:                ; was: locret_2E3F2
                rts
; End of function Enemy_Stage12FloaterReleaseState
; Applies gravity and converts a Stage 12 falling object after it crosses the lower bound
Enemy_UpdateStage12FallingObject:                       ; was: sub_2E3F4
                                        ; ROM:0002E630   o
                addi.l  #$2000,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_UpdateStage12FallingObject_Return
                ori.w   #$1000,$E(a5)
                cmpi.w  #$150,$14(a5)
                blt.s   Enemy_UpdateStage12FallingObject_Return
                bra.s   Enemy_ConvertStage12FallingObjectToEffect
; ---------------------------------------------------------------------------
Enemy_UpdateStage12FallingObject_Return:                ; was: locret_2E414
                                        ; Enemy_UpdateStage12FallingObject+1C   j
                rts
; ---------------------------------------------------------------------------
Enemy_ConvertStage12FallingObjectToEffect:              ; was: loc_2E416
                                        ; Enemy_UpdateStage12FallingObject+1E   j
                movea.w a5,a0
                jsr     (Projectile_InitType88FromCurrent).l
                move.l  #SharedProjectileDuration4Animation,8(a5)
                move.w  #$C000,$E(a5)
                move.l  #$FFFD8000,$1C(a5)
                rts
; End of function Enemy_UpdateStage12FallingObject
Enemy_Stage12SharedNoOpState:                           ; was: nullsub_67
                                        ; ROM:0002E632   o
                rts
; End of function Enemy_Stage12SharedNoOpState

Enemy_Stage12FloaterNoOpState:                          ; was: nullsub_68
                rts
; End of function Enemy_Stage12FloaterNoOpState

; Converts an inactive Stage 12 floater or launcher to shared defeat debris
Enemy_ConvertStage12ObjectToDefeatDebris:               ; was: sub_2E43A
                                        ; Enemy_Stage12FloaterController+12   j
                tst.w   $24(a5)
                bmi.s   Enemy_ConvertStage12ObjectToDefeatDebris_Activate
                btst    #4,$22(a5)
                bne.s   Enemy_ConvertStage12ObjectToDefeatDebris_Activate
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Effect_SpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Enemy_ConvertStage12ObjectToDefeatDebris_Activate:      ; was: loc_2E46C
                                        ; Enemy_ConvertStage12ObjectToDefeatDebris+C   j
                clr.w   4(a5)
                move.w  #$2D0,(a5)
                move.w  #$10,$48(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #$FFFB8000,$1C(a5)
                rts
; End of function Enemy_ConvertStage12ObjectToDefeatDebris
; Updates shared Stage 12 defeat debris, then explodes and drops a pickup unless the yacht is active
Enemy_UpdateStage12DefeatDebris:                        ; was: sub_2E490
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateStage12DefeatDebris_Blink
                jsr     (Effect_SpawnExplosionA).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                cmpi.w  #$1B8,(Entity57Type).w
                beq.s   Enemy_UpdateStage12DefeatDebris_HideInsteadOfPickup
                moveq   #$F,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateStage12DefeatDebris_HideInsteadOfPickup:    ; was: loc_2E4BE
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_UpdateStage12DefeatDebris_Blink:                  ; was: loc_2E4C6
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateStage12DefeatDebris_Return
                bclr    #7,2(a5)
Enemy_UpdateStage12DefeatDebris_Return:                 ; was: locret_2E4DA
                rts
; End of function Enemy_UpdateStage12DefeatDebris
; Updates the yacht-attached Stage 12 turret and its periodic bird spawn
Enemy_Stage12TurretController:                          ; was: sub_2E4DC
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_Stage12TurretHide
                bsr.s   Enemy_DispatchStage12TurretState
                move.l  (Entity57XPos).w,$10(a5)
                move.l  (Entity57YPos).w,$14(a5)
                cmpi.w  #4,4(a5)
                bcc.w   Enemy_Stage12TurretSpawnPeriodicBird
                rts
; End of function Enemy_Stage12TurretController
; Dispatches the Stage 12 turret's current state
Enemy_DispatchStage12TurretState:                       ; was: sub_2E4FE
                move.w  4(a5),d0
                lea     Enemy_Stage12TurretStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage12TurretState
; ---------------------------------------------------------------------------
Enemy_Stage12TurretStateOffsets:    dc.w    Enemy_Stage12TurretInit-*  ; was: off_2E50A
                dc.w    Enemy_Stage12TurretIdle-*
                dc.w    Enemy_Stage12TurretDelayState-*
                dc.w    Enemy_Stage12TurretAllocateLauncherState-*
                dc.w    Enemy_Stage12TurretActivateLauncherState-*
                dc.w    Enemy_Stage12TurretBeginResetState-*
                dc.w    Enemy_Stage12TurretResetDelayState-*

; Initializes turret sprite
Enemy_Stage12TurretInit:                                ; was: sub_2E518
                move.w  #$D00,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage12TurretInit
; Turret idle state
Enemy_Stage12TurretIdle:                                ; was: sub_2E524
                cmpi.w  #$1B8,(Entity57Type).w
                bne.s   Enemy_Stage12TurretIdle_Return
                cmpi.w  #6,(Entity57State).w
                bcs.s   Enemy_Stage12TurretIdle_Return
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
Enemy_Stage12TurretIdle_Return:                         ; was: locret_2E53E
                                        ; Enemy_Stage12TurretIdle+E   j
                rts
; End of function Enemy_Stage12TurretIdle
; Waits before allocating a launcher object
Enemy_Stage12TurretDelayState:                          ; was: sub_2E540
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage12TurretDelayState_Return
                addq.w  #2,4(a5)
Enemy_Stage12TurretDelayState_Return:                   ; was: locret_2E54A
                rts
; End of function Enemy_Stage12TurretDelayState
; Allocates a dormant object slot for the next launcher
Enemy_Stage12TurretAllocateLauncherState:               ; was: sub_2E54C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_Stage12TurretAllocateLauncherState_Return
                move.w  #$10,(a0)
                move.w  a0,$4A(a5)
                addq.w  #2,4(a5)
Enemy_Stage12TurretAllocateLauncherState_Return:        ; was: locret_2E560
                rts
; End of function Enemy_Stage12TurretAllocateLauncherState
; Activates the reserved launcher after the turret reaches its Y threshold
Enemy_Stage12TurretActivateLauncherState:               ; was: sub_2E562
                cmpi.w  #$140,$14(a5)
                bcs.s   Enemy_Stage12TurretActivateLauncherState_Return
                movea.w $4A(a5),a0
                move.w  #$2E4,(a0)
                addq.w  #2,4(a5)
                move.w  #$38,$4E(a0)                    ; '8'
                move.w  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$50,d0                         ; 'P'
                move.w  d0,$4C(a0)
Enemy_Stage12TurretActivateLauncherState_Return:        ; was: locret_2E58C
                rts
; End of function Enemy_Stage12TurretActivateLauncherState
; Starts the turret reset delay
Enemy_Stage12TurretBeginResetState:                     ; was: sub_2E58E
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage12TurretBeginResetState
; Returns the turret to its delay state when the reset timer expires
Enemy_Stage12TurretResetDelayState:                     ; was: sub_2E59A
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage12TurretResetDelayState_Return
                move.w  #6,4(a5)
Enemy_Stage12TurretResetDelayState_Return:              ; was: locret_2E5A6
                rts
; End of function Enemy_Stage12TurretResetDelayState
; Periodically spawns a bird enemy at the top of the screen
Enemy_Stage12TurretSpawnPeriodicBird:                   ; was: sub_2E5A8
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                bne.s   Enemy_Stage12TurretSpawnPeriodicBird_CheckSlowInterval
                move.w  (FrameCounter).w,d7
                andi.w  #$FF,d7
                bne.s   Enemy_Stage12TurretSpawnPeriodicBird_Return
                bra.s   Enemy_Stage12TurretSpawnPeriodicBird_Spawn
; ---------------------------------------------------------------------------
Enemy_Stage12TurretSpawnPeriodicBird_CheckSlowInterval:  ; was: loc_2E5BE
                move.w  (FrameCounter).w,d7
                andi.w  #$1FF,d7
                bne.s   Enemy_Stage12TurretSpawnPeriodicBird_Return
Enemy_Stage12TurretSpawnPeriodicBird_Spawn:             ; was: loc_2E5C8
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_Stage12TurretSpawnPeriodicBird_Return
                move.w  #$90,(a0)
                move.w  #1,$5E(a0)
                move.w  #$B0,$14(a0)
Enemy_Stage12TurretSpawnPeriodicBird_Return:            ; was: locret_2E5E0
                                        ; Enemy_Stage12TurretSpawnPeriodicBird+1E   j
                rts
; End of function Enemy_Stage12TurretSpawnPeriodicBird
; Hides the turret by writing the bit-4 flag byte to its sprite word
Enemy_Stage12TurretHide:                                ; was: sub_2E5E2
                move.w  #$1000,2(a5)
                rts
; End of function Enemy_Stage12TurretHide
; Updates the Stage 12 launcher or converts it to shared defeat debris
Enemy_Stage12LauncherController:                        ; was: sub_2E5EA
                tst.w   4(a5)
                beq.s   Enemy_Stage12LauncherController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertStage12ObjectToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertStage12ObjectToDefeatDebris
                bclr    #7,$22(a5)
                bne.w   Enemy_ConvertStage12ObjectToDefeatDebris
                jsr     (RandomNumber).l
                clr.w   6(a5)
Enemy_Stage12LauncherController_UpdateState:            ; was: loc_2E614
                bsr.s   Enemy_DispatchStage12LauncherState
                bra.w   Enemy_UpdateStage12ShrimpAnimation
; End of function Enemy_Stage12LauncherController
; Dispatches the Stage 12 launcher's current state
Enemy_DispatchStage12LauncherState:                     ; was: sub_2E61A
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_Stage12LauncherStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage12LauncherState
; ---------------------------------------------------------------------------
Enemy_Stage12LauncherStateOffsets:  dc.w    Enemy_Stage12LauncherInitState-*  ; was: off_2E62A
                dc.w    Enemy_Stage12LauncherRiseToYachtState-*
                dc.w    Enemy_Stage12LauncherLaunchState-*
                dc.w    Enemy_UpdateStage12FallingObject-*
                dc.w    Enemy_Stage12SharedNoOpState-*

; Initializes the launcher and attaches it to the yacht
Enemy_Stage12LauncherInitState:                         ; was: sub_2E634
                moveq   #4,d0
                bsr.w   Enemy_InitStage12ShrimpSprite
                move.b  #0,$20(a5)
                move.b  #$80,$21(a5)
                move.b  #$40,$23(a5)                    ; '@'
                move.w  #$ED00,2(a5)
                move.w  #4,$5C(a5)
                addq.w  #2,4(a5)
; Rises to the yacht a pixel a frame: $4E is both the delay and the Y offset
Enemy_Stage12LauncherRiseToYachtState:                  ; was: loc_2E65C
                bsr.w   Enemy_Stage12LauncherUpdatePosition
                subq.w  #1,$4E(a5)
                bne.s   Enemy_Stage12LauncherRiseToYachtState_Return
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Enemy_Stage12LauncherRiseToYachtState_Return:           ; was: locret_2E670
                rts
; End of function Enemy_Stage12LauncherInitState
; Places the launcher at the yacht position plus its $4C and $4E offsets
Enemy_Stage12LauncherUpdatePosition:                    ; was: sub_2E672
                                        ; sub_2E690   p
                move.l  (Entity57XPos).w,$10(a5)
                move.l  (Entity57YPos).w,$14(a5)
                move.w  $4C(a5),d0
                add.w   d0,$10(a5)
                move.w  $4E(a5),d0
                add.w   d0,$14(a5)
                rts
; End of function Enemy_Stage12LauncherUpdatePosition
; Detaches and launches the Stage 12 launcher after its preparation timer
Enemy_Stage12LauncherLaunchState:                       ; was: sub_2E690
                bsr.w   Enemy_Stage12LauncherUpdatePosition
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage12LauncherLaunchState_Return
                ori.b   #$40,$21(a5)                    ; '@'
                move.w  #$EF00,2(a5)
                move.l  #$FFFB8000,$1C(a5)
                move.w  #8,$5C(a5)
                move.l  #$FFFE0000,$18(a5)
                addq.w  #2,4(a5)
Enemy_Stage12LauncherLaunchState_Return:                ; was: locret_2E6C0
                rts
; End of function Enemy_Stage12LauncherLaunchState
