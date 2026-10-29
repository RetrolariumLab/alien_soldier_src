; Initialize nine consecutive $60-byte auxiliary sprite records
UnreferencedInitializeNineAuxiliarySprites:             ; was: sub_548EE
                move.w  #8,d7
                lea     $360(a5),a0
UnreferencedInitializeNineAuxiliarySpritesLoop:         ; was: loc_548F6
                move.w  #$10,(a0)
                move.l  #Effect_SpriteAnimation12,8(a0)
                clr.w   $C(a0)
                move.w  #$EC80,2(a0)
                move.w  #$8480,$E(a0)
                lea     $60(a0),a0
                dbf     d7,UnreferencedInitializeNineAuxiliarySpritesLoop
                rts
; End of function UnreferencedInitializeNineAuxiliarySprites
; Position one sprite at the first anchor and four around each of two anchors
UnreferencedUpdateNineAuxiliarySpritePositions:         ; was: sub_5491C
                lea     $360(a5),a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                lea     $60(a0),a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),d0
                add.b   $2C(a5),d0
                move.w  d0,$14(a0)
                lea     $60(a0),a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),d0
                add.b   $2D(a5),d0
                move.w  d0,$14(a0)
                lea     $60(a0),a0
                move.w  $14(a5),$14(a0)
                move.w  $10(a5),d0
                add.b   $2E(a5),d0
                move.w  d0,$10(a0)
                lea     $60(a0),a0
                move.w  $14(a5),$14(a0)
                move.w  $10(a5),d0
                add.b   $2F(a5),d0
                move.w  d0,$10(a0)
                lea     $180(a5),a1
                lea     $60(a0),a0
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),d0
                add.b   $2C(a1),d0
                move.w  d0,$14(a0)
                lea     $60(a0),a0
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),d0
                add.b   $2D(a1),d0
                move.w  d0,$14(a0)
                lea     $60(a0),a0
                move.w  $14(a1),$14(a0)
                move.w  $10(a1),d0
                add.b   $2E(a1),d0
                move.w  d0,$10(a0)
                lea     $60(a0),a0
                move.w  $14(a1),$14(a0)
                move.w  $10(a1),d0
                add.b   $2F(a1),d0
                move.w  d0,$10(a0)
                rts
; End of function UnreferencedUpdateNineAuxiliarySpritePositions
