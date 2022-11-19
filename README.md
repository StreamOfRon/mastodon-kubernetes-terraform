# mastodon-kubernetes-terraform

Yep, the repo name is buzzword soup, but this is based on the code used to set up and maintain macaw.social.  I wanted to publish this in case it helps others get started with expanding the fediverse.

***This is provided as-is with no warranties whatsoever.  You should be at least somewhat comfortable/familiar with the technologies involved***

If this helps you, consider supporting https://macaw.social by using our [DigitalOcean referral link](https://m.do.co/c/4c16aca034d2) to sign up for their services

## Prerequisites

- A working kubernetes cluster with at least 2GB usable RAM with:
  - A working storage provisioner which is resilient enough for your needs
  - A working ingress controller - this is preconfigured for traefik so you may need to make changes if you are using something else.
  - Working cluster DNS
- S3-compatible storage - a configuration for minio is provided but commented out by default since you'll need to be somewhat comfortable configuring minio to get it working
  - Tested and working:
    - DigitalOcean Spaces
    - Minio
  - Not tested, assumed working:
    - Amazon S3
  - Tested, does not work:
    - Cloudflare R2
    - Linode Object Storage
- A PostgreSQL database - a configuration for postgres is provided but commented out by default since you'll need to be somewhat comfortable configuring postgres to get it working
- An email provider - Anything which can accept messages via SMTP and relay them is fine to use here.  Amazon SES is a popular, low-cost option.
- Terraform and familiarity with the basic usage thereof.
  - This was tested against version 1.3.4

## Instructions for Use

### Gathering variables

There are a couple of dozen (sorry!) variables you'll have to supply to get everything up and running appropriately. For a complete list, see variables.tf.  Most of these are exactly as documented at https://docs.joinmastodon.org/admin/config/ with the ones I've added specified below

- kube_host: This is the URI where your kubernetes management endpoint can be reached by terraform
- kube_token: The auth token which terraform can use to manage resources on your kubernetes cluster
- kube_insecure: If your kubernetes management endpoint uses a self-signed cert, set this to true to bypass cert validation
- namespace: Defaults to "default" but if you're using your kubernetes cluster for things other than Mastodon, you may want to deploy into a dedicated namespace
- nameservers: A list of nameservers to append to the DNS configuration for pods if your cluster DNS does not consistently resolve external hostnames in a timely fashion.

### Launch!

Run terraform init/plan/apply to submit the changes, resolving any errors you may encounter. Once the deployments are up and running, and you've pointed the appropriate DNS entries to your server, you'll want to log into a shell on the running mastodon-web pod with kubectl exec -it mastodon-web-xxxxx (substitute for your actual running pod name, find it with kubectl get pods) and then run the following command to set up your initial admin account:
- tootctl accounts create (yourusernamehere) --email (youremailhere) --role Owner

If you encounter an error here saying your email is invalid, check the DNS configuration in your pod.  You may need to specify additional external nameservers (or troubleshoot your cluster's DNS).  You can bypass this by adding --confirmed to the above command which does not attempt to send the email.

From here, you can follow the remainder of the instructions at https://docs.joinmastodon.org/admin/setup/ to get things up and running

## Scaling

Most of the interesting scalability options documented at https://docs.joinmastodon.org/admin/scaling/ are exposed via locals in main.tf

The one you'll likely want to tweak before any others is the sidekiq threads. Sidekiq runs all of the background operations for Mastodon and the queues can get backed up once you have more than a small number of users.  Check your queues at https://*your domain here*/sidekiq/queues and if you see they don't ever seem to catch up, increase the thread and/or replica counts.  This deployment already does the work of splitting out all of the workers on a per-queue basis so you don't have to worry about that task :)

### Replicas vs. Threads

This is a decision that you'll need to make based on your current server topology. More, small replicas are likely going to be more resilient and ultimately scale better if you are on a cluster with multiple servers.  If you have a single server running everything, increase thread counts instead.  There's likely a sweet spot in the balance here but at this point I haven't done enough testing to give pointers on where that is.

