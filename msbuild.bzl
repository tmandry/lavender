def _expand_items(items):
  return '\n'.join(items)

def _msb_project(*items):
  return ("""<?xml version="1.0" encoding="utf-8"?>
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
        <!-- Removed: ProjectGuid -->
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
  """ +
  _expand_items(items) +
  """
      <ImportGroup Label="ExtensionTargets">
      </ImportGroup>
    </Project>
  """)

def _msb_props(info):
  print(info.ctx.bin_dir.path)
  return ('''
      <PropertyGroup>
      </PropertyGroup>
  ''')

def _msb_cc_src(info, file):
  print(file)
  return '<ClCompile Include="{wspath}{name}" />'.format(wspath=info.wsPath, name=file.path)

def _msb_cc_inc(info, file):
  print(file)
  return '<ClInclude Include="{wspath}{name}" />'.format(wspath=info.wsPath, name=file.path)

def _msb_item_group(info, attrs, attr_name, func):
  file_targets = getattr(attrs, attr_name, None)
  if not file_targets:
    return ''
  return ('''
      <ItemGroup>
''' + '''
        '''.join([func(info, f) for t in file_targets for f in t.files]) +
      '''
      </ItemGroup>
      ''')

def _msb_files(info):
  return (
      _msb_item_group(info, info.ctx.rule.attr, 'srcs', _msb_cc_src) +
      _msb_item_group(info, info.ctx.rule.attr, 'hdrs', _msb_cc_inc))

def _msb_targets(info):
  print([f.basename for f in info.target.files])
  return '''
      <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />

      <!-- TODO -->
      <Target Name="Build">
        <Exec Command="bazel build {label}"
              Outputs="{outputs}"
        />
      </Target>
  '''.format(label=str(info.target.label),
             outputs=';'.join([f.basename for f in info.target.files]))

def _generate_msbuild_file(target, ctx):
  path = ctx.label.workspace_root
  if path: path = path + '/'
  path = path + ctx.label.package
  if path: path = path + '/'

  # Assume the user is opening the project from bazel-bin.
  wsPath = '../' * (path.count('/') + 1)

  info = struct(target=target, ctx=ctx, path=path, wsPath=wsPath)

  project = ctx.actions.declare_file(target.label.name + '.vcxproj')
  content = _msb_project(_msb_props(info), _msb_files(info), _msb_targets(info))
  ctx.actions.write(project, content, is_executable=False)
  print(dir(ctx.configuration.bin_dir))
  return project

def _msbuild_aspect_impl(target, ctx):
  outputs = depset([_generate_msbuild_file(target, ctx)])
  for dep in ctx.rule.attr.deps:
    outputs += dep[OutputGroupInfo].msbuild_outputs
  return [OutputGroupInfo(msbuild_outputs=outputs)]

msbuild_aspect = aspect(
    attr_aspects = ["deps"],
    implementation = _msbuild_aspect_impl,
)
