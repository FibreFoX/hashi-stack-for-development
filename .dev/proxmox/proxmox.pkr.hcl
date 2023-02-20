source "vagrant" "debainbase" {
  source_path = "generic/debian11"
  # for proper reproducability make sure to use fixed versions !!! ("latest" is the worst concept ever)
  box_version  = "4.2.12"
  communicator = "ssh"
  # box supports multiple providers, so specify one here
  provider = "hyperv"
  # if box_version was NOT provided, use this to make it using the latest available box version
  ###add_force = true
  output_dir = "proxmox-image"
  #### https://github.com/hashicorp/packer-plugin-vagrant/blob/main/builder/vagrant/step_create_vagrantfile.go#L25
}

build {
  name = "hashi-stack-proxmox"

  sources = ["source.vagrant.debainbase"]

  # make sure base-system starts with up2date installed stuff (can still be outdated with latest vagrant image)
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      # will get executed as "vagrant" user so we have to use SUDO here
      "sudo -E apt-get update",
      "sudo -E apt-get upgrade -y",
      "sudo -E apt-get clean",
    ]
  }

  # install proxmox provided kernel
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "set -ex",
      "echo \"deb [arch=amd64] http://download.proxmox.com/debian/pve bullseye pve-no-subscription\" | sudo tee /etc/apt/sources.list.d/pve-install-repo.list",
      "sudo wget https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bullseye.gpg",
      "sudo -E apt-get update",
      # remove non-required stuff to speed up build time
      "sudo -E apt-get remove -y os-prober",
      # use newer version
      "sudo -E apt-get install -y pve-kernel-5.19",
      "sudo update-grub",
      # IMPORTANT reboot VM as some tools require newer kernel stuff (RTFM said so)
      "sudo systemctl reboot",
    ]
    expect_disconnect = true
  }

  # remove old kernel after rebooting with the new one
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "set -ex",
      "sudo -E apt-get remove -y linux-image-amd64 'linux-image-5.10*'",
    ]
  }

  # replace ifupdown with ifupdown2 (would be installed with proxmox-ve, which breaks the vagrant connection to the VM)
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "set -ex",
      "sudo -E apt-get install -y ifupdown2",
      # IMPORTANT reboot VM as part of this script or we will never be able to connect again (it gets stuck)
      "sudo systemctl reboot",
    ]
    expect_disconnect = true
  }

  # make sure hosts file is set up accordingly
  provisioner "shell" {
    inline = [
      "set -ex",
      # use IPv4 only for this system
      "echo \"127.0.0.1 localhost\" | sudo tee /etc/hosts",
      # make sure to have the currect (non localhost) "external" IP address pointing to the hostname, otherwise proxmox will fail to install
      # with dpkg not being able to configure, and some error messages like "ipcc_send_rec[1] failed: Connection refused"
      # https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_11_Bullseye#Add_an_.2Fetc.2Fhosts_entry_for_your_IP_address
      # https://www.geekdecoder.com/proxmox-on-debian-install-fails-errors-were-encountered-while-processing-pve-manager-proxmox-ve/
      # https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address#comment42249706_21340278
      # adding short hostname is required too, otherwise it would break installing pve-manager when only having "long" hostname
      "echo \"$(hostname -I | cut -f1 -d' ') $(hostname -s) $(hostname)\" | sudo tee -a /etc/hosts",
      "sudo chown root:root /etc/hosts",
      "sudo chmod 0644 /etc/hosts",
    ]
  }

  # install ProxmoxVE itself
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "set -ex",
      # finally install ProxmoxVE
      "sudo -E apt-get install -y proxmox-ve postfix open-iscsi",
      # it is possible that some packages need updates that are coming from the proxmox repository (happened to me)
      "sudo -E apt-get upgrade -y",
      "sudo -E apt-get clean",
    ]
  }

  # prepare image with Debian 11 LXC image
  provisioner "shell" {
    inline = [
      "set -ex",
      # finally install ProxmoxVE
      "sudo pveam update",
      "export LATEST_DEBIAN_LXC_IMAGE=$(sudo pveam available | fgrep debian-11-standard | awk '{print $2}')",
      "sudo -E pveam download local $LATEST_DEBIAN_LXC_IMAGE",
      "echo \"$LATEST_DEBIAN_LXC_IMAGE\" | tee /tmp/debian_lxc_image"
    ]
  }

  # for later reference in other scripts, store information about the embedded Debian LXC image
  provisioner "file" {
    source      = "/tmp/debian_lxc_image"
    destination = "debian_lxc_image"
    direction   = "download"
  }

  # there is no need for "vagrant" post-processor, as this is part of the builder
  # took me some time initially to fight in the beginning
  # as per RTFM https://developer.hashicorp.com/packer/plugins/builders/vagrant#vagrant-builder
  # "Please note that if you are using the Vagrant builder, then the Vagrant post-processor is unnecesary
  # because the output of the Vagrant builder is already a Vagrant box".
}
