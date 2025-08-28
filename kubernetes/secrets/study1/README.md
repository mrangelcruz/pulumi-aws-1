# Create a kubernetes secret and deploy a python application that will print out that secret

## Step 1: Create the Kubernetes Secret

    kubectl create secret generic my-secret \
    --from-literal=API_KEY='supersecretvalue123'

