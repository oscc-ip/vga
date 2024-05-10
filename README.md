# VGA

## Features
* VGA and LCD mode support
* RGB332, RGB444, RGB555 and RGB565 color modes
* Programmable video timing
* Programmable burst length
* Programmable frame buffer switch
* Static synchronous design
* Full synthesizable

FULL vision of datatsheet can be found in [datasheet.md](./doc/datasheet.md).

## Build and Test
```bash
make comp    # compile code with vcs
make run     # compile and run test with vcs
make wave    # open fsdb format waveform with verdi
```