# Author: Kenneth Alcineus
# Attributed to https://makefiletutorial.com/

CC = $(CROSS_COMPILE)gcc

default: writer.o
	$(CC) writer.o -o writer # Second step

writer.o: writer.c
	$(CC) -c writer.c -o writer.o # First step

clean:
	rm -f writer.o writer