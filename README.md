# bazel-msbuild

Generate Visual Studio projects with bazel. The projects use bazel to do the actual building.

Currently this only works for C++.

## Prerequistes
- bazel
- Python 2 or 3

## Usage

```
$ cd myproject
$ python /path/to/bazel-msbuild/generate.py //mypackage/...
$ start msbuild/myproject.sln
```
