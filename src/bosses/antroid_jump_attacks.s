; Antroid jump, slam, and projectile-wait states

; Selects jump-preparation state $10 and falls through to its handler
Boss_AntroidEnterJumpAttackPreparation:                 ; CODE XREF: Boss_AntroidReturnToNeutral+C0   j  ; was: sub_379A0
                                        ; Boss_AntroidReturnToNeutral+D4   j
                bsr.w   Boss_AntroidFacePlayer
                moveq   #$10,d0
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
; Jump preparation waits for animation phase 3 before launching
Boss_AntroidPrepareJumpAttack:                          ; DATA XREF: ROM:0003751E   o  ; was: sub_379AA
                cmpi.w  #3,$29C(a5)
                beq.s   Boss_AntroidJumpAttackLaunch
                lea     Boss_AntroidJumpAttackPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderPose
                bra.w   Boss_AntroidSelectBlinkMetasprite
; ---------------------------------------------------------------------------
Boss_AntroidJumpAttackLaunch:                           ; CODE XREF: Boss_AntroidPrepareJumpAttack+6   j  ; was: loc_379C4
                subi.w  #$3C,(BossCombatCounter).w      ; '<'
                addq.w  #2,4(a5)
                move.w  #2,(PlaneAShakeLevel).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFF30000,$1C(a5)
                move.l  #$38000,$18(a5)
                tst.w   $23C(a5)
                bne.s   Boss_AntroidJumpAttackSelectDirection
                move.l  #$28000,$18(a5)
Boss_AntroidJumpAttackSelectDirection:                  ; CODE XREF: Boss_AntroidPrepareJumpAttack+46   j  ; was: loc_379FA
                tst.w   $54(a5)
                beq.s   Boss_AntroidJumpAttackApplyGravity
                neg.l   $18(a5)
; Applies gravity and tests the linked part's landing threshold
Boss_AntroidJumpAttackApplyGravity:                     ; CODE XREF: Boss_AntroidPrepareJumpAttack+54   j  ; was: loc_37A04
                                        ; DATA XREF: ROM:00037520   o
                addi.l  #$C000,$1C(a5)
                bmi.s   Boss_AntroidJumpAttackAnimateAirborne
                movea.w $17E(a5),a0
                move.w  $14(a0),d0
                subi.w  #$142,d0
                bmi.s   Boss_AntroidJumpAttackAnimateAirborne
                sub.w   d0,$14(a5)
                bra.s   Boss_AntroidJumpAttackBeginLandingArc
; ---------------------------------------------------------------------------
Boss_AntroidJumpAttackAnimateAirborne:                  ; CODE XREF: Boss_AntroidPrepareJumpAttack+62   j  ; was: loc_37A22
                                        ; Boss_AntroidPrepareJumpAttack+70   j
                lea     Boss_AntroidJumpAttackPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpAttackBeginLandingArc:                  ; CODE XREF: Boss_AntroidPrepareJumpAttack+76   j  ; was: loc_37A30
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #4,(PlaneAShakeLevel).w
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                addq.w  #2,4(a5)
                move.l  #$FFFA0000,$1C(a5)
                move.l  $18(a5),d0
                asr.l   #2,d0
                move.l  d0,$18(a5)
; Jump attack fall state with gravity application
Boss_AntroidJumpAttackLandingState:                     ; DATA XREF: ROM:00037522   o  ; was: loc_37A60
                addi.l  #$6000,$1C(a5)
                bmi.s   Boss_AntroidJumpAttackAnimateLandingArc
                movea.w $17E(a5),a0
                cmpi.w  #$14E,$14(a0)
                bpl.w   Boss_AntroidReturnToNeutral
Boss_AntroidJumpAttackAnimateLandingArc:                ; CODE XREF: Boss_AntroidPrepareJumpAttack+BE   j  ; was: loc_37A78
                lea     Boss_AntroidReturnPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderPose
                bra.w   Boss_AntroidSelectBlinkMetasprite
; End of function Boss_AntroidPrepareJumpAttack
; Selects jump-slam preparation state $26 and falls through to its handler
Boss_AntroidEnterJumpSlamPreparation:                   ; CODE XREF: Boss_AntroidReturnToNeutral+AE   j  ; was: sub_37A8A
                                        ; Boss_AntroidReturnToNeutral+B6   j
                bsr.w   Boss_AntroidFacePlayer
                moveq   #$26,d0                         ; '&'
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
; Complex jump slam attack with trajectory tracking, ground detection, and damage triggers
Boss_AntroidJumpSlamAttack:                             ; DATA XREF: ROM:00037534   o  ; was: sub_37A94
                cmpi.w  #3,$29C(a5)
                beq.s   Boss_AntroidJumpSlamLaunch
                lea     Boss_AntroidJumpSlamFirstArcPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamLaunch:                             ; CODE XREF: Boss_AntroidJumpSlamAttack+6   j  ; was: loc_37AAA
                                        ; Boss_AntroidJumpSlamAttack+1FE   j
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$28,4(a5)                      ; '('
                move.w  #2,(PlaneAShakeLevel).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFF78000,$1C(a5)
                move.l  #$FFFE1000,$18(a5)
                tst.w   $54(a5)
                beq.s   Boss_AntroidJumpSlamApplyGravity
                neg.l   $18(a5)
; Applies gravity through the jump-slam's first arc
Boss_AntroidJumpSlamApplyGravity:                       ; CODE XREF: Boss_AntroidJumpSlamAttack+48   j  ; was: loc_37AE2
                                        ; DATA XREF: ROM:00037536   o
                subi.w  #$10,$56(a5)
                addi.l  #$8000,$1C(a5)
                bmi.s   Boss_AntroidJumpSlamAnimateFirstArc
                movea.w $17E(a5),a0
                move.w  $14(a0),d0
                subi.w  #$14A,d0
                bpl.s   Boss_AntroidJumpSlamResolveFirstLanding
Boss_AntroidJumpSlamAnimateFirstArc:                    ; CODE XREF: Boss_AntroidJumpSlamAttack+5C   j  ; was: loc_37B00
                lea     Boss_AntroidJumpSlamFirstArcPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamResolveFirstLanding:                ; CODE XREF: Boss_AntroidJumpSlamAttack+6A   j  ; was: loc_37B0E
                subi.w  #$58,(BossCombatCounter).w      ; 'X'
                bmi.s   Boss_AntroidJumpSlamBeginDeceleration
                tst.w   $54(a5)
                beq.s   Boss_AntroidJumpSlamCheckAlternateScreenBound
                cmpi.w  #$D38,$BC(a5)
                bpl.s   Boss_AntroidJumpSlamBeginDeceleration
                bra.s   Boss_AntroidJumpSlamChooseFollowup
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamCheckAlternateScreenBound:          ; CODE XREF: Boss_AntroidJumpSlamAttack+86   j  ; was: loc_37B26
                cmpi.w  #$C48,$BC(a5)
                bmi.s   Boss_AntroidJumpSlamBeginDeceleration
Boss_AntroidJumpSlamChooseFollowup:                     ; CODE XREF: Boss_AntroidJumpSlamAttack+90   j  ; was: loc_37B2E
                move.w  (RandomNumberState).w,d0
                andi.w  #$380,d0
                beq.s   Boss_AntroidJumpSlamBeginDeceleration
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$88,d0
                bmi.w   Boss_AntroidJumpSlamBeginRetryWait
                move.b  (RandomNumberState+2).w,d0
                andi.w  #$2A00,d0
                beq.w   Boss_AntroidJumpSlamBeginRetryWait
Boss_AntroidJumpSlamBeginDeceleration:                  ; CODE XREF: Boss_AntroidJumpSlamAttack+80   j  ; was: loc_37B52
                                        ; Boss_AntroidJumpSlamAttack+8E   j
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #2,(PlaneAShakeLevel).w
                clr.w   $56(a5)
                move.w  a5,$48(a5)
                movea.w $17E(a5),a0
                move.w  a0,$4A(a5)
                move.w  #$14E,$14(a0)
                clr.l   $1C(a5)
; Jump slam pre-impact horizontal deceleration
Boss_AntroidJumpSlamDecelerateHorizontal:               ; DATA XREF: ROM:00037538   o  ; was: loc_37B80
                tst.w   $58(a5)
                bmi.s   Boss_AntroidJumpSlamLaunchSecondArc
                move.l  #$1800,d0
                tst.l   $18(a5)
                bpl.s   Boss_AntroidJumpSlamApplyHorizontalDeceleration
                neg.l   d0
Boss_AntroidJumpSlamApplyHorizontalDeceleration:        ; CODE XREF: Boss_AntroidJumpSlamAttack+FC   j  ; was: loc_37B94
                sub.l   d0,$18(a5)
                lea     Boss_AntroidJumpSlamDecelerationPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamLaunchSecondArc:                    ; CODE XREF: Boss_AntroidJumpSlamAttack+F0   j  ; was: loc_37BA6
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Boss_AntroidBlinkAlternateMapping,$C8(a5)
                move.w  #5,(PlaneAShakeLevel).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFF80000,$1C(a5)
                move.l  #$78000,$18(a5)
                tst.w   $54(a5)
                beq.s   Boss_AntroidJumpSlamApplySecondArcGravity
                neg.l   $18(a5)
; Applies gravity through the jump-slam's second arc
Boss_AntroidJumpSlamApplySecondArcGravity:              ; CODE XREF: Boss_AntroidJumpSlamAttack+154   j  ; was: loc_37BEE
                                        ; DATA XREF: ROM:0003753A   o
                addi.l  #$8000,$1C(a5)
                bmi.s   Boss_AntroidJumpSlamAnimateSecondArc
                movea.w $17E(a5),a0
                move.w  $14(a0),d0
                subi.w  #$14C,d0
                bpl.s   Boss_AntroidJumpSlamResolveSecondLanding
Boss_AntroidJumpSlamAnimateSecondArc:                   ; CODE XREF: Boss_AntroidJumpSlamAttack+162   j  ; was: loc_37C06
                lea     Boss_AntroidJumpSlamSecondArcPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamResolveSecondLanding:               ; CODE XREF: Boss_AntroidJumpSlamAttack+170   j  ; was: loc_37C14
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #Boss_AntroidBlinkDefaultMapping,$C8(a5)
                clr.w   $56(a5)
                move.w  #$A,$17C(a5)
                move.w  a5,$48(a5)
                movea.w $17E(a5),a0
                move.w  a0,$4A(a5)
                move.w  #$14E,$14(a0)
                clr.l   $1C(a5)
                move.l  $18(a5),d0
                asr.l   #2,d0
                move.l  d0,$18(a5)
; Holds the post-impact pose until its delay expires
Boss_AntroidJumpSlamImpactDelay:                        ; DATA XREF: ROM:0003753C   o  ; was: loc_37C5E
                subq.w  #1,$17C(a5)
                bmi.w   Boss_AntroidReturnToNeutralLoadAnimation
                lea     Boss_AntroidJumpSlamImpactPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidJumpSlamBeginRetryWait:                     ; CODE XREF: Boss_AntroidJumpSlamAttack+AE   j  ; was: loc_37C74
                                        ; Boss_AntroidJumpSlamAttack+BA   j
                moveq   #$30,d0                         ; '0'
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
                move.w  #3,(PlaneAShakeLevel).w
                move.l  #Boss_AntroidBlinkAlternateMapping,$C8(a5)
                clr.w   $56(a5)
; Waits for animation phase 3 before retrying the jump-slam launch
Boss_AntroidJumpSlamRetryWait:                          ; DATA XREF: ROM:0003753E   o  ; was: loc_37C8C
                cmpi.w  #3,$29C(a5)
                beq.w   Boss_AntroidJumpSlamLaunch
                lea     Boss_AntroidJumpSlamRetryPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; End of function Boss_AntroidJumpSlamAttack
; Selects projectile-wait state $16 and falls through to its handler
Boss_AntroidEnterWaitState:                             ; CODE XREF: Boss_AntroidReturnToNeutral+98   j  ; was: sub_37CA4
                                        ; Boss_AntroidReturnToNeutral+C4   j
                moveq   #$16,d0
                bsr.w   Boss_AntroidEnterStateWithSecondPartSlot
; Projectile-wait pose state
Boss_AntroidWaitState:                                  ; DATA XREF: ROM:00037524   o  ; was: sub_37CAA
                tst.w   $58(a5)
                bmi.s   Boss_AntroidWaitBeginCountdown
                lea     Boss_AntroidWaitPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderPose
; ---------------------------------------------------------------------------
Boss_AntroidWaitBeginCountdown:                         ; CODE XREF: Boss_AntroidWaitState+4   j  ; was: loc_37CBE
                addq.w  #2,4(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
; Projectile-wait countdown and active update
Boss_AntroidWaitCountdown:                              ; DATA XREF: ROM:00037526   o  ; was: loc_37CD6
                move.w  #1,(PlaneAShakeLevel).w
                subq.w  #1,$11C(a5)
                bpl.s   Boss_AntroidWaitUpdateActive
                tst.w   $23E(a5)
                beq.s   Boss_AntroidWaitUpdateActive
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$40,$11C(a5)                   ; '@'
                move.w  $4A(a5),$48(a5)
                clr.w   $29C(a5)
                bra.w   Boss_AntroidNeutralState
; ---------------------------------------------------------------------------
Boss_AntroidWaitUpdateActive:                           ; CODE XREF: Boss_AntroidWaitState+36   j  ; was: loc_37D0C
                                        ; Boss_AntroidWaitState+3C   j
                btst    #1,(FrameCounter+1).w
                beq.s   Boss_AntroidWaitSpawnProjectileAndAnimate
                subq.w  #1,(BossCombatCounter).w
Boss_AntroidWaitSpawnProjectileAndAnimate:              ; CODE XREF: Boss_AntroidWaitState+68   j  ; was: loc_37D18
                bsr.w   Boss_AntroidSpawnWaitProjectile
                lea     Boss_AntroidWaitFiringPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderPose
                bsr.w   Boss_AntroidSelectBlinkMetasprite
                movea.w $11E(a5),a0
                move.w  #$14E,$14(a0)
                rts
; End of function Boss_AntroidWaitState
