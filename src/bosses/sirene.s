; Update battle effects, handle completion, and dispatch the Sirene state machine
Boss_UpdateSirene:                                      ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_57498
                tst.w   4(a5)
                beq.w   Boss_DispatchSireneState
                tst.w   8(a5)
                beq.s   Boss_DispatchSireneState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_UpdateSireneBattleEffects
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_UpdateSireneBattleEffects
                tst.w   (BossHealth).w
                bne.s   Boss_UpdateSireneBattleEffects
                move.b  #$C1,d0
                jsr     (Sound_QueueSFXRequest).l
                bclr    #7,(PlayerRestrictionFlags).w
                moveq   #$E,d0
                jmp     Boss_QueueSevenForcePostBattleTransition
; ---------------------------------------------------------------------------
Boss_UpdateSireneBattleEffects:                         ; CODE XREF: Boss_UpdateSirene+14   j  ; was: loc_574D4
                                        ; Boss_UpdateSirene+1C   j
                lea     (PaletteFade_SevenForceEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                moveq   #$C,d0
                jsr     (Gfx_UpdateSevenForceBattlePalette).l
; Resolve the even-numbered state offset and jump to its handler
Boss_DispatchSireneState:                               ; CODE XREF: Boss_UpdateSirene+4   j  ; was: loc_574E8
                                        ; Boss_UpdateSirene+C   j
                move.w  4(a5),d0
                movea.w Boss_SireneStateOffsets(pc,d0.w),a0
                adda.l  #Boss_InitSireneState0,a0
                jmp     (a0)
; End of function Boss_UpdateSirene
; ---------------------------------------------------------------------------
; Eleven relative handler offsets for states $00 through $14
Boss_SireneStateOffsets:    dc.w    Boss_InitSireneState0-Boss_InitSireneState0  ; was: off_574F8
                                        ; DATA XREF: Boss_UpdateSirene+54   r
                dc.w    Boss_UpdateSireneState2-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState4-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState6-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState8-Boss_InitSireneState0
                dc.w    Boss_InitSireneStateA-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneStateC-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneStateE-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState10-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState12-Boss_InitSireneState0
                dc.w    Boss_UpdateSireneState14-Boss_InitSireneState0

; Initialize the Sirene metasprite and enter state four
Boss_InitSireneState0:                                  ; CODE XREF: Boss_InitSireneStateA   p  ; was: sub_5750E
                                        ; DATA XREF: Boss_UpdateSirene+58   o
                bsr.s   Boss_InitSireneMetasprite
                move.w  #2,$1DE(a5)
                move.w  #$8000,(GlobalSpritePriorityBit).w
                bra.w   Boss_EnterSireneState4
; End of function Boss_InitSireneState0
; Initialize Sirene's 28-part metasprite and pose-frame source
Boss_InitSireneMetasprite:                              ; CODE XREF: Boss_InitSireneState0   p  ; was: sub_57520
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$1B,d7
                movea.l #Boss_SireneMetaspritePartDescriptors,a0
                movea.l #Boss_SireneMetaspriteInitialAngles,a1
                movea.l #Boss_SireneMetaspritePartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.l  #Boss_SireneMetaspritePoseAngles,$2FC(a5)
                move.l  #Sirene_PoseTable,$35C(a5)
                move.w  #$434,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                rts
; End of function Boss_InitSireneMetasprite
; Alternate entry: initialize Sirene at a fixed position and continue in state two
Boss_InitSireneAtFixedPosition:                         ; was: sub_57568
                move.w  #2,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$E0,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.w   (PlayerScriptStateOffset).w
                move.w  #$FFF0,$3BC(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$120,$70(a5)
                move.w  #$100,$74(a5)
                move.w  #$C680,$48(a5)
                move.w  #$C680,$4A(a5)
; End of function Boss_InitSireneAtFixedPosition
; State two changes the pose angle from vertical controller input
Boss_UpdateSireneState2:                                ; DATA XREF: ROM:000574FA   o  ; was: sub_575B6
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_CheckSireneState2DownInput
                addq.w  #2,$56(a5)
Boss_CheckSireneState2DownInput:                        ; CODE XREF: Boss_UpdateSireneState2+6   j  ; was: loc_575C2
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_NormalizeSireneState2PoseAngle
                subq.w  #2,$56(a5)
Boss_NormalizeSireneState2PoseAngle:                    ; CODE XREF: Boss_UpdateSireneState2+12   j  ; was: loc_575CE
                andi.w  #$1FE,$56(a5)
                lea     Sirene_State2Poses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneState4:                                 ; CODE XREF: Boss_InitSireneState0+E   j  ; was: loc_575DE
                bset    #7,(PlayerRestrictionFlags).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$FFF0,$3BC(a5)
                move.w  #$C680,$48(a5)
                move.w  #$C680,$4A(a5)
                move.w  #$80,$11C(a5)
                movea.l #Sirene_PoseTable,a0
                bsr.w   Boss_SireneInitializePoseChannels
; End of function Boss_UpdateSireneState2
; State four tracks the shared effect coordinates during its opening delay
Boss_UpdateSireneState4:                                ; DATA XREF: ROM:000574FC   o  ; was: sub_5761C
                move.w  (PlayerXPosition).w,$70(a5)
                move.w  (PrimaryCameraYPosition).w,d0
                subi.w  #$E200,d0
                addi.w  #$1A0,d0
                move.w  d0,$74(a5)
                subq.w  #1,$11C(a5)
                bmi.s   Boss_EnterSireneState6
                lea     Sirene_State4And6Poses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneState6:                                 ; CODE XREF: Boss_UpdateSireneState4+1A   j  ; was: loc_57642
                addq.w  #2,4(a5)
                bset    #0,(PlayerRestrictionFlags).w
                move.w  #$58,(PlayerStateOffset).w      ; 'X'
; State six advances the opening pose before enabling the active battle phase
Boss_UpdateSireneState6:                                ; DATA XREF: ROM:000574FE   o  ; was: loc_57652
                move.w  $6D4(a5),(PlayerYPosition).w
                move.w  $70(a5),(PlayerXPosition).w
                tst.w   $58(a5)
                bmi.s   Boss_EnterSireneState8
                lea     Sirene_State4And6Poses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneState8:                                 ; CODE XREF: Boss_UpdateSireneState4+46   j  ; was: loc_5766E
                addq.w  #2,4(a5)
                move.w  #$7000,(BossHealth).w
                move.w  #$7000,(BossMaxHealth).w
                move.b  #1,(SceneSequenceFlags).w
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d3
                moveq   #$1A,d7
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                jsr     (Object_ClearRecordsExceptTwoTypes_Loop).l
                clr.w   2(a5)
                clr.w   8(a5)
                bset    #2,(PlayerModeFlags).w
                clr.w   (PlayerStateOffset).w
                move.w  #$200,(PlayerYPosition).w
; State eight intentionally performs no update
Boss_UpdateSireneState8:                                ; DATA XREF: ROM:00057500   o  ; was: locret_576AE
                rts
; End of Sirene opening-state sequence
; Initialize state A at the active battle position and continue in state C
Boss_InitSireneStateA:                                  ; DATA XREF: ROM:00057502   o  ; was: sub_576B0
                bsr.w   Boss_InitSireneState0
                move.w  #$C,4(a5)
                move.w  #$FFF0,$3BC(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$180,$10(a5)
                move.w  #$188,$14(a5)
                bset    #0,2(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; State C holds the active pose until the battle-effect gate opens
Boss_UpdateSireneStateC:                                ; DATA XREF: ROM:00057504   o  ; was: loc_576E4
                tst.b   (SceneSequenceFlags).w
                bne.s   Boss_EnterSireneStateE
                lea     Sirene_ActivePoses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneStateE:                                 ; CODE XREF: Boss_UpdateSireneStateC   j  ; was: loc_576F4
                addq.w  #2,4(a5)
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  #$A2FF,(TilemapRowXOrFillWord).w
; State E waits for the queued DMA phase to complete
Boss_UpdateSireneStateE:                                ; DATA XREF: ROM:00057506   o  ; was: loc_5770A
                jsr     (Tilemap_QueueNextConstantRow).l
                tst.w   (TilemapRowCountdown).w
                bmi.s   Boss_EnterSireneState10
                lea     Sirene_ActivePoses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneState10:                                ; CODE XREF: Boss_UpdateSireneStateE   j  ; was: loc_57720
                addq.w  #2,4(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; State $10 runs the timed battle-effect transition and enables spawned objects
Boss_UpdateSireneState10:                               ; DATA XREF: ROM:00057508   o  ; was: loc_5772A
                subq.w  #1,$11C(a5)
                bpl.s   Boss_RenderSireneState10
                bsr.w   Gfx_InitSireneBattleEffect
                lea     (SireneAndLateStagePaletteCommandBank).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.b  #$F9,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.w   (PlayerScriptStateOffset).w
                subi.w  #$20,(CameraXLowerBound).w      ; ' '
                addi.w  #$20,(CameraXUpperBound).w      ; ' '
                clr.b   (BossColorEffectFlags).w
                bclr    #0,(StageTimerPauseFlag).w
                movea.l #Boss_SireneObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                bclr    #0,2(a5)
                bset    #0,$62(a5)
                bra.w   Boss_EnterSireneState12
; ---------------------------------------------------------------------------
Boss_RenderSireneState10:                               ; CODE XREF: Boss_UpdateSireneState10   j  ; was: loc_57780
                lea     Sirene_ActivePoses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_ResetSireneState14PoseScript:                      ; CODE XREF: Boss_UpdateSireneState14   j  ; was: loc_5778A
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_EnterSireneState12:                                ; CODE XREF: Boss_UpdateSireneState10   j  ; was: loc_57794
                move.w  #$12,4(a5)
                move.w  #$C680,$48(a5)
                move.w  #$C680,$4A(a5)
; State $12 updates the periodic projectile and Sirene distortion effect
Boss_UpdateSireneState12:                               ; DATA XREF: ROM:0005750A   o  ; was: loc_577A6
                move.w  $54(a5),d1
                clr.w   $54(a5)
                move.w  $70(a5),d0
                cmp.w   (Entity57XPos).w,d0
                bpl.s   Boss_CheckSireneState12FacingChange
                move.w  #$100,$54(a5)
Boss_CheckSireneState12FacingChange:                    ; CODE XREF: Boss_UpdateSireneState12   j  ; was: loc_577BE
                cmp.w   $54(a5),d1
                bne.s   Boss_EnterSireneState14
                bsr.w   Boss_SpawnSirenePeriodicProjectile
                bsr.w   Boss_UpdateSireneBattlePositionsAndDistortion
                lea     Sirene_ActivePoses(pc),a1
                nop
                bra.w   Boss_RenderSirenePose
; ---------------------------------------------------------------------------
Boss_EnterSireneState14:                                ; CODE XREF: Boss_UpdateSireneState12   j  ; was: loc_577D6
                move.w  #$14,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                lea     Sirene_State14PoseScriptSet0(pc),a0
                nop
                tst.w   $54(a5)
                bne.s   Boss_SelectSireneState14PoseScript
                lea     Sirene_State14PoseScriptSet1(pc),a0
                nop
Boss_SelectSireneState14PoseScript:                     ; CODE XREF: Boss_EnterSireneState14   j  ; was: loc_577F8
                move.w  (RandomNumberState).w,d0
                andi.w  #$C,d0
                move.l  (a0,d0.w),$71C(a5)
; State $14 plays a direction-selected pose script, then returns to state $12
Boss_UpdateSireneState14:                               ; DATA XREF: ROM:0005750C   o  ; was: loc_57806
                tst.w   $58(a5)
                bpl.s   Boss_RenderSireneState14
                bra.w   Boss_ResetSireneState14PoseScript
; ---------------------------------------------------------------------------
Boss_RenderSireneState14:                               ; CODE XREF: Boss_UpdateSireneState14   j  ; was: loc_57810
                bsr.w   Boss_UpdateSireneBattlePositionsAndDistortion
                movea.l $71C(a5),a1
                bra.w   Boss_RenderSirenePose
; End of Sirene active-state controller
; ---------------------------------------------------------------------------
Sirene_State14PoseScriptSet0:   dc.l    Sirene_State14PoseScript0  ; DATA XREF: Boss_EnterSireneState14   o  ; was: off_5781C
                dc.l    Sirene_State14PoseScript0
                dc.l    Sirene_State14PoseScript2
                dc.l    Sirene_State14PoseScript2
Sirene_State14PoseScriptSet1:   dc.l    Sirene_State14PoseScript0  ; DATA XREF: Boss_EnterSireneState14   o  ; was: off_5782C
                dc.l    Sirene_State14PoseScript0
                dc.l    Sirene_State14PoseScript1
                dc.l    Sirene_State14PoseScript1

; Move the player and auxiliary Sirene coordinate, then write mirrored scroll offsets
Boss_UpdateSireneBattlePositionsAndDistortion:          ; CODE XREF: Boss_UpdateSireneState12   p  ; was: sub_5783C
                                        ; Boss_RenderSireneState14   p
                bsr.w   Gfx_UpdateSireneBattleEffectPattern
                move.w  (PlayerXPosition).w,d0
                move.w  (PlayerYPosition).w,d1
                sub.w   (Entity57XPos).w,d0
                sub.w   (Entity57YPos).w,d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #7,d2
                addi.w  #$80,d2
                andi.w  #$1FE,d2
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d2.w),d0
                move.w  (a0,d2.w),d1
                muls.w  #5,d0
                muls.w  #$C,d1
                add.l   d0,(PlayerYPosition).w
                add.l   d1,(PlayerXPosition).w
                cmpi.w  #$159,(PlayerYPosition).w
                bmi.s   Boss_UpdateSireneAuxiliaryPosition
                move.w  #$158,(PlayerYPosition).w
Boss_UpdateSireneAuxiliaryPosition:                     ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+48   j  ; was: loc_5788C
                move.w  $70(a5),d0
                move.w  $74(a5),d1
                sub.w   (Entity57XPos).w,d0
                sub.w   (Entity57YPos).w,d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #7,d2
                addi.w  #$80,d2
                andi.w  #$1FE,d2
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d2.w),d0
                move.w  (a0,d2.w),d1
                muls.w  #4,d0
                muls.w  #$D,d1
                add.l   d0,$74(a5)
                add.l   d1,$70(a5)
                cmpi.w  #$159,$74(a5)
                bmi.s   Boss_CheckSireneAuxiliaryYMinimum
                move.w  #$158,$74(a5)
Boss_CheckSireneAuxiliaryYMinimum:                      ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+94   j  ; was: loc_578D8
                cmpi.w  #$7F,$74(a5)
                bpl.s   Boss_CheckSireneAuxiliaryXMinimum
                move.w  #$80,$74(a5)
Boss_CheckSireneAuxiliaryXMinimum:                      ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+A2   j  ; was: loc_578E6
                cmpi.w  #$5F,$70(a5)                    ; '_'
                bpl.s   Boss_CheckSireneAuxiliaryXMaximum
                move.w  #$60,$70(a5)                    ; '`'
Boss_CheckSireneAuxiliaryXMaximum:                      ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+B0   j  ; was: loc_578F4
                cmpi.w  #$1E1,$70(a5)
                bmi.s   Boss_AdvanceSireneDistortionAccumulators
                move.w  #$1E0,$70(a5)
Boss_AdvanceSireneDistortionAccumulators:               ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+BE   j  ; was: loc_57902
                move.l  #$FFFFD000,$47C(a5)
                move.l  #$FFFFEE00,$41C(a5)
                move.l  #$FFFFE000,$5FC(a5)
                move.l  #$FFFFE000,$59C(a5)
                move.l  $47C(a5),d3
                add.l   d3,$4DC(a5)
                move.l  $5FC(a5),d4
                add.l   d4,$65C(a5)
                move.l  $41C(a5),d5
                add.l   d5,$53C(a5)
                move.l  $59C(a5),d6
                add.l   d6,$6BC(a5)
                move.l  $4DC(a5),d3
                move.l  $53C(a5),d5
                btst    #0,(FrameCounter+1).w
                bne.s   Gfx_PrepareSireneMirroredScrollWrites
                move.l  $65C(a5),d3
                move.l  $6BC(a5),d5
Gfx_PrepareSireneMirroredScrollWrites:                  ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+114   j  ; was: loc_5795A
                movea.w #(HScrollPlaneBRow128-M68K_RAM),a0
                movea.w a0,a1
                moveq   #$B,d7
                moveq   #0,d1
                move.w  (PrimaryCameraXPosition).w,d2
                subi.w  #$60,d2                         ; '`'
                neg.w   d2
Gfx_WriteSireneMirroredHScrollRowsLoop:                 ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+150   j  ; was: loc_5796E
                lea     -$20(a1),a1
                swap    d1
                move.w  d2,d4
                add.w   d1,d4
                move.w  d4,(a0)
                neg.w   d1
                move.w  d2,d4
                add.w   d1,d4
                move.w  d4,(a1)
                neg.w   d1
                swap    d1
                add.l   d3,d1
                lea     $20(a0),a0
                dbf     d7,Gfx_WriteSireneMirroredHScrollRowsLoop
                movea.w #(VScrollPlaneBColumn10-M68K_RAM),a0
                movea.w a0,a1
                moveq   #9,d7
                moveq   #0,d1
Gfx_WriteSireneMirroredVScrollColumnsLoop:              ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion+170   j  ; was: loc_5799A
                subq.w  #4,a1
                swap    d1
                move.w  d1,(a0)
                neg.w   d1
                move.w  d1,(a1)
                neg.w   d1
                swap    d1
                add.l   d5,d1
                addq.w  #4,a0
                dbf     d7,Gfx_WriteSireneMirroredVScrollColumnsLoop
                rts
; End of function Boss_UpdateSireneBattlePositionsAndDistortion
; Initialize the Sirene battle-effect object and display parameters
Gfx_InitSireneBattleEffect:                             ; CODE XREF: Boss_UpdateSireneState10   p  ; was: sub_579B2
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  #$48C,(a0)
                move.w  #$100,2(a0)
                clr.b   $21(a0)
                clr.b   $23(a0)
                move.w  #$120,$10(a0)
                move.w  #$F8,$14(a0)
                move.b  #6,(VDPReg11Shadow+1).w
                move.b  #$C,(PlaneAScrollModeFlags).w
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #0,(PaletteActiveColor16).w
                move.w  #$400,(PaletteActiveColor29).w
                rts
; End of function Gfx_InitSireneBattleEffect
; Write the alternating Sirene pattern and queue its VDP transfer
Gfx_UpdateSireneBattleEffectPattern:                    ; CODE XREF: Boss_UpdateSireneBattlePositionsAndDistortion   p  ; was: sub_579F4
                movea.w #(SirenePatternBuffer-M68K_RAM),a0
                move.l  #$D0D0D0D0,d0
                move.l  #$DDDDDDDD,d1
                btst    #0,(FrameCounter+1).w
                bne.s   Gfx_WriteSireneBattlePattern
                exg     d0,d1
Gfx_WriteSireneBattlePattern:                           ; CODE XREF: Gfx_UpdateSireneBattleEffectPattern+16   j  ; was: loc_57A0E
                move.l  d0,(a0)+
                move.l  d1,(a0)+
                move.l  d0,(a0)+
                move.l  d1,(a0)+
                move.l  d0,(a0)+
                move.l  d1,(a0)+
                move.l  d0,(a0)+
                move.l  d1,(a0)+
                movea.w #(SirenePatternBuffer-M68K_RAM),a0
                move.w  #$5FE0,d0
                move.w  #$8F02,d3
                move.l  #$94009310,d4
                jsr     (VDP_QueueCommand_Build).l
                btst    #0,(FrameCounter+1).w
                bne.s   Gfx_SetSireneAlternatePatternAndPalette
                move.w  #$F000,(SirenePatternNormalA).w
                move.w  #$E000,(SirenePatternNormalB).w
                move.w  #$820,(PaletteActiveColor30).w
                move.w  #$E20,(PaletteActiveColor31).w
                rts
; ---------------------------------------------------------------------------
Gfx_SetSireneAlternatePatternAndPalette:                ; CODE XREF: Gfx_UpdateSireneBattleEffectPattern+48   j  ; was: loc_57A58
                move.w  #$E0,(SirenePatternAltA).w
                move.w  #$F0,(SirenePatternAltB).w
                move.w  #$E00,(PaletteActiveColor30).w
                move.w  #$A00,(PaletteActiveColor31).w
                rts
; End of function Gfx_UpdateSireneBattleEffectPattern
; Advance the Sirene pose, apply it to 28 parts, and begin shared traversal
Boss_RenderSirenePose:                                  ; CODE XREF: Boss_UpdateSireneState2+24   j  ; was: sub_57A72
                                        ; Boss_UpdateSireneState4+22   j
                bsr.w   Boss_UpdateSirenePoseScript
                bsr.w   Boss_ApplySirenePoseToParts
                moveq   #$1A,d7
                jmp     Sprite_BeginMetaspritePartTraversal
; End of function Boss_RenderSirenePose
; Distribute the current pose values and offsets across the Sirene metasprite
Boss_ApplySirenePoseToParts:                            ; CODE XREF: Boss_RenderSirenePose+4   p  ; was: sub_57A82
                movea.w #(SirenePoseHistory-M68K_RAM),a1
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$176(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$1D6(a5)
                move.b  8(a0),d0
                asl.w   #1,d0
                movea.w #(SixthEntityWork56-M68K_RAM),a2
                bsr.w   Boss_PropagateSirenePoseGrid
                move.b  $C(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$536(a5)
                move.b  $10(a0),d1
                asl.w   #1,d1
                add.w   d0,d1
                and.w   d7,d1
                move.w  d1,$596(a5)
                move.b  $14(a0),d0
                asl.w   #1,d0
                movea.w #(SixteenthEntityWork56-M68K_RAM),a2
                bsr.w   Boss_PropagateSirenePoseGrid
                move.b  $18(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  $1C(a0),d0
                asl.w   #1,d0
                addi.w  #$80,d0
                and.w   d7,d0
                move.w  d0,$8F6(a5)
                move.w  d0,$956(a5)
                movea.w #(TwentySixthEntityWork56-M68K_RAM),a2
                moveq   #2,d7
Boss_PropagateSirenePoseRowsLoop:                       ; CODE XREF: Boss_ApplySirenePoseToParts+8A   j  ; was: loc_57AFA
                moveq   #$B,d6
Boss_PropagateSirenePoseColumnsLoop:                    ; CODE XREF: Boss_ApplySirenePoseToParts+80   j  ; was: loc_57AFC
                move.w  (a1),d1
                move.w  d0,(a1)+
                move.w  d1,d0
                dbf     d6,Boss_PropagateSirenePoseColumnsLoop
                move.w  d0,(a2)
                lea     $60(a2),a2
                dbf     d7,Boss_PropagateSirenePoseRowsLoop
                move.b  $20(a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$116(a5)
                move.b  $24(a0),d0
                ext.w   d0
                move.w  $232(a5),d1
                add.w   d0,d1
                move.w  d1,$234(a5)
                move.w  $292(a5),d1
                add.w   d0,d1
                move.w  d1,$294(a5)
                move.w  $2F2(a5),d1
                add.w   d0,d1
                move.w  d1,$2F4(a5)
                move.w  $352(a5),d1
                add.w   d0,d1
                move.w  d1,$354(a5)
                move.w  $5F2(a5),d1
                add.w   d0,d1
                move.w  d1,$5F4(a5)
                move.w  $652(a5),d1
                add.w   d0,d1
                move.w  d1,$654(a5)
                move.w  $6B2(a5),d1
                add.w   d0,d1
                move.w  d1,$6B4(a5)
                move.w  $712(a5),d1
                add.w   d0,d1
                move.w  d1,$714(a5)
                move.w  #$80,d6
                move.w  $3BE(a5),d0
                add.w   $3BC(a5),d0
                move.w  d0,$3BE(a5)
                and.w   d7,d0
                move.w  d0,d1
                move.w  d0,$3B6(a5)
                neg.w   d1
                and.w   d7,d1
                move.w  d1,$776(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,d1
                move.w  d0,$416(a5)
                neg.w   d1
                and.w   d7,d1
                move.w  d1,$7D6(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,d1
                move.w  d0,$476(a5)
                neg.w   d1
                and.w   d7,d1
                move.w  d1,$836(a5)
                add.w   d6,d0
                and.w   d7,d0
                move.w  d0,d1
                move.w  d0,$4D6(a5)
                neg.w   d1
                and.w   d7,d1
                move.w  d1,$896(a5)
                rts
; End of function Boss_ApplySirenePoseToParts
; Propagate one pose value through a four-by-eight linked-part grid
Boss_PropagateSirenePoseGrid:                           ; CODE XREF: Boss_ApplySirenePoseToParts+26   p  ; was: sub_57BCA
                                        ; Boss_ApplySirenePoseToParts+4E   p
                and.w   d7,d0
                moveq   #3,d4
Boss_PropagateSirenePoseGridRowsLoop:                   ; CODE XREF: Boss_PropagateSirenePoseGrid+16   j  ; was: loc_57BCE
                moveq   #7,d5
Boss_PropagateSirenePoseGridColumnsLoop:                ; CODE XREF: Boss_PropagateSirenePoseGrid+C   j  ; was: loc_57BD0
                move.w  (a1),d1
                move.w  d0,(a1)+
                move.w  d1,d0
                dbf     d5,Boss_PropagateSirenePoseGridColumnsLoop
                move.w  d0,(a2)
                lea     $60(a2),a2
                dbf     d4,Boss_PropagateSirenePoseGridRowsLoop
                rts
; End of function Boss_PropagateSirenePoseGrid
; Interpret the current state's Sirene pose script
Boss_UpdateSirenePoseScript:                            ; CODE XREF: Boss_RenderSirenePose   p  ; was: sub_57BE6
                clr.b   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_AdvanceSirenePoseInterpolation
Boss_ReadSirenePoseScriptCommand:                       ; CODE XREF: Boss_UpdateSirenePoseScript+24   j  ; was: loc_57BF0
                                        ; Boss_LoadSirenePoseFrame+E   j
                move.w  $58(a5),d0
                bmi.w   Boss_PrepareSirenePoseRender
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_ProcessSirenePoseScriptEntry
                move.b  1(a1,d0.w),$23E(a5)
                addq.w  #2,$58(a5)
                bra.s   Boss_ReadSirenePoseScriptCommand
; ---------------------------------------------------------------------------
Boss_ProcessSirenePoseScriptEntry:                      ; CODE XREF: Boss_UpdateSirenePoseScript+18   j  ; was: loc_57C0C
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_LoadSirenePoseFrame
                move.w  d3,$58(a5)
                bra.w   Boss_PrepareSirenePoseRender
; End of function Boss_UpdateSirenePoseScript
Boss_SirenePoseScriptNoOp:                              ; was: nullsub_130
                rts
; End of function Boss_SirenePoseScriptNoOp

; Load a Sirene pose frame and advance its interpolation countdown
Boss_LoadSirenePoseFrame:                               ; CODE XREF: Boss_UpdateSirenePoseScript+2E   j  ; was: sub_57C20
                cmpi.w  #$FFFF,d3
                bne.s   Boss_StartSirenePoseFrame
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_ReadSirenePoseScriptCommand
; ---------------------------------------------------------------------------
Boss_StartSirenePoseFrame:                              ; CODE XREF: Boss_LoadSirenePoseFrame+4   j  ; was: loc_57C30
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                add.l   $35C(a5),d0
                movea.l d0,a0
                bsr.w   Boss_CalculateSirenePoseInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                tst.w   $C(a5)
                bmi.s   Boss_PrepareSirenePoseRender
Boss_AdvanceSirenePoseInterpolation:                    ; CODE XREF: Boss_UpdateSirenePoseScript+8   j  ; was: loc_57C60
                subq.w  #1,$C(a5)
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #9,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_PrepareSirenePoseRender:                           ; CODE XREF: Boss_UpdateSirenePoseScript+E   j  ; was: loc_57C70
                                        ; Boss_UpdateSirenePoseScript+34   j
                move.w  #$1FE,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                rts
; End of function Boss_LoadSirenePoseFrame
; Calculate interpolation deltas for the next Sirene pose frame
Boss_CalculateSirenePoseInterpolation:                  ; CODE XREF: Boss_LoadSirenePoseFrame+24   p  ; was: sub_57C7A
                movea.l $2FC(a5),a1
                moveq   #9,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a2
                move.w  d3,$C(a5)
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Boss_CalculateSirenePoseInterpolation
; Initialize Sirene's ten fixed-point pose channels from bytes at a0
Boss_SireneInitializePoseChannels:                      ; CODE XREF: Boss_EnterSireneState4   p  ; was: sub_57C8E
                moveq   #9,d7
                movea.w #(SharedScratchLong0-M68K_RAM),a1
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_SireneInitializePoseChannels
; ---------------------------------------------------------------------------
; Direct state-selected command streams for Boss_UpdateSirenePoseScript
Sirene_State2Poses: dc.w    $810, 0, $1010, 0, $810, $A, $1010, $A  ; was: word_57C9A
                                        ; DATA XREF: Boss_UpdateSireneState2+1E   o
                dc.w    $FFFF
Sirene_ActivePoses: dc.w    $820, 0, $C0C, 0, $418, $A, $4040, $A  ; was: word_57CAC
                                        ; DATA XREF: Boss_UpdateSireneStateC   o
                                        ; Boss_UpdateSireneStateE   o
                                        ; Boss_RenderSireneState10   o
                                        ; Boss_UpdateSireneState12   o
                dc.w    $FFFF
Sirene_State4And6Poses: dc.w    $2050, $5A, $2020, $5A, $418, $64, $4040, $64  ; was: word_57CBE
                                        ; DATA XREF: Boss_UpdateSireneState4+1C   o
                                        ; Boss_UpdateSireneState6   o
                dc.w    $2050, $5A, $2020, $5A, $FFFE
; State-$14 streams selected indirectly by the two four-pointer tables
Sirene_State14PoseScript0:  dc.w    $820, $14, $C0C, $14, $418, $1E, $4040, $1E  ; was: word_57CD8
                                        ; DATA XREF: ROM:Sirene_State14PoseScriptSet0   o
                                        ; ROM:00057820   o
                dc.w    $FFFE
Sirene_State14PoseScript1:  dc.w    $820, $28, $C0C, $28, $418, $32, $4040, $32  ; was: word_57CEA
                                        ; DATA XREF: ROM:00057834   o
                                        ; ROM:00057838   o
                dc.w    $FFFE
Sirene_State14PoseScript2:  dc.w    $820, $3C, $C0C, $3C, $418, $46, $4040, $46  ; was: word_57CFC
                                        ; DATA XREF: ROM:00057824   o
                                        ; ROM:00057828   o
                dc.w    $FFFE
; Additional words follow the stop marker; no direct symbolic pointer is known
                dc.w    $820, $50, $1414, $50, $FFFE
; Frame-data base saved at $35C(a5), then indexed by signed script offsets
Sirene_PoseTable:   dc.w    $88D2, $40F8, $2E4E, $3024, $B201, $9C00, $A0E0, $E0  ; was: word_57D18
                                        ; DATA XREF: Boss_InitSireneMetasprite+30   o
                                        ; Boss_EnterSireneState4   o
                dc.w    $1FFA, $C5F8, $8800, $90D0, $20, $6060, $ACEE, $80E0
                dc.w    $4800, $6068, $3000, $B814, $88C0, $30E8, $2E40, $2820
                dc.w    $AEF4, $7800, $8410, $5874, $FED8, $C00A, $40A0, $2000
                dc.w    $80, $D040, $80EE, $A020, $C0A0, $80, $20C0, $A014
                dc.w    $9C00, $A0E0, $E0, $1FFA, $C5EE, $80E0, $6000, $2020
                dc.w    $4000, $C0F8, $A030, $E0E0, $D0A0, $4000, $C00C

; Ninth no-op entity update handler in the global dispatch table
Entity_NullUpdateHandler9:                              ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: nullsub_9
                rts
; End of function Entity_NullUpdateHandler9
; Spawn Sirene's type-$490 projectile on the 32-frame interval
Boss_SpawnSirenePeriodicProjectile:                     ; CODE XREF: Boss_UpdateSireneState12   p  ; was: sub_57D88
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.s   Boss_SpawnSirenePeriodicProjectileReturn
                movea.w #(FiftiethEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward4).l
                bne.s   Boss_SpawnSirenePeriodicProjectileReturn
                move.w  #$490,(a0)
                move.w  #$E100,2(a0)
                move.w  #$8480,$E(a0)
                move.l  #SharedCombatSpriteAnimation22,8(a0)
                clr.w   $C(a0)
                move.b  #4,$20(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FC04FC04,$2C(a0)
                clr.b   $23(a0)
                move.w  #$50,$26(a0)                    ; 'P'
                move.w  $70(a5),$10(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                add.w   $74(a5),d0
                move.w  d0,$14(a0)
Boss_SpawnSirenePeriodicProjectileReturn:               ; CODE XREF: Boss_SpawnSirenePeriodicProjectile+8   j  ; was: locret_57DF2
                                        ; Boss_SpawnSirenePeriodicProjectile+14   j
                rts
; End of function Boss_SpawnSirenePeriodicProjectile
; Update a Sirene projectile, including bounds, conversion, drops, and homing
Projectile_UpdateSireneHoming:                          ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_57DF4
                cmpi.w  #$88,$14(a5)
                bmi.s   Projectile_RemoveSireneHomingOutsideBounds
                cmpi.w  #$170,$14(a5)
                bpl.s   Projectile_RemoveSireneHomingOutsideBounds
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$26C,d0
                bpl.s   Projectile_RemoveSireneHomingOutsideBounds
                cmpi.w  #$94,d0
                bpl.s   Projectile_ProcessSireneHomingInBounds
Projectile_RemoveSireneHomingOutsideBounds:             ; CODE XREF: Projectile_UpdateSireneHoming+6   j  ; was: loc_57E18
                                        ; Projectile_UpdateSireneHoming+E   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ProcessSireneHomingInBounds:                 ; CODE XREF: Projectile_UpdateSireneHoming+22   j  ; was: loc_57E20
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertSireneHomingToParticle
                bclr    #7,$22(a5)
                beq.s   Projectile_SteerSireneHomingTowardEntity57
                bclr    #4,$22(a5)
                beq.s   Projectile_ConvertSireneHomingToParticle
                move.w  (FrameCounter).w,d0
                andi.w  #$50,d0                         ; 'P'
                bne.s   Projectile_ConvertSireneHomingToParticle
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_ConvertSireneHomingToParticle
                moveq   #1,d0
                tst.w   (DifficultyMode).w
                beq.s   Projectile_InitSireneHomingPickupDrop
                move.w  #7,d0
Projectile_InitSireneHomingPickupDrop:                  ; CODE XREF: Projectile_UpdateSireneHoming+5A   j  ; was: loc_57E54
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                jsr     (Pickup_SelectRandomSize).l
Projectile_ConvertSireneHomingToParticle:               ; CODE XREF: Projectile_UpdateSireneHoming+30   j  ; was: loc_57E66
                                        ; Projectile_UpdateSireneHoming+40   j
                move.b  #$2F,d0                         ; '/'
                jsr     (Sound_QueueSFXRequest).l
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
; Sirene's battle-effect initializer sets Entity57 to type $48C, not the player
Projectile_SteerSireneHomingTowardEntity57:             ; CODE XREF: Projectile_UpdateSireneHoming+38   j  ; was: loc_57E7E
                move.w  (Entity57XPos).w,d0
                move.w  (Entity57YPos).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #7,d2
                addi.w  #$80,d2
                andi.w  #$1FE,d2
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d2.w),d0
                move.w  (a0,d2.w),d1
                muls.w  #4,d0
                muls.w  #$D,d1
                add.l   d0,$14(a5)
                add.l   d1,$10(a5)
                rts
; End of function Projectile_UpdateSireneHoming
