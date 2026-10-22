class team_linux::profile::colorprompt {

  # see if we can do clever things with the prompt
  if  $cmdb != undef and $cmdb['params'] != undef and
      $cmdb['params']['dnsfuncname'] != undef  {
    $host_tag = regsubst($cmdb['params']['dnsfuncname'], '(\.func|)\.cak-bz\.local', '', 'G' )
  } else {
    $host_tag = '\h'
  }

  # Show prompt with current woring dir and time:
  #$prompt = "\\[\\e]0;\\u@${host_tag}\\a\\]\${env}[\${userColor}\\u\\[\\e[0m\\]@\${serverColor}${host_tag}\\[\\e[0m\\] \\t \\W]\\\\$ "
  # only show current working dir
  $prompt = "\\[\\e]0;\\u@${host_tag}\\a\\]\${env}[\${userColor}\\u\\[\\e[0m\\]@\${serverColor}${host_tag}\\[\\e[0m\\] \\W]\\\\$ "

  case $environment {
    'experimenteel': {
      class { 'colorprompt':
        env_name          => 'EXP',
        env_color         => ['black','bg_green'],
        server_color      => 'green',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    'ontwikkeling': {
      class { 'colorprompt':
        env_name          => 'ONT',
        env_color         => ['black','bg_green'],
        server_color      => 'green',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    'test': {
      class { 'colorprompt':
        env_name          => 'TST',
        env_color         => ['white','bg_blue'],
        server_color      => 'blue',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    'acceptatie': {
      class { 'colorprompt':
        env_name          => 'ACC',
        env_color         => ['black','bg_yellow'],
        server_color      => 'yellow',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    productie,master_production: {
      class { 'colorprompt':
        env_name          => 'PRD',
        env_color         => ['white','bg_red'],
        server_color      => 'red',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    /^dev_/: {
      class { 'colorprompt':
        env_name          => 'PUPDEV',
        env_color         => ['white','bg_magenta'],
        server_color      => 'green',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
    default: {
      class { 'colorprompt':
        env_name          => 'ENVERR',
        env_color         => ['white','bg_red'],
        server_color      => 'red',
        default_usercolor => 'cyan',
        custom_usercolors => {
          'root' => 'red',
        },
        prompt      => $prompt,
        modify_skel => false,
        modify_root => false,
      }
    }
  }

}
