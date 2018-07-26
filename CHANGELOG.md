# Changelog

## v0.3.0

The certificate structure has changed.
Prior to this version, all certificates were signed off the main root certificate.
This version will generate a root certificate and several intermediate root 
certificates for use with signing users, devices, servers, and ca clients.

```
                   --------------
                  |   Root CA    |
                   --------------
                /         |        \
 --------------    --------------    --------------
| Intermediate |  | Intermediate |  | Intermediate |
|   User CA    |  |  Device CA   |  |  Server CA   | 
 --------------    --------------    --------------
       |                  |                 |        \
 --------------    --------------    --------------    ---------------
|     User     |  |    Device    |  |    Server    |  |   CA Client   |
|  Certificate |  |  Certificate |  |  Certificate |  |  Certificate  |
 --------------    --------------    --------------    ---------------
```


* Enhancements
  * Added mix task for generating initial certificate structure.
  * Start CFSSL processes configured for each certificate type.

* Certificate Expirations
  * Root CA: 30 years
  * Intermediate CA: 10 years
  * Server certificate: 1 year
  * User certificate: 1 year
  * Device certificate: 5 years

## v0.2.0

* Enhancements
  * Added `/health_check` to router to return 200.
  * Removed setting the docker ENTRYPOINT in the image.
    
    This makes it easier to make a container for use in dev and test.
    You can bind mount a directory containing your cfssl configs and 
    certificates.

    ```
    docker run --rm \
      --mount type=bind,src=`pwd`/test/fixtures/ssl,dst=/etc/cfssl \
      -p 8443:8443 \
      nerveshub/nerves_hub_ca:v0.2.0
    ```

    Running in production, you can set the entry point to sync the data.
    For example, from S3
    ```
    docker run --rm \
      --entrypoint=/app/s3-entrypoint.sh \
      -p 8443:8443 \
      nerveshub/nerves_hub_ca:v0.2.0
    ```
  
## v0.1.0

Initial Release.

`nerves_hub_ca` is released as a docker image and pushed to dockerhub.
The `ENTRYPOINT` of the container is configured to execute an included
`docker-entrypoint.sh` script which will perform an `aws s3 sync` of the
production certificates. 

If you are using this image privately, you can either
specify your own bucket / aws credentials when running the container:

```
docker run --rm --name nerves-hub-ca \
  -e "S3_BUCKET=my-bucket" \
  -e "AWS_DEFAULT_REGION=us-east-1" \
  -e "AWS_ACCESS_KEY_ID=12345" \
  -e "AWS_SECRET_ACCESS_KEY=67890" \
  -p 8443:8443 \
  nerveshub/nerves_hub_ca:0.1.0
```

Or you can override the `ENTRYPOINT` by basing a new image off 
`nerveshub/nerves_hub_ca:0.1.0`

```
FROM nerveshub/nerves_hub_ca:0.1.0

ENTRYPOINT "my-entrypoint.sh"
```
