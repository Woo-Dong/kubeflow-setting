# Deploying Kubeflow with RDS and S3 using Kustomize

## Getting Started
---

### 1. Before kustomize kubeflow-setting, check accessKey and secretKey at default minio-artifact and change with your AWS ACCESS KEY
* the file directory is `apps/pipeline/upstream/third-party/minio/mlpipeline-minio-artifact-secret.yaml`
  ```yaml
  kind: Secret
  apiVersion: v1
  metadata:
    name: mlpipeline-minio-artifact
  stringData:
    accesskey: <YOUR_AWS_ACCESS_ID>
    secretkey: <YOUR_AWS_SECRET_KEY>
  ```

### 2. Edit 3 .env files
  * 1-1. `secret.env`
    ```txt
    username=YOUR_RDS_USERNAME
    password=YOUR_RDS_PASSWORD
    ```

  * 1-2. `params.env`
    ```txt
    dbHost=YOUR_RDS_ENDPOINT_URL

    bucketName=YOUR_S3_BUCKET_NAME
    minioServiceHost=s3.amazonaws.com
    minioServiceRegion=ap-northeast-2
    ```

  * 1-3. minio-artifact-secret-patch.env
    ```txt
    accesskey=YOUR_AWS_ACCESS_ID
    secretkey=YOUR_AWS_SECRET_KEY
    ```

### 2. Kustomize build & kubectl apply
  ```txt
  kustomize build kubeflow-setting/aws | kubectl apply -f -
  ```