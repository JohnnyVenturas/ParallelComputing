SRC_DIR=src
HEADER_DIR=include
OBJ_DIR=obj

CC=gcc
CFLAGS=-O3 -I$(HEADER_DIR)
LDFLAGS=-lm

SRC= dgif_lib.c \
	egif_lib.c \
	gif_err.c \
	gif_font.c \
	gif_hash.c \
	gifalloc.c \
	main.c \
	main_mpi.c \
	openbsd-reallocarray.c \
	quantize.c

OBJ_COMMON= $(OBJ_DIR)/dgif_lib.o \
	$(OBJ_DIR)/egif_lib.o \
	$(OBJ_DIR)/gif_err.o \
	$(OBJ_DIR)/gif_font.o \
	$(OBJ_DIR)/gif_hash.o \
	$(OBJ_DIR)/gifalloc.o \
	$(OBJ_DIR)/openbsd-reallocarray.o \
	$(OBJ_DIR)/quantize.o

OBJ_MAIN=$(OBJ_COMMON) $(OBJ_DIR)/main.o
OBJ_MAIN_MPI=$(OBJ_COMMON) $(OBJ_DIR)/main_mpi.o

all: $(OBJ_DIR) sobelf sobelf_mpi

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c -o $@ $^

sobelf: $(OBJ_MAIN)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

sobelf_mpi: $(OBJ_MAIN_MPI)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f sobelf sobelf2 $(OBJ_DIR)/*.o

