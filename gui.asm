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

;========= SCANCODE ENUM =========
KEY_DOWN equ 5000h;
KEY_UP equ 4800h
KEY_ESC equ 011Bh
;========= SCANCODE ENUM =========

;========= MACRO DEFINITIONS =========
PASS_RECT_PARAM MACRO Xpos, Ypos, Xlen, Ylen, Color
;Pass parameters to register for rectangle function
            mov RectXpos,Xpos
            mov RectYpos,Ypos
            mov RectXdim,Xlen
            mov RectYdim,Ylen
            mov RectColor,Color
ENDM

PASS_SEL_PARAM MACRO Xpos, Ypos, Xlen, Ylen, Color
;Pass parameters to register for selection function
            mov BoxXpos,Xpos
            mov BoxYpos,Ypos
            mov BoxXdim,Xlen
            mov BoxYdim,Ylen
            mov BoxSelColor,Color
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

MULW        MACRO reg1, reg2
;MUL word reg2 to reg1 and store to reg1
            push dx
            push bx
            push ax
            xor dx,dx
            mov bx,reg2
            mov ax,reg1
            mul bx
            mov reg1,ax
            pop ax
            pop bx
            pop dx
ENDM

PUT_PIXEL   MACRO x_cor, y_cor, color
            push ax
            push bx
            xor bx,bx
            mov ah,0Ch
            mov al,color
            mov cx,x_cor
            mov dx,y_cor
            int 10h
            pop bx
            pop ax
ENDM
;========= MACRO DEFINITIONS =========

.MODEL large,stdcall
.STACK 100h ;256 BYTE STACK

.DATA
message db "hello, world!",0dh,0ah,'$'
BGcolour db PL_BLUE
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
;DrawSelectionBox function variables
BoxXpos dw 0000h ;0-80
BoxYpos dw 0000h ;0-480
BoxXdim dw 0000h ;0-80
BoxYdim dw 0000h ;0-480
BoxSelColor db 00h ;Selection box color
;DrawSelection function variables
UIactiveSel dw 80d ;Position of active selection
UIbtnOffset dw 80d ;Offset to first Buttons
UIbtnSpacing dw 80d ;Spacing between Buttons
UIbtnNumber dw 4d ; Number of buttons
UIopt dw 0000h ;0-1-2-3

.CODE
.STARTUP
        ;DS -> Data segment
        mov ax,@data
        mov ds,ax
        ;ES -> Video memory
        mov ax,0A000h
        mov es,ax

        mov ah,9
        lea dx,message
        int 21h
        call InitScreen
main:
        call CheckKey
        call DrawSelection
        ;call ExitProgram
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
        MOVRB PLnewcolor,BGcolour
        call SetPalette
;BG fill
        mov ax,0FFFFh
        mov cx,19200d ;Fullscreen 640*480/16bit
        xor di,di
        rep stosw

;Draw Buttons
        mov ax,UIbtnOffset
        mov cx,UIbtnNumber
init_drawbtn:
        push cx
        push ax
        PASS_RECT_PARAM 24d,ax,32d,40d,PL_CYAN
        call DrawRect
        pop ax
        pop cx
        add ax,UIbtnSpacing
        loop init_drawbtn

;Draw Header
        PASS_RECT_PARAM 0d,0d,80d,20d,PL_LGRAY
        call DrawRect

;Draw Footer
        PASS_RECT_PARAM 0d,440d,80d,40d,PL_LGRAY
        call DrawRect

;Draw Selection box
        mov UIopt,0d
        call DrawSelection

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

DrawSelection PROC
;Reset current selection
        mov ax,UIactiveSel
        mov bl,BGcolour
        PASS_SEL_PARAM 24d,ax,32d,40d,bl
        call DrawSelectionBox

;Draw new selection
        mov ax,UIbtnOffset
        mov UIactiveSel,80d
        MULW UIactiveSel,UIopt
        add UIactiveSel,ax
        mov ax,UIactiveSel

        PASS_SEL_PARAM 24d,ax,32d,40d,PL_RED
        call DrawSelectionBox

        ret
DrawSelection ENDP

DrawSelectionBox PROC
        MULW BoxXpos,8d
        MULW BoxXdim,8d

        mov cx,BoxXpos
        mov dx,BoxYpos
        dec cx
        dec dx

        mov ax,cx
        add ax,BoxXdim
        inc ax
ds_toploop:
        PUT_PIXEL cx, dx, BoxSelColor
        dec dx ;2wide
        PUT_PIXEL cx, dx, BoxSelColor
        inc dx ;2wide
        inc cx
        cmp cx,ax
        jnz ds_toploop

        mov ax,dx
        add ax,BoxYdim
        inc ax
ds_rsidelp:
        PUT_PIXEL cx, dx, BoxSelColor
        inc cx ;2wide
        PUT_PIXEL cx, dx, BoxSelColor
        dec cx ;2wide
        inc dx
        cmp dx,ax
        jnz ds_rsidelp

        mov ax,BoxXpos
        dec ax
ds_botloop:
        PUT_PIXEL cx, dx, BoxSelColor
        inc dx ;2wide
        PUT_PIXEL cx, dx, BoxSelColor
        dec dx
        dec cx
        cmp cx,ax
        jnz ds_botloop

        mov ax,BoxYpos
        dec ax
ds_lsidelp:
        PUT_PIXEL cx, dx, BoxSelColor
        dec cx ;2wide
        PUT_PIXEL cx, dx, BoxSelColor
        inc cx ;2wide
        dec dx
        cmp dx,ax
        jnz ds_lsidelp

        RET

DrawSelectionBox ENDP

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

CheckKey  PROC
;Check keyboard and update ui
        mov ax,0000h
        int 16h
        cmp ax,KEY_UP
        jz ck_dec
        cmp ax,KEY_DOWN
        jz ck_inc
        cmp ax,KEY_ESC
        jz ck_exit
ck_end:
        ret
ck_inc:
        mov ax,UIbtnNumber
        add UIopt,1d
        cmp UIopt,ax
        jb ck_end
        sub UIopt,ax
        jmp ck_end
ck_dec:
        mov ax,UIbtnNumber
        sub UIopt,1d
        cmp UIopt,0d
        jns ck_end
        add UIopt,ax
        jmp ck_end
ck_exit:
        mov ax,0002h  ;Set text mode
        int 10h
        mov ax, 4c00h
        int 21h

CheckKey  ENDP

ExitProgram  PROC
;Check keyboard and exits if ESC pressed
        mov ax,0000h
        int 16h
        cmp ax,KEY_ESC
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
