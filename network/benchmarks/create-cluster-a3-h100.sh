# for L4 and spot node-pools
export PROJECT_ID=<your-project-id>

export REGION=europe-west4
export ZONE_1=${REGION}-a # You may want to change the zone letter based on the region you selected above
export ZONE_2=${REGION}-b # You may want to change the zone letter based on the region you selected above
export CLUSTER_NAME=two-sigma-cluster

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE_1"

## default cluster
export CLUSTER_ARGUMENTS=" \
 --network=natt-a3-base-sysnet \
 --subnetwork=gke-subnet \
 --scopes=storage-full,gke-default \
 --enable-ip-alias \
 --enable-private-nodes \
 --master-ipv4-cidr 172.16.0.32/28 \
 --cluster-ipv4-cidr=10.224.0.0/12 \
 --no-enable-master-authorized-networks \
 --release-channel regular \
"