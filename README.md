# malloc

This is a work-in-progress malloc library for MSX computers (or emulators) running MSX-DOS2 or [Nextor](https://github.com/Konamiman/Nextor).

The purpose is to implement a library to make it easier to manage mapped memory under MSX-DOS2 applications written in assembler.

**This is a work-in-progress. The code is not functional yet, and it is commited to this repository for code management.**

Source code in Z80 assembler provided.

## Build

This program is distributed in source code form, but the assembler (`AS.COM`) and linker (`LD.COM`) required to build it are included in the repository.

Both of these tools were developed by Egor Voznessenski. Sadly, he passed away a few years ago.

To build the binary, run the `MAKE.BAT` script. This will first assemble the assembly program into relocatable files. Theny it will link the relocatable files into the `APP.COM` binary and clean up temporary files left behind by the assembler and linker.

## License

Copyright 2022 Javier Lavandeira.

Released under the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) license. The source code is heavily commented in the hope that it will help others understand how memory works in MSX computers and to encourage the development of new tools and applications.