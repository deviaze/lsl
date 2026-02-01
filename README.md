# lsl

A pretty, multithreaded directory content lister sorted by date modified or file or (recursive) directory size.

## Why?

Whenever I download something and want to `zcp` or move it somewhere I tend to forget what it's named.

Or when I downloaded it.

Running `ls -l` gives a bunch of info I don't really need. I just want to know when I last used a file or directory,
and how big it is. Plus I don't want to remember all the options.

## Install

You need the [seal runtime](https://github.com/seal-runtime/seal) to run this Luau code. Put *seal* in your `$PATH`.

Copy `./lsl.luau` to somewhere in your `$PATH/lsl`. Or name it whatever you want.

Make it executable with `chmod +x wherever/lsl` or your operating system's equivalent.

## Usage

By default, `lsl` lists directories by last modified, and computes directory size recursively. The directory
being listed should be your `cwd` unless you override it by passing `--path | -p <directory>`.

### Named arguments

- `--path` or `-p` to override the directory being listed.
- `--match` or -m` to pass a Luau string matching pattern to filter entries against.
- `--limit` or `-l` if you only want to see the first `n` results

### Flags

- `--size` or `-s` to sort by size instead of date modified.
- `--norec` or `-nr` if you don't want to compute directory size recursively (you only care about date modified).
- `--date` or `-d` if you want to see the actual date/time modified instead of `n <timeunit> ago`.

## Examples

`lsl -p /home/username/Downloads -l 5`

## Building

1. Run `seal compile -o lsl.luau`
2. Make sure it got bundled correctly/no syntax errors.
3. Put `#!/usr/bin/env seal` on top of `lsl.luau`
4. `cp ./lsl.luau lsl`
5. Make it executable `chmod +x ./lsl`
6. Move `./lsl` to your `$PATH`.
