job "nginx-proxy" {
  datacenters = ["dc1"]
  type        = "service"

  group "proxy" {
    network {
      mode = "host"
      port "https" {}
    }

    service {
      name     = "nginx-proxy"
      port     = "https"
      provider = "consul"

      check {
        type            = "http"
        protocol        = "https"
        tls_skip_verify = true
        path            = "/healthz"
        interval        = "10s"
        timeout         = "2s"
      }
    }

    task "gen-cert" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        image   = "alpine:3.20"
        command = "sh"
        args    = ["-c", "apk add --no-cache openssl >/dev/null && openssl req -x509 -newkey rsa:2048 -nodes -days 30 -subj /CN=localhost -keyout /alloc/data/tls.key -out /alloc/data/tls.crt"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }

    task "proxy" {
      driver = "docker"

      config {
        image        = "nginx:1.27-alpine-slim"
        network_mode = "host"
        volumes = ["local/nginx.conf:/etc/nginx/nginx.conf:ro"]
      }

      template {
        destination   = "local/nginx.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          events {}
          http {
            upstream app {
          {{- range service "nginx-app" }}
              server {{ .Address }}:{{ .Port }};
          {{- end }}
            }
            server {
              listen {{ env "NOMAD_PORT_https" }} ssl;
              ssl_certificate     /alloc/data/tls.crt;
              ssl_certificate_key /alloc/data/tls.key;
              location / {
                proxy_pass http://app;
                proxy_set_header Host $host;
              }
            }
          }
        EOT
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
