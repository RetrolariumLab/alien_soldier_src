; Handle Medusa completion, battle effects, scripted spawns, then state dispatch
Boss_UpdateMedusa:                                      ; was: sub_5699C
                tst.w   4(a5)
                beq.w   Boss_DispatchMedusaState
                tst.w   8(a5)
                beq.s   Boss_DispatchMedusaState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_UpdateMedusaBattleEffects
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_UpdateMedusaBattleEffects
                tst.w   (BossHealth).w
                bne.s   Boss_UpdateMedusaBattleEffects
                moveq   #4,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_UpdateMedusaBattleEffects:                         ; was: loc_569C8
                                        ; Boss_UpdateMedusa+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #6,d0
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
                bsr.w   Entity_UpdateMedusaScriptedSpawnSequence
; Resolve the even-numbered state offset and jump to its handler
Boss_DispatchMedusaState:                               ; was: loc_569E0
                                        ; Boss_UpdateMedusa+C   j
                move.w  4(a5),d0
                movea.w Boss_MedusaStateOffsets(pc,d0.w),a0
                adda.l  #Boss_InitMedusaState0,a0
                jmp     (a0)
; End of function Boss_UpdateMedusa
; ---------------------------------------------------------------------------
; Eleven relative handler offsets for states $00 through $14
Boss_MedusaStateOffsets:    dc.w    Boss_InitMedusaState0-Boss_InitMedusaState0  ; was: off_569F0
                dc.w    Boss_UpdateMedusaState2-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState4-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState6-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState8-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaStateA-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaStateC-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaStateE-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState10-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState12-Boss_InitMedusaState0
                dc.w    Boss_UpdateMedusaState14-Boss_InitMedusaState0

; Initialize the Medusa metasprite and enter state four
Boss_InitMedusaState0:                                  ; was: sub_56A06
                                        ; ROM:Boss_MedusaStateOffsets   o
                move.w  #1,8(a5)
                move.w  #$7000,(BossHealth).w
                move.w  #$7000,(BossMaxHealth).w
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$14,d7
                movea.l #Boss_MedusaMetaspritePartDescriptors,a0
                movea.l #Boss_MedusaMetaspriteInitialAngles,a1
                movea.l #Boss_MedusaMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_MedusaMetaspritePoseAngles,$2FC(a5)
                move.l  #Medusa_PoseTable,$35C(a5)
                move.w  #$430,(a5)
                move.w  #$CC00,2(a5)
                clr.w   (MedusaSpawnSequenceFlag).w
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  #$450,(a0)
                clr.w   4(a0)
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  $10(a0),$10(a5)
                move.w  $14(a0),$14(a5)
                move.l  $18(a0),$18(a5)
                move.l  $1C(a0),$1C(a5)
                move.w  #2,$1DE(a5)
                bra.w   Boss_EnterMedusaState4
; End of function Boss_InitMedusaState0
; Alternate entry: initialize Medusa at a fixed position and continue in state two
Boss_InitMedusaAtFixedPosition:                         ; was: sub_56A8A
                move.w  #2,4(a5)
                clr.w   (PlayerScriptStateOffset).w
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
; End of function Boss_InitMedusaAtFixedPosition
; State two follows the shared vertical coordinate and accepts left/right input
Boss_UpdateMedusaState2:                                ; was: sub_56ABA
                move.w  (Entity57YPos).w,d0
                move.w  d0,$14(a5)
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_CheckMedusaState2RightInput
                subq.w  #4,$10(a5)
Boss_CheckMedusaState2RightInput:                       ; was: loc_56ACE
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_RenderMedusaState2
                addq.w  #4,$10(a5)
Boss_RenderMedusaState2:                                ; was: loc_56ADA
                lea     Medusa_State2Poses(pc),a1
                nop
                bra.w   Boss_RenderMedusaPose
; End of function Boss_UpdateMedusaState2
; Enter state four and seed the pose interpolator
Boss_EnterMedusaState4:                                 ; was: sub_56AE4
                move.w  #4,4(a5)
                bclr    #3,2(a5)
                bclr    #2,2(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$100,$50(a5)
                move.w  #$100,$47C(a5)
                lea     Medusa_InitialPoseChannelValues(pc),a0
                nop
                bsr.w   Boss_MedusaInitializePoseChannels
; End of function Boss_EnterMedusaState4
; State four advances its pose script before opening the active battle phase
Boss_UpdateMedusaState4:                                ; was: sub_56B16
                tst.w   $58(a5)
                bmi.s   Boss_EnterMedusaState6
                lea     Medusa_State4Poses(pc),a1
                nop
                bsr.w   Boss_RenderMedusaPose
                move.b  (SharedScratchLong4).w,d0
                ext.w   d0
                move.w  d0,$50(a5)
                rts
; ---------------------------------------------------------------------------
Boss_EnterMedusaState6:                                 ; was: loc_56B32
                addq.w  #2,4(a5)
                clr.w   $50(a5)
                bset    #3,2(a5)
                bset    #2,2(a5)
                bset    #0,2(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$F0,d0
                jsr     (Sound_QueueSFXRequest).l
                movea.l #Boss_MedusaObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
; End of function Boss_UpdateMedusaState4
; State six applies vertical acceleration until it crosses the shared coordinate
Boss_UpdateMedusaState6:                                ; was: sub_56B6C
                addi.l  #$2000,$1C(a5)
                bmi.s   Boss_RenderMedusaState6
                move.w  (Entity57YPos).w,d0
                cmp.w   $14(a5),d0
                bmi.s   Boss_EnterMedusaState8
Boss_RenderMedusaState6:                                ; was: loc_56B80
                lea     Medusa_State6And12Poses(pc),a1
                nop
                bra.w   Boss_RenderMedusaPose
; ---------------------------------------------------------------------------
Boss_EnterMedusaState8:                                 ; was: loc_56B8A
                addq.w  #2,4(a5)
                move.l  $18(a5),d0
                asr.l   #3,d0
                move.l  d0,$18(a5)
                move.l  #$FFFE0000,$1C(a5)
                move.w  #1,$4DC(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State eight settles onto the shared vertical coordinate while moving right
Boss_UpdateMedusaState8:                                ; was: loc_56BB0
                tst.w   $4DC(a5)
                beq.s   Boss_SyncMedusaState8VerticalPosition
                addi.l  #$2000,$1C(a5)
                bmi.s   Boss_RenderMedusaState8
                move.w  (Entity57YPos).w,d0
                cmp.w   $14(a5),d0
                bpl.s   Boss_RenderMedusaState8
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.w   $4DC(a5)
Boss_SyncMedusaState8VerticalPosition:                  ; was: loc_56BD6
                move.w  (Entity57YPos).w,d0
                move.w  d0,$14(a5)
                cmpi.w  #$1C0,$10(a5)
                bpl.s   Boss_EnterMedusaStateA
Boss_RenderMedusaState8:                                ; was: loc_56BE6
                lea     Medusa_State8And12Poses(pc),a1
                nop
                bra.w   Boss_RenderMedusaPose
; ---------------------------------------------------------------------------
Boss_EnterMedusaStateA:                                 ; was: loc_56BF0
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; State A approaches its target, then enables the scripted spawn sequence
Boss_UpdateMedusaStateA:                                ; was: loc_56C04
                subq.w  #1,$11C(a5)
                bpl.s   Boss_UpdateMedusaStateAApproach
                clr.b   (BossColorEffectFlags).w
                bclr    #0,(StageTimerPauseFlag).w
                move.w  #1,(MedusaSpawnSequenceFlag).w
                move.l  #Medusa_StateASpawnSchedule,$59C(a5)
                move.w  #$10,(MedusaSequenceOffset).w
                move.w  #$18C,$11E(a5)
                clr.w   $4DC(a5)
                bra.w   Boss_EnterMedusaStateC
; ---------------------------------------------------------------------------
Boss_UpdateMedusaStateAApproach:                        ; was: loc_56C36
                move.w  #$180,d0
                bsr.w   Boss_SteerMedusaHorizontalVelocityByXTarget
                lea     Medusa_StateACPoses(pc),a1
                nop
                bra.w   Boss_SyncMedusaVerticalPosition
; ---------------------------------------------------------------------------
Boss_ClearMedusaSequenceCommand:                        ; was: loc_56C48
                                        ; Boss_UpdateMedusaState10   j
                                        ; Boss_UpdateMedusaState14   j
                clr.w   $47E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_EnterMedusaStateC:                                 ; was: loc_56C56
                                        ; Boss_UpdateMedusaStateE   j
                move.w  #$C,4(a5)
; State C consumes scripted commands and tracks the selected horizontal target
Boss_UpdateMedusaStateC:                                ; was: loc_56C5C
                move.l  #Medusa_StateACPoses,$53C(a5)
                tst.b   (Entity57Work56).w
                beq.w   Boss_EnterMedusaStateE
                tst.w   $4DC(a5)
                beq.s   Boss_SyncMedusaStateCVerticalPosition
                addi.l  #$2000,$1C(a5)
                bmi.s   Boss_ProcessMedusaStateCCommand
                move.w  (Entity57YPos).w,d0
                cmp.w   $14(a5),d0
                bpl.s   Boss_ProcessMedusaStateCCommand
                move.w  #1,(PlaneAShakeLevel).w
                clr.w   $4DC(a5)
                clr.l   $1C(a5)
Boss_SyncMedusaStateCVerticalPosition:                  ; was: loc_56C94
                move.w  (Entity57YPos).w,d0
                move.w  d0,$14(a5)
Boss_ProcessMedusaStateCCommand:                        ; was: loc_56C9C
                cmpi.w  #4,$47E(a5)
                bne.s   Boss_DispatchMedusaStateCCommand
                clr.w   $47E(a5)
                move.w  $5E(a5),$11E(a5)
                bra.s   Boss_UpdateMedusaStateCTarget
; ---------------------------------------------------------------------------
Boss_DispatchMedusaStateCCommand:                       ; was: loc_56CB0
                cmpi.w  #2,$47E(a5)
                beq.w   Boss_EnterMedusaState10
                cmpi.w  #6,$47E(a5)
                beq.w   Boss_EnterMedusaState12
                cmpi.w  #8,$47E(a5)
                beq.w   Boss_EnterMedusaState14
Boss_UpdateMedusaStateCTarget:                          ; was: loc_56CCE
                bsr.w   Boss_SteerMedusaHorizontalVelocityFromStoredTarget
                move.b  #$D8,d0
                bsr.w   Boss_MedusaPlaySFXEvery8Frames
                lea     Medusa_StateACPoses(pc),a1
                nop
                bra.w   Boss_RenderMedusaPose
; ---------------------------------------------------------------------------
Boss_EnterMedusaStateE:                                 ; was: loc_56CE4
                                        ; Boss_UpdateMedusaState10   j
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State E completes the vertical transfer before returning to state C
Boss_UpdateMedusaStateE:                                ; was: loc_56CF4
                cmpi.l  #$68000,$1C(a5)
                bpl.s   Boss_CheckMedusaStateEVerticalTransfer
                addi.l  #$2000,$1C(a5)
                bmi.s   Boss_RenderMedusaStateE
Boss_CheckMedusaStateEVerticalTransfer:                 ; was: loc_56D08
                tst.b   (Entity57Work56).w
                beq.s   Boss_RenderMedusaStateE
                move.w  (Entity57YPos).w,d0
                cmp.w   $14(a5),d0
                bpl.s   Boss_RenderMedusaStateE
                addq.w  #2,4(a5)
                move.l  #$FFFE8000,$1C(a5)
                move.w  #1,$4DC(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$48,d0                         ; 'H'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #2,(PlaneAShakeLevel).w
                bra.w   Boss_EnterMedusaStateC
; ---------------------------------------------------------------------------
Boss_RenderMedusaStateE:                                ; was: loc_56D48
                movea.l $53C(a5),a1
                bra.w   Boss_RenderMedusaPose
; ---------------------------------------------------------------------------
Boss_EnterMedusaState12:                                ; was: loc_56D50
                move.w  #$12,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State $12 damps horizontal velocity and reacts to scripted commands
Boss_UpdateMedusaState12:                               ; was: loc_56D60
                cmpi.w  #4,$47E(a5)
                bne.s   Boss_UpdateMedusaState12Motion
                clr.w   $47E(a5)
                move.w  $5E(a5),$11E(a5)
                bra.w   Boss_ClearMedusaSequenceCommand
; ---------------------------------------------------------------------------
Boss_UpdateMedusaState12Motion:                         ; was: loc_56D76
                cmpi.w  #2,$47E(a5)
                beq.w   Boss_EnterMedusaState10
                cmpi.w  #8,$47E(a5)
                beq.w   Boss_EnterMedusaState14
                tst.l   $18(a5)
                beq.s   Boss_RenderMedusaState12IdlePose
                bmi.s   Boss_DecelerateMedusaState12NegativeVelocity
                subi.l  #$2000,$18(a5)
                bmi.s   Boss_StopMedusaState12HorizontalMotion
                bra.s   Boss_RenderMedusaState12MovingPose
; ---------------------------------------------------------------------------
Boss_DecelerateMedusaState12NegativeVelocity:           ; was: loc_56D9E
                addi.l  #$2000,$18(a5)
                bmi.s   Boss_RenderMedusaState12MovingPose
Boss_StopMedusaState12HorizontalMotion:                 ; was: loc_56DA8
                clr.l   $18(a5)
Boss_RenderMedusaState12MovingPose:                     ; was: loc_56DAC
                lea     Medusa_State6And12Poses(pc),a1
                nop
                bra.w   Boss_SyncMedusaVerticalPosition
; ---------------------------------------------------------------------------
Boss_RenderMedusaState12IdlePose:                       ; was: loc_56DB6
                lea     Medusa_State8And12Poses(pc),a1
                nop
                bra.w   Boss_SyncMedusaVerticalPosition
; ---------------------------------------------------------------------------
Boss_EnterMedusaState10:                                ; was: loc_56DC0
                                        ; Boss_UpdateMedusaState12Motion   j
                move.w  #$10,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State $10 accelerates left until it can return to state C
Boss_UpdateMedusaState10:                               ; was: loc_56DD0
                move.l  #Medusa_State10Poses,$53C(a5)
                tst.b   (Entity57Work56).w
                beq.w   Boss_EnterMedusaStateE
                move.w  #1,(PlaneAShakeLevel).w
                cmpi.w  #$D0,$10(a5)
                bpl.s   Boss_AccelerateMedusaState10Left
                move.w  #$B0,$11E(a5)
                bra.w   Boss_ClearMedusaSequenceCommand
; ---------------------------------------------------------------------------
Boss_AccelerateMedusaState10Left:                       ; was: loc_56DF8
                tst.l   $18(a5)
                bpl.s   Boss_ApplyMedusaState10LeftAcceleration
                cmpi.l  #$FFFB0000,$18(a5)
                bmi.s   Boss_RenderMedusaState10
Boss_ApplyMedusaState10LeftAcceleration:                ; was: loc_56E08
                subi.l  #$800,$18(a5)
Boss_RenderMedusaState10:                               ; was: loc_56E10
                move.b  #$F2,d0
                bsr.w   Boss_MedusaPlaySFXEvery4Frames
                lea     Medusa_State10Poses(pc),a1
                nop
                bra.w   Boss_SyncMedusaVerticalPosition
; ---------------------------------------------------------------------------
Boss_EnterMedusaState14:                                ; was: loc_56E22
                                        ; Boss_UpdateMedusaState12Motion   j
                move.w  #$14,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State $14 accelerates right until it can return to state C
Boss_UpdateMedusaState14:                               ; was: loc_56E32
                cmpi.w  #$180,$10(a5)
                bmi.s   Boss_AccelerateMedusaState14Right
                move.w  #$18C,$11E(a5)
                bra.w   Boss_ClearMedusaSequenceCommand
; ---------------------------------------------------------------------------
Boss_AccelerateMedusaState14Right:                      ; was: loc_56E44
                tst.l   $18(a5)
                bpl.s   Boss_ApplyMedusaState14RightAcceleration
                cmpi.l  #$24000,$18(a5)
                bpl.s   Boss_RenderMedusaState14
Boss_ApplyMedusaState14RightAcceleration:               ; was: loc_56E54
                addi.l  #$800,$18(a5)
Boss_RenderMedusaState14:                               ; was: loc_56E5C
                move.b  #$F3,d0
                bsr.w   Boss_MedusaPlaySFXEvery4Frames
                lea     Medusa_State14PoseScript(pc),a1
                nop
                bra.w   Boss_SyncMedusaVerticalPosition
; End of Medusa state controller
; Alternate entry: load the scripted X target from $11E, then fall through
Boss_SteerMedusaHorizontalVelocityFromStoredTarget:     ; was: sub_56E6E
                move.w  $11E(a5),d0
; Shared entry: steer X velocity by comparing target d0 with current X
Boss_SteerMedusaHorizontalVelocityByXTarget:            ; was: sub_56E72
                cmp.w   $10(a5),d0
                bpl.s   Boss_CheckMedusaRightwardAcceleration
                tst.l   $18(a5)
                bpl.s   Boss_DecreaseMedusaXVelocityBy2000
                cmpi.l  #$FFFDC000,$18(a5)
                bmi.s   Boss_SteerMedusaHorizontalVelocityReturn
Boss_DecreaseMedusaXVelocityBy2000:                     ; was: loc_56E88
                subi.l  #$2000,$18(a5)
Boss_SteerMedusaHorizontalVelocityReturn:               ; was: locret_56E90
                                        ; Boss_SteerMedusaHorizontalVelocityByXTarget+2E   j
                rts
; ---------------------------------------------------------------------------
Boss_CheckMedusaRightwardAcceleration:                  ; was: loc_56E92
                tst.l   $18(a5)
                bmi.s   Boss_IncreaseMedusaXVelocityBy2000
                cmpi.l  #$12000,$18(a5)
                bpl.s   Boss_SteerMedusaHorizontalVelocityReturn
Boss_IncreaseMedusaXVelocityBy2000:                     ; was: loc_56EA2
                addi.l  #$2000,$18(a5)
                rts
; End of Medusa horizontal-velocity steering helper
; Synchronize Medusa with the shared vertical coordinate
Boss_SyncMedusaVerticalPosition:                        ; was: sub_56EAC
                                        ; Boss_RenderMedusaState12MovingPose   j
                move.w  (Entity57YPos).w,d0
                move.w  d0,$14(a5)
; End of function Boss_SyncMedusaVerticalPosition
; Advance the pose, apply it to the metasprite, and traverse its 20 parts
Boss_RenderMedusaPose:                                  ; was: sub_56EB4
                                        ; Boss_UpdateMedusaState4+C   p
                bsr.w   Boss_UpdateMedusaPoseScript
                bsr.w   Boss_ApplyMedusaPoseToParts
                moveq   #$13,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_RenderMedusaPose
; Map the current pose values and offsets onto the Medusa metasprite parts
Boss_ApplyMedusaPoseToParts:                            ; was: sub_56EC4
                move.w  #$80,d6
                move.w  #0,$B6(a5)
                move.w  #$80,$296(a5)
                move.w  #$100,$476(a5)
                move.w  #$180,$656(a5)
                move.b  (a0),d0
                asl.w   #1,d0
                move.w  d0,d2
                and.w   d7,d0
                move.w  d0,$116(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$2F6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$4D6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$6B6(a5)
                move.b  4(a0),d0
                asl.w   #1,d0
                add.w   d2,d0
                move.w  d0,d2
                and.w   d7,d0
                move.w  d0,$176(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$356(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$536(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$716(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                add.w   d2,d0
                move.w  d0,d2
                and.w   d7,d0
                move.w  d0,$1D6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$3B6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$596(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$776(a5)
                move.b  $C(a0),d0
                asl.w   #1,d0
                add.w   d2,d0
                move.w  d0,d2
                and.w   d7,d0
                move.w  d0,$236(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$416(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$5F6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,$7D6(a5)
                move.b  $10(a0),d1
                ext.w   d1
                move.w  d1,d2
                asr.w   #1,d2
                move.w  $B2(a5),d0
                add.w   d2,d0
                move.w  d0,$B4(a5)
                move.w  $292(a5),d0
                add.w   d2,d0
                move.w  d0,$294(a5)
                move.w  $472(a5),d0
                add.w   d2,d0
                move.w  d0,$474(a5)
                move.w  $652(a5),d0
                add.w   d2,d0
                move.w  d0,$654(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a1
                bsr.w   Boss_OffsetMedusaPosePartGroup
                movea.w #(SeventhEntityType-M68K_RAM),a1
                bsr.w   Boss_OffsetMedusaPosePartGroup
                movea.w #(TwelfthEntityType-M68K_RAM),a1
                bsr.w   Boss_OffsetMedusaPosePartGroup
                movea.w #(SeventeenthEntityType-M68K_RAM),a1
                bsr.w   Boss_OffsetMedusaPosePartGroup
                move.b  $14(a0),d1
                ext.w   d1
                ext.l   d1
                swap    d1
                asr.l   #2,d1
                add.l   d1,$3BC(a5)
                move.w  $3BC(a5),$56(a5)
                move.b  $18(a0),d1
                asl.w   #1,d1
                add.w   $47C(a5),d1
                and.w   d7,d1
                move.w  d1,$54(a5)
                rts
; End of function Boss_ApplyMedusaPoseToParts
; Apply one pose offset to a four-part metasprite group
Boss_OffsetMedusaPosePartGroup:                         ; was: sub_56FF6
                                        ; Boss_ApplyMedusaPoseToParts+F6   p
                move.w  $B2(a1),d0
                add.w   d1,d0
                move.w  d0,$B4(a1)
                move.w  $112(a1),d0
                add.w   d1,d0
                move.w  d0,$114(a1)
                move.w  $172(a1),d0
                add.w   d1,d0
                move.w  d0,$174(a1)
                move.w  $1D2(a1),d0
                add.w   d1,d0
                move.w  d0,$1D4(a1)
                rts
; End of function Boss_OffsetMedusaPosePartGroup
; Plays sound effect every 4th frame during animation
Boss_MedusaPlaySFXEvery4Frames:                         ; was: sub_57020
                                        ; Boss_RenderMedusaState14   p
                move.w  (FrameCounter).w,d1
                andi.w  #3,d1
                bne.s   Boss_PlayMedusaSFXEvery4FramesReturn
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_PlayMedusaSFXEvery4FramesReturn:                   ; was: locret_57030
                rts
; End of function Boss_MedusaPlaySFXEvery4Frames
; Plays sound effect every 8th frame during animation
Boss_MedusaPlaySFXEvery8Frames:                         ; was: sub_57032
                move.w  (FrameCounter).w,d1
                andi.w  #7,d1
                bne.s   Boss_PlayMedusaSFXEvery8FramesReturn
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_PlayMedusaSFXEvery8FramesReturn:                   ; was: locret_57042
                rts
; End of function Boss_MedusaPlaySFXEvery8Frames
; Interpret the current state's pose script
Boss_UpdateMedusaPoseScript:                            ; was: sub_57044
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_AdvanceMedusaPoseInterpolation
Boss_ReadMedusaPoseScriptCommand:                       ; was: loc_5704E
                                        ; Boss_CheckMedusaPoseLoopMarker+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_PrepareMedusaPosePartTraversal
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_CheckMedusaPoseStopMarker
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ReadMedusaPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_CheckMedusaPoseStopMarker:                         ; was: loc_5706A
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_CheckMedusaPoseLoopMarker
                move.w  d3,$58(a5)
                bra.w   Boss_PrepareMedusaPosePartTraversal
; End of function Boss_UpdateMedusaPoseScript
Boss_MedusaPoseScriptNoOp:                              ; was: nullsub_129
                rts
; End of function Boss_MedusaPoseScriptNoOp

; Restart at $FFFF or set up the next pose frame and interpolation countdown
Boss_CheckMedusaPoseLoopMarker:                         ; was: sub_5707E
                cmpi.w  #$FFFF,d3
                bne.s   Boss_StartMedusaPoseFrame
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ReadMedusaPoseScriptCommand
; ---------------------------------------------------------------------------
Boss_StartMedusaPoseFrame:                              ; was: loc_5708E
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_CalculateMedusaPoseDeltas
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_PrepareMedusaPosePartTraversal
Boss_AdvanceMedusaPoseInterpolation:                    ; was: loc_570BE
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #7,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_PrepareMedusaPosePartTraversal:                    ; was: loc_570CE
                                        ; Boss_UpdateMedusaPoseScript+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Boss_CheckMedusaPoseLoopMarker
; Calculate interpolation deltas for the next Medusa pose frame
Boss_CalculateMedusaPoseDeltas:                         ; was: sub_570D8
                movea.l $2FC(a5),a1
                moveq   #7,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_CalculateMedusaPoseDeltas
; Initialize Medusa's eight fixed-point pose channels from bytes at a0
Boss_MedusaInitializePoseChannels:                      ; was: sub_570EC
                moveq   #7,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_MedusaInitializePoseChannels
; ---------------------------------------------------------------------------
; State-selected word streams consumed by Boss_UpdateMedusaPoseScript
Medusa_State2Poses:     dc.w    $2020, 0, $FFFF         ; was: word_570F8
Medusa_State4Poses:     dc.w    $3060, 0, $2020, 0, $FFFE  ; was: word_570FE
Medusa_StateACPoses:    dc.w    $2020, 0, $FFFF         ; was: word_57108
                                        ; Boss_UpdateMedusaStateC   o
Medusa_State14PoseScript:   dc.w    $1818, $10, $FFFF   ; was: word_5710E
Medusa_State6And12Poses:    dc.w    $1010, $28, $FFFF   ; was: word_57114
                                        ; Boss_RenderMedusaState12MovingPose   o
Medusa_State10Poses:    dc.w    $1010, $18, $FFFF       ; was: word_5711A
                                        ; Boss_RenderMedusaState10   o
Medusa_State8And12Poses:    dc.w    $308, $30, $E0E, $30, $408, $28, $1010  ; was: word_57120
                                        ; Boss_RenderMedusaState12IdlePose   o
                dc.w    $28, $FFFF
; Frame-data base saved in $35C(a5); script offsets select poses from here
Medusa_PoseTable:   dc.w    $401C, $1402, $14, 0, $C01C, $1402, $10  ; was: word_57132
                dc.w    0, $C0E4, $E4FE, $D0, 0, $401C, $1402
                dc.w    $28, $1000, 0, 0, $FC00, 0, $401C
                dc.w    $1402, 0, 0, $5018, $8F0, $1E0, 0
                dc.w    $4018, $20F0, $238, $1800
; Initial eight pose-channel bytes, not interpolation delays
Medusa_InitialPoseChannelValues:    dc.w    0, 0, $7090, 0  ; was: word_57172

; Synchronize the falling part X coordinate and dispatch its three states
Entity_UpdateMedusaFallingPart:                         ; was: sub_5717A
                move.w  (PrimaryEntityXPos).w,$10(a5)
                clr.w   6(a5)
                move.w  4(a5),d0
                movea.w Entity_MedusaFallingPartStateOffsets(pc,d0.w),a0
                adda.l  #Entity_InitMedusaFallingPartState0,a0
                jmp     (a0)
; End of function Entity_UpdateMedusaFallingPart
; ---------------------------------------------------------------------------
Entity_MedusaFallingPartStateOffsets:   dc.w    Entity_InitMedusaFallingPartState0-Entity_InitMedusaFallingPartState0  ; was: off_57194
                dc.w    Entity_UpdateMedusaFallingPartState2-Entity_InitMedusaFallingPartState0
                dc.w    Entity_UpdateMedusaFallingPartState4-Entity_InitMedusaFallingPartState0

; Initialize the falling-part sprite and enter terrain-wait state two
Entity_InitMedusaFallingPartState0:                     ; was: sub_5719A
                                        ; ROM:Entity_MedusaFallingPartStateOffsets   o
                addq.w  #2,4(a5)
                move.w  #$400,2(a5)
                move.w  #$C480,$E(a5)
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                move.w  #$128,$14(a5)
Entity_ResetMedusaFallingPartState2:                    ; was: loc_571BC
                move.w  #2,4(a5)
                clr.l   $1C(a5)
                move.b  #1,$56(a5)
                rts
; End of function Entity_InitMedusaFallingPartState0
; Hold state two while lower-terrain contact remains asserted
Entity_UpdateMedusaFallingPartState2:                   ; was: sub_571CE
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                beq.s   Entity_AdvanceMedusaFallingPartState4
                rts
; ---------------------------------------------------------------------------
Entity_AdvanceMedusaFallingPartState4:                  ; was: loc_571DE
                move.w  #4,4(a5)
                clr.b   $56(a5)
                rts
; End of function Entity_UpdateMedusaFallingPartState2
; Apply gravity in state four until descending terrain contact resets state two
Entity_UpdateMedusaFallingPartState4:                   ; was: sub_571EA
                cmpi.w  #7,$1C(a5)
                bpl.s   Entity_CheckMedusaFallingPartTerrain
                addi.l  #$4000,$1C(a5)
Entity_CheckMedusaFallingPartTerrain:                   ; was: loc_571FA
                jsr     (Physics_CheckLowerTerrainWhenDescending).l
                btst    #0,6(a5)
                bne.w   Entity_ResetMedusaFallingPartState2
                rts
; End of function Entity_UpdateMedusaFallingPartState4
; Consume scroll-triggered spawn records and controller commands
Entity_UpdateMedusaScriptedSpawnSequence:               ; was: sub_5720C
                tst.w   (MedusaSpawnSequenceFlag).w
                beq.w   Entity_UpdateMedusaSpawnSequenceReturn
                movea.l $59C(a5),a4
                moveq   #0,d1
                move.w  (MedusaSequenceOffset).w,d1
                move.w  (a4,d1.w),d2
                bpl.s   Entity_CheckMedusaSpawnSequenceTrigger
                clr.w   (MedusaSequenceOffset).w
                clr.w   (MedusaSpawnSequenceFlag).w
                cmpi.w  #$FFFE,d2
                bne.s   Entity_AdvanceMedusaSpawnSequenceSegment
                move.l  #Medusa_ScriptedSpawnSequenceData,$59C(a5)
                rts
; ---------------------------------------------------------------------------
Entity_AdvanceMedusaSpawnSequenceSegment:               ; was: loc_5723C
                addq.w  #2,d1
                adda.l  d1,a4
                move.l  a4,$59C(a5)
Entity_CheckMedusaSpawnSequenceTrigger:                 ; was: loc_57244
                move.w  (PrimaryCameraXPosition).w,d4
                cmp.w   d2,d4
                beq.s   Entity_ProcessMedusaSpawnSequenceEntry
                bpl.s   Entity_UpdateMedusaSpawnSequenceReturn
Entity_ProcessMedusaSpawnSequenceEntry:                 ; was: loc_5724E
                addq.w  #8,(MedusaSequenceOffset).w
                move.w  2(a4,d1.w),d5
                beq.w   Entity_ApplyMedusaSpawnSequenceCommand
                tst.w   (DifficultyMode).w
                bne.s   Entity_SpawnMedusaSequenceObject
                tst.w   d5
                bmi.s   Entity_UpdateMedusaSpawnSequenceReturn
Entity_SpawnMedusaSequenceObject:                       ; was: loc_57264
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Entity_UpdateMedusaSpawnSequenceReturn
                move.w  (a4,d1.w),d2
                sub.w   d4,d2
                addi.w  #$80,d2
                move.w  d2,$10(a0)
                andi.w  #$7FFF,d5
                move.w  d5,$14(a0)
                move.w  4(a4,d1.w),$5E(a0)
                move.w  6(a4,d1.w),(a0)
                bpl.s   Entity_UpdateMedusaSpawnSequenceReturn
                cmpi.w  #$8000,(a0)
                bne.s   Entity_SpawnMedusaSequenceLargePickup
                jmp     Pickup_SpawnSmall
; ---------------------------------------------------------------------------
Entity_SpawnMedusaSequenceLargePickup:                  ; was: loc_5729A
                jmp     Pickup_SpawnLarge
; ---------------------------------------------------------------------------
Entity_UpdateMedusaSpawnSequenceReturn:                 ; was: locret_572A0
                                        ; Entity_UpdateMedusaScriptedSpawnSequence+40   j
                rts
; ---------------------------------------------------------------------------
Entity_ApplyMedusaSpawnSequenceCommand:                 ; was: loc_572A2
                move.w  6(a4,d1.w),$47E(a5)
                move.w  4(a4,d1.w),$5E(a5)
                rts
; End of function Entity_UpdateMedusaScriptedSpawnSequence
; ---------------------------------------------------------------------------
Medusa_ScriptedSpawnSequenceData:   binclude "data/other/word_572B0.bin"  ; was: word_572B0
Medusa_ScriptedSpawnSequenceDataEnd:                    ; was: word_572B0_End
Medusa_StateASpawnSchedule:         dc.w    $698, 0, 0, 8, $5D4, $11A, 0, $24C  ; was: word_573E6
                dc.w    $4C4, 0, $120, 4, $4C0, $D0, 0, $8000
                dc.w    $480, $130, 0, $8000, $408, $D0, 0, $8000
                dc.w    $480, $130, 0, $8000, $3E8, $148, 0, $8001
                dc.w    $360, $D0, 0, $8000, $340, $B0, 0, $8000
                dc.w    $300, $D0, 0, $8000, $2C0, $B0, 0, $8000
                dc.w    $280, $D0, 0, $8000, $240, $B0, 0, $8000
                dc.w    $1D8, 0, $B0, 4, $1D0, $DC, 0, $24C
                dc.w    $120, $8150, 0, $2B4, $E0, $150, 0, $8000
                dc.w    $A0, $150, 0, $8000, $80, 0, 0, 2
                dc.w    $60, $150, 0, $8000, $20, $150, 0, $8001
                dc.w    $FFFE
