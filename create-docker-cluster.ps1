# Load variables file into $values
$Path = ".\variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData

$apiToken = $values.do_api_token

# manager-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "8gb" --digitalocean-access-token $apiToken manager-0
$manager0ip = docker-machine ip manager-0
docker-machine ssh manager-0 docker swarm init --advertise-addr $manager0ip

# Get join tokens
$workerJoinToken = docker-machine ssh manager-0 docker swarm join-token worker -q
$swarmPort = "2377"
$joinIp = $manager0ip + ":" + $swarmPort
$ucpUsr = "admin"
$ucpPwd = "adminadmin"
$ucpPort = "2378"

# Install UCP
docker-machine ssh manager-0 docker container run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.2.6 install --host-address $manager0ip --admin-username $ucpUsr --admin-password $ucpPwd --swarm-port $ucpPort

# minio-0
$minio_access_key = "THISISTHEACCESSKEY"
$minio_secret = "THISISTHESECRETKEY"
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "4gb" --digitalocean-access-token $apiToken minio-0
docker-machine ssh minio-0 docker swarm join --token $workerJoinToken $joinIp
docker-machine ssh minio-0 docker run -d -p 9000:9000 --name minio0 -e "MINIO_ACCESS_KEY=$minio_access_key" -e "MINIO_SECRET_KEY=$minio_secret" -v /mnt/data:/data -v /mnt/config:/root/.minio minio/minio server /data

# dtr-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "8gb" --digitalocean-access-token $apiToken dtr-0
docker-machine ssh dtr-0 docker swarm join --token $workerJoinToken $joinIp

# Install DTR
$dtrId = "6474722d3063"
docker-machine ssh dtr-0 docker pull docker/dtr:2.4.2
docker-machine ssh dtr-0 docker run -it --rm docker/dtr:2.4.2 install --replica-id $dtrId --ucp-node dtr-0 --ucp-url https://$manager0ip --ucp-username admin --ucp-password adminadmin --ucp-insecure-tls

# worker-0
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-0
docker-machine ssh worker-0 docker swarm join --token $workerJoinToken $joinIp

# worker-1
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-1
docker-machine ssh worker-1 docker swarm join --token $workerJoinToken $joinIp

# worker-2
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "4gb" --digitalocean-access-token $apiToken worker-2
docker-machine ssh worker-2 docker swarm join --token $workerJoinToken $joinIp

# List nodes in swarm
docker-machine ssh manager-0 docker node ls

# List docker machines
docker-machine ls 
