as runstart.asm
as runend.asm
as main.asm
as malloc.asm
as mapper.asm
ld app=runstart,main,mapper,malloc,runend
del runstart.rel
del runend.rel
del main.rel
del malloc.rel
del mapper.rel

echo Symbol table:
type app.sym
