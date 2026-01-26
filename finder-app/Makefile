# Author: Kenneth Alcineus
# Attributed to https://makefiletutorial.com/

CC = $(CROSS_COMPILE)gcc

writer: writer.o
	cc writer.o -o writer # Second step

writer.o: writer.c
	cc -c writer.c -o writer.o # First step

clean:
	rm -f writer.o writer