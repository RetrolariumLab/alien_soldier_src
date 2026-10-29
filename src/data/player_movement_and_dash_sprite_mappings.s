; ROM-ordered player dash, directional movement, and common frame mappings
Player_DashTrailInitialSpriteMapping:   dc.w    $800, 0, $F00D  ; was: word_E8680
                                        ; Effect_CreateDashTrail+38   o
                dc.w    $801, 0, $1818
                dc.w    $802, $E00, $F0
                dc.w    $80E, $100, $1020
                dc.w    $810, $600, $10
                dc.w    $816, $100, $F0E5
                dc.w    $8818, $F00, $E1ED
Player_PhoenixDashAttackSpriteMapping:  dc.w    $800    ; was: word_E86AA
                                        ; Player_InitiateDashAttack+A0   o
                dc.l    Player_PhoenixDashAttackSpriteArtPiece00
                dc.w    $F00D
                dc.w    $801
                dc.l    Player_PhoenixDashAttackSpriteArtPiece01
                dc.w    $1818
                dc.w    $802
                dc.l    Player_PhoenixDashAttackSpriteArtPiece02+$E000000
                dc.w    $F0
                dc.w    $80E
                dc.l    Player_PhoenixDashAttackSpriteArtPiece03+$1000000
                dc.w    $1020
                dc.w    $810
                dc.l    Player_PhoenixDashAttackSpriteArtPiece04+$6000000
                dc.w    $10
                dc.w    $816
                dc.l    Player_PhoenixDashAttackSpriteArtPiece05+$1000000
                dc.w    $F0E5
                dc.w    $8818
                dc.l    Player_PhoenixDashAttackSpriteArtPiece06+$F000000
                dc.w    $E1ED
; Frame 07 precedes frame 00 in ROM; the primary pointer table selects 00..07
Player_DirectionalPrimarySpriteMapping07:   dc.w    $800  ; was: word_E86E2
                dc.l    Player_DirectionalPrimarySpriteArt07Piece00+$E000000
                dc.w    $E0E9
                dc.w    $80C
                dc.l    Player_DirectionalPrimarySpriteArt07Piece01+$8000000
                dc.w    $D8F1
                dc.w    $880F
                dc.l    Player_DirectionalPrimarySpriteArt07Piece02+$1000000
                dc.w    $D809
Player_DirectionalPrimarySpriteMapping00:   dc.w    $800  ; was: word_E86FA
                dc.l    Player_DirectionalPrimarySpriteArt00Piece00+$E000000
                dc.w    $DFE7
                dc.w    $80C
                dc.l    Player_DirectionalPrimarySpriteArt00Piece01+$3000000
                dc.w    $D707
                dc.w    $810
                dc.l    Player_DirectionalPrimarySpriteArt00Piece02
                dc.w    $D90F
                dc.w    $8811
                dc.l    Player_DirectionalPrimarySpriteArt00Piece03+$8000000
                dc.w    $D7EF
Player_DirectionalPrimarySpriteMapping01:   dc.w    $800  ; was: word_E871A
                dc.l    Player_DirectionalPrimarySpriteArt01Piece00
                dc.w    $D80F
                dc.w    $801
                dc.l    Player_DirectionalPrimarySpriteArt01Piece01+$3000000
                dc.w    $D807
                dc.w    $805
                dc.l    Player_DirectionalPrimarySpriteArt01Piece02+$8000000
                dc.w    $D8EF
                dc.w    $8808
                dc.l    Player_DirectionalPrimarySpriteArt01Piece03+$E000000
                dc.w    $E0E7
Player_DirectionalPrimarySpriteMapping02:   dc.w    $800  ; was: word_E873A
                dc.l    Player_DirectionalPrimarySpriteArt02Piece00+$E000000
                dc.w    $E1E8
                dc.w    $80C
                dc.l    Player_DirectionalPrimarySpriteArt02Piece01
                dc.w    $D910
                dc.w    $80D
                dc.l    Player_DirectionalPrimarySpriteArt02Piece02+$8000000
                dc.w    $D9F0
                dc.w    $810
                dc.l    Player_DirectionalPrimarySpriteArt02Piece03+$1000000
                dc.w    $D908
                dc.w    $8812
                dc.l    Player_DirectionalPrimarySpriteArt02Piece04+$4000000
                dc.w    $F9E8
Player_DirectionalPrimarySpriteMapping03:   dc.w    $800  ; was: word_E8762
                dc.l    Player_DirectionalPrimarySpriteArt03Piece00+$1000000
                dc.w    $D80A
                dc.w    $802
                dc.l    Player_DirectionalPrimarySpriteArt03Piece01+$8000000
                dc.w    $F8EA
                dc.w    $805
                dc.l    Player_DirectionalPrimarySpriteArt03Piece02+$8000000
                dc.w    $D8F2
                dc.w    $8808
                dc.l    Player_DirectionalPrimarySpriteArt03Piece03+$E000000
                dc.w    $E0EA
Player_DirectionalPrimarySpriteMapping04:   dc.w    $800  ; was: word_E8782
                dc.l    Player_DirectionalPrimarySpriteArt04Piece00+$4000000
                dc.w    $F7FF
                dc.w    $802
                dc.l    Player_DirectionalPrimarySpriteArt04Piece01
                dc.w    $EBDF
                dc.w    $803
                dc.l    Player_DirectionalPrimarySpriteArt04Piece02+$2000000
                dc.w    $DFE7
                dc.w    $8806
                dc.l    Player_DirectionalPrimarySpriteArt04Piece03+$F000000
                dc.w    $D7EF
Player_DirectionalPrimarySpriteMapping05:   dc.w    $800  ; was: word_E87A2
                dc.l    Player_DirectionalPrimarySpriteArt05Piece00+$1000000
                dc.w    $D80F
                dc.w    $802
                dc.l    Player_DirectionalPrimarySpriteArt05Piece01+$2000000
                dc.w    $D807
                dc.w    $805
                dc.l    Player_DirectionalPrimarySpriteArt05Piece02+$8000000
                dc.w    $D8EF
                dc.w    $8808
                dc.l    Player_DirectionalPrimarySpriteArt05Piece03+$F000000
                dc.w    $E0E7
Player_DirectionalPrimarySpriteMapping06:   dc.w    $800  ; was: word_E87C2
                dc.l    Player_DirectionalPrimarySpriteArt06Piece00+$1000000
                dc.w    $D90F
                dc.w    $802
                dc.l    Player_DirectionalPrimarySpriteArt06Piece01+$2000000
                dc.w    $D907
                dc.w    $805
                dc.l    Player_DirectionalPrimarySpriteArt06Piece02+$8000000
                dc.w    $D9EF
                dc.w    $808
                dc.l    Player_DirectionalPrimarySpriteArt06Piece03+$8000000
                dc.w    $F9E7
                dc.w    $880B
                dc.l    Player_DirectionalPrimarySpriteArt06Piece04+$E000000
                dc.w    $E1E7
; The secondary pointer table has the same 00..07 order despite this ROM order
Player_DirectionalSecondarySpriteMapping07: dc.w    $800  ; was: word_E87EA
                dc.l    Player_DirectionalSecondarySpriteArt07Piece00+$5000000
                dc.w    $10FA
                dc.w    $804
                dc.l    Player_DirectionalSecondarySpriteArt07Piece01+$9000000
                dc.w    $1010
                dc.w    $80A
                dc.l    Player_DirectionalSecondarySpriteArt07Piece02+$6000000
                dc.w    $F8E8
                dc.w    $810
                dc.l    Player_DirectionalSecondarySpriteArt07Piece03+$8000000
                dc.w    $F0F8
                dc.w    $8813
                dc.l    Player_DirectionalSecondarySpriteArt07Piece04+$E000000
                dc.w    $F8F8
Player_DirectionalSecondarySpriteMapping00: dc.w    $800  ; was: word_E8812
                dc.l    Player_DirectionalSecondarySpriteArt00Piece00+$1000000
                dc.w    $FFE7
                dc.w    $802
                dc.l    Player_DirectionalSecondarySpriteArt00Piece01+$5000000
                dc.w    $FDF
                dc.w    $806
                dc.l    Player_DirectionalSecondarySpriteArt00Piece02+$3000000
                dc.w    $F7EF
                dc.w    $80A
                dc.l    Player_DirectionalSecondarySpriteArt00Piece03+$5000000
                dc.w    $FF17
                dc.w    $80E
                dc.l    Player_DirectionalSecondarySpriteArt00Piece04+$8000000
                dc.w    $EFF7
                dc.w    $8811
                dc.l    Player_DirectionalSecondarySpriteArt00Piece05+$E000000
                dc.w    $F7F7
Player_DirectionalSecondarySpriteMapping01: dc.w    $800  ; was: word_E8842
                dc.l    Player_DirectionalSecondarySpriteArt01Piece00
                dc.w    $F80F
                dc.w    $801
                dc.l    Player_DirectionalSecondarySpriteArt01Piece01+$9000000
                dc.w    $10E4
                dc.w    $807
                dc.l    Player_DirectionalSecondarySpriteArt01Piece02+$5000000
                dc.w    $30F
                dc.w    $80B
                dc.l    Player_DirectionalSecondarySpriteArt01Piece03+$2000000
                dc.w    $F8EF
                dc.w    $880E
                dc.l    Player_DirectionalSecondarySpriteArt01Piece04+$B000000
                dc.w    $F0F7
Player_DirectionalSecondarySpriteMapping02: dc.w    $800  ; was: word_E886A
                dc.l    Player_DirectionalSecondarySpriteArt02Piece00
                dc.w    $F90F
                dc.w    $801
                dc.l    Player_DirectionalSecondarySpriteArt02Piece01
                dc.w    $90F
                dc.w    $802
                dc.l    Player_DirectionalSecondarySpriteArt02Piece02
                dc.w    $11F7
                dc.w    $803
                dc.l    Player_DirectionalSecondarySpriteArt02Piece03+$9000000
                dc.w    $11FF
                dc.w    $809
                dc.l    Player_DirectionalSecondarySpriteArt02Piece04+$8000000
                dc.w    $F1F7
                dc.w    $880C
                dc.l    Player_DirectionalSecondarySpriteArt02Piece05+$E000000
                dc.w    $F9EF
Player_DirectionalSecondarySpriteMapping03: dc.w    $800  ; was: word_E889A
                dc.l    Player_DirectionalSecondarySpriteArt03Piece00+$1000000
                dc.w    $D
                dc.w    $802
                dc.l    Player_DirectionalSecondarySpriteArt03Piece01
                dc.w    $F80D
                dc.w    $803
                dc.l    Player_DirectionalSecondarySpriteArt03Piece02+$D000000
                dc.w    $1000
                dc.w    $80B
                dc.l    Player_DirectionalSecondarySpriteArt03Piece03+$8000000
                dc.w    $F0F5
                dc.w    $880E
                dc.l    Player_DirectionalSecondarySpriteArt03Piece04+$E000000
                dc.w    $F8ED
Player_DirectionalSecondarySpriteMapping04: dc.w    $800  ; was: word_E88C2
                dc.l    Player_DirectionalSecondarySpriteArt04Piece00+$9000000
                dc.w    $FDF
                dc.w    $806
                dc.l    Player_DirectionalSecondarySpriteArt04Piece01+$2000000
                dc.w    $F7EF
                dc.w    $809
                dc.l    Player_DirectionalSecondarySpriteArt04Piece02+$6000000
                dc.w    $FF17
                dc.w    $80F
                dc.l    Player_DirectionalSecondarySpriteArt04Piece03+$8000000
                dc.w    $EFF7
                dc.w    $8812
                dc.l    Player_DirectionalSecondarySpriteArt04Piece04+$E000000
                dc.w    $F7F7
Player_DirectionalSecondarySpriteMapping05: dc.w    $800  ; was: word_E88EA
                dc.l    Player_DirectionalSecondarySpriteArt05Piece00
                dc.w    $F80F
                dc.w    $801
                dc.l    Player_DirectionalSecondarySpriteArt05Piece01+$6000000
                dc.w    $F
                dc.w    $807
                dc.l    Player_DirectionalSecondarySpriteArt05Piece02
                dc.w    $18E7
                dc.w    $808
                dc.l    Player_DirectionalSecondarySpriteArt05Piece03+$5000000
                dc.w    $10EF
                dc.w    $80C
                dc.l    Player_DirectionalSecondarySpriteArt05Piece04+$D000000
                dc.w    $EF
                dc.w    $8814
                dc.l    Player_DirectionalSecondarySpriteArt05Piece05+$9000000
                dc.w    $F0F7
Player_DirectionalSecondarySpriteMapping06: dc.w    $800  ; was: word_E891A
                dc.l    Player_DirectionalSecondarySpriteArt06Piece00
                dc.w    $F90F
                dc.w    $801
                dc.l    Player_DirectionalSecondarySpriteArt06Piece01+$1000000
                dc.w    $10F
                dc.w    $803
                dc.l    Player_DirectionalSecondarySpriteArt06Piece02+$9000000
                dc.w    $11FF
                dc.w    $809
                dc.l    Player_DirectionalSecondarySpriteArt06Piece03+$D000000
                dc.w    $1EF
                dc.w    $8811
                dc.l    Player_DirectionalSecondarySpriteArt06Piece04+$9000000
                dc.w    $F1F7
Player_IdleSecondarySpriteMapping:  dc.w    $800        ; was: word_E8942
                                        ; Player_RenderCeilingArmedIdle+16   o
                dc.l    Player_IdleSecondarySpriteArtPiece00+$4000000
                dc.w    $F0F8
                dc.w    $802
                dc.l    Player_IdleSecondarySpriteArtPiece01
                dc.w    $18E1
                dc.w    $803
                dc.l    Player_IdleSecondarySpriteArtPiece02+$5000000
                dc.w    $10E9
                dc.w    $807
                dc.l    Player_IdleSecondarySpriteArtPiece03
                dc.w    $1816
                dc.w    $808
                dc.l    Player_IdleSecondarySpriteArtPiece04+$5000000
                dc.w    $1006
                dc.w    $880C
                dc.l    Player_IdleSecondarySpriteArtPiece05+$E000000
                dc.w    $F8F0
Player_CommonPrimarySpriteMapping:  dc.w    $800        ; was: word_E8972
                                        ; Player_HandleSpecialAttack+B4   o
                dc.l    Player_CommonPrimarySpriteArtPiece00+$F000000
                dc.w    $DAEC
                dc.w    $810
                dc.l    Player_CommonPrimarySpriteArtPiece01
                dc.w    $F40C
                dc.w    $811
                dc.l    Player_CommonPrimarySpriteArtPiece02+$1000000
                dc.w    $EAE4
                dc.w    $8813
                dc.l    Player_IdleSecondarySpriteArtPiece00+$4000000
                dc.w    $F0F8
Player_DashSecondarySpriteMapping:  dc.w    $800        ; was: word_E8992
                                        ; Player_RenderCeilingArmedIdle+2A   o
                dc.l    Player_DashSecondarySpriteArtPiece00
                dc.w    $18E5
                dc.w    $801
                dc.l    Player_DashSecondarySpriteArtPiece01+$5000000
                dc.w    $10ED
                dc.w    $805
                dc.l    Player_DashSecondarySpriteArtPiece02
                dc.w    $180F
                dc.w    $806
                dc.l    Player_DashSecondarySpriteArtPiece03+$5000000
                dc.w    $10FF
                dc.w    $80A
                dc.l    Player_DashSecondarySpriteArtPiece04+$8000000
                dc.w    $F0F7
                dc.w    $880D
                dc.l    Player_DashSecondarySpriteArtPiece05+$E000000
                dc.w    $F8EF
Player_CommonMovementSecondarySpriteMapping:    dc.w    $800  ; was: word_E89C2
                                        ; Player_KnockbackState+6   o
                dc.l    Player_CommonMovementSecondarySpriteArtPiece00
                dc.w    $18DF
                dc.w    $801
                dc.l    Player_CommonMovementSecondarySpriteArtPiece01+$5000000
                dc.w    $10E7
                dc.w    $805
                dc.l    Player_CommonMovementSecondarySpriteArtPiece02
                dc.w    $10F7
                dc.w    $806
                dc.l    Player_CommonMovementSecondarySpriteArtPiece03+$9000000
                dc.w    $10FF
                dc.w    $80C
                dc.l    Player_CommonMovementSecondarySpriteArtPiece04+$5000000
                dc.w    $E8
                dc.w    $8810
                dc.l    Player_CommonMovementSecondarySpriteArtPiece05+$A000000
                dc.w    $F8F7
Player_WeaponSecondarySpriteMapping:    dc.w    $800    ; was: word_E89F2
                                        ; Player_RenderCeilingMotionWithWeapon+6E   o
                dc.l    Player_WeaponSecondarySpriteArtPiece00+$D000000
                dc.w    $10F2
                dc.w    $808
                dc.l    Player_WeaponSecondarySpriteArtPiece01+$4000000
                dc.w    $18DA
                dc.w    $80A
                dc.l    Player_WeaponSecondarySpriteArtPiece02+$3000000
                dc.w    $EA
                dc.w    $80E
                dc.l    Player_WeaponSecondarySpriteArtPiece03
                dc.w    $80A
                dc.w    $880F
                dc.l    Player_WeaponSecondarySpriteArtPiece04+$9000000
                dc.w    $F2
