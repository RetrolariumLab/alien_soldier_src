; Destroyer-Mk2 scroll deformation, linked-part ring, and main state flow

Boss_DestroyerMk2Main:                                  ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4A84E
                tst.w   4(a5)
                beq.w   Boss_DestroyerMk2DispatchMainState
                bsr.w   Gfx_DestroyerMk2UpdateForegroundScrollRows
                btst    #1,$4C(a5)
                bne.s   Boss_DestroyerMk2CheckFinalTransitionTrigger
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_DestroyerMk2CheckFinalTransitionTrigger
                move.w  $50(a5),d0
                beq.s   Boss_DestroyerMk2CheckFinalTransitionTrigger
                sub.w   d0,(BossCombatCounter).w
Boss_DestroyerMk2CheckFinalTransitionTrigger:           ; CODE XREF: Boss_DestroyerMk2Main+12   j  ; was: loc_4A876
                                        ; Boss_DestroyerMk2Main+1C   j
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_DestroyerMk2UpdateEncounterEffects
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_DestroyerMk2UpdateEncounterEffects
                tst.w   (BossHealth).w
                bne.s   Boss_DestroyerMk2UpdateEncounterEffects
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,$4C(a5)
                move.w  #$2A,4(a5)                      ; '*'
                bset    #0,(StageTimerPauseFlag).w
Boss_DestroyerMk2UpdateEncounterEffects:                ; CODE XREF: Boss_DestroyerMk2Main+2E   j  ; was: loc_4A8A4
                                        ; Boss_DestroyerMk2Main+36   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                bsr.w   Gfx_DestroyerMk2CyclePaletteWords
                btst    #3,$4C(a5)
                beq.s   Boss_DestroyerMk2AnchorToScrollPosition
                move.w  #$C70,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                addi.w  #-$80,d0
                lea     (HScrollPlaneARow72).w,a0
                lea     (DestroyerMk2ScrollTable).w,a1
                move.w  #$B6,d7
Boss_DestroyerMk2WriteScrollRowsLoop:                   ; CODE XREF: Boss_DestroyerMk2Main+88   j  ; was: loc_4A8CE
                move.w  d0,(a0)
                move.w  (a1)+,d1
                add.w   d1,(a0)
                addq.w  #4,a0
                dbf     d7,Boss_DestroyerMk2WriteScrollRowsLoop
Boss_DestroyerMk2AnchorToScrollPosition:                ; CODE XREF: Boss_DestroyerMk2Main+66   j  ; was: loc_4A8DA
                lea     (HScrollPlaneARow184).w,a0
                move.w  (a0),d0
                addi.w  #$C0,d0
                move.w  d0,$10(a5)
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$4E(a5)
Boss_DestroyerMk2DispatchMainState:                     ; CODE XREF: Boss_DestroyerMk2Main+4   j  ; was: loc_4A8F4
                move.w  4(a5),d0
                lea     Boss_DestroyerMk2MainStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2Main
; ---------------------------------------------------------------------------
Boss_DestroyerMk2MainStateHandlers: dc.w    Boss_DestroyerMk2InitializeEncounterState-*  ; DATA XREF: Boss_DestroyerMk2Main+AA   o  ; was: off_4A900
                dc.w    Boss_DestroyerMk2SetIntroPlayerModeState-*
                dc.w    Boss_DestroyerMk2LoadEncounterTilesState-*
                dc.w    Boss_DestroyerMk2InitializeScrollDeformationState-*
                dc.w    Boss_DestroyerMk2ShuffleScrollDeformationState-*
                dc.w    Boss_DestroyerMk2WriteInitialScrollBandsState-*
                dc.w    Boss_DestroyerMk2WaitBeforeCollisionEnableState-*
                dc.w    Boss_DestroyerMk2EnableLinkedCollisionState-*
                dc.w    Boss_DestroyerMk2WaitForExternalEffectState-*
                dc.w    Boss_DestroyerMk2ToggleOrbitingPartsState-*
                dc.w    Boss_DestroyerMk2CollapseOrbitingPartsState-*
                dc.w    Boss_DestroyerMk2WaitForLinkedComponentsState-*
                dc.w    Boss_DestroyerMk2SelectScrollWaveParametersState-*
                dc.w    Boss_DestroyerMk2AnimateScrollWaveState-*
                dc.w    Boss_DestroyerMk2WriteScrollWaveState-*
                dc.w    Boss_DestroyerMk2ExpandOrbitingPartsState-*
                dc.w    Boss_DestroyerMk2ResetScrollWavePhaseState-*
                dc.w    Boss_DestroyerMk2ApplySineScrollWaveState-*
                dc.w    Boss_DestroyerMk2DispatchProjectilePatternState-*
                dc.w    Boss_DestroyerMk2EnterProjectilePatternCycle-*
                dc.w    Boss_DestroyerMk2WaitThenRepeatProjectilePatterns-*
                dc.w    Boss_DestroyerMk2WaitForLinkedPartsToDeactivate-*
                dc.w    Boss_DestroyerMk2RunDebrisTransitionTimer-*
                dc.w    Gfx_DestroyerMk2FadeAndLoadFirstTransitionTiles-*
                dc.w    Gfx_DestroyerMk2FadeAndLoadSecondTransitionTiles-*
                dc.w    Boss_DestroyerMk2ClearTransitionControlFlags-*
                dc.w    Boss_DestroyerMk2ClearObjectsForNextEncounter-*
                dc.w    Boss_DestroyerMk2FinishTransitionPaletteFade-*

; Initializes encounter buffers, controller fields, and linked object records
Boss_DestroyerMk2InitializeEncounterState:              ; DATA XREF: ROM:Boss_DestroyerMk2MainStateHandlers   o  ; was: sub_4A938
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_DestroyerMk2InitializeEncounterReturn
                addq.w  #2,4(a5)
                moveq   #0,d0
                move.l  d0,(SharedScratchLong1).w
                move.l  d0,(SharedScratchLong2).w
                move.l  d0,(SharedScratchLong3).w
                clr.w   (SharedScratchLong6).w
                lea     (DestroyerMk2ScrollRows).w,a0
                lea     (DestroyerMk2RowSpeeds).w,a1
                move.w  #$7F,d7
Boss_DestroyerMk2ClearScrollBuffersLoop:                ; CODE XREF: Boss_DestroyerMk2InitializeEncounterState+2E   j  ; was: loc_4A962
                move.l  d0,(a0)+
                move.l  d0,(a1)+
                dbf     d7,Boss_DestroyerMk2ClearScrollBuffersLoop
                move.b  #4,(PlayerOAMBucketOffset).w
                bset    #3,$4C(a5)
                move.w  #$240,d0
                move.w  #$3DC,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$C0,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  #$118,$14(a5)
                move.b  #4,(PlaneBScrollModeFlags).w
                move.b  #1,(PlaneAScrollModeFlags).w
                lea     (HScrollPlaneARow72).w,a0
                move.w  #$FF80,d0
                move.w  #$B7,d7
Boss_DestroyerMk2InitializeScrollRowsLoop:              ; CODE XREF: Boss_DestroyerMk2InitializeEncounterState+7A   j  ; was: loc_4A9AE
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Boss_DestroyerMk2InitializeScrollRowsLoop
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #$100,2(a5)
                move.b  #$88,$23(a5)
                move.w  #$96,$26(a5)
                move.l  #$F808E818,$2C(a5)
                move.l  #$F40CE020,$28(a5)
                move.w  #$1C,$24(a5)
                move.w  #8,(SharedScratchLong4).w
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
                move.w  #$25C,(a0)
                move.b  #$10,$23(a0)
                move.w  #$D00,2(a0)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$D00,2(a0)
                move.b  #$10,$23(a0)
                move.w  #$96,$26(a0)
                move.b  #$10,$23(a0)
                move.l  #$28E020,$2C(a0)
                move.l  #$34D030,$28(a0)
                move.w  #$FFC0,$4C(a0)
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$D00,2(a0)
                move.b  #$10,$23(a0)
                move.w  #$96,$26(a0)
                move.b  #$10,$23(a0)
                move.l  #$D800E020,$2C(a0)
                move.l  #$CC00D030,$28(a0)
                move.w  #$40,$4C(a0)                    ; '@'
                move.b  $20(a5),d1
                move.w  #3,d7
                clr.w   d6
                movea.w #(FifthEntityType-M68K_RAM),a0
                lea     Boss_DestroyerMk2LinkedPartDescriptors(pc),a1
                nop
Boss_DestroyerMk2InitializeLinkedPartLoop:              ; CODE XREF: Boss_DestroyerMk2InitializeEncounterState+17C   j  ; was: loc_4AA7E
                move.w  #$244,(a0)
                move.w  #$4D00,2(a0)
                move.b  #$10,$23(a0)
                move.w  #$96,$26(a0)
                move.b  d1,$20(a0)
                move.l  #Boss_DestroyerMk2ComponentMapping,8(a0)
                move.w  (a1)+,$4E(a0)
                move.w  (a1)+,$4A(a0)
                move.w  (a1)+,$4C(a0)
                move.w  (a1)+,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2InitializeLinkedPartLoop
                move.w  #$D0,(SharedScratchLong1).w
                move.w  #7,d7
                movea.w #(NinthEntityType-M68K_RAM),a0
                clr.w   d6
Boss_DestroyerMk2InitializeOrbitingPartLoop:            ; CODE XREF: Boss_DestroyerMk2InitializeEncounterState+1DA   j  ; was: loc_4AAC8
                move.w  #$258,(a0)
                move.w  #$CD00,2(a0)
                move.b  #$18,$23(a0)
                move.w  #$28,$26(a0)                    ; '('
                move.l  #$F808F808,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  #$30,$24(a0)                    ; '0'
                move.b  d1,$20(a0)
                move.l  #Boss_DestroyerMk2OrbitingPartMapping2,8(a0)
                move.w  #$EB00,$E(a0)
                move.w  d6,$4C(a0)
                addi.w  #$40,d6                         ; '@'
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2InitializeOrbitingPartLoop
Boss_DestroyerMk2InitializeEncounterReturn:             ; CODE XREF: Boss_DestroyerMk2InitializeEncounterState+4   j  ; was: locret_4AB16
                rts
; End of function Boss_DestroyerMk2InitializeEncounterState
; ---------------------------------------------------------------------------
Boss_DestroyerMk2LinkedPartDescriptors: dc.w    0, $FFD4, $FFC4, $F300  ; was: word_4AB18
                                        ; DATA XREF: Boss_DestroyerMk2InitializeEncounterState+140   o
                dc.w    2, $2C, $FFC4, $FB00
                dc.w    4, $FFD4, $3C, $E300
                dc.w    6, $2C, $3C, $EB00

; Publishes player mode 3 and advances to tile loading
Boss_DestroyerMk2SetIntroPlayerModeState:               ; DATA XREF: ROM:0004A902   o  ; was: sub_4AB38
                move.b  #3,(VDPReg11Shadow+1).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2SetIntroPlayerModeState
; Loads the encounter tile block and advances
Boss_DestroyerMk2LoadEncounterTilesState:               ; DATA XREF: ROM:0004A904   o  ; was: sub_4AB44
                addq.w  #2,4(a5)
                lea     Boss_DestroyerMk2EncounterTileLoadDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedColumns).l
                rts
; End of function Boss_DestroyerMk2LoadEncounterTilesState
; ---------------------------------------------------------------------------
Boss_DestroyerMk2EncounterTileLoadDescriptor:   dc.w    $4480, $2000, $304, $9697, $9495, $9293, $9091, $8687, $8485, $8A8B, $8889, $8E8F, $8C8D  ; was: word_4AB56
                                        ; DATA XREF: Boss_DestroyerMk2LoadEncounterTilesState+4   o

; Waits for the intro gate, then initializes scroll-deformation state
Boss_DestroyerMk2InitializeScrollDeformationState:      ; DATA XREF: ROM:0004A906   o  ; was: sub_4AB70
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_DestroyerMk2InitializeScrollDeformationReturn
                move.w  #8,(SharedScratchLong3).w
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                bsr.w   Boss_DestroyerMk2InitializeScrollIndexTable
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2InitializeScrollDeformationReturn:     ; CODE XREF: Boss_DestroyerMk2InitializeScrollDeformationState+4   j  ; was: locret_4AB8E
                rts
; End of function Boss_DestroyerMk2InitializeScrollDeformationState
; Shuffles four scroll indices per frame during the initial delay
Boss_DestroyerMk2ShuffleScrollDeformationState:         ; DATA XREF: ROM:0004A908   o  ; was: sub_4AB90
                bsr.w   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.w   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.w   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.w   Boss_DestroyerMk2ShuffleScrollIndexPair
                move.w  (RandomNumberState).w,d0
                andi.w  #$E,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2ShuffleScrollDeformationReturn
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
                move.b  #$5B,d0                         ; '['
                jsr     (Sound_QueueSFXRequest).l
Boss_DestroyerMk2ShuffleScrollDeformationReturn:        ; CODE XREF: Boss_DestroyerMk2ShuffleScrollDeformationState+20   j  ; was: locret_4ABC4
                rts
; End of function Boss_DestroyerMk2ShuffleScrollDeformationState
; Writes $E0 to four selected scroll rows per frame until all 256 are covered
Boss_DestroyerMk2WriteInitialScrollBandsState:          ; DATA XREF: ROM:0004A90A   o  ; was: sub_4ABC6
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                move.w  (RandomNumberState).w,d0
                andi.w  #$E,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
                move.w  #$E0,d0
                bsr.w   Boss_DestroyerMk2WriteFourScrollOffsets
                addq.w  #4,$4A(a5)
                cmpi.w  #$100,$4A(a5)
                bne.s   Boss_DestroyerMk2WriteInitialScrollBandsReturn
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                moveq   #0,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
Boss_DestroyerMk2WriteInitialScrollBandsReturn:         ; CODE XREF: Boss_DestroyerMk2WriteInitialScrollBandsState+22   j  ; was: locret_4ABFA
                rts
; End of function Boss_DestroyerMk2WriteInitialScrollBandsState
; Holds linked-object geometry for $10 frames before collision activation
Boss_DestroyerMk2WaitBeforeCollisionEnableState:        ; DATA XREF: ROM:0004A90C   o  ; was: sub_4ABFC
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2WaitBeforeCollisionEnableReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2WaitBeforeCollisionEnableReturn:       ; CODE XREF: Boss_DestroyerMk2WaitBeforeCollisionEnableState+8   j  ; was: locret_4AC10
                rts
; End of function Boss_DestroyerMk2WaitBeforeCollisionEnableState
; Enables linked collision fields and advances to the external-effect wait
Boss_DestroyerMk2EnableLinkedCollisionState:            ; DATA XREF: ROM:0004A90E   o  ; was: sub_4AC12
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2EnableLinkedCollisionReturn
                bsr.w   Boss_DestroyerMk2SetLinkedCollisionFields
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
Boss_DestroyerMk2EnableLinkedCollisionReturn:           ; CODE XREF: Boss_DestroyerMk2EnableLinkedCollisionState+8   j  ; was: locret_4AC2E
                rts
; End of function Boss_DestroyerMk2EnableLinkedCollisionState
; Enables collision fields on the controller and twelve linked records
Boss_DestroyerMk2SetLinkedCollisionFields:              ; CODE XREF: Boss_DestroyerMk2EnableLinkedCollisionState+A   p  ; was: sub_4AC30
                                        ; Boss_DestroyerMk2ExpandOrbitingPartsState+2A   p
                move.b  #$D0,$21(a5)
                move.b  #$C0,(SecondaryEntityStatus).w
                move.b  #$C0,(TertiaryEntityStatus).w
                movea.w #(FifthEntityType-M68K_RAM),a0
                move.w  #$B,d7
Boss_DestroyerMk2SetLinkedCollisionLoop:                ; CODE XREF: Boss_DestroyerMk2SetLinkedCollisionFields+24   j  ; was: loc_4AC4A
                move.b  #$C0,$21(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2SetLinkedCollisionLoop
                rts
; End of function Boss_DestroyerMk2SetLinkedCollisionFields
; Clears collision fields on the controller and twelve linked records
Boss_DestroyerMk2ClearLinkedCollisionFields:            ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsState+2E   p  ; was: sub_4AC5A
                                        ; Boss_DestroyerMk2WaitForLinkedPartsToDeactivate+22   p
                clr.b   $21(a5)
                clr.b   (SecondaryEntityStatus).w
                clr.b   (TertiaryEntityStatus).w
                movea.w #(FifthEntityType-M68K_RAM),a0
                move.w  #$B,d7
Boss_DestroyerMk2ClearLinkedCollisionLoop:              ; CODE XREF: Boss_DestroyerMk2ClearLinkedCollisionFields+1C   j  ; was: loc_4AC6E
                clr.b   $21(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2ClearLinkedCollisionLoop
                rts
; End of function Boss_DestroyerMk2ClearLinkedCollisionFields
; Waits for MessageSequenceState, then updates external state and orbiting-part fields
Boss_DestroyerMk2WaitForExternalEffectState:            ; DATA XREF: ROM:0004A910   o  ; was: sub_4AC7C
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                tst.w   (MessageSequenceState).w
                bne.s   Boss_DestroyerMk2WaitForExternalEffectReturn
                addq.w  #2,4(a5)
                subi.w  #$A0,(CameraXLowerBound).w
                clr.b   (BossColorEffectFlags).w
                movea.w #(NinthEntityType-M68K_RAM),a0
                move.w  #8,d7
Boss_DestroyerMk2LowerOrbitingPartCollisionLoop:        ; CODE XREF: Boss_DestroyerMk2WaitForExternalEffectState+2A   j  ; was: loc_4AC9C
                move.b  #8,$23(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2LowerOrbitingPartCollisionLoop
Boss_DestroyerMk2WaitForExternalEffectReturn:           ; CODE XREF: Boss_DestroyerMk2WaitForExternalEffectState+8   j  ; was: locret_4ACAA
                rts
; End of function Boss_DestroyerMk2WaitForExternalEffectState
; Alternates the orbiting-part active bits before the collapse state
Boss_DestroyerMk2ToggleOrbitingPartsState:              ; DATA XREF: ROM:0004A912   o  ; was: sub_4ACAC
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                eori.w  #1,$54(a5)
                bne.s   Boss_DestroyerMk2AdvanceOrbitToggle
                move.w  #$20,4(a5)                      ; ' '
                rts
; ---------------------------------------------------------------------------
Boss_DestroyerMk2AdvanceOrbitToggle:                    ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsState+A   j  ; was: loc_4ACC0
                addq.w  #2,4(a5)
; Collapses the orbiting ring angle to $60, then disables the linked parts
Boss_DestroyerMk2CollapseOrbitingPartsState:            ; DATA XREF: ROM:0004A914   o  ; was: loc_4ACC4
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                bsr.s   Boss_DestroyerMk2ToggleOrbitingPartsActive
                subq.w  #4,(SharedScratchLong1).w
                cmpi.w  #$60,(SharedScratchLong1).w     ; '`'
                bcc.s   Boss_DestroyerMk2CollapseOrbitingPartsReturn
                bsr.s   Boss_DestroyerMk2DisableOrbitingParts
                bsr.s   Boss_DestroyerMk2InitializeScrollIndexTable
                bsr.w   Boss_DestroyerMk2ClearLinkedCollisionFields
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_DestroyerMk2CollapseOrbitingPartsReturn:           ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsState+28   j  ; was: locret_4ACE8
                rts
; End of function Boss_DestroyerMk2ToggleOrbitingPartsState
; Initializes the 256-entry scroll index table in descending order
Boss_DestroyerMk2InitializeScrollIndexTable:            ; CODE XREF: Boss_DestroyerMk2InitializeScrollDeformationState+10   p  ; was: sub_4ACEA
                                        ; Boss_DestroyerMk2ToggleOrbitingPartsState+2C   p
                move.w  #$FF,d7
                lea     (SharedScratchLong8).w,a0
Boss_DestroyerMk2InitializeScrollIndexLoop:             ; CODE XREF: Boss_DestroyerMk2InitializeScrollIndexTable+A   j  ; was: loc_4ACF2
                move.w  d7,(a0)+
                dbf     d7,Boss_DestroyerMk2InitializeScrollIndexLoop
                rts
; End of function Boss_DestroyerMk2InitializeScrollIndexTable
; Toggles the active bit on eight orbiting-part records
Boss_DestroyerMk2ToggleOrbitingPartsActive:             ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsState+1C   p  ; was: sub_4ACFA
                                        ; Boss_DestroyerMk2ExpandOrbitingPartsState+10   p
                move.w  #7,d7
                movea.w #(NinthEntityType-M68K_RAM),a0
Boss_DestroyerMk2ToggleOrbitingPartLoop:                ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsActive+12   j  ; was: loc_4AD02
                eori.w  #$8000,2(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2ToggleOrbitingPartLoop
                rts
; End of function Boss_DestroyerMk2ToggleOrbitingPartsActive
; Disables eight orbiting parts and clears their collision fields
Boss_DestroyerMk2DisableOrbitingParts:                  ; CODE XREF: Boss_DestroyerMk2ToggleOrbitingPartsState+2A   p  ; was: sub_4AD12
                move.w  #7,d7
                movea.w #(NinthEntityType-M68K_RAM),a0
Boss_DestroyerMk2DisableOrbitingPartLoop:               ; CODE XREF: Boss_DestroyerMk2DisableOrbitingParts+16   j  ; was: loc_4AD1A
                andi.w  #$7FFF,2(a0)
                clr.b   $21(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2DisableOrbitingPartLoop
                rts
; End of function Boss_DestroyerMk2DisableOrbitingParts
; Enables eight orbiting parts and sets their collision fields to $80
Boss_DestroyerMk2EnableOrbitingParts:                   ; CODE XREF: Boss_DestroyerMk2ExpandOrbitingPartsState+20   p  ; was: sub_4AD2E
                move.w  #7,d7
                movea.w #(NinthEntityType-M68K_RAM),a0
Boss_DestroyerMk2EnableOrbitingPartLoop:                ; CODE XREF: Boss_DestroyerMk2EnableOrbitingParts+18   j  ; was: loc_4AD36
                ori.w   #$8000,2(a0)
                move.b  #$80,$21(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_DestroyerMk2EnableOrbitingPartLoop
                rts
; End of function Boss_DestroyerMk2EnableOrbitingParts
; Waits for five linked components while shuffling the scroll-index table
Boss_DestroyerMk2WaitForLinkedComponentsState:          ; DATA XREF: ROM:0004A916   o  ; was: sub_4AD4C
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                tst.w   (FifthEntityState).w
                bne.s   Boss_DestroyerMk2WaitForLinkedComponentsReturn
                tst.w   (SixthEntityState).w
                bne.s   Boss_DestroyerMk2WaitForLinkedComponentsReturn
                tst.w   (SeventhEntityState).w
                bne.s   Boss_DestroyerMk2WaitForLinkedComponentsReturn
                tst.w   (EighthEntityState).w
                bne.s   Boss_DestroyerMk2WaitForLinkedComponentsReturn
                bsr.s   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.s   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.s   Boss_DestroyerMk2ShuffleScrollIndexPair
                bsr.s   Boss_DestroyerMk2ShuffleScrollIndexPair
                move.w  (RandomNumberState).w,d0
                andi.w  #$E,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
                cmpi.w  #$40,$48(a5)                    ; '@'
                bne.s   Boss_DestroyerMk2UpdateLinkedComponentWaitTimer
                move.b  #$E6,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_DestroyerMk2UpdateLinkedComponentWaitTimer:        ; CODE XREF: Boss_DestroyerMk2WaitForLinkedComponentsState+36   j  ; was: loc_4AD8E
                subq.w  #1,$48(a5)
                bne.s   Boss_DestroyerMk2WaitForLinkedComponentsReturn
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2WaitForLinkedComponentsReturn:         ; CODE XREF: Boss_DestroyerMk2WaitForLinkedComponentsState+8   j  ; was: locret_4AD9C
                                        ; Boss_DestroyerMk2WaitForLinkedComponentsState+E   j
                rts
; End of function Boss_DestroyerMk2WaitForLinkedComponentsState
; Exchanges two randomly selected entries in the scroll-index table
Boss_DestroyerMk2ShuffleScrollIndexPair:                ; CODE XREF: Boss_DestroyerMk2ShuffleScrollDeformationState   p  ; was: sub_4AD9E
                                        ; Boss_DestroyerMk2ShuffleScrollDeformationState+4   p
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                move.w  (RandomNumberState+2).w,d1
                andi.w  #$FF,d1
                add.w   d0,d0
                add.w   d1,d1
                lea     (SharedScratchLong8).w,a0
                move.w  (a0,d0.w),d2
                move.w  (a0,d1.w),(a0,d0.w)
                move.w  d2,(a0,d1.w)
                rts
; End of function Boss_DestroyerMk2ShuffleScrollIndexPair
; Applies the default Destroyer-Mk2 palette-fade base
Gfx_DestroyerMk2ApplyPaletteFade:                       ; CODE XREF: Boss_DestroyerMk2ShuffleScrollDeformationState+18   p  ; was: sub_4ADCC
                                        ; Boss_DestroyerMk2WriteInitialScrollBandsState+C   p
                move.w  #$7000,d7
Gfx_DestroyerMk2ApplyPaletteFadeWithBase:               ; CODE XREF: Boss_DestroyerMk2AnimateScrollWaveState+14   p  ; was: loc_4ADD0
                                        ; Boss_DestroyerMk2WriteScrollWaveState+14   p
                movea.w #(PaletteActiveColor48-M68K_RAM),a0
                move.w  #$F,d5
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Gfx_DestroyerMk2ApplyPaletteFade
; Writes one value to four selected scroll-offset rows and clears their velocities
Boss_DestroyerMk2WriteFourScrollOffsets:                ; CODE XREF: Boss_DestroyerMk2WriteInitialScrollBandsState+14   p  ; was: sub_4ADE0
                                        ; sub_4AEFA   p
                lea     (SharedScratchLong8).w,a0
                lea     (DestroyerMk2ScrollRows).w,a1
                lea     (DestroyerMk2RowSpeeds).w,a2
                move.w  $4A(a5),d1
                add.w   d1,d1
                move.w  #3,d7
Boss_DestroyerMk2WriteFourScrollOffsetsLoop:            ; CODE XREF: Boss_DestroyerMk2WriteFourScrollOffsets+26   j  ; was: loc_4ADF6
                move.w  (a0,d1.w),d2
                add.w   d2,d2
                move.w  d0,(a1,d2.w)
                clr.w   (a2,d2.w)
                addq.w  #2,d1
                dbf     d7,Boss_DestroyerMk2WriteFourScrollOffsetsLoop
                rts
; End of function Boss_DestroyerMk2WriteFourScrollOffsets
; Seeds alternating signed velocities in four selected scroll rows
Boss_DestroyerMk2SeedFourScrollVelocities:              ; CODE XREF: Boss_DestroyerMk2AnimateScrollWaveState+18   p  ; was: sub_4AE0C
                lea     (SharedScratchLong8).w,a0
                lea     (DestroyerMk2RowSpeeds).w,a1
                move.w  $4A(a5),d1
                add.w   d1,d1
                move.w  #3,d7
Boss_DestroyerMk2SeedFourScrollVelocitiesLoop:          ; CODE XREF: Boss_DestroyerMk2SeedFourScrollVelocities+30   j  ; was: loc_4AE1E
                move.w  (a0,d1.w),d2
                add.w   d2,d2
                move.w  d7,d0
                andi.w  #1,d0
                beq.s   Boss_DestroyerMk2UsePositiveScrollVelocity
                move.w  #$FFFF,(a1,d2.w)
                bra.s   Boss_DestroyerMk2AdvanceScrollVelocityIndex
; ---------------------------------------------------------------------------
Boss_DestroyerMk2UsePositiveScrollVelocity:             ; CODE XREF: Boss_DestroyerMk2SeedFourScrollVelocities+1E   j  ; was: loc_4AE34
                move.w  #1,(a1,d2.w)
Boss_DestroyerMk2AdvanceScrollVelocityIndex:            ; CODE XREF: Boss_DestroyerMk2SeedFourScrollVelocities+26   j  ; was: loc_4AE3A
                addq.w  #2,d1
                dbf     d7,Boss_DestroyerMk2SeedFourScrollVelocitiesLoop
                rts
; End of function Boss_DestroyerMk2SeedFourScrollVelocities
; Integrates all 255 scroll-row velocities and relaxes positive values toward zero
Boss_DestroyerMk2IntegrateScrollVelocities:             ; CODE XREF: Boss_DestroyerMk2AnimateScrollWaveState+4   p  ; was: sub_4AE42
                                        ; Boss_DestroyerMk2WriteScrollWaveState+4   p
                move.w  #$FE,d7
                lea     (DestroyerMk2ScrollRows).w,a0
                lea     (DestroyerMk2RowSpeeds).w,a1
Boss_DestroyerMk2IntegrateScrollVelocityLoop:           ; CODE XREF: Boss_DestroyerMk2IntegrateScrollVelocities+20   j  ; was: loc_4AE4E
                tst.w   (a1)
                beq.s   Boss_DestroyerMk2AdvanceScrollVelocityRow
                move.w  (a1),d0
                add.w   d0,(a0)
                tst.w   (a1)
                bmi.s   Boss_DestroyerMk2ReducePositiveScrollVelocity
                addq.w  #1,(a1)
Boss_DestroyerMk2ReducePositiveScrollVelocity:          ; CODE XREF: Boss_DestroyerMk2IntegrateScrollVelocities+16   j  ; was: loc_4AE5C
                subq.w  #1,(a1)
Boss_DestroyerMk2AdvanceScrollVelocityRow:              ; CODE XREF: Boss_DestroyerMk2IntegrateScrollVelocities+E   j  ; was: loc_4AE5E
                addq.w  #2,a0
                addq.w  #2,a1
                dbf     d7,Boss_DestroyerMk2IntegrateScrollVelocityLoop
                rts
; End of function Boss_DestroyerMk2IntegrateScrollVelocities
; Selects the next scroll-wave duration and angular velocity
Boss_DestroyerMk2SelectScrollWaveParametersState:       ; DATA XREF: ROM:0004A918   o  ; was: sub_4AE68
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                move.w  $56(a5),d0
                move.w  #$FFE0,(SharedScratchLong5).w
                move.w  Boss_DestroyerMk2ScrollWaveDurationTable(pc,d0.w),$48(a5)
                addq.w  #2,$56(a5)
                andi.w  #$E,$56(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2SelectScrollWaveParametersState
; ---------------------------------------------------------------------------
                dc.w    $130, $FFF0, $130, $FFF0, $90, $FFF0, $130, $90
Boss_DestroyerMk2ScrollWaveDurationTable:   dc.w    $2000, $8000, $2000, $8000, $4000, $8000, $2000, $4000  ; was: word_4AE9C
                                        ; DATA XREF: Boss_DestroyerMk2SelectScrollWaveParametersState+E   r

; Advances the current scroll wave until its 64 four-row batches are complete
Boss_DestroyerMk2AnimateScrollWaveState:                ; DATA XREF: ROM:0004A91A   o  ; was: sub_4AEAC
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                bsr.w   Boss_DestroyerMk2IntegrateScrollVelocities
                move.w  (FrameCounter).w,d0
                andi.w  #$E,d0
                move.w  $48(a5),d7
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFadeWithBase
                bsr.w   Boss_DestroyerMk2SeedFourScrollVelocities
                addq.w  #4,$4A(a5)
                cmpi.w  #$100,$4A(a5)
                bne.s   Boss_DestroyerMk2AnimateScrollWaveReturn
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2AnimateScrollWaveReturn:               ; CODE XREF: Boss_DestroyerMk2AnimateScrollWaveState+26   j  ; was: locret_4AEDC
                rts
; End of function Boss_DestroyerMk2AnimateScrollWaveState
; Updates linked geometry, integrates row velocities, and begins a scroll-wave batch
Boss_DestroyerMk2WriteScrollWaveState:                  ; DATA XREF: ROM:0004A91C   o  ; was: sub_4AEDE
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                bsr.w   Boss_DestroyerMk2IntegrateScrollVelocities
                move.w  (FrameCounter).w,d0
                andi.w  #$E,d0
                move.w  $48(a5),d7
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFadeWithBase
                move.w  (SharedScratchLong5).w,d0
; End of function Boss_DestroyerMk2WriteScrollWaveState
; Writes four rows for the current scroll-wave batch
Boss_DestroyerMk2WriteScrollWaveBands:                  ; was: sub_4AEFA
                bsr.w   Boss_DestroyerMk2WriteFourScrollOffsets
                addq.w  #4,$4A(a5)
                cmpi.w  #$100,$4A(a5)
                bne.s   Boss_DestroyerMk2WriteScrollWaveReturn
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
Boss_DestroyerMk2WriteScrollWaveReturn:                 ; CODE XREF: Boss_DestroyerMk2WriteScrollWaveBands+E   j  ; was: locret_4AF12
                rts
; End of function Boss_DestroyerMk2WriteScrollWaveBands
; Expands the orbiting-ring angle to $D0, then restores collision fields
Boss_DestroyerMk2ExpandOrbitingPartsState:              ; DATA XREF: ROM:0004A91E   o  ; was: sub_4AF14
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                move.w  (FrameCounter).w,d0
                andi.w  #$E,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
                bsr.w   Boss_DestroyerMk2ToggleOrbitingPartsActive
                addq.w  #4,(SharedScratchLong1).w
                cmpi.w  #$D0,(SharedScratchLong1).w
                bne.s   Boss_DestroyerMk2ExpandOrbitingPartsReturn
                bsr.w   Boss_DestroyerMk2EnableOrbitingParts
                moveq   #0,d0
                bsr.w   Gfx_DestroyerMk2ApplyPaletteFade
                bsr.w   Boss_DestroyerMk2SetLinkedCollisionFields
                move.w  #$12,4(a5)
Boss_DestroyerMk2ExpandOrbitingPartsReturn:             ; CODE XREF: Boss_DestroyerMk2ExpandOrbitingPartsState+1E   j  ; was: locret_4AF48
                rts
; End of function Boss_DestroyerMk2ExpandOrbitingPartsState
; Clears vertical phase and starts the sine scroll-wave delay
Boss_DestroyerMk2ResetScrollWavePhaseState:             ; DATA XREF: ROM:0004A920   o  ; was: sub_4AF4A
                clr.w   $1C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2ResetScrollWavePhaseState
; Applies a sine-derived uniform offset to the scroll-row buffer
Boss_DestroyerMk2ApplySineScrollWaveState:              ; DATA XREF: ROM:0004A922   o  ; was: sub_4AF5A
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                addi.w  #-$10,$1C(a5)
                move.w  $1C(a5),d1
                andi.w  #$1FE,d1
                beq.s   Boss_DestroyerMk2AdvanceSineScrollWave
                move.w  (SharedScratchLong4).w,d6
                add.w   d6,d6
                move.w  Boss_DestroyerMk2ScrollWaveBaseOffsetTable(pc,d6.w),d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d1.w),d1
                bpl.s   Boss_DestroyerMk2ApplySineWaveRowOffset
                ext.l   d1
                move.w  Boss_DestroyerMk2ScrollWaveShiftTable(pc,d6.w),d2
                asl.l   d2,d1
                swap    d1
                add.w   d1,d0
Boss_DestroyerMk2ApplySineWaveRowOffset:                ; CODE XREF: Boss_DestroyerMk2ApplySineScrollWaveState+28   j  ; was: loc_4AF90
                bsr.w   Gfx_DestroyerMk2ApplyUniformScrollOffset
                beq.s   Boss_DestroyerMk2ApplySineScrollWaveReturn
                move.w  #$12,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_DestroyerMk2AdvanceSineScrollWave:                 ; CODE XREF: Boss_DestroyerMk2ApplySineScrollWaveState+12   j  ; was: loc_4AF9E
                addq.w  #2,4(a5)
                clr.w   (SharedScratchLong7).w
                addq.w  #2,(SharedScratchLong6+2).w
                andi.w  #$1E,(SharedScratchLong6+2).w
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                move.w  d0,$48(a5)
Boss_DestroyerMk2ApplySineScrollWaveReturn:             ; CODE XREF: Boss_DestroyerMk2ApplySineScrollWaveState+3A   j  ; was: locret_4AFBC
                rts
; End of function Boss_DestroyerMk2ApplySineScrollWaveState
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ScrollWaveBaseOffsetTable: dc.w    5, 5, 5, 4, 4, 4, 3, 3, 2  ; was: word_4AFBE
                                        ; DATA XREF: Boss_DestroyerMk2ApplySineScrollWaveState+1A   r
Boss_DestroyerMk2ScrollWaveShiftTable:  dc.w    5, 5, 5, 5, 4, 4, 4, 3, 3  ; was: word_4AFD0
                                        ; DATA XREF: Boss_DestroyerMk2ApplySineScrollWaveState+2C   r

; Dispatches a nested projectile-pattern table selected by phase and timer sign
Boss_DestroyerMk2DispatchProjectilePatternState:        ; DATA XREF: ROM:0004A924   o  ; was: sub_4AFE2
                bsr.w   Boss_DestroyerMk2UpdateLinkedObjectGeometry
                move.w  (SharedScratchLong6+2).w,d0
                tst.w   $48(a5)
                bmi.w   Boss_DestroyerMk2DispatchNegativeTimerPattern
                move.w  d0,d0
                lea     Boss_DestroyerMk2PositiveTimerPatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; ---------------------------------------------------------------------------
Boss_DestroyerMk2PositiveTimerPatternHandlers:  dc.w    Boss_DestroyerMk2LinkedActivationPatternDispatch-*  ; DATA XREF: Boss_DestroyerMk2DispatchProjectilePatternState+12   o  ; was: off_4AFFC
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2TripleProjectilePatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2LinkedActivationPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectileSpreadPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2TripleProjectilePatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectileSpreadPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectileSpreadPatternDispatch-*
                dc.w    Boss_DestroyerMk2TripleProjectilePatternDispatch-*
; ---------------------------------------------------------------------------
Boss_DestroyerMk2DispatchNegativeTimerPattern:          ; CODE XREF: Boss_DestroyerMk2DispatchProjectilePatternState+C   j  ; was: loc_4B01C
                move.w  d0,d0
                lea     Boss_DestroyerMk2NegativeTimerPatternHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_DestroyerMk2DispatchProjectilePatternState
; ---------------------------------------------------------------------------
Boss_DestroyerMk2NegativeTimerPatternHandlers:  dc.w    Boss_DestroyerMk2LinkedActivationPatternDispatch-*  ; DATA XREF: Boss_DestroyerMk2DispatchProjectilePatternState+3C   o  ; was: off_4B026
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2SingleLinkedActivationDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2LinkedActivationPatternDispatch-*
                dc.w    Boss_DestroyerMk2SingleLinkedActivationDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2SingleLinkedActivationDispatch-*
                dc.w    Boss_DestroyerMk2SingleLinkedActivationDispatch-*
                dc.w    Boss_DestroyerMk2ProjectileSpreadPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectedSweepPatternDispatch-*
                dc.w    Boss_DestroyerMk2ProjectileSpreadPatternDispatch-*
                dc.w    Boss_DestroyerMk2SingleLinkedActivationDispatch-*

; Advances the main state by one state-table slot
Boss_DestroyerMk2AdvanceMainState:                      ; CODE XREF: Boss_DestroyerMk2UpdateProjectedSweep+44   j  ; was: sub_4B046
                                        ; Boss_DestroyerMk2WaitBetweenTripleProjectiles+A   j
                                        ; DATA XREF:
                addq.w  #2,4(a5)
                rts
; End of function Boss_DestroyerMk2AdvanceMainState
; State machine for defeat sequence
