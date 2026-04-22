# main.tftest.hcl

mock_provider "aws" {
  source = "./tests"
}

run "test" {
  assert {
    condition     = jsondecode(local_file.credentials_json.content).username == "username12345"
    error_message = "incorrect username"
  }
}
