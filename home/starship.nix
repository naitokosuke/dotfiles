{ ... }:

let
  # Free space on the startup disk, shown as "󰋊 <free> / <size>". Starship
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
    # Nerd Font hard disk glyph (nf-md-harddisk)
    symbol = "󰋊 ";
    format = "with [$symbol$output]($style) ";
  };
in
{
  programs.starship = {
    enable = true;

    enableNushellIntegration = true;

    settings = {
      add_newline = true;

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
