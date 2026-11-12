final: prev:
{
  deviceTree =
    prev.deviceTree
  //
    {
      applyOverlays = final.callPackage ../../packages/device-tree {};
    }
    ;
}
