using BinDeps

@BinDeps.setup

libasl = library_dependency("libasl")

# General settings.
so = "so"
all_load = "--whole-archive"
noall_load = "--no-whole-archive"

@static if Base.Sys.isapple()
  so = "dylib"
  all_load = "-all_load"
  noall_load = "-noall_load"
end

@static if Base.Sys.iswindows()
  so = "dll"
  push!(BinDeps.defaults, BinDeps.BuildProcess)
end

extra_cflags = ""
@static if Base.Sys.isfreebsd()
  extra_cflags = "-DS_IFREG=S_ISREG -DS_IFDIR=S_ISDIR"
end

provides(Sources,
         URI("http://netlib.org/ampl/solvers.tgz"),
         libasl,
         unpacked_dir="solvers")

depsdir = BinDeps.depsdir(libasl)
rcdir = joinpath(depsdir, "rc")
prefix = joinpath(depsdir, "usr")
libdir = joinpath(prefix, "lib")
srcdir = joinpath(depsdir, "src", "solvers")
aslinterface_src = joinpath(rcdir, "aslinterface.cc")
makefile_mingw = joinpath(rcdir, "makefile.mingw")
arith_mingw = joinpath(rcdir, "arith$(Sys.WORD_SIZE).h")

provides(SimpleBuild,
         (@build_steps begin
            GetSources(libasl)
            CreateDirectory(libdir)
            (@build_steps begin
              ChangeDirectory(srcdir)
              (@build_steps begin
                `make -f makefile.u CC=gcc CFLAGS="-O -fPIC $extra_cflags"`
                `g++ -fPIC -shared -I$srcdir -I$rcdir $aslinterface_src -Wl,$all_load amplsolver.a -Wl,$noall_load -o libasl.$so`
                `mv libasl.$so $libdir`
              end)
            end)
          end), libasl, os = :Unix)

provides(SimpleBuild,
         (@build_steps begin
            GetSources(libasl)
            CreateDirectory(libdir)
            (@build_steps begin
              ChangeDirectory(srcdir)
              (@build_steps begin
                `cp $arith_mingw arith.h`
                `cp details.c0 details.c`
                `mingw32-make -f $makefile_mingw CC=gcc CFLAGS="-O -fPIC"`
                `g++ -fPIC -shared -I$srcdir -I$rcdir $aslinterface_src -Wl,$all_load amplsolver.a -Wl,$noall_load -o libasl.$so`
                `mv libasl.$so $libdir`
              end)
            end)
          end), libasl, os = :Windows)

@BinDeps.install Dict(:libasl => :libasl)
