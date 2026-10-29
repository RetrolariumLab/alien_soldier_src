; Unreferenced helper that restores the player's object type to $08
UnreferencedSetPlayerObjectType08:                      ; was: sub_106C6
                lea     (PlayerObjectType).w,a5
                move.w  #8,(a5)
                rts
; End of function UnreferencedSetPlayerObjectType08
; Unreferenced entry that queues a column from the secondary camera with a $180 X offset
UnreferencedQueueSecondaryCameraColumnOffset180:        ; was: sub_106D0
                move.w  (SecondaryCameraXPos).w,d0
                addi.w  #$180,d0
                move.w  (SecondaryCameraYPos).w,d1
                lea     Gfx_FrontendAlternateVRAMTransferParameters(pc),a0
                nop
                bra.s   Tilemap_QueueColumnFromDescriptor
; End of function UnreferencedQueueSecondaryCameraColumnOffset180
; Unreferenced entry that queues a column from the primary camera with a -$58 X offset
UnreferencedQueuePrimaryCameraColumnOffsetMinus58:      ; was: sub_106E4
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$58,d0                         ; 'X'
                move.w  (PrimaryCameraYPosition).w,d1
                bra.s   Tilemap_QueuePrimaryPlaneColumn
; End of function UnreferencedQueuePrimaryCameraColumnOffsetMinus58
; Queue a primary-plane column from the camera with a $158 X offset
Tilemap_QueuePrimaryCameraColumnOffset158:              ; was: sub_106F2
                                        ; Camera_UpdateAndRenderStageTilemap+4   j
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$158,d0
                move.w  (PrimaryCameraYPosition).w,d1
; End of function Tilemap_QueuePrimaryCameraColumnOffset158
; Select the primary-plane descriptor and queue one streamed tilemap column
Tilemap_QueuePrimaryPlaneColumn:                        ; was: sub_106FE
                                        ; Stage_SevenForceUpdateMedusaCameraAndParallax+46   p
                lea     Gfx_TitleAndZLeoVRAMTransferParameters(pc),a0
                nop
Tilemap_QueueColumnFromDescriptor:                      ; was: loc_10704
                                        ; Stage18_UpdateScrollAndRenderTilemap+1A   j
                neg.w   d1
                moveq   #8,d7
                move.w  d0,d2
                lsr.w   #8,d2
                move.w  d2,(TileCoarseLookupOffset).w
                move.w  d0,d2
                lsr.w   #5,d2
                andi.w  #7,d2
                move.w  d2,(TileFineLookupOffset).w
                move.w  d0,d2
                lsr.w   #2,d2
                andi.w  #6,d2
                move.w  d2,(TilePatternOffset).w
                moveq   #$FFFFFFFF,d2
                move.w  d0,d2
                lsr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.l  d2,(TilePlaneBufferOffset).w
Tilemap_BuildColumnRowLoop:                             ; was: loc_10736
                movea.l (a0)+,a1
                move.w  (TileCoarseLookupOffset).w,d2
                move.w  d1,d3
                lsr.w   #3,d3
                andi.w  #$3E0,d3
                add.w   d3,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #6,d4
                movea.l (a0)+,a1
                move.w  (TileFineLookupOffset).w,d2
                move.w  d1,d3
                lsr.w   #2,d3
                andi.w  #$38,d3                         ; '8'
                add.w   d3,d2
                add.w   d4,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #5,d4
                tst.w   d7
                bne.w   Tilemap_WriteFullColumnRow
                subi.w  #$100,d1
                move.w  d1,d2
                move.w  (VDPStagingDataCursor).w,d3
                lsr.w   #2,d2
                andi.w  #$38,d2                         ; '8'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  (TilePatternOffset).w,d3
                add.w   d4,d3
                move.w  d1,d2
                andi.w  #$18,d2
                move.w  d2,d5
                subq.w  #8,d2
                bmi.s   Tilemap_WritePartialColumnRow
                move.w  (a1,d3.w),(a2)+
                subq.w  #8,d2
                bmi.s   Tilemap_WritePartialColumnRow
                move.w  8(a1,d3.w),(a2)+
                subq.w  #8,d2
                bmi.s   Tilemap_WritePartialColumnRow
                move.w  $10(a1,d3.w),(a2)+
Tilemap_WritePartialColumnRow:                          ; was: loc_107AA
                                        ; Tilemap_QueuePrimaryPlaneColumn+9E   j
                tst.w   (a0)+
                beq.s   Tilemap_QueueColumnTransfer
                move.l  (TilePlaneBufferOffset).w,d2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1E00,d4
                add.w   d4,d2
                movea.l d2,a2
                subq.w  #8,d5
                bmi.s   Tilemap_QueueColumnTransfer
                move.w  (a1,d3.w),(a2)
                subq.w  #8,d5
                bmi.s   Tilemap_QueueColumnTransfer
                move.w  8(a1,d3.w),$80(a2)
                subq.w  #8,d5
                bmi.s   Tilemap_QueueColumnTransfer
                move.w  $10(a1,d3.w),$100(a2)
Tilemap_QueueColumnTransfer:                            ; was: loc_107DA
                                        ; Tilemap_QueuePrimaryPlaneColumn+C2   j
                move.w  d0,d2
                lsr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                add.w   (a0),d2
                move.w  d2,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F80977F,-(a1)
                move.l  #$94009320,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                addi.w  #$40,(VDPStagingDataCursor).w   ; '@'
                rts
; ---------------------------------------------------------------------------
Tilemap_WriteFullColumnRow:                             ; was: loc_1081E
                move.w  d1,d2
                move.w  (VDPStagingDataCursor).w,d3
                lsr.w   #2,d2
                andi.w  #$38,d2                         ; '8'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  (TilePatternOffset).w,d3
                add.w   d4,d3
                move.w  (a1,d3.w),(a2)+
                move.w  8(a1,d3.w),(a2)+
                move.w  $10(a1,d3.w),(a2)+
                move.w  $18(a1,d3.w),(a2)+
                tst.w   (a0)+
                beq.w   Tilemap_AdvanceColumnRow
                move.l  (TilePlaneBufferOffset).w,d2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1E00,d4
                add.w   d4,d2
                movea.l d2,a2
                move.w  (a1,d3.w),(a2)
                move.w  8(a1,d3.w),$80(a2)
                move.w  $10(a1,d3.w),$100(a2)
                move.w  $18(a1,d3.w),$180(a2)
Tilemap_AdvanceColumnRow:                               ; was: loc_10872
                suba.l  #$E,a0
                addi.w  #$20,d1                         ; ' '
                dbf     d7,Tilemap_BuildColumnRowLoop
                rts
; End of function Tilemap_QueuePrimaryPlaneColumn
; Unreferenced entry that populates an unqueued column at vertical offset -$1000
UnreferencedPopulateUnqueuedColumnOffset1000:           ; was: sub_10882
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$58,d0                         ; 'X'
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$1000,d1
                bra.s   Tilemap_PopulateUnqueuedColumnFromDescriptor
; End of function UnreferencedPopulateUnqueuedColumnOffset1000
; Populate Stage 18 column rows without adding a second DMA command
Tilemap_PopulateStage18UnqueuedColumn:                  ; was: sub_10894
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$158,d0
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$1000,d1
Tilemap_PopulateUnqueuedColumnFromDescriptor:           ; was: loc_108A4
                                        ; UnreferencedPopulateUnqueuedColumnOffset1000+10   j
                lea     Gfx_DefaultVRAMTransferParameters(pc),a0
                nop
                neg.w   d1
                moveq   #8,d7
                move.w  d0,d2
                lsr.w   #8,d2
                move.w  d2,(TileCoarseLookupOffset).w
                move.w  d0,d2
                lsr.w   #5,d2
                andi.w  #7,d2
                move.w  d2,(TileFineLookupOffset).w
                move.w  d0,d2
                lsr.w   #2,d2
                andi.w  #6,d2
                move.w  d2,(TilePatternOffset).w
                moveq   #$FFFFFFFF,d2
                move.w  d0,d2
                lsr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.l  d2,(TilePlaneBufferOffset).w
Tilemap_BuildUnqueuedColumnRowLoop:                     ; was: loc_108DC
                movea.l (a0)+,a1
                move.w  (TileCoarseLookupOffset).w,d2
                move.w  d1,d3
                lsr.w   #3,d3
                andi.w  #$3E0,d3
                add.w   d3,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #6,d4
                movea.l (a0)+,a1
                move.w  (TileFineLookupOffset).w,d2
                move.w  d1,d3
                lsr.w   #2,d3
                andi.w  #$38,d3                         ; '8'
                add.w   d3,d2
                add.w   d4,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #5,d4
                tst.w   d7
                bne.w   Tilemap_WriteFullUnqueuedColumnRow
                subi.w  #$100,d1
                move.w  d1,d2
                move.w  (VDPStagingDataCursor).w,d3
                lsr.w   #2,d2
                andi.w  #$38,d2                         ; '8'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  (TilePatternOffset).w,d3
                add.w   d4,d3
                move.w  d1,d2
                andi.w  #$18,d2
                move.w  d2,d5
                tst.w   (a0)+
                move.l  (TilePlaneBufferOffset).w,d2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1E00,d4
                add.w   d4,d2
                movea.l d2,a2
                subq.w  #8,d5
                bmi.s   Tilemap_UnqueuedPartialRowReturn
                move.w  (a1,d3.w),(a2)
                subq.w  #8,d5
                bmi.s   Tilemap_UnqueuedPartialRowReturn
                move.w  8(a1,d3.w),$80(a2)
                subq.w  #8,d5
                bmi.s   Tilemap_UnqueuedPartialRowReturn
                move.w  $10(a1,d3.w),$100(a2)
Tilemap_UnqueuedPartialRowReturn:                       ; was: locret_10966
                                        ; Tilemap_PopulateStage18UnqueuedColumn+C0   j
                rts
; ---------------------------------------------------------------------------
Tilemap_WriteFullUnqueuedColumnRow:                     ; was: loc_10968
                movea.l (a0)+,a1
                move.w  (TilePatternOffset).w,d3
                add.w   d4,d3
                tst.w   (a0)+
                move.l  (TilePlaneBufferOffset).w,d2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1E00,d4
                add.w   d4,d2
                movea.l d2,a2
                move.w  (a1,d3.w),(a2)
                move.w  8(a1,d3.w),$80(a2)
                move.w  $10(a1,d3.w),$100(a2)
                move.w  $18(a1,d3.w),$180(a2)
                suba.l  #$E,a0
                addi.w  #$20,d1                         ; ' '
                dbf     d7,Tilemap_BuildUnqueuedColumnRowLoop
                rts
; End of function Tilemap_PopulateStage18UnqueuedColumn
