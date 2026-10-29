UnreferencedToggleFrameTimingMarkers:
                move.b  (GameplayControlFlags).w,d0     ; was: sub_1CB32
                bpl.w   UnreferencedToggleFrameTimingMarkers_Return
                btst    #6,d0
                beq.w   UnreferencedToggleFrameTimingMarkers_Return
                move.b  (ControllerPressedState).w,d0
                or.b    (ControllerPressedState+1).w,d0
                btst    #5,d0
                beq.w   UnreferencedToggleFrameTimingMarkers_Return
                eori.b  #$80,(FrameTimingDebugFlag).w
UnreferencedToggleFrameTimingMarkers_Return:            ; was: locret_1CB58
                                        ; UnreferencedToggleFrameTimingMarkers+C   j
                rts
; End of function UnreferencedToggleFrameTimingMarkers
