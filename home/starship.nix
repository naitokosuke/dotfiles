{ ... }:

let
  # Free space on the startup disk, shown as "<free> / <size> free". Starship
  # has no built-in module for it. The APFS volumes share one container, so /
  # reports the same free space as the Data volume.
  #
  # A custom module can't restyle itself from its own output, so each colour
  # is a separate module, shown only while the used share falls in its range.
  diskFree = style: min: max: {
    command = "df -h / | awk 'NR == 2 { print $4 \" / \" $2 }'";
    when = "p=$(df -k / | awk 'NR == 2 { print int(($2 - $4) * 100 / $2) }'); [ $p -ge ${toString min} ] && [ $p -lt ${toString max} ]";
    shell = [ "sh" ];
    inherit style;
    format = "with [$output free]($style) ";
  };
in
{
  programs.starship = {
    enable = true;

    # Enable for Nushell
    enableNushellIntegration = true;

    # Starship configuration
    settings = {
      # Add newline before prompt
      add_newline = true;

      # Prompt format
      format = "$username$hostname\${custom.disk_free}\${custom.disk_free_warning}\${custom.disk_free_critical}$directory$git_branch$git_status$cmd_duration$line_break$character";

      # Character module (prompt indicator)
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };

      # Username
      username = {
        show_always = true;
        style_user = "green bold";
        format = "[$user]($style) ";
      };

      # Hostname
      hostname = {
        ssh_only = false;
        style = "yellow";
        format = "at [$hostname]($style) ";
      };

      # Free disk space: yellow from 90% used, red from 95%
      custom = {
        disk_free = diskFree "cyan" 0 90;
        disk_free_warning = diskFree "yellow" 90 95;
        disk_free_critical = diskFree "red bold" 95 101;
      };

      # Directory
      directory = {
        style = "green bold";
        format = "in [$path]($style) ";
        truncation_length = 5;
        truncate_to_repo = false;
      };

      # Git branch
      git_branch = {
        style = "purple bold";
        format = "on [$symbol$branch]($style) ";
      };

      # Git status
      git_status = {
        style = "red bold";
        format = "([$all_status$ahead_behind]($style))";
      };

      # Command duration
      cmd_duration = {
        min_time = 2000;
        style = "yellow";
        format = "took [$duration]($style) ";
      };
    };
  };
}
