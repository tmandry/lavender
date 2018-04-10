# bazel-msbuild

Generate Visual Studio projects with bazel. The projects use bazel to do the actual building.

Currently this only works for C++.

## Prerequistes
- bazel
- Python 2 or 3

## Getting started

Run this in your normal development environment (MSYS bash, cmd.exe, or PowerShell):
```
$ git clone https://github.com/tmandry/bazel-msbuild.git

# Then, in your bazel project...
$ python /path/to/bazel-msbuild/generate.py //mypackage/...

$ start msbuild/myproject.sln
```
Where `//mypackage/...` is an optional Bazel query describing which packages you want to generate projects for. Generally, you want to use a package name, label name, or wildcard such as `//mypackage/...`, which means "mypackage and everything beneath it".

You can specify more than one query. If you specify no query, projects will be generated for ALL packages. Be careful on large repos!

### Environment
The environment you start Visual Studio from affects how Bazel is configured. Make sure this environment is configured according to the [Using Bazel on Windows](https://docs.bazel.build/versions/master/windows.html) docs.

If your environment settings are different between Visual Studio and your terminal, you might end up talking to two different Bazel servers. If you're experiencing problems when launching Visual Studio from explorer, try launching from your terminal, or vice versa.
I hope to improve documentation around this eventually; please report any difficulty you have by opening an issue.

### Debugging

Full C++ debugging is supported.

However, when debugging, Visual Studio will open up source file names built into the binary that are symlinks to the original source. This can be confusing, because you will have two copies of the same file open. Making a change to one may cause Visual Studio to prompt you about changes made to the other tab. It is best to check "Always reload files when there are no unsaved changes", so that this becomes less annoying.

## Usage
```
usage: generate.py [-h] [--output OUTPUT] [--solution SOLUTION]
                   [--config CONFIG]
                   [query [query ...]]

Generates Visual Studio project files from Bazel projects.

positional arguments:
  query                 Target query to generate project for [default: all
                        targets]

optional arguments:
  -h, --help            show this help message and exit
  --output OUTPUT, -o OUTPUT
                        Output directory
  --solution SOLUTION, -n SOLUTION
                        Solution name [default: current directory name]
  --config CONFIG       Additional --config option to pass to bazel; may be
                        used multiple times
```
