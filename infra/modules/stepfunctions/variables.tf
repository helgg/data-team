variable "state_machine_name" {
  description = "nome da state machine"
  type        = string
}

variable "state_machine_iam_role_arn" {
  description = "ARN da IAM role usada pela state machine (criada fora deste módulo)"
  type        = string
}

variable "state_machine_log_level" {
  description = "nível de log da state machine no CloudWatch Logs"
  type        = string

  validation {
    condition     = contains(["ERROR", "ALL"], var.state_machine_log_level)
    error_message = "state_machine_log_level must be 'ERROR' or 'ALL'."
  }
}

variable "state_machine_type" {
  description = "tipo da state machine"
  type        = string
  default     = "STANDARD"
}

variable "state_machine_definition" {
  description = "definição ASL (JSON) já renderizada da state machine"
  type        = string
}

variable "owner_team_email" {
  description = "e-mail do time owner da state machine"
  type        = string
}

variable "tech_team_email" {
  description = "e-mail do time técnico responsável"
  type        = string
}

variable "github_repo_id" {
  description = "ID do repositório GitHub de origem"
  type        = string
}

variable "github_repo_name" {
  description = "nome do repositório GitHub de origem"
  type        = string
}

variable "deployment_alias" {
  description = "nome do alias de deployment (publica uma versão e cria aws_sfn_alias quando definido)"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags a aplicar nos recursos do módulo"
  type        = map(string)
  default     = {}
}
