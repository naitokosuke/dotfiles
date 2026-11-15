# Starship draws the prompt; home-manager wires it into zsh. A leading newline
# gives every prompt room, and `format` names exactly what appears instead of
# the default module list.
{ lib, pkgs, ... }:

let
  ## Free disk space
  # Free space on the startup disk, shown as "󰋊 <free> / <size>". Starship
  # has no built-in module for it. The macOS system and data volumes share one
  # APFS container, so / reports the same free space as the data volume.
  #
  # macOS's own df and awk are named by path on purpose: the awk programs
  # read the column layout of BSD df, which GNU coreutils' df does not
  # reproduce. `sh` comes from the store, so nothing depends on $PATH.
  diskFree = style: min: max: {
    command = "/bin/df -h / | /usr/bin/awk 'NR == 2 { print $4 \" / \" $2 }'";
    when = "p=$(/bin/df -k / | /usr/bin/awk 'NR == 2 { print int(($2 - $4) * 100 / $2) }'); [ $p -ge ${toString min} ] && [ $p -lt ${toString max} ]";
    shell = [ (lib.getExe' pkgs.bash "sh") ];
    inherit style;
    # Nerd Font hard disk glyph (nf-md-harddisk)
    symbol = "󰋊 ";
    format = "with [$symbol$output]($style) ";
  };
in
{
  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;

      ## Format
      # User, host, free disk space, directory, git branch and status, and
      # command duration, then a line break and the `❯` character, green on
      # success and red on failure. User and host show outside SSH too, and
      # the duration only for commands that took two seconds or more.
      format = "$username$hostname\${custom.disk_free}\${custom.disk_free_warning}\${custom.disk_free_critical}$directory$git_branch$git_status$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };

      username = {
        show_always = true;
        style_user = "green bold";
        format = "[$user]($style) ";
      };

      hostname = {
        ssh_only = false;
        style = "yellow";
        format = "at [$hostname]($style) ";
      };

      ## Colour by usage
      # A custom module can't restyle itself from its own output, so each
      # colour is a separate module: cyan below 90 % used, yellow from 90 %,
      # red from 95 %, the levels Powerlevel10k's disk_usage uses. Each one's
      # `when` shows it only inside its range, so exactly one appears.
      custom = {
        disk_free = diskFree "cyan" 0 90;
        disk_free_warning = diskFree "yellow" 90 95;
        disk_free_critical = diskFree "red bold" 95 101;
      };

      directory = {
        style = "green bold";
        format = "in [$path]($style) ";
        truncation_length = 5;
        truncate_to_repo = false;
      };

      git_branch = {
        style = "purple bold";
        format = "on [$symbol$branch]($style) ";
      };

      git_status = {
        style = "red bold";
        format = "([$all_status$ahead_behind]($style))";
      };

      cmd_duration = {
        min_time = 2000;
        style = "yellow";
        format = "took [$duration]($style) ";
      };
    };
  };
}
