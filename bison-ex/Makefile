%.tab.c: %.y
	bison $<

%alc%: %alc.tab.c
	cc -lm -o $@ $<

.PHONY : clean

clean: 
	-rm -f *.o *.c *calc *calc.exe