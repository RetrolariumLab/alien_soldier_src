GameOver_InitializeScreen:                              ; was: sub_275C6
                tst.w   (GameSubstateIndex).w
                bne.s   GameOver_InitializeScreen_Activate
                jsr     (Sys_InitGameMode).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
GameOver_InitializeScreen_Activate:                     ; was: loc_275E2
                addq.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                move.w  #$4C,(RasterEffectIndex).w      ; 'L'
                clr.w   (RasterEffectInitState).w
                move.b  #3,(VDPReg11Shadow+1).w
                move.w  #$12,(RasterLayoutOffset).w
                move.b  #$28,(VDPReg2Shadow+1).w        ; '('
                move.b  #5,(VDPReg4Shadow+1).w
                move.b  #0,(VDPReg18Shadow+1).w
                move.b  #$11,(VDPReg16Shadow+1).w
                lea     GameOver_GraphicsLoadDescriptor(pc),a0
                nop
                jsr     (LoadObjData).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                move.w  #$2C,(PaletteActiveColor01).w   ; ','
                move.w  #0,(PaletteActiveColor02).w
                bsr.w   GameOver_InitializeDitherPatterns
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$80,-(a1)
                move.w  #$4020,-(a1)
                move.w  #$9500,-(a1)
                move.w  #$96CA,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009340,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                move.w  #1,(GameOverLandscapeDepth).w
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
                rts
; End of function GameOver_InitializeScreen
; ---------------------------------------------------------------------------
GameOver_GraphicsLoadDescriptor:    dc.w    7           ; field_0  ; was: stru_27676
                dc.l    GameOverTileArtA000             ; field_2
                dc.w    $A000                           ; field_6
                dc.w    $FFFF

; Copies 16 transition-buffer blocks, then dispatches the game-over state
GameOver_CopyTransitionBufferAndDispatch:               ; was: sub_27680
                movea.w #(GameOverRasterSource-M68K_RAM),a0
                movea.w #(GameOverRowWorkBuffer-M68K_RAM),a1
                moveq   #$F,d7
                bsr.w   Effect_Copy32ByteBlocks
                bsr.s   GameOver_Update
                rts
; End of function GameOver_CopyTransitionBufferAndDispatch
; Dispatcher that jumps to game over state handler based on GameSubstateIndex index via offset table
GameOver_Update:                                        ; was: sub_27692
                move.w  (GameSubstateIndex).w,d0
                movea.w GameOver_StateOffsets(pc,d0.w),a0
                adda.l  #GameOver_UpdateInteractiveLandscape,a0
                jmp     (a0)
; End of function GameOver_Update
; ---------------------------------------------------------------------------
GameOver_StateOffsets:  dc.w    GameOver_UpdateInteractiveLandscape-GameOver_UpdateInteractiveLandscape  ; was: off_276A2
                dc.w    GameOver_UpdateAutoLandscape-GameOver_UpdateInteractiveLandscape
                dc.w    GameOver_ResetLandscapeRows-GameOver_UpdateInteractiveLandscape

; Applies interactive angle and depth controls to the game-over landscape
GameOver_UpdateInteractiveLandscape:                    ; was: sub_276A8
                                        ; ROM:GameOver_StateOffsets   o
                btst    #6,(ControllerPressedState).w
                beq.s   GameOver_UpdateInteractiveLandscape_CheckReverseAngle
                addi.w  #$400,(GameOverLandscapeAngle).w
                cmpi.w  #$2000,(GameOverLandscapeAngle).w
                bmi.s   GameOver_UpdateInteractiveLandscape_CheckReverseAngle
                clr.w   (GameOverLandscapeAngle).w
GameOver_UpdateInteractiveLandscape_CheckReverseAngle:  ; was: loc_276C2
                                        ; GameOver_UpdateInteractiveLandscape+14   j
                btst    #4,(ControllerPressedState).w
                beq.s   GameOver_UpdateInteractiveLandscape_CheckIncreaseDepth
                subi.w  #$400,(GameOverLandscapeAngle).w
                bpl.s   GameOver_UpdateInteractiveLandscape_CheckIncreaseDepth
                move.w  #$2000,(GameOverLandscapeAngle).w
GameOver_UpdateInteractiveLandscape_CheckIncreaseDepth:  ; was: loc_276D8
                                        ; GameOver_UpdateInteractiveLandscape+28   j
                btst    #1,(ControllerHeldState).w
                beq.s   GameOver_UpdateInteractiveLandscape_CheckDecreaseDepth
                addi.w  #$10,(GameOverLandscapeDepth).w
GameOver_UpdateInteractiveLandscape_CheckDecreaseDepth:  ; was: loc_276E6
                btst    #0,(ControllerHeldState).w
                beq.s   GameOver_UpdateInteractiveLandscape_CheckAdvance
                subi.w  #$10,(GameOverLandscapeDepth).w
                bmi.s   GameOver_UpdateInteractiveLandscape_ClampMinimumDepth
                bne.s   GameOver_UpdateInteractiveLandscape_CheckAdvance
GameOver_UpdateInteractiveLandscape_ClampMinimumDepth:  ; was: loc_276F8
                move.w  #$10,(GameOverLandscapeDepth).w
GameOver_UpdateInteractiveLandscape_CheckAdvance:       ; was: loc_276FE
                                        ; GameOver_UpdateInteractiveLandscape+4E   j
                btst    #6,(ControllerPressedState).w
                beq.s   GameOver_UpdateInteractiveLandscape_Render
                addq.w  #2,(GameSubstateIndex).w
                clr.w   (GameOverLandscapeIndex).w
                move.w  #$50,(GameOverLandscapeDepth).w  ; 'P'
                move.w  #$20,(GameOverViewOffset).w     ; ' '
GameOver_UpdateInteractiveLandscape_Render:             ; was: loc_2771A
                bsr.w   GameOver_InitializeRowBuffer
                bra.w   GameOver_BuildPerspectiveBuffers
; End of function GameOver_UpdateInteractiveLandscape
; Auto-advances camera through predefined positions using data table
GameOver_UpdateAutoLandscape:                           ; was: sub_27722
                addi.w  #$18,(GameOverLandscapeDepth).w
                cmpi.w  #$450,(GameOverLandscapeDepth).w
                bmi.s   GameOver_UpdateAutoLandscape_AdvanceTimer
                addq.w  #2,(GameOverLandscapeIndex).w
                move.w  #$20,(GameOverLandscapeDepth).w  ; ' '
                move.w  #$20,(GameOverViewOffset).w     ; ' '
GameOver_UpdateAutoLandscape_AdvanceTimer:              ; was: loc_27740
                subq.w  #1,(GameOverViewOffset).w
                move.w  (GameOverLandscapeIndex).w,d0
                move.w  GameOver_LandscapeAngleSequence(pc,d0.w),(GameOverLandscapeAngle).w
                bpl.s   GameOver_UpdateAutoLandscape_Render
                addq.w  #2,(GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
GameOver_UpdateAutoLandscape_Render:                    ; was: loc_27756
                bra.w   GameOver_BuildPerspectiveBuffers
; End of function GameOver_UpdateAutoLandscape
; ---------------------------------------------------------------------------
GameOver_LandscapeAngleSequence:    dc.w    0, $400, $800, $C00, $1000, $1400, $1800, $400, $1C00, $800, $C00, $2000, $FFFF  ; was: word_2775A

; Attributes: thunk
; Thunk to call 3D scene rendering routine
GameOver_ResetLandscapeRows:                            ; was: sub_27774
                bra.w   GameOver_InitializeRowBuffer
; End of function GameOver_ResetLandscapeRows
; Initializes first set of dither patterns for 3D rendering
GameOver_InitializeDitherPatterns:                      ; was: sub_27778
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                move.l  #$1010101,d4
                move.l  #$10101010,d5
                bsr.s   GameOver_FillAlternatingPattern
                move.l  #0,(a0)+
                move.l  #$10000000,(a0)+
                move.l  #$1000000,(a0)+
                move.l  #$10100000,(a0)+
                move.l  #$1010000,(a0)+
                move.l  #$10101000,(a0)+
                move.l  #$1010100,(a0)+
                move.l  #$10101010,(a0)+
                move.l  #$22222222,d4
                move.l  #$22222222,d5
                bsr.s   GameOver_FillAlternatingPattern
                move.l  #0,(a0)+
                move.l  #$20000000,(a0)+
                move.l  #$22000000,(a0)+
                move.l  #$22200000,(a0)+
                move.l  #$22220000,(a0)+
                move.l  #$22222000,(a0)+
                move.l  #$22222200,(a0)+
                move.l  #$22222220,(a0)+
                rts
; End of function GameOver_InitializeDitherPatterns
; Fills 4 blocks with alternating pattern data
GameOver_FillAlternatingPattern:                        ; was: sub_277FA
                                        ; GameOver_InitializeDitherPatterns+4E   p
                moveq   #3,d7
GameOver_FillAlternatingPattern_Loop:                   ; was: loc_277FC
                move.l  d4,(a0)+
                move.l  d5,(a0)+
                dbf     d7,GameOver_FillAlternatingPattern_Loop
                rts
; End of function GameOver_FillAlternatingPattern
; Initializes second set of dither patterns for 3D rendering
UnreferencedGameOver_InitializeDitherPatterns:          ; was: sub_27806
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #0,d0
                move.l  #$11000000,d1
                move.l  #$11110000,d2
                move.l  #$11111100,d3
                move.l  #$11111111,d4
                bsr.s   GameOver_WriteDitherSequence
                moveq   #0,d0
                move.l  #$22000000,d1
                move.l  #$22220000,d2
                move.l  #$22222200,d3
                move.l  #$22222222,d4
; End of function UnreferencedGameOver_InitializeDitherPatterns
; Writes decreasing dither pattern sequence to buffer
GameOver_WriteDitherSequence:                           ; was: sub_27840
                moveq   #7,d7
GameOver_WriteDitherSequence_InitialFillLoop:           ; was: loc_27842
                move.l  d4,(a0)+
                dbf     d7,GameOver_WriteDitherSequence_InitialFillLoop
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d1,(a0)+
                move.l  d1,(a0)+
                move.l  d2,(a0)+
                move.l  d2,(a0)+
                move.l  d3,(a0)+
                move.l  d3,(a0)+
                rts
; End of function GameOver_WriteDitherSequence
; Initializes the perspective row buffer with descending even values
GameOver_InitializeRowBuffer:                           ; was: sub_2785A
                                        ; GameOver_ResetLandscapeRows   j
                movea.w #(GameOverRowWorkBuffer-M68K_RAM),a0
                moveq   #$FFFFFFFF,d5
                move.w  #$6F,d7                         ; 'o'
GameOver_InitializeRowBuffer_Loop:                      ; was: loc_27864
                move.w  d5,(a0)+
                move.w  d5,(a0)+
                subq.w  #2,d5
                dbf     d7,GameOver_InitializeRowBuffer_Loop
                rts
; End of function GameOver_InitializeRowBuffer
; Builds row and coordinate buffers for the perspective landscape
GameOver_BuildPerspectiveBuffers:                       ; was: sub_27870
                                        ; GameOver_UpdateAutoLandscape:GameOver_UpdateAutoLandscape_Render   j
                tst.w   (GameOverLandscapeDepth).w
                beq.w   GameOver_BuildPerspectiveBuffers_Return
                move.l  #$8000,d4
                divu.w  (GameOverLandscapeDepth).w,d4
                subi.w  #$A0,d4
                moveq   #0,d0
                move.w  (GameOverLandscapeAngle).w,d0
                ext.l   d0
                addi.l  #GameOver_PerspectiveLookupTable,d0
                movea.l d0,a0
                movea.w #(GameOverRowWorkBuffer-M68K_RAM),a1
                movea.w #(GameOverRasterBuffer-M68K_RAM),a2
                move.w  d4,d1
                asl.w   #3,d1
                moveq   #0,d0
                move.w  (GameOverViewOffset).w,d0
                asl.w   #3,d0
                add.w   d1,d0
                swap    d0
                moveq   #0,d1
                move.w  (GameOverLandscapeDepth).w,d1
                swap    d1
                asr.l   #5,d1
                moveq   #$FFFFFFFF,d5
                move.w  (GameOverLandscapeDepth).w,d6
                move.w  #$6F,d7                         ; 'o'
GameOver_BuildPerspectiveBuffers_ProjectRowLoop:        ; was: loc_278C2
                                        ; GameOver_BuildPerspectiveBuffers+B2   j
                move.l  d0,d2
                bmi.s   GameOver_BuildPerspectiveBuffers_StoreClippedRow
                swap    d2
                cmpi.w  #$400,d2
                bpl.s   GameOver_BuildPerspectiveBuffers_FillRemainingRows
                andi.w  #$3F8,d2
                moveq   #0,d3
                move.w  (a0,d2.w),d3
                divu.w  d6,d3
                add.w   d5,d3
                move.w  d3,(a1)+
                moveq   #0,d3
                move.w  4(a0,d2.w),d3
                divu.w  d6,d3
                add.w   d5,d3
                move.w  d3,(a1)+
                moveq   #0,d3
                move.w  2(a0,d2.w),d3
                divu.w  d6,d3
                sub.w   d4,d3
                move.w  d3,(a2)
                move.w  d3,4(a2)
                moveq   #0,d3
                move.w  6(a0,d2.w),d3
                divu.w  d6,d3
                sub.w   d4,d3
                move.w  d3,2(a2)
                move.w  d3,6(a2)
                subq.w  #2,d5
                addq.w  #8,a2
                add.l   d1,d0
                dbf     d7,GameOver_BuildPerspectiveBuffers_ProjectRowLoop
GameOver_BuildPerspectiveBuffers_Return:                ; was: locret_27916
                rts
; ---------------------------------------------------------------------------
GameOver_BuildPerspectiveBuffers_StoreClippedRow:       ; was: loc_27918
                move.w  d5,(a1)+
                move.w  d5,(a1)+
                subq.w  #2,d5
                addq.w  #8,a2
                add.l   d1,d0
                dbf     d7,GameOver_BuildPerspectiveBuffers_ProjectRowLoop
                rts
; ---------------------------------------------------------------------------
GameOver_BuildPerspectiveBuffers_FillRemainingRows:     ; was: loc_27928
                                        ; GameOver_BuildPerspectiveBuffers+BE   j
                move.w  d5,(a1)+
                move.w  d5,(a1)+
                subq.w  #2,d5
                dbf     d7,GameOver_BuildPerspectiveBuffers_FillRemainingRows
                rts
; End of function GameOver_BuildPerspectiveBuffers
