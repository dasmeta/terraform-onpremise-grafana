output "result" {
  description = "description"
  value = concat(
    [
      [{ type : "text/title-with-collapse", text : var.name }]
    ],
    local.all_widgets
  )
}
