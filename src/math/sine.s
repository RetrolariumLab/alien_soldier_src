; In: d0.w = even angle-table offset. Out: d0.w = cosine, d1.w = sine
Math_LookupSineCosinePair:                              ; was: sub_8618
                                        ; EndingPlanet_ApproachCenter+24   p
                lea     (Math_QuarterSineTable).l,a0
                move.w  (a0,d0.w),d1
                addi.w  #$80,d0
                andi.w  #$1FE,d0
                move.w  (a0,d0.w),d0
                rts
; End of function Math_LookupSineCosinePair
; ---------------------------------------------------------------------------
Sprite_SharedGraphicsFrameTable:    dc.w    $8000       ; field_0  ; was: stru_8630
                                        ; Sprite_SelectSharedGraphicsFrame+8   o
                dc.l    $F00F0F0                        ; field_2
                dc.w    $8010                           ; field_0
                dc.l    $F00F0F0                        ; field_2
                dc.w    $8020                           ; field_0
                dc.l    $F00F1F1                        ; field_2
                dc.w    $8030                           ; field_0
                dc.l    $F00F1F1                        ; field_2
                dc.w    $8040                           ; field_0
                dc.l    $F00F2F2                        ; field_2
                dc.w    $8050                           ; field_0
                dc.l    $F00F2F2                        ; field_2
                dc.w    $8060                           ; field_0
                dc.l    $F00F3F3                        ; field_2
                dc.w    $8070                           ; field_0
                dc.l    $F00F3F3                        ; field_2
                dc.w    $8080                           ; field_0
                dc.l    $A00F4F4                        ; field_2
                dc.w    $8089                           ; field_0
                dc.l    $A00F4F4                        ; field_2
                dc.w    $8092                           ; field_0
                dc.l    $A00F5F5                        ; field_2
                dc.w    $809B                           ; field_0
                dc.l    $A00F5F5                        ; field_2
                dc.w    $80A4                           ; field_0
                dc.l    $A00F6F6                        ; field_2
                dc.w    $80AD                           ; field_0
                dc.l    $A00F6F6                        ; field_2
                dc.w    $80B6                           ; field_0
                dc.l    $A00F7F7                        ; field_2
                dc.w    $80BF                           ; field_0
                dc.l    $A00F7F7                        ; field_2
                dc.w    $80C8                           ; field_0
                dc.l    $500F8F8                        ; field_2
                dc.w    $80CC                           ; field_0
                dc.l    $500F8F8                        ; field_2
                dc.w    $80D0                           ; field_0
                dc.l    $500F9F9                        ; field_2
                dc.w    $80D4                           ; field_0
                dc.l    $500F9F9                        ; field_2
                dc.w    $80D8                           ; field_0
                dc.l    $500FAFA                        ; field_2
                dc.w    $80DC                           ; field_0
                dc.l    $500FAFA                        ; field_2
                dc.w    $80E0                           ; field_0
                dc.l    $500FBFB                        ; field_2
                dc.w    $80E4                           ; field_0
                dc.l    $500FBFB                        ; field_2
                dc.w    $80E8                           ; field_0
                dc.l    $FCFC                           ; field_2
                dc.w    $80E9                           ; field_0
                dc.l    $FCFC                           ; field_2
                dc.w    $80EA                           ; field_0
                dc.l    $FDFD                           ; field_2
                dc.w    $80EB                           ; field_0
                dc.l    $FDFD                           ; field_2
                dc.w    $80EC                           ; field_0
                dc.l    $FEFE                           ; field_2
                dc.w    $80ED                           ; field_0
                dc.l    $FEFE                           ; field_2
                dc.w    $80EE                           ; field_0
                dc.l    $FFFF                           ; field_2
                dc.w    $80EF                           ; field_0
                dc.l    $FFFF                           ; field_2

; Dispatches ship cutscene object with palette update condition
