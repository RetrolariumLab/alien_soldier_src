TransitionEffect_ReplaceOwnerAndClearObjects:           ; CODE XREF: EndingSequence_FadeOutCredits+52   p  ; was: sub_268FA
                move.w  #$150,(a5)
                clr.w   4(a5)
                move.w  #$150,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function TransitionEffect_ReplaceOwnerAndClearObjects
; Spawns the alternate transition object at the current object's position
AlternateTransition_SpawnAtOwner:                       ; CODE XREF: Boss_SniperHoneyviperDefeatSequence+58   p  ; was: sub_2690E
                                        ; Boss_TerobusterDefeatFadeState+38   p
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$354,(a0)
                clr.w   4(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                rts
; End of function AlternateTransition_SpawnAtOwner
; Dispatches the alternate defeat-transition object state
AlternateTransition_ObjectMain:                         ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_26928
                move.w  4(a5),d0
                movea.w AlternateTransition_StateOffsets(pc,d0.w),a0
                adda.l  #AlternateTransition_InitializeObject,a0
                jmp     (a0)
; End of function AlternateTransition_ObjectMain
; ---------------------------------------------------------------------------
AlternateTransition_StateOffsets:   dc.w    AlternateTransition_InitializeObject-AlternateTransition_InitializeObject  ; was: off_26938
                                        ; DATA XREF: AlternateTransition_ObjectMain+4   r
                dc.w    AlternateTransition_LoadGraphics-AlternateTransition_InitializeObject
                dc.w    AlternateTransition_ConfigureEffect-AlternateTransition_InitializeObject
                dc.w    AlternateTransition_BuildInitialPattern-AlternateTransition_InitializeObject
                dc.w    AlternateTransition_Update-AlternateTransition_InitializeObject

; Initializes the alternate transition object and clears its mask buffer
AlternateTransition_InitializeObject:                   ; DATA XREF: AlternateTransition_ObjectMain+8   o  ; was: sub_26942
                                        ; ROM:AlternateTransition_StateOffsets   o
                move.w  #2,4(a5)
                move.w  #$100,2(a5)
                move.b  #4,(PlaneBScrollModeFlags).w
                clr.w   (GlobalSpritePriorityBit).w
                bra.w   Effect_ClearTransitionPatternBuffer
; End of function AlternateTransition_InitializeObject
; Loads the shared transition graphics
AlternateTransition_LoadGraphics:                       ; DATA XREF: ROM:0002693A   o  ; was: sub_2695C
                addq.w  #2,4(a5)
                movem.l a5,-(sp)
                lea     AlternateTransition_GraphicsLoadDescriptor(pc),a0
                nop
                jsr     (LoadObjData).l
                movem.l (sp)+,a5
                rts
; End of function AlternateTransition_LoadGraphics
; ---------------------------------------------------------------------------
AlternateTransition_GraphicsLoadDescriptor: dc.w    7   ; field_0  ; was: stru_26976
                                        ; DATA XREF: AlternateTransition_LoadGraphics+8   o
                dc.l    CreditsAndTransitionTileArtE000  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF

; Configures the alternate transition's raster and buffer modes
AlternateTransition_ConfigureEffect:                    ; DATA XREF: ROM:0002693C   o  ; was: sub_26980
                addq.w  #2,4(a5)
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #$14,(RasterLayoutOffset).w
                move.w  #4,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                clr.w   (TransitionProgress).w
                move.w  #8,(TransitionModeOffset).w
                move.b  #$CA,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function AlternateTransition_ConfigureEffect
; Builds the alternate transition's initial mask pattern
AlternateTransition_BuildInitialPattern:                ; DATA XREF: ROM:0002693E   o  ; was: sub_269B4
                addq.w  #2,4(a5)
                move.l  #$18000,(TransitionEdgeSpan).w
                bsr.w   Effect_InitDefeatScroll
; End of function AlternateTransition_BuildInitialPattern
; Advances the alternate transition until the shared completion threshold
AlternateTransition_Update:                             ; DATA XREF: ROM:00026940   o  ; was: sub_269C4
                bsr.w   Effect_UpdateTransitionColor62
                move.w  $10(a5),(TransitionOriginXY).w
                move.w  $14(a5),(TransitionOriginXY+2).w
                addq.w  #3,(TransitionProgress).w
                cmpi.w  #$7F,(TransitionProgress).w
                bmi.w   Effect_ApplyTransitionMask
                bra.w   TransitionEffect_Finish
; End of function AlternateTransition_Update
; Spawns the standard transition object at the current object's position
TransitionEffect_SpawnAtOwner:                          ; CODE XREF: Boss_ShellshogunDefeatPaletteState+10   p  ; was: sub_269E6
                                        ; Boss_JokerFadeOutState+2E   p
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$150,(a0)
                clr.w   4(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                rts
; End of function TransitionEffect_SpawnAtOwner
; Dispatches the standard transition object's state
TransitionEffect_ObjectMain:                            ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_26A00
                move.w  4(a5),d0
                movea.w TransitionEffect_StateOffsets(pc,d0.w),a0
                adda.l  #TransitionEffect_InitializeObject,a0
                jmp     (a0)
; End of function TransitionEffect_ObjectMain
; ---------------------------------------------------------------------------
TransitionEffect_StateOffsets:  dc.w    TransitionEffect_InitializeObject-TransitionEffect_InitializeObject  ; was: off_26A10
                                        ; DATA XREF: TransitionEffect_ObjectMain+4   r
                dc.w    TransitionEffect_LoadGraphics-TransitionEffect_InitializeObject
                dc.w    TransitionEffect_ConfigureEffect-TransitionEffect_InitializeObject
                dc.w    TransitionEffect_BuildInitialPattern-TransitionEffect_InitializeObject
                dc.w    TransitionEffect_Update-TransitionEffect_InitializeObject

; Initializes the standard transition object and clears its mask buffer
TransitionEffect_InitializeObject:                      ; DATA XREF: TransitionEffect_ObjectMain+8   o  ; was: sub_26A1A
                                        ; ROM:TransitionEffect_StateOffsets   o
                move.w  #2,4(a5)
                move.w  #$100,2(a5)
                move.b  #4,(PlaneBScrollModeFlags).w
                clr.w   (GlobalSpritePriorityBit).w
                bra.w   Effect_ClearTransitionPatternBuffer
; End of function TransitionEffect_InitializeObject
; Loads transition graphics data
TransitionEffect_LoadGraphics:                          ; DATA XREF: ROM:00026A12   o  ; was: sub_26A34
                addq.w  #2,4(a5)
                movem.l a5,-(sp)
                lea     TransitionEffect_GraphicsLoadDescriptor(pc),a0
                nop
                jsr     (LoadObjData).l
                movem.l (sp)+,a5
                rts
; End of function TransitionEffect_LoadGraphics
; ---------------------------------------------------------------------------
TransitionEffect_GraphicsLoadDescriptor:    dc.w    7   ; field_0  ; was: stru_26A4E
                                        ; DATA XREF: TransitionEffect_LoadGraphics+8   o
                dc.l    CreditsAndTransitionTileArtE000  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF

; Configures the standard transition's raster and buffer modes
TransitionEffect_ConfigureEffect:                       ; DATA XREF: ROM:00026A14   o  ; was: sub_26A58
                addq.w  #2,4(a5)
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #4,(RasterLayoutOffset).w
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                clr.w   (TransitionProgress).w
                move.b  #$CA,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #2,(TransitionModeOffset).w
                rts
; End of function TransitionEffect_ConfigureEffect
; Builds the standard transition's initial mask pattern
TransitionEffect_BuildInitialPattern:                   ; DATA XREF: ROM:00026A16   o  ; was: sub_26A8E
                addq.w  #2,4(a5)
                move.l  #$18000,(TransitionEdgeSpan).w
                bsr.w   Effect_BuildTransitionPattern
; End of function TransitionEffect_BuildInitialPattern
; Advances the standard transition until the shared completion threshold
TransitionEffect_Update:                                ; DATA XREF: ROM:00026A18   o  ; was: sub_26A9E
                bsr.w   Effect_UpdateTransitionColor62
                move.w  $10(a5),(TransitionOriginXY).w
                move.w  $14(a5),(TransitionOriginXY+2).w
                subi.l  #$3C0,(TransitionEdgeSpan).w
                move.w  (FrameCounter).w,d0
                andi.w  #1,d0
                addq.w  #1,d0
                add.w   d0,(TransitionProgress).w
                cmpi.w  #$7F,(TransitionProgress).w
                bmi.w   Effect_ApplyTransitionMask
TransitionEffect_Finish:                                ; CODE XREF: AlternateTransition_Update+1E   j  ; was: loc_26ACE
                clr.w   (TransitionModeOffset).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                clr.w   (RasterLayoutOffset).w
                bset    #4,2(a5)
                move.b  #4,(PlaneBScrollModeFlags).w
                bra.w   Effect_ClearTransitionPatternBuffer
; End of function TransitionEffect_Update
; Configures raster state for the selected transition buffer mode
TransitionEffect_ConfigureRasterMode:                   ; CODE XREF: Credits_InitializeScreen+84   p  ; was: sub_26AEE
                move.w  (TransitionModeOffset).w,d0
                movea.w TransitionEffect_RasterModeOffsets(pc,d0.w),a0
                adda.l  #TransitionEffect_ConfigureRasterMode0,a0
                jmp     (a0)
; End of function TransitionEffect_ConfigureRasterMode
; ---------------------------------------------------------------------------
TransitionEffect_RasterModeOffsets: dc.w    TransitionEffect_ConfigureRasterMode0-TransitionEffect_ConfigureRasterMode0  ; was: off_26AFE
                                        ; DATA XREF: TransitionEffect_ConfigureRasterMode+4   r
                dc.w    TransitionEffect_ConfigureRasterMode1-TransitionEffect_ConfigureRasterMode0
                dc.w    TransitionEffect_ConfigureRasterModes2And3-TransitionEffect_ConfigureRasterMode0
                dc.w    TransitionEffect_ConfigureRasterModes2And3-TransitionEffect_ConfigureRasterMode0
                dc.w    TransitionEffect_ConfigureRasterMode4-TransitionEffect_ConfigureRasterMode0

; Configures raster registers for transition buffer mode zero
TransitionEffect_ConfigureRasterMode0:                  ; DATA XREF: TransitionEffect_ConfigureRasterMode+8   o  ; was: sub_26B08
                                        ; ROM:TransitionEffect_RasterModeOffsets   o
                move.w  #4,(RasterLayoutOffset).w
                move.b  #$80,(PlaneBScrollModeFlags).w
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                clr.w   (TransitionProgress).w
                rts
; End of function TransitionEffect_ConfigureRasterMode0
; Configures raster registers for transition buffer mode one
TransitionEffect_ConfigureRasterMode1:                  ; DATA XREF: ROM:00026B00   o  ; was: sub_26B2A
                move.w  #4,(RasterLayoutOffset).w
                move.b  #$80,(PlaneBScrollModeFlags).w
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                clr.w   (TransitionProgress).w
                rts
; End of function TransitionEffect_ConfigureRasterMode1
; Configures raster registers for transition buffer mode four
TransitionEffect_ConfigureRasterMode4:                  ; DATA XREF: ROM:00026B06   o  ; was: sub_26B4C
                move.w  #$14,(RasterLayoutOffset).w
                move.b  #$80,(PlaneBScrollModeFlags).w
                move.w  #4,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                clr.w   (TransitionProgress).w
                rts
; End of function TransitionEffect_ConfigureRasterMode4
; Configures the shared raster registers for buffer modes two and three
TransitionEffect_ConfigureRasterModes2And3:             ; DATA XREF: ROM:00026B02   o  ; was: sub_26B6E
                                        ; ROM:00026B04   o
                move.w  #4,(RasterLayoutOffset).w
                move.b  #$80,(PlaneBScrollModeFlags).w
                move.w  #$10,(RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                rts
; End of function TransitionEffect_ConfigureRasterModes2And3
; Dispatches construction of the selected transition-effect output buffers
TransitionEffect_UpdateBuffers:                         ; CODE XREF: EndingSequence_Dispatch   p  ; was: sub_26B8C
                                        ; Sys_GameplayMainLoop+118   p
                move.w  (TransitionModeOffset).w,d0
                movea.w TransitionEffect_BufferModeOffsets(pc,d0.w),a0
                adda.l  #TransitionEffect_UpdateMode1Buffers,a0
                jmp     (a0)
; End of function TransitionEffect_UpdateBuffers
; ---------------------------------------------------------------------------
TransitionEffect_BufferModeOffsets: dc.w    TransitionEffect_UpdateMode0-TransitionEffect_UpdateMode1Buffers  ; was: off_26B9C
                                        ; DATA XREF: TransitionEffect_UpdateBuffers+4   r
                dc.w    TransitionEffect_UpdateMode1Buffers-TransitionEffect_UpdateMode1Buffers
                dc.w    TransitionEffect_UpdateMode2Buffers-TransitionEffect_UpdateMode1Buffers
                dc.w    TransitionEffect_UpdateMode3Buffers-TransitionEffect_UpdateMode1Buffers
                dc.w    TransitionEffect_UpdateMode4Buffers-TransitionEffect_UpdateMode1Buffers

; Builds the standard output buffers for transition mode one
TransitionEffect_UpdateMode1Buffers:                    ; DATA XREF: TransitionEffect_UpdateBuffers+8   o  ; was: sub_26BA6
                                        ; ROM:TransitionEffect_BufferModeOffsets   o
                bsr.w   TransitionEffect_CopyWorkingBuffer
                bra.w   Effect_GenerateTransitionBuffers
; End of function TransitionEffect_UpdateMode1Buffers
; Builds the symmetric ramp and its conditional output buffers for mode two
TransitionEffect_UpdateMode2Buffers:                    ; DATA XREF: ROM:00026BA0   o  ; was: sub_26BAE
                bsr.w   TransitionEffect_CopyWorkingBuffer
                bsr.w   TransitionEffect_BuildSymmetricRamp
                bsr.w   Effect_ProcessConditionalScroll
; End of function TransitionEffect_UpdateMode2Buffers
TransitionEffect_UpdateMode0:                           ; DATA XREF: ROM:TransitionEffect_BufferModeOffsets   o  ; was: nullsub_60
                rts
; End of function TransitionEffect_UpdateMode0

; Builds cleared, filled, and constant-offset output buffers for mode three
TransitionEffect_UpdateMode3Buffers:                    ; DATA XREF: ROM:00026BA2   o  ; was: sub_26BBC
                tst.w   (TransitionMaskStep).w
                bpl.s   TransitionEffect_UpdateMode3Buffers_Prepare
                clr.w   (TransitionMaskStep).w
TransitionEffect_UpdateMode3Buffers_Prepare:            ; CODE XREF: TransitionEffect_UpdateMode3Buffers+4   j  ; was: loc_26BC6
                bsr.w   Effect_ClearScrollBuffer
                bsr.w   TransitionEffect_CopyWorkingBuffer
                bsr.w   Effect_FillScrollBuffer
                bra.w   Effect_ProcessSimpleScroll
; End of function TransitionEffect_UpdateMode3Buffers
; Builds 63 mirrored ramp pairs at $FF9480 from the transition sine table
TransitionEffect_BuildSymmetricRamp:                    ; CODE XREF: TransitionEffect_UpdateMode2Buffers+4   p  ; was: sub_26BD6
                movea.w #(TransitionRampBuffer-M68K_RAM),a0
                movea.w #(TransitionRampBuffer-M68K_RAM),a1
                moveq   #$3E,d7                         ; '>'
                movea.l #Effect_TransitionSineTable,a2
                move.w  (TransitionProgress).w,d0
                andi.w  #$1FE,d0
                cmpi.w  #$80,d0
                beq.s   TransitionEffect_BuildSymmetricRamp_FillMaximum
                cmpi.w  #$180,d0
                beq.s   TransitionEffect_BuildSymmetricRamp_FillZero
                move.w  (a2,d0.w),d1
                muls.w  #$60,d1                         ; '`'
                asl.l   #2,d1
                move.l  #$300000,d0
TransitionEffect_BuildSymmetricRamp_Loop:               ; CODE XREF: TransitionEffect_BuildSymmetricRamp+62   j  ; was: loc_26C0A
                tst.l   d0
                bpl.s   TransitionEffect_BuildSymmetricRamp_CheckHigh
TransitionEffect_BuildSymmetricRamp_ClampLow:           ; CODE XREF: TransitionEffect_BuildSymmetricRamp+46   j  ; was: loc_26C0E
                clr.l   d0
                bra.s   TransitionEffect_BuildSymmetricRamp_StorePair
; ---------------------------------------------------------------------------
TransitionEffect_BuildSymmetricRamp_CheckHigh:          ; CODE XREF: TransitionEffect_BuildSymmetricRamp+36   j  ; was: loc_26C12
                cmpi.l  #$600000,d0
                bpl.s   TransitionEffect_BuildSymmetricRamp_ClampHigh
                add.l   d1,d0
                bmi.s   TransitionEffect_BuildSymmetricRamp_ClampLow
                cmpi.l  #$600000,d0
                bmi.s   TransitionEffect_BuildSymmetricRamp_StorePair
TransitionEffect_BuildSymmetricRamp_ClampHigh:          ; CODE XREF: TransitionEffect_BuildSymmetricRamp+42   j  ; was: loc_26C26
                move.l  #$600000,d0
TransitionEffect_BuildSymmetricRamp_StorePair:          ; CODE XREF: TransitionEffect_BuildSymmetricRamp+3A   j  ; was: loc_26C2C
                                        ; TransitionEffect_BuildSymmetricRamp+4E   j
                swap    d0
                move.w  d0,(a0)+
                swap    d0
                swap    d0
                move.w  d0,-(a1)
                swap    d0
                dbf     d7,TransitionEffect_BuildSymmetricRamp_Loop
TransitionEffect_SetOutputBufferPointers:               ; CODE XREF: Effect_SetupScrollPointers   j  ; was: loc_26C3C
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                movea.w #(TransitionHScrollBuffer-M68K_RAM),a2
                movea.w #(TransitionVScrollBuffer-M68K_RAM),a3
                rts
; ---------------------------------------------------------------------------
TransitionEffect_BuildSymmetricRamp_FillMaximum:        ; CODE XREF: TransitionEffect_BuildSymmetricRamp+1C   j  ; was: loc_26C4A
                moveq   #$60,d0                         ; '`'
                bra.s   TransitionEffect_BuildSymmetricRamp_FillConstantLoop
; ---------------------------------------------------------------------------
TransitionEffect_BuildSymmetricRamp_FillZero:           ; CODE XREF: TransitionEffect_BuildSymmetricRamp+22   j  ; was: loc_26C4E
                moveq   #0,d0
TransitionEffect_BuildSymmetricRamp_FillConstantLoop:   ; CODE XREF: TransitionEffect_BuildSymmetricRamp+76   j  ; was: loc_26C50
                                        ; TransitionEffect_BuildSymmetricRamp+7E   j
                move.w  d0,(a0)+
                move.w  d0,-(a1)
                dbf     d7,TransitionEffect_BuildSymmetricRamp_FillConstantLoop
; End of function TransitionEffect_BuildSymmetricRamp
; Attributes: thunk
; Thunk to set up scroll effect address registers a0/a2/a3 to point to scroll data buffers
