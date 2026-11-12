# build dts file for the raspberry pi
{
  lib,
  stdenv,
}:
lib.extendMkDerivation
  {
    constructDrv = stdenv.mkDerivation;
    excludeDrvArgNames = [];

    extendDrvArgs =
      finalAttrs:
      {}:
      {};
  }
