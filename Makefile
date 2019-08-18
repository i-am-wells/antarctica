CC=gcc

CFLAGS=-std=c99 -O0 -g -Wall `sdl2-config --cflags` -Isrc -fpic

LIBS=-llua -lSDL2_image -lSDL2_mixer `sdl2-config --libs`

OBJS=src/tilemap_bridge.o \
		 src/sound_bridge.o \
		 src/engine_bridge.o \
		 src/image_bridge.o \
		 src/object_bridge.o \
		 src/lua_helpers.o \
		 src/engine.o \
		 src/image.o \
		 src/sound.o \
		 src/tilemap.o \
		 src/antarctica.o \
		 src/luaarg.o \
		 src/vec.o \
		 src/object.o

all: antarctica.so

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

antarctica.so: $(OBJS)
	$(CC) --shared $(LIBS) $(OBJS) -o antarctica.so

clean:
	-rm -rf src/*.o antarctica.so
