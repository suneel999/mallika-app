# Infrastructure

The app is small: about 100 appointments and 200 patients. It runs on one EC2 server with one S3 bucket for backups. There is no load balancer, no Fargate, and no RDS in this setup.

| Piece | What it does |
| --- | --- |
| EC2 server, 2 GB memory, Ubuntu 24.04 | Runs three containers: PostgreSQL 18, the API, and Caddy |
| Caddy | Serves HTTPS for `app.mallikahospitals.in`, sends `/api/` to the API, and serves the reception desk for everything else |
| S3 bucket | Nightly database backups. Banner images go here later |

The patient app calls `https://app.mallikahospitals.in/api/v1`. Reception opens `https://app.mallikahospitals.in`.

## Files

- `docker-compose.yml` starts the three containers.
- `Caddyfile` is the web server configuration.
- `web.Dockerfile` builds the reception desk into the Caddy image.
- `.env.example` lists the values the server needs. The real `.env` is never committed.
- `setup-server.sh` prepares a new server.
- `backup.sh` saves the database to S3.
- `set-whatsapp-token.ps1` puts a new WhatsApp token on the server from this computer.

The app is running on the server since 13 November 2026, with an empty database. HTTPS works on `https://app.mallikahospitals.in`. The old load balancer, Fargate service, and RDS database were deleted the same day; the snapshot `mallika-db-final-2026-11-13` is what remains of the old database. The code was sent as a bundle through the backup bucket (`deploy/app.tar.gz`), not with `git clone`, because it was not pushed yet. The nightly backup is scheduled and one backup was taken by hand. `docker compose config` accepts the compose file.

## One-time setup

1. The AWS pieces were created on 13 November 2026 in Hyderabad (`ap-south-2`):

   | Piece | Name |
   | --- | --- |
   | Server | `mallika-app`, `i-023a7aae2ad686bf8`, `t4g.small` (ARM, 2 GB), Ubuntu 24.04, 30 GB encrypted disk |
   | Fixed address | `18.60.7.170` |
   | Firewall | `mallika-app-server`: ports 80 and 443 only. Port 22 is closed |
   | Server role | `mallika-app-server`: the backup bucket and Session Manager, nothing else |
   | Backup bucket | `mallika-hospitals-backups-` followed by the last six digits of the account number. Private, encrypted, `db/` deleted after 30 days |

   Docker, Docker Compose, git, the AWS tool, and 2 GB of swap are installed. There is no SSH key. Open a shell from the AWS console with EC2, Connect, Session Manager, or with `aws ssm start-session --target i-023a7aae2ad686bf8`. The server cannot be terminated until termination protection is switched off.
2. In the domain's DNS (the name servers are `dns-parking.com`), add an A record: `app` pointing at `18.60.7.170`. Wait until `nslookup app.mallikahospitals.in` shows that address.
3. On the server:

   ```bash
   sudo -iu ubuntu
   git clone https://github.com/suneel999/mallika-app.git
   ```

   `setup-server.sh` has already been run on this server. It is kept for a rebuild.
4. Create the settings file and fill in every placeholder:

   ```bash
   cd mallika-app/infra
   cp .env.example .env
   nano .env
   chmod 600 .env
   ```

5. Start everything:

   ```bash
   docker compose up -d --build
   ```

   The API creates its tables on first start. Caddy asks for the certificate on the first request.
6. Check it:

   ```bash
   curl https://app.mallikahospitals.in/api/v1/health/
   ```

   The answer is `{"status":"ok"}`.

## Move the data from the old database

Do this once, in a quiet hour, after step 6 works. Stop the old API first so nothing new is written while copying.

```bash
# From a machine that can reach the old database:
pg_dump -h <old-rds-address> -U <old-user> -d <old-database> -Fc -f mallika.dump

# On the new server, in mallika-app/infra:
docker compose stop api
docker compose exec -T db pg_restore -U mallika -d mallika --clean --if-exists --no-owner < mallika.dump
docker compose start api
```

Then build the patient app against the new address and install it:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://app.mallikahospitals.in/api/v1
```

Only after sign-in, a booking, and the desk all work on the new address: take a final snapshot of the old database, then delete the old load balancer, the Fargate service, and the RDS instance. The saving starts when those are deleted.

## Nightly backup

```bash
chmod +x ~/mallika-app/infra/backup.sh
sudo nano /etc/cron.d/mallika-backup
```

Add this line. It runs at 01:30 India time (20:00 UTC):

```
0 20 * * * ubuntu /home/ubuntu/mallika-app/infra/backup.sh >> /home/ubuntu/backup.log 2>&1
```

Run `./backup.sh` once by hand and check that a file appears in the bucket.

To restore a backup:

```bash
aws s3 cp s3://<bucket>/db/<file>.dump mallika.dump
docker compose stop api
docker compose exec -T db pg_restore -U mallika -d mallika --clean --if-exists --no-owner < mallika.dump
docker compose start api
```

Try one restore on a spare machine before relying on the backups.

## Secrets

All server secrets are in one file on the server: `/home/ubuntu/mallika-app/infra/.env`. Only the `ubuntu` user can read it. It is not in the repository or in the app.

| Value | What it is | When to change it |
| --- | --- | --- |
| `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` | Sends sign-in codes through WhatsApp | When Meta rejects the token. On 13 November 2026 the stored token was rejected: the session was logged out. Use a System User token that does not expire |
| `DJANGO_SECRET_KEY` | Signs the API's tokens | Only if it leaks. Everyone has to sign in again |
| `POSTGRES_PASSWORD` | The database password | Only if it leaks. Changing it here is not enough: the database user's password must be changed too |

To change the WhatsApp token from the office computer, without opening the server:

```powershell
powershell -File infra\set-whatsapp-token.ps1
```

It asks for the token with hidden typing, puts it on the server, restarts the API, and says whether Meta accepts it. It has been checked for syntax only; it has not been run with a real token yet.

To change any value by hand on the server:

```bash
sudo -iu ubuntu
cd ~/mallika-app/infra
nano .env
docker compose up -d --force-recreate api
docker compose logs api --tail 20
```

Staff passwords are stored hashed in the database, not in this file. Create the first staff login with:

```bash
docker compose exec api python manage.py createsuperuser
```

It asks for the mobile number as `+91` and ten digits, then the password.

## Updating the app

```bash
cd ~/mallika-app
git pull
cd infra
docker compose up -d --build
```

## What this setup does not do

- If the server stops, the app is down until it restarts or is rebuilt from a backup.
- Up to one day of bookings can be lost if the disk fails between backups. A daily EBS snapshot does not shorten that, but it makes rebuilding the server faster.
- Push notifications and SMS are still not sent. Sign-in codes go out through WhatsApp.

Keep production secrets out of the repository and out of the Flutter app.
