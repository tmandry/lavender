"""Generates Visual Studio project files."""

from __future__ import division, print_function, unicode_literals
import argparse
import re
import sys
import os
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

class Label:
    PATTERN = re.compile(r'((@[a-zA-Z0-9/._-]+)?//)?([a-zA-Z0-9/._-]*)(:([a-zA-Z0-9_/.+=,@~-]+))?$')

    def __init__(self, name):
        match = re.match(Label.PATTERN, name)
        if not match:
            raise ValueError("Invalid label: " + name)
        self.repo = match[2] or None
        self._absolute = True if match[1] else False
        self.package = match[3]
        self.name = match[5] or self.package.split('/')[-1]

    @property
    def info_path(self):
        """Path to the msbuild info file for this label, relative to the bin path."""
        if self.repo:
            raise NotImplementedError("External repos")
        # TODO: absolute
        return os.path.join(self.package, self.name+'.msbuild')

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

def _sln_project(project):
    # This first UUID appears to be an identifier for Visual C++ packages?
    return (
        'Project("{guid2}") = "{name}", "{package}/{name}.vcxproj", "{guid}"\nEndProject'
        .format(guid=project.guid, guid2=_generate_uuid_from_data(project.guid),
                name=project.label.name, package=project.label.package))

def _sln_projects(projects):
    return '\n'.join([_sln_project(project) for project in projects])

def _generate_uuid_from_data(data):
    # We don't comply with any UUID standard, but we use 3 to advertise that it is a deterministic
    # hash of a name. I don't think Visual Studio will complain about the method used to create our
    # one-way hash.
    # TODO: Actually use more bits.
    hsh = hash(data)
    part1 = hsh // (2**32)
    part2 = hsh % (2**32)
    return '{{{:08X}-0000-3000-A000-0000{:08X}}}'.format(part1, part2)

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

    print()

    with open(os.path.join(SCRIPT_DIR, 'templates', 'solution.sln')) as f:
        template = f.read()
    content = template.format(projects=_sln_projects([info]))
    print(content)

if __name__ == '__main__':
    main(sys.argv)
