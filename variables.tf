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
  default     = "0.1.1"
  nullable    = false
  description = "conn3x-ui release to install, without the leading v. Null means the default."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.]+)?$", var.conn3x_ui_version))
    error_message = "conn3x_ui_version is a release number without the leading v, such as \"0.1.1\"."
  }
}

variable "conn3x_ui_checksums" {
  type        = map(string)
  nullable    = false
  description = "SHA-256 of the conn3x-ui release archive for each architecture, from the release's checksums.txt. Change these with conn3x_ui_version. Null means the default."
  default = {
    amd64 = "7ee009393cfcf5563a05d25b895abfae42c2ee1694e0192a1664658f6f75a2e1"
    arm64 = "80fe1d46dbdc4240ccdc5d4f5ac82ae9cc5670b95058f2824525d34fd393f7d4"
  }
}

variable "conn3x_version" {
  type        = string
  default     = "0.21.0"
  nullable    = false
  description = "Conn3x release the UI runs plans and applies with, without the leading v. A project can name another binary. Null means the default."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.]+)?$", var.conn3x_version))
    error_message = "conn3x_version is a release number without the leading v, such as \"0.21.0\"."
  }
}

variable "conn3x_checksums" {
  type        = map(string)
  nullable    = false
  description = "SHA-256 of the conn3x release archive for each architecture, from the release's checksums.txt. Change these with conn3x_version. Null means the default."
  default = {
    amd64 = "7712571cca774201988a98126115a9592eaecf75819fd0353dd6ead84c7e1292"
    arm64 = "21b5b3446740d992e8827e1646a342aff523929374eb76f0e7a887315893c6a2"
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
