"""Generates Visual Studio project files."""

from __future__ import division, print_function, unicode_literals
import argparse
import re
import sys
import os
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

class Label:
    def __init__(self, name):
        match = re.match(r'((@[\w_-]+)?//)?([\w/_-]*)(:([\w_-]+))?$', name)
        if not match:
            raise ValueError("Invalid label: " + name)
        self._repo = match[2] or None
        self._absolute = True if match[1] else False
        self._pkg = match[3]
        self._target = match[5] or self._pkg.split('/')[-1]

    @property
    def info_path(self):
        """Path to the msbuild info file for this label, relative to the bin path."""
        if self._repo:
            raise NotImplementedError("External repos")
        # TODO: absolute
        return os.path.join(self._pkg, self._target+'.msbuild')

class Struct:
    pass

class ProjectInfo:
    def __init__(self, label, info_dict):
        self.label = label
        self.ws_path = info_dict['workspace_root']
        self.srcs = info_dict['files']['srcs']
        self.hdrs = info_dict['files']['hdrs']
        self.target = Struct()
        self.target.label = info_dict['target']['label']
        self.target.files = info_dict['target']['files']
        self.guid = 'TODO-GUID'

def bin_path():
    return 'bazel-bin'

def run_aspect(target):
    """Invokes bazel on our aspect to generate target info."""
    pass

def read_info(target):
    """Reads the generated msbuild info file for the given target."""
    info_dict = json.load(open(os.path.join(bin_path(), target.info_path)))
    return ProjectInfo(target, info_dict)

def _msb_cc_src(info, filename):
    return '<ClCompile Include="{wspath}{name}" />'.format(wspath=info.ws_path, name=filename)

def _msb_cc_inc(info, filename):
    return '<ClInclude Include="{wspath}{name}" />'.format(wspath=info.ws_path, name=filename)

def _msb_item_group(info, file_targets, func):
    if not file_targets:
        return ''
    return (
        '\n  <ItemGroup>' +
        '\n    '.join([''] + [func(info, f) for f in file_targets]) +
        '\n  </ItemGroup>'
    )

def _msb_files(info):
    return (
        _msb_item_group(info, info.srcs, _msb_cc_src) +
        _msb_item_group(info, info.hdrs, _msb_cc_inc))

def main(argv):
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Generates Visual Studio project files from Bazel projects.")
    parser.add_argument("target", help="Target to generate project for")
    args = parser.parse_args(argv[1:])

    info = read_info(Label(args.target))
    with open(os.path.join(SCRIPT_DIR, 'templates', 'vcxproj.xml')) as f:
        template = f.read()
    content = template.format(
        info=info,
        label=str(info.target.label),
        outputs=';'.join([os.path.basename(f) for f in info.target.files]),
        file_groups=_msb_files(info))
    print(content)

if __name__ == '__main__':
    main(sys.argv)
