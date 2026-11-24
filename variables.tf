variable "hosts" {
  type        = any
  description = "Hosts to configure: a map of names to addresses, or to host objects with an address and optional host_key, user, port, private_key_file or jump_hosts."
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "known_hosts file to check host keys against. When null, ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run commands as root through sudo."
}



variable "conn3x_ui_version" {
  type        = string
  default     = "0.4.1"
  nullable    = false
  description = "conn3x-ui release to install, without the leading v. Null means the default."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.]+)?$", var.conn3x_ui_version))
    error_message = "conn3x_ui_version is a release number without the leading v, such as \"0.4.1\"."
  }
}

variable "conn3x_ui_checksums" {
  type        = map(string)
  nullable    = false
  description = "SHA-256 of the conn3x-ui release archive for each architecture, from the release's checksums.txt. Change these with conn3x_ui_version. Null means the default."
  default = {
    amd64 = "4a012a9ffe35f1a0b717bd569f85c39a3e235bbfb9d923b549627bb880c1827c"
    arm64 = "535b5b30f4559340b8ad05c3c730ce92231a9862c71c204380d3ad6e0f0616a8"
  }
}

variable "conn3x_version" {
  type        = string
  default     = "0.31.0"
  nullable    = false
  description = "Conn3x release the UI runs plans and applies with, without the leading v. A project can name another binary. Null means the default."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.]+)?$", var.conn3x_version))
    error_message = "conn3x_version is a release number without the leading v, such as \"0.31.0\"."
  }
}

variable "conn3x_checksums" {
  type        = map(string)
  nullable    = false
  description = "SHA-256 of the conn3x release archive for each architecture, from the release's checksums.txt. Change these with conn3x_version. Null means the default."
  default = {
    amd64 = "bd12ea595da2176a09d28de5b8249937d315153eeb3e97285fa6d23c50289edb"
    arm64 = "918fd83f85a4f0295ac2c799247d48a71fe265eb273b134a47fbce41b4985962"
  }
}

variable "listen" {
  type        = string
  default     = "127.0.0.1:8080"
  description = "Address the UI listens on. Keep it on loopback and put a TLS proxy in front to reach it from elsewhere: off localhost, the session cookie needs https."

  validation {
    condition     = can(regex("^[0-9A-Za-z.:\\[\\]-]*:[0-9]+$", var.listen))
    error_message = "listen is host:port, such as \"127.0.0.1:8080\"."
  }
}

variable "extra_args" {
  type        = list(string)
  default     = []
  description = "More flags for conn3x-ui serve, such as the -oidc-* ones for single sign-on. Each one is passed as a single argument, as written. Keep secrets out: use -oidc-client-secret-file."

  # Each flag is quoted into the unit's ExecStart, which quoting can't make
  # safe for a newline: that would start a new line of the unit.
  validation {
    condition     = alltrue([for a in var.extra_args : !can(regex("[\\x00-\\x1f\\x7f]", a))])
    error_message = "extra_args can't contain newlines or other control characters."
  }
}
