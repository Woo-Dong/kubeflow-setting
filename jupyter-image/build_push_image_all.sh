#!/bin/bash

# fill in your .env file like below
# =============================
# TAG=20221121
# ACCOUNT_ID=00000000
# =============================
source .env

make docker-build-all TAG=${TAG} ACCOUNT_ID=${ACCOUNT_ID}

make docker-push-all TAG=${TAG} ACCOUNT_ID=${ACCOUNT_ID}
