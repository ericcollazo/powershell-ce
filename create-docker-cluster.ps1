# Load variables file into $values
$Path = ".\variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData

$apiToken = $values.do_api_token

# manager-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "8gb" --digitalocean-access-token $apiToken manager-0
$manager0ip = docker-machine ip manager-0
$joinIp = $manager0ip + ":2377"
docker-machine ssh manager-0 docker swarm init --advertise-addr $manager0ip

# Install UCP
docker-machine ssh manager-0 docker container run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:latest install --host-address $manager0ip --admin-username admin --admin-password adminadmin --swarm-port 2378

# Get join tokens
$workerJoinToken = docker-machine ssh manager-0 docker swarm join-token worker -q

# dtr-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "8gb" --digitalocean-access-token $apiToken dtr-0
docker-machine ssh dtr-0 docker swarm join --token $workerJoinToken $joinIp

# worker-0
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-0
docker-machine ssh worker-0 docker swarm join --token $workerJoinToken $joinIp

# worker-1
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-1
docker-machine ssh worker-1 docker swarm join --token $workerJoinToken $joinIp

# worker-2
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-2
docker-machine ssh worker-2 docker swarm join --token $workerJoinToken $joinIp

# minio-0
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "4gb" --digitalocean-access-token $apiToken minio-0
docker-machine ssh minio-0 docker run -d -p 9000:9000 --name minio-0 -e "MINIO_ACCESS_KEY=minioAccessKey" -e "MINIO_SECRET_KEY=minioSecretKey" -v /mnt/data:/data -v /mnt/config:/root/.minio minio/minio server /data

# jenkins-0
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "4gb" --digitalocean-access-token $apiToken jenkins-0

# List nodes in swarm
docker-machine ssh manager-0 docker node ls

# List docker machines
docker-machine ls

Write-Host "***************************************"
Write-Host "Run the following to install DTR on dtr-0 vm..."
Write-Host "docker-machine ssh dtr-0 docker pull docker/dtr:latest"
Write-Host "docker-machine ssh dtr-0 docker run --rm docker/dtr:latest install --ucp-node dtr-0 --ucp-url https://$manager0ip --ucp-username admin --ucp-password adminadmin --ucp-insecure-tls"
Write-Host "***************************************"
Write-Host ""
Write-Host "***************************************"
Write-Host "Run the following to install Jenkins on jenkins-0 vm..."
Write-Host "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -"
Write-Host "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'"
Write-Host "sudo apt-get update"
Write-Host "sudo apt-get install jenkins"
Write-Host "sudo usermod -a -G docker jenkins"
Write-Host "***************************************"
