{
  kernel,
  kernelModuleMakeFlags,

  lib,
  stdenv,

  src,
}:

stdenv.mkDerivation
  {
    pname = "${kernel.name}_module-ltr30x";
    version = "0.1";

    inherit src;

    sourceRoot = "modules/ltr30x";
    hardeningDisable = [ "pic" "format" ];
    nativeBuildInputs = kernel.moduleBuildDependencies;

    makeFlags =
      kernelModuleMakeFlags
    ++
      [
        "KVERSION=${kernel.modDirVersion}"
        "INSTALL_MOD_PATH=$(out)"
      ];

    meta =
      {
        homepage = "https://github.com/Seeed-Studio/seeed-linux-dtoverlays/blob/fe6b8c8dfddd3c63f39f895e8a49f4612340a3fe/modules/ltr30x";
        platforms = lib.platforms.linux;

        # The base repo is licensed as GPL2, inherited from the Linux Kernel.
        #
        # `Makefile` is licensed MIT by Zhangqun Ming at Seeed Studio.
        # I would think that the `dkms.conf` was also intended be licensed MIT,
        # but because it lacks an explicit license notice, we must assume the
        # repo-wide license is applied (GPL2).
        #
        # `ltr30x.c` is licensed GPL2 by [Peter Meerwald](https://pmeerw.net/),
        # at the time employed by [BCT Electronic](https://www.bctelectronic.com/).
        license = [ lib.licenses.gpl2 lib.licenses.mit ];
      };
  }
