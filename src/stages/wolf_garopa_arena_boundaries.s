; Initializes the two Wolf Garopa arena-boundary records
StageTransition_InitializeWolfGaropaArenaBoundaries:    ; was: sub_FEA0
                                        ; StageTransition_RestartWolfGaropaBackdropFinalize+E   p
                movea.w #(Entity58Type-M68K_RAM),a0
                clr.w   $48(a0)
                move.w  #$D0,$10(a0)
                bsr.s   StageTransition_InitializeWolfGaropaArenaBoundary
                movea.w #(Entity59Type-M68K_RAM),a0
                move.w  #1,$48(a0)
                move.w  #$170,$10(a0)
; End of function StageTransition_InitializeWolfGaropaArenaBoundaries
; Initializes one Wolf Garopa arena-boundary record
StageTransition_InitializeWolfGaropaArenaBoundary:      ; was: sub_FEC0
                move.w  #$41C,(a0)
                clr.w   2(a0)
                move.b  #$80,$21(a0)
                move.b  #$10,$23(a0)
                move.l  #$40827E,$28(a0)
                rts
; End of function StageTransition_InitializeWolfGaropaArenaBoundary
; Updates one Wolf Garopa arena-boundary record
Stage23_UpdateWolfGaropaArenaBoundary:                  ; was: sub_FEDE
                move.b  #$80,$21(a5)
                move.w  #$F3E0,d0
                sub.w   (PrimaryCameraYPosition).w,d0
                move.w  #$150,d1
                sub.w   d0,d1
                move.w  d1,$14(a5)
                tst.w   $48(a5)
                bne.s   Stage23_WolfGaropaArenaBoundaryReturn
                subi.w  #$20,d1                         ; ' '
                cmp.w   (PlayerYPosition).w,d1
                bpl.s   Stage23_WolfGaropaArenaBoundaryReturn
                move.w  d1,(PlayerYPosition).w
                subq.w  #1,(PlayerYPosition).w
Stage23_WolfGaropaArenaBoundaryReturn:                  ; was: locret_FF0E
                                        ; Stage23_UpdateWolfGaropaArenaBoundary+26   j
                rts
; End of function Stage23_UpdateWolfGaropaArenaBoundary
; Clears scroll animation timer at FFA960
