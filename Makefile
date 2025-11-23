# Simple Makefile for Marbles
# No build system complexity - just compile and link

CC = gcc
CXX = g++
CFLAGS = -std=c11 -Wall -Wextra -O2
CXXFLAGS = -std=c++17 -Wall -Wextra -O2

# Libraries
LIBS = -lglfw -lvulkan -lode -lm -ldl -lpthread

# Source files
SRCS = src/main.cpp
OBJS = $(SRCS:.cpp=.o)

# Output
TARGET = marbles

# Build
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
