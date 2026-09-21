final: prev: {
  # v1.0.93 ships a stale NuGet lockfile with duplicate SDK packages.
  buildDotnetModule =
    args:
    prev.buildDotnetModule (
      args
      // prev.lib.optionalAttrs ((args.pname or "") == "ghelper") {
        nugetDeps = map (
          dep:
          let
            package = prev.dotnetCorePackages.fetchNupkg dep;
          in
          if dep.pname == "SkiaSharp.NativeAssets.Linux" then
            package.overrideAttrs (old: {
              # SkiaSharp 4 additionally links against libstdc++.
              buildInputs = (old.buildInputs or [ ]) ++ [ prev.stdenv.cc.cc.lib ];
            })
          else
            package
        ) (builtins.fromJSON (builtins.readFile ./deps.json));

        # Install the native libraries matching the resolved managed
        # assemblies, rather than the first transitive version found.
        postInstall =
          builtins.replaceStrings
            [
              "libSkiaSharp.so:skiasharp.nativeassets.linux"
              "libHarfBuzzSharp.so:harfbuzzsharp.nativeassets.linux"
              "*/$pkg_name/*/runtimes"
            ]
            [
              "libSkiaSharp.so:skiasharp.nativeassets.linux/4.148.0"
              "libHarfBuzzSharp.so:harfbuzzsharp.nativeassets.linux/14.2.0"
              "*/$pkg_name/runtimes"
            ]
            args.postInstall;
      }
    );
}
