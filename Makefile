CC=gcc

CFLAGS=-std=c99 -O0 -g -Wall `sdl2-config --cflags` -Iinclude

LIBS=-llua -lSDL2_image -lSDL2_mixer `sdl2-config --libs`

OBJS=src/main.o src/engine.o src/image.o src/sound.o src/tilemap.o src/lantarcticalib.o src/luaarg.o src/vec.o src/object.o

all: antarctica

docs: all
	doxygen


%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

antarctica: $(OBJS)
	$(CC) $(LIBS) $(OBJS) -o antarctica

clean:
	-rm -rf src/*.o antarctica
