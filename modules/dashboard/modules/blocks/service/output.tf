output "result" {
  description = "description"
  value = concat(
    [
      [{ type : "text/title-with-collapse", text : coalesce(var.block_name, var.name) }]
    ],
    local.all_widgets
  )
}
