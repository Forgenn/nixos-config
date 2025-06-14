# bootstrap-democratic-csi-zfs.nix
{ pkgs, config, lib }:
let
  targetManifestFilename = "01-democratic-csi-zfs-config.yaml";
  k3sManifestsDir = "/var/lib/rancher/k3s/server/manifests";
  driverConfigYamlWithPlaceholder = ''
    driver: zfs-generic-nfs
    sshConnection:
      host: dolores.home
      port: 22
      username: revachol-csi-user
      privateKey: |
        __SSH_PRIVATE_KEY_PLACEHOLDER__

    zfs:
      cli:
        sudoEnabled: true
      datasetParentName: revachol-pool/k8s-data/main
      detachedSnapshotsDatasetParentName: revachol-pool/k8s-data/snapshots
      datasetEnableQuotas: true
      datasetEnableReservation: false
      datasetPermissionsMode: "0777"
      datasetPermissionsUser: revachol-csi-user
      datasetPermissionsGroup: revachol-csi-user

    nfs:
      shareStrategy: "setDatasetProperties"
      shareStrategySetDatasetProperties:
        properties:
          sharenfs: "on"
      shareHost: "dolores.home"
  '';
in
{
  manifests = {
    "00-democratic-csi-namespace" = {
      enable = true;
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = { name = "democratic-csi"; };
      };
    };
  };

  updateManifestScript = pkgs.writeShellScriptBin "update-csi-manifest-key" ''
    #!${pkgs.stdenv.shell}
    set -euo pipefail

    MANIFEST_FILE="${k3sManifestsDir}/${targetManifestFilename}"
    DECRYPTED_KEY_PATH="${config.age.secrets.nas_node_key.path}"

    echo "Creating manifest file: $MANIFEST_FILE"

    # Ensure the manifests directory exists
    mkdir -p "${k3sManifestsDir}"

    if [ ! -f "$DECRYPTED_KEY_PATH" ]; then
      echo "ERROR: Decrypted SSH key not found at $DECRYPTED_KEY_PATH. Agenix might not have run or failed." >&2
      exit 1
    fi

    echo "Reading private key from $DECRYPTED_KEY_PATH"
    PRIVATE_KEY_CONTENT=$(${pkgs.coreutils-full}/bin/cat "$DECRYPTED_KEY_PATH")
    echo "Private key read successfully"

    # Create the YAML content with the actual key
    echo "Creating YAML content with the actual key"
    # Create a temporary file for the key content
    KEY_FILE=$(${pkgs.coreutils-full}/bin/mktemp)
    echo "$PRIVATE_KEY_CONTENT" | ${pkgs.gnused}/bin/sed 's/^/        /' > "$KEY_FILE"

    # Create a temporary file for the YAML template
    YAML_FILE=$(${pkgs.coreutils-full}/bin/mktemp)
    echo "${driverConfigYamlWithPlaceholder}" > "$YAML_FILE"

    # Replace the placeholder with the key content
    ${pkgs.gnused}/bin/sed -i -e "/__SSH_PRIVATE_KEY_PLACEHOLDER__/r $KEY_FILE" -e "//d" "$YAML_FILE"

    # Read the final YAML content
    YAML_CONTENT=$(${pkgs.coreutils-full}/bin/cat "$YAML_FILE")
    
    # Base64 encode the YAML content
    echo "Encoding YAML content"
    B64_CONTENT=$(echo -n "$YAML_CONTENT" | ${pkgs.coreutils-full}/bin/base64 -w0)
    
    # Validate the base64 encoding
    if ! echo "$B64_CONTENT" | ${pkgs.coreutils-full}/bin/base64 -d > /dev/null 2>&1; then
        echo "ERROR: Generated base64 is invalid" >&2
        exit 1
    fi
    echo "YAML content encoded and validated"

    # Create the manifest file
    echo "Creating manifest file"
    cat > "$MANIFEST_FILE" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: democratic-csi-zfs-config
  namespace: democratic-csi
type: Opaque
data:
  driver-config-file.yaml: $B64_CONTENT
EOF

    # Set permissions to 777
    chmod 777 "$MANIFEST_FILE"
    echo "Set permissions to 777 on $MANIFEST_FILE"

    # Clean up temporary files
    rm -f "$KEY_FILE" "$YAML_FILE"

    echo "Successfully created manifest file with the real SSH key."
  '';
}