{ stdenv, source }:

stdenv.mkDerivation rec {
  name = "n-${version}";
  version = "master";

  src = source;

  dontBuild = true;

  installPhase = ''
    PREFIX=$out make install
  '';

  meta = with stdenv.lib; {
    description = "Node version management";
    homepage = "https://github.com/tj/n";
    license = licenses.mit;
  };
}
