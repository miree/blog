CFLAGS = `pkg-config gtk4 --cflags`
LDFLAGS = `pkg-config gtk4 --libs`

all: gtkapp

run: gtkapp
	GSK_RENDERER=cairo ./gtkapp	

%.i: %.c
	gcc $(CFLAGS) -E $< > $@

gtkapp: gtkapp.d gtk4.d gtk4_import.i 
	gdc $(CFLAGS) -o $@ $+ $(LDFLAGS)

clean:
	rm -f *.i *.o gtkapp	

