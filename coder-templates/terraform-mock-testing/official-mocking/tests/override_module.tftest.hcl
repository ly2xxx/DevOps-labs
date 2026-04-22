# main.tftest.hcl
mock_provider "aws" {}

override_module {
  target = module.credentials
  outputs = {
    data = { username = "username", password = "password" }
  }
}

run "test" {
  assert {
    condition     = jsondecode(local_file.credentials_json.content).username == "username"
    error_message = "incorrect username"
  }
}
