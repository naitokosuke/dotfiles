# The MacBook Air, the one host with Touch ID: sudo accepts a fingerprint.
# hosts/common/homebrew.nix reads this to keep Homebrew's sudo prompt on the
# terminal (#504).
{
  security.pam.services.sudo_local.touchIdAuth = true;
}
