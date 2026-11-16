# Facts give each host's architecture, which picks the release archives,
# and its family, which names the ssh client package.
data "conn3x_host" "facts" {
  for_each = var.hosts

  ssh {
    host             = try(each.value.address, each.value)
    host_key         = try(each.value.host_key, null)
    user             = try(each.value.user, var.ssh_user)
    port             = try(each.value.port, var.ssh_port)
    private_key_file = try(each.value.private_key_file, var.ssh_private_key_file)
    jump_hosts       = try(each.value.jump_hosts, null)
    known_hosts_file = var.ssh_known_hosts_file
  }
}

locals {
  goarch = { x86_64 = "amd64", aarch64 = "arm64" }
  arch   = { for name, f in data.conn3x_host.facts : name => local.goarch[f.arch] }
  ssh    = { for name, f in data.conn3x_host.facts : name => f.os_family == "debian" ? "openssh-client" : "openssh-clients" }

  # Each release unpacks into a directory of its own, so changing a version
  # never runs a half-replaced binary.
  ui_dir     = "/opt/conn3x-ui/conn3x-ui-${var.conn3x_ui_version}"
  conn3x_dir = "/opt/conn3x-ui/conn3x-${var.conn3x_version}"

  # Each flag quoted for systemd, so a space stays inside its argument and
  # systemd doesn't expand a % specifier or a $ variable in it.
  flags = join(" ", [for a in concat(["-listen", var.listen, "-data", "/var/lib/conn3x-ui", "-key-file", "/etc/conn3x-ui/key"], var.extra_args) :
    "\"${replace(replace(replace(replace(a, "\\", "\\\\"), "\"", "\\\""), "%", "%%"), "$", "$$")}\""
  ])
}

circuit "conn3x_ui" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  # curl, tar and gzip to install; git and ssh for the UI, which clones each
  # project's repository for every run.
  step "tools" {
    for_each = toset(["curl", "tar", "gzip", "git"])
    package {
      name = item.value
    }
  }

  step "ssh_client" {
    package {
      name = local.ssh[each.key]
    }
  }

  step "user" {
    user {
      name   = "conn3x-ui"
      system = true
      home   = "/var/lib/conn3x-ui"
      shell  = "/usr/sbin/nologin"
    }
  }

  # The database, saved plans and credentials directories: only the UI's
  # user can read them.
  step "data_dir" {
    directory {
      path  = "/var/lib/conn3x-ui"
      owner = "conn3x-ui"
      group = "conn3x-ui"
      mode  = "0700"
    }
  }

  step "config_dir" {
    directory {
      path  = "/etc/conn3x-ui"
      owner = "root"
      group = "conn3x-ui"
      mode  = "0750"
    }
  }

  # mkdir would make these with the login session's umask, and under
  # circuit-hardening's 027 the UI's user couldn't reach its binaries.
  step "opt_dirs" {
    for_each = toset(["/opt/conn3x-ui", local.ui_dir, local.conn3x_dir])
    directory {
      path = item.value
      mode = "0755"
    }
  }

  step "download_ui" {
    download {
      url    = "https://github.com/conn3xorg/conn3x-ui/releases/download/v${var.conn3x_ui_version}/conn3x-ui_${var.conn3x_ui_version}_linux_${local.arch[each.key]}.tar.gz"
      sha256 = var.conn3x_ui_checksums[local.arch[each.key]]
      dest   = "${local.ui_dir}.tar.gz"
    }
  }

  step "unpack_ui" {
    archive {
      src     = "${local.ui_dir}.tar.gz"
      dest    = local.ui_dir
      creates = "${local.ui_dir}/conn3x-ui"
    }
  }

  step "download_conn3x" {
    download {
      url    = "https://github.com/conn3xorg/conn3x/releases/download/v${var.conn3x_version}/conn3x_${var.conn3x_version}_linux_${local.arch[each.key]}.tar.gz"
      sha256 = var.conn3x_checksums[local.arch[each.key]]
      dest   = "${local.conn3x_dir}.tar.gz"
    }
  }

  step "unpack_conn3x" {
    archive {
      src     = "${local.conn3x_dir}.tar.gz"
      dest    = local.conn3x_dir
      creates = "${local.conn3x_dir}/conn3x"
    }
  }

  # The credentials key is made on the host, once, and never leaves it: it
  # isn't in this circuit's plan or state. Back it up apart from
  # /var/lib/conn3x-ui, since one without the other opens nothing.
  step "key" {
    command {
      command = "umask 027 && head -c 32 /dev/urandom | base64 > /etc/conn3x-ui/key.new && chgrp conn3x-ui /etc/conn3x-ui/key.new && mv /etc/conn3x-ui/key.new /etc/conn3x-ui/key"
      creates = "/etc/conn3x-ui/key"
    }
  }

  # A project's "conn3x" runs the release above, through PATH.
  step "unit" {
    file {
      path    = "/etc/systemd/system/conn3x-ui.service"
      content = <<-EOT
        [Unit]
        Description=Conn3x web UI
        After=network-online.target
        Wants=network-online.target

        [Service]
        User=conn3x-ui
        Group=conn3x-ui
        Environment=PATH=${local.conn3x_dir}:/usr/local/bin:/usr/bin:/bin
        Environment=HOME=/var/lib/conn3x-ui
        ExecStart=${local.ui_dir}/conn3x-ui serve ${local.flags}
        Restart=on-failure
        NoNewPrivileges=true
        ProtectSystem=strict
        ProtectHome=true
        PrivateTmp=true
        ReadWritePaths=/var/lib/conn3x-ui

        [Install]
        WantedBy=multi-user.target
      EOT
    }
    notify = [handler.restart]
  }

  step "running" {
    service {
      name    = "conn3x-ui"
      state   = "started"
      enabled = true
    }
  }

  handler "restart" {
    service {
      name = "conn3x-ui"
    }
  }
}
