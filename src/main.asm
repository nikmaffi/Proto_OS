;#####################################################################################
;BIOS legacy booting
;1 - BIOS loads first sector of each bootable device into memory (location 0x7C00).
;2 - BIOS checks for 0xAA55 signature (into the last 2 bytes of the first sector).
;3 - BIOS starts executing the operating system code if the signature was found.
;#####################################################################################

;######################################################################################
;8086 has 20 bits address bus -> we can address 1 MB of memory.
;The addresses are computed with this scheme --> segment:offset (each size: 16 bits)
;Each segment contains 64 KB, each byte can be accessed by the offset value
;segment:offset to absolute address -> real_addr = segment * 16 + offset
;...
;######################################################################################

;The following code will assembled and put into the first sector of a floppy disk

;Tells the assembler to calculate all memory offsets starting as specified address
;(basically tells the assembler where we expect our code to be loaded).
;Different addresses wont make the BIOS starts the operating system.
ORG 0x7C00
;Tells the assembler to init 16 bit code.
;We need to start in this mode in order to make backward compatibility
;...
BITS 16

;New line character macro
%DEFINE ENDL 0x0D, 0x0A

;Entry point
START:
    JMP MAIN

;Print a string to the screen
;Parameters:
;   ds:si --> points to string
PUTS:
    ;Saving registers
    PUSH SI
    PUSH AX

    .LOOP:
        ;Load a byte from the address ds:si into the al reg, and increments si 
        LODSB
        ;Checking if we have reached the null character (string terminator)
        OR AL, AL
        ;Ending loop if the zer flag is set
        JZ .DONE

        ;Printing the characters
        ;NOTE: The BIOS provides some functions to to basics stuff (ei writing text to the screen)
        ;Setting the value in order to call the function for writing the character in TTY mode (al contains the character)
        MOV AH, 0EH
        ;Setting page number (multiple text screens side-by-side. The page numbers allow you to do double-buffering,
        ;where you draw to an off-screen page, and then when it's ready change the currently visible page to the new one.)
        MOV BH, 0
        ;Generating an interrupt with code 10H (code for the video)
        INT 0x10

        JMP .LOOP

    .DONE:
    ;Restoring registers
    POP AX
    POP SI

    RET

MAIN:
    ;Setting up data segment (we use ax since we cant put a constants directly ds/es)
    MOV AX, 0
    MOV DS, AX
    MOV ES, AX

    ;Setting up the stack segment and stack pointer (grows downwards from where we loaded in memory)
    MOV SS, AX
    MOV SP, 0x7C00

    MOV SI, HELLO_WORLD
    CALL PUTS

    HLT

.HALT:
    JMP .HALT

HELLO_WORLD: DB ENDL, ENDL, "Hello world from Proto OS! (By Nicolo' Maffi)", ENDL, 0

;We will booting the program on a 1.44 MB floppy (each sector will be 512 bytes).
;We need to put the signature 0xAA55 into the last 2 bytes of the first sector.
;Used to repeat instructions or data; use to skip (pad and fill with 0) the first 510 bytes,
;but we need to subtract the lenght of the program writter so far ($-$$)
TIMES 510-($-$$) DB 0
;Declaring signature (D.W. -> declare word --> word = 2 bytes)
DW 0AA55H