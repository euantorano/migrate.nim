NIM=nim

all: windows linux

windows: migrate.nim
	$(NIM) --os:windows --cpu:amd64 --gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-gcc -d:release -o=release/migrate_win64 c migrate.nim
	$(NIM) --os:windows --cpu:i386 --gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-gcc -d:release -o=release/migrate_win32 c migrate.nim

linux: migrate.nim
	$(NIM) --cpu:i386 --passC:-m32 --passL:-m32 -d:release -o=release/migrate_linux_x86 c migrate.nim
	$(NIM) --cpu:amd64 --passC:-Iglibc-hack -d:release -o=release/migrate_linux_x86_64 c migrate.nim

clean:
	rm -Rf release/
