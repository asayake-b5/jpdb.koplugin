compile:
    fennel --compile main.fnl > main.lua
compileall:
    for file in *.fnl; do fennel --compile $file > $(basename $file .fnl).lua; done
