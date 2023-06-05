compile:
    for file in *.fnl; do fennel --compile $file > $(basename $file .fnl).lua; done
