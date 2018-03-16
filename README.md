# bazel-msbuild

Generate Visual Studio projects with bazel. The projects use bazel to do the actual building.

Currently this only works for C++.

## Prerequistes
- bazel
- Python 2 or 3

## Usage

```
$ git clone https://github.com/tmandry/bazel-msbuild.git

# Then, in your bazel project...
$ python /path/to/bazel-msbuild/generate.py //mypackage/...
$ start msbuild/myproject.sln
```

Where `//mypackage/...` is an optional Bazel query describing which packages you want to generate projects for. Generally, you want to use a package name, label name, or wildcard such as `//mypackage/...`, which means "mypackage and everything beneath it".

You can specify more than one query. If you specify no query, projects will be generated for ALL packages. Be careful on large repos!

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
