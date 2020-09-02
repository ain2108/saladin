# Optimized Arbiter Verilog Implementation

## Quickstart

### Install Icarus Verilog
For MacOS:
```bash
brew install icarus-verilog
```

### Install gtkwave

For MacOS:
```bash

# Install gtkwave
brew tap homebrew/cask
brew cask install gtkwave

# Perl Switch
cpan install Switch
perl -V:'installsitelib'
sudo cp /usr/local/Cellar/perl/5.*/lib/perl5/site_perl/5.*/Switch.pm /Library/Perl/5.*/
```

### Run Testbench

Run unit tests:
```bash
make test
```

Compile SystemVerilog:
```bash
iverilog -g2005-sv -o sim -c modules.txt -s <module_name>
```

Run the simulation:
```bash
vvp sim -lxt2
```

See the waveforms:
```bash
gtkwave test.vcd
```
