; Clears 17 consecutive 96-byte object blocks from the shared effect pool
Sys_ClearObjectBlocks17:                                ; was: sub_19244
                                        ; Player_InitKnockbackState+12   p
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #$10,d7
                bra.s   Sys_ClearObjectBlocks96
; End of function Sys_ClearObjectBlocks17
; Clears 16 consecutive 96-byte object blocks from the shared effect pool
Sys_ClearObjectBlocks16:                                ; was: sub_1924C
                                        ; Player_StartAirCounterForce+A   p
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #$F,d7
                bra.s   Sys_ClearObjectBlocks96
; End of function Sys_ClearObjectBlocks16
; Clears eight consecutive 96-byte object blocks from the shared effect pool
Sys_ClearObjectBlocks8:
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0  ; was: sub_19254
                moveq   #7,d7
; End of function Sys_ClearObjectBlocks8
; Clears d7+1 consecutive 96-byte object blocks starting at a0
Sys_ClearObjectBlocks96:                                ; was: sub_1925A
                                        ; Sys_ClearObjectBlocks17+6   j
                moveq   #0,d0
; Clears the next 96-byte object block in the requested span
Sys_ClearNextObjectBlock96:                             ; was: loc_1925C
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                dbf     d7,Sys_ClearNextObjectBlock96
                rts
; End of function Sys_ClearObjectBlocks96
