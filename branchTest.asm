// ------------------------------------------------------------
// Simple branching demo for C64 in KickAssembler
// Using F1, F3, F5 keys
// ------------------------------------------------------------

BasicUpstart2(main)

* = $1000

.const CHROUT = $FFD2
.const GETIN  = $FFE4
.const BORDER = $D020

main:
    cli                 // enable interrupts (keyboard scan)

    jsr PrintMessage

    lda #13
    jsr CHROUT

WaitKey:
    jsr GETIN
    beq WaitKey         // no key yet

    // ---- Function keys ----
    cmp #$85            // F1
    beq PressedF1

    cmp #$86            // F3
    beq PressedF3

    cmp #$87            // F5
    beq PressedF5

    jmp WaitKey         // ignore anything else

// ------------------------------------------------------------
// Branch targets
// ------------------------------------------------------------
PressedF1:
    lda #2              // red
    sta BORDER
    lda #'1'
    jmp PrintPressed

PressedF3:
    lda #1              // white
    sta BORDER
    lda #'3'
    jmp PrintPressed

PressedF5:
    lda #6              // blue
    sta BORDER
    lda #'5'
    jmp PrintPressed

// ------------------------------------------------------------
// Print "YOU PRESSED X"
// ------------------------------------------------------------
PrintPressed:
    sta keyStore
    jsr PrintYouPressed
    lda keyStore
    jsr CHROUT
    rts

// ------------------------------------------------------------
// Subroutines
// ------------------------------------------------------------
PrintMessage:
    ldx #0
PM_Loop:
    lda Message,x
    beq PM_Done
    jsr CHROUT
    inx
    bne PM_Loop
PM_Done:
    rts

PrintYouPressed:
    ldx #0
PYP_Loop:
    lda YouPressed,x
    beq PYP_Done
    jsr CHROUT
    inx
    bne PYP_Loop
PYP_Done:
    rts

// ------------------------------------------------------------
// Data
// ------------------------------------------------------------
Message:
    .text "PRESS F1, F3 OR F5"
    .byte 0

YouPressed:
    .text "YOU PRESSED F"
    .byte 0

keyStore:
    .byte 0
