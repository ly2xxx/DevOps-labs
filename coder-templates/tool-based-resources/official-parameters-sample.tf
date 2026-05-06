terraform {
  required_providers {
    coder = {
      source = "coder/coder"
      version = "2.5.3"
    }
  }
}

# Welcome to the Parameters Playground. You can:
# - edit user data in the "users" tab
# - share your form via URL
# - delete the Terraform below to start from scratch

locals {
  ides = [
    {
      name = "VSCode",
      value = "vscode",
      icon = "/icon/code.svg"
    },
    {
      name = "Jetbrains IntelliJ",
      value = "intellij",
      icon = "/icon/intellij.svg"
    },
    {
      name = "Cursor",
      value = "cursor",
      icon = "/icon/cursor.svg"
    },
  ]

  username = data.coder_workspace_owner.me.name
  is_admin = contains(data.coder_workspace_owner.me.groups, "admin")
}

data "coder_workspace_owner" "me" {}

data "coder_parameter" "dropdown_picker" {
  name = "dropdown_picker"
  display_name = "Pick your next parameter!"
  description = "Hello ${username}, pick your next parameter using this `dropdown` parameter."
  form_type = "dropdown"
  mutable = true

  option {
    value = "ide_picker"
    name = "IDE multi-select"
  }

  option {
    value = "text_area"
    name = "Large text entry"
  }

  option {
    value = "cpu_slider"
    name = "CPU slider"
  }
} 

data "coder_parameter" "ide_picker" {
  count = try(data.coder_parameter.dropdown_picker.value, "") == "ide_picker" ? 1 : 0
  
  name = "ide_picker"
  display_name = "Pick your IDEs!"
  description = "This is created using the `form_type = 'multi-select'` option."

  type = "list(string)"
  form_type = "multi-select"
  order = 2
  mutable = true

  dynamic "option" {
    for_each = local.ides
    content {
      name        = option.value.name
      value       = option.value.value
      description = option.value.description
      icon        = option.value.icon
    }
  }
}

data "coder_parameter" "text_area" {
  count = try(data.coder_parameter.dropdown_picker.value, "") == "text_area" ? 1 : 0
  
  name = "text_area"
  display_name = "Enter a large AI prompt or script!"
  description = "This is created using the `form_type = 'textarea'` option."
  
  type = "string"
  form_type = "textarea"
  order = 2
  mutable = true

  styling = jsonencode({
    placeholder = <<-EOT
  This is a large text entry, try it out!
  
  Including support for multi-line text entry.
  EOT
  }) 
}

data "coder_parameter" "cpu_slider" {
  count = try(data.coder_parameter.dropdown_picker.value, "") == "cpu_slider" ? 1 : 0
  name = "cpu_slider"
  display_name = "CPU Cores Slider"
  description = "This is created using the `form_type = 'slider'` option."
  
  type = "number"
  form_type = "slider"
  order = 2
  default = 4
  mutable = true

  validation {
    min = 2
    max = 8
  }
}

data "coder_parameter" "admin_only" {
  count = local.is_admin ? 1 : 0
  
  name = "admin_only"
  display_name = "Use imaginary experimental features?"
  description = "This option is only available to those in the 'admin' group. You can hide it by changing your user data. \n\n _This does not actually enable experimental features._"

  type = "bool"
  form_type = "checkbox"
  default = false
  
  order = 5
}
