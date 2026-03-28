// ------------------------------------------------------------
// Simple Branching Demo for Commodore 64
// Press F1, F3 or F5 to change border color
// ------------------------------------------------------------

BasicUpstart2(main)

* = $1000

// Kernal routines
.const CHROUT = $FFD2   // Print character to screen
.const GETIN  = $FFE4   // Get keyboard input (returns 0 if no key)

// VIC-II registers
.const BORDER = $D020   // Border color register

main:
    cli                 // Enable interrupts so keyboard works

    jsr PrintMessage    // Show initial message
    jsr NewLine

WaitKey:
    jsr GETIN           // Get a keypress
    beq WaitKey         // Branch if no key was pressed (Z=1)

    // Check which function key was pressed
    cmp #$85            // F1 key code
    beq PressedF1

    cmp #$86            // F3 key code
    beq PressedF3

    cmp #$87            // F5 key code
    beq PressedF5

    jmp WaitKey         // Ignore all other keys

// ------------------------------------------------------------
PressedF1:
    lda #2              // Color 2 = Red
    sta BORDER
    lda #'1'            // Character to print after "YOU PRESSED F"
    jmp PrintPressed    // Reuse the printing code

PressedF3:
    lda #1              // Color 1 = White
    sta BORDER
    lda #'3'
    jmp PrintPressed

PressedF5:
    lda #6              // Color 6 = Blue
    sta BORDER
    lda #'5'
    jmp PrintPressed

// ------------------------------------------------------------
// Common routine: Print "YOU PRESSED F" + the digit
// ------------------------------------------------------------
PrintPressed:
    sta keyStore        // Save the digit ('1', '3' or '5')

    jsr PrintYouPressed // Print "YOU PRESSED F"
    
    lda keyStore        // Restore the digit
    jsr CHROUT          // Print it (e.g. "1", "3" or "5")
    
    jsr NewLine         // Move to next line
    jmp WaitKey         // Go back to waiting for next key

// ------------------------------------------------------------
// Subroutines
// ------------------------------------------------------------
PrintMessage:
    ldx #0
LoopMessage:
    lda Message,x
    beq DoneMessage     // End of string (0 byte)
    jsr CHROUT
    inx
    bne LoopMessage     // Simple loop (won't wrap around realistically)
DoneMessage:
    rts

PrintYouPressed:
    ldx #0
LoopYouPressed:
    lda YouPressed,x
    beq DoneYouPressed
    jsr CHROUT
    inx
    bne LoopYouPressed
DoneYouPressed:
    rts

NewLine:
    lda #13             // PETSCII code for carriage return (new line)
    jsr CHROUT
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
    .byte 0             // Temporary storage for the key digit