{
  lib,
  stdenvNoCC,
  fetchurl,
  python3,
}:

let
  crxUrl =
    id:
    "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=139.0.0.0&acceptformat=crx2,crx3&x=id%3D${id}%26uc";

  extensions = [
    {
      pname = "bitwarden";
      id = "nngceckbapebfimnlniiiahkandclblb";
      hash = "sha256-0aWULZwjTQM4LamSeZMgVQZMquejLMmxV5QMhjFl1Z8=";
    }
    {
      pname = "darkreader";
      id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      hash = "sha256-Cfq1Bqjwpled0jkBydCKdK+RU5i8d3YtUHqNGv323Qw=";
    }
    {
      pname = "video-downloadhelper";
      id = "lmjnegcaeklhafolokijcfjliaokphfk";
      hash = "sha256-45PufH4MHBmxqbj2wmhAgDoK+PJ2QTTwS33+CWoJwNo=";
    }
    {
      pname = "return-youtube-dislike";
      id = "gebbhagfogifgggkldgodflihgfeippi";
      hash = "sha256-orlCwWL0GeALQYCMxrHd71wpOWNVupLk0VrtQcxYtUk=";
    }
    {
      pname = "sponsorblock";
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      hash = "sha256-VYf+K2qZRhAcoN3nxu/nanVcXuW21uY9/EjH9zbNtP8=";
    }
    {
      pname = "grammarly";
      id = "kbfnbcaeplbcioakkpcpgfkobkghlhen";
      hash = "sha256-WG1h9OcAjMA2pPKp/T0wGDVSBQyvReBfpYTsuvbtOFE=";
    }
  ];

  fetchCrx =
    {
      pname,
      id,
      hash,
    }:
    fetchurl {
      inherit hash;
      name = "${pname}.crx";
      url = crxUrl id;
    };
in
stdenvNoCC.mkDerivation {
  name = "helium-external-extensions";
  nativeBuildInputs = [ python3 ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ${lib.concatMapStrings (ext: ''
      cp ${fetchCrx ext} "$out/${ext.id}.crx"
      python3 ${./unpack-crx.py} "$out/${ext.id}.crx" unpacked-${ext.id}
      python3 ${./write-external-json.py} \
        "$out/${ext.id}.json" \
        "$out/${ext.id}.crx" \
        unpacked-${ext.id}/manifest.json
    '') extensions}
    runHook postInstall
  '';
}
