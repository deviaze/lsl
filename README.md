# lsl

A pretty, multithreaded directory content lister sorted by date modified or file or (recursive) directory size.

Directory sizes are computed in parallel and cached by modify time (mtime) to `~/.cache/lsl/sizes.json`, so repeated runs on the same directory are near-instant. Inaccessible subdirectories are skipped and reported as approximate (`~42.3 MB`) rather than erroring out.

<!-- markdownlint-disable MD033 -->
<img width="640" height="700" alt="lsl listing screenshot with big directory" src="https://github.com/user-attachments/assets/aad4a839-7c9f-4177-a0cb-a096af247e2f" />
<!-- markdownlint-enable MD033 -->

## Why?

Whenever I download something and want to `zcp` or move it somewhere I tend to forget what it's named.

Or when I downloaded it.

Running `ls -l` gives a bunch of info I don't really need. I just want to know when I last used a file or directory,
and how big it is. Plus I don't want to remember all the options.

## Install

You need the [seal runtime](https://github.com/seal-runtime/seal) to run this Luau code. Put *seal* in your `$PATH`.

Run the build script `seal .seal/build.luau`. By default it installs to `~/.local/bin/lsl`, but you can override the destination by setting the `DIRECTORY_LISTER_LSL_BIN_LOCATION` environment variable. The script will prompt before overwriting an existing binary.

## Usage

By default, `lsl` lists directories by last modified, and computes directory size recursively. The directory
being listed should be your `cwd` unless you override it by passing `--path | -p <directory>`.

### Named arguments

- `--path` or `-p` to override the directory being listed.
- `--match` or `-m` to pass a Luau string matching pattern to filter entries against.
- `--limit` or `-l` if you only want to see the first `n` results.
- `--timeout` or `-t` so it doesn't take forever with huge nested directories. Defaults to 2.5 seconds.

### Flags

- `--size` or `-s` to sort by size instead of date modified.
- `--norec` or `-nr` if you don't want to compute directory size recursively (you only care about date modified).
- `--date` or `-d` if you want to see the actual date/time modified instead of `n <timeunit> ago`.

## Examples

`lsl -p /home/username/Downloads -l 5`

## Building

- Run `seal .seal/build.luau`. Set `DIRECTORY_LISTER_LSL_BIN_LOCATION` to install somewhere other than `~/.local/bin/lsl`.
