Entity_EmptyState3:                                     ; was: nullsub_3
                rts
; End of function Entity_EmptyState3
; ---------------------------------------------------------------------------
; 5,000 packed-BCD words for values 0-4,999, followed by 36 opaque bytes
; retained in the original preservation segment
Math_PackedBCDLookup:   binclude "data/other/word_5A43E.bin"  ; was: word_5A43E
Math_PackedBCDLookup_End:                               ; was: word_5A43E_End
                ; dc.b [$257B2]$FF
                org     $82324

; Attributes: thunk
; Thunk to main sound driver update
