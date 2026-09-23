; Preservation build profile selected by the Makefile
; The default must remain the released Japanese Source 1.0 image

                ifndef  BuildProfileEU
BuildProfileEU  equ     0
                endif

BuildProfileJP  equ     1-BuildProfileEU

RegionLockTextPosition          equ     $438C+BuildProfileEU*$180
StoryInitialTimer               equ     $2900+BuildProfileEU*$800
StoryFirstCueTimer              equ     $18C0+BuildProfileEU*$480
StoryFadeCueTimer               equ     $1880+BuildProfileEU*$480
StoryLogoExpansionWait          equ     $1C0-BuildProfileEU*$48
CreditsFadeStartFrame           equ     $11C0-BuildProfileEU*$2D0
CreditsMusicFadeOutCountdown    equ     $1F40+BuildProfileEU*$800
CreditsXiTigerBGMCountdown      equ     $1EC0+BuildProfileEU*$800
