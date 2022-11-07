
## Setting Notebooks for Starting Image from Private Registry(ECR)

1. Get Docker config json file
    * prerequisites
        - aws-cli
        - amazon-ecr-credential-helper(optional)
    ```sh
    sudo apt-get install awscli
    sudo apt-get install amazon-ecr-credential-helper
    ```
    * configure
    ```sh
    aws configure
    ```

2. login ECR(DockerHub)
    ```sh
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin {YOUR_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com
    ```

3. Create secret regcred on your workspace
    ```sh
    kubectl -n {YOUR_WORKSPACE} create secret generic regcred --from-file=.dockerconfigjson=.docker/config.json --type=kubernetes.io/dockerconfigjson
    ```

4. Patch serviceaccount named "default-editor"
    ```sh
    kubectl -n {YOUR_WORKSPACE} patch serviceaccount default-editor -p '{"imagePullSecrets": [{"name": "regcred"}]}'
    ```
    ---

## (ETC) Push Docker Image on ECR

1. Push Public Registry
    ```sh
    #login
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/{REGISTRY_NAME}
    docker build -t {TAG_NAME} .
    docker tag {TAG_NAME} public.ecr.aws/{REGISTRY_NAME}/...:latest
    docker push public.ecr.aws/{REGISTRY_NAME}/...:latest
    ```


2. Push Private Registry
    ```sh
    #login
    aws ecr get-login-password --region {YOUR_REGION} | docker login --username AWS --password-stdin {YOUR_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com

    docker build -t {TAG_NAME} .
    docker tag {TAG_NAME} {YOUR_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/{REGISTRY_NAME}/...:latest
    docker push {YOUR_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/{REGISTRY_NAME}/...:latest
    ```


