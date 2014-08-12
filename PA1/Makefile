
ASSN = 2
CLASS= cs143
CLASSDIR= ../class/cs143/cool
LIB= -L/usr/lib -lfl

SRC= cool.flex test.cl README
CSRC= lextest.cc utilities.cc stringtab.cc handle_flags.cc
TSRC=
HSRC=
CGEN= cool-lex.cc
HGEN=
LIBS=
CFIL= ${CSRC} ${CGEN}
LSRC= Makefile
OBJS= ${CFIL:.cc=.o}
DEPS= ${CFIL:.cc=.d}
OUTPUT= test.output

CPPINCLUDE= -I. -I${CLASSDIR}/include/PA${ASSN} -I${CLASSDIR}/src/PA${ASSN}


FFLAGS= -d -ocool-lex.cc

CC= g++
CFLAGS= -g -Wall -Wno-unused -Wno-write-strings ${CPPINCLUDE}
FLEX= flex ${FFLAGS}
DEPEND= ${CC} -MM ${CPPINCLUDE}


source : ${SRC} ${TSRC} ${LIBS} ${CSRC} lsource

lsource: ${LSRC}

${OUTPUT}: lexer test.cl
	@rm -f test.output
	-./lexer test.cl >test.output 2>&1

lexer: ${OBJS} ${DEPS}
	${CC} ${CFLAGS} ${OBJS} ${LIB} -o lexer

.cc.o:
	${CC} ${CFLAGS} -c $<

${CGEN}: cool.flex
	${FLEX} cool.flex

dotest:	lexer test.cl
	./lexer test.cl

${LIBS}:
	-${CLASSDIR}/etc/link-object ${ASSN} $@

# These dependencies allow you to get the starting files for
# the assignment.  They will not overwrite a file you already have.

${SRC} :
	-${CLASSDIR}/etc/copy-skel ${ASSN} ${SRC}

${LSRC} :
	-${CLASSDIR}/etc/link-shared ${ASSN} ${LSRC}

${TSRC} ${CSRC}:
	-ln -s ${CLASSDIR}/src/PA${ASSN}/$@ $@

${HSRC}:
	-ln -s ${CLASSDIR}/include/PA${ASSN}/$@ $@

submit-clean: ${OUTPUT}
	-rm -f *.s ${OBJS} lexer ${CGEN} ${DEPS} *~ ${LIBS}

clean :
	-rm -f ${OUTPUT} *.s ${OBJS} lexer ${CGEN} ${DEPS} *~ ${LIBS}

clean-compile:
	@-rm -f ${OBJS} ${CGEN} ${DEPS}

%.d: %.cc ${SRC} ${LSRC}
	${SHELL} -ec '${DEPEND} $< | sed '\''s/\($*\.o\)[ :]*/\1 $@ : /g'\'' > $@'

