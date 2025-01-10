
# instalar docker

Set selinux in permissive mode

```bash
setenforce 0
```

Set selinux in permissive mode at every system restart

```bash
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

Write the docker-ce.repo file in the system. In this case go to the `/etc/yum.repos.d` directory

```bash
cd /etc/yum.repos.d
```

Download the next `.repo` file (for RREL based linux distributions)

```bash
wget https://download.docker.com/linux/centos/docker-ce.repo
```

Sometimes, the appropiate OS release is not appropiate in that file, if necessary run the next command

```bash
sed -i 's/$releasever/8.8/g' docker-ce.repo
```

Install Docker

```bash
dnf -y install containerd.io docker-ce-cli docker-ce
```

Enable the automatic restart

```bash
systemctl enable --now docker
```

Validate that the Docker service is running

```bash
systemctl status docker
```

Optionally for Docker Compose create a symlink

```bash
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose
```
