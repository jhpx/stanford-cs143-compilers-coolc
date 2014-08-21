rpcalc.tab.c: rpcalc.y
	bison rpcalc.y

rpcalc: rpcalc.tab.c
	cc -lm -o rpcalc rpcalc.tab.c

calc.tab.c: calc.y
	bison calc.y

calc: calc.tab.c
	cc -lm -o calc calc.tab.c

clean: 
	-rm -f *.o *.c rpcalc calc