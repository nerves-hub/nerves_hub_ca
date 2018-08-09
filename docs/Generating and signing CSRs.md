# Creating a CSR with openssl


## Devices

Generating a key

```bash
openssl ecparam -genkey -name prime256v1 -noout -out device-key.pem
```

Generating a CSR

```
openssl req -new -sha256 -key device-key.pem -out device.csr -subj "/O=device-1234"
```


## Users

Generating a key

```bash
openssl ecparam -genkey -name prime256v1 -noout -out user-key.pem
```

Generating a CSR

```
openssl req -new -sha256 -key user-key.pem -out user.csr -subj "/O=test@test.com"
```
