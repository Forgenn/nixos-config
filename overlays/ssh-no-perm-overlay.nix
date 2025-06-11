{ patchFile }:
final: prev: {
  openssh-no-checkperm = prev.openssh.overrideAttrs (oldAttrs: {
    pname = "${oldAttrs.pname or "openssh"}-no-checkperm";
    patches = (oldAttrs.patches or [ ]) ++ [
      patchFile # Uses the resolved patchFile passed as an argument
    ];
  });
}
