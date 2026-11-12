{
  lib,
  stdenvNoCC,
  writers,
  python3,
}:
let
  writeOverlays = writers.writeJSON "overlays.json";
in
  lib.makeOverridable ({ base, overlays }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      name = "device-tree-overlays";
      src = builtins.filterSource (
        path: type: !(builtins.elem (baseNameOf path) [
          "default.nix"
        ])
      ) ./.;
      nativeBuildInputs = [
        (python3.pythonOnBuildForHost.withPackages (ps:
          with ps; [ libfdt pyaml jsonschema ]
        ))
      ];
      phases = [ "buildPhase" ];
      buildPhase = /* bash */ ''
        python $src/apply_overlays.py \
          --source ${base} \
          --destination $out \
          --overlays ${finalAttrs.passthru.inputs.overlays}
      '';
      passthru.inputs.overlays = writeOverlays overlays;
    })
  )
