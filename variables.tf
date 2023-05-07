variable "user_app_info" {
  type = object({
    user_name    = string
    label_app    = string
  })
  default = [
    {
      user_name = "likewind"
      app_name = "cws-codeserver-" + user_name
      label_app = app_name
    }
  ]
}