output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "Nginx Ingress Controller" }
    ],
    [
      { type : "ingress/request-rate" },
      { type : "ingress/connections" },
      { type : "ingress/latency" },
      { type : "ingress/latency", by_host : true },
    ],
    [
      { type : "ingress/request-count" },
      { type : "ingress/request-count", only_5xx : true },
      { type : "ingress/request-count", only_5xx : true, by_path : true },
      { type : "ingress/request-count", only_5xx : true, by_status_path : true },
    ],
    [
      { type : "ingress/cpu", pod : "nginx-ingress", namespace : "ingress-nginx", width : 4, },
      { type : "ingress/memory", pod : "nginx-ingress", namespace : "ingress-nginx", width : 4, },
      { type : "container/network-traffic", pod : "nginx-ingress", width : 4 },
      { type : "container/network-transmit", pod : "nginx-ingress", width : 4 },
    ],
  ]
}
