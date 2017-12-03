def _expand_items(items):
  return '\n'.join(items)

def _msb_project(info, *items):
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
        <ProjectGuid>"""+info.guid+"""</ProjectGuid>
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
              WorkingDirectory="{cwd}"
        />
      </Target>
  '''.format(label=str(info.target.label),
             outputs=';'.join([f.basename for f in info.target.files]),
             cwd=info.wsPath)

def _hexStr(v, lmin=0, lmax=40):
  HEX_DIGITS = '0123456789ABCDEF'
  s = ''
  v = int(v)
  for i in range(lmax):
    d = v % 0x10
    s += HEX_DIGITS[d]
    v /= 0x10
    if v == 0: break
  zeroes = max(0, lmin - len(s))
  # Prepend zeroes and reverse.
  return '0' * zeroes + s[::-1]

def _generate_uuid_from_data(data):
  # We don't comply with any UUID standard, but we use 3 to advertise that it is a deterministic
  # hash of a name. I don't think Visual Studio will complain about the method used to create our
  # one-way hash.
  # TODO: Actually use more bits.
  hsh = hash(data)
  return '{%s-0000-3000-A000-0000%s}' % (_hexStr(hash(data), lmin=8, lmax=8),
                                         _hexStr(hash(data[::-1]), lmin=8, lmax=8))

def _get_info(target, ctx):
  path = ctx.label.workspace_root
  if path: path = path + '/'
  path = path + ctx.label.package
  if path: path = path + '/'

  # Assume the user is opening the project from bazel-bin.
  binPath = '../' * path.count('/')
  wsPath = '../' * (path.count('/') + 1)

  guid = _generate_uuid_from_data(str(target))

  info = struct(target=target, ctx=ctx, path=path, wsPath=wsPath, binPath=binPath, guid=guid)
  return info

def _generate_msbuild_file(target, ctx):
  info = _get_info(target, ctx)
  project = ctx.actions.declare_file(target.label.name + '.vcxproj')
  content = _msb_project(info, _msb_props(info), _msb_files(info), _msb_targets(info))
  ctx.actions.write(project, content, is_executable=False)
  print(dir(ctx.configuration.bin_dir))
  return project, info.guid

def _sln_solution(info, deps, msbuild_info):
  return '''
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 15
VisualStudioVersion = 15.0.27004.2002
MinimumVisualStudioVersion = 10.0.40219.1
#Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "stage3_wizard_inplace", "stage3_wizard_inplace.vcxproj", "{5C6C586A-D090-4E78-9D16-BC69939BBEA0}"
#EndProject
''' + _sln_projects(info, deps, msbuild_info) + '''
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|x64 = Debug|x64
		Debug|x86 = Debug|x86
		Release|x64 = Release|x64
		Release|x86 = Release|x86
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Debug|x64.ActiveCfg = Debug|x64
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Debug|x64.Build.0 = Debug|x64
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Debug|x86.ActiveCfg = Debug|Win32
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Debug|x86.Build.0 = Debug|Win32
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Release|x64.ActiveCfg = Release|x64
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Release|x64.Build.0 = Release|x64
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Release|x86.ActiveCfg = Release|Win32
		#{5C6C586A-D090-4E78-9D16-BC69939BBEA0}.Release|x86.Build.0 = Release|Win32
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(ExtensibilityGlobals) = postSolution
		#SolutionGuid = {E53EC800-4964-4FE0-B76A-EC14DF2A16BA}
	EndGlobalSection
EndGlobal'''

MSBuildInfo = provider()  # TODO fields

def _sln_project(info, dep, msbuild_info):
    return (
        '''Project("{guid2}") = "{name}", "{binPath}/{package}/{name}.vcxproj", "{guid}"\nEndProject'''
        .format(guid=msbuild_info.guid, guid2=_generate_uuid_from_data(msbuild_info.guid),
                name=dep.label.name, binPath=info.binPath, package=dep.label.package))

def _sln_projects(info, deps, msbuild_info):
  # This first UUID appears to be an identifier for Visual C++ packages?
  return '\n'.join([_sln_project(info, dep, dep[MSBuildInfo]) for dep in deps] +
                   [_sln_project(info, info.target, msbuild_info)])

def _generate_sln_file(target, ctx, msbuild_info):
  info = _get_info(target, ctx)
  solution = ctx.actions.declare_file(target.label.name + '.sln')
  content = _sln_solution(info, ctx.rule.attr.deps, msbuild_info)
  ctx.actions.write(solution, content, is_executable=False)
  return solution

def _msbuild_aspect_impl(target, ctx):
  project, guid = _generate_msbuild_file(target, ctx)
  transitive_projects = depset([project])
  for dep in ctx.rule.attr.deps:
    transitive_projects += dep[MSBuildInfo].transitive_projects
  msbuild_info = MSBuildInfo(transitive_projects=transitive_projects, guid=guid)
  outputs = transitive_projects + [_generate_sln_file(target, ctx, msbuild_info)]
  return [msbuild_info,
          OutputGroupInfo(msbuild_outputs=outputs)]

msbuild_aspect = aspect(
    attr_aspects = ["deps"],
    implementation = _msbuild_aspect_impl,
)
