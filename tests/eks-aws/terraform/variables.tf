variable "repo_url" {
  type    = string
  #default = "https://github.com/camptocamp/devops-stack.git"
  default = "https://github.com/ckaenzig/devops-stack.git"
}

variable "target_revision" {
  type    = string
  #default = "master"
  default = "debug"
}
