; Seven Force intro controller setup, entrance states, and scroll debug
Entity_UpdateSevenForceIntro:                           ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_54B84
                move.w  4(a5),d0
                beq.w   Entity_SevenForceNoOpState
                movea.w Entity_SevenForceIntroStateOffsets(pc,d0.w),a0
                adda.l  #Entity_SevenForceIntroInitState0,a0
                jmp     (a0)
; End of function Entity_UpdateSevenForceIntro
; ---------------------------------------------------------------------------
Entity_SevenForceIntroStateOffsets: dc.w    Entity_SevenForceIntroInitState0-Entity_SevenForceIntroInitState0  ; was: off_54B98
                                        ; DATA XREF: Entity_UpdateSevenForceIntro+8   r
                dc.w    Entity_SevenForceIntroInitState0-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceEntranceState4-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSwitchTransformationFrameState6-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceWaitForTransformationState8-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceBeginFormSequenceStateA-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceValkirieFadeInStateC-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceValkirieFadeOutStateE-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceStartMedusaEntranceState10-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceUpdateMedusaEntranceState12-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceMedusaHoldState14-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceMedusaFadeOutState16-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceStartSylpheedEntranceState18-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceUpdateSylpheedEntranceState1A-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSylpheedHoldState1C-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceWaitForSylpheedScrollState1E-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSylpheedFadeOutState20-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceStartArtemisEntranceState22-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceUpdateArtemisEntranceState24-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceWaitForArtemisSignalState26-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceArtemisFadeOutState28-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceStartSireneEntranceState2A-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceUpdateSireneEntranceState2C-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSireneHoldState2E-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceResetState30-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSirenePaletteEventState32-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceSirenePaletteEventState34-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceExplosionSequenceState36-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceExplosionWaitState38-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceArmFinalFadeState3A-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceFinalFadeState3C-Entity_SevenForceIntroInitState0
                dc.w    Entity_SevenForceFinishIntroState3E-Entity_SevenForceIntroInitState0

; State 0/2 entry: initialize the Seven Force intro entity
Entity_SevenForceIntroInitState0:                       ; DATA XREF: Entity_UpdateSevenForceIntro+C   o  ; was: sub_54BD8
                                        ; ROM:Entity_SevenForceIntroStateOffsets   o
                bra.w   Entity_InitSevenForceIntro
; End of function Entity_SevenForceIntroInitState0
; Configure the Seven Force intro state and three VDP DMA channels
; No static caller is present in the reconstructed ROM
SevenForce_SetupIntroDma:                               ; was: sub_54BDC
                move.w  #4,4(a5)
                move.b  #6,(VDPReg11Shadow+1).w
                move.b  #$8A,(VDPReg17Shadow+1).w
                move.b  #3,(PlaneAScrollModeFlags).w
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #$58,(RasterEffectIndex).w      ; 'X'
                clr.w   (RasterEffectInitState).w
                move.w  #$4000,(TilemapTransferBase).w
                move.w  #1,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #2,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #$5000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                rts
; End of function SevenForce_SetupIntroDma
; Initialize the Seven Force entrance sprite and palette
Entity_InitSevenForceIntro:                             ; CODE XREF: Entity_SevenForceIntroInitState0   j  ; was: sub_54C3C
                move.w  #4,4(a5)
                move.w  #$E900,2(a5)
                move.w  #$2300,$E(a5)
                move.b  #$14,$20(a5)
                move.l  #Stage24SceneObject_SpriteAnimation,8(a5)
                clr.w   $C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #$60,$10(a5)                    ; '`'
                move.w  #$128,$14(a5)
                lea     (SevenForceIntroPaletteCommand).l,a0
                jmp     Gfx_LoadPaletteCommand
; End of function Entity_InitSevenForceIntro
; State 4 entry thunk for the Seven Force entrance timer
Entity_SevenForceEntranceState4:                        ; DATA XREF: ROM:00054B9C   o  ; was: sub_54C7E
                bra.w   Entity_UpdateSevenForceEntranceState4
; End of function Entity_SevenForceEntranceState4
; Exercise paired scroll-table generators with live directional input
; No static caller is present in the reconstructed ROM
Debug_SevenForceScrollTableTest:                        ; was: sub_54C82
                btst    #6,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckAlternateLayerInput
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckVerticalPositiveInput
                subi.l  #$800,(SharedPatternRow0Long1).w
                subi.l  #$400,(SharedPatternRow0Long3).w
Debug_SevenForceScrollTableTestCheckVerticalPositiveInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+E   j  ; was: loc_54CA2
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckHorizontalPositiveInput
                addi.l  #$800,(SharedPatternRow0Long1).w
                addi.l  #$400,(SharedPatternRow0Long3).w
Debug_SevenForceScrollTableTestCheckHorizontalPositiveInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+26   j  ; was: loc_54CBA
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckHorizontalNegativeInput
                addi.l  #$800,(SharedPatternRow0Long0).w
                addi.l  #$400,(SharedPatternRow0Long2).w
Debug_SevenForceScrollTableTestCheckHorizontalNegativeInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+3E   j  ; was: loc_54CD2
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckAlternateLayerInput
                subi.l  #$800,(SharedPatternRow0Long0).w
                subi.l  #$400,(SharedPatternRow0Long2).w
Debug_SevenForceScrollTableTestCheckAlternateLayerInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+6   j  ; was: loc_54CEA
                                        ; Debug_SevenForceScrollTableTest+56   j
                btst    #4,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckResetInput
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckAlternateVerticalPositiveInput
                subi.l  #$800,(SharedPatternRow0Long5).w
                subi.l  #$400,(SharedPatternRow0Long7).w
Debug_SevenForceScrollTableTestCheckAlternateVerticalPositiveInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+76   j  ; was: loc_54D0A
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckAlternateHorizontalPositiveInput
                addi.l  #$800,(SharedPatternRow0Long5).w
                addi.l  #$400,(SharedPatternRow0Long7).w
Debug_SevenForceScrollTableTestCheckAlternateHorizontalPositiveInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+8E   j  ; was: loc_54D22
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckAlternateHorizontalNegativeInput
                addi.l  #$800,(SharedPatternRow0Long4).w
                addi.l  #$400,(SharedPatternRow0Long6).w
Debug_SevenForceScrollTableTestCheckAlternateHorizontalNegativeInput:  ; CODE XREF: Debug_SevenForceScrollTableTest+A6   j  ; was: loc_54D3A
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestCheckResetInput
                subi.l  #$800,(SharedPatternRow0Long4).w
                subi.l  #$400,(SharedPatternRow0Long6).w
Debug_SevenForceScrollTableTestCheckResetInput:         ; CODE XREF: Debug_SevenForceScrollTableTest+6E   j  ; was: loc_54D52
                                        ; Debug_SevenForceScrollTableTest+BE   j
                btst    #5,(ControllerHeldState).w
                beq.s   Debug_SevenForceScrollTableTestAccumulateOffsets
                clr.l   (SharedPatternRow0Long0).w
                clr.l   (SharedPatternRow0Long2).w
                clr.l   (SharedPatternRow0Long4).w
                clr.l   (SharedPatternRow0Long6).w
                clr.l   (SharedPatternRow0Long1).w
                clr.l   (SharedPatternRow0Long3).w
                clr.l   (SharedPatternRow0Long5).w
                clr.l   (SharedPatternRow0Long7).w
                clr.l   (SharedPatternRow1Long0).w
                clr.l   (SharedPatternRow1Long2).w
                clr.l   (SharedPatternRow1Long4).w
                clr.l   (SharedPatternRow1Long6).w
                clr.l   (SharedPatternRow1Long1).w
                clr.l   (SharedPatternRow1Long3).w
                clr.l   (SharedPatternRow1Long5).w
                clr.l   (SharedPatternRow1Long7).w
Debug_SevenForceScrollTableTestAccumulateOffsets:       ; CODE XREF: Debug_SevenForceScrollTableTest+D6   j  ; was: loc_54D9A
                move.l  (SharedPatternRow0Long0).w,d0
                add.l   d0,(SharedPatternRow1Long0).w
                move.l  (SharedPatternRow0Long2).w,d0
                add.l   d0,(SharedPatternRow1Long2).w
                move.l  (SharedPatternRow0Long1).w,d0
                add.l   d0,(SharedPatternRow1Long1).w
                move.l  (SharedPatternRow0Long3).w,d0
                add.l   d0,(SharedPatternRow1Long3).w
                move.l  (SharedPatternRow0Long4).w,d0
                add.l   d0,(SharedPatternRow1Long4).w
                move.l  (SharedPatternRow0Long6).w,d0
                add.l   d0,(SharedPatternRow1Long6).w
                move.l  (SharedPatternRow0Long5).w,d0
                add.l   d0,(SharedPatternRow1Long5).w
                move.l  (SharedPatternRow0Long7).w,d0
                add.l   d0,(SharedPatternRow1Long7).w
                move.l  (SharedPatternRow1Long0).w,d3
                move.l  (SharedPatternRow1Long4).w,d4
                move.l  (SharedPatternRow1Long1).w,d5
                move.l  (SharedPatternRow1Long5).w,d6
                btst    #0,(FrameCounter+1).w
                bne.s   Debug_SevenForceScrollTableTestBuildTables
                move.l  (SharedPatternRow1Long2).w,d3
                move.l  (SharedPatternRow1Long6).w,d4
                move.l  (SharedPatternRow1Long3).w,d5
                move.l  (SharedPatternRow1Long7).w,d6
Debug_SevenForceScrollTableTestBuildTables:             ; CODE XREF: Debug_SevenForceScrollTableTest+16E   j  ; was: loc_54E02
                movea.w #(HScrollBuffer-M68K_RAM),a0
                movea.w #(HScrollAuxBuffer-M68K_RAM),a1
                moveq   #$F,d7
                moveq   #0,d1
                moveq   #0,d2
Debug_SevenForceScrollTableTestBuildPrimaryLoop:        ; CODE XREF: Debug_SevenForceScrollTableTest+1B6   j  ; was: loc_54E10
                lea     -$20(a1),a1
                swap    d1
                move.w  d1,(a0)
                neg.w   d1
                move.w  d1,(a1)
                neg.w   d1
                swap    d1
                add.l   d3,d1
                swap    d2
                move.w  d2,2(a0)
                neg.w   d2
                move.w  d2,2(a1)
                neg.w   d2
                swap    d2
                add.l   d4,d2
                lea     $20(a0),a0
                dbf     d7,Debug_SevenForceScrollTableTestBuildPrimaryLoop
                movea.w #(VScrollBuffer-M68K_RAM),a0
                movea.w #(VScrollAuxBuffer-M68K_RAM),a1
                moveq   #9,d7
                moveq   #0,d1
                moveq   #0,d2
Debug_SevenForceScrollTableTestBuildSecondaryLoop:      ; CODE XREF: Debug_SevenForceScrollTableTest+1E4   j  ; was: loc_54E4A
                swap    d1
                swap    d2
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                neg.w   d2
                move.w  d2,-(a1)
                neg.w   d2
                neg.w   d1
                move.w  d1,-(a1)
                neg.w   d1
                swap    d1
                swap    d2
                add.l   d5,d1
                add.l   d6,d2
                dbf     d7,Debug_SevenForceScrollTableTestBuildSecondaryLoop
                movea.w #(SevenForcePattern-M68K_RAM),a0
                move.l  #$CCCCCCCC,d0
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  #$CCCCCCCC,d0
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                movea.w #(SevenForcePattern-M68K_RAM),a0
                move.w  #$20,d0                         ; ' '
                move.w  #$8F02,d3
                move.l  #$94009320,d4
                jsr     (VDP_QueueCommand_Build).l
                move.w  #0,(PaletteActiveColor12).w
                btst    #0,(FrameCounter+1).w
                bne.s   Debug_SevenForceScrollTableTestWriteAlternateMarkers
                move.w  #$FCCC,(SevenForcePatchA).w
                move.w  #$ECCC,(SevenForcePatchB).w
                move.w  #$2CCC,(SevenForcePatchC).w
                move.w  #$1CCC,(SevenForcePatchD).w
                move.w  #$E0,(PaletteActiveColor14).w
                move.w  #$E0,(PaletteActiveColor15).w
                move.w  #$E0,(PaletteActiveColor01).w
                move.w  #$E0,(PaletteActiveColor02).w
                rts
; ---------------------------------------------------------------------------
Debug_SevenForceScrollTableTestWriteAlternateMarkers:   ; CODE XREF: Debug_SevenForceScrollTableTest+23C   j  ; was: loc_54EF2
                move.w  #$CCEC,(SevenForceAltPatchA).w
                move.w  #$CCFC,(SevenForceAltPatchB).w
                move.w  #$CC2C,(SevenForceAltPatchC).w
                move.w  #$CC1C,(SevenForceAltPatchD).w
                move.w  #$E0,(PaletteActiveColor14).w
                move.w  #$E0,(PaletteActiveColor15).w
                move.w  #$E0,(PaletteActiveColor01).w
                move.w  #$E0,(PaletteActiveColor02).w
                rts
; End of function Debug_SevenForceScrollTableTest
; Finish state 4 after its timer and advance the stage entrance phase
Entity_UpdateSevenForceEntranceState4:                  ; CODE XREF: Entity_SevenForceEntranceState4   j  ; was: sub_54F24
                subq.w  #1,$48(a5)
                bpl.s   Entity_UpdateSevenForceEntranceState4Return
                addq.w  #2,4(a5)
                move.l  #$10000,$18(a5)
                bset    #0,(StageTimerPauseFlag).w
                jsr     (Stage_TransitionToNextPhase).l
                subq.w  #2,(StageStateOffset).w
Entity_UpdateSevenForceEntranceState4Return:            ; CODE XREF: Entity_UpdateSevenForceEntranceState4+4   j  ; was: locret_54F46
                rts
; End of function Entity_UpdateSevenForceEntranceState4
; State 6: switch the entity mapping after it reaches X=$E0
Entity_SevenForceSwitchTransformationFrameState6:       ; DATA XREF: ROM:00054B9E   o  ; was: sub_54F48
                cmpi.w  #$E0,$10(a5)
                bmi.s   Entity_SevenForceSwitchTransformationFrameReturn
                addq.w  #2,4(a5)
                move.w  #8,$48(a5)
                move.l  #Stage24SceneObject_CompositeSpriteFrame,8(a5)
                clr.w   $C(a5)
                clr.l   $18(a5)
Entity_SevenForceSwitchTransformationFrameReturn:       ; CODE XREF: Entity_SevenForceSwitchTransformationFrameState6+6   j  ; was: locret_54F6A
                rts
; End of function Entity_SevenForceSwitchTransformationFrameState6
; State 8: wait for the shared transition work and local timer
Entity_SevenForceWaitForTransformationState8:           ; DATA XREF: ROM:00054BA0   o  ; was: sub_54F6C
                tst.w   (MessageSequenceState).w
                bne.s   Entity_SevenForceWaitForTransformationReturn
                subq.w  #1,$48(a5)
                bpl.s   Entity_SevenForceWaitForTransformationReturn
                addq.w  #2,4(a5)
Entity_SevenForceWaitForTransformationReturn:           ; CODE XREF: Entity_SevenForceWaitForTransformationState8+4   j  ; was: locret_54F7C
                                        ; Entity_SevenForceWaitForTransformationState8+A   j
                rts
; End of function Entity_SevenForceWaitForTransformationState8
; State A: arm the first form-transition state and sound
Entity_SevenForceBeginFormSequenceStateA:               ; DATA XREF: ROM:00054BA2   o  ; was: sub_54F7E
                tst.w   (MessageSequenceState).w
                bne.s   Entity_SevenForceBeginFormSequenceReturn
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                clr.w   $5E(a5)
                move.b  #$A5,d0
                jsr     (Sound_QueueSFXRequest).l
Entity_SevenForceBeginFormSequenceReturn:               ; CODE XREF: Entity_SevenForceBeginFormSequenceStateA+4   j  ; was: locret_54F9C
                rts
; End of function Entity_SevenForceBeginFormSequenceStateA
