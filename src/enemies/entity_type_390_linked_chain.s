; Type-$390 linked eight-segment attack object; visual owner is unproved
; Type $390 owns the chain, type $394 updates ordinary segments, and type $398
; updates the damageable terminal segment and scatters the chain when it is hit
; REVIEWED VIS-001: role-only name; visible bird is separate type $90; see docs/unknowns.md
EntityType390_ControllerMain:                           ; was: sub_310E6
                bsr.w   EntityType390_CullAtLeftEdge
                move.w  4(a5),d0
                lea     EntityType390_ControllerStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function EntityType390_ControllerMain
; ---------------------------------------------------------------------------
EntityType390_ControllerStates: dc.w    EntityType390_ControllerInit-*  ; was: off_310F6
                dc.w    EntityType390_SpawnSegments-*
                dc.w    EntityType390_ControllerIdle-*

; Initializes the invisible chain controller
EntityType390_ControllerInit:                           ; was: sub_310FC
                move.w  #$D00,2(a5)
                move.b  #$50,$20(a5)                    ; 'P'
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_ControllerInit
; Allocates and links eight segments, promoting the last one to type $398
EntityType390_SpawnSegments:                            ; was: sub_3110E
                cmpi.w  #$180,$10(a5)
                bcc.w   Entity_UpdateReturn
                move.w  #7,d7
                move.w  a5,$44(a5)
EntityType390_SpawnNextSegment:                         ; was: loc_31120
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   EntityType390_HandleAllocationFailure
                movea.w $44(a5),a1
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),$14(a0)
                move.w  #$394,(a0)
                move.w  d7,d1
                lsl.w   #3,d1
                addq.w  #1,d1
                move.w  d1,$46(a0)
                clr.w   4(a0)
                move.w  a1,$44(a0)
                move.w  a0,$44(a5)
                dbf     d7,EntityType390_SpawnNextSegment
                move.w  #$398,(a0)
                move.w  a5,$48(a0)
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
EntityType390_HandleAllocationFailure:                  ; was: loc_31164
                move.w  #$1000,2(a5)
                rts
; End of function EntityType390_SpawnSegments
EntityType390_ControllerIdle:                           ; was: nullsub_74
                rts
; End of function EntityType390_ControllerIdle

; Marks every linked segment for removal after the controller crosses the left edge
EntityType390_CullAtLeftEdge:                           ; was: sub_3116E
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcc.w   Entity_UpdateReturn
                movea.w a5,a4
                move.w  #7,d7
EntityType390_CullNextSegment:                          ; was: loc_3117E
                tst.w   $44(a4)
                beq.s   EntityType390_ContinueCull
                movea.w $44(a4),a4
                move.w  #$1000,2(a4)
EntityType390_ContinueCull:                             ; was: loc_3118E
                dbf     d7,EntityType390_CullNextSegment
                rts
; End of function EntityType390_CullAtLeftEdge
; Dispatches an ordinary type-$394 chain segment
EntityType390_SegmentMain:                              ; was: sub_31194
                move.w  4(a5),d0
                lea     EntityType390_SegmentStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function EntityType390_SegmentMain
; ---------------------------------------------------------------------------
EntityType390_SegmentStates:    dc.w    EntityType390_SegmentInit-*  ; was: off_311A0
                dc.w    EntityType390_BeginAttackCycle-*
                dc.w    EntityType390_ExpandRadiusAndFire-*
                dc.w    EntityType390_SweepAngleBackward-*
                dc.w    EntityType390_SweepAngleForward-*
                dc.w    EntityType390_RetractRadius-*
                dc.w    EntityType390_SegmentFallAndFire-*

; Initializes an ordinary chain segment
EntityType390_SegmentInit:                              ; was: sub_311AE
                move.w  #$CD00,2(a5)
                move.w  #$1B9,$E(a5)
                move.l  #EntityType390_SegmentMapping,8(a5)
                move.b  #$60,$20(a5)                    ; '`'
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_SegmentInit
; Counts down the segment delay, then begins its polar attack cycle
EntityType390_BeginAttackCycle:                         ; was: sub_311CE
                bsr.w   Entity_UpdatePolarPositionFromParent
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$180,$40(a5)
                clr.w   $42(a5)
                move.w  #4,4(a5)
EntityType390_FireRandomShot:                           ; was: loc_311EA
                                        ; EntityType390_TryRandomShot+8   j
                jsr     (RandomNumber).l
                andi.w  #$FE,d0
                addi.w  #$100,d0
                move.w  d0,d4
                move.w  $10(a5),d5
                move.w  #$148,d6
                jmp     Projectile_SpawnType1A8AtAngle
; End of function EntityType390_BeginAttackCycle
; Starts the terminal segment's attack cycle and plays its cue
EntityType390_TerminalBeginAttackCycle:                 ; was: sub_31208
                bsr.w   Entity_UpdatePolarPositionFromParent
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$180,$40(a5)
                clr.w   $42(a5)
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #4,4(a5)
                bra.w   EntityType390_FireRandomShot
; End of function EntityType390_TerminalBeginAttackCycle
; Expands the polar radius while periodically firing a random-angle shot
EntityType390_ExpandRadiusAndFire:                      ; was: sub_31232
                                        ; ROM:000313B8   o
                bsr.w   Entity_UpdatePolarPositionFromParent
                bsr.w   EntityType390_TryRandomShot
                addq.w  #8,$42(a5)
                cmpi.w  #$40,$42(a5)                    ; '@'
                bne.w   Entity_UpdateReturn
                move.w  #3,$46(a5)
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_ExpandRadiusAndFire
; Sweeps the polar angle backward from $180 to just below $140
EntityType390_SweepAngleBackward:                       ; was: sub_31254
                                        ; ROM:000313BA   o
                bsr.w   Entity_UpdatePolarPositionFromParent
                subq.w  #2,$40(a5)
                cmpi.w  #$140,$40(a5)
                bcc.w   Entity_UpdateReturn
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_SweepAngleBackward
; Emits a fragment cluster when the polar angle reaches $19E
EntityType390_EmitFragmentClusterAtAngle:               ; was: sub_3126C
                cmpi.w  #$19E,$40(a5)
                bne.w   Entity_UpdateReturn
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                move.w  #2,d3
                move.w  (PlayerXPosition).w,d0
                cmp.w   $10(a5),d0
                bcs.s   EntityType390_AimFragmentClusterLeft
                clr.w   d4
                bra.w   Projectile_SpawnFragmentCluster
; ---------------------------------------------------------------------------
EntityType390_AimFragmentClusterLeft:                   ; was: loc_31292
                move.w  #$10,d4
                bra.w   Projectile_SpawnFragmentCluster
; End of function EntityType390_EmitFragmentClusterAtAngle
; Runs the terminal segment's angle-gated fragment attack, then falls through
EntityType390_TerminalFragmentAttack:                   ; was: sub_3129A
                bsr.w   EntityType390_EmitFragmentClusterAtAngle
; End of function EntityType390_TerminalFragmentAttack
; Sweeps the polar angle forward to $1A0, repeating the attack three times
EntityType390_SweepAngleForward:                        ; was: sub_3129E
                bsr.w   Entity_UpdatePolarPositionFromParent
                addq.w  #2,$40(a5)
                cmpi.w  #$1A0,$40(a5)
                bcs.w   Entity_UpdateReturn
                subq.w  #1,$46(a5)
                beq.s   EntityType390_AdvanceAfterOrbit
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
EntityType390_AdvanceAfterOrbit:                        ; was: loc_312BC
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_SweepAngleForward
; Retracts an ordinary segment's polar radius through its parent position
EntityType390_RetractRadius:                            ; was: sub_312C2
                bsr.w   Entity_UpdatePolarPositionFromParent
                subq.w  #8,$42(a5)
                cmpi.w  #$FFF8,$42(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$C0,$46(a5)
                move.w  #2,4(a5)
                rts
; End of function EntityType390_RetractRadius
; Retracts the terminal segment while firing, then plays its cue
EntityType390_TerminalRetractAndFire:                   ; was: sub_312E2
                bsr.w   Entity_UpdatePolarPositionFromParent
                bsr.w   EntityType390_TryRandomShot
                subq.w  #8,$42(a5)
                cmpi.w  #$FFF8,$42(a5)
                bne.w   Entity_UpdateReturn
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$C0,$46(a5)
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_TerminalRetractAndFire
; Fires the shared random-angle shot on one frame out of four
EntityType390_TryRandomShot:                            ; was: sub_3130E
                                        ; EntityType390_TerminalRetractAndFire+4   p
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                beq.w   EntityType390_FireRandomShot
                rts
; End of function EntityType390_TryRandomShot
; Holds the terminal segment in place and fires until its timer reaches $A0
EntityType390_TerminalWaitAndFire:                      ; was: sub_3131C
                bsr.w   Entity_UpdatePolarPositionFromParent
                bsr.w   EntityType390_TryRandomShot
                subq.w  #1,$46(a5)
                cmpi.w  #$A0,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  #2,4(a5)
                rts
; End of function EntityType390_TerminalWaitAndFire
; Duplicate of Math_LookupSineCosinePair used by later enemy code
; In: d0.w = even angle-table offset. Out: d0.w = cosine, d1.w = sine
Math_LookupSineCosinePairDuplicate:                     ; was: sub_3133A
                                        ; Stage18_SegmentedWormGetRandomScatterVelocity+E   p
                lea     (Math_QuarterSineTable).l,a0
                move.w  (a0,d0.w),d1
                addi.w  #$80,d0
                andi.w  #$1FE,d0
                move.w  (a0,d0.w),d0
                rts
; End of function Math_LookupSineCosinePairDuplicate
; Updates the damageable terminal segment and scatters the chain when hit
EntityType390_TerminalMain:                             ; was: sub_31352
                cmpi.w  #$E,4(a5)
                bcc.w   EntityType390_DispatchTerminalState
                tst.w   $24(a5)
                bpl.w   EntityType390_DispatchTerminalState
                movea.w $48(a5),a4
                move.w  #7,d7
EntityType390_ScatterNextSegment:                       ; was: loc_3136C
                movea.w $44(a4),a4
                move.w  #$C,4(a4)
                jsr     (RandomNumber).l
                andi.w  #$7E,d0                         ; '~'
                addi.w  #$140,d0
                bsr.w   Math_LookupSineCosinePairDuplicate
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a4)
                ext.l   d1
                asl.l   #3,d1
                move.l  d1,$1C(a4)
                clr.b   $21(a4)
                dbf     d7,EntityType390_ScatterNextSegment
                move.w  #$E,4(a5)
                rts
; ---------------------------------------------------------------------------
EntityType390_DispatchTerminalState:                    ; was: loc_313A8
                                        ; EntityType390_TerminalMain+E   j
                move.w  4(a5),d0
                lea     EntityType390_TerminalStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function EntityType390_TerminalMain
; ---------------------------------------------------------------------------
EntityType390_TerminalStates:   dc.w    EntityType390_TerminalInit-*  ; was: off_313B4
                dc.w    EntityType390_TerminalBeginAttackCycle-*
                dc.w    EntityType390_ExpandRadiusAndFire-*
                dc.w    EntityType390_SweepAngleBackward-*
                dc.w    EntityType390_TerminalFragmentAttack-*
                dc.w    EntityType390_TerminalRetractAndFire-*
                dc.w    EntityType390_TerminalWaitAndFire-*
                dc.w    EntityType390_TerminalFallAndFire-*

; Initializes the damageable terminal segment
EntityType390_TerminalInit:                             ; was: sub_313C4
                move.w  #$CD00,2(a5)
                move.w  #$1B9,$E(a5)
                move.l  #EntityType390_TerminalMapping,8(a5)
                move.b  #$5C,$20(a5)                    ; '\'
                move.w  #$64,$24(a5)                    ; 'd'
                move.b  #$C0,$21(a5)
                move.l  #$F010F010,$2C(a5)
                move.l  #$E818E818,$28(a5)
                clr.b   $22(a5)
                move.b  #5,$23(a5)
                move.w  #$28,$26(a5)                    ; '('
                addq.w  #2,4(a5)
                rts
; End of function EntityType390_TerminalInit
; Accelerates downward and spawns doubled-velocity projectiles every 4 frames until Y >= 1A0h
EntityType390_TerminalFallAndFire:                      ; was: sub_31410
                addi.l  #$1800,$1C(a5)
                cmpi.w  #$1A0,$14(a5)
                bcc.w   EntityType390_RemoveSegment
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                bsr.w   Projectile_SpawnRandomAngleShot
                asl     $18(a4)
                asl     $1C(a4)
                rts
; End of function EntityType390_TerminalFallAndFire
; Accelerates downward slowly and spawns projectiles every 8 frames until Y >= 180h
EntityType390_SegmentFallAndFire:                       ; was: sub_31446
                addi.l  #$1000,$1C(a5)
                cmpi.w  #$180,$14(a5)
                bcc.s   EntityType390_RemoveSegment
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
; End of function EntityType390_SegmentFallAndFire
; Spawns projectile with sound BBh at calculated angle toward player with offset positioning
Projectile_SpawnRandomAngleShot:                        ; was: sub_3146C
                                        ; EntityType390_TerminalFallAndFire+28   p
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Projectile_InitType88).l
                movea.w a0,a4
                jsr     (RandomNumber).l
                andi.w  #$1FE,d0
                bsr.w   Math_LookupSineCosinePairDuplicate
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a4)
                asl.l   #2,d0
                add.l   $10(a5),d0
                move.l  d0,$10(a4)
                ext.l   d1
                asl.l   #3,d1
                move.l  d1,$1C(a4)
                asl.l   #2,d1
                add.l   $14(a5),d1
                move.l  d1,$14(a4)
                rts
; End of function Projectile_SpawnRandomAngleShot
; Marks a falling segment for removal
EntityType390_RemoveSegment:                            ; was: sub_314BA
                                        ; EntityType390_SegmentFallAndFire+E   j
                move.w  #$1000,2(a5)
                rts
; End of function EntityType390_RemoveSegment
