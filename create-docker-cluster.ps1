# Load variables file into $values
$Path = ".\variables.txt"
$values = Get-Content $Path | Out-String | ConvertFrom-StringData

# Digitalocean API token
$apiToken = $values.do_api_token

# manager-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "2gb" --digitalocean-access-token $apiToken manager-0
docker node update --availability drain manager-0
$manager0ip = docker-machine ip manager-0

# Initiate swarm
docker-machine ssh manager-0 docker swarm init --advertise-addr $manager0ip

# Get join tokens
$managerJoinToken = docker-machine ssh manager-0 docker swarm join-token manager -q
$workerJoinToken = docker-machine ssh manager-0 docker swarm join-token worker -q
$swarmPort = "2377"
$joinIp = $manager0ip + ":" + $swarmPort
$ucpUsr = "admin"
$ucpPwd = "adminadmin"
$ucpPort = "2378"

# Install UCP
docker-machine ssh manager-0 docker container run --rm -it --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.2.5 install --host-address $manager0ip --admin-username $ucpUsr --admin-password $ucpPwd --swarm-port $ucpPort

# worker-0
docker-machine create  --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "2gb" --digitalocean-access-token $apiToken worker-0
docker-machine ssh worker-0 docker swarm join --token $workerJoinToken $joinIp

# dtr-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc3" --digitalocean-size "2gb" --digitalocean-access-token $apiToken dtr-0
docker-machine ssh dtr-0 docker swarm join --token $workerJoinToken $joinIp
docker node update --availability drain dtr-0

# Install DTR
docker-machine ssh dtr-0 docker pull docker/dtr:2.4.2
docker-machine ssh dtr-0 docker run -it --rm docker/dtr:2.4.1 install --ucp-node dtr-0 --ucp-url https://$manager0ip --ucp-username admin --ucp-password adminadmin --ucp-insecure-tls

# List nodes in swarm
docker-machine ssh manager-0 docker node ls

# List docker machines
docker-machine ls