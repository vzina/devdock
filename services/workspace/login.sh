#!/usr/bin/env bash

SHELL_FILE=~/.ssh/insecure_id_rsa

if [ ! -f "$SHELL_FILE" ]; then
	SHELL_FILE=$(cd "$(dirname "$0")";pwd)/insecure_id_rsa
fi

# 登录workspace
ssh -o PasswordAuthentication=no \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -p 2222 \
  -i $SHELL_FILE \
  devdock@localhost
