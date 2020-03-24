#!/usr/bin/env bash

SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

# 登录workspace
ssh -o PasswordAuthentication=no \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -p 2222 \
  -i $SHELL_FOLDER/insecure_id_rsa \
  devdock@localhost