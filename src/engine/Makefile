CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O3 -march=native -flto
LDFLAGS = -lpthread -lcurl

TARGET = netraven_engine
SRC = netraven_engine.cpp
HDR = netraven_engine.h

all: $(TARGET)

$(TARGET): $(SRC) $(HDR)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/
	chmod +x /usr/local/bin/$(TARGET)

.PHONY: all clean install