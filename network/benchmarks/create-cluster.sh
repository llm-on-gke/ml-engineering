# for L4 and spot node-pools
export PROJECT_ID=<your-project-id>

export REGION=us-central1
export ZONE_1=${REGION}-a # You may want to change the zone letter based on the region you selected above
export ZONE_2=${REGION}-b # You may want to change the zone letter based on the region you selected above
export CLUSTER_NAME=two-sigma-cluster

gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE_1"

gcloud container clusters create $CLUSTER_NAME --location ${REGION} \
  --workload-pool ${PROJECT_ID}.svc.id.goog \
  --enable-image-streaming --enable-shielded-nodes \
  --shielded-secure-boot --shielded-integrity-monitoring \
  --enable-ip-alias \
  --node-locations=$REGION-b \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --addons GcsFuseCsiDriver   \
  --no-enable-master-authorized-networks \
  --machine-type n2d-standard-4 \
  --num-nodes 1 --min-nodes 1 --max-nodes 3 \
  --ephemeral-storage-local-ssd=count=2 \
  --scopes="gke-default,storage-rw"

gcloud container node-pools create a2-pool   --accelerator type=nvidia-tesla-a100,count=8,gpu-driver-version=latest   --machine-type a2-highgpu-8g   --region us-central1 --cluster two-sigma-cluster     --node-locations us-central1-b   --enable-autoscaling    --min-nodes 0    --num-nodes 0 --max-nodes 4   --ephemeral-storage-local-ssd=count=0 --spot


gcloud container node-pools create a2-gvnic-pool --accelerator type=nvidia-tesla-a100,count=8,gpu-driver-version=latest  --machine-type a2-highgpu-8g   --region us-central1 --cluster two-sigma-cluster  --node-locations us-central1-b   --enable-autoscaling    --min-nodes 0    --num-nodes 0 --max-nodes 4 --ephemeral-storage-local-ssd=count=0 --spot --enable-gvnic