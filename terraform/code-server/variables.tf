variable "user_app_info" {
  type = object({
    user_name    = string
    label_app    = string
  })
  default = [
    {
      user_name = "likewind"
      app_name = "cws-codeserver-likewind"
      label_app = "cws-codeserver-likewind"
    }
  ]
}