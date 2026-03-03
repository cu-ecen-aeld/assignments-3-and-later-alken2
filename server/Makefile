# The following Makefile is entirely attributed to Piyush Nagpal 
# (https://github.com/cu-ecen-aeld/assignments-3-and-later-its-me-piyush/blob/main/server/Makefile)

CC ?= $(CROSS_COMPILE)gcc
CFLAGS ?= -Wall -Werror -Wextra -O0 -g
LDFLAGS ?=
TARGET ?= aesdsocket
SRC := aesdsocket.c
OBJ := $(SRC:.c=.o)

all default: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJ)