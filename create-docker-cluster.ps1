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

# Install UCP
docker-machine ssh manager-0 docker container run --rm --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.2.6 install --host-address $manager0ip --admin-username admin --admin-password adminadmin --swarm-port 2378

# dtr-0
docker-machine create --driver digitalocean --digitalocean-image "ubuntu-16-04-x64" --digitalocean-region "nyc1" --digitalocean-size "8gb" --digitalocean-access-token $apiToken dtr-0
docker-machine ssh dtr-0 docker swarm join --token $workerJoinToken $joinIp

# Install DTR
docker-machine ssh dtr-0 docker pull docker/dtr:2.4.2
docker-machine ssh dtr-0 docker run -it --rm docker/dtr:2.4.2 install --replica-id 6474722d3063 --ucp-node dtr-0 --ucp-url https://$manager0ip --ucp-username admin --ucp-password adminadmin --ucp-insecure-tls

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