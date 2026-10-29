; Update battle effects, handle completion, and dispatch the Artemis state machine
Boss_UpdateArtemis:                                     ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_57EBE
                tst.w   4(a5)
                beq.w   Boss_DispatchArtemisState
                tst.w   8(a5)
                beq.s   Boss_DispatchArtemisState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_UpdateArtemisBattleEffects
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_UpdateArtemisBattleEffects
                tst.w   (BossHealth).w
                bne.s   Boss_UpdateArtemisBattleEffects
                moveq   #8,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_UpdateArtemisBattleEffects:                        ; CODE XREF: Boss_UpdateArtemis+14   j  ; was: loc_57EEA
                                        ; Boss_UpdateArtemis+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #$12,d0
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
                clr.b   $3BD(a5)
Boss_DispatchArtemisState:                              ; CODE XREF: Boss_UpdateArtemis+4   j  ; was: loc_57F0E
                                        ; Boss_UpdateArtemis+C   j
                move.w  4(a5),d0
                movea.w Boss_ArtemisStateOffsets(pc,d0.w),a0
                adda.l  #Boss_InitArtemisState0,a0
                jmp     (a0)
; End of function Boss_UpdateArtemis
; ---------------------------------------------------------------------------
Boss_ArtemisStateOffsets:   dc.w    Boss_InitArtemisState0-Boss_InitArtemisState0  ; was: off_57F1E
                                        ; DATA XREF: Boss_UpdateArtemis+54   r
                dc.w    Boss_UpdateArtemisState2-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState4-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState6-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState8-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisStateA-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisStateC-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisStateE-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState10-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState12-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState14-Boss_InitArtemisState0
                dc.w    Boss_UpdateArtemisState16-Boss_InitArtemisState0

; Initialize the Artemis metasprite and enter state four
Boss_InitArtemisState0:                                 ; DATA XREF: Boss_UpdateArtemis+58   o  ; was: sub_57F36
                                        ; ROM:Boss_ArtemisStateOffsets   o
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$1D,d7
                movea.l #Boss_ArtemisMetaspritePartDescriptors,a0
                movea.l #Boss_ArtemisMetaspriteInitialAngles,a1
                movea.l #Boss_ArtemisMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_ArtemisMetaspritePoseAngles,$2FC(a5)
                move.l  #Artemis_PoseFrameData,$35C(a5)
                move.w  #$438,(a5)
                move.w  #$8C00,2(a5)
                clr.w   6(a5)
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  $14(a0),$14(a5)
                move.w  $18(a0),$18(a5)
                move.w  $1C(a0),$1C(a5)
                move.b  #$10,(PlayerOAMBucketOffset).w
                move.w  #2,$1DE(a5)
                bra.w   Boss_EnterArtemisState4
; End of function Boss_InitArtemisState0
; Alternate entry: initialize Artemis at a fixed position and continue in state two
Boss_InitArtemisAtFixedPosition:                        ; was: sub_57FA8
                move.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$CDA0,$4A(a5)
                move.w  #$130,$794(a5)
                move.w  a5,$48(a5)
                move.w  #$120,$10(a5)
                clr.w   (PlayerScriptStateOffset).w
; End of function Boss_InitArtemisAtFixedPosition
; State two changes the pose angle from vertical controller input
Boss_UpdateArtemisState2:                               ; DATA XREF: ROM:00057F20   o  ; was: sub_57FDA
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_CheckArtemisState2DownInput
                addq.w  #2,$56(a5)
Boss_CheckArtemisState2DownInput:                       ; CODE XREF: Boss_UpdateArtemisState2+6   j  ; was: loc_57FE6
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_NormalizeArtemisState2PoseAngle
                subq.w  #2,$56(a5)
Boss_NormalizeArtemisState2PoseAngle:                   ; CODE XREF: Boss_UpdateArtemisState2+12   j  ; was: loc_57FF2
                andi.w  #$1FE,$56(a5)
                lea     Artemis_State2And4PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; End of function Boss_UpdateArtemisState2
; Enter state four with its initial vertical motion and pose state
Boss_EnterArtemisState4:                                ; CODE XREF: Boss_InitArtemisState0+6E   j  ; was: sub_58002
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$FFE0,$50(a5)
                move.l  #$12000,$1C(a5)
                move.l  $18(a5),d0
                asr.l   #2,d0
                move.l  d0,$18(a5)
                move.b  #$26,d0                         ; '&'
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_EnterArtemisState4
; State four applies vertical acceleration until reaching the upper threshold
Boss_UpdateArtemisState4:                               ; DATA XREF: ROM:00057F22   o  ; was: sub_5803C
                cmpi.w  #$30,$14(a5)                    ; '0'
                bmi.s   Boss_EnterArtemisState6
                addq.w  #2,$50(a5)
                bmi.s   Boss_UpdateArtemisState4Motion
                clr.w   $50(a5)
Boss_UpdateArtemisState4Motion:                         ; CODE XREF: Boss_UpdateArtemisState4+C   j  ; was: loc_5804E
                subi.l  #$1000,$1C(a5)
                subi.w  #$C,$56(a5)
                lea     Artemis_State2And4PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; ---------------------------------------------------------------------------
Boss_EnterArtemisState6:                                ; CODE XREF: Boss_UpdateArtemisState4+6   j  ; was: loc_58066
                addq.w  #2,4(a5)
                clr.w   $50(a5)
                clr.w   $56(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
; State six holds the neutral pose until the battle-effect gate opens
Boss_UpdateArtemisState6:                               ; DATA XREF: ROM:00057F24   o  ; was: loc_5807A
                tst.b   (SceneSequenceFlags).w
                bne.s   Boss_EnterArtemisState8
                lea     Artemis_State2And4PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; ---------------------------------------------------------------------------
Boss_EnterArtemisState8:                                ; CODE XREF: Boss_UpdateArtemisState4+42   j  ; was: loc_5808A
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CDA0,$4A(a5)
                move.w  #$170,$10(a5)
                move.w  #$FDC0,$794(a5)
                move.w  #$7000,(BossHealth).w
                move.w  #$7000,(BossMaxHealth).w
; State eight accelerates the linked vertical coordinate toward its stage target
Boss_UpdateArtemisState8:                               ; DATA XREF: ROM:00057F26   o  ; was: loc_580B6
                addi.l  #$78000,$794(a5)
                move.w  $794(a5),d0
                bsr.w   Boss_CompareArtemisVerticalTarget
                bpl.s   Boss_EnterArtemisStateA
                lea     Artemis_State8PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; ---------------------------------------------------------------------------
Boss_EnterArtemisStateA:                                ; CODE XREF: Boss_UpdateArtemisState4+8A   j  ; was: loc_580D2
                addq.w  #2,4(a5)
                move.w  #$C980,d0
                move.w  #$CDA0,d1
                bsr.w   Boss_PositionArtemisActivePartPair
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$C2,d0
                jsr     (Sound_QueueSFXRequest).l
                movea.l #Boss_ArtemisAttackObjectInitData,a1
                jsr     (Object_InitGroupFromTable).l
; End of function Boss_UpdateArtemisState4
; State A advances its pose before enabling the next transformation phase
Boss_UpdateArtemisStateA:                               ; DATA XREF: ROM:00057F28   o  ; was: sub_58102
                tst.w   $58(a5)
                bmi.s   Boss_EnterArtemisStateC
                lea     Artemis_StateAPoseScript(pc),a1
                nop
                bra.w   Boss_SyncArtemisLinkedPartVerticalPosition
; ---------------------------------------------------------------------------
Boss_EnterArtemisStateC:                                ; CODE XREF: Boss_UpdateArtemisStateA+4   j  ; was: loc_58112
                addq.w  #2,4(a5)
                move.b  #$F,$3BC(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bset    #0,2(a5)
                move.b  #$39,d0                         ; '9'
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_UpdateArtemisStateA
; State C completes the pose transition and returns control to the battle phase
Boss_UpdateArtemisStateC:                               ; DATA XREF: ROM:00057F2A   o  ; was: sub_58136
                tst.w   $58(a5)
                bpl.s   Boss_RenderArtemisStateC
                clr.b   (BossColorEffectFlags).w
                bclr    #0,(StageTimerPauseFlag).w
                clr.w   (PlayerScriptStateOffset).w
                subi.w  #$40,(CameraXLowerBound).w      ; '@'
                addi.w  #$40,(CameraXUpperBound).w      ; '@'
                bra.s   Boss_ReturnArtemisToStateEWithRandomPose
; ---------------------------------------------------------------------------
Boss_RenderArtemisStateC:                               ; CODE XREF: Boss_UpdateArtemisStateC+4   j  ; was: loc_58158
                lea     Artemis_StateCAndEPoseScript(pc),a1
                nop
                bra.w   Boss_SyncArtemisLinkedPartVerticalPosition
; End of function Boss_UpdateArtemisStateC
; Enter state E and align the selected active part pair to the stage reference
Boss_EnterArtemisStateE:                                ; CODE XREF: Boss_ReturnArtemisToStateEWithRandomPose   p  ; was: sub_58162
                                        ; Boss_ReturnArtemisToStateE   p
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$F,$3BC(a5)
                move.w  #$C980,d0
                move.w  #$CF80,d1
                bra.w   Boss_PositionArtemisActivePartPair
; End of function Boss_EnterArtemisStateE
; Re-enter state E and choose a new pose script
Boss_ReturnArtemisToStateEWithRandomPose:               ; CODE XREF: Boss_UpdateArtemisStateC+20   j  ; was: sub_58184
                                        ; Boss_UpdateArtemisState12+4   j
                bsr.s   Boss_EnterArtemisStateE
                bra.w   Boss_ResetArtemisStateEPoseScript
; End of function Boss_ReturnArtemisToStateEWithRandomPose
; Re-enter state E and continue directly into its update handler
Boss_ReturnArtemisToStateE:                             ; was: sub_5818A
                bsr.s   Boss_EnterArtemisStateE
; End of function Boss_ReturnArtemisToStateE
; State E selects a pose loop or one of the state $10/$14 follow-ups
Boss_UpdateArtemisStateE:                               ; DATA XREF: ROM:00057F2C   o  ; was: sub_5818C
                tst.w   $58(a5)
                bpl.s   Boss_RenderArtemisStateE
                jsr     (Entity_SetFacingField54FromPlayerXDelta).l
                cmpi.w  #$A0,d0
                bpl.s   Boss_SelectArtemisStateEFollowup
                cmpi.w  #$E0,$BC(a5)
                bmi.s   Boss_SelectArtemisStateEFollowup
                cmpi.w  #$220,$BC(a5)
                bpl.s   Boss_SelectArtemisStateEFollowup
                bra.w   Boss_EnterArtemisState14
; ---------------------------------------------------------------------------
Boss_SelectArtemisStateEFollowup:                       ; CODE XREF: Boss_UpdateArtemisStateE+10   j  ; was: loc_581B2
                                        ; Boss_UpdateArtemisStateE+18   j
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ResetArtemisStateEPoseScript
                move.w  #$1800,$11C(a5)
                tst.w   (DifficultyMode).w
                bne.s   Boss_CheckArtemisStateEAngleGate
                move.w  (FrameCounter).w,d4
                andi.w  #7,d4
                bne.s   Boss_SelectArtemisState10
Boss_CheckArtemisStateEAngleGate:                       ; CODE XREF: Boss_UpdateArtemisStateE+38   j  ; was: loc_581D0
                cmpi.w  #$C0,d0
                bmi.s   Boss_SelectArtemisState10
                move.w  #$B00,$11C(a5)
Boss_SelectArtemisState10:                              ; CODE XREF: Boss_UpdateArtemisStateE+42   j  ; was: loc_581DC
                                        ; Boss_UpdateArtemisStateE+48   j
                bra.w   Boss_EnterArtemisState10
; ---------------------------------------------------------------------------
Boss_ResetArtemisStateEPoseScript:                      ; CODE XREF: Boss_ReturnArtemisToStateEWithRandomPose+2   j  ; was: loc_581E0
                                        ; Boss_UpdateArtemisStateE+2C   j
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  (RandomNumberState).w,d1
                andi.w  #$1C,d1
                bne.s   Boss_SelectArtemisStateERandomPose
                move.b  #$39,d0                         ; '9'
                jsr     (Sound_QueueSFXRequest).l
Boss_SelectArtemisStateERandomPose:                     ; CODE XREF: Boss_UpdateArtemisStateE+66   j  ; was: loc_581FE
                move.l  Artemis_StateEPoseScriptTable(pc,d1.w),$41C(a5)
Boss_RenderArtemisStateE:                               ; CODE XREF: Boss_UpdateArtemisStateE+4   j  ; was: loc_58204
                movea.l $41C(a5),a1
                bra.w   Boss_SyncArtemisLinkedPartVerticalPosition
; ---------------------------------------------------------------------------
Artemis_StateEPoseScriptTable:  dc.l    Artemis_StateCAndEPoseScript  ; DATA XREF: Boss_UpdateArtemisStateE:Boss_SelectArtemisStateERandomPose   r  ; was: off_5820C
                dc.l    Artemis_StateEPoseScript1
                dc.l    Artemis_StateEPoseScript2
                dc.l    Artemis_StateEPoseScript2
                dc.l    Artemis_StateEPoseScript4
                dc.l    Artemis_StateEPoseScript4
                dc.l    Artemis_StateEPoseScript6
                dc.l    Artemis_StateEPoseScript6
; ---------------------------------------------------------------------------
Boss_EnterArtemisState10:                               ; CODE XREF: Boss_UpdateArtemisStateE:Boss_SelectArtemisState10   j  ; was: loc_5822C
                move.w  #$10,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.b   $3BC(a5)
                move.l  #$FFFA0000,$1C(a5)
                move.l  #$FFFB0000,d0
                bsr.w   Boss_SetArtemisDirectionalHorizontalVelocity
                move.w  a5,d0
                move.w  a5,d1
                jsr     (Entity_SelectValkirieActivePartPair).l
                move.w  #$8000,(ArtemisForegroundState).w
                lea     Artemis_State10PartMotionCommands(pc),a0
                nop
                jsr     (Entity_ApplyValkiriePartMotionCommands).l
; End of function Boss_UpdateArtemisStateE
; State $10 applies signed horizontal motion until its pose flag enters state $12
Boss_UpdateArtemisState10:                              ; DATA XREF: ROM:00057F2E   o  ; was: sub_5826E
                bclr    #0,$23E(a5)
                bne.s   Boss_EnterArtemisState12
                addi.l  #$4000,$1C(a5)
                lea     Artemis_State10And12PoseScript(pc),a1
                nop
                bsr.w   Boss_RenderArtemisPose
                moveq   #0,d0
                move.w  $11C(a5),d0
                tst.w   $18(a5)
                bpl.s   Boss_AdjustArtemisState10PositiveVelocity
                add.l   d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Boss_AdjustArtemisState10PositiveVelocity:              ; CODE XREF: Boss_UpdateArtemisState10+24   j  ; was: loc_5829A
                sub.l   d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Artemis_State10PartMotionCommands:  dc.w    $B7, $7840, $C680, $EC14, $EC14, $C6E0, $EC14, $EC14  ; was: word_582A0
                                        ; DATA XREF: Boss_UpdateArtemisStateE+D6   o
                dc.w    $C7A0, $FA06, $FA06, 0
Artemis_State10PartHideCommands:    dc.w    $FF00, $60, $C0, $120, 0  ; was: word_582B8
                                        ; DATA XREF: Boss_UpdateArtemisState10+6E   o
; ---------------------------------------------------------------------------
Boss_EnterArtemisState12:                               ; CODE XREF: Boss_UpdateArtemisState10+6   j  ; was: loc_582C2
                addq.w  #2,4(a5)
                clr.b   $23E(a5)
                move.b  #1,$3BC(a5)
                move.w  #$C980,d0
                move.w  #$C980,d1
                bsr.w   Boss_PositionArtemisActivePartPair
                lea     Artemis_State10PartHideCommands(pc),a0
                jsr     (Entity_ApplyValkiriePartHideCommands).l
                bsr.w   Boss_InitArtemisAttackPartGroup
                move.b  #$C2,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_UpdateArtemisState10
; State $12 advances pose flags and returns to state E when its script completes
Boss_UpdateArtemisState12:                              ; DATA XREF: ROM:00057F30   o  ; was: sub_582F4
                tst.w   $58(a5)
                bmi.w   Boss_ReturnArtemisToStateEWithRandomPose
                bsr.w   Boss_ArtemisMergePosePartFlags
                lea     Artemis_State10And12PoseScript(pc),a1
                nop
                bra.w   Boss_SyncArtemisLinkedPartVerticalPosition
; End of function Boss_UpdateArtemisState12
; Merges the pose command's low-nibble part flags into the active-part mask
Boss_ArtemisMergePosePartFlags:                         ; CODE XREF: Boss_UpdateArtemisState12+8   p  ; was: sub_5830A
                move.b  $23E(a5),d0
                andi.b  #$F,d0
                or.b    d0,$3BC(a5)
                rts
; End of function Boss_ArtemisMergePosePartFlags
; Apply a horizontal velocity with sign selected by the Artemis facing field
Boss_SetArtemisDirectionalHorizontalVelocity:           ; CODE XREF: Boss_UpdateArtemisStateE+C2   p  ; was: sub_58318
                tst.w   $54(a5)
                beq.s   Boss_StoreArtemisDirectionalHorizontalVelocity
                neg.l   d0
Boss_StoreArtemisDirectionalHorizontalVelocity:         ; CODE XREF: Boss_SetArtemisDirectionalHorizontalVelocity+4   j  ; was: loc_58320
                move.l  d0,$18(a5)
                rts
; End of function Boss_SetArtemisDirectionalHorizontalVelocity
; Initialize the linked Artemis attack-part group
Boss_InitArtemisAttackPartGroup:                        ; CODE XREF: Boss_UpdateArtemisState10+78   p  ; was: sub_58326
                lea     (Boss_ArtemisAttackPartGroupInitTable).l,a1
                jmp     Object_InitGroupFromTable
; End of function Boss_InitArtemisAttackPartGroup
; Enter state $14 and load a random motion descriptor
Boss_EnterArtemisState14:                               ; CODE XREF: Boss_UpdateArtemisStateE+22   j  ; was: sub_58332
                move.w  #$14,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CDA0,d0
                move.w  #$CDA0,d1
                bsr.w   Boss_PositionArtemisActivePartPair
                move.b  #4,$3BC(a5)
                move.b  #$DC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$1C,d0
                tst.w   (DifficultyMode).w
                bne.s   Boss_SelectArtemisState14Motion
                moveq   #0,d0
Boss_SelectArtemisState14Motion:                        ; CODE XREF: Boss_EnterArtemisState14+38   j  ; was: loc_5836E
                lea     Artemis_State14MotionTable(pc),a0
                nop
                movea.l (a0,d0.w),a0
                move.l  (a0)+,d5
                move.l  (a0)+,d4
                move.w  (a0)+,d7
                moveq   #$40,d6                         ; '@'
                bsr.w   Boss_SpawnArtemisRadialEmitter
; End of function Boss_EnterArtemisState14
; State $14 consumes pose flags and transitions to state $16 on flag seven
Boss_UpdateArtemisState14:                              ; DATA XREF: ROM:00057F32   o  ; was: sub_58384
                bclr    #7,$23E(a5)
                bne.w   Boss_EnterArtemisState16
                bclr    #0,$23E(a5)
                beq.s   Boss_ProcessArtemisState14PoseFlag1
                move.w  #$C980,d0
                move.w  #$C980,d1
                bsr.w   Boss_PositionArtemisActivePartPair
                move.b  #1,$3BC(a5)
Boss_ProcessArtemisState14PoseFlag1:                    ; CODE XREF: Boss_UpdateArtemisState14+10   j  ; was: loc_583A8
                bclr    #1,$23E(a5)
                beq.s   Boss_RenderArtemisState14
                move.w  #$CBC0,d0
                move.w  #$CBC0,d1
                bsr.w   Boss_PositionArtemisActivePartPair
                move.b  #3,$3BC(a5)
Boss_RenderArtemisState14:                              ; CODE XREF: Boss_UpdateArtemisState14+2A   j  ; was: loc_583C2
                move.b  #1,$3BD(a5)
                lea     Artemis_State14And16PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; End of function Boss_UpdateArtemisState14
; ---------------------------------------------------------------------------
Artemis_State14MotionTable: dc.l    Artemis_State14Motion0  ; DATA XREF: Boss_EnterArtemisState14:Boss_SelectArtemisState14Motion   o  ; was: off_583D2
                dc.l    Artemis_State14Motion0
                dc.l    Artemis_State14Motion0
                dc.l    Artemis_State14Motion1
                dc.l    Artemis_State14Motion2
                dc.l    Artemis_State14Motion2
                dc.l    Artemis_State14Motion2
                dc.l    Artemis_State14Motion3
Artemis_State14Motion0: dc.w    0, 0, 0, 0, $D8         ; DATA XREF: ROM:Artemis_State14MotionTable   o  ; was: word_583F2
                                        ; ROM:000583D6   o
Artemis_State14Motion1: dc.w    0, $2000, $FFFF, $D000, $CA  ; was: word_583FC
                                        ; DATA XREF: ROM:000583DE   o
Artemis_State14Motion2: dc.w    0, $2000, 0, $4000, $140  ; was: word_58406
                                        ; DATA XREF: ROM:000583E2   o
                                        ; ROM:000583E6   o
Artemis_State14Motion3: dc.w    0, $2600, 0, $E00, $110  ; was: word_58410
                                        ; DATA XREF: ROM:000583EE   o

; Enter state $16 and realign the selected part pair
Boss_EnterArtemisState16:                               ; CODE XREF: Boss_UpdateArtemisState14+6   j  ; was: sub_5841A
                addq.w  #2,4(a5)
                move.b  #$F,$3BC(a5)
                move.w  #$C980,d0
                move.w  #$CF80,d1
                bsr.w   Boss_PositionArtemisActivePartPair
; End of function Boss_EnterArtemisState16
; State $16 advances its pose before returning to state E
Boss_UpdateArtemisState16:                              ; DATA XREF: ROM:00057F34   o  ; was: sub_58430
                tst.w   $58(a5)
                bpl.s   Boss_RenderArtemisState16
                clr.w   $56(a5)
                bra.w   Boss_ReturnArtemisToStateEWithRandomPose
; ---------------------------------------------------------------------------
Boss_RenderArtemisState16:                              ; CODE XREF: Boss_UpdateArtemisState16+4   j  ; was: loc_5843E
                move.b  #1,$3BD(a5)
                lea     Artemis_State14And16PoseScript(pc),a1
                nop
                bra.w   Boss_RenderArtemisPose
; End of function Boss_UpdateArtemisState16
; Compare a requested vertical coordinate with the stage-relative target
Boss_CompareArtemisVerticalTarget:                      ; CODE XREF: Boss_UpdateArtemisState4+86   p  ; was: sub_5844E
                bmi.s   Boss_CompareArtemisVerticalTargetReturn
                move.w  (PrimaryCameraYPosition).w,d6
                subi.w  #$E200,d6
                addi.w  #$12A,d6
                cmp.w   d6,d0
Boss_CompareArtemisVerticalTargetReturn:                ; CODE XREF: Boss_CompareArtemisVerticalTarget   j  ; was: locret_5845E
                rts
; End of function Boss_CompareArtemisVerticalTarget
; Load the current stage-relative Artemis vertical reference
Boss_LoadArtemisStageVerticalReference:                 ; CODE XREF: Boss_PositionArtemisActivePartPair+6   p  ; was: sub_58460
                                        ; Boss_SyncArtemisLinkedPartVerticalPosition   p
                move.w  (PrimaryCameraYPosition).w,d6
                subi.w  #$E200,d6
                addi.w  #$12A,d6
                rts
; End of function Boss_LoadArtemisStageVerticalReference
; Select the active Artemis part pair and assign its vertical coordinate
Boss_PositionArtemisActivePartPair:                     ; CODE XREF: Boss_UpdateArtemisState4+A2   p  ; was: sub_5846E
                                        ; Boss_EnterArtemisStateE+1E   j
                jsr     (Entity_SelectValkirieActivePartPair).l
                bsr.s   Boss_LoadArtemisStageVerticalReference
                move.w  d6,$14(a0)
                rts
; End of function Boss_PositionArtemisActivePartPair
; Synchronize the linked Artemis part's vertical coordinate
Boss_SyncArtemisLinkedPartVerticalPosition:             ; CODE XREF: Boss_UpdateArtemisStateA+C   j  ; was: sub_5847C
                                        ; Boss_UpdateArtemisStateC+28   j
                bsr.s   Boss_LoadArtemisStageVerticalReference
                movea.w $4A(a5),a0
                move.w  d6,$14(a0)
; End of function Boss_SyncArtemisLinkedPartVerticalPosition
; Advance the Artemis pose, update active parts, and begin shared traversal
Boss_RenderArtemisPose:                                 ; CODE XREF: Boss_UpdateArtemisState2+24   j  ; was: sub_58486
                                        ; Boss_UpdateArtemisState4+26   j
                bsr.w   Boss_UpdateArtemisPoseScript
                bsr.w   Boss_ApplyArtemisPoseToParts
                moveq   #$1C,d7
                jsr     (Sprite_BeginMetaspritePartTraversal).l
                move.w  (PrimaryCameraYPosition).w,d6
                subi.w  #$E200,d6
                addi.w  #$12A,d6
                btst    #0,$3BC(a5)
                beq.s   Boss_CheckArtemisPosePartFlag1
                movea.w #(TenthEntityType-M68K_RAM),a0
                bsr.s   Boss_UpdateArtemisActivePartVerticalPosition
Boss_CheckArtemisPosePartFlag1:                         ; CODE XREF: Boss_RenderArtemisPose+22   j  ; was: loc_584B0
                btst    #1,$3BC(a5)
                beq.s   Boss_CheckArtemisPosePartFlag2
                movea.w #(SixteenthEntityType-M68K_RAM),a0
                bsr.s   Boss_UpdateArtemisActivePartVerticalPosition
Boss_CheckArtemisPosePartFlag2:                         ; CODE XREF: Boss_RenderArtemisPose+30   j  ; was: loc_584BE
                btst    #2,$3BC(a5)
                beq.s   Boss_CheckArtemisPosePartFlag3
                movea.w #(TwentyFirstEntityType-M68K_RAM),a0
                bsr.s   Boss_UpdateArtemisActivePartVerticalPosition
Boss_CheckArtemisPosePartFlag3:                         ; CODE XREF: Boss_RenderArtemisPose+3E   j  ; was: loc_584CC
                btst    #3,$3BC(a5)
                beq.s   Boss_RenderArtemisPoseReturn
                movea.w #(TwentySixthEntityType-M68K_RAM),a0
                bra.s   Boss_UpdateArtemisActivePartVerticalPosition
; ---------------------------------------------------------------------------
Boss_RenderArtemisPoseReturn:                           ; CODE XREF: Boss_RenderArtemisPose+4C   j  ; was: locret_584DA
                rts
; End of function Boss_RenderArtemisPose
