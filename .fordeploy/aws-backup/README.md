# Local AWS Runtime Backup

Create the real AWS runtime environment file manually at:

```text
.fordeploy/aws-backup/.env
```

Start from the repository root `.env.example`, replace every secret placeholder,
and keep the real `.env` out of Git. Deployment stops if the file is absent or
if a required variable is empty.

This directory is excluded from Docker build contexts. The deploy script copies
the file by absolute path to `/home/ubuntu/vueshines/.env`, without printing its
contents, and installs it with owner `ubuntu:ubuntu` and mode `600`.
