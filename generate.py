"""Generates Visual Studio project files."""

from __future__ import division, print_function, unicode_literals
import argparse
import re
import sys
import os
import json

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

def _msb_project(info, *items):
    return r'''<?xml version="1.0" encoding="utf-8"?>
    <Project DefaultTargets="Build" ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

      <ItemGroup Label="ProjectConfigurations">
        <ProjectConfiguration Include="Debug|Win32">
          <Configuration>Debug</Configuration>
          <Platform>Win32</Platform>
        </ProjectConfiguration>
        <ProjectConfiguration Include="Release|Win32">
          <Configuration>Release</Configuration>
          <Platform>Win32</Platform>
        </ProjectConfiguration>
        <ProjectConfiguration Include="Debug|x64">
          <Configuration>Debug</Configuration>
          <Platform>x64</Platform>
        </ProjectConfiguration>
        <ProjectConfiguration Include="Release|x64">
          <Configuration>Release</Configuration>
          <Platform>x64</Platform>
        </ProjectConfiguration>
      </ItemGroup>

      <PropertyGroup Label="Globals">
        <VCProjectVersion>15.0</VCProjectVersion>
        <ProjectGuid>''' + info.guid + r'''</ProjectGuid>
        <Keyword>MakeFileProj</Keyword>
      </PropertyGroup>

      <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />

      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'" Label="Configuration">
        <ConfigurationType>Makefile</ConfigurationType>
        <UseDebugLibraries>true</UseDebugLibraries>
        <PlatformToolset>v141</PlatformToolset>
      </PropertyGroup>
      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Win32'" Label="Configuration">
        <ConfigurationType>Makefile</ConfigurationType>
        <UseDebugLibraries>false</UseDebugLibraries>
        <PlatformToolset>v141</PlatformToolset>
      </PropertyGroup>
      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|x64'" Label="Configuration">
        <ConfigurationType>Application</ConfigurationType>
        <UseDebugLibraries>true</UseDebugLibraries>
        <PlatformToolset>v141</PlatformToolset>
      </PropertyGroup>
      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'" Label="Configuration">
        <ConfigurationType>Application</ConfigurationType>
        <UseDebugLibraries>false</UseDebugLibraries>
        <PlatformToolset>v141</PlatformToolset>
      </PropertyGroup>
      <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />

      <ImportGroup Label="ExtensionSettings">
      </ImportGroup>
      <ImportGroup Label="Shared">
      </ImportGroup>

      <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
        <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
      </ImportGroup>
      <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Release|Win32'">
        <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
      </ImportGroup>
      <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
        <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
      </ImportGroup>
      <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
        <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
      </ImportGroup>

      <PropertyGroup Label="UserMacros" />
      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
        <NMakePreprocessorDefinitions>WIN32;_DEBUG;$(NMakePreprocessorDefinitions)</NMakePreprocessorDefinitions>
      </PropertyGroup>
      <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Win32'">
        <NMakePreprocessorDefinitions>WIN32;NDEBUG;$(NMakePreprocessorDefinitions)</NMakePreprocessorDefinitions>
      </PropertyGroup>

      <ItemDefinitionGroup>
      </ItemDefinitionGroup>
''' + '\n'.join(items) + '''
      <ImportGroup Label="ExtensionTargets">
      </ImportGroup>
    </Project>
'''

def _msb_props(info):
    return '''
      <PropertyGroup>
      </PropertyGroup>
    '''

def _msb_cc_src(info, filename):
    return '<ClCompile Include="{wspath}{name}" />'.format(wspath=info.ws_path, name=filename)

def _msb_cc_inc(info, filename):
    return '<ClInclude Include="{wspath}{name}" />'.format(wspath=info.ws_path, name=filename)

def _msb_item_group(info, file_targets, func):
    if not file_targets:
        return ''
    return '''
      <ItemGroup>
        ''' + '''
        '''.join([func(info, f) for f in file_targets]) + '''
      </ItemGroup>
      '''

def _msb_files(info):
    return (
        _msb_item_group(info, info.srcs, _msb_cc_src) +
        _msb_item_group(info, info.hdrs, _msb_cc_inc))

def _msb_targets(info):
    return r'''
      <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />

      <Target Name="Build">
        <Exec Command="bazel build {label}"
              Outputs="{outputs}"
              WorkingDirectory="{cwd}" />
      </Target>
    '''.format(label=str(info.target.label),
               outputs=';'.join([os.path.basename(f) for f in info.target.files]),
               cwd=info.ws_path)

def main(argv):
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Generates Visual Studio project files from Bazel projects.")
    parser.add_argument("target", help="Target to generate project for")
    args = parser.parse_args(argv[1:])

    info = read_info(Label(args.target))
    content = _msb_project(info, _msb_props(info), _msb_files(info), _msb_targets(info))
    print(content)

if __name__ == '__main__':
    main(sys.argv)
