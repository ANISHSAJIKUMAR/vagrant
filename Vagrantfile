Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.hostname = "vpn-gateway"

  # Terminal-only VM (no GUI)
  config.vm.provider "virtualbox" do |vb|
    vb.name = "vpn-gateway"
    vb.memory = 1024
    vb.cpus = 1
    vb.gui = false
  end

  # SSH access from host terminal
  config.ssh.insert_key = false

  # WireGuard UDP port exposed on host.
  # If 51820 is busy, vagrant auto-corrects to another host port.
  config.vm.network "forwarded_port",
    guest: 51820,
    host: 51820,
    protocol: "udp",
    auto_correct: true

  # Optional admin web port (disabled by default)
  # config.vm.network "forwarded_port", guest: 8080, host: 8080

  config.vm.provision "shell",
    run: "always",
    path: "provision/setup_wireguard.sh",
    env: {
      "WG_SERVER_PUBLIC_IP" => ENV.fetch("WG_SERVER_PUBLIC_IP", "REPLACE_WITH_YOUR_PUBLIC_IP_OR_DNS"),
      "WG_PORT" => ENV.fetch("WG_PORT", "51820"),
      "WG_SUBNET" => ENV.fetch("WG_SUBNET", "10.8.0.0/24"),
      "WG_SERVER_ADDRESS" => ENV.fetch("WG_SERVER_ADDRESS", "10.8.0.1/24"),
      "WG_DNS" => ENV.fetch("WG_DNS", "1.1.1.1,8.8.8.8"),
      "CONNECTION_DIR" => ENV.fetch("CONNECTION_DIR", "/vagrant/connection")
    }
end
