; Unresolved ROM-neighboring handlers preserved at 0x02FC26-0x02FCF5
; The dispatch entry has no known constructor and was not reached in the pinned TAS
; The following terrain-animation companion has no live code or data reference

; Unresolved entity dispatcher. Its first table target is not a code entry;
; the other two target Stage 15 fragment-emitter states
OrphanedCrossStageEntityDispatch:                       ; was: sub_2FC26
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bpl.s   OrphanedCrossStageEntitySelectState
                move.w  #4,4(a5)
OrphanedCrossStageEntitySelectState:
                nop
                move.w  4(a5),d0
                movea.w OrphanedCrossStageEntityStateTable(pc,d0.w),a0  ; signed offset from the initializer base
                adda.l  #OrphanedTerrainTileAnimationInit,a0
                jmp     (a0)
; End of function OrphanedCrossStageEntityDispatch
; ---------------------------------------------------------------------------
OrphanedCrossStageEntityStateTable: dc.w    Stage18_SegmentedWormUpdateFollower+2-OrphanedTerrainTileAnimationInit
                                        ; target $0304B2 is the displacement word of a bsr.w, not an entry
                dc.w    Stage15_FragmentEmitterWaveSpawn-OrphanedTerrainTileAnimationInit
                dc.w    Stage15_FragmentEmitterWaveCheckThreshold-OrphanedTerrainTileAnimationInit

; Orphaned companion initializer for the terrain-tile animation descriptor
OrphanedTerrainTileAnimationInit:                       ; was: sub_2FC4C
                                        ; ROM:OrphanedCrossStageEntityStateTable   o
                addq.w  #2,4(a5)
                move.w  #$100,2(a5)
                ori.w   #$8000,2(a5)
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   OrphanedTerrainTileUseAlternateTile
                move.w  #$C4AC,$E(a5)
                bra.s   OrphanedTerrainTileStoreDescriptor
; ---------------------------------------------------------------------------
OrphanedTerrainTileUseAlternateTile:
                move.w  #$C4B4,$E(a5)
OrphanedTerrainTileStoreDescriptor:
                move.w  #$20,$4A(a5)                    ; ' '
                move.w  #5,$4E(a5)
                move.w  $5E(a5),d0
                move.w  OrphanedTerrainLayoutBases(pc,d0.w),$50(a5)
                move.w  #$4000,$52(a5)
                move.b  #0,$54(a5)
                move.b  #1,$55(a5)
                rts
; End of function OrphanedTerrainTileAnimationInit
; ---------------------------------------------------------------------------
OrphanedTerrainLayoutBases: dc.w    $42E5, $4291, $42B5, $42E1, $4285, $42B1, $42D5, $4281

OrphanedTerrainTileAnimationReturn:
                rts
; End of function OrphanedTerrainTileAnimationReturn

; Orphaned reveal state for the terrain-tile animation companion
OrphanedTerrainTileAnimationReveal:
                tst.w   $48(a5)                         ; was: sub_2FCBA
                bne.s   OrphanedTerrainTileAnimationReturn
                bset    #4,2(a5)
                clr.w   $4C(a5)
                bra.w   TerrainTileAnimation_TransferOnSelectedFramePhase
; End of function OrphanedTerrainTileAnimationReveal
; Orphaned DMA state for the terrain-tile animation companion
OrphanedTerrainTileAnimationTransfer:
                tst.w   $48(a5)                         ; was: sub_2FCCE
                bne.w   TerrainTileAnimation_Return
                move.w  $4C(a5),d0
                move.w  OrphanedTerrainTilePatterns(pc,d0.w),$56(a5)
                movea.w a5,a0
                adda.w  #$50,a0                         ; 'P'
                jmp     Tilemap_QueueIndexedColumns
; End of function OrphanedTerrainTileAnimationTransfer
; ---------------------------------------------------------------------------
OrphanedTerrainTilePatterns:    dc.w    $878C, $888D, $898E, $8A8F, $8B90
