TITLE HELLO WORLD PROGRAM
; THIS PROGRAM DISPLAYS "HELLO, WORLD!"

;========= COLOR ENUM =========
PL_BLACK equ 00h
PL_BLUE equ 01h
PL_GREEN equ 02h
PL_CYAN equ 03h
PL_RED equ 04h
PL_MAGENTA equ 05h
PL_BROWN equ 06h
PL_LGRAY equ 07h
PL_DGRAY equ 08h
PL_LBLUE equ 09h
PL_LGREEN equ 0Ah
PL_LCYAN equ 0Bh
PL_LRED equ 0Ch
PL_LMAGENTA equ 0Dh
PL_YELLOW equ 0Eh
PL_WHITE equ 0Fh
;========= COLOR ENUM =========

;========= MACRO DEFINITIONS =========
PASS_RECT_PARAM MACRO Xpos, Ypos, Xlen, Ylen, Color
;Pass parameters to register for rectangle function
            mov RectXpos,Xpos
            mov RectYpos,Ypos
            mov RectXdim,Xlen
            mov RectYdim,Ylen
            mov RectColor,Color
ENDM

MOVRB       MACRO reg1, reg2
;Mov byte reg2 to reg1
            push bx
            xor bx,bx
            mov bl,reg2
            mov reg1,bl
            pop bx
ENDM

MOVRW       MACRO reg1, reg2
;Mov word reg2 to reg1
            push bx
            mov bx,reg2
            mov reg1,bx
            pop bx
ENDM
;========= MACRO DEFINITIONS =========

.MODEL large,stdcall
.STACK 100h ;256 BYTE STACK

.DATA
message db "hello, world!",0dh,0ah,'$'
;Set palette variables
PLnewcolor db 00h
PLlastcolor db 00h
PLaddrReg db 00h
PLdataReg db 00h
;DrawRect function variables
RectXpos dw 0000h ;0-80
RectYpos dw 0000h ;0-480
RectXdim dw 0000h ;0-80
RectYdim dw 0000h ;0-480
RectColor db 00h

.CODE
.STARTUP
        ;DS -> Data segment
        mov ax,@data
        mov ds,ax
        ;ES -> Video memory
        mov ax,0A000h
        mov es,ax
main:
        mov ah,9
        lea dx,message
        int 21h
        call InitScreen

        PASS_RECT_PARAM 40d,240d,10d,60d,PL_BLUE
        call DrawRect

        call ExitProgram
        jmp main
.EXIT
        mov ax,0002h  ;Set text mode
        int 10h
        mov ax,4c00h
        int 21h
; ===================== PROCEDURES =====================
InitScreen  PROC
;Initialize display
        mov ax,0012h
        int 10h
;Set Palette Color
        mov PLnewcolor,PL_RED
        call SetPalette
;BG fill
        mov ax,0FFFFh
        mov cx,19200d ;Fullscreen 640*480/16bit
        xor di,di
        rep stosw
InitScreen  ENDP

DrawRect PROC
;Read pixel color in start pos
        mov ax,0D00h
        xor bx,bx
        mov cx,RectXpos
        mov dx,RectYpos
        int 10h
;Create mask for new color
        MOVRB PLnewcolor,RectColor
        call SetPalette

;Calculate Di = 80*y + x and Cx = ylen
        mov ax,RectYpos
        xor dx,dx
        mov bx,80d
        mul bx
        add ax,RectXpos
        mov di,ax ;Start position
        mov cx,RectYdim
;Draw rectangle
DrawRect_START:
        push cx
        mov cx,RectXdim
        mov al,0FFh
        rep stosb
        sub di,RectXdim
        add di,80d
        pop cx
        loop DrawRect_START
DrawRect_END:

        ret
DrawRect ENDP

SetPalette PROC
        ;save value of address register
        mov dx,03c4h
        in al,dx
        mov PLaddrReg,al

        ;output the index of desired data reg. to address reg
        mov al,02h ; Map Mask register (02h)
        out dx,al

        ;read value of data register and save
        mov dx,03c5h
        in al,dx
        mov PLdataReg,al

        ;modify data register value
        MOVRB PLdataReg,PLnewcolor ; 0b0000XXXX Planes I-R-G-B

        ;Write into data register
        mov al,PLdataReg
        mov dx,03c5h
        out dx,al

        ;Write stored address register value to address reg.
        mov dx,3c4h
        mov al,PLaddrReg
        out dx,al

        ;Update current color palette
        MOVRB PLlastcolor,PLnewcolor

        ret
SetPalette ENDP

ExitProgram  PROC
;Check keyboard and exits if ESC pressed
        mov ax,0800h
        int 21h
        cmp al,1Bh
        jnz continue
        mov ax,0002h  ;Set text mode
        int 10h
        mov ax, 4c00h
        int 21h
continue:
        ret
ExitProgram  ENDP
; ===================== PROCEDURES =====================

END
