
## Setting Notebooks for pulling Image from Private Registry(ECR)

### 1. Set CronJob
1. edit your info below variables in `ecr-secret-helper.yaml` file
    ```txt
    <NAMESPACE>
    <AWS_ACCESS_KEY_ID>
    <AWS_SECRET_ACCESS_KEY>
    <ACCOUNT_ID>
    <ECR_REPOSITORY>
    ```

2. apply config
    ```sh
    kubectl apply -f ecr-secret-helper.yaml
    ```


### 2. on Manual
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
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com
    ```

3. Create secret regcred on your workspace
    ```sh
    kubectl create secret generic regcred -n {YOUR_WORKSPACE} --from-file=.dockerconfigjson=.docker/config.json --type=kubernetes.io/dockerconfigjson
    ```

4. Patch serviceaccount named "default-editor"
    ```sh
    kubectl patch serviceaccount default-editor -n {YOUR_WORKSPACE} -p '{"imagePullSecrets": [{"name": "regcred"}]}'
    ```
    ---

## Push Docker Image on ECR

### On Manual
1. Push Public Registry
    * `--region` option must be `"us-east-1"` on the public registry
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
    aws ecr get-login-password --region {YOUR_REGION} | docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com

    docker build -t {TAG_NAME} .
    docker tag {TAG_NAME} {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/{REGISTRY_NAME}/...:latest
    docker push {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/{REGISTRY_NAME}/...:latest
    ```


### Using Makefile
1. Install make
    ```sh
    sudo apt-get install make
    ```

2. fill .env file
    ```sh
    TAG=xxxxxxxx
    ACCOUNT_ID=xxxxxxxxxxxx
    ```

3. Run shell script
    ```sh
    chmod +x build_push_image_all.sh
    ./build_push_image_all.sh
    ```