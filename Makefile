SRC = $(wildcard src/*.elm)
TARGET = build/elm.js

build: $(TARGET)

debug:
	@echo "Compiling Elm files... in debug mode!"
	elm make src/Main.elm --output $(TARGET) --debug

$(TARGET): $(SRC)
	@echo "Compiling Elm files..."
	elm make src/Main.elm --output $(TARGET)

clean:
	@echo "Cleaning up..."
	rm -f $(TARGET)

.PHONY: build clean debug
