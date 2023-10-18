# horizons_query

A simple bash script to query NASA's JPL/Horizons system.

## Description

The goal of this script to help query the JPL/Horizons system in a scriptable way, when someone has tens or hundreds of targets, or epochs.
The recommended usage is to do queries en masse, and not for only one or two targets, but naturally it can be used for that, too.
The script depends on the [Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html) and the [Horizons File API](https://ssd-api.jpl.nasa.gov/doc/horizons_file.html).

## Installation

```shell
$ git clone https://github.com/rszakats/horizons_query
$ cd horizons_query
$ ./horizons_query.sh --help
```
From the horizons_query folder the script can be linked or copied to a different directory, which is in the **$PATH** variable to make it available system wide.

## Requirements

- `bash`
- `awk`
- `grep`
- `curl`
- `wget`
- `wc`
- Internet connection.

## Features

- Usable in three modes: File API mode, command line arguments mode, or hybrid command line arguments + input file mode.
- Offers the EPHEM_TYPE='OBSERVER', EPHEM_TYPE='VECTORS', EPHEM_TYPE='ELEMENTS' functionality.
- Can be scriptable, or put in a for loop, etc.
<!-- ## Screenshots -->
## Usage

Get the help message:
```shell
$ ./horizons_query.sh --help
```
Script specific arguments:

- --wdir: &nbsp; Define the directory where the input file expected and the output file(s) will be written.
                  If not specified, the script's current directory will be set.
- --infile: &nbsp;    Input file name for the File API mode or for the hybrid Horizons API mode.
                  Path is relative to \<wdir\>.

- --outfile:&nbsp; Desired output file name for the query result.
                  Path is relative to \<wdir\>.

- --usefileapi: &nbsp;Use the File API mode, see below.

- --printarguments: &nbsp; Prints the available arguments for the Horizons API mode.

- --verbose: &nbsp; Use verbose mode. More text output in the terminal.

- --help: &nbsp; Displays help message.

   
The script can be used in three modes:

- Using the File API.
- Using the Horizons API, via command line arguments.
- Using the Horizons API, via command line arguments and an input file.

### Using the FILE API

It can be turned on via the --usefileapi option.

In this case only the script specific arguments will be passed.
An input file is required, which follows the File API format, described [here](https://ssd-api.jpl.nasa.gov/doc/horizons_file.html).

File API example:
```shell
$ ./horizons_query.sh --wdir=/data/ --infile=my_input_file.txt --outfile=results.csv --usefileapi
```
Where my_input_file.txt contains the following:
```
!$$SOF
COMMAND='Eris;'
OBJ_DATA='YES'
MAKE_EPHEM='YES'
TABLE_TYPE='OBSERVER'
CENTER='500@399'
START_TIME='2006-01-01'
STOP_TIME='2006-01-20'
STEP_SIZE='1 d'
QUANTITIES='1,9,20,23,24,29'
CSV_FORMAT='YES'"
```
### Using the Horizons API

The script can accept command line arguments which were derived from
the original query parameter names. **The argument names were made
the following way: all uppercase letter became lowercase, and all
underscores were removed.** E.g.: STEP_SIZE -> stepsize"<br>
To list the available command line arguments:
```shell
./horizons_query.sh --printarguments
```
The official API documentation is available [here](https://ssd-api.jpl.nasa.gov/doc/horizons.html)<br>
Two parameters are fixed: OBJ_DATA='YES' and MAKE_EPHEM='YES".<br>
Example usage:
```shell
./horizons_query.sh --command='Psyche;' --ephemtype=observer --tlist='2460115.875 2460115.975' --center='500@-486' --format=text --calformat=both --wdir=/data/ --angformat=DEG
```

### Using the Horizons API with input file.

In this hybrid form the script can be used to get arguments and parameter values from a file.
You can still specify arguments in the command line, but in case of
duplication, it will be overwritten from the file.<br>
Typical use case is when someone has multiple different targets
for the query, or when some parameteres can change from target to target.<br>
Example usage:
```shell
./horizons_query.sh --ephemtype=observer --format=text --calformat=both --wdir=/data/ --angformat=DEG --infile=test_input.csv
```
Where test_input.csv contains the following:<br>
```
command,center,tlist
1;,500@-486,2460115.875 2460115.975
5;,500@-48,2460171.977211 2460234.9166
19;,561,2460101.977211 2460204.9166
```
In this case the input file is expected in csv format, and must
contain a header line. The header keywords must be the argument names,
e.g.: center, sitecoord, rangeunits, etc. See
```shell
./horizons_query.sh --printarguments
```
for all options.

## Limitations

- The script probably works for EPHEM_TYPE='APPROACH', but it was never tested.
- It is not capable for SPK file generation yet.
- Does not check if the TLIST is above the limit.
- Does not check if an argument has a valid value or not.
- Does not fully check if the input file is properly formatted.
- Output is hardwired to csv. No JSON support is available.
- Verbose mode is not yet fully implemented.

<!-- ## Known problems -->
## Author

@author: R. Szakáts, [Konkoly Observatory](https://konkoly.hu/en), 2023

## Credits

- [NASA JPL](https://ssd-api.jpl.nasa.gov/about/)

## License

This software is licensed under the [GNU GPL-3.0](LICENSE) License.

