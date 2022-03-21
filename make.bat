echo Assembling RUNSTART
as runstart.asm

echo Assembling RUNEND
as runend.asm

echo Assembling MAIN
as main.asm

echo Assembling MALLOC
as malloc.asm

echo Assembling MAPPER
as mapper.asm

echo Assembling GETSLTTB and GETEXPTTB
as getslttb.asm
as getexptb.asm

echo Linking into APP.com
ld app=runstart,mapper,malloc,main,getslttb,getexptb,runend

echo Cleaning up relocatable files
del runstart.rel
del runend.rel
del main.rel
del malloc.rel
del mapper.rel
del getslttb.rel
del getexptb.rel

rem echo Symbol table:
rem type app.sym
