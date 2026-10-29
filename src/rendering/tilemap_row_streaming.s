; Unreferenced wrapper that queues a row from the secondary camera, offset left by $60
UnreferencedTilemapQueueSecondaryCameraRowOffset60:
                move.w  (SecondaryCameraXPos).w,d0      ; was: sub_109A8
                subi.w  #$60,d0                         ; '`'
                move.w  (SecondaryCameraYPos).w,d1
                lea     Gfx_FrontendAlternateVRAMTransferParameters(pc),a0
                nop
                bra.s   Tilemap_QueueRowFromDescriptor
; End of function UnreferencedTilemapQueueSecondaryCameraRowOffset60
; Unreferenced wrapper that queues a primary-camera row with $60/$F8 offsets
UnreferencedTilemapQueuePrimaryCameraRowOffset60F8:
                move.w  (PrimaryCameraXPosition).w,d0   ; was: sub_109BC
                subi.w  #$60,d0                         ; '`'
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$F8,d1
                bra.s   Tilemap_SelectPrimaryRowDescriptor
; End of function UnreferencedTilemapQueuePrimaryCameraRowOffset60F8
; Queues one tilemap row from the primary camera, offset left by $60
Tilemap_QueuePrimaryCameraRowOffset60:                  ; CODE XREF: Stage16_StartPostViblackTransition+24   p  ; was: sub_109CE
                                        ; Scroll_UpdateAndRenderSylpheedBackdrop+4   j
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$60,d0                         ; '`'
                move.w  (PrimaryCameraYPosition).w,d1
Tilemap_SelectPrimaryRowDescriptor:                     ; CODE XREF: UnreferencedTilemapQueuePrimaryCameraRowOffset60F8+10   j  ; was: loc_109DA
                lea     Gfx_TitleAndZLeoVRAMTransferParameters(pc),a0
                nop
Tilemap_QueueRowFromDescriptor:                         ; CODE XREF: Stage_SevenForceUpdateSylpheedPrimaryPlane+4A   j  ; was: loc_109E0
                                        ; Stage_SevenForceUpdateSylpheedSecondaryPlane+20   j
                neg.w   d1
                moveq   #$F,d7
                move.w  d1,d2
                lsr.w   #3,d2
                andi.w  #$3E0,d2
                move.w  d2,(TileCoarseLookupOffset).w
                move.w  d1,d2
                lsr.w   #2,d2
                andi.w  #$38,d2                         ; '8'
                move.w  d2,(TileFineLookupOffset).w
                move.w  d1,d2
                andi.w  #$18,d2
                move.w  d2,(TilePatternOffset).w
                moveq   #$FFFFFFFF,d2
                move.w  d1,d2
                lsl.w   #4,d2
                andi.w  #$1F80,d2
                move.l  d2,(TilePlaneBufferOffset).w
Tilemap_BuildQueuedRowLoop:                             ; CODE XREF: Tilemap_QueuePrimaryCameraRowOffset60+C4   j  ; was: loc_10A14
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  (TileCoarseLookupOffset).w,d3
                lsr.w   #8,d2
                add.w   d3,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #6,d4
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  (TileFineLookupOffset).w,d3
                lsr.w   #5,d2
                andi.w  #7,d2
                add.w   d3,d2
                add.w   d4,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #5,d4
                move.w  d0,d2
                move.w  (VDPStagingDataCursor).w,d3
                lsr.w   #2,d2
                andi.w  #$78,d2                         ; 'x'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  (TilePatternOffset).w,d3
                add.w   d4,d3
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
                tst.w   (a0)+
                beq.w   Tilemap_AdvanceQueuedRowSegment
                move.l  (TilePlaneBufferOffset).w,d4
                add.w   d4,d2
                movea.l d2,a2
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
Tilemap_AdvanceQueuedRowSegment:                        ; CODE XREF: Tilemap_QueuePrimaryCameraRowOffset60+9E   j  ; was: loc_10A88
                suba.l  #$E,a0
                addi.w  #$20,d0                         ; ' '
                dbf     d7,Tilemap_BuildQueuedRowLoop
                move.w  d1,d2
                lsl.w   #4,d2
                andi.w  #$F80,d2
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                add.w   $E(a0),d2
                move.w  d2,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009340,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                addi.w  #$80,(VDPStagingDataCursor).w
                rts
; End of function Tilemap_QueuePrimaryCameraRowOffset60
; Starts a full direct tilemap transfer at the secondary-camera coordinates
Tilemap_DirectTransferFromSecondaryCamera:              ; CODE XREF: XiTigerCutscene_InitializeReveal+72   j  ; was: sub_10ADC
                move.w  (SecondaryCameraXPos).w,d0
                move.w  (SecondaryCameraYPos).w,d1
; End of function Tilemap_DirectTransferFromSecondaryCamera
; Starts a full direct tilemap transfer with the alternate frontend descriptor
Tilemap_DirectTransferWithAlternateDescriptor:          ; CODE XREF: Frontend_ActivateSegaSequence+18   p  ; was: sub_10AE4
                lea     Gfx_FrontendAlternateVRAMTransferParameters(pc),a0
                nop
                bra.s   Tilemap_TransferFullMapDirectToVRAM
; End of function Tilemap_DirectTransferWithAlternateDescriptor
; Starts a full direct tilemap transfer at the primary-camera coordinates
Tilemap_DirectTransferFromPrimaryCamera:                ; CODE XREF: XiTigerCutscene_InitializeReveal+66   p  ; was: sub_10AEC
                                        ; ZLeoEnding_InitializeScene+3C   p
                move.w  (PrimaryCameraXPosition).w,d0
                move.w  (PrimaryCameraYPosition).w,d1
; End of function Tilemap_DirectTransferFromPrimaryCamera
; Starts a full direct tilemap transfer with the primary descriptor
Tilemap_DirectTransferWithPrimaryDescriptor:            ; CODE XREF: UI_InitSecondaryOptionsMenu+50   p  ; was: sub_10AF4
                                        ; PasswordMenu_Initialize+5A   p
                lea     Gfx_TitleAndZLeoVRAMTransferParameters(pc),a0
                nop
; End of function Tilemap_DirectTransferWithPrimaryDescriptor
; Transfers all 32 tilemap rows directly to VRAM while holding the Z80 bus
Tilemap_TransferFullMapDirectToVRAM:                    ; CODE XREF: EndingSequence_Initialize+58   p  ; was: sub_10AFA
                                        ; TitleScreen_Initialize+90   p
                move    sr,-(sp)
                move    #$2700,sr
Tilemap_WaitForZ80BusRequest:                           ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+E   j  ; was: loc_10B00
                bset    #0,(IO_Z80BUS).l
                bne.s   Tilemap_WaitForZ80BusRequest
                lea     (VDP_CTRL).l,a4
                move.w  (VDPReg1Shadow).w,d2
                bset    #4,d2
                move.w  d2,(a4)
                neg.w   d1
                moveq   #$1F,d6
Tilemap_DirectTransferRowLoop:                          ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+102   j  ; was: loc_10B1E
                moveq   #$F,d7
Tilemap_BuildDirectTransferRowLoop:                     ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+C4   j  ; was: loc_10B20
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  d1,d3
                lsr.w   #8,d2
                lsr.w   #3,d3
                andi.w  #$3E0,d3
                add.w   d3,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                move.w  d4,d5
                lsl.w   #6,d4
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  d1,d3
                lsr.w   #5,d2
                lsr.w   #2,d3
                andi.w  #7,d2
                andi.w  #$38,d3                         ; '8'
                add.w   d3,d2
                add.w   d4,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #5,d4
                move.w  d0,d2
                move.l  #$FFFFA980,d3
                lsr.w   #2,d2
                andi.w  #$78,d2                         ; 'x'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  d1,d3
                andi.w  #$18,d3
                add.w   d4,d3
                cmpi.w  #$FF,d5
                bne.s   Tilemap_WriteDirectTransferRowSegment
                moveq   #0,d3
Tilemap_WriteDirectTransferRowSegment:                  ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+7E   j  ; was: loc_10B7C
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
                tst.w   (a0)+
                beq.w   Tilemap_AdvanceDirectTransferRowSegment
                movea.l #M68K_RAM,a2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1F80,d4
                add.w   d4,d2
                adda.w  d2,a2
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
Tilemap_AdvanceDirectTransferRowSegment:                ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+94   j  ; was: loc_10BB4
                suba.l  #$E,a0
                addi.w  #$20,d0                         ; ' '
                dbf     d7,Tilemap_BuildDirectTransferRowLoop
                move.w  d1,d2
                lsl.w   #4,d2
                andi.w  #$F80,d2
                move.w  #$8F02,(a4)
                move.l  #$93409400,(a4)
                move.w  #$95C0,(a4)
                move.w  #$96D4,(a4)
                move.w  #$977F,(a4)
                add.w   $E(a0),d2
                move.w  d2,(VDPCommand+2).w
                move.w  #$83,(VDPCommand).w
                move.w  (VDPCommand+2).w,(a4)
                move.w  (VDPCommand).w,(a4)
                subi.w  #$200,d0
                addq.w  #8,d1
                dbf     d6,Tilemap_DirectTransferRowLoop
                move.w  (VDPReg1Shadow).w,d0
                bclr    #4,d0
                move.w  d0,(a4)
Tilemap_WaitForZ80BusRelease:                           ; CODE XREF: Tilemap_TransferFullMapDirectToVRAM+118   j  ; was: loc_10C0A
                bclr    #0,(IO_Z80BUS).l
                beq.s   Tilemap_WaitForZ80BusRelease
                move    (sp)+,sr
                rts
; End of function Tilemap_TransferFullMapDirectToVRAM
; Builds and queues the next row of a staged scrolling tilemap transfer
Tilemap_QueueNextScrollingRow:                          ; CODE XREF: StoryScreen_WaitForScrollAndLoadPalette+16   p  ; was: sub_10C18
                                        ; StoryScreen_WaitForScrollAndLoadPalette+1C   p
                movea.l (TilemapTransferBase).w,a0
                move.w  (TilemapRowXOrFillWord).w,d0
                move.w  (TilemapRowYPosition).w,d1
                neg.w   d1
                moveq   #$F,d7
Tilemap_BuildScrollingRowLoop:                          ; CODE XREF: Tilemap_QueueNextScrollingRow+AC   j  ; was: loc_10C28
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  d1,d3
                lsr.w   #8,d2
                lsr.w   #3,d3
                andi.w  #$3E0,d3
                add.w   d3,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                move.w  d4,d5
                lsl.w   #6,d4
                movea.l (a0)+,a1
                move.w  d0,d2
                move.w  d1,d3
                lsr.w   #5,d2
                lsr.w   #2,d3
                andi.w  #7,d2
                andi.w  #$38,d3                         ; '8'
                add.w   d3,d2
                add.w   d4,d2
                moveq   #0,d4
                move.b  (a1,d2.w),d4
                lsl.w   #5,d4
                move.w  d0,d2
                move.w  (VDPStagingDataCursor).w,d3
                lsr.w   #2,d2
                andi.w  #$78,d2                         ; 'x'
                add.w   d2,d3
                movea.w d3,a2
                movea.l (a0)+,a1
                move.w  d1,d3
                andi.w  #$18,d3
                add.w   d4,d3
                cmpi.w  #$FF,d5
                bne.s   Tilemap_WriteScrollingRowSegment
                moveq   #0,d3
Tilemap_WriteScrollingRowSegment:                       ; CODE XREF: Tilemap_QueueNextScrollingRow+66   j  ; was: loc_10C82
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
                tst.w   (a0)+
                beq.w   Tilemap_AdvanceScrollingRowSegment
                movea.l #M68K_RAM,a2
                move.w  d1,d4
                lsl.w   #4,d4
                andi.w  #$1F80,d4
                add.w   d4,d2
                adda.w  d2,a2
                move.w  (a1,d3.w),(a2)+
                move.w  2(a1,d3.w),(a2)+
                move.w  4(a1,d3.w),(a2)+
                move.w  6(a1,d3.w),(a2)+
Tilemap_AdvanceScrollingRowSegment:                     ; CODE XREF: Tilemap_QueueNextScrollingRow+7C   j  ; was: loc_10CBA
                suba.l  #$E,a0
                addi.w  #$20,d0                         ; ' '
                dbf     d7,Tilemap_BuildScrollingRowLoop
                move.w  d1,d2
                lsl.w   #4,d2
                andi.w  #$F80,d2
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                add.w   $E(a0),d2
                move.w  d2,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009340,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                addi.w  #$80,(VDPStagingDataCursor).w
                subq.w  #8,(TilemapRowYPosition).w
                subq.w  #1,(TilemapRowCountdown).w
                rts
; End of function Tilemap_QueueNextScrollingRow
