Entity_UpdateValkirieBattle:                            ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_5575E
                tst.w   4(a5)
                beq.w   Entity_DispatchValkirieBattleState
                tst.w   8(a5)
                beq.s   Entity_DispatchValkirieBattleState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Entity_UpdateValkirieBattleActive
                btst    #1,(BossColorEffectFlags).w
                bne.s   Entity_UpdateValkirieBattleActive
                tst.w   (BossHealth).w
                bne.s   Entity_UpdateValkirieBattleActive
                moveq   #2,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Entity_UpdateValkirieBattleActive:                      ; CODE XREF: Entity_UpdateValkirieBattle+14   j  ; was: loc_5578A
                                        ; Entity_UpdateValkirieBattle+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #0,d0
                jsr     Gfx_UpdateSevenForceBattlePalette(pc)  ; (pc)
                nop
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$BC(a5)
Entity_DispatchValkirieBattleState:                     ; CODE XREF: Entity_UpdateValkirieBattle+4   j  ; was: loc_557AA
                                        ; Entity_UpdateValkirieBattle+C   j
                move.w  4(a5),d0
                movea.w Entity_ValkirieBattleStateOffsets(pc,d0.w),a0
                adda.l  #Entity_InitValkirieBattleState0,a0
                jmp     (a0)
; End of function Entity_UpdateValkirieBattle
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateOffsets:  dc.w    Entity_InitValkirieBattleState0-Entity_InitValkirieBattleState0  ; was: off_557BA
                                        ; DATA XREF: Entity_UpdateValkirieBattle+50   r
                dc.w    Entity_UpdateValkirieBattleState2-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState4-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState6-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState8-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleStateA-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleStateC-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieAirborneStateEOr16-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState10-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState12-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState14-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieAirborneStateEOr16-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState18-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState1A-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState1C-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState1E-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState20-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState22-Entity_InitValkirieBattleState0
                dc.w    Entity_UpdateValkirieBattleState24-Entity_InitValkirieBattleState0

; Initialize the Valkirie controller, its 25-part body, and auxiliary objects
Entity_InitValkirieBattleState0:                        ; DATA XREF: Entity_UpdateValkirieBattle+54   o  ; was: sub_557E0
                                        ; ROM:Entity_ValkirieBattleStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$19,d7
                movea.l #Boss_ValkirieMetaspritePartDescriptors,a0
                movea.l #Boss_ValkirieMetaspriteInitialAngles,a1
                movea.l #Boss_ValkirieMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_ValkirieMetaspritePoseAngles,$2FC(a5)
                move.l  #Valkirie_PoseFrameData,$35C(a5)
                move.w  #$42C,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                movea.l #Boss_ValkirieIntroObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                bsr.w   Entity_InitValkirieAuxiliaryGroup
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  #2,$1DE(a5)
                bra.w   Entity_StartValkirieBattleState4
; End of function Entity_InitValkirieBattleState0
; Initialize Valkirie position, motion, and active-part pointers
Entity_InitValkirieBattleFields:                        ; was: sub_5584A
                move.w  #2,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$140,$8B4(a5)
; End of function Entity_InitValkirieBattleFields
; Apply state-two animation events to the active body-part pointers
Entity_UpdateValkirieBattleState2:                      ; DATA XREF: ROM:000557BC   o  ; was: sub_55882
                bclr    #0,$23E(a5)
                beq.s   Entity_ValkirieBattleState2CheckSecondPart
                move.w  #$CEC0,$4A(a5)
                move.w  #$140,$8B4(a5)
Entity_ValkirieBattleState2CheckSecondPart:             ; CODE XREF: Entity_UpdateValkirieBattleState2+6   j  ; was: loc_55896
                bclr    #1,$23E(a5)
                beq.s   Entity_RenderValkirieBattleState2
                move.w  #$CC80,$4A(a5)
                move.w  #$140,$674(a5)
Entity_RenderValkirieBattleState2:                      ; CODE XREF: Entity_UpdateValkirieBattleState2+1A   j  ; was: loc_558AA
                lea     Valkirie_State2PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; End of function Entity_UpdateValkirieBattleState2
; Start the timed pre-battle pose in state four
Entity_StartValkirieBattleState4:                       ; CODE XREF: Entity_InitValkirieBattleState0+66   j  ; was: sub_558B4
                move.w  #4,4(a5)
                move.w  #$100,$54(a5)
                move.w  #$C0,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  $10(a5),$70(a5)
                move.w  #$C680,$48(a5)
                move.w  #$CC80,$4A(a5)
                bset    #0,$62(a5)
                move.w  #$140,$674(a5)
; Count down state four and publish the boss message on expiration
Entity_UpdateValkirieBattleState4:                      ; DATA XREF: ROM:000557BE   o  ; was: loc_558EE
                subq.w  #1,$11C(a5)
                bpl.s   Entity_RenderValkirieBattleState4
                addq.w  #2,4(a5)
                moveq   #8,d0
                jsr     (BossMessage_Start).l
Entity_RenderValkirieBattleState4:                      ; CODE XREF: Entity_StartValkirieBattleState4+3E   j  ; was: loc_55900
                lea     Valkirie_State4To8PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; End of function Entity_StartValkirieBattleState4
; Wait in state six for the shared battle gate, then enter state eight
Entity_UpdateValkirieBattleState6:                      ; DATA XREF: ROM:000557C0   o  ; was: sub_5590A
                tst.w   (MessageSequenceState).w
                bne.s   Entity_RenderValkirieBattleState6
                addq.w  #2,4(a5)
                clr.b   (BossColorEffectFlags).w
                clr.w   (PlayerScriptStateOffset).w
                subi.w  #$58,(CameraXLowerBound).w      ; 'X'
                bra.w   Entity_StartValkirieBattleState8
; ---------------------------------------------------------------------------
Entity_RenderValkirieBattleState6:                      ; CODE XREF: Entity_UpdateValkirieBattleState6+4   j  ; was: loc_55926
                lea     Valkirie_State4To8PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_StartValkirieBattleState8:                       ; CODE XREF: Entity_UpdateValkirieBattleState6+18   j  ; was: loc_55930
                                        ; Entity_UpdateValkirieBattleStateA+6   j
                move.w  #8,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
; End of function Entity_UpdateValkirieBattleState6
; Choose the next attack when state-eight animation event zero fires
Entity_UpdateValkirieBattleState8:                      ; DATA XREF: ROM:000557C2   o  ; was: sub_5594E
                bclr    #0,$23E(a5)
                beq.s   Entity_RenderValkirieBattleState8
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$80,d0
                bpl.s   Entity_ValkirieBattleState8CheckRandomStateSelection
                bra.w   Entity_StartValkirieBattleState12
; ---------------------------------------------------------------------------
Entity_ValkirieBattleState8CheckRandomStateSelection:   ; CODE XREF: Entity_UpdateValkirieBattleState8+12   j  ; was: loc_55966
                cmpi.w  #$700,$BC(a5)
                bmi.s   Entity_ValkirieBattleState8CheckState22Selection
                cmpi.w  #$840,$BC(a5)
                bpl.s   Entity_ValkirieBattleState8CheckState22Selection
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.w   Entity_StartValkirieBattleState14
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.w   Entity_StartValkirieBattleState18
Entity_ValkirieBattleState8CheckState22Selection:       ; CODE XREF: Entity_UpdateValkirieBattleState8+1E   j  ; was: loc_5598E
                                        ; Entity_UpdateValkirieBattleState8+26   j
                cmpi.w  #$720,$BC(a5)
                bmi.s   Entity_ValkirieBattleState8SelectStateA
                cmpi.w  #$820,$BC(a5)
                bpl.s   Entity_ValkirieBattleState8SelectStateA
                cmpi.w  #$F8,d0
                bpl.w   Entity_StartValkirieBattleState22
Entity_ValkirieBattleState8SelectStateA:                ; CODE XREF: Entity_UpdateValkirieBattleState8+46   j  ; was: loc_559A6
                                        ; Entity_UpdateValkirieBattleState8+4E   j
                bra.w   Entity_StartValkirieBattleStateA
; ---------------------------------------------------------------------------
Entity_RenderValkirieBattleState8:                      ; CODE XREF: Entity_UpdateValkirieBattleState8+6   j  ; was: loc_559AA
                bsr.w   Entity_SetFacingField54FromPlayerXDelta
                lea     Valkirie_State4To8PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_StartValkirieBattleStateA:                       ; CODE XREF: Entity_UpdateValkirieBattleState8:Entity_ValkirieBattleState8SelectStateA   j  ; was: loc_559B8
                move.w  #$A,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.b   $23E(a5)
                move.w  #$CC80,d0
                move.w  #$CC80,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
; End of function Entity_UpdateValkirieBattleState8
; Choose an airborne branch from player distance and relative facing in state $A
Entity_UpdateValkirieBattleStateA:                      ; CODE XREF: Entity_UpdateValkirieBattleStateC+42   j  ; was: sub_559D8
                                        ; DATA XREF: ROM:000557C4   o
                tst.w   $58(a5)
                bpl.s   Entity_ValkirieBattleStateAHandleAnimationEvent
                bra.w   Entity_StartValkirieBattleState8
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateAHandleAnimationEvent:        ; CODE XREF: Entity_UpdateValkirieBattleStateA+4   j  ; was: loc_559E2
                bclr    #0,$23E(a5)
                beq.s   Entity_RenderValkirieBattleStateA
                jsr     Entity_GetValkiriePlayerDeltaAndRelativeSign(pc)  ; (pc)
                nop
                bmi.s   Entity_ValkirieBattleStateASelectStateCRise
                cmpi.w  #$30,d0                         ; '0'
                bmi.s   Entity_ValkirieBattleStateASelectStateCRise
                cmpi.w  #$A0,d0
                bpl.s   Entity_ValkirieBattleStateASelectStateCRise
                move.w  d0,d1
                cmpi.w  #$46,d1                         ; 'F'
                bpl.s   Entity_ValkirieBattleStateASelectMediumVelocity
                move.l  #$8000,d0
                bra.s   Entity_ValkirieBattleStateAStartCharge
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateASelectMediumVelocity:        ; CODE XREF: Entity_UpdateValkirieBattleStateA+2C   j  ; was: loc_55A0E
                move.l  #$FFFE8000,d0
                cmpi.w  #$70,d1                         ; 'p'
                bpl.s   Entity_ValkirieBattleStateASelectFarVelocity
                bra.s   Entity_ValkirieBattleStateAStartCharge
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateASelectFarVelocity:           ; CODE XREF: Entity_UpdateValkirieBattleStateA+40   j  ; was: loc_55A1C
                tst.w   (DifficultyMode).w
                beq.s   Entity_ValkirieBattleStateAStartCharge
                move.l  #$FFFDC000,d0
Entity_ValkirieBattleStateAStartCharge:                 ; CODE XREF: Entity_UpdateValkirieBattleStateA+34   j  ; was: loc_55A28
                                        ; Entity_UpdateValkirieBattleStateA+42   j
                bsr.w   Entity_SetValkirieHorizontalVelocityByFacing
                bra.w   Entity_StartValkirieBattleStateE
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateASelectStateCRise:            ; CODE XREF: Entity_UpdateValkirieBattleStateA+18   j  ; was: loc_55A30
                                        ; Entity_UpdateValkirieBattleStateA+1E   j
                bra.s   Entity_StartValkirieBattleStateC
; ---------------------------------------------------------------------------
Entity_RenderValkirieBattleStateA:                      ; CODE XREF: Entity_UpdateValkirieBattleStateA+10   j  ; was: loc_55A32
                lea     Valkirie_StateAAndCPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_StartValkirieBattleStateC:                       ; CODE XREF: Entity_UpdateValkirieBattleStateA:Entity_ValkirieBattleStateASelectStateCRise   j  ; was: loc_55A3C
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                move.w  a5,d0
                move.w  a5,d1
                bsr.w   Entity_SelectValkirieActivePartPair
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$FFFE0000,d0
                bsr.w   Entity_SetValkirieHorizontalVelocityByFacing
                move.b  #$5A,d0                         ; 'Z'
                jsr     (Sound_QueueSFXRequest).l
; End of function Entity_UpdateValkirieBattleStateA
; Decelerate the state-$C rise until animation event zero returns to state $A
Entity_UpdateValkirieBattleStateC:                      ; DATA XREF: ROM:000557C6   o  ; was: sub_55A68
                addi.l  #$2000,$1C(a5)
                bclr    #0,$23E(a5)
                bne.s   Entity_CompleteValkirieBattleStateC
                lea     Valkirie_StateAAndCPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_CompleteValkirieBattleStateC:                    ; CODE XREF: Entity_UpdateValkirieBattleStateC+E   j  ; was: loc_55A82
                move.w  #$A,4(a5)
                clr.b   $23E(a5)
                move.w  #$CEC0,d0
                move.w  #$CC80,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.b  #$5A,d0                         ; 'Z'
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Entity_UpdateValkirieBattleStateA
; End of function Entity_UpdateValkirieBattleStateC
; Start state $22 with both active-part pointers set to $CEC0
Entity_StartValkirieBattleState22:                      ; CODE XREF: Entity_UpdateValkirieBattleState8+54   j  ; was: sub_55AAE
                move.w  #$22,4(a5)                      ; '"'
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CEC0,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
; End of function Entity_StartValkirieBattleState22
; Apply state-$22 animation events and enforce facing-dependent screen bounds
Entity_UpdateValkirieBattleState22:                     ; DATA XREF: ROM:000557DC   o  ; was: sub_55ACE
                bclr    #7,$23E(a5)
                beq.s   Entity_ValkirieBattleState22CheckPartEvents
                tst.w   $54(a5)
                bne.s   Entity_ValkirieBattleState22CheckLowerBoundary
                cmpi.w  #$810,$BC(a5)
                bmi.s   Entity_ValkirieBattleState22CheckPartEvents
                bra.w   Entity_StartValkirieBattleState8
; ---------------------------------------------------------------------------
Entity_ValkirieBattleState22CheckLowerBoundary:         ; CODE XREF: Entity_UpdateValkirieBattleState22+C   j  ; was: loc_55AE8
                cmpi.w  #$730,$BC(a5)
                bmi.w   Entity_StartValkirieBattleState8
Entity_ValkirieBattleState22CheckPartEvents:            ; CODE XREF: Entity_UpdateValkirieBattleState22+6   j  ; was: loc_55AF2
                                        ; Entity_UpdateValkirieBattleState22+14   j
                bclr    #0,$23E(a5)
                beq.s   Entity_ValkirieBattleState22CheckSecondPart
                move.w  #$CEC0,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
                bra.s   Entity_RenderValkirieBattleState22
; ---------------------------------------------------------------------------
Entity_ValkirieBattleState22CheckSecondPart:            ; CODE XREF: Entity_UpdateValkirieBattleState22+2A   j  ; was: loc_55B08
                bclr    #1,$23E(a5)
                beq.s   Entity_RenderValkirieBattleState22
                move.w  #$CC80,d0
                move.w  #$CC80,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
Entity_RenderValkirieBattleState22:                     ; CODE XREF: Entity_UpdateValkirieBattleState22+38   j  ; was: loc_55B1C
                                        ; Entity_UpdateValkirieBattleState22+40   j
                lea     Valkirie_State22PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; End of function Entity_UpdateValkirieBattleState22
; Start airborne state $E and select its animation script from player height
Entity_StartValkirieBattleStateE:                       ; CODE XREF: Entity_UpdateValkirieBattleStateA+54   j  ; was: sub_55B26
                move.w  #$E,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$FFFE8000,$1C(a5)
                move.w  a5,d0
                move.w  a5,d1
                bsr.w   Entity_SelectValkirieActivePartPair
                move.b  #$5A,d0                         ; 'Z'
                jsr     (Sound_QueueSFXRequest).l
                cmpi.w  #$120,(PlayerYPosition).w
                bmi.s   Entity_ValkirieBattleStateECheckMidPattern
                tst.w   (PlayerYVelocity).w
                bmi.s   Entity_ValkirieBattleStateEUsePattern01
Entity_ValkirieBattleStateEUsePattern00:                ; CODE XREF: Entity_StartValkirieBattleStateE+6E   j  ; was: loc_55B62
                move.l  #Valkirie_AirbornePattern00PoseScript,$41C(a5)
                bra.s   Entity_UpdateValkirieAirborneStateEOr16
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateECheckMidPattern:             ; CODE XREF: Entity_StartValkirieBattleStateE+34   j  ; was: loc_55B6C
                cmpi.w  #$E0,(PlayerYPosition).w
                bmi.s   Entity_ValkirieBattleStateEChooseRandomPattern
                btst    #1,(FrameCounter+1).w
                bne.s   Entity_ValkirieBattleStateEUsePattern01
                tst.w   (PlayerYVelocity).w
                bmi.s   Entity_ValkirieBattleStateEUsePattern02
Entity_ValkirieBattleStateEUsePattern01:                ; CODE XREF: Entity_StartValkirieBattleStateE+3A   j  ; was: loc_55B82
                                        ; Entity_StartValkirieBattleStateE+54   j
                move.l  #Valkirie_AirbornePattern01PoseScript,$41C(a5)
                bra.s   Entity_UpdateValkirieAirborneStateEOr16
; ---------------------------------------------------------------------------
Entity_ValkirieBattleStateEChooseRandomPattern:         ; CODE XREF: Entity_StartValkirieBattleStateE+4C   j  ; was: loc_55B8C
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Entity_ValkirieBattleStateEUsePattern00
Entity_ValkirieBattleStateEUsePattern02:                ; CODE XREF: Entity_StartValkirieBattleStateE+5A   j  ; was: loc_55B96
                move.l  #Valkirie_AirbornePattern02PoseScript,$41C(a5)
; Apply gravity in the shared state-$E/state-$16 airborne updater
Entity_UpdateValkirieAirborneStateEOr16:                ; CODE XREF: Entity_StartValkirieBattleStateE+44   j  ; was: loc_55B9E
                                        ; Entity_StartValkirieBattleStateE+64   j
                                        ; DATA XREF:
                addi.l  #$2000,$1C(a5)
                bclr    #0,$23E(a5)
                bne.s   Entity_AdvanceValkirieAirborneState
                bsr.w   Projectile_SpawnValkirieBullet
                movea.l $41C(a5),a1
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieAirborneState:                    ; CODE XREF: Entity_StartValkirieBattleStateE+86   j  ; was: loc_55BBA
                addq.w  #2,4(a5)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$858(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$CE60,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
                lea     Valkirie_State10PartMotionCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartMotionCommands
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Entity_StartValkirieBattleStateE
; Converge detached-part velocity and handle state-$10 animation events
Entity_UpdateValkirieBattleState10:                     ; DATA XREF: ROM:000557CA   o  ; was: sub_55BF0
                tst.w   $58(a5)
                bpl.s   Entity_UpdateValkirieState10PartVelocity
                clr.l   $8B8(a5)
                bsr.w   Entity_SpawnValkirieTransitionEffect
                bra.w   Entity_StartValkirieBattleState8
; ---------------------------------------------------------------------------
Entity_UpdateValkirieState10PartVelocity:               ; CODE XREF: Entity_UpdateValkirieBattleState10+4   j  ; was: loc_55C02
                tst.l   $8B8(a5)
                beq.s   Entity_CheckValkirieState10PartEvents
                bpl.s   Entity_DecelerateValkirieState10PositivePartVelocity
                addi.l  #$1000,$8B8(a5)
                bmi.s   Entity_CheckValkirieState10PartEvents
                clr.l   $8B8(a5)
                bra.s   Entity_CheckValkirieState10PartEvents
; ---------------------------------------------------------------------------
Entity_DecelerateValkirieState10PositivePartVelocity:   ; CODE XREF: Entity_UpdateValkirieBattleState10+18   j  ; was: loc_55C1A
                subi.l  #$1000,$8B8(a5)
                bpl.s   Entity_CheckValkirieState10PartEvents
                clr.l   $8B8(a5)
Entity_CheckValkirieState10PartEvents:                  ; CODE XREF: Entity_UpdateValkirieBattleState10+16   j  ; was: loc_55C28
                                        ; Entity_UpdateValkirieBattleState10+22   j
                bclr    #2,$23E(a5)
                beq.s   Entity_CheckValkirieState10CloseRangeEvent
                lea     Valkirie_State10PartHideCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartHideCommands
Entity_CheckValkirieState10CloseRangeEvent:             ; CODE XREF: Entity_UpdateValkirieBattleState10+3E   j  ; was: loc_55C3A
                bclr    #3,$23E(a5)
                beq.s   Entity_RenderValkirieBattleState10
                tst.w   (DifficultyMode).w
                beq.s   Entity_RenderValkirieBattleState10
                bsr.w   Entity_GetValkiriePlayerDeltaAndRelativeSign
                bmi.s   Entity_RenderValkirieBattleState10
                cmpi.w  #$80,d0
                bpl.s   Entity_RenderValkirieBattleState10
                bra.w   Entity_StartValkirieBattleState12
; ---------------------------------------------------------------------------
Entity_RenderValkirieBattleState10:                     ; CODE XREF: Entity_UpdateValkirieBattleState10+50   j  ; was: loc_55C58
                                        ; Entity_UpdateValkirieBattleState10+56   j
                bsr.w   Projectile_SpawnValkirieBullet
                movea.l $41C(a5),a1
                bra.w   Entity_RenderValkirieBattleAnimation
; End of function Entity_UpdateValkirieBattleState10
; ---------------------------------------------------------------------------
Valkirie_State10PartMotionCommands: dc.w    $4D, $7840, $CB60, $F808, $F808, $CBC0, $FA06, $FA06, $CC20, $FA06, $FA06, $CCE0, $FC04, $FC04, 0  ; was: word_55C64
                                        ; DATA XREF: Entity_StartValkirieBattleStateE+B6   o
Valkirie_State10PartHideCommands:   dc.w    $BF00, $540, $600, $6C0, 0  ; was: word_55C82
                                        ; DATA XREF: Entity_UpdateValkirieBattleState10+40   o

; Attempt a Valkirie bullet only on frames with FrameCounter bit zero clear
Projectile_SpawnValkirieBullet:                         ; CODE XREF: Entity_StartValkirieBattleStateE+88   p  ; was: sub_55C8C
                                        ; Entity_UpdateValkirieBattleState10:Entity_RenderValkirieBattleState10   p
                movea.w #(NineteenthEntityType-M68K_RAM),a1
                moveq   #$18,d3
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_SpawnValkirieBulletReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                beq.s   Projectile_InitValkirieBullet
Projectile_SpawnValkirieBulletReturn:                   ; CODE XREF: Projectile_SpawnValkirieBullet+C   j  ; was: locret_55CA2
                rts
; ---------------------------------------------------------------------------
Projectile_InitValkirieBullet:                          ; CODE XREF: Projectile_SpawnValkirieBullet+14   j  ; was: loc_55CA4
                moveq   #0,d4
                jmp     Projectile_InitValkirieBulletFromSource
; End of function Projectile_SpawnValkirieBullet
; ---------------------------------------------------------------------------
; Start state $14, select its visible parts, and reset the auxiliary group
Entity_StartValkirieBattleState14:                      ; CODE XREF: Entity_UpdateValkirieBattleState8+30   j  ; was: loc_55CAC
                move.w  #$14,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CC20,d0
                move.w  #$CC80,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
                move.w  #$53,$11C(a5)                   ; 'S'
                bsr.w   Entity_InitValkirieAuxiliaryGroup
; Process state-$14 animation events and its auxiliary-object timer
Entity_UpdateValkirieBattleState14:                     ; DATA XREF: ROM:000557CE   o  ; was: sub_55CD6
                tst.w   $58(a5)
                bmi.w   Entity_StartValkirieBattleState24
                bclr    #3,$23E(a5)
                beq.s   Entity_CheckValkirieState14SoundEvent
                move.w  #$CC80,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
Entity_CheckValkirieState14SoundEvent:                  ; CODE XREF: Entity_UpdateValkirieBattleState14+E   j  ; was: loc_55CF2
                bclr    #0,$23E(a5)
                beq.s   Entity_UpdateValkirieState14Timer
                move.b  #$4F,d0                         ; 'O'
                jsr     (Sound_QueueSFXRequest).l
Entity_UpdateValkirieState14Timer:                      ; CODE XREF: Entity_UpdateValkirieBattleState14+22   j  ; was: loc_55D04
                subq.w  #1,$11C(a5)
                bne.s   Entity_RenderValkirieBattleState14
                bset    #4,(ValkirieAuxFlags).w
Entity_RenderValkirieBattleState14:                     ; CODE XREF: Entity_UpdateValkirieBattleState14+32   j  ; was: loc_55D10
                lea     Valkirie_State14PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
; Enter state $24 after the state-$14 animation terminates
Entity_StartValkirieBattleState24:                      ; CODE XREF: Entity_UpdateValkirieBattleState14+4   j  ; was: loc_55D1A
                bset    #7,(ValkirieAuxFlags).w
                move.w  #$24,4(a5)                      ; '$'
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Wait in state $24 until both tracked coordinates are within 16 pixels
Entity_UpdateValkirieBattleState24:                     ; DATA XREF: ROM:000557DE   o  ; was: loc_55D34
                moveq   #0,d1
                move.w  (ThirtySecondEntityXPos).w,d0
                sub.w   $4F0(a5),d0
                bpl.s   Entity_CheckValkirieState24VerticalDistance
                neg.w   d0
Entity_CheckValkirieState24VerticalDistance:            ; CODE XREF: Entity_UpdateValkirieBattleState14+68   j  ; was: loc_55D42
                cmpi.w  #$10,d0
                bpl.s   Entity_MeasureValkirieState24VerticalDistance
                addq.w  #1,d1
Entity_MeasureValkirieState24VerticalDistance:          ; CODE XREF: Entity_UpdateValkirieBattleState14+70   j  ; was: loc_55D4A
                move.w  (ThirtySecondEntityYPos).w,d0
                sub.w   $4F4(a5),d0
                bpl.s   Entity_CheckValkirieState24Arrival
                neg.w   d0
Entity_CheckValkirieState24Arrival:                     ; CODE XREF: Entity_UpdateValkirieBattleState14+7C   j  ; was: loc_55D56
                cmpi.w  #$10,d0
                bpl.s   Entity_RenderValkirieBattleState24
                tst.w   d1
                bne.s   Entity_CompleteValkirieBattleState24
Entity_RenderValkirieBattleState24:                     ; CODE XREF: Entity_UpdateValkirieBattleState14+84   j  ; was: loc_55D60
                lea     Valkirie_State24PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_CompleteValkirieBattleState24:                   ; CODE XREF: Entity_UpdateValkirieBattleState14+88   j  ; was: loc_55D6A
                bset    #5,(ValkirieAuxFlags).w
                bra.w   Entity_StartValkirieBattleState8
; End of function Entity_UpdateValkirieBattleState14
; Start close-range response state $12 with a randomized hold timer
Entity_StartValkirieBattleState12:                      ; CODE XREF: Entity_UpdateValkirieBattleState8+14   j  ; was: sub_55D74
                                        ; Entity_UpdateValkirieBattleState10+64   j
                move.w  #$12,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                addq.w  #4,d0
                move.w  d0,$11C(a5)
                lea     Valkirie_State12PartHideCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartHideCommands
                clr.w   $54(a5)
                tst.w   d1
                bmi.s   Entity_SelectValkirieState12ActiveParts
                move.w  #$100,$54(a5)
Entity_SelectValkirieState12ActiveParts:                ; CODE XREF: Entity_StartValkirieBattleState12+32   j  ; was: loc_55DAE
                move.w  #$C6E0,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPairAtY140
                lea     Valkirie_State12PoseScript(pc),a1
                nop
                bsr.w   Entity_RenderValkirieBattleAnimation
                move.w  #$CEC0,d0
                move.w  #$CEC0,d1
                bra.w   Entity_SelectValkirieActivePartPairAtY140
; End of function Entity_StartValkirieBattleState12
; Process state-$12 part-motion and exit animation events
Entity_UpdateValkirieBattleState12:                     ; DATA XREF: ROM:000557CC   o  ; was: sub_55DD0
                bclr    #0,$23E(a5)
                beq.s   Entity_CheckValkirieState12ExitEvent
                lea     Valkirie_State12PartMotionCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartMotionCommands
                move.b  #$C6,d0
                jsr     (Sound_QueueSFXRequest).l
Entity_CheckValkirieState12ExitEvent:                   ; CODE XREF: Entity_UpdateValkirieBattleState12+6   j  ; was: loc_55DEC
                bclr    #1,$23E(a5)
                beq.s   Entity_RenderValkirieBattleState12
                subq.w  #1,$11C(a5)
                bmi.w   Entity_ExitValkirieBattleState12
                jsr     Entity_GetValkiriePlayerDeltaAndRelativeSign(pc)  ; (pc)
                nop
                bmi.w   Entity_ExitValkirieBattleState12
                cmpi.w  #$80,d0
                bmi.s   Entity_RenderValkirieBattleState12
                btst    #0,(RandomNumberState+1).w
                beq.w   Entity_ExitValkirieBattleState12
                lea     Valkirie_State12PartHideCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartHideCommands
Entity_RenderValkirieBattleState12:                     ; CODE XREF: Entity_UpdateValkirieBattleState12+22   j  ; was: loc_55E20
                                        ; Entity_UpdateValkirieBattleState12+3A   j
                bsr.w   Projectile_SpawnValkirieBullet
                lea     Valkirie_State12PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_ExitValkirieBattleState12:                       ; CODE XREF: Entity_UpdateValkirieBattleState12+28   j  ; was: loc_55E2E
                                        ; Entity_UpdateValkirieBattleState12+32   j
                lea     Valkirie_State12PartHideCommands(pc),a0
                nop
                bsr.w   Entity_ApplyValkiriePartHideCommands
                bsr.w   Entity_SpawnValkirieTransitionEffect
                bra.w   Entity_StartValkirieBattleState8
; End of function Entity_UpdateValkirieBattleState12
; ---------------------------------------------------------------------------
Valkirie_State12PartMotionCommands: dc.w    7, $3242, $CB60, $F808, $F808, $CBC0, $FA06, $FA06, $CC20, $FA06, $FA06, $CCE0, $FC04, $FC04, 0  ; was: word_55E40
                                        ; DATA XREF: Entity_UpdateValkirieBattleState12+8   o
Valkirie_State12PartHideCommands:   dc.w    $BD00, $540, $600, $6C0, 0  ; was: word_55E5E
                                        ; DATA XREF: Entity_StartValkirieBattleState12+22   o
                                        ; Entity_UpdateValkirieBattleState12+46   o

; Consume damage-flash event six and return the current frame phase in Z
Entity_TestValkirieDamageFlash:                         ; was: sub_55E68
                tst.w   (DifficultyMode).w
                beq.s   Entity_TestValkirieDamageFlashReturn
                bclr    #6,$23E(a5)
                beq.s   Entity_TestValkirieDamageFlashReturn
                btst    #0,(RandomNumberState).w
Entity_TestValkirieDamageFlashReturn:                   ; CODE XREF: Entity_TestValkirieDamageFlash+4   j  ; was: locret_55E7C
                                        ; Entity_TestValkirieDamageFlash+C   j
                rts
; End of function Entity_TestValkirieDamageFlash
; Instantiate the transition-effect object group
Entity_SpawnValkirieTransitionEffect:                   ; CODE XREF: Entity_UpdateValkirieBattleState10+A   p  ; was: sub_55E7E
                                        ; Entity_UpdateValkirieBattleState12+68   p
                lea     (Boss_ValkirieEffectObjectInitTable).l,a1
                jmp     Object_InitGroupFromTable
; End of function Entity_SpawnValkirieTransitionEffect
; Apply a packed motion command to each listed Valkirie part
Entity_ApplyValkiriePartMotionCommands:                 ; CODE XREF: Entity_StartValkirieBattleStateE+BC   p  ; was: sub_55E8A
                                        ; Entity_UpdateValkirieBattleState12+E   p
                move.w  (a0)+,d1
                moveq   #0,d2
                move.b  (a0)+,d2
                move.b  (a0)+,d3
                ext.w   d2
                swap    d2
                asr.l   #4,d2
                tst.w   $54(a5)
                bne.s   Entity_ApplyValkiriePartMotionCommandLoop
                neg.l   d2
Entity_ApplyValkiriePartMotionCommandLoop:              ; CODE XREF: Entity_ApplyValkiriePartMotionCommands+12   j  ; was: loc_55EA0
                                        ; Entity_ApplyValkiriePartMotionCommands+2C   j
                move.w  (a0)+,d0
                beq.s   Entity_ApplyValkiriePartMotionCommandsReturn
                movea.w d0,a1
                move.w  d1,$26(a1)
                move.l  d2,$18(a1)
                or.b    d3,$21(a1)
                move.l  (a0)+,$2C(a1)
                bra.s   Entity_ApplyValkiriePartMotionCommandLoop
; ---------------------------------------------------------------------------
Entity_ApplyValkiriePartMotionCommandsReturn:           ; CODE XREF: Entity_ApplyValkiriePartMotionCommands+18   j  ; was: locret_55EB8
                rts
; End of function Entity_ApplyValkiriePartMotionCommands
; Apply the first header byte as a flags mask and clear listed part motion
; The second header byte is consumed into D2 but not used by this routine
Entity_ApplyValkiriePartHideCommands:                   ; CODE XREF: Entity_UpdateValkirieBattleState10+46   p  ; was: sub_55EBA
                                        ; Entity_StartValkirieBattleState12+28   p
                move.b  (a0)+,d1
                move.b  (a0)+,d2
Entity_ApplyValkiriePartHideCommandLoop:                ; CODE XREF: Entity_ApplyValkiriePartHideCommands+12   j  ; was: loc_55EBE
                move.w  (a0)+,d0
                beq.s   Entity_ApplyValkiriePartHideCommandsReturn
                movea.w d0,a1
                and.b   d1,-$39BF(a1)
                clr.l   -$39C8(a1)
                bra.s   Entity_ApplyValkiriePartHideCommandLoop
; ---------------------------------------------------------------------------
Entity_ApplyValkiriePartHideCommandsReturn:             ; CODE XREF: Entity_ApplyValkiriePartHideCommands+6   j  ; was: locret_55ECE
                rts
; End of function Entity_ApplyValkiriePartHideCommands
; Start the multi-stage part-offset sequence at state $18
Entity_StartValkirieBattleState18:                      ; CODE XREF: Entity_UpdateValkirieBattleState8+3C   j  ; was: sub_55ED0
                move.w  #$18,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CEC0,d0
                move.w  #$CEC0,d1
                bsr.w   Entity_SelectValkirieActivePartPair
; End of function Entity_StartValkirieBattleState18
; Wait for the state-$18 animation event before advancing to state $1A
Entity_UpdateValkirieBattleState18:                     ; DATA XREF: ROM:000557D2   o  ; was: sub_55EF0
                bclr    #0,$23E(a5)
                bne.s   Entity_AdvanceValkirieBattleState1A
                lea     Valkirie_State18To1EPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieBattleState1A:                    ; CODE XREF: Entity_UpdateValkirieBattleState18+6   j  ; was: loc_55F02
                addq.w  #2,4(a5)
; Wait for the second animation event in state $1A
Entity_UpdateValkirieBattleState1A:                     ; DATA XREF: ROM:000557D4   o  ; was: loc_55F06
                bclr    #0,$23E(a5)
                bne.s   Entity_AdvanceValkirieBattleState1C
                lea     Valkirie_State18To1EPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieBattleState1C:                    ; CODE XREF: Entity_UpdateValkirieBattleState18+1C   j  ; was: loc_55F18
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                move.w  #3,(PlaneAShakeLevel).w
                move.b  #$A0,d0
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Entity_StartValkirieState1CPartFlash
; End of function Entity_UpdateValkirieBattleState18
; Raise two part offsets during state $1C
Entity_UpdateValkirieBattleState1C:                     ; DATA XREF: ROM:000557D6   o  ; was: sub_55F34
                bclr    #0,$23E(a5)
                bne.s   Entity_AdvanceValkirieBattleState1E
                addq.w  #6,$11C(a5)
                bsr.w   Entity_ApplyValkirieState1CPartOffsets
                lea     Valkirie_State18To1EPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieBattleState1E:                    ; CODE XREF: Entity_UpdateValkirieBattleState1C+6   j  ; was: loc_55F4E
                addq.w  #2,4(a5)
                bclr    #6,$2C1(a5)
; Lower the two part offsets during state $1E
Entity_UpdateValkirieBattleState1E:                     ; DATA XREF: ROM:000557D8   o  ; was: loc_55F58
                subi.w  #$A,$11C(a5)
                bmi.s   Entity_AdvanceValkirieBattleState20
                bsr.w   Entity_ApplyValkirieState1CPartOffsets
                lea     Valkirie_State18To1EPoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; ---------------------------------------------------------------------------
Entity_AdvanceValkirieBattleState20:                    ; CODE XREF: Entity_UpdateValkirieBattleState1C+2A   j  ; was: loc_55F6E
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  $2F2(a5),$2F4(a5)
                move.w  $352(a5),$354(a5)
                move.b  #$F1,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Entity_UpdateValkirieBattleState1C
; Hold the terminal animation in state $20 until it finishes
Entity_UpdateValkirieBattleState20:                     ; DATA XREF: ROM:000557DA   o  ; was: sub_55F96
                tst.w   $58(a5)
                bmi.w   Entity_StartValkirieBattleState8
                lea     Valkirie_State20PoseScript(pc),a1
                nop
                bra.w   Entity_RenderValkirieBattleAnimation
; End of function Entity_UpdateValkirieBattleState20
; Add state-$1C/$1E offset $11C to the two saved part coordinates
Entity_ApplyValkirieState1CPartOffsets:                 ; CODE XREF: Entity_UpdateValkirieBattleState1C+C   p  ; was: sub_55FA8
                                        ; Entity_UpdateValkirieBattleState1C+2C   p
                move.w  $11C(a5),d0
                move.w  $2F2(a5),d1
                add.w   d0,d1
                move.w  d1,$2F4(a5)
                move.w  $352(a5),d1
                add.w   d0,d1
                move.w  d1,$354(a5)
                rts
; End of function Entity_ApplyValkirieState1CPartOffsets
; Arm the highlighted part used by the state-$1C sequence
Entity_StartValkirieState1CPartFlash:                   ; CODE XREF: Entity_UpdateValkirieBattleState18+40   p  ; was: sub_55FC2
                bset    #6,$2C1(a5)
                move.w  #$64,$2C6(a5)                   ; 'd'
                move.l  #$F808F808,$2CC(a5)
                rts
; End of function Entity_StartValkirieState1CPartFlash
; Store d0 as X velocity, negating it only when direction field $54 is nonzero
Entity_SetValkirieHorizontalVelocityByFacing:           ; CODE XREF: Entity_UpdateValkirieBattleStateA:Entity_ValkirieBattleStateAStartCharge   p  ; was: sub_55FD8
                                        ; Entity_UpdateValkirieBattleStateA+82   p
                tst.w   $54(a5)
                beq.s   Entity_StoreValkirieHorizontalVelocity
                neg.l   d0
Entity_StoreValkirieHorizontalVelocity:                 ; CODE XREF: Entity_SetValkirieHorizontalVelocityByFacing+4   j  ; was: loc_55FE0
                move.l  d0,$18(a5)
                rts
; End of function Entity_SetValkirieHorizontalVelocityByFacing
; Select the active part pair and place the second selected part at Y=$140
Entity_SelectValkirieActivePartPairAtY140:              ; CODE XREF: Entity_UpdateValkirieBattleState6+40   p  ; was: sub_55FE6
                                        ; Entity_UpdateValkirieBattleState8+86   p
                move.w  #$140,d4
                bsr.s   Entity_SelectValkirieActivePartPair
                move.w  d4,$14(a0)
                rts
; End of function Entity_SelectValkirieActivePartPairAtY140
; Disable the old active pair and enable the pair supplied in d0/d1
Entity_SelectValkirieActivePartPair:                    ; CODE XREF: Entity_UpdateValkirieBattleStateA+70   p  ; was: sub_55FF2
                                        ; Entity_StartValkirieBattleStateE+20   p
                moveq   #0,d2
                movea.w $48(a5),a0
                bclr    d2,2(a0)
                movea.w $4A(a5),a0
                bclr    d2,2(a0)
                move.w  d0,$48(a5)
                move.w  d1,$4A(a5)
                movea.w d0,a0
                bset    d2,2(a0)
                movea.w d1,a0
                bset    d2,2(a0)
                rts
; End of function Entity_SelectValkirieActivePartPair
; Return player deltas; d3 is positive for $54!=0/dx>=0 or $54==0/dx<0
Entity_GetValkiriePlayerDeltaAndRelativeSign:           ; CODE XREF: Entity_UpdateValkirieBattleStateA+12   p  ; was: sub_5601A
                                        ; Entity_UpdateValkirieBattleState10+58   p
                jsr     (Physics_GetPlayerDelta).l
                tst.w   $54(a5)
                beq.s   Entity_CheckValkirieDeltaForZeroFacing
                tst.w   d1
                bmi.s   Entity_SetValkirieRelativeSignNegative
Entity_SetValkirieRelativeSignPositive:                 ; CODE XREF: Entity_GetValkiriePlayerDeltaAndRelativeSign+16   j  ; was: loc_5602A
                moveq   #1,d3
                rts
; ---------------------------------------------------------------------------
Entity_CheckValkirieDeltaForZeroFacing:                 ; CODE XREF: Entity_GetValkiriePlayerDeltaAndRelativeSign+A   j  ; was: loc_5602E
                tst.w   d1
                bmi.s   Entity_SetValkirieRelativeSignPositive
Entity_SetValkirieRelativeSignNegative:                 ; CODE XREF: Entity_GetValkiriePlayerDeltaAndRelativeSign+E   j  ; was: loc_56032
                moveq   #$FFFFFFFF,d3
                rts
; End of function Entity_GetValkiriePlayerDeltaAndRelativeSign
; Shared by Valkirie and Artemis: set field $54 to zero for player-left, $100 otherwise
Entity_SetFacingField54FromPlayerXDelta:                ; CODE XREF: Entity_UpdateValkirieBattleState8:Entity_RenderValkirieBattleState8   p  ; was: sub_56036
                                        ; Boss_UpdateArtemisStateE+6   p
                jsr     (Physics_GetPlayerDelta).l
                clr.w   $54(a5)
                tst.w   d1
                bmi.s   Entity_SetFacingField54FromPlayerXDeltaReturn
                move.w  #$100,$54(a5)
Entity_SetFacingField54FromPlayerXDeltaReturn:          ; CODE XREF: Entity_SetFacingField54FromPlayerXDelta+C   j  ; was: locret_5604A
                rts
; End of function Entity_SetFacingField54FromPlayerXDelta
; Advance Valkirie pose animation and render all 25 metasprite parts
Entity_RenderValkirieBattleAnimation:                   ; CODE XREF: Entity_UpdateValkirieBattleState2+2E   j  ; was: sub_5604C
                                        ; Entity_StartValkirieBattleState4+52   j
                bsr.w   Anim_UpdateValkiriePoseScript
                bsr.w   Anim_ApplyValkiriePoseToParts
                moveq   #$18,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Entity_RenderValkirieBattleAnimation
