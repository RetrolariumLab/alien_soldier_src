; Dispatch the Stage 24 scene object through its eight-state sequence
Stage24SceneObject_DispatchState:                       ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_549E2
                move.w  4(a5),d0
                movea.w Stage24SceneObject_StateOffsets(pc,d0.w),a0
                adda.l  #Entity_SevenForceNoOpState,a0
                jmp     (a0)
; End of function Stage24SceneObject_DispatchState
; ---------------------------------------------------------------------------
Stage24SceneObject_StateOffsets:    dc.w    Stage24SceneObject_Initialize-Entity_SevenForceNoOpState  ; was: off_549F2
                                        ; DATA XREF: Stage24SceneObject_DispatchState+4   r
                dc.w    Stage24SceneObject_MoveToY120-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_DecelerateTowardY140-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_GrowTileAnimation-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_HoldExpandedFrame-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_MoveLeftToX150-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_ShrinkTilesAndLaunchCompanion-Entity_SevenForceNoOpState
                dc.w    Stage24SceneObject_SignalSequenceCompletion-Entity_SevenForceNoOpState

Entity_SevenForceNoOpState:                             ; CODE XREF: Stage24SceneObject_HoldExpandedFrame+4   j  ; was: nullsub_126
                                        ; Stage24SceneObject_MoveLeftToX150+A   j
                rts
; End of function Entity_SevenForceNoOpState

; Initializes the Stage 24 scene object with downward motion and composite sprite data
Stage24SceneObject_Initialize:                          ; DATA XREF: ROM:Stage24SceneObject_StateOffsets   o  ; was: sub_54A04
                addq.w  #2,4(a5)
                move.w  #$ED00,2(a5)
                move.w  #$2B00,$E(a5)
                move.b  #$14,$20(a5)
                move.l  #$10000,$1C(a5)
                move.l  #Stage24SceneObject_CompositeSpriteFrame,8(a5)
                clr.w   $C(a5)
                rts
; End of function Stage24SceneObject_Initialize
; Moves the scene object toward Y=$120 and keeps its companion at X+$0B, Y+$10
Stage24SceneObject_MoveToY120:                          ; DATA XREF: ROM:000549F4   o  ; was: sub_54A30
                cmpi.w  #$120,$14(a5)
                bmi.s   Stage24SceneObject_SyncCompanionPosition
                addq.w  #2,4(a5)
Stage24SceneObject_SyncCompanionPosition:               ; CODE XREF: Stage24SceneObject_MoveToY120+6   j  ; was: loc_54A3C
                                        ; Stage24SceneObject_DecelerateTowardY140:Stage24SceneObject_ContinueCompanionSync   j
                movea.w #(Entity58Type-M68K_RAM),a0
                move.w  $14(a5),d0
                addi.w  #$10,d0
                move.w  d0,$14(a0)
                move.w  $10(a5),d0
                addi.w  #$B,d0
                move.w  d0,$10(a0)
                rts
; End of function Stage24SceneObject_MoveToY120
; Decelerates the scene object until reaching Y=$140, then snaps it to Y=$130
Stage24SceneObject_DecelerateTowardY140:                ; DATA XREF: ROM:000549F6   o  ; was: sub_54A5A
                subi.l  #$200,$1C(a5)
                cmpi.w  #$140,$14(a5)
                bmi.s   Stage24SceneObject_ContinueCompanionSync
                addq.w  #2,4(a5)
                move.w  #$130,$14(a5)
                clr.l   $1C(a5)
                move.w  #4,$48(a5)
Stage24SceneObject_ContinueCompanionSync:               ; CODE XREF: Stage24SceneObject_DecelerateTowardY140+E   j  ; was: loc_54A7E
                bra.s   Stage24SceneObject_SyncCompanionPosition
; End of function Stage24SceneObject_DecelerateTowardY140
; Expands the scene object's streamed tile frame every fourth update
Stage24SceneObject_GrowTileAnimation:                   ; DATA XREF: ROM:000549F8   o  ; was: sub_54A80
                move.w  #$150,(Entity58YPos).w
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Stage24SceneObject_TransferGrowthFrame
                addq.w  #4,$48(a5)
                cmpi.w  #$10,$48(a5)
                bmi.s   Stage24SceneObject_TransferGrowthFrame
                addq.w  #2,4(a5)
                move.w  #$28,$4A(a5)                    ; '('
Stage24SceneObject_TransferGrowthFrame:                 ; CODE XREF: Stage24SceneObject_GrowTileAnimation+E   j  ; was: loc_54AA6
                                        ; Stage24SceneObject_GrowTileAnimation+1A   j
                bra.w   Stage24SceneObject_TransferAnimationTiles
; End of function Stage24SceneObject_GrowTileAnimation
; Holds the fully expanded frame before selecting the sprite animation
Stage24SceneObject_HoldExpandedFrame:                   ; DATA XREF: ROM:000549FA   o  ; was: sub_54AAA
                subq.w  #1,$4A(a5)
                bpl.w   Entity_SevenForceNoOpState
                addq.w  #2,4(a5)
                move.l  #Stage24SceneObject_SpriteAnimation,8(a5)
                clr.w   $C(a5)
                rts
; End of function Stage24SceneObject_HoldExpandedFrame
; Accelerates the scene object leftward until it crosses X=$150
Stage24SceneObject_MoveLeftToX150:                      ; DATA XREF: ROM:000549FC   o  ; was: sub_54AC4
                bsr.w   Stage24SceneObject_AccelerateLeft
                cmpi.w  #$150,$10(a5)
                bpl.w   Entity_SevenForceNoOpState
                addq.w  #2,4(a5)
                rts
; End of function Stage24SceneObject_MoveLeftToX150
; Shrinks the streamed tile frame, then launches the companion upward
Stage24SceneObject_ShrinkTilesAndLaunchCompanion:       ; DATA XREF: ROM:000549FE   o  ; was: sub_54AD8
                bsr.w   Stage24SceneObject_AccelerateLeft
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Stage24SceneObject_TransferShrinkFrame
                subq.w  #4,$48(a5)
                bne.s   Stage24SceneObject_TransferShrinkFrame
                addq.w  #2,4(a5)
                movea.w #(Entity58Type-M68K_RAM),a0
                move.l  #$FFFE8000,$1C(a0)
                bset    #1,2(a0)
Stage24SceneObject_TransferShrinkFrame:                 ; CODE XREF: Stage24SceneObject_ShrinkTilesAndLaunchCompanion+C   j  ; was: loc_54B02
                                        ; Stage24SceneObject_ShrinkTilesAndLaunchCompanion+12   j
                bra.w   Stage24SceneObject_TransferAnimationTiles
; End of function Stage24SceneObject_ShrinkTilesAndLaunchCompanion
; Stops the scene object, restores its composite frame, and signals completion
Stage24SceneObject_SignalSequenceCompletion:            ; DATA XREF: ROM:00054A00   o  ; was: sub_54B06
                clr.l   $18(a5)
                move.l  #Stage24SceneObject_CompositeSpriteFrame,8(a5)
                clr.w   $C(a5)
                move.b  #1,(SceneSequenceFlags).w
                rts
; End of function Stage24SceneObject_SignalSequenceCompletion
; Subtract from horizontal velocity until its integer part is below -1
Stage24SceneObject_AccelerateLeft:                      ; CODE XREF: Stage24SceneObject_MoveLeftToX150   p  ; was: sub_54B1E
                                        ; Stage24SceneObject_ShrinkTilesAndLaunchCompanion   p
                cmpi.w  #$FFFF,$18(a5)
                bmi.s   Stage24SceneObject_AccelerateLeftReturn
                subi.l  #$C00,$18(a5)
Stage24SceneObject_AccelerateLeftReturn:                ; CODE XREF: Stage24SceneObject_AccelerateLeft+6   j  ; was: locret_54B2E
                rts
; End of function Stage24SceneObject_AccelerateLeft
; Select the current frame descriptor and transfer its tiles by DMA
Stage24SceneObject_TransferAnimationTiles:              ; CODE XREF: Stage24SceneObject_GrowTileAnimation:Stage24SceneObject_TransferGrowthFrame   j  ; was: sub_54B30
                                        ; Stage24SceneObject_ShrinkTilesAndLaunchCompanion:Stage24SceneObject_TransferShrinkFrame   j
                move.w  $48(a5),d0
                movea.l Stage24SceneObject_TileTransferDescriptors(pc,d0.w),a0
                jmp     Tilemap_QueueIndexedColumns
; End of function Stage24SceneObject_TransferAnimationTiles
; ---------------------------------------------------------------------------
Stage24SceneObject_TileTransferDescriptors: dc.l    Stage24SceneObject_TileTransferFrame0  ; DATA XREF: Stage24SceneObject_TransferAnimationTiles+4   r  ; was: off_54B3E
                dc.l    Stage24SceneObject_TileTransferFrame1
                dc.l    Stage24SceneObject_TileTransferFrame2
                dc.l    Stage24SceneObject_TileTransferFrame3
                dc.l    Stage24SceneObject_TileTransferFrame4
Stage24SceneObject_TileTransferFrame0:  dc.b    $48, $F0, $40, 0, 0, 3, $65, $5A, $6E, $72  ; was: byte_54B52
                                        ; DATA XREF: ROM:Stage24SceneObject_TileTransferDescriptors   o
Stage24SceneObject_TileTransferFrame1:  dc.b    $48, $F0, $40, 0, 0, 3, $66, $6A, $6F, $73  ; was: byte_54B5C
                                        ; DATA XREF: ROM:00054B42   o
Stage24SceneObject_TileTransferFrame2:  dc.b    $48, $F0, $40, 0, 0, 3, $67, $6B, $70, $74  ; was: byte_54B66
                                        ; DATA XREF: ROM:00054B46   o
Stage24SceneObject_TileTransferFrame3:  dc.b    $48, $F0, $40, 0, 0, 3, $68, $6C, $71, $75  ; was: byte_54B70
                                        ; DATA XREF: ROM:00054B4A   o
Stage24SceneObject_TileTransferFrame4:  dc.b    $48, $F0, $40, 0, 0, 3, $69, $6D, $6D, $76  ; was: byte_54B7A
                                        ; DATA XREF: ROM:00054B4E   o
