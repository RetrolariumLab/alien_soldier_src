; ROM-ordered phoenix/teleport, special-attack, and death-particle mappings
Player_PhoenixAndTeleportDashSpriteMapping: dc.w    0   ; was: word_E8E6A
                                        ; Player_InitiateDashAttack+84   o
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece00+$D000000
                dc.w    $B09
                dc.w    8
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece01+$4000000
                dc.w    $309
                dc.w    $A
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece02+$C000000
                dc.w    $FB09
                dc.w    $E
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece03+$8000000
                dc.w    $F309
                dc.w    $11
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece04
                dc.w    $E329
                dc.w    $12
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece05+$1000000
                dc.w    $F3E9
                dc.w    $14
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece06+$D000000
                dc.w    $E309
                dc.w    $1C
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece07+$E000000
                dc.w    $3E9
                dc.w    $28
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece08+$5000000
                dc.w    $F7D9
                dc.w    $802C
                dc.l    Player_PhoenixAndTeleportDashSpriteArtPiece09+$B000000
                dc.w    $E3F1
Player_TeleportDashTrailSpriteMapping:  dc.w    0       ; was: word_E8EBA
                                        ; Effect_CreateDashTrail+6   o
                dc.l    Player_TeleportDashTrailSpriteArtPiece00+$5000000
                dc.w    $F430
                dc.w    4
                dc.l    Player_TeleportDashTrailSpriteArtPiece01
                dc.w    $ECD8
                dc.w    5
                dc.l    Player_TeleportDashTrailSpriteArtPiece02+$D000000
                dc.w    $E4E0
                dc.w    $D
                dc.l    Player_TeleportDashTrailSpriteArtPiece03+$D000000
                dc.w    $E400
                dc.w    $15
                dc.l    Player_TeleportDashTrailSpriteArtPiece04+$5000000
                dc.w    $E420
                dc.w    $19
                dc.l    Player_TeleportDashTrailSpriteArtPiece05+$E000000
                dc.w    $F400
                dc.w    $25
                dc.l    Player_TeleportDashTrailSpriteArtPiece06+$6000000
                dc.w    $F420
                dc.w    $2B
                dc.l    Player_TeleportDashTrailSpriteArtPiece07+$8000000
                dc.w    $FB40
                dc.w    $2E
                dc.l    Player_TeleportDashTrailSpriteArtPiece08+$E000000
                dc.w    $F4E0
                dc.w    $803A
                dc.l    Player_TeleportDashTrailSpriteArtPiece09+$6000000
                dc.w    $F4D0
Player_MotionPoseSecondarySpriteMapping:    dc.w    $800  ; was: word_E8F0A
                                        ; Player_RenderCeilingMotionWithWeapon+1E   o
                dc.l    Player_AirborneWeaponSecondarySpriteArtPiece00
                dc.w    3
                dc.w    $801
                dc.l    Player_AirborneWeaponSecondarySpriteArtPiece01+$6000000
                dc.w    $803
                dc.w    $8807
                dc.l    Player_AirborneWeaponSecondarySpriteArtPiece02+$B000000
                dc.w    $EB
Player_TeleportDashProjectileSpriteMapping: dc.w    4, 0, $ECD8  ; was: word_E8F22
                                        ; Player_SpawnProjectile+30   o
                dc.w    5, $D00, $E4E0
                dc.w    $D, $D00, $E400
                dc.w    $8015, $500, $E420
Player_SpecialAttackSecondarySpriteMappingA:    dc.w    $800  ; was: word_E8F3A
                                        ; sub_16116   o
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece00+$5000000
                dc.w    $17F9
                dc.w    $804
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece01+$5000000
                dc.w    $1711
                dc.w    $808
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece02+$9000000
                dc.w    $701
                dc.w    $80E
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece03+$5000000
                dc.w    $7F1
                dc.w    $812
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece04+$1000000
                dc.w    $F7F1
                dc.w    $8814
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece05+$A000000
                dc.w    $EFF9
Player_SpecialAttackSecondarySpriteMappingB:    dc.w    $800  ; was: word_E8F6A
                                        ; Player_RenderSpecialMoveRecovery+E   o
                dc.l    Player_SpecialAttackSecondarySpriteArtBPiece00+$E000000
                dc.w    $EFF9
                dc.w    $80C
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece00+$5000000
                dc.w    $17F9
                dc.w    $810
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece01+$5000000
                dc.w    $1711
                dc.w    $814
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece02+$9000000
                dc.w    $701
                dc.w    $81A
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece03+$5000000
                dc.w    $7F1
                dc.w    $881E
                dc.l    Player_SpecialAttackSecondarySpriteArtAPiece04+$1000000
                dc.w    $F7F1
Player_DeathSequenceSpriteMapping00:    dc.w    $800    ; was: word_E8F9A
                dc.l    Player_DeathSequenceSpriteArt00Piece00+$9000000
                dc.w    $5F3
                dc.w    $806
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $E3F5
                dc.w    $80E
                dc.l    Player_DeathSequenceSpriteArt00Piece02
                dc.w    $E2DC
                dc.w    $80F
                dc.l    Player_DeathSequenceSpriteArt00Piece03+$C000000
                dc.w    $E2E4
                dc.w    $8813
                dc.l    Player_DeathSequenceSpriteArt00Piece04+$C000000
                dc.w    $E204
Player_DeathSequenceSpriteMapping01:    dc.w    $800    ; was: word_E8FC2
                dc.l    Player_DeathSequenceSpriteArt00Piece00+$9000000
                dc.w    $5F3
                dc.w    $806
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $E7F5
                dc.w    $80E
                dc.l    Player_DeathSequenceSpriteArt00Piece02
                dc.w    $E2DC
                dc.w    $80F
                dc.l    Player_DeathSequenceSpriteArt00Piece03+$C000000
                dc.w    $E2E4
                dc.w    $8813
                dc.l    Player_DeathSequenceSpriteArt00Piece04+$C000000
                dc.w    $E204
Player_DeathSequenceSpriteMapping02:    dc.w    $800    ; was: word_E8FEA
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $EAF5
                dc.w    $808
                dc.l    Player_DeathSequenceSpriteArt00Piece00+$9000000
                dc.w    $5F3
                dc.w    $80E
                dc.l    Player_DeathSequenceSpriteArt00Piece02
                dc.w    $E2DC
                dc.w    $80F
                dc.l    Player_DeathSequenceSpriteArt00Piece03+$C000000
                dc.w    $E2E4
                dc.w    $8813
                dc.l    Player_DeathSequenceSpriteArt00Piece04+$C000000
                dc.w    $E204
Player_DeathSequenceSpriteMapping03:    dc.w    $800    ; was: word_E9012
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $ECF5
                dc.w    $808
                dc.l    Player_DeathSequenceSpriteArt03Piece01+$8000000
                dc.w    $9F3
                dc.w    $80B
                dc.l    Player_DeathSequenceSpriteArt00Piece02
                dc.w    $E2DC
                dc.w    $80C
                dc.l    Player_DeathSequenceSpriteArt00Piece03+$C000000
                dc.w    $E2E4
                dc.w    $8810
                dc.l    Player_DeathSequenceSpriteArt00Piece04+$C000000
                dc.w    $E204
Player_DeathSequenceSpriteMapping04:    dc.w    $800    ; was: word_E903A
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $EDF5
                dc.w    $8808
                dc.l    Player_DeathSequenceSpriteArt03Piece01+$8000000
                dc.w    $9F3
Player_DeathSequenceSpriteMapping05:    dc.w    $800    ; was: word_E904A
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $EEF5
                dc.w    $8808
                dc.l    Player_DeathSequenceSpriteArt03Piece01+$8000000
                dc.w    $9F3
Player_DeathSequenceSpriteMapping06:    dc.w    $800    ; was: word_E905A
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $EAF5
                dc.w    $8808
                dc.l    Player_DeathSequenceSpriteArt03Piece01+$8000000
                dc.w    $9F3
Player_DeathSequenceSpriteMapping07:    dc.w    $800    ; was: word_E906A
                dc.l    Player_DeathSequenceSpriteArt00Piece01+$7000000
                dc.w    $E6F5
                dc.w    $8808
                dc.l    Player_DeathSequenceSpriteArt03Piece01+$8000000
                dc.w    $9F3
