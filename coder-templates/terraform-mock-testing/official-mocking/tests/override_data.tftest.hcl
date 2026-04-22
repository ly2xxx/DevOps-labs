# main.tftest.hcl

mock_provider "aws" {}

override_data {
  target = module.credentials.data.aws_s3_object.data_bucket
  values = {
    body = "{\"username\":\"username\",\"password\":\"password\"}"
  }
}

run "test_file_override" {
  assert {
    condition     = jsondecode(local_file.credentials_json.content).username == "username"
    error_message = "incorrect username"
  }
}

run "test_run_override" {
  # The value in this local override block takes precedence over the
  # alternate defined in the file.
  override_data {
    target = module.credentials.data.aws_s3_object.data_bucket
    values = {
      body = "{\"username\":\"a_different_username\",\"password\":\"password\"}"
    }
  }

  assert {
    condition     = jsondecode(local_file.credentials_json.content).username == "a_different_username"
    error_message = "incorrect username"
  }
}
