{ ... }:

# Distrust the root behind the compromised eMudhra intermediates (issue #527,
# CVE-2026-111943), which Homebrew/homebrew-core#319674 also removed. NSS, and
# so nixpkgs' `cacert`, still ships it. The other roots Homebrew dropped
# (`AAA Certificate Services`, `emSign Root TLS CA - G3`) are already absent,
# and `cacert` fails to build on a blocklist entry it does not have, so this
# breaks the build once upstream drops the root, and the list can go.
{
  security.pki.caCertificateBlacklist = [ "emSign ECC Root CA - G3" ];
}
