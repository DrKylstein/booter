    .8086
    .model tiny
.code
    org 7c00h
    jmp short start
    nop
    db "CONHGECO" ;vendor name
    dw 512 ;bytes per sector
    db 1 ;sectors per cluster
    dw 33 ;reserved sectors
    db 2 ;FAT copies
    dw 224 ;root directory entries
    dw 2880 ;total sectors
    db 0f0h ;media descriptor: 1.44MB floppy
    dw 9 ;sectors per FAT
    dw 12 ; sectors per track
    dw 2 ;heads (double-sided?)
    dw 0 ;hidden sectors
    ;extended:
    dw 0 ;extension of hidden sectors
    dd 2880 ;copy of total sectors
    db 0 ;logical drive number
    db 0 ;reserved
    db 29h ;extended signature
    dd 00001138h ; serial number of partition
    db "NO NAME    " ;volume label (MSDOS 6 only recognizes one in FAT)
    db "BOOTER  ";db "FAT12   " ;filesystem type
    
start:
;setup
    cli
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov bp,7c00h
    mov sp,7c00h
    sti
        
;set video mode    
    mov ax,0004h
    int 10h
;set palette
    mov ah,0bh
    mov bh,1
    mov bl,0
    int 10h

    REPEAT 3
;reset disk
    mov ah,0
    int 13h
;display image
    mov ax,0b800h ;dest segment
    mov es,ax
    mov bx,0000h ;dest offset
    mov ah,2 ;read sectors
    mov al,32 ;read 32 sectors
    mov cl,02h ;start at sector 2
    mov ch,00h ;
    mov dl,00h ; drive
    mov dh,00h ;head and track
    int 13h
    ENDM
end_of_program:
    jmp end_of_program
    
    org 7dfeh
    dw 55aah ; boot sector signature
end
