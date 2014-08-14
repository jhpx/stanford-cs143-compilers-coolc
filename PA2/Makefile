
ASSN = 3
CLASS= cs143
CLASSDIR= ../class/cs143/cool
LIB= -L/usr/lib -lfl
AR= gar
ARCHIVE_NEW= -cr
RANLIB= gar -qs

SRC= cool.y cool-tree.handcode.h good.cl bad.cl README
CSRC= parser-phase.cc utilities.cc stringtab.cc dumptype.cc \
      tree.cc cool-tree.cc tokens-lex.cc  handle_flags.cc
TSRC= myparser cool-tree.aps
HSRC=
CGEN= cool-parse.cc
HGEN= cool-parse.h
LIBS= lexer
CFIL= ${CSRC} ${CGEN}

LSRC= Makefile
OBJS= ${CFIL:.cc=.o}
DEPS= ${CFIL:.cc=.d}
OUTPUT= good.output bad.output


CPPINCLUDE= -I. -I${CLASSDIR}/include/PA${ASSN} -I${CLASSDIR}/src/PA${ASSN}

BFLAGS= -d -v -y -o cool-parse.cc --debug -p cool_yy

CC= g++
CFLAGS= -g -Wall -Wno-unused -Wno-deprecated -Wno-write-strings -DDEBUG ${CPPINCLUDE}
FLEX= flex ${FFLAGS}
BISON= bison ${BFLAGS}
DEPEND= ${CC} -MM ${CPPINCLUDE}

source: ${SRC} ${TSRC} ${CSRC} lsource

lsource: ${LSRC}

${OUTPUT}: parser good.cl bad.cl
	@rm -f ${OUTPUT}
	./myparser good.cl >good.output 2>&1
	-./myparser bad.cl >bad.output 2>&1

parser: ${OBJS} ${TSRC} ${LIBS} ${DEPS}
	${CC} ${CFLAGS} ${OBJS} ${LIB} -o parser

%.o: %.cc
	${CC} ${CFLAGS} -c $<

cool-parse.cc: cool.y
	bison ${BFLAGS} cool.y

dotest:	parser good.cl bad.cl
	@echo "\nRunning parser on good.cl\n"
	-./myparser good.cl
	@echo "\nRunning parser on bad.cl\n"
	-./myparser bad.cl

${LIBS}:
	${CLASSDIR}/etc/mk-link-object ${ASSN} $@

# These dependencies allow you to get the starting files for
# the assignment.  They will not overwrite a file you already have.

${SRC}:
	-${CLASSDIR}/etc/copy-skel ${ASSN} ${SRC}

${LSRC}:
	-${CLASSDIR}/etc/link-shared ${ASSN} ${LSRC}

${TSRC} ${CSRC}:
	-ln -s ${CLASSDIR}/src/PA${ASSN}/$@ $@

${HSRC}:
	-ln -s ${CLASSDIR}/include/PA${ASSN}/$@ $@

submit-clean: ${OUTPUT}
	-rm -f *.s ${OBJS} ${CGEN} ${HGEN} ${DEPS} lexer parser *~

clean:
	-rm -f ${OUTPUT} *.s ${OBJS} ${CGEN} ${HGEN} ${DEPS} lexer parser *~

clean-compile:
	@-rm -f ${OBJS} ${CGEN} ${HGEN} ${DEPS}

%.d: %.cc cool-tree.handcode.h ${LSRC}
	${SHELL} -ec '${DEPEND} $< | sed '\''s/\($*\.o\)[ :]*/\1 $@ : /g'\'' > $@'

-include ${CSRC:.cc=.d}