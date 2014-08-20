rpcalc.tab.c: rpcalc.y
	bison rpcalc.y

rpcalc: rpcalc.tab.c
	cc -lm -o rpcalc rpcalc.tab.c
clean: 
	-rm -f *.o rpcalc.tab.c rpcalc 